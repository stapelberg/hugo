---
layout: post
title:  "kinX: keyboard without input latency"
date:   2017-12-25 07:45:00 +01:00
categories: Artikel
draft: yes
---

tl;dr: I built a keyboard with < 300 μs of input latency (0.11ms scan, 0.125ms USB)

### Background

Recently, input latency has become a more widely discussed topic in my circles: good posts include [Pavel Fatin’s Typing With Pleasure](https://pavelfatin.com/typing-with-pleasure/) and [Dan Luu’s Input Lag](https://danluu.com/input-lag/), each of which contain more references.

This made me curious: I wanted to measure the input latency of the [custom keyboard controller](TODO) which I use, and possibly reduce it for a possibly more pleasant computing experience.

This post describes what I have learnt in the process.

### Terminology

Within this post, the term “input latency” describes the time between a key switch electronically registering as closed (or pressed), and the userspace of the computer processing the key press.

Notably, this definition excludes:

1. processing latency: how long Emacs takes until it instructs new content to be shown on the screen
2. output latency (or display latency): how long updated display contents take to be visible to your eyes

Make no mistake: processing and output latency are important. However, one needs
to start somewhere, so let’s start understanding and eliminating input latency.

### Sources of input latency

A computer keyboard is an array of switches, either all individually or, more commonly, in a matrix arrangement wired up to a microcontroller or [IC](TODO).

On a high level, the following 3 parts determine input latency:

1. Scan rate
2. Debouncing
3. USB polling interval/transmission

Note that — unlike Dan Luu — I don’t count key travel as a source of input latency. For many years, I’ve been a fan of the Cherry MX key switches, specifically the blue version. I’m not looking to change my key switches, so for the time being, I just accept their key travel time as-is.

TODO: visualization of how the parts relate

### Eliminating latency: scan rate


#### Key matrix

There are two factors which determine the scan rate: how long each scan takes,
and how frequently a scan is started.

The scan duration is determined by:
* the size of the key matrix, (kinX: 15 rows by 7 columns)
* the speed of the keyboard controller (kinX: 180 MHz)
* the TODO (rise and fall time?), i.e. the time it takes for a signal to propagate
  (kinX: 900 cycles == 5μs)
* the number and duration of interruptions

On the kinX, the measured scan duration is 20690 cycles (0.11ms). Scans are done
back-to-back, resulting in about 9000 scans per second, or a **scan rate of 9 kHz**.

On the kinX, the matrix is connected such that all columns can be read with a
single 32-bit memory access.

#### Individual wiring

When each key switch is individually wired up to the keyboard controller, one can use interrupts to be notified within a few cycles (TODO: verify) of a key press.

The downside of this approach is that you need a microcontroller with a lot of
GPIO pins, and you need a lot of wiring. The wiring is doable, but the high
number of required GPIO pins necessitates a custom microcontroller design, which
is a significant increase in complexity for this project.

In my measurements, scanning takes 20690 CPU cycles (0.11ms). Typically, this is
a very small fraction of the total latency, so it usually does not make sense to
focus on optimizing it away.

Hence, most keyboards use a key matrix.

### Eliminating latency: debouncing

As described in [post](TODO), key switches don’t make perfect contact: when pressing or releasing a key switch, it will bounce for a certain duration ([Cherry MX: < 5 ms](TODO: data sheet)).

The naive strategies of scanning slower than the key bounce duration or waiting for the key bounce duration to pass before registering a key as pressed both add a fixed additional input latency of at least 5 ms.

Luckily, there is a viable strategy which

TODO: why not also debounce on the falling edge? should work with the same assumption

TODO: state machine in graphviz?

### Eliminating latency: USB polling

Many posts list USB polling as the biggest issue with input latency, and often rightfully so. As a quick refresher, USB can run in the following speeds:

| Speed      | since USB | Bandwidth | Frame length   |
| ---------- | --------- | :-------: | :------------: |
| Low Speed  | 1.0 |   1.5 Mbit/s    | 10ms |
| Full Speed | 1.0 |  12 Mbit/s      | 1ms |
| High speed | 2.0 | 480 Mbit/s      | 125μs

The value of interest is the poll interval, which is specified in the device’s endpoint configuration descriptor (`bInterval`) in units of USB frames (!).

This means that a Full Speed USB device cannot go faster than a 1ms poll interval.

Hence, the kinX uses the Teensy 3.6’s secondary USB port with its USB High Speed controller. The poll interval is set to `bInterval == 1`, i.e. 125μs.

### Measurement setup

To verify my setup, I did some measurements with my iPhone SE’s 240 fps camera,
see [Appendix A](TODO) for details. A 240 fps camera is too slow to make
statements about effects below 4.16ms, so I settled on the following measurement
setup:

I made my keyboard firmware store a microsecond timestamp whenever Caps Lock
registers as pressed, and whenever the LED state changes to include Caps Lock.

These measurements establish an upper bound on input latency: they also include
the time it takes for the SET_REPORT USB request to reach the microcontroller.

#### Endpoint: graphics system

Both X11 and Wayland come with logic to handle the Caps Lock key by default,
making them very easy to measure without any changes.

#### Endpoint: evdev

I wrote an evdev-based program which turns on the Caps Lock LED upon reading a
Caps Lock key press. This mimics the architecture of X11 or Wayland, which also
read input events via evdev, but discards any implementation-specific processing
latency.

#### Endpoint: application software (Emacs)

I wrote a little bit of Emacs Lisp which will turn on the Caps Lock LED (via an
X11 API) as soon as a key was inserted into the current buffer.

### Measurement results

TODO

### Conclusion

### Appendix A: visual measurement

* iPhone SE
