---
layout: post
title:  "Home network 10 Gbit/s upgrade"
date:   2021-05-16 17:33:16 +02:00
categories: Artikel
tags:
- fiber
tweet_url: "https://twitter.com/zekjur/status/1393953665774407691"
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

Each SFP+ port can be used with either an RJ-45 Ethernet or a fiber SFP+ module,
but beware! As [Nexus2kSwiss points out on
twitter](https://twitter.com/Nexus2kSwiss/status/1394395280120897544), the
Mikrotik supports **at most 2 RJ-45 SFPs at a time**!

## Fiber module upgrade

I’m using 10 Gbit/s fiber SFP+ modules for the fiber link between my kitchen and
living room.

To make use of the 10 Gbit/s link between the switches, all devices that should
get their guaranteed 1 Gbit/s end-to-end connection need to be connected
directly to a Mikrotik switch.

I’m connecting the PCs to the switch using Direct Attach Cables (DAC) where
possible. The advantage of DAC cables over RJ45 SFP+ modules is their lower
power usage and heat.

The resulting list of SFP modules used in the two Mikrotik switches looks like
so:

| Mikrotik 1 SFP | speed          |                     | speed          | Mikrotik 2 SFP |
|----------------|----------------|---------------------|----------------|----------------|
| chuchi         | 10 Gbit/s DAC  |                     | 10 Gbit/s DAC  | midna          |
| storage2       | 1 Gbit/s  RJ45 |                     | 1 Gbit/s RJ45  | router7        |
|                | 10 Gbit/s BiDi | ⬅ BiDi fiber link ➡ | 10 Gbit/s BiDi |                |


## Hardware sourcing

The total cost of this upgrade is 676 CHF, with the biggest chunk spent on the
Mellanox ConnectX-3 network cards and MikroTik switches.

### FS (Fiber Store) order

[FS.COM](https://www.FS.COM) was my go-to source for anything
fiber-related. Everything they have is very affordable, and products in stock at
their German warehouse arrive in Switzerland (and presumably other European
countries, too) within the same week.

| num | price  | name                                                                                                                                                            |
|-----|--------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 × | 34 CHF | [Generic Compatible 10GBASE-BX BiDi SFP+ 1270nm-TX/1330nm-RX 10km DOM Transceiver Module, FS P/N: SFP-10G-BX #74681](https://www.fs.com/de/products/74681.html) |
| 1 × | 34 CHF | [Generic Compatible 10GBASE-BX BiDi SFP+ 1330nm-TX/1270nm-RX 10km DOM Transceiver Module, FS P/N: SFP-10G-BX #74682](https://www.fs.com/de/products/74682.html) |
| 2 × | 14 CHF | [3m Generic Compatible 10G SFP+ Passive Direct Attach Copper Twinax Cable](https://www.fs.com/de/products/74621.html) |
| 0 × | 56 CHF | <del>[SFP+ Transceiver Modul - Generisch kompatibel 10GBASE-T SFP+ Kupfer RJ-45 30m, FS P/N: SFP-10G-T #74680](https://www.fs.com/de/products/74680.html)</del> |

### digitec order

There are a few items that [FS.COM](https://www.FS.COM) doesn’t stock. These I
bought at [digitec](https://www.digitec.ch/), a big and popular electronics
store in Switzerland. My thinking is that if products are available at digitec,
they most likely are available at your preferred big electronics store, too.

| num | price    | name                                                                                                                                  |
|-----|----------|---------------------------------------------------------------------------------------------------------------------------------------|
| 2 × | 149 CHF  | [Mikrotik CRS305-1G-4S+IN](https://www.digitec.ch/de/s1/product/mikrotik-crs305-1g-4sin-5ports-switch-9876046) switch                 |

### misc order

The Mellanox cards are not as widely available as I’d like.

I’m waiting for an FS.COM card to arrive, which might be a better choice.

| num | price    | name                                                                                                                                  |
|-----|----------|---------------------------------------------------------------------------------------------------------------------------------------|
| 2 × | 129 EUR  | [Mellanox ConnectX-3 MCX311A-XCAT](https://www.heise.de/preisvergleich/nvidia-mellanox-connectx-3-en-10g-mcx311a-xcat-a2508412.html)  |

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

After booting with the Mellanox ConnectX3 in a PCIe slot, the card should show
up in {{< man name="dmesg" section="8" >}}:

{{< highlight text "hl_lines=4" >}}
mlx4_core: Mellanox ConnectX core driver v4.0-0
mlx4_core: Initializing 0000:03:00.0
mlx4_core 0000:03:00.0: DMFS high rate steer mode is: disabled performance optimized steering
mlx4_core 0000:03:00.0: 31.504 Gb/s available PCIe bandwidth (8.0 GT/s PCIe x4 link)
mlx4_en: Mellanox ConnectX HCA Ethernet driver v4.0-0
mlx4_en 0000:03:00.0: Activating port:1
mlx4_en: 0000:03:00.0: Port 1: Using 16 TX rings
mlx4_en: 0000:03:00.0: Port 1: Using 16 RX rings
mlx4_en: 0000:03:00.0: Port 1: Initializing port
mlx4_en 0000:03:00.0: registered PHC clock
mlx4_core 0000:03:00.0 enp3s0: renamed from eth0
<mlx4_ib> mlx4_ib_add: mlx4_ib: Mellanox ConnectX InfiniBand driver v4.0-0
<mlx4_ib> mlx4_ib_add: counter index 1 for port 1 allocated 1
mlx4_en: enp3s0: Steering Mode 1
mlx4_en: enp3s0: Link Up
{{< /highlight >}}

Another way to verify the device is running at maximum speed on the computer’s
PCIe bus, is to ensure `LnkSta` matches `LnkCap` in the {{< man name="lspci"
section="8" >}} output:

{{< highlight text "hl_lines=7 11" >}}
% sudo lspci -vv
03:00.0 Ethernet controller: Mellanox Technologies MT27500 Family [ConnectX-3]
	Subsystem: Mellanox Technologies Device 0055
[…]
	Capabilities: [60] Express (v2) Endpoint, MSI 00
[…]
		LnkCap:	Port #8, Speed 8GT/s, Width x4, ASPM L0s, Exit Latency L0s unlimited
			ClockPM- Surprise- LLActRep- BwNot- ASPMOptComp+
		LnkCtl:	ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
			ExtSynch- ClockPM- AutWidDis- BWInt- AutBWInt-
		LnkSta:	Speed 8GT/s (ok), Width x4 (ok)
			TrErr- Train- SlotClk+ DLActive- BWMgmt- ABWMgmt-
[…]
{{< /highlight >}}



You can verify your network link is running at 10 Gbit/s using {{< man
name="ethtool" section="8" >}}:

{{< highlight text "hl_lines=14" >}}
% sudo ethtool enp3s0
Settings for enp3s0:
	Supported ports: [ FIBRE ]
	Supported link modes:   1000baseKX/Full
	                        10000baseKR/Full
	Supported pause frame use: Symmetric Receive-only
	Supports auto-negotiation: No
	Supported FEC modes: Not reported
	Advertised link modes:  1000baseKX/Full
	                        10000baseKR/Full
	Advertised pause frame use: Symmetric
	Advertised auto-negotiation: No
	Advertised FEC modes: Not reported
	Speed: 10000Mb/s
	Duplex: Full
	Auto-negotiation: off
	Port: Direct Attach Copper
	PHYAD: 0
	Transceiver: internal
	Supports Wake-on: d
	Wake-on: d
        Current message level: 0x00000014 (20)
                               link ifdown
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

The Mikrotik switch provides great value for money, and the Mellanox ConnectX-3
cards work well, provided you can find them.

## Appendix A: Switching from RJ45 SFP+ modules to Direct Attach Cables

Originally, I connected all PCs to the MikroTik switches with RJ45 SFP+ modules
for two reasons:

1. I bought [Intel
   X550-T2](https://www.digitec.ch/de/s1/product/intel-x550-t2-pci-express-30-netzwerkadapter-5926807)
   PCIe 10 Gbit/s network cards that RJ45 as my first choice.
1. The SFP+ modules are backwards-compatible and can be used with 1 Gbit/s RJ45
   devices, too, which makes for a nice incremental upgrade path.

However, I later was made aware that the RJ45 SFP+ modules use significantly
more power and run significantly hotter than Direct Attach Cables (DAC).

I measured it: each RJ45 SFP+ module was causing my BiDi SFP+ module to run 5℃
hotter!

{{< img src="2021-06-06-sfp-temperatures.jpg" >}}

Around 06/02 I replaced one RJ45 SFP+ module with a Direct Attach Cable.

Around 06/06 I replaced the remaining RJ45 SFP+ module with another Direct
Attach Cable.

As you can see, this caused a 10℃ drop in temperature of the BiDi SFP+ module.

The MikroTik is still uncomfortably hot, making it hard to work with when it’s
powered on.

## Appendix B: Network card setup (Linux) with Intel X550-T2

For reference, here is the Network card setup (Linux) section, but with the
Intel X550-T2 that I previously used.

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

I think if you only use 1 of the card’s 2 network ports, you might not hit any
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

## Appendix C: BIOS update for Mellanox ConnectX-3

On my Supermicro X11SSZ-QF mainboard, the Mellanox ConnectX-3 would not
establish a link. The Mellanox Linux kernel driver logged a number of errors:

```
kernel: mlx4_en: enp1s0: CQE error - cqn 0x8e, ci 0x0, vendor syndrome: 0x57 syndrome: 0x4
kernel: mlx4_en: enp1s0: Related WQE - qpn 0x20d, wqe index 0x0, wqe size 0x40
kernel: mlx4_en: enp1s0: Scheduling port restart
kernel: mlx4_core 0000:01:00.0: Internal error detected:
kernel: mlx4_core 0000:01:00.0: device is going to be reset
kernel: mlx4_core 0000:01:00.0: crdump: devlink snapshot disabled, skipping
kernel: mlx4_core 0000:01:00.0: device was reset successfully
kernel: mlx4_en 0000:01:00.0: Internal error detected, restarting device
kernel: <mlx4_ib> mlx4_ib_handle_catas_error: mlx4_ib_handle_catas_error was started
kernel: <mlx4_ib> mlx4_ib_handle_catas_error: mlx4_ib_handle_catas_error ended
kernel: mlx4_core 0000:01:00.0: command 0x21 failed: fw status = 0x1
kernel: pcieport 0000:00:1c.0: AER: Uncorrected (Fatal) error received: 0000:00:1c.0
kernel: pcieport 0000:00:1c.0: PCIe Bus Error: severity=Uncorrected (Fatal), type=Transaction Layer, (Receiver ID)
kernel: mlx4_core 0000:01:00.0: command 0x43 failed: fw status = 0x1
kernel: infiniband mlx4_0: ib_query_port failed (-5)
kernel: pcieport 0000:00:1c.0:   device [8086:a110] error status/mask=00040000/00010000
kernel: pcieport 0000:00:1c.0:    [18] MalfTLP                (First)
kernel: pcieport 0000:00:1c.0: AER:   TLP Header: 4a000001 01000004 00000000 00000000
kernel: mlx4_core 0000:01:00.0: mlx4_pci_err_detected was called
kernel: mlx4_core 0000:01:00.0: Fail to set mac in port 1 during unregister
systemd-networkd[313]: enp1s0: Link DOWN
kernel: mlx4_en: enp1s0: Failed activating Rx CQ
kernel: mlx4_en: enp1s0: Failed restarting port 1
kernel: mlx4_en: enp1s0: Link Down
kernel: mlx4_en: enp1s0: Close port called
systemd-networkd[313]: enp1s0: Lost carrier
kernel: mlx4_en 0000:01:00.0: removed PHC
kernel: mlx4_core 0000:01:00.0: mlx4_restart_one_up: ERROR: mlx4_load_one failed, pci_name=0000:01:00.0, err=-5
kernel: mlx4_core 0000:01:00.0: mlx4_restart_one was ended, ret=-5
systemd-networkd[313]: enp1s0: DHCPv6 lease lost
kernel: pcieport 0000:00:1c.0: AER: Root Port link has been reset
kernel: mlx4_core 0000:01:00.0: mlx4_pci_resume was called
kernel: mlx4_core 0000:01:00.0: Multiple PFs not yet supported - Skipping PF
kernel: mlx4_core 0000:01:00.0: mlx4_pci_resume: mlx4_load_one failed, err=-22
kernel: pcieport 0000:00:1c.0: AER: device recovery successful
```

What helped was to update the X11SSZ-QF BIOS to the latest version.
