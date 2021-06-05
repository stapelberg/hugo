---
layout: post
title:  "Laptop review: ThinkPad X1 Extreme (Gen 2)"
date:   2021-06-05 20:43:00 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1401249410781257732"
---

{{< img src="2021-06-02-thinkpad-x1-extreme.jpg" alt="ThinkPad X1 Extreme Gen 2, pear for scale" >}}

For many of my school and university years, I used and liked my ThinkPad X200
ultraportable laptop. But now that these years are long gone, I realized my
use-case for laptops had changed: instead of carrying my laptop with me every
day, I am now only bringing it on occasion, for example when I travel to
conferences, visit friends, or do volunteer work.

After the ThinkPad X200, I used a few different laptops:

* MacBook Pro 13" Retina, bought for its screen
* ThinkPad X1 Carbon, which newly introduced a hi-dpi screen to ThinkPads
* Dell XPS 9360, for a change, to try a device that ships with Linux

With each of these devices, I have felt limited by the lack of connectors and
slim compute power that comes with the Ultrabook brand, even after years of
technical progress.

More compute power is nice to be able to work on projects with larger data sets,
for example debiman (scanning and converting all manpages in Debian), or distri
(building Linux packages).

More peripheral options such as USB ports are nice when connecting a keyboard,
trackball, USB-to-serial adapter, etc., to work on a micro controller or
Raspberry Pi project, for example.

So, I was ready to switch from the heaviest Ultrabooks to the lightest of the
“mobile workstation” category, when I stumbled upon Lenovo’s ThinkPad X1 Extreme
(Gen 2), and it piqued my curiosity.

## Peripherals

Let me start by going into the key peripherals of a laptop: keyboard, touchpad
and screen. I will talk about these independently from the remaining hardware
because they define the experience of using the computer.

### Keyboard

After having used the Dell XPS 9360 for a few years, I can confidently say that
the keyboard of the ThinkPads is definitely much better, and in a noticeable
way.

It’s not that the Dell keyboards are *bad*. But comparing the Dell and ThinkPad
side-by-side makes it really clear that the ThinkPad keyboards are the best
notebook keyboards.

On the ThinkPad keyboard, every key press lands exactly as I imagine. Never do I
need to hit a key twice because I didn’t press it just-right, and never do I
notice additional ghost key presses.

Even though I connect my external Kinesis Advantage keyboard when doing longer
stretches of work, the quality of the built-in keyboard matters: a good keyboard
enables using the laptop on the couch.

### Touchpad

Unfortunately, while the keyboard is great, I can’t say the same about the
touchpad. I mean, it’s not terrible, but it’s also not good by any stretch.

This seems to be the status quo with PC touchpads for decades. It really blows
my mind that Apple’s touchpads are consistently so much better!

My only hope is that [Bill Harding
(GitClear)](https://github.com/sponsors/gitclear), who is working on improving
the Linux touchpad experience, will eventually find a magic software tweak or
something…

As [mentioned on the
ArchWiki](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Extreme_(Gen_2)#Touchpad),
I also had to adjust the sensitivity like so:

```
% xinput set-prop 'SynPS/2 Synaptics TouchPad' 'libinput Accel Speed' 0.5
```


### Display

I have high demands regarding displays: since 2013, every device of mine has a
hi-dpi display.

The industry hasn’t improved displays across the board as fast as I’d like, so
non-hi-dpi displays are still quite common. The silver lining is that it makes
laptop selection a little easier for me: anything without a decent display I can
discard right away.

I’m glad to report that the 4K display in the ThinkPad X1 Extreme with its
3840x2160 pixels is sharp, bright, and generally has good viewing angles.

It’s also a touchscreen, which I don’t strictly need, but it’s nice to use it
from time to time.

I use the display in 200% scaling mode, i.e. I set `Xft.dpi: 192`. See also
[HiDPI in ArchWiki](https://wiki.archlinux.org/index.php/HiDPI).

{{< note >}}

**Tip**: In case your brightness control keys don’t work, check if the [required
patches](https://gitlab.freedesktop.org/drm/intel/issues/510) have not been
applied in your environment yet.

{{< /note >}}

## Hardware

Spec-wise, the ThinkPad X1 Extreme is a beast!

{{< img src="specs.jpg" alt="ThinkPad X1 Extreme Specs" >}}

The build quality seems very robust to me.

Another big plus of the ThinkPad series over other laptop series is the
availability of the official Hardware Maintenance Manual: you can put “ThinkPad
X1 Extreme Gen 2 Hardware Maintenance Manual” into Google and will find
[`p1_gen2_x1extreme_hmm_v1.pdf`](https://download.lenovo.com/pccbbs/mobiles_pdf/p1_gen2_x1extreme_hmm_v1.pdf)
as the first hit. This manual describes in detail how to repair or upgrade your
device if you want to (or have to) do it yourself.

### WiFi

The built-in Intel AX200 WiFi interface works fine, provided you have a
new-enough `linux-firmware` package and kernel version installed.

I had trouble with Linux 5.6.0, and Linux 5.6.5 fixed it. Luckily, at the time
of writing, Linux 5.11 is the most recent release, so most distributions should
be recent enough for things to just work.

The WiFi card reaches almost the same download speed as the most modern WiFi
device I can test: a MacBook Air M1. Both are connected to my [UniFi
UAP-AC-HD](https://unifi-hd.ui.com/) access point.

| Laptop              | Download   | Upload     |
|---------------------|------------|------------|
| ThinkPad X1 Extreme | 500 Mbit/s | 150 Mbit/s |
| MacBook Air M1      | 600 Mbit/s | 500 Mbit/s |

I’m not sure why the upload speed is so low in comparison.

### GPU

The GPU in this machine is by far the most troublesome bit of hardware.

I had hoped that after many years of laptops containing Intel/nVidia hybrid
graphics, this setup would largely work, but was disappointed.

Both the proprietary nVidia driver and the `nouveau` driver would not work
reliably for me. I ran into kernel error messages and hard-freezes, with even
SSH sessions to the machine breaking.

In the end, I blacklisted the `nouveau` driver to use Intel graphics only:

```
% echo blacklist nouveau | sudo tee /etc/modprobe.d/blacklist.conf 
```

Without the nVidia driver, the GPU will not go into powersave mode, so I remove
it from the PCI bus entirely to save power:

```bash
#!/bin/zsh

sudo tee /sys/bus/pci/devices/0000\:01\:00.0/remove <<<1
sudo tee /sys/bus/pci/devices/0000\:01\:00.1/remove <<<1
```

You can only re-awaken the GPU with a reboot.

Obviously this isn’t a great setup — I would prefer to be able to actually use
the GPU. If you have any tips or a better experience, please let me know.

Also note that the HDMI port will be unusable if you go this route, as the HDMI
port is connected to the nVidia GPU only.

### Battery life

The 80 Wh battery lasts between 5 to 6 hours for me, without any extra power
saving tuning beyond what the Linux distribution Fedora 33 comes with by
default.

This is good enough for using the laptop away from a power socket from time to
time, which matches my expectation for this kind of mobile workstation.

## Software support

Linux support is generally good on this machine! Yes, I provide a few pointers
in this article regarding problems, patches and old software versions. But, if
you use a newer Linux distribution, all of these fixes are included and things
just work out of the box. I tested with Fedora 33.

For a few months, I was using this laptop exclusively with my research Linux
distribution [distri](https://distr1.org/), so even if you just track upstream
software closely, the machine works well.

### Firmware updates

Lenovo partnered with the [Linux Vendor Firmware Service Project
(LVFS)](https://fwupd.org/), which means that through `fwupd`, ThinkPad laptops
such as this X1 Extreme can easily receive firmware updates!

This is a huge improvement in comparison to earlier ThinkPad models, where you
had to jump through hoops with Windows-only software, or CD images that you
needed to boot just right.

If your laptop has a very old firmware version (before `1.30`), you might be
affected by the [skipping
keystrokes](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Extreme_(Gen_2)#Skipping_keystrokes)
issues. You can check using the always-handy {{< man name="lshw" section="1" >}}
tool.

## Performance

The specific configuration of my ThinkPad is:

|      | ThinkPad X1 Extreme Spec (2020)          |
|------|------------------------------------------|
| CPU  | Intel Core i7-9750H CPU @ 2.60GHz        |
| RAM  | 2 × 32 GB Samsung M471A4G43MB1-CTD       |
| Disk | 2 × SAMSUNG MZVLB2T0HALB-000L7 NVMe disk |

You can google for CPU benchmarks and comparisons yourself, and those likely are
more scientific and carefully done than I have time for.

What I can provide however, is a comparison of working on one of my projects on
the ThinkPad vs. on my workstation, an Intel Core i9-9900K that I bought in
2018:

|      | Workstation Spec (2018)                  |
|------|------------------------------------------|
| CPU  | Intel(R) Core(TM) i9-9900K CPU @ 3.60GHz |
| RAM  | 4 × Corsair CMK32GX4M2A2666C16           |
| Disk | Corsair Force MP600 M.2 NVMe disk        |

Specifically, I am comparing how long my manpage static archive generator
[debiman](https://github.com/Debian/debiman/) takes to analyze and render all
manpages in Debian unstable, using the following command:

```
ulimit -n 8192; time ~/go/bin/debiman \
  -keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
  -sync_codenames=, \
  -sync_suites=unstable \
  -serving_dir=/srv/man/benchmark \
  -inject_assets=~/go/src/github.com/Debian/debiman/debian-assets \
  -concurrency_render=20 \
  -alternatives_dir=~/go/src/github.com/Debian/debiman/piuparts
```

On both machines, I ensured that:

1. The CPU performance governor was set to `performance`
1. A warm `apt-cacher-ng` cache was present, i.e. network download was not part of the test.
1. Linux kernel caches were dropped using `echo 3 | sudo tee /proc/sys/vm/drop_caches`
1. I was using [debiman git revision `f78c160`](https://github.com/Debian/debiman/tree/f78c160f05c1f4d25c7836a6ca9198019947c1b5)

Here are the results:

| Machine                     | Time           |
|-----------------------------|----------------|
| i9-9900K Workstation        | 4:57,10 (100%) |
| ThinkPad X1 Extreme (Gen 2) | 7:19,56 (147%) |

This reaffirms my impression that even high-end laptop hardware just cannot beat
a workstation setup (which has more space and better thermals), but it comes
close enough to be useful.

## Conclusion

Positives:

* The ergonomics of the device really are great. It is a pleasure to type on a
  first-class, full-size ThinkPad keyboard. The screen has good quality and a
  high resolution.

* Performance-wise, this machine can almost replace a proper workstation.

Negatives are:

* the mediocre battery life
* an annoyingly loud fan that spins up too frequently
* poor software/driver support for hybrid nVidia GPUs.

Notably, all of these could be improved by better power saving, so perhaps it’s
just a matter of time until Linux kernel developers land some improvements…? :)
