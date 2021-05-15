---
layout: post
title:  "Home network 10 Gbit/s upgrade"
date:   2021-05-16 17:33:16 +02:00
categories: Artikel
tags:
- fiber
---

After [adding a fiber link to my home
network](/posts/2020-08-09-fiber-link-home-network/), I am upgrading that link
from 1 Gbit/s to 10 Gbit/s.

As a reminder, conceptually the fiber link is built using two media converters
from/to ethernet:

{{< img src="2020-08-04-media-converters.jpg" alt="0.9mm thin fiber cables" >}}

Schematically, this is what’s connected to both ends:

{{< img src="2021-05-15-bottleneck-1g.svg" alt="1 Gbit/s bottleneck" >}}

All links are 1 Gbit/s, so it’s easy to see that, for example, transfers between
chuchi↔router7 and storage2↔midna cannot both use 1 Gbit/s at the same time.

This upgrade serves 2 purposes:

1. **Raise the floor to 1 Gbit/s end-to-end**: Ensure that serving large files
   (e.g. distri Linux images and packages) does no longer impact, and is no
   longer impacted by, other bandwidth flows that also use this transfer link in
   my home network, e.g. daily backups.

1. **Raise the ceiling to 10 Gbit/s**: Make it possible to selectively upgrade
   Linux PCs on either end of the link to 10 Gbit/s peak bandwidth.

Note that the internet uplink remains untouched at 1 Gbit/s — only transfers
within the home network can happen at 10 Gbit/s.

## Replacing the media converters with Mikrotik switches

We first replace both media converters and switches with a [Mikrotik
CRS305-1G-4S+IN](https://mikrotik.com/product/crs305_1g_4s_in).

{{< img src="2020-07-30-mikrotiks-featured.jpg" alt="Mikrotik CRS305-1G-4S+IN" >}}

This device [costs 149 CHF on digitec](https://www.digitec.ch/de/s1/product/mikrotik-crs305-1g-4sin-5ports-switch-9876046) and comes with 5 ports:

* 1 × RJ45 Ethernet port for management, can be used as a regular 1 Gbit/s port.
* 4 × SFP+ ports

Each SFP+ port can be used with either an RJ-45 Ethernet or a fiber SFP+
module.

## Fiber module upgrade

I’m using 10 Gbit/s fiber SFP+ modules for the fiber link between my kitchen and
living room.

To make use of the 10 Gbit/s link between the switches, all devices that should
get their guaranteed 1 Gbit/s end-to-end connection need to be connected
directly to a Mikrotik switch.

I’m connecting all PCs to the switch with RJ45 SFP+ modules for two reasons:

1. My [Intel
   X550-T2](https://www.digitec.ch/de/s1/product/intel-x550-t2-pci-express-30-netzwerkadapter-5926807)
   PCIe 10 Gbit/s network cards use RJ45.
1. The SFP+ modules are backwards-compatible and can be used with 1 Gbit/s RJ45
   devices, too, which makes for a nice incremental upgrade path.

The resulting list of SFP modules used in the two Mikrotik switches looks like
so:

| Mikrotik 1 SFP | speed     |                     | speed     | Mikrotik 2 SFP |
|----------------|-----------|---------------------|-----------|----------------|
| chuchi         | 10 Gbit/s |                     | 10 Gbit/s | midna          |
| storage2       | 1 Gbit/s  |                     | 1 Gbit/s  | router7        |
|                | 10 Gbit/s | ⬅ BiDi fiber link ➡ | 10 Gbit/s |                |

## Hardware sourcing

The total cost of this upgrade is 1241 CHF, with the biggest chunk spent on the
Intel X550-T2 network cards. You can most likely find 10 Gbit/s network cards
for cheaper, but I wanted something readily available with no doubts about Linux
compatibility.

### FS (Fiber Store) order

[FS.COM](https://www.FS.COM) was my go-to source for anything
fiber-related. Everything they have is very affordable, and products in stock at
their German warehouse arrive in Switzerland (and presumably other European
countries, too) within the same week.

| num | price  | name                                                                                                                                                            |
|-----|--------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 × | 34 CHF | [Generic Compatible 10GBASE-BX BiDi SFP+ 1270nm-TX/1330nm-RX 10km DOM Transceiver Module, FS P/N: SFP-10G-BX #74681](https://www.fs.com/de/products/74681.html) |
| 1 × | 34 CHF | [Generic Compatible 10GBASE-BX BiDi SFP+ 1330nm-TX/1270nm-RX 10km DOM Transceiver Module, FS P/N: SFP-10G-BX #74682](https://www.fs.com/de/products/74682.html) |
| 4 × | 56 CHF | [SFP+ Transceiver Modul - Generisch kompatibel 10GBASE-T SFP+ Kupfer RJ-45 30m, FS P/N: SFP-10G-T #74680](https://www.fs.com/de/products/74680.html)            |

### digitec order

There are a few items that [FS.COM](https://www.FS.COM) doesn’t stock. These I
bought at [digitec](https://www.digitec.ch/), a big and popular electronics
store in Switzerland. My thinking is that if products are available at digitec,
they most likely are available at your preferred big electronics store, too.

| num | price    | name                                                                                                                                      |
|-----|----------|-------------------------------------------------------------------------------------------------------------------------------------------|
| 2 × | 317 CHF  | [Intel X550-T2 (PCI Express 3.0)](https://www.digitec.ch/de/s1/product/intel-x550-t2-pci-express-30-netzwerkadapter-5926807) network card |
| 2 × | 149 CHF  | [Mikrotik CRS305-1G-4S+IN](https://www.digitec.ch/de/s1/product/mikrotik-crs305-1g-4sin-5ports-switch-9876046) switch                     |
| 2 × | 8.65 CHF | [Lindy Cat 6 Ethernet network cables](https://www.digitec.ch/de/s1/product/lindy-netzwerkkabel-sftp-kat-6-200cm-netzwerkkabel-630147)     |

## Mikrotik switch setup

I want to use my switches only as switches, not for any routing or other layer 3
features that might reduce bandwidth, so I first reboot the [MikroTik
CRS305-1G-4S+](https://mikrotik.com/product/crs305_1g_4s_in) into SwOS:

1. In the web interface menu, navigate to <em>System → Routerboard →
   Settings</em>, open the <em>Boot OS</em> drop-down and select option
   <em>SwOS</em>.

1. In the web interface menu, navigate to <em>System → Reboot</em>.

1. After the device rebooted, change the hostname which was reset to `MikroTik`.

Next, upgrade the firmware to 2.12 to fix a weird issue with certain
combinations of SFP modules (SFP-10G-BX in SFP1, SFP-10G-T in SFP2):

1. In the SwOS web interface, select the <em>Upgrade</em> tab, then click
   <em>Download & Upgrade</em>.

## Network card setup (Linux)

After booting with the Intel X550-T2 in a PCIe slot, the card should show up in
{{< man name="dmesg" section="8" >}}:

{{< highlight text "hl_lines=3 8" >}}
ixgbe: Intel(R) 10 Gigabit PCI Express Network Driver
ixgbe 0000:03:00.0: Multiqueue Enabled: Rx Queue count = 16, Tx Queue count = 16 XDP Queue count = 0
ixgbe 0000:03:00.0: 31.504 Gb/s available PCIe bandwidth (8.0 GT/s PCIe x4 link)
ixgbe 0000:03:00.0: MAC: 4, PHY: 0, PBA No: H86377-006
ixgbe 0000:03:00.0: Intel(R) 10 Gigabit Network Connection
libphy: ixgbe-mdio: probed
ixgbe 0000:03:00.1: Multiqueue Enabled: Rx Queue count = 16, Tx Queue count = 16 XDP Queue count = 0
ixgbe 0000:03:00.1: 31.504 Gb/s available PCIe bandwidth (8.0 GT/s PCIe x4 link)
ixgbe 0000:03:00.1: MAC: 4, PHY: 0, PBA No: H86377-006
tun: Universal TUN/TAP device driver, 1.6
ixgbe 0000:03:00.1: Intel(R) 10 Gigabit Network Connection
libphy: ixgbe-mdio: probed
ixgbe 0000:03:00.0 enp3s0f0: renamed from eth0
ixgbe 0000:03:00.1 enp3s0f1: renamed from eth1
pps pps0: new PPS source ptp1
ixgbe 0000:03:00.0: registered PHC device on enp3s0f0
pps pps1: new PPS source ptp2
ixgbe 0000:03:00.1: registered PHC device on enp3s0f1
{{< /highlight >}}

I think if you only use 1 of the card’s 4 network ports, you might not hit any
bottlenecks even when running the card only at [PCIe 3.0 ×2 link
speed](https://en.wikipedia.org/wiki/PCI_Express#History_and_revisions), but I
haven’t verified this!

Another way to verify the device is running at maximum speed on the computer’s
PCIe bus, is to ensure `LnkSta` matches `LnkCap` in the {{< man name="lspci"
section="8" >}} output:

{{< highlight text "hl_lines=8 12" >}}
% sudo lspci -vv
[…]
03:00.0 Ethernet controller: Intel Corporation Ethernet Controller 10G X550T (rev 01)
        Subsystem: Intel Corporation Ethernet Converged Network Adapter X550-T2
[…]
        Capabilities: [a0] Express (v2) Endpoint, MSI 00
[…]
                LnkCap: Port #0, Speed 8GT/s, Width x4, ASPM L0s L1, Exit Latency L0s <2us, L1 <16us
                        ClockPM- Surprise- LLActRep- BwNot- ASPMOptComp+
                LnkCtl: ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
                        ExtSynch- ClockPM- AutWidDis- BWInt- AutBWInt-
                LnkSta: Speed 8GT/s (ok), Width x4 (ok)
                        TrErr- Train- SlotClk+ DLActive- BWMgmt- ABWMgmt-
[…]
{{< /highlight >}}



You can verify your network link is running at 10 Gbit/s using {{< man
name="ethtool" section="8" >}}:

{{< highlight text "hl_lines=6 18" >}}
% sudo ethtool enp3s0f1 
Settings for enp3s0f1:
	Supported ports: [ TP ]
	Supported link modes:   100baseT/Full
	                        1000baseT/Full
	                        10000baseT/Full
	                        2500baseT/Full
	                        5000baseT/Full
	Supported pause frame use: Symmetric
	Supports auto-negotiation: Yes
	Supported FEC modes: Not reported
	Advertised link modes:  100baseT/Full
	                        1000baseT/Full
	                        10000baseT/Full
	Advertised pause frame use: Symmetric
	Advertised auto-negotiation: Yes
	Advertised FEC modes: Not reported
	Speed: 10000Mb/s
	Duplex: Full
	Auto-negotiation: on
	Port: Twisted Pair
	PHYAD: 0
	Transceiver: internal
	MDI-X: Unknown
	Supports Wake-on: d
	Wake-on: d
        Current message level: 0x00000007 (7)
                               drv probe link
	Link detected: yes
{{< /highlight >}}


## Benchmarking batch transfers

As mentioned in the introduction, routing 10 Gbit/s is out of scope in this
article. If you’re interested in routing performance, check out Andree Toonk’s
[post which confirms that Linux can route 10 Gbit/s at line
rate](https://toonk.io/linux-kernel-and-measuring-network-throughput/index.html).

The following sections cover individual batch transfers of large files, not many
small flows.

### iperf3 speed test

Out of the box, the speeds that {{< man name="iperf3" section="1" >}} measures
are decent:

```
chuchi % iperf3 --version
iperf 3.6 (cJSON 1.5.2)
Linux chuchi 4.19.0-16-amd64 #1 SMP Debian 4.19.181-1 (2021-03-19) x86_64
Optional features available: CPU affinity setting, IPv6 flow label, SCTP, TCP congestion algorithm setting, sendfile / zerocopy, socket pacing, authentication

chuchi % iperf3 --server
[…]

midna % iperf3 --version          
iperf 3.9 (cJSON 1.7.13)
Linux midna 5.12.1-arch1-1 #1 SMP PREEMPT Sun, 02 May 2021 12:43:58 +0000 x86_64
Optional features available: CPU affinity setting, IPv6 flow label, TCP congestion algorithm setting, sendfile / zerocopy, socket pacing, authentication

midna % iperf3 --client chuchi.lan
Connecting to host 10.0.0.173, port 5201
[  5] local 10.0.0.76 port 43168 connected to 10.0.0.173 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.10 GBytes  9.42 Gbits/sec    0   1.62 MBytes       
[  5]   1.00-2.00   sec  1.09 GBytes  9.41 Gbits/sec    0   1.70 MBytes       
[  5]   2.00-3.00   sec  1.10 GBytes  9.41 Gbits/sec    0   1.70 MBytes       
[  5]   3.00-4.00   sec  1.09 GBytes  9.41 Gbits/sec    0   1.78 MBytes       
[  5]   4.00-5.00   sec  1.09 GBytes  9.41 Gbits/sec    0   1.87 MBytes       
[  5]   5.00-6.00   sec  1.10 GBytes  9.42 Gbits/sec    0   1.87 MBytes       
[  5]   6.00-7.00   sec  1.10 GBytes  9.42 Gbits/sec    0   1.87 MBytes       
[  5]   7.00-8.00   sec  1.10 GBytes  9.41 Gbits/sec    0   1.87 MBytes       
[  5]   8.00-9.00   sec  1.09 GBytes  9.41 Gbits/sec    0   1.96 MBytes       
[  5]   9.00-10.00  sec  1.09 GBytes  9.38 Gbits/sec  402   1.52 MBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  11.0 GBytes  9.41 Gbits/sec  402             sender
[  5]   0.00-10.00  sec  11.0 GBytes  9.40 Gbits/sec                  receiver

iperf Done.
```

### HTTP speed test

Downloading a file from an {{< man name="nginx" section="1" >}} web server using {{< man name="curl" section="1" >}} is fast, too:

```
% curl -o /dev/null http://chuchi.lan/distri/supersilverhaze/img/distri-disk.img.zst
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  934M  100  934M    0     0  1118M      0 --:--:-- --:--:-- --:--:-- 1117M
```

Note that this download was served from RAM (Linux page cache). The next upgrade
I need to do in this machine is replace the SATA SSD with an NVMe SSD, because
the disk is now the bottleneck.

## Conclusion

This was a pleasantly simple upgrade: plug in a bunch of new hardware and batch
transfers become faster.

The Mikrotik switch provides great value for money, and the Intel X550-T2 works
well, but you might want to look for a cheaper alternative.
