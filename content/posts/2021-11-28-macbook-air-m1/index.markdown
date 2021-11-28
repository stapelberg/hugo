---
layout: post
title:  "MacBook Air M1: the best laptop?"
date:   2021-11-28 16:50:00 +01:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1464986951392673807"
---

You most likely have heard that Apple switched from Intel CPUs to their own,
ARM-based CPUs.

Various early reviews touted the new MacBooks, among the first devices with the
ARM-based M1 CPU, as the best computer ever. This got me curious: after years of
not using any Macs, would an M1 Mac blow my mind?

In this article, I share my thoughts about the MacBook Air M1, after a year of
occasional usage.

{{< img src="mba.jpg" alt="MacBook Air M1" >}}

## Energy efficiency

The M1 CPU is remarkably energy-efficient. This has two notable effects:

1. The device does not have a fan, and **stays absolutely quiet**. This is
   pretty magical, and I now notice my ThinkPad’s fan immediately.
1. The **battery lasts many hours**, even with demanding use-cases like video
   conferencing.

When it comes to energy efficiency, Apple sets the bar. All other laptops should
be fanless, too! And the battery life really is incredible: taking notes in
Google Docs (via WiFi) while at a conference for many hours left me with well
over 80% of battery at the end of the day!

I briefly lent the computer to someone and got it back with a VPN client
installed. The battery life was considerably shortened by that VPN client and
recovered once I uninstalled it. So if you’re not seeing great battery life,
maybe a single program is ruining your experience.

The fast wakeup feature that was heavily stressed during the initial
introduction (to some ridicule) is actually pretty nice! I now notice having to
wait for my ThinkPad to wake up.

Battery life during standby is great, too. Anecdotally, when leaving my ThinkPad
lying around, it never survives until I plug it in again. The MacBook survives
every single time.

## Chipset advantage?

Now, given that Apple controls the entire machine, does that mean they now offer
features that other computers cannot offer yet?

My personal bar for this question is whether a computer can be used with my
[bandwidth-hungry 8K monitor](/posts/2017-12-11-dell-up3218k/), and the
disappointing news is that the MacBook Air M1 cannot drive the 8K monitor with
its 7680x4320 pixels resolution (at 60 Hz, using 2 DisplayPort links), not even
with [an external USB-C
dock](https://www.displaylink.com/products/find?vid_dp=1&usbc=1).

Maybe future hardware generations add support for 8K displays, but for my
day-to-day, Apple’s complete control doesn’t improve anything.

## Built-in peripherals

The screen is great! Everything looks sharp, colors are vibrant and brightness
is good.

As usual, the touchpad (which Apple calls “trackpad”) is great, much better than
any touchpad I have ever used on a PC laptop. Apple trackpads have always had
this advantage since I know them, and I don’t know why PC touchpads don’t seem
to get any better? 🤔

Apple brought back their [scissor mechanism
keyboards](https://www.macrumors.com/guide/butterfly-keyboard-vs-scissor-keyboard/),
which is a very welcome change. I have witnessed so so many problems with the
old butterfly mechanism keyboards.

This first MacBook Air M1 model has no MagSafe. Apple added MagSafe in the
MacBook Pro M1 in late 2021. I hope they’ll eventually expand MagSafe to all
notebooks.

## Peripherals: not enough ports

Staying in peripheral-land, let me first state that this MacBook’s **2 USB-C
ports are not enough**!

When working on the go, after plugging in power, I can plug in a wired ethernet
adapter (wireless can be spotty), but then won’t have any ports left for my
ergonomic keyboard and mouse.

For video conferencing, I can plug in power (to ensure I won’t run out of
battery), connect a table microphone, but won’t have any ports left for a decent
webcam. This is particularly annoying because this MacBook’s built-in webcam is
really bad, and the main reason why reviewers don’t give the MacBook a perfect
score ([example review on
YouTube](https://www.youtube.com/watch?v=OEaKQ0pxQsg)).

So, in practice, you need to carry a USB-C dock, or at least a USB hub, with
your laptop when you anticipate possibly needing any peripherals. #donglelife

## Not enough RAM for local software development

Hardware-wise, the biggest pain point for software developers is the small
amount of RAM: both the MacBook Air M1 and the MacBook Pro M1 (13") can be
configured with up to 16 GB of RAM. Only the newer MacBook Pro M1 14" or 16"
(introduced late 2021) support more RAM.

To be clear, 16 GB RAM is enough to do software development in general, but it
can quickly become limiting when you deal with larger programs or data sets.

In my ThinkPad, I have 64 GB of RAM, which allows for a lot more VMs, large
index data structures, or just plenty of page cache. With the ThinkPad, I don’t
have to worry about RAM.

Of course, there are strategies around this. Maybe your projects are large
enough to warrant maintaining a remote build cluster, and you can run your test
jobs in a staging environment. The MacBook makes for a fine thin client —
provided your internet connection is fast and stable.

## Operating System: macOS

I am talking about Operating Systems at a very high level in this section. Many
use-cases will work fine, regardless of the Operating System one uses. I can
typically get by with a browser and a terminal program.

So, this section isn’t a nuanced or fair review or critique of macOS or anything
like that, just a collection of a few random things I found notable while
playing with this device :)

My favorite way to install macOS is Internet Recovery. You can install a blank
disk in your Mac and start the macOS installer via the internet! The Mac will
even remember your WiFi password. The closest thing I know in the PC world is
[netboot.xyz](https://netboot.xyz/), and that needs to be installed in your
local network first.

Similarly, Apple’s integration when using multiple devices seems pretty
good. For example, the Mac will offer to switch to your iPhone’s mobile
connection when it loses network connectivity.

But, just like in all other operating systems, there is plenty in macOS to
improve.

For example, software updates on the Mac still take 30 minutes (!) or so, which
is entirely unacceptable for such a fast device! In particular, Apple seems to
be (partially?) using immutable file system snapshots to distribute their
software, so I don’t know why [distri can install and update so much
faster](https://distr1.org/).

Speaking of Operating System shortcomings, I have observed how [APFS (the Apple
File System)](https://en.wikipedia.org/wiki/Apple_File_System) can get into a
state in which it cannot be repaired, which I found pretty concerning! Automated
and frequent backups of all on-device data is definitely a must.

Slow software updates are annoying, and having little confidence in the file
system makes me uneasy, but what’s really a dealbreaker is that my preferred
keyboard layout does not work well on macOS: see [Appendix A: NEO keyboard
layout](#neo).

## Linux? 🐧

So given my preference for Linux, could I just use Linux instead?

Unfortunately, while [Asahi Linux](https://asahilinux.org) is making great
progress in bringing Linux to the M1 Macs, it seems like it’ll still be many
months before I can install a Linux distribution and expect it to just work on
the M1 Mac.

Until then, check out the [Asahi Linux Progress Report blog
posts](https://asahilinux.org/blog/)!

## Intel to M1 architecture transition

Apple developed the [Rosetta 2 dynamic binary
translator](https://en.wikipedia.org/wiki/Rosetta_(software)#Rosetta_2) which
transparently handles non-M1 programs, and so far it seems to work fine! All the
things I tried just worked, and architecture never seemed to play a role during
my usage.

## Conclusion

The MacBook Air M1 is indeed impressive! It’s light, silent, fast and the
battery life is amazing. If these points are the most important to you in a
laptop, and you’re already in the Mac ecosystem, I imagine you’ll be very happy
with this laptop.

But is the M1 really so mind-blowing that you should switch to it no matter
what? No. As a long-time Linux user who is primarily developing software, I
prefer my [ThinkPad X1
Extreme](/posts/2021-06-05-laptop-review-lenovo-thinkpad-x1-extreme-gen2/) with
its plentiful peripheral connections and lots of RAM.

I know it’s not an entirely fair comparison: I should probably compare the
ThinkPad to the newer MacBook **Pro** models (not MacBook Air). But I’m not a
professional laptop reviewer, I can only speak about these 2 laptops that I
found interesting enough to personally try.

## Appendix A: NEO keyboard layout {#neo}

The macOS implementation of the [NEO keyboard layout](https://neo-layout.org/)
has a number of significant incompatibilities/limitations: its layer 3 does not
work correctly. Layer 3 contains many important common characters, such as `/`
(`Mod3 + i`, i.e. Caps Lock + i) or `?` (`Mod3 + s`).

I installed the current `neo.keylayout` file (2019-08-16) as described on the
[NEO download page](https://neo-layout.org/Download/).

In order to make `/` and `?` work in Google Docs, I had to enable the additional
Karabiner rule *“Prevent all layer 3 keys from being treated as option key
shortcut”* (see also: [this GitHub
issue](https://github.com/jgosmann/neo2-layout-osx/issues/6#issuecomment-604622834))

---

I encountered the following issues, ordered by severity:

**Issue 1**: I cannot use Emacs at all! I installed the emacsformacosx.com
version (also tried homebrew), but cannot enter keys such as `/` or `?`. Emacs
interprets these as `M-u` instead.

The Karabiner rule *“Prevent all layer 3 keys from being treated as option key
shortcut”* that fixed this issue in Google Docs does not help for
Emacs. Removing it from Karabiner changes behavior, but Emacs still recognizes
`M-i` instead of `/`, so it’s broken with or without the rule.
  
**Issue 2**: In the Terminal app, I cannot enable the *“Use Option as Meta key”*
keyboard option, otherwise all layer 3 keys function as meta shortcuts (`M-i`)
instead of key symbols (`/`).

I commonly use the Meta key to jump around word-wise: `Alt+b` / `Alt+f` on a
PC. Since I can’t use Option + b / Option + f on a Mac, I need to use Option +
arrow keys instead, which works.

Since the Option key does not work as Meta key, I need to press (and release!)
the Escape key instead. This is pretty inconvenient in Emacs in a terminal.

**Issue 3**: In Gmail in Chrome, the search keyboard shortcut (`/`) is not
recognized.

I [reported this problem
upstream](https://git.neo-layout.org/neo/neo-layout/issues/590), but there seems
to be no solution.

---

I’m not sure why these programs don’t work well with NEO. I tried BBEdit for
comparison, and it had no trouble with (macOS-level) shortcuts such as
`command + /` and `option + command + /`.

On Linux, the NEO layout works so much better. I’m really not in the mood to
continuously fight with my operating system over keyboard input and shortcuts.
