---
layout: post
title:  "kinX: keyboard controller with <0.225ms input latency"
date:   2018-04-17 17:49:00 +02:00
categories: Artikel
tags:
- kinX
---

This post is part of a [series of posts about the kinX project](/posts/2018-04-17-kinx).

### Background

10 years ago I got a Kinesis Advantage keyboard. I wrote about the experience of
learning to touch-type using the ergonomic [NEO layout](https://neo-layout.org/)
in my (German) post [“Neo-Layout auf einer
Kinesis-Tastatur”](/posts/2009-01-01-neo_kinesis/).

The Kinesis Advantage is still the best keyboard I’ve ever used, and I use one
every day, both at the office and at home.

I had two reasons to start modifying the keyboard:

1. I prefer Cherry MX blue key switches over the Cherry MX brown key switches
   the Kinesis comes with. Nowadays, you can get a Kinesis with Cherry MX red
   key switches, which felt okay in a quick test.

2. The original keyboard controller has (had?) a bug where modifier keys such as
   Shift would get stuck at least once a week: you would press Shift, press A,
   release A, release Shift, press A and see AA instead of Aa.

I solved issue ① with the help of the excellent Kinesis technical support, who
sold me unpopulated PCBs so that I could solder on my own key switches.

Issue ② was what lead to my first own keyboard controller build, which I
documented in [“Hacking your own Kinesis keyboard
controller”](/posts/2013-03-21-kinesis_custom_controller/) (2013).

Then, the topic of input latency popped into my filter bubble, with excellent
 posts such as [Pavel Fatin’s “Typing with
pleasure”](https://pavelfatin.com/typing-with-pleasure/). I started wondering
what input latency I was facing, and whether/how I could reduce it.

Given that I was using a custom keyboard controller, it was up to me to answer
that question. After trying to understand and modify the firmware I had been
using for the last 4 years, I realized that I first needed to learn much more
about how keyboards work.

I firmly believe that creating a good environment is vital for development,
especially for intrinsically-motivated side projects like this one. Hence, I set
the project aside until a colleague gifted me his old Kinesis which had
intermittent issues. I removed the electronics and started using that keyboard
as my development keyboard.

### Sources of input latency

A keyboard controller has 3 major tasks:

* **matrix scan**: to avoid physically connecting every single key switch
  directly to a microcontroller (requiring a large number of GPIO pins), most
  keyboards use a matrix. See [“How to make a keyboard — the
  matrix”](http://blog.komar.be/how-to-make-a-keyboard-the-matrix/) for a good
  explanation.

* **debouncing**: when pressing a key switch, it doesn’t cleanly change from a
  low voltage level to a high voltage level (or vice-versa). Instead, it
  bounces: the voltage level rapidly oscillates until it eventually reaches a
  stable steady state. Because one key press shouldn’t result in a whole bunch
  of characters, keyboard controllers need to debounce the key press.

* **USB**: nowadays, keyboards use USB (for example to be compatible with
  laptops, which generally don’t have PS/2 ports), so the keyboard’s state needs
  to be communicated to the computer via USB.

Here’s an illustration of the timing of a key press being handled by a naive
keyboard controller implementation:

<img src="/Bilder/kinx-input-latency-sources.svg">

In the worst case, a key press happens just after a keyboard matrix scan. The
first source of latency is the time it takes until the next keyboard matrix scan
happens.

Depending on the implementation, the key press now sits in a data structure,
waiting for the debounce time to pass.

Finally, once the key press was successfully debounced, the device must wait
until the USB host polls it before it can send the HID report.

Unless the matrix scan interval is coupled to the USB poll interval, the delays
are additive, and the debounce time is usually constant: in the best case, a key
press happens just before a matrix scan (0ms) and gets debounced (say, 5ms) just
before a USB poll (0ms).

### Teensy 3.6 controller (for learning)

My old keyboard controller used the
[Teensy++](https://www.pjrc.com/teensy/index.html), which is fairly dated at
this point. I decided a good start of the project would be to upgrade to the
current Teensy 3.6, cleaning up the schematics on the way.

<img src="/Bilder/kinx-teensy36.jpg" width="100%">

To ensure I understand all involved parts, I implemented a bare-metal firmware
almost from scratch: I cobbled together the required startup code, USB stack
and, most importantly, key matrix scanning code.

In my firmware, the Teensy 3.6 runs at 180 MHz (compared to the Teensy++’s 16
MHz) and scans the keyboard matrix in a busy loop (as opposed to on USB
poll). Measurements confirmed a matrix scan time of only 100μs (0.1ms).

I implemented debouncing the way it is described in [Yin Zhong’s “Keyboard
Matrix Scanning and
Debouncing”](https://summivox.wordpress.com/2016/06/03/keyboard-matrix-scanning-and-debouncing/):
by registering a key press/release on the rising/falling edge and applying the
debounce time afterwards, effectively eliminating debounce latency.

Note that while the Cherry MX datasheet specifies a debounce time of 5ms, I
found it necessary to increase the time to 10ms to prevent bouncing in some of
my key switches, which are already a few years old.

I set the USB device descriptor’s poll interval to 1, meaning poll every 1 USB
micro frame, which is 1ms long with USB 1.x (Full Speed).

This leaves us at an input latency within [0ms, 1.1ms]:

* ≤ 0.1ms scan latency
* 0ms debounce latency
* ≤ 1ms USB poll latency

Can we reduce the input latency even further? The biggest factor is the USB poll
interval.

### USB High Speed

With USB 2.0 High Speed, the micro frame duration is reduced to 125μs
(0.125ms). The NXP MK66F micro controller in the Teensy 3.6 has two USB ports:

1. the Full Speed-only USBFS port, which is used by the Teensy 3.6
2. the High Speed-capable USBHS port, which the Teensy optionally uses for host
   mode, with experimental software support (at the time of writing)

<img src="/Bilder/kinx-usbhs-breakout.jpg" width="100%">

While the software support was a road block which could conceivably be solved, I
also faced a mechanical problem: the available space in the Kinesis keyboard and
the position of the USB High Speed port pins on the Teensy 3.6 unfortunately
prevented installing any sort of breakout board to actually use the port.

I decided to move from the Teensy 3.6 to my own design with the same
microcontroller.

### MK66F keyboard controller

{{< img src="kinx-mk66f.jpg" alt="MK66F" >}}

To make development pleasant, I connected a USB-to-serial adapter (to UART0) and
a “rebootor” (to PROGHEAD): another Teensy with a special firmware to trigger
programming mode. This way, I could set my editor’s `compile-command` to `make
&& teensy_loader_cli -r …`, compiling the code, uploading and booting into the
resulting firmware with a single keyboard shortcut.

I based the firmware for this controller on NXP’s SDK examples, to ensure I get
a well-tested and maintained USB stack for the USBHS port. I did some
measurements to confirm the stack does not add measurable extra latency, so I
did not see any value in me maintaining a custom USB stack.

The firmware can be found at https://github.com/kinx-project/mk66f-fw

The hardware can be found at https://github.com/kinx-project/mk66f-hw

Using USB 2.0 High Speed leaves us at an input latency within [0ms, 0.225ms]:

* ≤ 0.1ms scan latency
* 0ms debounce latency
* ≤ 0.125ms USB poll latency

### Lessons learnt

* In the future, I will base custom designs on the vendor’s development board
  (instead of on the Teensy). This way, the vendor-provided code could be used
  without any modifications.

* While the Teensy bootloader means getting started with the microcontroller
  just requires a USB port, using a JTAG connector for development would be more
  powerful: not only does it replace the combination of Teensy bootloader,
  serial and rebootor, but it also supports debugging with gdb.

### Next up

The [second post motivates and describes building a drop-in replacement USB
hub](/posts/2018-04-17-kinx-usb-hub/) for the Kinesis Advantage keyboard.
