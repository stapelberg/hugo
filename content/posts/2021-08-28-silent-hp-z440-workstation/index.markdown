---
layout: post
title:  "Silent HP Z440 workstation: replacing noisy fans"
date:   2021-08-28 15:16:00 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1431607602992107523"
---

Since March 2020, I have been using my work computer at home: an [HP Z440
workstation](https://support.hp.com/us-en/document/c04506309).

When I originally took the machine home, I immediately noticed that it’s quite a
bit louder than my other PCs, but only now did I finally decide to investigate
what I could do about it.

## Finding all the fans

I first identified all fans, both by opening the chassis and looking around, and
by looking at the [HP Z440 Maintenance and Service
Guide](http://h10032.www1.hp.com/ctg/Manual/c04823811), which contains this
description:

{{< img src="chassis-components.jpg" alt="chassis components" >}}

Specifically, I identified the following fans:

* “1 Fan”, a 92mm rear fan, sucking air out of the back of the chassis.
* “5 Memory fans”, two 60mm fans in a custom HP plastic enclosure that are
  positioned directly above the DIMM slots to the left and right of the CPU.
* “6 CPU Heat sink”, a 92mm fan on top of a heat sink
* “11 Rear System Fan”, a 92mm front (!) fan, pulling air into the front of the
  chassis.
* My aftermarket nVidia GeForce GPU has 3 fans on a massive heat sink.
* The power supply has a fan, too, which I will not touch.

## Memory fans

The Z440 comes with a custom HP plastic enclosure that is put over the CPU
cooler, fastened with two clips at opposite ends, and positions two small 60mm
fans above the DIMM banks.

This memory fan plastic enclosure is a pain to find anywhere. It looks like HP
is no longer producing it.


The enclosure plugs into the mainboard with a custom connector that is directly
wired up to the fans, meaning it’s a pain to replace the fans.

{{< img src="2021-08-21-memory-fans.jpg" alt="memory fans" >}}

Luckily, while [shopping around for an
enclosure](https://www.workstation4u.de/de/ersatzteile/hp/hp-z440/1513/hp-z440-memory-cooling-solution-neu)
I could modify, I realized that memory fans are only required when installing
more than 4 DIMM modules!

My machine “only” has 64 GB of RAM, in 4 DIMM modules, and I don’t intend to
upgrade anytime soon, so I just unplugged the whole memory fan enclosure and
removed it from the chassis.

The UEFI firmware does not complain about the memory fans missing (contrary to
the rear fan!), and this simple change alone makes a noticeable difference in
noise levels.

## GPU fans

nVidia GPUs can be run at different “PowerMizer” performance levels:

{{< img src="nvidia-powermizer.jpg" alt="nVidia PowerMizer" >}}

Many years ago, I ran into lag when using Chrome that went away as soon as I
switched my nVidia GPU’s Preferred Mode to “Prefer Maximum Performance” instead
of “Auto” or “Adaptive mode”.

It turns out that nowadays, that is no longer a problem, so running at Prefer
Maximum Performance is no longer necessary.

Worse, pinning the GPU at the highest Performance Level means that it produces
more heat, resulting in the fans having to spin up more often, and run for
longer durations.

But, even after switching to Auto, resulting in Adaptive mode being chosen, I
noticed that my GPU was stuck at a higher PowerMizer level than I thought it
should be.

An easy fix is to limit the GPU to a certain PowerMizer level, and ideally not
the lowest level (level 0). For me, one level after that (level 1) seems to
result in no slow-down during my typical usage.

I followed [this blog post to limit my GPU to PowerMizer level
1](https://db.tannercrook.com/limiting-nvidia-gpu-in-linux/), i.e. I added
`/etc/modprobe.d/nvidia-power-save.conf` with the following contents:

```
options nvidia NVreg_RegistryDwords="OverrideMaxPerf=0x2"
```

…followed by a rebuild of my initramfs (`update-initramfs -u`) and a `reboot`.

This way, the fans don’t typically need to spin up as the GPU stays below its
temperature limit.

{{< note >}}

For some reason, the above method worked fine on my Debian work machine, but not
on my Arch private machine…? I have not investigated why.

{{< /note >}}

## Rear and front fans

With the memory fans and GPU fans out of the way, two easy to check fans remain:
the rear fan and front fan. These are 92mm in size, the model number is Foxconn
PVA092G12S.

{{< img src="2021-08-20-rear-fan-featured.jpg" alt="rear fan" >}}

I unplugged both of them to see what effect these fans have on the noise level,
and the difference was significant!

Unfortunately, unplugging isn’t enough: the UEFI firmware complains on boot when
the rear fan is not connected, requiring you to press `Enter` to boot. Also, the
machine seems to get a few degrees Celsius hotter inside without the front and
rear fans, so I don’t want to run the machine without these fans for an extended
period of time.

I ordered two [Noctua NF-A9x14 PWM](https://noctua.at/en/nf-a9x14-pwm) fans (for
about 25 CHF each) to replace the stock front and rear fans.

Unfortunately, while HP uses a standard 4-pin PWM fan connector
(electronically), the connector on the Z440 mainboard uses a non-standard guard
rail configuration (mechanically)!

Luckily, modifying the connector of the Noctua Low-Noise Adapter cable to fit on
the custom 4-pin connector is as simple as using a knife to remove the
connector’s guard rails:

{{< img src="2021-08-24-fan-connector-mod.jpg" alt="fan connector mod" >}}

After connecting the Noctua fan, the boot warning was gone.

## CPU fan

For the CPU fan, HP again chose to use a [custom (6-pin)
connector](https://h30434.www3.hp.com/t5/Business-PCs-Workstations-and-Point-of-Sale-Systems/Z620-Aftermarker-CPU-Cooler-CPU-Cooling-shroud-necessary-or/td-p/7842134).

On the web, I read that the Z440 CPU fan is quite efficient and not worth
replacing. This matches my experience, so I kept the standard Z440 CPU cooler.

## Conclusion

I was quite happy to discover that I could just unplug the memory fans, and
configure my GPU to make less noise. Together with replacing the front/rear fans
with Noctua ones, the machine is much quieter now than before!

One downside of workstation-class hardware is that manufacturers (at least HP)
like to build custom parts and solutions. Using their own fan connectors instead
of standard connectors is such a pain! I’ll be sure to stick to standard PC
hardware :)
