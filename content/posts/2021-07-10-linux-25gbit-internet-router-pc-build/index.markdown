---
layout: post
title:  "25 Gigabit Linux internet router PC build"
date:   2021-07-10 13:43:00 +02:00
categories: Artikel
tags:
- fiber
---

init7 recently announced that with their [FTTH fiber offering
Fiber7](https://www.init7.net/en/internet/fiber7/), they will now sell and
connect you with 25 Gbit/s (Fiber7-X2) or 10 Gbit/s (Fiber7-X) fiber optics, if
you want more than 1 Gbit/s.

While this offer will only become available at my location late this year ([or
possibly later due to the supply chain
shortage](https://twitter.com/init7/status/1403287499175235584)), I already
wanted to get the hardware on my end sorted out.

After my [previous
disappointment](/posts/2021-05-28-configured-and-returned-mikrotik-ccr2004-for-fiber7/)
with the MikroTik CCR2004, I decided to try a custom PC build.

An alternative to many specialized devices, including routers, is to use a PC
with an expansion card. An internet router’s job is to configure a network
connection and forward network packets. So, in our case, we’ll build a PC and
install some network expansion cards!

{{< img src="2021-06-27-router-featured.jpg" alt="router PC build" >}}

## Goals

For this PC internet router build, I had the following goals, highest priority
to lowest priority:

1. Enough performance to saturate 25 Gbit/s, e.g. with two 10 Gbit/s downloads.
1. Silent: no loud fan noise.
1. Power-efficient: low power usage, as little heat as possible.
1. Low cost (well, for a high-end networking build…).

## Network Port Plan

The simplest internet router has 2 network connections: one uplink to the
internet, and the local network. You can build a router without extra cards by
using a mainboard with 2 network ports.

Because there are no mainboards with SFP28 slots (for 25 Gbit/s SFP28 fiber
modules), we need at least 1 network card for our build. You might be able to
get by with a dual-port SFP28 network card if you have an SFP28-compatible
network switch already, or need just one fast connection.

I want to connect a few fast devices (directly and via fiber) to my router, so
I’m using 2 network cards: an SFP28 network card for the uplink, and a quad-port
10G SFP+ network card for the local network (LAN). This leaves us with the
following network ports and connections:

| Network Card | max speed  | cable | effective | Connection          |
|--------------|------------|-------|-----------|---------------------|
| Intel XXV710 | 25 Gbit/s  | fiber | 25 Gbit/s | Fiber7-X2 uplink    |
| Intel XXV710 | 25 Gbit/s  | DAC   | 10 Gbit/s | workstation         |
| Intel XL710  | 10 Gbit/s  | RJ45  | 1 Gbit/s  | rest (RJ45 Gigabit) |
| Intel XL710  | 10 Gbit/s  | fiber | 10 Gbit/s | MikroTik 1          |
| Intel XL710  | 10 Gbit/s  | fiber | 10 Gbit/s | MikroTik 2          |
| Intel XL710  | 10 Gbit/s  | /     | 10 Gbit/s | (unused)            |
| onboard      | 2.5 Gbit/s | RJ45  | 1 Gbit/s  | (management)        |

{{< img src="2021-06-27-back-connectors.jpg" alt="network connectors" >}}

## Hardware selection

Now that we have defined the goals and network needs, let’s select the actual
hardware!

### Network Cards

My favorite store for 10 Gbit/s+ network equipment is
[FS.COM](https://www.fs.com/). They offer Intel-based cards:

{{< img src="2021-06-03-network-cards.jpg" alt="Network cards" >}} 

* (347 CHF) PCIe 3.0 x8 Dual-Port 25G SFP28 Ethernet Network Card (Intel XXV710) \
  [FS.COM XXV710AM2-F2 #75603](https://www.fs.com/de/products/75603.html)

* (329 CHF) PCIe 3.0 x8 Quad-Port 10G SFP+ Ethernet Network Card (Intel XL710-BM1) \
  [FS.COM FTXL710BM1-F4 #75602](https://www.fs.com/de/products/75602.html)

Both cards work out of the box with the [`i40e` Linux kernel
driver](https://www.kernel.org/doc/Documentation/networking/i40e.txt), no
firmware blobs required.

For a good overview over the different available Intel cards, check out the
second page (“Product View”) in the card’s [User
Manual](https://img-en.fs.com/file/user_manual/network-adapter-user-manual.pdf).

### CPU and Chipset

I read on many different sites that AMD’s current CPUs beat Intel’s CPUs in
terms of performance per watt. We can better achieve goals 2 and 3 (low noise
and low power usage) by using fewer watts, so we’ll pick an AMD CPU and
mainboard for this build.

AMD’s current CPU generation is Zen 3, and [current Zen 3 based
CPUs](https://en.wikipedia.org/wiki/List_of_AMD_Ryzen_processors#Zen_3_based)
can be divided into 65W [TDP (Thermal Design
Power)](https://en.wikipedia.org/wiki/Thermal_design_power) and 105W TDP
models. Only one 65W model is available to customers right now: the Ryzen 5
5600X.

Mainboards are built for/with a certain so-called chipset. Zen 3 CPUs use the
AM4 socket, for which [8 different
chipsets](https://en.wikipedia.org/wiki/Socket_AM4#Chipsets) exist. Our network
cards need PCIe 3.0, so that disqualifies 5 chipsets right away: only the A520,
B550 and X570 chipsets remain.

{{< img src="2021-06-08-ryzen5-on-mainboard.jpg" alt="Ryzen 5" >}}

### Mainboard: PCIe bandwidth

I originally tried using the ASUS PRIME X570-P mainboard, but I ran into two
problems:

Too loud: X570 mainboards need an annoyingly loud chipset fan for their 15W
TDP. Other chipsets such as the B550 don’t need a fan for their 5W TDP. With a
loud chipset fan, goal 2 (low noise) cannot be achieved. Only the
[recently-released X570**S**
variant](https://www.golem.de/news/sockel-am4-x570s-mainboards-mit-passivkuehlung-verfuegbar-2106-157434.html)
comes without fans.
   
Not enough PCIe bandwidth/slots! This is how the ASUS tech specs describe the slots: 

{{< img src="x570p_expansion.jpg" >}}

This means the board has 2 slots (1 CPU, 1 chipset) that are physically wide
enough to hold a full-length x16 card, but only the first port can
electronically be used as an x16 slot. The other port only has PCIe lanes
electronically connected for x4, hence “x16 (max at x4 mode)”.

Unfortunately, our network cards need electrical connection of all their PCIe x8
lanes to run at full speed. Perhaps Intel/FS.COM will one day offer a new
generation of network cards that use PCIe **4.0**, because PCIe 4.0 x4 achieves
the same 7.877 GB/s throughput as PCIe **3.0** x8. Until then, I needed to find
a new mainboard.

Searching mainboards by PCIe capabilities is rather tedious, as mainboard block
diagrams or PCIe tree diagrams are not consistently available from all mainboard
vendors.

Instead, we can look explicitly for a feature called **PCIe Bifurcation**. In a
nutshell, PCIe bifurcation lets us divide the PCIe bandwidth from the Ryzen CPU
from 1 PCIe 4.0 x16 into 1 PCIe 4.0 x8 + 1 PCIe 4.0 x8, definitely satisfying
our requirement for two x8 slots at full bandwidth.

I found a list of (only!) three B550 mainboards supporting PCIe Bifurcation in [an
Anandtech
review](https://www.anandtech.com/show/15850/the-amd-b550-motherboard-overview-asus-gigabyte-msi-asrock-and-others/39). Two
are made by Gigabyte, one by ASRock. I read the Gigabyte UEFI setup is rather
odd, so I went with the ASRock B550 Taichi mainboard.

### Case

For the case, I needed a midi case (large enough for the B550 mainboard’s ATX
form factor) with plenty of options for large, low-spinning fans.

I stumbled upon the [Corsair 4000D Airflow](#), which is available for 80 CHF
and [achieved positive
reviews](https://www.gamersnexus.net/hwreviews/3624-corsair-4000d-airflow-case-review-vs-solid-panel). I’m
pleased with the 4000D: there are no sharp corners, installation is quick, easy
and clean, and the front and top panels offer plenty of space for cooling behind
large air intakes:

{{< img src="2021-06-01-airflow-case-top.jpg" alt="Airflow case (from the top)" >}}

Inside, the case offers plenty of space and options for routing cables on the back side:

{{< img src="2021-06-27-case-back.jpg" alt="Airflow case (back)" >}}

Which in turn makes for a clean front side:

{{< img src="2021-06-27-case-front.jpg" alt="Airflow case (front)" >}}

### Fans

I have been happy with [Noctua](https://noctua.at/) fans for many years. In this
build, I’m using only Noctua fans so that I can reach goal 2 (silent, no loud
fan noise):

{{< img src="2021-06-01-noctua-fans.jpg" alt="Noctua fans" >}}

These fans are large (140mm), so they can spin on slow speeds and still be
effective.

The specific fan configuration I ended up with:

* 1 Noctua NF-A14 PWM 140mm in the front, pulling air out of the case
* 1 Noctua NF-A14 PWM 140mm in the top, pulling air into the case
* 1 Noctua NF-A12x25 PWM 120mm in the back, pulling air into the case
* 1 Noctua NH-L12S CPU fan

Note that this is most likely overkill: I can well imagine that I could turn off
one of these fans entirely without a noticeable effect on temperatures. But I
wanted to be on the safe side and have a lot of cooling capacity, as I don’t
know how hot the Intel network cards run in practice.

### Fan Controller

The ASRock B550 Taichi [comes with a Nuvoton
NCT6683D-T](https://www.techpowerup.com/review/asrock-b550-taichi/7.html) fan
controller.

Unfortunately, ASRock seems to have set the Customer ID register to 0 instead of
`CUSTOMER_ID_ASROCK`, so you need to load the `nct6683` Linux driver with its
`force` option.

Once the module is loaded, `lm-sensors` lists accurate PWM fan speeds, but the
temperature values are mislabeled and don’t quite match the temperatures I see
in the UEFI H/W Monitor:

```
nct6683-isa-0a20
Adapter: ISA adapter
fan1:              471 RPM  (min =    0 RPM)
fan2:                0 RPM  (min =    0 RPM)
fan3:                0 RPM  (min =    0 RPM)
fan4:                0 RPM  (min =    0 RPM)
fan5:                0 RPM  (min =    0 RPM)
fan6:                0 RPM  (min =    0 RPM)
fan7:                0 RPM  (min =    0 RPM)
Thermistor 14:     +45.5 C  (low  =  +0.0 C)
                            (high =  +0.0 C, hyst =  +0.0 C)
                            (crit =  +0.0 C)  sensor = thermistor
AMD TSI Addr 98h:  +40.0 C  (low  =  +0.0 C)
                            (high =  +0.0 C, hyst =  +0.0 C)
                            (crit =  +0.0 C)  sensor = AMD AMDSI
intrusion0:       OK
beep_enable:      disabled
```

At least with the `nct6683` Linux driver, there is no way to change the PWM fan
speed: the corresponding files in the `hwmon` interface are marked read-only.

At this point I accepted that I won’t be able to work with the fan controller
from Linux, and tried just configuring static fan control settings in the UEFI
setup.

But despite identical fan settings, one of my 140mm fans would end up turned
off. I’m not sure why — is it an unclean PWM signal, or is there just a bug in
the fan controller?

Controlling the fans to reliably spin at a low speed is vital to reach goal 2
(low noise), so I looked around for third-party fan controllers and found the
[Corsair Commander
Pro](https://www.corsair.com/eu/en/Categories/Products/Accessories-%7C-Parts/iCUE-CONTROLLERS/iCUE-Commander-PRO-Smart-RGB-Lighting-and-Fan-Speed-Controller/p/CL-9011110-WW),
which [a blog post explains is compatible with
Linux](https://blog.ktz.me/a-usb-fan-controller-that-now-works-under-linux/).

### Server Disk

This part of the build is not router-related, but I figured if I have a fast
machine with a fast network connection, I could add a fast big disk to it and
retire my other server PC.

Specifically, I chose the Samsung 970 EVO Plus M.2 SSD with 2 TB of
capacity. This disk can [deliver 3500 MB/s of sequential read
throughput](https://www.tomshardware.com/reviews/samsung-970-evo-plus-ssd,5608.html),
which is more than the ≈3000 MB/s that a 25 Gbit/s link can handle.

### Graphics Card

An important part of computer builds for me is making troubleshooting and
maintenance as easy as possible. In my current tech landscape, that translates
to connecting an HDMI monitor and a USB keyboard, for example to boot from a
different device, to enter the UEFI setup, or to look at Linux console messages.

Unfortunately, the Ryzen 5 5600X does not have integrated graphics, so to get
any graphics output, we need to install a graphics card. I chose the Zotac
GeForce GT 710 Zone Edition, because it was the cheapest available card (60 CHF)
that’s passively cooled.

An alternative to using a graphics card might be to use a PCIe IPMI card like
the [ASRock
PAUL](https://www.asrockrack.com/general/productdetail.asp?Model=PAUL#Specifications),
however these seem to be harder to find, and more expensive.

Longer-term, I think the best option would be to use the Ryzen 5 5600G with
integrated graphics, but that model only [becomes available later this
year](https://www.pcmag.com/news/amds-new-ryzen-5000-g-series-will-come-with-an-integrated-gpu).


### Component List

I’m listing 2 different options here. Option A is what I built (router+server),
but Option B is a lot cheaper if you only want a router. Both options use the
same base components:

| Price   | Type         | Article                                                                                                                                   |
|---------|--------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| 347 CHF | Network card | [FS.COM Intel XXV710, 2 × 25 Gbit/s (#75603)](https://www.fs.com/products/75603.html)                                                     |
| 329 CHF | Network card | [FS.COM Intel XL710, 4 × 10 Gbit/s (#75602)](https://www.fs.com/products/75602.html)                                                      |
| 314 CHF | CPU          | [Ryzen 5 5600X](https://www.digitec.ch/de/s1/product/amd-ryzen-5-5600x-am4-370ghz-6-core-prozessor-13987919)                              |
| 290 CHF | Mainboard    | [ASRock B550 Taichi](https://www.digitec.ch/de/s1/product/asrock-b550-taichi-am4-amd-b550-atx-mainboard-13348335)                         |
| 92 CHF  | Case         | [Corsair 4000D Airflow (Midi Tower)](https://www.digitec.ch/de/s1/product/corsair-4000d-airflow-midi-tower-pc-gehaeuse-13552873)          |
| 67 CHF  | Fan control  | [Corsair Commander Pro](https://www.digitec.ch/de/s1/product/corsair-commander-pro-extern-6x-luefter-kontroller-6332927)                  |
| 65 CHF  | Case fan     | [2 × Noctua NF-A14 PWM (140mm)](https://www.digitec.ch/de/s1/product/noctua-nf-a14-pwm-140mm-1x-pc-luefter-657800)                        |
| 62 CHF  | CPU fan      | [Noctua NH-L12S](https://www.digitec.ch/de/s1/product/noctua-nh-l12s-7cm-cpu-kuehler-6817433)                                             |
| 35 CHF  | Case fan     | [1 × Noctua NF-A12x25 PWM (120mm)](https://www.digitec.ch/de/s1/product/noctua-nf-a12x25-pwm-120mm-1x-pc-luefter-9161307)                 |
| 60 CHF  | GPU          | [Zotac GeForce GT 710 Zone Edition (1GB)](https://www.digitec.ch/de/s1/product/zotac-geforce-gt-710-zone-edition-1gb-grafikkarte-7526609) |

Base total: 1590 CHF

**Option A: Server extension**. Because I had some parts lying around, and because I
wanted to use my router for serving files (from large RAM cache/fast disk), I
went with the following parts:

| Price   | Type         | Article                                                                                                                                                               |
|---------|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 309 CHF | Disk         | [Samsung 970 EVO Plus 2000GB, M.2 2280](https://www.digitec.ch/de/s1/product/samsung-970-evo-plus-2000gb-m2-2280-ssd-10339167)                                        |
| 439 CHF | RAM          | [64GB HyperX Predator RAM (4x, 16GB, DDR4-3600, DIMM 288)](https://www.digitec.ch/de/s1/product/kingston-hyperx-predator-rgb-4x-16gb-ddr4-3600-dimm-288-ram-14062636) |
| 127 CHF | Power supply | [Corsair SF600 Platinum (600W)](https://www.digitec.ch/de/s1/product/corsair-sf600-platinum-600w-pc-netzteil-9034178)                                                 |
| 14 CHF  | Power ext    | [Silverstone ATX 24-24Pin Extension (30cm)](https://www.digitec.ch/de/s1/product/silverstone-atx-24-24pin-verlaengerung-30cm-modding-sleeving-3456447)                |
| 10 CHF  | Power ext    | [Silverstone ATX Extension 8-8(4+4)Pin (30cm)](https://www.digitec.ch/de/s1/product/silverstone-atx-extension-8-844pin-30cm-modding-sleeving-5808252)                 |

The Corsair SF600 power supply is not server-related, I just had it lying around. I’d
recommend going for the Corsair RM650x \*2018\* (which has longer cables) instead.

Server total: 2770 CHF

**Option B: Non-server (router only) alternative**. If you’re *only* interested
in routing, you can opt for cheaper low-end disk and RAM, for example:

| Price   | Type         | Article                                                                                                                                    |
|---------|--------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| 112 CHF | Power supply | [Corsair RM650x \*2018\*](https://www.digitec.ch/de/s1/product/corsair-rm650x-2018-650w-pc-netzteil-8849945)                               |
| 33 CHF  | Disk         | [Kingston A400 120GB M.2 SSD](https://www.digitec.ch/de/s1/product/kingston-a400-120gb-m2-2280-ssd-10628775)                               |
| 29 CHF  | RAM          | [Crucial CT4G4DFS8266 4GB DDR4-2666 RAM](https://www.digitec.ch/de/s1/product/crucial-ct4g4dfs8266-1x-4gb-ddr4-2666-dimm-288-ram-10447900) |

Non-server total: 1764 CHF

{{< note >}}

I had the Noctua NH-L12S CPU fan lying around, so I re-used it.

Noctua [recently released a passive CPU
cooler](https://www.golem.de/news/nh-p1-noctuas-passiver-cpu-kuehler-schafft-125-watt-2106-157334.html),
which might be an interesting alternative.

{{< /note >}}

## ASRock B550 Taichi Mainboard UEFI Setup

To enable PCIe Bifurcation for our two PCIe 3.0 x8 card setup:

1. Set `Advanced > AMD PBS > PCIe/GFX Lanes Configuration` \
to `x8x8`.

To always turn on the PC after power is lost:

1. Set `Advanced > Onboard Devices Configuration > Restore On AC Power Loss` \
to `Power On`.

To PXE boot (via UEFI) on the onboard ethernet port (management), but disable
slow option roms for PXE boot on the FS.COM network cards:

1. Set `Boot > Boot From Onboard LAN` \
to `Enabled`.
1. Set `Boot > CSM (Compatibility Support Module) > Launch PXE OpROM Policy` \
to `UEFI only`.

## Fan Controller Setup

The [Corsair Commander Pro](#) fan controller is well-supported on Linux.

After enabling the Linux kernel option `CONFIG_SENSORS_CORSAIR_CPRO`, the device
shows up in the `hwmon` subsystem.

You can completely spin up (100% PWM) or turn off (0% PWM) a fan like so:
```
# echo 255 > /sys/class/hwmon/hwmon3/pwm1
# echo 0 > /sys/class/hwmon/hwmon3/pwm1
```

I run my fans at 13% PWM, which translates to about 226 rpm:
```
# echo 33 > /sys/class/hwmon/hwmon3/pwm1
# cat /sys/class/hwmon/hwmon3/fan1_input
226
```

Conveniently, the Corsair Commander Pro stores your settings even when power is
lost. So you don’t even need to run a permanent fan control process, a one-off
adjustment might be sufficient.

## Power Usage

The PC consumes about 48W of power when idle (only management network connected)
by default without further tuning. Each extra network link increases power usage
by ≈1W:

{{< img src="2021-06-11-power-network-link.jpg" alt="graph showing power consumption when enabling network links" >}}

Enabling all [Ryzen-related options](https://wiki.gentoo.org/wiki/Ryzen#Kernel)
in my Linux kernel and switching to the powersave CPU frequency governor lowers
power usage by ≈1W.

On some mainboards, you might need to [force-enable Global
C-States](https://twitter.com/falcon3754/status/1403102789367119876) to save
power. Not on the B550 Taichi, though.

I tried undervolting the CPU, but that didn’t even make ≈1W of difference in
power usage. Potentially making my setup unreliable is not worth that little
power saving to me.

I measured these values using a [Homematic
HM-ES-PMSw1-Pl-DN-R5](https://www.conrad.ch/de/p/homematic-hm-es-pmsw1-pl-dn-r5-funk-schaltaktor-1-fach-funk-steckdose-2300-w-2507749.html)
I had lying around.

## Performance

Goal 1 is to saturate 25 Gbit/s, for example using two 10 Gbit/s downloads. I’m
talking about large bulk transfers here, not many small transfers.

{{< note >}}

If you’re interested in the “many small packets” scenario, check out [“The
calculations: 10Gbit/s
wirespeed”](https://netoptimizer.blogspot.com/2014/05/the-calculations-10gbits-wirespeed.html)
for a good intro, and [Thomas Fragstein’s benchmark tool
recommendations](https://twitter.com/fragstone/status/1401807613642280963). I
haven’t run any such tests yet.

{{< /note >}}

To get a feel for the performance/headroom of the router build, I ran 3 different tests.

### Test A: 10 Gbit/s bridging throughput

For this test, I connected 2 PCs to the router’s XL710 network card and used {{<
man name="iperf3" section="1" >}} to generate a 10 Gbit/s TCP stream between the
2 PCs. The router doesn’t need to modify the packets in this scenario, only
forward them, so this should be the lightest load scenario.

{{< img src="2021-06-06-bridging.jpg" alt="bridging throughput" >}}

### Test B: 10 Gbit/s NAT throughput

In this test, the 2 PCs were connected such that the router performs [Network
Address Translation
(NAT)](https://en.wikipedia.org/wiki/Network_address_translation), which is
required for downloads from the internet via IPv4.

This scenario is slightly more involved, as the router needs to modify
packets. But, as we can see below, a 10 Gbit/s NAT stream consumes barely more
resources than 10 Gbit/s bridging:

{{< img src="2021-06-12-nat.jpg" alt="NAT throughput" >}}

### Test C: 4 × 10 Gbit/s TCP streams

In this test, I wanted to max out the XL710 network card, so I connected 4 PCs
and started an {{< man name="iperf3" section="1" >}} benchmark between each PC
and the router itself, simultaneously.

This scenario consumes about 16% CPU, meaning we’ll most likely have plenty of
headroom even when all ports are maxed out!

{{< img src="2021-06-14-four.jpg" alt="four 10 Gbit/s streams" >}}

Tip: make sure to enable the `CONFIG_IRQ_TIME_ACCOUNTING` Linux kernel option to
[include IRQ handlers in CPU usage
numbers](https://tanelpoder.com/posts/linux-hiding-interrupt-cpu-usage/) for
accurate measurements.

## Alternatives considered

The passively-cooled SuperServer E302-9D comes with 2 SFP+ ports (10 Gbit/s). It
even comes with 2 PCIe 3.0 x8 capable slots. Unfortunately it seems impossible
to currently buy this machine, at least in Switzerland.

You can find a few more suggestions in the replies of [this Twitter
thread](https://twitter.com/zekjur/status/1361414105211437056). Most are either
unavailable, require a lot more DIY work (e.g. a custom case), or don’t support
25 Gbit/s.

## Router software: router7 porting

I wrote [router7](https://router7.org/), my own small home internet router
software in Go, back in 2018, and have been using it ever since. 

I don’t have time to support any users, so I don’t recommend anyone else use
router7, unless the project really excites you, and the lack of support doesn’t
bother you! Instead, you might be better served with a more established and
supported router software option. Popular options include
[OPNsense](https://en.wikipedia.org/wiki/OPNsense) or
[OpenWrt](https://en.wikipedia.org/wiki/OpenWrt). See also Wikipedia’s [List of
router and firewall
distributions](https://en.wikipedia.org/wiki/List_of_router_and_firewall_distributions).

To make router7 work for this 25 Gbit/s router PC build, I had to make a few
adjustments.

Because we are using UEFI network boot instead of BIOS network boot, I first had
to make the PXE boot implementation in router7’s installer [work with UEFI PXE
boot](https://github.com/rtr7/tools/commits/00be57a557a5fb2bf8958fbc1417f57ab17fc54b).

I then enabled a few additional [kernel options for network and storage
drivers](https://github.com/rtr7/kernel/commits/8694ece47fb07ffeea8a96dc48eb8faa3969250a)
in router7’s kernel.

To router7’s control plane code, I [added bridge network device
configuration](https://github.com/rtr7/router7/commits/b88ddd41c377087cc4b6d1fe6c7a5550399a730c),
which in my previous 2-port router setup was not needed.

During development, I compiled a few Linux programs statically or copied them
with their dependencies (→ [gokrazy
prototyping](https://gokrazy.org/prototyping/)) to run them on router7, such as
{{< man name="sensors" section="1" >}}, {{< man name="ethtool" section="8" >}},
as well as iproute2’s {{< man name="ip" section="8" >}} and {{< man
name="bridge" section="8" >}} implementation.

## Next Steps

Based on my tests, the hardware I selected seems to deliver enough performance
to use it for distributing a 25 Gbit/s upstream link across multiple 10 Gbit/s
devices.

I won’t know for sure until the [fiber7](https://twitter.com/fiber7_ch) Point Of
Presence (POP, German Anschlusszentrale) close to my home is upgraded to support
25 Gbit/s “Fiber7-X2” connections. As I mentioned, unfortunately [the upgrade
plan is delayed](https://twitter.com/init7/status/1403287499175235584) due to
the component shortage. I’ll keep you posted!
