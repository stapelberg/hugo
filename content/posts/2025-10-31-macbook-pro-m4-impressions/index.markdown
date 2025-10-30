---
layout: post
title:  "My impressions of the MacBook Pro M4"
date:   2025-10-31 11:04:59 +01:00
categories: Artikel
tags:
- pc
---

I have been using a MacBook Pro M4 as my portable computer for the last half a
year and wanted to share a few short impressions. As always, I am not a
professional laptop reviewer, so in this article you won’t find benchmarks, just
subjective thoughts!

Back in 2021, I wrote about the [MacBook Air
M1](/posts/2021-11-28-macbook-air-m1/), which was the first computer I used that
contained Apple’s own ARM-based CPU. Having a silent laptop with long battery
life was a game-changer, so I wanted to keep those properties.

When the US government announced tariffs, I figured I would replace my 4-year
old MacBook Air M1 with a more recent model that should last a few more
years. Ultimately, Apple’s prices remained stable, so, in retrospect, I could
have stayed with the M1 for a few more years. Oh well.

## The nano-textured display

I went to the Apple Store to compare the different options in
person. Specifically, I was curious about the display and whether the increased
weight and form factor of the MacBook Pro (compared to a MacBook Air) would be
acceptable. Another downside of the Pro model is that it comes with a fan, and I
really like absolutely quiet computers. Online, I read from other MacBook Pro
owners that the fan mostly stays off.

In general, I would have preferred to go with a MacBook Air because it has
enough compute power for my needs and I like the case better (no ventilation
slots), but unfortunately only the MacBook Pro line has the better displays.

Why aren’t all displays nano-textured? The employee at the Apple Store presented
the trade-off as follows: The nano texture display is great at reducing
reflections, at the expense of also making the picture slightly less vibrant.

I could immediately see the difference when placing two laptops side by side:
The bright Apple Store lights showed up very prominently on the normal display
(left), and were almost not visible at all on the nano texture display (right):

{{< img src="2025-10-30-macbooks-displays.jpg" alt="MacBook Air (left) vs. MacBook Pro (right)" >}}

Personally, I did not perceive a big difference in “vibrancy”, so my choice was
clear: I’ll pick the MacBook Pro over the MacBook Air (despite the weight) for
the nano texture display!

After using the laptop in a number of situations, I am very happy with this
choice. In normal scenarios, I notice no reflections at all (where my previous
laptop did show reflections!). This includes using the laptop on a train (next
to the window), or using the laptop outside in daylight.

## Specs: M4 or M4 Pro?

(When I chose the new laptop, Apple’s M4 chips were current. By now, they have
released the first devices with M5 chips.)

I decided to go with the MacBook Pro with M4 chip instead of the M4 **Pro** chip
because I don’t need the extra compute, and the M4 needs less cooling — the M4
Pro apparently runs hotter. This increases the chance of the fan staying off.

Here are the specs I ended up with:

* 14" Liquid Retina XDR Display with nano texture
* Apple M4 Chip (10 core CPU, 10 core GPU)
* 32 GB RAM (this is the maximum!), 2 TB SSD (enough for this computer)

## Impressions

One thing I noticed is that the MacBook Pro M4 sometimes gets warm, even when it
is connected to power, but is suspended to RAM (and has been fully charged for
hours). I’m not sure why.

Luckily, the fan indeed stays silent. I think I might have heard it spin up once
in half a year or so?

The battery life is amazing! The previous MacBook Air M1 had amazing all-day
battery life already, and this MacBook Pro M4 lasts even longer. For example,
watching videos on a train ride (with VLC) for 3 hours consumed only 10% of
battery life. I generally never even carry the charger.

Because of that, Apple’s re-introduction of MagSafe, a magnetic power connector
(so you don’t damage the laptop when you trip over it), is nice-to-have but
doesn’t really make much of a difference anymore. In fact, it might be better to
pack a USB-C cable when traveling, as that makes you more flexible in how you
use the charger.

## 120 Hz display

I was curious whether the 120 Hz display would make a difference in practice. I
mostly notice the increased refresh rate when there are animations, but not,
for example, when scrolling. 

One surprising discovery (but obvious in retrospect) is that even non-animations
can become faster. For example, when running a Go web server on `localhost`, I
noticed that navigating between pages by clicking links felt faster on the 120
Hz display!

The following illustration shows why that is, using a page load that takes 6ms
of processing time. There are three cases (the illustration shows an average
case and the worst case):

1. Best case: Page load finishes *just before* the next frame is displayed: no delay.
2. Worst case: Page load finishes *just after* a frame is displayed: one frame of delay.
3. Most page loads are somewhere in between. We’ll have 0.x to 1.0 frames of delay

{{< img src="2025-10-31-delay-60-vs-120.svg" alt="delay" >}}

As you can see, the waiting time becomes shorter when going from 60 Hz (one
frame every 16.6ms) to 120 Hz (one frame every 8.3ms). So if you’re working with
a system that has <8ms response times, you might observe actions completing (up
to) twice as fast!

I don’t notice going back to 60 Hz displays on computers. However, on phones,
where a lot more animations are a key part of the user experience, I think 120
Hz displays are more interesting.

## Conclusion

My ideal MacBook would probably be a MacBook Air, but with the nano-texture display! :)

I still don’t like macOS and would prefer to run Linux on this laptop. But
[Asahi Linux](https://asahilinux.org/) still needs some work before it’s usable
for me (I need external display output, and M4 support). This doesn’t bother me
too much, though, as I don’t use this computer for serious work.
