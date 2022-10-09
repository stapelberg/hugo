---
layout: post
title:  "DIY out-of-band management: remote console server"
date:   2022-08-27 14:40:00 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1563508916289687553"
---

For the guest WiFi at an event that eventually fell through, we wanted to tunnel
all the traffic through my internet connection via my home router.

Because the event is located in another country, many hours of travel away,
there are a couple of scenarios where remote control of my home router can be a
life-saver. For example, should my home router crash, remotely turning power off
and on again gets the event back online.

But, power-cycling a machine is a pretty big hammer. For some cases, like
locking yourself out with a configuration mistake, a more precise tool like a
remote serial console might be nicer.

In this article, I’ll present two cheap and pragmatic DIY out-of-band management
solutions that I have experimented with in the last couple of weeks and wanted
to share:

* [Variant 1: Remote Power Management only](#power-only)
* [Variant 2: a full Remote Console Server](#remote-console)

You can easily start with the first variant and upgrade it into the second
variant later.

## Variant 1: Remote Power Management {#power-only}

### Architecture Diagram

Here is the architecture of the system at a glance. The right-hand side is the
existing router I want to control, the left-hand side shows the out of band
management system:

{{< img src="2022-07-02-power-mgmt-architecture.svg" >}} 

Let’s go through the hardware components from top to bottom.

### Hardware: 4G WiFi Router (Out Of Band Network)

The easiest way to have another network connection for projects like this one is
the [digitec iot
subscription](https://www.digitec.ch/en/s1/product/digitec-iot-test-sim-card-data-flat-30-days-unlimited-10-mbits-sim-card-11689214?supplier=406802). They
offer various different options, and their cheapest one, a 0.4 Mbps flatrate for
4 CHF per month, is sufficient for our use-case.

A convenient way of making the digitec iot subscription available to other
devices is to use a mobile WiFi router such as the [TP-Link M7350 4G/LTE Mobile
Wi-Fi
router](https://www.digitec.ch/en/s1/product/tp-link-m7350-routers-5615329?supplier=406802)
(68 CHF). You can power it via USB, and it has a built-in battery that will last
for a few hours.

{{< img src="IMG_0484.jpg" alt="TP-Link M7350 4G/LTE Mobile Wi-Fi router connected to digitec iot" >}}

By default, the device turns itself off after a while when it thinks it is
unused, which is undesired for us — if the smart plug drops out of the WiFi, we
don’t want the whole system to go offline. You can turn off this behavior in the
web interface under `Advanced → Power Saving → Power Saving Mode`.

### Hardware: WiFi Smart Plug

With the out of band network connection established, all you need to remotely
toggle power is a smart plug such as the [Sonoff S26 WiFi Smart
Plug](https://itead.cc/product/sonoff-s26-wifi-smart-plug/).

The simplest setup is to connect the Smart Plug to the 4G router via WiFi, and
control it using Sonoff’s mobile app via Sonoff’s cloud.

#### Non-cloud solution

Alternatively, if you want to avoid the Sonoff cloud, the device comes with a
“DIY mode”, but [the DIY mode wouldn’t work reliably for
me](https://twitter.com/zekjur/status/1321949087160258562) when I tried
it. Instead, I flashed the [Open Source Tasmota
firmware](https://tasmota.github.io/docs/) and connected it to a self-hosted
MQTT server via the internet.

Of course, now your self-hosted MQTT server is a single point of failure, but
perhaps you prefer that over the Sonoff cloud being a single point of failure.

## Variant 2: Remote Console Server {#remote-console}

Turning power off and on remotely is a great start, but what if you need actual
remote access to a system? In my case, I’m using a [serial
port](https://en.wikipedia.org/wiki/Serial_port) to see log messages and run a
shell on my router. This is also called a “serial console”, and any device that
allows accessing a serial console without sitting physically in front of the
serial port is called a “remote console server”.

Commercially available remote console servers typically offer lots of ports (up
to 48) and cost lots of money (many thousand dollars or equivalent), because
their target application is to be installed in a rack full of machines in a lab
or data center. A few years ago, I built
[freetserv](https://freetserv.github.io/), an open source, open hardware
solution for this problem.

For the use-case at hand, we only need a single serial console, so we’ll do it
with a Raspberry Pi.

### Architecture Diagram

The architecture for this variant looks similar to the other variant, but adds
the *consrv* Raspberry Pi Zero 2 W and a USB-to-serial adapter:

{{< img src="2022-06-19-consrv_architecture.svg" >}} 

### Hardware: Raspberry Pi Zero 2 W

We’ll use a [Raspberry Pi Zero 2
W](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/) as our console
server. While the device is a little slower than a Raspberry Pi 3 B, it is still
plenty fast enough for providing a serial console, and it only consumes 0.8W of
power (see [gokrazy → Supported platforms](https://gokrazy.org/platforms/) for
a comparison):

{{< img src="IMG_0767_featured.jpg" alt="Raspberry Pi Zero 2 W with USB hub, ethernet and serial" >}}

If the Pi Zero 2 W is not available, you can try using any other [Raspberry Pi
supported by gokrazy](https://gokrazy.org/platforms/), or even an older Pi Zero
with the [community-supported Pi OS 32-bit
kernel](https://gokrazy.org/platforms/#community-supported-raspberry-pi-os-32-bit-kernelfirmware)
(I didn’t test that).

Our Pi will have at least two tasks:

1. With a USB-to-serial adapter, the Pi will provide a serial console.
1. The Pi will run [Tailscale](https://tailscale.com/) mesh networking, which
   will transparently use either the wired network or fail over to the Out Of
   Band network. Tailscale also frees us from setting up port forwardings,
   dynamic DNS or anything like that.
2. Optionally, the Pi can run a local MQTT server if you want to avoid the
   Sonoff cloud.

### Hardware: USB-to-serial adapter

You can use any USB-to-serial adapter supported by Linux. Personally, I like the
[Adafruit FT232H adapter](https://www.adafruit.com/product/2264), which I like
to [re-program with FTDI’s FT_Prog so that it has a unique serial
number](https://twitter.com/zekjur/status/1256879027266224128).

In my router, I plugged in an [Longshine LCS-6321M serial PCIe
card](https://twitter.com/zekjur/status/1443461234930634755) to add a serial
port. Before you ask: no, [using USB serial consoles for the kernel
console](https://twitter.com/zekjur/status/1439612800561819649) does not cut it.

### Hardware: USB ethernet adapter

Because we not only want this Raspberry Pi to be available via the Out Of Band
network (via WiFi), but also on the regular home network, we need a USB ethernet
adapter.

Originally I was going to use the Waveshare ETH-USB-HUB-BOX: Ethernet / USB HUB
BOX for Raspberry Pi Zero Series, but it [turned out to be
unreliable](https://twitter.com/zekjur/status/1538582804224782337).

Instead, I’m now connecting a USB hub (as the Pi Zero 2 W has only one USB
port), a [Linksys USB3GIG](https://www.linksys.com/support-product?sku=USB3GIG)
network adapter I had lying around, and my USB-to-serial adapter.

### gokrazy setup {#gokrazy-setup}

Just like in the [gokrazy quickstart](https://gokrazy.org/quickstart/), we’re
going to create a directory for this gokrazy instance:

```shell
INSTANCE=gokrazy/consrv
mkdir -p ~/${INSTANCE?}
cd ~/${INSTANCE?}
go mod init consrv
```

You could now directly run `gokr-packer`, but personally, I like putting the
`gokr-packer` command into a
[`Makefile`](https://en.wikipedia.org/wiki/Make_(software)#Makefile) right away:

```makefile
# The consrv hostname resolves to the device’s Tailscale IP address,
# once Tailscale is set up.
PACKER := gokr-packer -hostname=consrv

PKGS := \
	github.com/gokrazy/breakglass \
	github.com/gokrazy/timestamps \
	github.com/gokrazy/serial-busybox \
	github.com/gokrazy/stat/cmd/gokr-webstat \
	github.com/gokrazy/stat/cmd/gokr-stat \
	github.com/gokrazy/mkfs \
	github.com/gokrazy/wifi \
	tailscale.com/cmd/tailscaled \
	tailscale.com/cmd/tailscale \
	github.com/mdlayher/consrv/cmd/consrv

all:

.PHONY: update overwrite

update:
	${PACKER} -update=yes ${PKGS}

overwrite:
	${PACKER} -overwrite=/dev/sdx ${PKGS}

```

For the initial install, plug the SD card into your computer, put its device
name into the `overwrite` target, and run `make overwrite`.

For subsequent changes, you can use `make update`.

### Tailscale

Tailscale is a peer-to-peer mesh VPN, meaning we can use it to connect to our
`consrv` Raspberry Pi from anywhere in the world, without having to set up port
forwardings, dynamic DNS, or similar.

As an added bonus, Tailscale also transparently fails over between connections,
so while the fast ethernet/fiber connection works, Tailscale uses that,
otherwise it uses the Out Of Band network.

Follow [the gokrazy guide on Tailscale](https://gokrazy.org/packages/tailscale/)
to include the device in your Tailscale mesh VPN.

### WiFi internet connection and dual homing

Setup WiFi:

```shell
mkdir -p extrafiles/github.com/gokrazy/wifi/etc
cat '{"ssid": "oob", "psk": "secret"}' \
  > extrafiles/github.com/gokrazy/wifi/etc/wifi.json
```

`consrv` should use the Out Of Band mobile uplink to reach the internet. At the
same time, it should still be usable from my home network, too, to make gokrazy
updates go quickly.

We accomplish this using route priorities.

I arranged for the WiFi interface to have higher route priority (5) than the
ethernet interface (typically 1, but 11 in our setup thanks to the
`-extra_route_priority=10` flag):

```shell
mkdir -p flags/github.com/gokrazy/gokrazy/cmd/dhcp
echo '-extra_route_priority=10' \
  > flags/github.com/gokrazy/gokrazy/cmd/dhcp/flags.txt
make update
```

Now, `tailscale netcheck` shows an IPv4 address belonging to Sunrise, the mobile
network provider behind the digitec iot subscription.

### The consrv Console Server

[`consrv`](https://github.com/mdlayher/consrv) is an SSH serial console server
written in Go that Matt Layher and I developed. If you’re curious, you can watch
the two of us creating it in this twitch stream recording:

{{< youtube 1g46ei9aBH0 >}}

The installation of `consrv` consists of two steps.

Step 1 is done: we already included `consrv` in the `Makefile` earlier in
[gokrazy setup](#gokrazy-setup).

So, we only need to configure the desired serial ports in `consrv.toml` (in
[gokrazy extrafiles](https://gokrazy.org/userguide/package-config/#extrafiles)):

```shell
mkdir -p extrafiles/github.com/mdlayher/consrv/cmd/consrv/etc/consrv
cat > extrafiles/github.com/mdlayher/consrv/cmd/consrv/etc/consrv/consrv.toml <<'EOT'
[server]
address = ":2222"

[[devices]]
serial = "01716A92"
name = "router7"
baud = 115200
logtostdout = true

[[identities]]
name = "michael"
public_key = "ssh-ed25519 AAAAC3… michael@midna"
EOT
```

Run `make update` to deploy the configuration to your device.

If everything is set up correctly, we can now start a serial console session via
SSH:

```text
midna% ssh -p 2222 router7@consrv.lan
Warning: Permanently added '[consrv.lan]:2222' (ED25519) to the list of known hosts.
consrv> opened serial connection "router7": path: "/dev/ttyUSB0", serial: "01716A92", baud: 115200
2022/06/19 20:50:47 dns.go:175: probe results: [{upstream: [2001:4860:4860::8888]:53, rtt: 999.665µs} {upstream: [2001:4860:4860::8844]:53, rtt: 2.041079ms} {upstream: 8.8.8.8:53, rtt: 2.073279ms} {upstream: 8.8.4.4:53, rtt: 16.200959ms}]
[…]
```

I’m using the `logtostdout` option to make `consrv` continuously read the serial
port and send it to `stdout`, which gokrazy in turn [sends via remote
syslog](https://gokrazy.org/userguide/remotesyslog/) to the [gokrazy syslog
daemon](https://github.com/gokrazy/syslogd), running on another machine. You
could also run it on the same machine if you want to log to file.

{{< note >}}

There is an [open issue in
`consrv`](https://github.com/mdlayher/consrv/issues/3) regarding the failure
mode when a serial adapter disappears. Currently, `consrv` hangs until you try
to send something, then must be restarted. A workaround is available in the
GitHub issue.

{{< /note >}}

### Controlling Tasmota from breakglass

You can use [`breakglass`](https://github.com/gokrazy/breakglass) to
interactively log into your gokrazy installation.

If you flashed your Smart Plug with Tasmota, you can easily turn power on from a
breakglass shell by directly calling Tasmota’s HTTP API with `curl`:

```
% breakglass consrv
consrv# curl -v -X POST --data 'cmnd=power on' http://tasmota_68462f-1583/cm
```

The original Sonoff firmware offers a DIY mode which should also offer an HTTP
API, but the [DIY mode did not work in my
tests](https://twitter.com/zekjur/status/1321949087160258562). Hence, I’m only
describing how to do it with Tasmota.

### Optional: Local MQTT Server

Personally, I like having the Smart Plug available both on the local network
(via Tasmota’s HTTP API) and via the internet with an external MQTT server. That
way, even if either option fails, I still have a way to toggle power remotely.

But, maybe you want to obtain usage stats by listening to MQTT or similar, and
you don’t want to use an extra server for this. In that situation, you can
easily run a local MQTT server on your Pi.

In the gokrazy `Makefile`, add
[`github.com/fhmq/hmq`](https://github.com/fhmq/hmq) to the list of packages to
install, and configure Tasmota to connect to `consrv` on port 1883.

To check that everything is working, use `mosquitto_sub` from another machine:

```
midna% mosquitto_sub --verbose -h consrv.monkey-turtle.ts.net -t '#'
```

## Conclusion

digitec’s IOT mobile internet subscription makes remote power management
delightfully easy with a smart plug and 4G WiFi router, and affordable
enough. The subscription is flexible enough that you can decide to only book it
while you’re traveling.

We can elevate the whole setup in functionality (but also complexity) by
combining Tailscale, consrv and gokrazy, running on a Raspberry Pi Zero 2 W, and
connecting a USB-to-serial adapter.

If you need more features than that, check out the next step on the feature and
complexity ladder: [PiKVM](https://pikvm.org/) or
[TinyPilot](https://tinypilotkvm.com/). See also [this comparison by Jeff
Geerling](https://www.jeffgeerling.com/blog/2021/raspberry-pi-kvms-compared-tinypilot-and-pi-kvm-v3).

## Appendix A: Unstable Apple USB ethernet adapter

The first USB ethernet adapter I tried was the [Apple USB Ethernet
Adapter](https://www.artcomputer.ch/b2c_en/apple-usb-ethernet-adapter-a00004961/).

Unfortunately, after a few days of uptime, I experienced the following kernel
driver crash (with the `asix` Linux driver), and the link remained down until I
rebooted.

I then switched to a [Linksys
USB3GIG](https://www.linksys.com/support-product?sku=USB3GIG) network adapter
(supported by the `r8152` Linux driver) and did not see any problems with that
so far.

<details>
<summary>kernel crash message (in dmesg)</summary>

```
dwc2 3f980000.usb: dwc2_hc_chhltd_intr_dma: Channel 5 - ChHltd set, but reason is unknown
dwc2 3f980000.usb: hcint 0x00000002, intsts 0x04600009
dwc2 3f980000.usb: dwc2_update_urb_state_abn(): trimming xfer length
asix 1-1.4:1.0 eth0: Failed to read reg index 0x0000: -71
------------[ cut here ]------------
WARNING: CPU: 1 PID: 7588 at drivers/net/phy/phy.c:942 phy_error+0x10/0x58
Modules linked in: brcmfmac brcmutil
CPU: 1 PID: 7588 Comm: kworker/u8:2 Not tainted 5.18.3 #1
Hardware name: Raspberry Pi Zero 2 W Rev 1.0 (DT)
Workqueue: events_power_efficient phy_state_machine
pstate: 80000005 (Nzcv daif -PAN -UAO -TCO -DIT -SSBS BTYPE=--)
pc : phy_error+0x10/0x58
lr : phy_state_machine+0x258/0x2b0
sp : ffff800009fe3d40
x29: ffff800009fe3d40 x28: 0000000000000000 x27: ffff6c7ac300c078
x26: ffff6c7ac300c000 x25: ffff6c7ac4390000 x24: 00000000ffffffb9
x23: 0000000000000004 x22: ffff6c7ac4019cd8 x21: ffff6c7ac4019800
x20: ffffce5c97f6f000 x19: ffff6c7ac4019800 x18: 0000000000000010
x17: 0000000400000000 x16: 0000000000000000 x15: 0000000000001007
x14: ffff800009fe3810 x13: 00000000ffffffea x12: 00000000fffff007
x11: fffffffffffe0290 x10: fffffffffffe0240 x9 : ffffce5c988e1018
x8 : c0000000fffff007 x7 : 00000000000000a8 x6 : ffffce5c98889280
x5 : 0000000000000268 x4 : ffff6c7acf392b80 x3 : ffff6c7ac4019cd8
x2 : 0000000000000000 x1 : 0000000000000000 x0 : ffff6c7ac4019800
Call trace:
 phy_error+0x10/0x58
 phy_state_machine+0x258/0x2b0
 process_one_work+0x1e4/0x348
 worker_thread+0x48/0x418
 kthread+0xf4/0x110
 ret_from_fork+0x10/0x20
---[ end trace 0000000000000000 ]---
asix 1-1.4:1.0 eth0: Link is Down
```

</details>
