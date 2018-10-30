---
layout: post
title:  "Network setup for our retro computing event RGB2Rv18"
date:   2018-10-30 23:00:00 +01:00
categories: Artikel
---

Our computer association [NoName e.V.](https://www.noname-ev.de/) organizes a
retro computing event called [RGB2R](https://www.rgb2r.de/) every year,
located in Heidelberg, Germany. This year’s version is called RGB2Rv18.

This article describes the network setup I created for this year’s event. If you
haven’t read it, the article about [last year’s RGB2Rv17
network](/posts/2017-11-13-rgb2r-network/) is also available.

### Connectivity

As a reminder, the venue’s DSL connection tops out at a megabit or two, so we
used my parent’s 400 Mbit/s cable internet line, like last year.

A difference to last year is that we switched from the tp-link CPE510 devices to
a pair of [Ubiquiti airFiber24](https://www.ubnt.com/airfiber/airfiber24/). The
airFibers are specified to reach 1.4 Gbit/s. In practice, we reached
approximately 700 Mbps displayed capacity (at a signal strength of ≈-60 dBm) and
422 Mbit/s end-to-end download speed, limited by the cable uplink.

Notably, using a single pair of radios removes a bunch of complexity from the
network setup as we no longer need to load-balance over two separate uplinks.

Like last year, the edge router for the event venue was a [PC Engines
apu2c4](https://pcengines.ch/apu2c4.htm). For the Local Area Network (LAN)
within the venue, we provided a few switches and WiFi using [Ubiquiti
Networks](https://www.ubnt.com/) access points.

### WiFi setup

It turns out that the 24 GHz-based airFiber radios are much harder to align than
the 5 GHz-based tp-links we used last year. With the tp-link devices, we were
able to easily obtain a link, and do maybe 45 minutes of fine tuning to achieve
maximum bandwidth.

With the airFiber radios mounted in the same location, we were unable to
establish a link even once in about 1.5 hours of trying. We think this was due
to trees/branches being in the way, so we decided to scout the property for a
better radio location with as much of a direct line of sight as possible.

We eventually found a better location on the other side of the house and managed
to establish a link. It still took us an hour or so of fine tuning to move the
link from weak (≈-80 dBm) to okay (≈-60 dBm).

After the first night, in which it rained for a while, the radios had lost their
link. We think that this might be due to the humidity, and managed to restore
the link after another 30 minutes of re-adjustment.

It also rained the second night, but this time, the link stayed up. During rain,
signal strength dropped from ≈-60 dBm to ≈-72 dBm, but that still resulted in
≈500 Mbit/s of WiFi capacity, sufficient to max out our uplink.

For next year, it would be great to use an antenna alignment tool of sorts to
cut down on setup time. Alternatively, we could switch to more forgiving radios
which also handle 500 Mbps+. Let me know if you have any suggestions!

### Software

In May this year, I wrote [router7](https://github.com/rtr7/router7), a pure-Go
small home internet router. Mostly out of curiosity, we gave it a shot, and I’m
happy to announce that router7 ran the event without any trouble.

In preparation, I [implemented TCP MSS
clamping](https://github.com/rtr7/router7/commit/2e8e0daa0ac8a6a123893b27fb1de566768383d0)
and [included the WireGuard kernel
module](https://github.com/rtr7/kernel/commit/c7afbc1fd2efdb9e1149d271c4d2be59cc5c98f4).

I largely followed the [router7 installation
instructions](https://github.com/rtr7/router7#installation). To be specific,
here is the `Makefile` I used for creating the router7 image:

```
# github.com/rtr7/router7/cmd/... without dhcp6,
# as the cable uplink does not provide IPv6:
PKGS := github.com/rtr7/router7/cmd/backupd \
	github.com/rtr7/router7/cmd/captured \
	github.com/rtr7/router7/cmd/dhcp4 \
	github.com/rtr7/router7/cmd/dhcp4d \
	github.com/rtr7/router7/cmd/diagd \
	github.com/rtr7/router7/cmd/dnsd \
	github.com/rtr7/router7/cmd/netconfigd \
	github.com/rtr7/router7/cmd/radvd \
	github.com/gokrazy/breakglass \
	github.com/gokrazy/timestamps \
	github.com/stapelberg/rgb2r/cmd/grafana \
	github.com/stapelberg/rgb2r/cmd/prometheus \
	github.com/stapelberg/rgb2r/cmd/node_exporter \
	github.com/stapelberg/rgb2r/cmd/blackbox_exporter \
	github.com/stapelberg/rgb2r/cmd/ratelimit \
	github.com/stapelberg/rgb2r/cmd/tc \
	github.com/stapelberg/rgb2r/cmd/wg

image:
ifndef DIR
	@echo variable DIR unset
	false
endif
	GOARCH=amd64 gokr-packer \
		-gokrazy_pkgs=github.com/gokrazy/gokrazy/cmd/ntp,github.com/gokrazy/gokrazy/cmd/randomd \
		-kernel_package=github.com/rtr7/kernel \
		-firmware_package=github.com/rtr7/kernel \
		-overwrite_boot=${DIR}/boot.img \
		-overwrite_root=${DIR}/root.img \
		-overwrite_mbr=${DIR}/mbr.img \
		-serial_console=ttyS0,115200n8 \
		-hostname=rgb2router \
		${PKGS}
```

After preparing an `interfaces.json` configuration file and a
[breakglass](https://github.com/gokrazy/breakglass) SSH hostkey, I used
`rtr7-recover` to net-install the image onto the apu2c4. For subsequent updates,
I used `rtr7-safe-update`.

The Go packages under `github.com/stapelberg/rgb2r` are wrappers which run
software I installed to the permanent partition mounted at `/perm`. See
[gokrazy: Prototyping](https://gokrazy.org/prototyping.html) for more details.

### Tunnel setup

Last year, we used a Foo-over-UDP tunnel after noticing that we didn’t get
enough bandwidth with OpenVPN. This year, after hearing much about it, we
successfully used [WireGuard](https://www.wireguard.com/).

I found WireGuard to be more performant than OpenVPN, and easier to set up than
either OpenVPN or Foo-over-UDP.

The one wrinkle is that its wire protocol is not yet frozen, and its kernel
module is not yet included in Linux.

### Traffic shaping

With asymmetric internet connections, such as the 400/20 cable connection we’re
using, it’s necessary to shape traffic such that the upstream is never entirely
saturated, otherwise the TCP ACK packets won’t reach their destination in time
to saturate the downstream.

While the FritzBox might already provide traffic shaping, we wanted to
voluntarily restrict our upstream usage to leave some headroom for my parents.

```
rgb2router# tc qdisc replace dev uplink0 root tbf \
  rate 16mbit \
  latency 50ms \
  burst 4000
```

The specified `latency` value is a best guess, and the `burst` value is derived
from the kernel internal timer frequency (`CONFIG_HZ`) (!), packet size and rate
as per
[https://unix.stackexchange.com/questions/100785/bucket-size-in-tbf](https://unix.stackexchange.com/questions/100785/bucket-size-in-tbf).

Tip: keep in mind to disable shaping temporarily when you’re doing bandwidth
tests ;-).

### Statistics

* We peaked at 59 active DHCP leases, which is very similar to the “about 60”
  last year.

* DNS traffic peaked at about 25 queries/second, while mostly remaining at less
  than 5 queries/second.

* We were able to obtain peaks of nearly 200 Mbit/s of download traffic and
  transferred over 200 GB of data, twice as much as last year.
