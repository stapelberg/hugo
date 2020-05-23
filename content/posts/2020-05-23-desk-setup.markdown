---
layout: post
title:  "stapelberg uses this: my 2020 desk setup"
date:   2020-05-23 15:22:00 +02:00
categories: Artikel
---

<a href="../../Bilder/2020-05-22-desk-setup.jpg"><img
src="../../Bilder/2020-05-22-desk-setup.thumb.jpg"
srcset="../../Bilder/2020-05-22-desk-setup.thumb.2x.jpg 2x,../../Bilder/2020-05-22-desk-setup.thumb.3x.jpg 3x" alt="Desk setup"
width="600" style="border: 1px solid #ccc"></a>

I generally enjoy reading the [uses this](https://usesthis.com/) blog, and
recently people have been talking about desk setups in my bubble (and [on my
Twitch stream](https://www.twitch.tv/stapelberg)), so I figured I’d write a post
about my current setup!

## Desk setup

I’m using a desk I bought at IKEA well over 10 years ago. I’m not using a
standing desk: while I have one at work, I never change its height. Just never
could get into the habit.

I was using an IKEA chair as well for many years.

Currently, I’m using a [Haworth Comforto
89](https://eu.haworth.com/home/seating/executive/zody) chair that I bought
second-hand. Unfortunately, the arm rests are literally crumbling apart and the
lumbar back support and back rest in general are not as comfortable as I would
like.

Hence, I recently ordered a [Vitra ID
Mesh](https://www.vitra.com/en-ch/office/product/details/id-mesh) chair, which I
have used for a couple of years at the office before moving office buildings. It
will take a few weeks before the chair arrives.

<details><summary>Full Vitra ID Mesh chair configuration details</summary>
<ul>
<li>ID Mesh</li>
<li>Chair type: office swivel chair</li>
<li>Backrest: ID Mesh</li>
<li>Colours and materials</li>
<li>- Cover material: seat and backrest Silk Mesh</li>
<li>- Colour of back cover: dim grey/ like frame colour</li>
<li>- Colour of seat cover: dim grey</li>
<li>- Frame colour: soft grey</li>
<li>Armrests: 2D armrests</li>
<li>Base: five-star base, polished aluminium</li>
<li>Base on: castors hard, braked for carpet</li>
<li>Ergonomics</li>
<li>Seat and seat depth adjustment: seat with seat depth adjustment</li>
<li>Forward tilt: with forward tilt</li>
</ul>
</details>

The most important aspect of the desk/chair setup for me are the arm rests. I
align them with the desk height so that I can [place my arms at a 90 degree
angle, eliminating
strain](https://de.wikipedia.org/wiki/Datei:Ergonomic_workstation.png).

## Peripherals

Note: all of my peripherals are Plug & Play under Linux and generally work with
standard drivers across Windows, macOS and Linux.

### Monitor: Dell 8K4K monitor (UP3218K)

The most important peripheral of a computer is the monitor: you stare at it all
the time. Even when you’re not using your keyboard or mouse, you’re still
looking at your monitor.

Ever since I first used a MacBook Pro with Retina display back in 2013, I’ve
been madly in love with hi-DPI displays, and have gradually replaced all
displays in my day-to-day with hi-DPI displays.

My current monitor is the [Dell UP3218K, an 8K4K monitor (blog post)](/posts/2017-12-11-dell-up3218k/).

Dell introduced the UP3218K in January 2017. It is the world’s first available
8K monitor, meaning it has a resolution of 7680x4320 pixels at a refresh rate of
60 Hz. The display’s dimensions are 698.1mm by 392.7mm (80cm diagonal, or 31.5
inches), meaning the display shows 280 dpi.

I run it in 300% scaling mode (`Xft.dpi: 288`), resulting in incredibly crisp
text.

Years ago, I used multiple monitors (sometimes 3, usually 2). I stopped doing
that in 2011/2012, when I lived in Dublin for half a year and decided to get
only one external monitor for practical and cost reasons.

I found that using only one monitor allows me to focus more on what I’m doing,
and I don’t miss anything about a multi-monitor setup.

### Keyboard: Kinesis advantage keyboard

<a href="../../Bilder/2020-05-22-kinesis-advantage.jpg"><img
src="../../Bilder/2020-05-22-kinesis-advantage.thumb.jpg"
srcset="../../Bilder/2020-05-22-kinesis-advantage.thumb.2x.jpg 2x,../../Bilder/2020-05-22-kinesis-advantage.thumb.3x.jpg 3x" alt="Kinesis advantage keyboard"
width="600" style="border: 1px solid #ccc"></a>

The Kinesis is my preferred commercially available ergonomic keyboard. I like
its matrix layout, ergonomic key bowls, thumb pads and split hands.

I find typing on it much more comfortable than regular keyboards, and I value
the Kinesis enough to usually carry one with me when I travel. When I need to
use a laptop keyboard for longer periods of time, my hands and arms get tired.

I bought my first one in 2008 for ≈250 EUR, but have since cleaned up and
repaired two more Kinesis keyboards that were about to be trashed. Now I have
one for home, one for work, and one for traveling (or keyboard development).

Over the years, I have modified my Kinesis keyboards in various ways:

The first modification I did was to put in [Cherry MX blue key
switches](https://www.cherrymx.de/en/mx-original/mx-blue.html) (tactile and
audible), replacing the default [Cherry MX
browns](https://www.cherrymx.de/en/mx-original/mx-brown.html). I like the quick
feedback of the blues better, possibly because I was used to them from my
previous keyboards. Without tons of patience and good equipment, it’s virtually
impossible to unsolder the key switches, so I reached out to Kinesis, and they
agreed to send me unpopulated PCBs into which I could solder my preferred
key switches! Thank you, Kinesis.

I later [replaced the keyboard controller to address a stuck modifier
bug](posts/2013-03-21-kinesis_custom_controller/). The
PCB I made for this remains popular in the Kinesis modification community to
this day.

In 2018, I got interested in keyboard input latency and developed [kinX, a new
version of my replacement keyboard controller](/posts/2018-04-17-kinx/). With
this controller, the keyboard has an input latency of merely 0.225ms in the
worst case.

Aside from the keyboard hardware itself, I’m [using the NEO Ergonomically
Optimized keyboard layout](/posts/2009-01-01-neo_kinesis/). It’s optimized for
German, English, Programming and Math, in that order. Especially its upper
layers are really useful: [hover over “Ebene 3”](https://neo-layout.org/) to
see.

I used to remap keys in hardware, but that doesn’t cover the upper layers, so
nowadays I prefer just enabling the NEO layout included in operating systems.

### Pointing device: Logitech MX Ergo

During my student years (2008 to 2013), I carried a ThinkPad X200 and used its
TrackPoint (“red dot”) in combination with trying to use lots of keyboard
shortcuts.

The concept of relative inputs for mouse movement made sense to me, so I
switched from a mouse to a trackball on the desktop, specifically the [Logitech
Trackball M570](https://www.logitech.com/en-us/product/wireless-trackball-m570).

I was using the M570 for many years, but have switched to the [Logitech MX
Ergo](https://www.logitech.com/en-ch/product/mx-ergo-wireless-trackball-mouse) a
few months ago. It is more comfortable to me, so I replaced all 3 trackballs
(home, office, travel) with the MX Ergo.

In terms of precision, a trackball will not be as good as a mouse can be. To me,
it more than makes up for the fact by reducing the strain on my hands and
wrists.

For comparison: a few years ago, I was playing a shooter with a regular mouse
for one evening (mostly due to nostalgia), and I could feel pain from that for
weeks afterwards.

### Microphone: RØDE Podcaster

To record screencasts for the [i3 window manager](https://i3wm.org/) with decent
audio, I bought a [RØDE Podcaster USB Broadcast
Mic](http://www.rode.com/microphones/podcaster) in 2012 and have been using it
ever since.

The big plus is that the setup couldn’t be easier: you connect it via USB, and
it is Plug & Play on Linux. This is much easier than getting a working setup
with [XLR audio gear](https://en.wikipedia.org/wiki/XLR_connector).

The audio quality is good: much better than headsets or cheap mics, but probably
not quite as good as a more expensive studio mic. For my usage, this is fine: I
don’t record radio broadcasts regularly, so I don’t need the absolutely highest
quality, and for video conferences or the occasional podcast, the RØDE Podcaster
is superb.

### Webcam: Logitech C920

In the past, I have upgraded my webcam every so often because higher resolutions
at higher frame rates became available for a reasonably low price.

I’m currently using the [Logitech HD Pro Webcam
C920](https://www.logitech.com/en-ch/product/hd-pro-webcam-c920), and I’m pretty
happy with it. The picture quality is good, the device is Plug & Play under
Linux and the picture quality is good out of the box. No fumbling with UVC
parameters or drivers required :-)

Note: to capture at 30 fps at the highest resolution, you may need to specify
the pixel format: https://wiki.archlinux.org/index.php/webcam_setup#mpv

### Headphones: Sony WH-1000XM3

At work, I have been using the [Bose QuietComfort 15 Noise Cancelling
headphones](https://www.bose.ch/de_ch/support/products/bose_headphones_support/bose_around_ear_headphones_support/qc15.html)
for many years, as they were considered the gold standard for noise cancelling
headphones.

I decided to do some research and give bluetooth headphones a try, in the hope
that the technology has matured enough.

I went with the [Sony
WH-1000XM3](https://www.sony.com/electronics/headband-headphones/wh-1000xm3)
bluetooth headphones, and am overall quite happy with them. The lack of a cable
is very convenient indeed, and the **audio quality and noise cancellation are
both superb**. A single charge lasts me for multiple days.

Switching devices is a bit cumbersome: when I have the headphones connected to
my phone and want to switch to my computer, I need to explicitly disconnect on
my phone, then explicitly connect on my computer. I guess this is just how
bluetooth works.

One issue I ran into is that when the headphones re-connected to my computer,
they [would not select the high-quality audio
profile](https://gitlab.freedesktop.org/pulseaudio/pulseaudio/issues/525#note_373471)
until you explicitly disconnect and re-connect again. This [was
fixed](https://git.kernel.org/pub/scm/bluetooth/bluez.git/patch/?id=477ecca127c529611adbc53f08039cefaf86305d)
in BlueZ 5.51, so make sure you run at least that version.

### USB memory stick: Sandisk Extreme PRO SSD USB 3.1

USB memory sticks are useful for all sorts of tasks, but I mostly use them to
boot Linux distributions on my laptop or computer, for development, recovery,
updates, etc.

A year ago, I was annoyed by my USB memory sticks being slow, and I found the
[Sandisk Extreme PRO SSD USB
3.1](https://shop.westerndigital.com/products/usb-flash-drives/sandisk-extreme-pro-usb-3-1)
which is essentially a little SSD in USB memory stick form factor. It is spec'd
at ≈400 MB/s read and write speed, and I do reach about ≈350 MB/s in practice,
which is a welcome upgrade from the < 10 MB/s my previous sticks did.

A quick USB memory stick lowers the hurdle for testing
[distri](https://distr1.org/) images on real hardware.

### Audio: teufel sound system

My computer is connected to a [Teufel Motiv
2](https://www.teufelaudio.com/pc/motiv-2-p167.html) stereo sound system I
bought in 2009.

The audio quality is superb, and when I tried to replace them with the [Q
Acoustics 3020 Speakers
(Pair)](https://www.qacoustics.co.uk/q-acoustics-3020-bookshelf-speakers-pair.html)
I ended up selling the Q Acoustics and going back to the Teufel. Maybe I’m just
very used to its sound at this point :-)

### Physical paper notebook for sketches

I also keep a paper notebook on my desk, but don’t use it a lot. It is good to
have it for ordering my thoughts when the subject at hand is more visual rather
than textual. For example, my [analysis of the TurboPFor integer compression
scheme](/posts/2019-02-05-turbopfor-analysis/) started out on a bunch of
notebook pages.

I don’t get much out of hand writing into a notebook (e.g. for task lists), so I
tend to do that in [Emacs Org mode](https://orgmode.org/) files instead (1 per
project). I’m only a very light Org mode user.

### Laptop: TBD

I’m writing a separate article about my current laptop and will reference the
post here once published.

I will say that I mostly use laptops for traveling (to conferences or events)
these days, and there is not much travel happening right now due to COVID-19.

Having a separate computer is handy for some debugging activities,
e.g. single-stepping X11 applications in a debugger, which needs to be done via
SSH.

### Internet router and WiFi: router7 and UniFi AP HD

Mostly for fun, I decided to write [router7, a highly reliabile, automatically
updating internet router entirely in Go](https://github.com/rtr7/router7),
primarily targeting the [fiber7](https://www.init7.net/) internet service.

While the router could go underneath my desk, I currently keep it on top of my
desk. Originally, I placed it in reach to lower the hurdle for debugging, but
after the initial development phase, I never had to physically power cycle it.

These days, I only keep it on top of my desk because I like the physical
reminder of what I accomplished :-)

For WiFi, I use a [UniFi AP HD](https://unifi-hd.ui.com/) access point from
Ubiquiti. My apartment is small enough that this single access point covers all
corners with great WiFi. I’m configuring the access point with the mobile app so
that I don’t need to run the controller app somewhere.

In general, I try to connect most devices via ethernet to remove WiFi-related
issues from the picture entirely, and reduce load on the WiFi.

### Switching peripherals between home and work computer

Like many, I am currently working from home due to COVID-19.

Because I only have space for one 32" monitor and peripherals on my desk, I
decided to share them between my personal computer and my work computer.

To make this easy, I got an active [Anker 10-port USB3
hub](https://www.anker.com/products/variant/anker-10-port-60w-data-hub/A7515111)
and two USB 3 cables for it: one connected to my personal computer, one to my
work computer. Whenever I need to switch, I just re-plug the one cable.

## Software setup

### Linux

I have been using Linux as my primary operating system since 2005. The first
Linux distribution that I installed in 2005 was Ubuntu-based. Later, I switched
to Gentoo, then to Debian, which I used and contributed to until [quitting the
project in March
2019](https://michael.stapelberg.ch/posts/2019-03-10-debian-winding-down/).

I had briefly tried Fedora before, and decided to give Arch Linux a shot now, so
that’s what I’m running on my desktop computer right now. My servers remain on
[Flatcar Container Linux](https://www.flatcar-linux.org/) (the successor to
CoreOS) or Debian, depending on their purpose.

For me, all [Linux package managers are too
slow](/posts/2019-08-17-linux-package-managers-are-slow/), which is why I
started [distri: a Linux distribution to research fast package
management](/posts/2019-08-17-introducing-distri/). I’m testing distri on my
laptop, and I’m using distri for a number of development tasks. I don’t want to
run it on my desktop computer, though, because of its experimental nature.

### Window Manager: i3

It won’t be a surprise that I am using the [i3 tiling window
manager](https://i3wm.org/), which I created in 2009 and still maintain.

[My i3 configuration
file](https://github.com/stapelberg/configfiles/blob/master/config/i3/config) is
pretty close to the i3 default config, with only two major modifications: I use
`workspace_layout stacked` and usually arrange two stacked containers next to
each other on every workspace. Also, I configured a [volume
mode](https://github.com/stapelberg/configfiles/blob/5a3703a8c0fca06242d936c13e4fcc2761f3a58b/config/i3/config#L170)
which allows for easily changing the default sink’s volume.

One way in which my usage might be a little unusual is that I always have at
least 10 workspaces open.

### Go

Over time, I have moved all new development work to Go, which is by far [my
favorite programming
language](https://michael.stapelberg.ch/posts/2017-08-19-golang_favorite/). See
the article for details, but in summary, Go’s values align well with my own: the
tooling is quick and high-quality, the language well thought-out and operating
at roughly my preferred level of abstraction vs. clarity.

Here is a quick description of a few notable Go projects I started:

[Debian Code Search](https://codesearch.debian.net/) is a regular expression
source code search engine covering all software available in Debian.

[RobustIRC](https://robustirc.net/) is an IRC network without netsplits, based
on [the Raft consensus
algorithm](https://en.wikipedia.org/wiki/Raft_(computer_science)).

[gokrazy](https://gokrazy.org/) is a pure-Go userland for your Raspberry Pi 3
appliances. It allows you to overwrite an SD card with a Linux kernel, Raspberry
Pi firmware and Go programs of your chosing with just one command.

[router7](https://github.com/rtr7/router7) is a pure-Go small home internet
router.

[debiman](https://github.com/debian/debiman) generates a static manpage HTML
repository out of a Debian archive and powers
[manpages.debian.org](https://manpages.debian.org/).

The [distri research linux distribution project](https://distr1.org/) was
started in 2019 to research whether a few architectural changes could enable
drastically faster package management. While the package managers in common
Linux distributions (e.g. apt, dnf, …) [top out at data rates of only a few
MB/s](/posts/2019-08-17-linux-package-managers-are-slow/), distri effortlessly
saturates 1 Gbit, 10 Gbit and even 40 Gbit connections, resulting in superior
installation and update speeds.


### Editor: Emacs

In my social circle, everyone used Vim, so that’s what I learnt. I used it for
many years, but eventually gave Emacs a shot so that I could try the best
[notmuch](https://notmuchmail.org/) frontend.

Emacs didn’t immediately click, and I haven’t used notmuch in many years, but it
got me curious enough that I tried getting into the habit of using Emacs a few
years ago, and now I prefer it over Vim and other editors.

Here is a non-exhaustive list of things I like about Emacs:

1. Emacs is not a modal editor. You don’t need to switch into insert mode before
   you can modify the text. This might sound like a small thing, but I feel more
   of a direct connection to the text this way.

1. I like Emacs’s built-in buffer management. I could never get used to using
   multiple tabs or otherwise arranging my Vim editor window, but with Emacs,
   juggling multiple things at the same time feels very natural.
\
   I make heavy use of Emacs’s compile mode (similar to Vim’s quick fix window):
   I will compile not only programs, but also config files (e.g. `M-x compile i3
   reload`) or `grep` commands, allowing me to go through matches via `M-g M-n`.

1. The [Magit](https://magit.vc/) package is **by far** my most favorite Git
   user interface. Staging individual lines or words comes very naturally, and
   many operations are much quicker to accomplish compared to using Git in a
   terminal.

1. The [eglot](https://github.com/joaotavora/eglot) package is a good
   [LSP](https://en.wikipedia.org/wiki/Language_Server_Protocol) client, making
   available tons of powerful cross-referencing and refactoring features.

1. The possible customization is impressive, including the development
   experience: Emacs’s built-in help system is really good, and allows jumping
   to the definition of variables or functions out of the box. Emacs is the only
   place in my day-to-day where I get a little glimpse into what it must have
   been like to use a [Lisp
   machine](https://en.wikipedia.org/wiki/Lisp_machine)…

Of course, not everything is great about Emacs. Here are a few annoyances:

1. The Emacs default configuration is very old, and a number of settings need to
   be changed to make it more modern. I have been tweaking my Emacs config since
   2012 and still feel like I’m barely scratching the surface. Many beginners
   find their way into Emacs by using a pre-configured version of it such as
   [Doom Emacs](https://github.com/hlissner/doom-emacs) or
   [Spacemacs](https://www.spacemacs.org/).

1. Even after going through great lengths to keep startup fast, Emacs definitely
   starts much more slowly than e.g. Vim. This makes it not a great fit for
   trivial editing tasks, such as commenting out a line of configuration on a
   server via SSH.

For consistency, I eventually switched my shell and readline config from vi key
bindings to the default Emacs key bindings. This turned out to be a great move:
the Emacs key bindings are generally better tested and more closely resemble the
behavior of the editor. With vi key bindings, sooner or later I always ran into
frustrating feature gaps (e.g. zsh didn’t support the
delete-until-next-x-character Vim command) or similar.

## Hardware setup: desktop computer

I should probably publish a separate blog post with PC hardware recommendation,
so let me focus on the most important points here only:

I’m using an Intel i9-9900K CPU. I briefly switched to an AMD Ryzen 3900X based
on tech news sites declaring it faster. I eventually found out that the Intel
i9-9900K actually benchmarks better in browser performance and incremental Go
compilation, so I switched back.

To be able to drive the Dell 8K4K monitor, I’m using a nVidia GeForce
RTX 2070. I don’t care for its 3D performance, but more video RAM and memory
bandwidth make a noticeable difference in how many Chrome tabs I can work with.

To avoid running out of memory, I usually max out memory based on mainboard
support and what is priced reasonably. Currently, I’m using 64 GB of Corsair
RAM.

For storage, I currently use a Phison Force MP600 PCIe 4 NVMe disk, back from
when I tried the Ryzen 3900X. When I’m not trying out PCIe 4, I usually go with
the latest Samsung Consumer SSD PRO, e.g. the [Samsung SSD 970
PRO](https://www.samsung.com/semiconductor/minisite/ssd/product/consumer/970pro/). Having
a lot of bandwidth and IOPS available is great in general, but especially
valuable when e.g. [re-generating all
manpages](https://github.com/Debian/debiman/) or compiling a new
[distri](https://distr1.org/) version from scratch.

I’m a fan of Fractal Design’s Define case series (e.g. the [Define
R6](https://www.fractal-design.com/products/cases/define/define-r6-usb-c/blackout/))
and have been using them for many years in many different builds. They are great
to work with: no sharp edges, convenient screws and mechanisms, and they result
in a quiet computer.

For fans, my choice is Noctua. Specifically, their
[NH-U14S](https://noctua.at/en/products/cpu-cooler-retail/nh-u14s) makes for a
great CPU fan, and their [NF-A12x25](https://noctua.at/en/nf-a12x25-pwm) are
great case fans. They cool well and are super quiet!

## Network storage

For redundancy, I am backing up my computers to 2 separate network storage devices.

My devices are [built from PC Hardware](/posts/2019-10-23-nas/) and run [Flatcar
Linux (previously CoreOS)](/posts/2016-11-21-gigabit-nas-coreos/) for automated
updates. I put in one hard disk per device for maximum redundancy: any hardware
component can fail and I can just use the other device.

The software setup is intentionally kept very simple: I use `rsync` (with
hardlinks) over SSH for backups, and serve files using Samba. That way, backups
are just files, immediately available, and accessible from another computer if
everything else fails.

## Conclusion

I hope this was interesting! If you have any detail questions, feel free to
reach out [via email](https://michael.stapelberg.ch/) or
[twitter](https://twitter.com/zekjur).

If you’re looking for more product recommendations (tech or otherwise), one of
my favorite places is the [wirecutter](https://thewirecutter.com/).
