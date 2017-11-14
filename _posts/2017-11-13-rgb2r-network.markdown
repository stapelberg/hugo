---
layout: post
title:  "Network setup for our retro computing event RGB2Rv17"
date:   2017-11-13 22:45:00 +01:00
categories: Artikel
---

Our computer association [NoName e.V.](https://www.noname-ev.de/) organizes a
retro computing event called [RGB2R](https://rgb2r.noname-ev.de/) every year,
located in Heidelberg, Germany. This year’s version is called RGB2Rv17.

This article describes the network setup I created for this year’s event.

The intention is not so much to provide a fully working setup (even though the
setup did work fine for us as-is), but rather inspire to you to create your own
network, based vaguely on what’s provided here.

### Connectivity

The venue has a DSL connection with speeds reaching 1 Mbit/s if you’re
lucky. Needless to say, that is not sufficient for the about 40 participants we
had.

Luckily, there is (almost) direct line of sight to my parent’s place, and my dad
recently got a 400 Mbit/s cable internet connection, which he’s happy to share
with us :-).

### Hardware

For the WiFi links to my parent’s place, we used 2 [tp-link
CPE510](http://www.tp-link.com/us/products/details/cat-37_CPE510.html) (CPE
stands for Customer Premise Equipment) on each site. The devices only have 100
Mbit/s ethernet ports, which is why we used two of them.

The edge router for the event venue was a [PC Engines
apu2c4](https://pcengines.ch/apu2c4.htm). For the Local Area Network (LAN)
within the venue, we provided a few switches and WiFi using [Ubiquiti
Networks](https://www.ubnt.com/) access points.

### Software

On the apu2c4, I installed Debian “stretch” 9, the latest Debian stable version
at the time of writing. I prepared a USB thumb drive with the netinst image:

```
% wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.2.1-amd64-netinst.iso
% cp debian-9.2.1-amd64-netinst.iso /dev/sdb
```

Then, I…

* plugged the USB thumb drive into the apu2c4
* On the serial console, pressed F10 (boot menu), then 1 (boot from USB)
* In the Debian installer, selected Help, pressed F6 (special boot parameters), entered `install console=ttyS0,115200n8`
* installed Debian as usual.

#### Initial setup

Debian stretch comes with systemd by default, but not with
[`systemd-networkd(8)`](https://manpages.debian.org/stretch/systemd/systemd-networkd.8.en.html)
by default, so I changed that:
```
edge# systemctl enable systemd-networkd
edge# systemctl disable networking
```

Also, I cleared the MOTD, placed `/tmp` on `tmpfs` and configured my usual
environment:

```
edge# echo > /etc/motd
edge# echo 'tmpfs /tmp tmpfs defaults 0 0' >> /etc/fstab
edge# wget -qO- https://d.zekjur.net | bash -s
```

I also installed a few troubleshooting tools which came in handy later:

```
edge# apt install tcpdump net-tools strace
```

#### Disabling ICMP rate-limiting for debugging

I had to learn the hard way that Linux imposes a rate-limit on outgoing ICMP
packets by default. This manifests itself as spurious timeouts in the
`traceroute` output. To ease debugging, I disabled the rate limit entirely:

```
edge# cat >> /etc/sysctl.conf <<'EOT'
net.ipv4.icmp_ratelimit=0
net.ipv6.icmp.ratelimit=0
EOT
edge# sysctl -p
```

#### Renaming network interfaces

Descriptive network interface names are helpful when debugging. I won’t remember
whether `enp0s3` is the interface for an uplink or the LAN, so I assigned the
names `uplink0`, `uplink1` and `lan0` to the apu2c4’s interfaces.

To rename network interfaces, I created a corresponding `.link` file, had the
initramfs pick it up, and rebooted:

```
edge# cat >/etc/systemd/network/10-uplink0.link <<'EOT'
[Match]
MACAddress=00:0d:b9:49:db:18

[Link]
Name=uplink0
EOT
edge# update-initramfs -u
edge# reboot
```

### Network topology

Because our internet provider didn’t offer IPv6, and to keep my dad out of the
loop in case any abuse issues should arise, we tunneled all of our traffic.

We decided to set up one tunnel per WiFi link, so that we could easily
load-balance over the two links by routing IP flows into one of the two tunnels.

Here’s a screenshot from the topology dashboard which I made using the
[Diagram](https://grafana.com/plugins/jdbranham-diagram-panel) Grafana plugin:

<img src="/Bilder/rgb2rv17-network-topology.jpg" width="943" height="536">

### Network interface setup

We configured IP addresses statically on the `uplink0` and `uplink1` interface
because we needed to use static addresses in the tunnel setup anyway.

Note that we placed a default route in route table 110. Later on, we used
[`iptables(8)`](https://manpages.debian.org/stretch/iptables/iptables.8.en.html)
to make traffic use either of these two default routes.

```
edge# cat > /etc/systemd/network/uplink0.network <<'EOT'
[Match]
Name=uplink0

[Network]
Address=192.168.178.10/24
IPForward=ipv4

[Route]
Gateway=192.168.178.1
Table=110
EOT
```

```
edge# cat > /etc/systemd/network/uplink1.network <<'EOT'
[Match]
Name=uplink1

[Network]
Address=192.168.178.11/24
IPForward=ipv4

[Route]
Gateway=192.168.178.1
Table=111
EOT
```

### Tunnel setup

Originally, I configured OpenVPN for our tunnels. However, it turned out the
apu2c4 tops out at 130 Mbit/s of traffic through OpenVPN. Notably, using two
tunnels didn’t help — I couldn’t reach more than 130 Mbit/s in total. This is
with authentication and crypto turned off.

This surprised me, but doesn’t seem too uncommon: on the internet, I could find
reports of similar speeds with the same hardware.

Given that our setup didn’t require cryptography (applications are using TLS
these days), I looked for light-weight alternatives and found Foo-over-UDP
(fou), a UDP encapsulation protocol supporting IPIP, GRE and SIT tunnels.

Each configured Foo-over-UDP tunnel only handles sending packets. For receiving,
you need to configure a listening port. If you want two machines to talk to each
other, you therefore need a listening port on each, and a tunnel on each.

Note that you need one tunnel per address family: IPIP only supports IPv4, SIT
only supports IPv6. In total, we ended up with 4 tunnels (2 WiFi uplinks with 2
address families each).

Also note that Foo-over-UDP provides no authentication: anyone who is able to
send packets to your configured listening port can spoof any IP address. If you
don’t restrict traffic in some way (e.g. by source IP), you are effectively
running an open proxy.

#### Tunnel configuration

First, load the kernel modules and set the corresponding interfaces to UP:
```
edge# modprobe fou
edge# modprobe ipip
edge# ip link set dev tunl0 up
edge# modprobe sit
edge# ip link set dev sit0 up
```

Configure the listening ports for receiving FOU packets:
```
edge# ip fou add port 1704 ipproto 4
edge# ip fou add port 1706 ipproto 41

edge# ip fou add port 1714 ipproto 4
edge# ip fou add port 1716 ipproto 41
```

Configure the tunnels for sending FOU packets, using the local interface of the
`uplink0` interface:
```
edge# ip link add name fou0v4 type ipip remote 203.0.113.1 local 192.168.178.10 encap fou encap-sport auto encap-dport 1704 dev uplink0
edge# ip link set dev fou0v4 up
edge# ip -4 address add 10.170.0.1/24 dev fou0v4

edge# ip link add name fou0v6 type sit remote 203.0.113.1 local 192.168.178.10 encap fou encap-sport auto encap-dport 1706 dev uplink0
edge# ip link set dev fou0v6 up
edge# ip -6 address add fd00::10:170:0:1/112 dev fou0v6 preferred_lft 0
```
Repeat for the `uplink1` interface:
```
# (IPv4) Set up the uplink1 transmit tunnel:
edge# ip link add name fou1v4 type ipip remote 203.0.113.1 local 192.168.178.11 encap fou encap-sport auto encap-dport 1714 dev uplink1
edge# ip link set dev fou1v4 up
edge# ip -4 address add 10.171.0.1/24 dev fou1v4

# (IPv6) Set up the uplink1 transmit tunnel:
edge# ip link add name fou1v6 type sit remote 203.0.113.1 local 192.168.178.11 encap fou encap-sport auto encap-dport 1716 dev uplink1
edge# ip link set dev fou1v6 up
edge# ip -6 address add fd00::10:171:0:1/112 dev fou1v6 preferred_lft 0
```

### Load-balancing setup

In previous years, we experimented with setups using MLVPN for load-balancing
traffic on layer 2 across multiple uplinks. Unfortunately, we weren’t able to
get good results: when aggregating links, bandwidth would be limited to the
slowest link. I expect that MLVPN and others would work better this year, if we
were to set it up directly before and after the WiFi uplinks, as the two links
should be almost identical in terms of latency and throughput.

Regardless, we didn’t want to take any chances and decided to go with IP flow
based load-balancing. The downside is that any individual connection can never
be faster than the uplink over which it is routed. Given the number of
concurrent connections in a typical network, in practice we observed good
utilization of both links regardless.

Let’s tell iptables to mark packets coming from the LAN with one of two values
based on the hash of their source IP, source port, destination IP and
destination port properties:

```
edge# iptables -t mangle -A PREROUTING -s 10.17.0.0/24 -j HMARK --hmark-tuple src,sport,dst,dport --hmark-mod 2 --hmark-offset 10 --hmark-rnd 0xdeadbeef
```

Note that the `--hmark-offset` parameter is required: mark 0 is the default, so
you need an offset of at least 1.

For debugging, it is helpful to exempt the IP addresses we use on the tunnels
themselves, otherwise we might not be able to ping an endpoint which is actually
reachable:

```
edge# iptables -t mangle -A PREROUTING -s 10.17.0.0/24 -d 10.170.0.0/24 -m comment --comment "for debugging" -j MARK --set-mark 10
edge# iptables -t mangle -A PREROUTING -s 10.17.0.0/24 -d 10.171.0.0/24 -m comment --comment "for debugging" -j MARK --set-mark 11
```

Now, we need to add a routing policy to select the correct default route based
on the firewall mark:
```
edge# ip -4 rule add fwmark 10 table 10
edge# ip -4 rule add fwmark 11 table 11
```

The steps for IPv6 are identical.

Note that current OpenWrt (15.05) does not provide the HMARK iptables module. I
filed [a GitHub issue with OpenWrt](https://github.com/openwrt/openwrt/issues/572).

#### Connectivity for the edge router

Because our default routes are placed in table 110 and 111, the router does not
have upstream connectivity. This is mostly working as intended, as it makes it
harder to accidentally route traffic outside of the tunnels.

There is one exception: we need a route to our DNS server:

```
edge# ip -4 rule add to 8.8.8.8/32 lookup 110
```

It doesn’t matter which uplink we use for that, since DNS traffic is tiny.

#### Connectivity to the tunnel endpoint

Of course, the tunnel endpoint itself must also be reachable:

```
edge# ip rule add fwmark 110 lookup 110
edge# ip rule add fwmark 111 lookup 111

edge# iptables -t mangle -A OUTPUT -d 203.0.113.1/32 -p udp --dport 1704 -j MARK --set-mark 110
edge# iptables -t mangle -A OUTPUT -d 203.0.113.1/32 -p udp --dport 1714 -j MARK --set-mark 111
edge# iptables -t mangle -A OUTPUT -d 203.0.113.1/32 -p udp --dport 1706 -j MARK --set-mark 110
edge# iptables -t mangle -A OUTPUT -d 203.0.113.1/32 -p udp --dport 1716 -j MARK --set-mark 111
```

#### Connectivity to the access points

By clearing the firewall mark, we ensure traffic doesn’t get sent through our
tunnel:

```
edge# iptables -t mangle -A PREROUTING -s 10.17.0.0/24 -d 192.168.178.250 -j MARK --set-mark 0 -m comment --comment "for debugging"
edge# iptables -t mangle -A PREROUTING -s 10.17.0.0/24 -d 192.168.178.251 -j MARK --set-mark 0 -m comment --comment "for debugging"
edge# iptables -t mangle -A PREROUTING -s 10.17.0.0/24 -d 192.168.178.252 -j MARK --set-mark 0 -m comment --comment "for debugging"
edge# iptables -t mangle -A PREROUTING -s 10.17.0.0/24 -d 192.168.178.253 -j MARK --set-mark 0 -m comment --comment "for debugging"
```

Also, since the access points are all in the same subnet, we need to tell Linux
on which interface to send the packets, otherwise packets might egress on the
wrong link:

```
edge# ip -4 route add 192.168.178.252 dev uplink0 src 192.168.178.10
edge# ip -4 route add 192.168.178.253 dev uplink1 src 192.168.178.11
```

#### MTU configuration

```
edge# ifconfig uplink0 mtu 1472
edge# ifconfig uplink1 mtu 1472
edge# ifconfig fou0v4 mtu 1416
edge# ifconfig fou0v6 mtu 1416
edge# ifconfig fou1v4 mtu 1416
edge# ifconfig fou1v6 mtu 1416
```

#### For maintenance: temporarily use only one uplink

It might come in handy to quickly be able to disable an uplink, be it for
diagnosing issues, performing maintenance on a link, or to work around a broken
uplink.

Let’s create a separate iptables chain in which we can place temporary
overrides:

```
edge# iptables -t mangle -N prerouting_override
edge# iptables -t mangle -A PREROUTING -j prerouting_override
edge# ip6tables -t mangle -N prerouting_override
edge# ip6tables -t mangle -A PREROUTING -j prerouting_override
```

With the following shell script, we can then install such an override:

```
#!/bin/bash
# vim:ts=4:sw=4
# enforces using a single uplink
# syntax:
#	./uplink.sh 0  # use only uplink0
#	./uplink.sh 1  # use only uplink1
#	./uplink.sh    # use both uplinks again

if [ "$1" = "0" ]; then
	# Use only uplink0
	MARK=10
elif [ "$1" = "1" ]; then
	# Use only uplink1
	MARK=11
else
	# Use both uplinks again
	iptables -t mangle -F prerouting_override
	ip6tables -t mangle -F prerouting_override
	ip -4 rule del to 8.8.8.8/32
	ip -4 rule add to 8.8.8.8/32 lookup "110"
	exit 0
fi

iptables -t mangle -F prerouting_override
iptables -t mangle -A prerouting_override -s 10.17.0.0/24 -j MARK --set-mark "${MARK}"
ip6tables -t mangle -F prerouting_override
ip6tables -t mangle -A prerouting_override -j MARK --set-mark "${MARK}"

ip -4 rule del to 8.8.8.8/32
ip -4 rule add to 8.8.8.8/32 lookup "1${MARK}"
```

### MSS clamping

Because Path MTU discovery is often broken on the internet, it’s best practice
to limit the Maximum Segment Size (MSS) of each TCP connection, achieving the
same effect (but only for TCP connections).

This technique is called “MSS clamping”, and can be implemented in Linux like
so:

```
edge# iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o fou0v4 -j TCPMSS --clamp-mss-to-pmtu
edge# iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o fou1v4 -j TCPMSS --clamp-mss-to-pmtu
edge# ip6tables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o fou0v6 -j TCPMSS --clamp-mss-to-pmtu
edge# ip6tables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o fou1v6 -j TCPMSS --clamp-mss-to-pmtu
```

### Traffic shaping

#### Shaping upstream

With asymmetric internet connections, such as the 400/20 cable connection we’re
using, it’s necessary to shape traffic such that the upstream is never entirely
saturated, otherwise the TCP ACK packets won’t reach their destination in time
to saturate the downstream.

While the FritzBox might already provide traffic shaping, we wanted to
voluntarily restrict our upstream usage to leave some headroom for my parents.

Hence, we’re shaping each uplink to 8 Mbit/s, which sums up to 16 Mbit/s, well
below the available 20 Mbit/s:

```
edge# tc qdisc replace dev uplink0 root tbf rate 8mbit latency 50ms burst 4000
edge# tc qdisc replace dev uplink1 root tbf rate 8mbit latency 50ms burst 4000
```

The specified `latency` value is a best guess, and the `burst` value is derived
from the kernel internal timer frequency (`CONFIG_HZ`) (!), packet size and rate
as per
[https://unix.stackexchange.com/questions/100785/bucket-size-in-tbf](https://unix.stackexchange.com/questions/100785/bucket-size-in-tbf).

Tip: keep in mind to disable shaping temporarily when you’re doing bandwidth
tests ;-).

#### Shaping downstream

It’s somewhat of a mystery to me why this helped, but we achieved noticeably
better bandwidth (50 Mbit/s without, 100 Mbit/s with shaping) when we also
shaped the downstream traffic (i.e. made the tunnel endpoint shape traffic).

### LAN

For DHCP, DNS and IPv6 router advertisments, we set up
[`dnsmasq(8)`](https://manpages.debian.org/stretch/dnsmasq-base/dnsmasq.8.en.html),
which worked beautifully and was way quicker to configure than the bigger ISC
servers:

```
edge# apt install dnsmasq
edge# cat > /etc/dnsmasq.d/rgb2r <<'EOT'
interface=lan0
dhcp-range=10.17.0.10,10.17.0.250,30m
dhcp-range=::,constructor:lan0,ra-only
enable-ra
cache-size=10000
EOT
```

### Monitoring

First, install and start Prometheus:

```
edge# apt install prometheus prometheus-node-exporter prometheus-blackbox-exporter
edge# systemctl enable prometheus
edge# systemctl restart prometheus
edge# systemctl enable prometheus-node-exporter
edge# systemctl restart prometheus-node-exporter
edge# systemctl enable prometheus-blackbox-exporter
edge# systemctl restart prometheus-blackbox-exporter
```

Then, install and start Grafana:

```
edge# apt install apt-transport-https
edge# wget -qO- https://packagecloud.io/gpg.key | apt-key add -
edge# echo deb https://packagecloud.io/grafana/stable/debian/ stretch main > /etc/apt/sources.list.d/grafana.list
edge# apt update
edge# apt install grafana
edge# systemctl enable grafana-server
edge# systemctl restart grafana-server
```

Also, install the excellent
[Diagram](https://grafana.com/plugins/jdbranham-diagram-panel) Grafana plugin:

```
edge# grafana-cli plugins install jdbranham-diagram-panel
edge# systemctl restart grafana-server
```

### Config files

I realize this post contains a lot of configuration excerpts which might be hard
to put together. So, you can [find all the config files in a git
repository](http://code.stapelberg.de/git/rgb2rv17-network-setup/). As I
mentioned at the beginning of the article, please create your own network and
don’t expect the config files to just work out of the box.

### Statistics

* We peaked at about 60 active DHCP leases.

* The connection tracking table (holding an entry for each IPv4 connection)
  never exceeded 4000 connections.

* DNS traffic peaked at about 12 queries/second.

* dnsmasq’s maximum cache size of 10000 records was sufficient: we did not have
  a single cache eviction over the entire event.

* We were able to obtain peaks of over 150 Mbit/s of download traffic.

* At peak, about 10% of our traffic was IPv6.

### WiFi statistics

* On link 1, our signal to noise ratio hovered between 31 dBm to 33 dBm. When it
  started raining, it dropped by 2-3 dBm.

* On link 2, our signal to noise ratio hovered between 34 dBm to 36 dBm. When it
  started raining, it dropped by 1 dBm.

Despite the relatively bad signal/noise ratios, we could easily obtain about 140
Mbps on the WiFi layer, which results in 100 Mbps on the ethernet layer.

The difference in signal/noise ratio between the two links had no visible impact
on bandwidth, but ICMP probes showed measurably more packet loss on link 1.