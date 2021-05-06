---
layout: post
title:  "kinX: latency measurement"
date:   2018-04-17 17:51:00 +02:00
categories: Artikel
tags:
- kinX
---

This post is part of a [series of posts about the kinX project](/posts/2018-04-17-kinx).

### Latency measurement

End-to-end latency consists of 3 parts:

1. input latency (keyboard)
2. processing latency (computer)
3. output latency (monitor)

During the development of the kinX keyboard controller, I realized that
measuring processing latency was quite simple with my hardware: I could start a
timer when sending a key press HID report to the computer and measure the
elapsed time when I would receive a reply from the computer.

The key to send is the Caps Lock key, because unlike other keys it results in a
reply: a HID report telling the keyboard to turn the Caps Lock LED on.

<img src="/Bilder/kinx-latency-measurement-device.svg">

### Measurement device

To make this measurement technique accessible to as many people as possible, I
decided to pull it out of my kinX keyboard controller and instead build it using
the FRDM-K66F evaluation board, which uses the same microcontroller.

The FRDM-K66F can be bought for about 60 USD at big electronics shops, e.g. Digi-Key.

Find the firmware at https://github.com/kinx-project/measure-fw

### Baseline

To determine the lowest processing latency one can possibly get for userspace
applications on a Linux system, I wrote a small program which uses Linux’s evdev
API to receive key presses and react to a Caps Lock keypress as quickly as it
can by turning the Caps Lock LED on.

Find the program at https://github.com/kinx-project/measure-evdev

The following layers are exercised when measuring this program:

* USB host controller
* Linux kernel (USB and input subsystems)
* input event API (evdev)

Notably, graphical interfaces such as X11 or Wayland are excluded.

The measurements can be verified using Wireshark’s usbmon capturing, which
provides a view of the USB bus from the computer’s perspective, excluding USB
poll latency and USB transaction time.

Using Ubuntu 17.10, I measured a processing latency of 152 μs on average.

### Emacs

Now let’s see whether my current editor of choice adds significant latency.

Using a few lines of Emacs Lisp, I instructed Emacs to turn on the Caps Lock LED
whenever a key is inserted into the current buffer. In combination with
remapping the Caps Lock key to any other key (e.g. “a”), this allows us to
measure Emacs’s processing latency.

On the same Ubuntu 17.10 installation used above, Emacs 25.2.2 adds on average
278 μs to the baseline processing latency.

Find the code at https://github.com/kinx-project/measure-emacs

### End-to-end latency

With the kinX keyboard controller, we can achieve the following end-to-end latency:

contributor | latency
------------|------
Matrix scan | ≈ 208 μs
USB poll    | ≈ 125 μs
Linux       | ≈ 152 μs
Emacs       | ≈ 278 μs

<br>This sums up to ≈ 763 μs on average. On top of that, we have output latency
within \[0, 16ms\] due to the 60 Hz refresh rate of our monitors.

Note that using a compositor adds one frame of output latency.

### Input latency perception

A natural question to ask is how well humans can perceive input latency. After
all, keyboards have been manufactured for many years, and if input latency was
really that important, surely manufacturers would have picked up on this fact by
now?

I ran a little unscientific experiment in the hope to further my understanding
of this question at the most recent Chaos Communication Congress in Leipzig.

In the experiment, I let 17 people play a game on a specially prepared
keyboard. In each round, the game reconfigures the keyboard to either have
additional input latency or not, decided at random. The player can then type a
few keys and make a decision. If the player can correctly indicate whether
additional input latency was present in more than 50% of the cases, the player
is said to be able to distinguish latency at that level. On each level, the game
decreases the additional input latency: it starts with 100ms, then 75ms, then
50ms, etc.

The most sensitive player reliably recognized an additional 15ms of input
latency.

Some players could not distinguish 75ms of additional input latency.

Every player could distinguish 100ms of additional input latency.

My take-away is that many people cannot perceive slight differences in input
latency at all, explaining why keyboard manufacturers don’t optimize for low
latency.

Reducing input latency still seems worthwhile to me: even if the reduction
happens under the threshold at which you can perceive differences in input
latency, it buys you more leeway in the entire stack. In other words, you might
now be able to turn on an expensive editor feature which previously slowed down
typing too much.

### Conclusion

When I started looking into input latency, my keyboard had dozens of
milliseconds of latency. I found an easy win in the old firmware, then hit a
wall, started the kinX project and eventually ended up with a keyboard with just
0.33ms input latency.

Even if I had not reduced the input latency of my keyboard at all, I feel that
this project was a valuable learning experience: I now know a lot more about PCB
design, ARM microcontrollers, USB, HID, etc.

Typing on a self-built keyboard feels good: be it because of the warm fuzzy
feeling of enjoying the fruits of your labor, or whether the input latency
indeed is lower, I’m happy with the result either way.

Lastly, I can now decidedly claim that the processing latency of modern
computers is perfectly fine (remember our 152 μs + 278 μs measurement for
Linux + Emacs), and as long as you pick decent peripherals, your end-to-end
latency will be fine, too.

### What’s next?

By far the biggest factor in the end-to-end latency is the monitor’s refresh
rate, so getting a monitor with a high refresh rate and no additional processing
latency would be the next step in reducing the end-to-end latency.

As far as the keyboard goes, the matrix scan could be eliminated by wiring up
each individual key to a microcontroller with enough GPIO pins. The USB poll
delay could be eliminated by switching to USB 3, but I don’t know of any
microcontrollers which have USB 3 built-in yet. Both of these improvements are
likely not worth the effort.
