---
layout: post
title:  "My 2022 high-end Linux PC 🐧"
date:   2022-01-15 16:00:00 +01:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1482423164667936771"
tags:
- pc
---

I finally managed to get my hands on some DDR5 RAM to complete my Intel i9-12900
high-end PC build! This article contains the exact component list if you’re
interested in doing a similar build.

{{< img src="IMG_4025_featured.jpg" >}}

Usually, I try to stay on the latest Intel CPU generation when possible. But I
decided to skip the i9-10900 ([Comet
Lake](https://en.wikipedia.org/wiki/Comet_Lake_(microprocessor))) and i9-11900
([Rocket Lake](https://en.wikipedia.org/wiki/Rocket_Lake)) series entirely,
largely because they were still stuck on Intel’s 14nm manufacturing process and
didn’t seem to offer much improvement.

The new i9-12900 ([Alder
Lake](https://en.wikipedia.org/wiki/Alder_Lake_(microprocessor))) delivered good
benchmark results and is manufactured with the much newer Intel 7 process, so I
was curious: would an upgrade be worth it?

## Components

| Price   | Type         | Article                                                                                                                                                             |
|---------|--------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 196 CHF | Case         | [Fractal Define 7 Solid (Midi Tower)](https://www.digitec.ch/de/s1/product/fractal-define-7-solid-midi-tower-pc-gehaeuse-12757904)                                  |
| 89 CHF  | Power Supply | [Corsair RM750x 2018 (750 W)](https://www.digitec.ch/de/s1/product/corsair-rm750x-2018-750-w-pc-netzteil-7678690?supplier=406802)                                   |
| 293 CHF | Mainboard    | [ASUS PRIME Z690-A (LGA1700, ATX)](https://www.digitec.ch/de/s1/product/asus-prime-z690-a-lga-1700-intel-z690-ddr5-atx-mainboard-17252893?supplier=406802)          |
| 646 CHF | CPU          | [Intel Core i9-12900K](https://www.digitec.ch/de/s1/product/intel-core-i9-12900k-lga-1700-320-ghz-16-core-prozessor-16552823?supplier=406802)                       |
| 113 CHF | CPU fan      | [Noctua NH-U12A](https://www.digitec.ch/de/s1/product/noctua-nh-u12a-1580-cm-cpu-kuehler-10847172?supplier=406802)                                                  |
| 30 CHF  | Case fan     | [Noctua NF-A14 PWM (140 m)](https://www.digitec.ch/de/s1/product/noctua-nf-a14-pwm-140-mm-1-x-pc-luefter-657800?supplier=406802)                                    |
| 770 CHF | RAM          | [Corsair Vengeance CMK32GX5M2A4800C40 (64 GB)](https://www.digitec.ch/de/s1/product/corsair-vengeance-2-x-16gb-ddr5-4800-dimm-288-pin-ram-17713383?supplier=406802) |
| 408 CHF | Disk         | [WD Black SN850 (2 TB)](https://www.digitec.ch/de/s1/product/wd-black-sn850-retail-2000-gb-m2-2280-ssd-15720645?supplier=406802)                                    |
| 605 CHF | GPU          | [GeForce RTX 2070](https://www.digitec.ch/de/s1/product/gigabyte-aorus-geforce-rtx-2070-xtreme-8-gb-grafikkarte-9896232)                                            |
| 65 EUR  | Network      | Mellanox ConnectX-3 (10 Gbit/s)                                                                                                                                     |

## Fan compatibility

The Noctua NH-U12A CPU fan required an adapter (“Noctua NM-i17xx-MP78 SecuFirm2
mounting kit”) to be compatible with the Intel LGA1700 socket. I requested the
adapter on Noctua’s Website on November 5th, and it arrived November 26th.

## Fractal Define 7 case

Anytime you need to access a PC’s components, you’ll deal with its
case. Especially for a self-built PC, the case you chose determines how easy it
is to assemble and later modify your PC.

Over the years, I have come to value the following aspects of a PC case:

1. No extra effort should be required for the case to be as quiet as possible.
1. The case should not have any sharp corners (no danger of injury!).
1. The case should provide just enough space for easy access to your components.
1. The more support the case has to encourage clean cable routing, the better.
1. USB3 front panel headers should be included.

I have been using Fractal cases for the past few years and came to generally
prefer them over other brands because of their good build quality.

Hence I’m happy to report that the Fractal Define 7 (their latest generation at
the time of writing) ticks all of the above boxes!

The case and power supply work well together in terms of cable management. It was a joy to route the cables.

It’s very easy to open the case doors (they clip in place), or remove the front
panel. This is definitely the best PC case I have seen so far in terms of quick
and easy access.

Here’s how clean the inside looks. Most cables are routed with very short ways
to the back, where the case offers plenty of convenient cable guides:

{{< img src="IMG_4028.jpg" >}}

You might also find this YouTube video review of the Fractal Define 7 interesting:

{{< youtube XeTxUjUrw4A >}}


## Slow boot

When I first powered everything on, I waited for a while, but never saw any
picture on my monitor. The PC eventually rebooted, multiple times in a row. I
took that as a bad sign and turned it off to prevent further damage.

Turns out I should have just waited until it would eventually start up!

It took multiple minutes for the machine to eventually start. I’m not 100% sure
what the cause is for that, but I heard in a Linus Tech Tips YouTube video that
DDR5 requires time-consuming memory testing when powering up with a fresh memory
configuration, so that seems plausible.

In any case, my advice is: be patient when waiting for this machine to start up.

## DDR5 availability as of Late 2021

I originally ordered all components on November 5th 2021. It took a while for
the mainboard to become available, but almost everything shipped on November
15th — except for the DDR5 RAM.

Until Late December, I was not able to find any available DDR5 RAM in Switzerland.

The shortage is so pronounced that some YouTubers recommend going with DDR4
mainboards for now, which manufacturers are scrambling to introduce in their
lineups. I did really want to squeeze out the last few extra percent in
memory-intensive workloads, so I decided to wait.

## Copying the data

Where possible, I like only changing one thing at a time. In this case, I wanted
to change the hardware, but keep using my Linux installation as-is.

To copy my Linux installation over, I plugged my old M.2 SSD into the new
machine, and then started a live Linux environment, so that neither my old nor
my new SSD were in use. My preferred live Linux is [grml (current version:
2021.07)](https://grml.org/), which I copied to a USB memory stick and booted
the machine from it.

In the grml live Linux environment, I copied the full M.2 SSD contents from old
to new:

```
grml# dd \
  if=/dev/disk/by-id/nvme-Force_MP600_<TAB> \
  of=/dev/disk/by-id/nvme-WD_BLACK_SN850_2TB_<TAB> \
  bs=5M \
  status=progress
```

For some reason, [the transfer was super
slow](https://twitter.com/zekjur/status/1476825858681802754). Last time I
transferred the contents of a Samsung 960 Pro to a Samsung 970 Pro, it took only
16 minutes. But this time, copying the Force MP600 to a WD Black SN850 took many
hours!

Once the data was transferred, I unplugged the old M.2 SSD and booted the
system.

The hostname remains the same, and the network addresses are tied to the MAC
address of the network card that I moved to the new machine. So, I didn’t have
to adjust anything in the new machine and could just boot into my usual
environment.

## UEFI settings: enable XMP for 4800 MHz RAM

By default, the memory uses 4000 MHz instead of the 4800 MHz advertised on the
box.

I figured it should be safe to try out the XMP option because it is shown as
part of ASUS’s “EZ Mode” welcome page in the UEFI setup.

So far, I have not noticed any issues when running the system with XMP enabled.

**Update February 2022**: I have experienced weird crashes that seem to have
gone away after disabling XMP. I’ll leave it disabled for now.

## UEFI settings: fan speed {#uefifan}

The Fractal Define case comes with a built-in fan controller.

I recommend not using the Fractal fan controller, as you can’t control it from
Linux!

Instead, I have plugged my fans into the mainboard directly.

In the UEFI setup, I have configured all fan speeds to use the “silent” profile.

## ASUS PRIME Z690-A: sensors and fan control

With Linux 5.15.11, some fan speeds and temperature are displayed, but oddly
enough it only shows 2 out of the 3 fans I have connected:

```
% sudo sensors
nct6798-isa-0290
Adapter: ISA adapter
[…]
fan1:                        0 RPM  (min =    0 RPM)
fan2:                      944 RPM  (min =    0 RPM)
fan3:                        0 RPM  (min =    0 RPM)
fan4:                      625 RPM  (min =    0 RPM)
fan5:                        0 RPM  (min =    0 RPM)
fan6:                        0 RPM  (min =    0 RPM)
fan7:                        0 RPM  (min =    0 RPM)
SYSTIN:                    +35.0°C  (high = +80.0°C, hyst = +75.0°C)  sensor = thermistor
CPUTIN:                    +40.0°C  (high = +80.0°C, hyst = +75.0°C)  sensor = thermistor
AUXTIN0:                  -128.0°C    sensor = thermistor
AUXTIN1:                   +24.0°C    sensor = thermistor
AUXTIN2:                   +28.0°C    sensor = thermistor
AUXTIN3:                   +31.0°C    sensor = thermistor
PECI Agent 0 Calibration:  +40.0°C
[…]
```

Unfortunately, writing to the `/sys/class/hwmon/hwmon2/pwm2` file does not seem
to change its value, so I don’t think one can control the fans via PWM from
Linux (yet?).

[I have set all fans to silent in the UEFI setup](#uefifan), which is sufficient
to not notice any noise.

## Performance comparison: i9-9900K vs. i9-12900K

After cloning my old disk to the new disk, I took the opportunity to run a few
time-intensive tasks from my day-to-day that I could remember.

On both machines, I configured the CPU governor to `performance` for stable
results.

Keep in mind that I’m comparing two unique PC builds as they are (not under
controlled and fair conditions), so the results might not necessarily be
representative. For example, it seems like the SSD performance in the old
machine was heavily degraded due to a [incorrect TRIM
configuration](https://twitter.com/zekjur/status/1476950514386538497).

| name                                                                                                                                        | old   | new  |
|---------------------------------------------------------------------------------------------------------------------------------------------|-------|------|
| [build Go 1.18beta1 (src/make.bash)](https://github.com/golang/go/tree/go1.18beta1)                                                         | ≈45s  | ≈29s |
| [gokrazy/rsync tests](https://github.com/gokrazy/rsync/tree/d1c307d7a3db853abb5b39de3a206303c4936f4f)                                       | ≈8s   | ≈5s  |
| [gokrazy UEFI test](https://github.com/gokrazy/gokrazy/blob/678bb92c2ee058df4b157fca53c486922951f2c8/integration/uefiboot/uefiboot_test.go) | ≈9s   | ≈8s  |
| [distri cryptimage (cold cache)](https://github.com/distr1/distri/blob/1c7fc9ad7e93e1de8fb85d5c4f0ca59f1f8c15e2/Makefile)                   | ≈143s | ≈18s |
| [gokrazy Linux compilation](https://github.com/gokrazy/kernel/tree/30167e68a3989313498679b9be05c824d956c4d4)                                | 215s  | 109s |

As we can see, in all of my tests, the new PC achieves measurably better times!
🎉

## Conclusion

Not only in the benchmarks above, but also subjectively, the new machine feels
fast!

Already in the first few days of usage, I notice how time-consuming tasks such
as [tracking down a Linux kernel
issue](https://github.com/gokrazy/kernel/commit/5aff50c59bbc350a034cf3b78f484d35d445c7e0)
(requires multiple Linux kernel builds), are a little less terrible thanks to
the faster machine :)

The Fractal Define 7 case is great and will likely serve as a good base for
upgrades over the next couple of years, just like its predecessor (but perhaps
even longer).

As far as I can tell, the machine works well and is compatible with Linux.
