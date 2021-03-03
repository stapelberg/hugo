---
layout: post
title:  "Make your intercom smarter with an MQTT backpack"
date:   2021-03-13 16:54:00 +01:00
categories: Artikel
---

I bought the cheapest compatible BTicino intercom device (BT 344232 for 32 €)
that I could find on eBay, then soldered in 4 wires and added microcontrollers
to make it smart. It now connects to my [Nuki Opener Smart Intercom IOT
device](https://nuki.io/en/opener/), and to [my local MQTT Pub/Sub
bus](/posts/2021-01-10-mqtt-introduction/) (why not?).

{{< img src="intercom-modified-featured.jpg" alt="modified BTicino" >}}

## Background

In my [last post about the BTicino intercom from
November](/posts/2020-11-30-scs-processing-microcontroller/), I described how to
use a Teensy microcontroller to reliably interpret SCS bus signals and drive a
Nuki Opener (Smart Intercom).

Originally, I had hoped the Nuki developers would be able to fix their device
based on my SCS bus research, but they don’t seem to be interested. Instead,
their support actually suggested I run my microcontroller workaround
indefinitely!

Hence, I decided to work on the next revision to clean up my setup in terms of
cable clutter. I also figured: if I already need to run my own microcontroller,
I also want to connect it to my local [MQTT Pub/Sub
bus](/posts/2021-01-10-mqtt-introduction/) for maximum flexibility.

Unfortunately, the Teensy microcontroller lacks built-in WiFi, or any kind of
networking.

I switched to an ESP32-based microcontroller, but powering those from the SCS
bus seems like a bad idea: they draw a lot of power, and building small
high-quality power supplies is hard.

This made me scrap [my previous plans to make my own SCS send/receive
hardware](https://twitter.com/zekjur/status/1331646748989788160).

Instead, I wondered what the easiest yet most reliable approach might be to make
this intercom unit smart. Instead of building my own SCS hardware, could I use
the intercom unit itself to send the door unlock signal, and could I obtain the
unit’s already-decoded SCS bus signal?

## Finding the signals

Based on my previous research, I roughly knew what to expect: closest to the bus
terminals, there will be some components that filter the bus signal and convert
the 27V into a lower voltage. Connected to that power supply is a
microcontroller which deals with all user interface.

To learn more about the components, I first identified all [ICs (Integrated
Circuits)](https://en.wikipedia.org/wiki/Integrated_circuit) based on their
labeling. The following are relevant:

* [TI LM393](https://www.ti.com/lit/ds/symlink/lm393-n.pdf): Dual Comparators
* [TI LP2951](https://www.ti.com/lit/ds/symlink/lp2951-q1.pdf): Adjustable Micropower Voltage Regulators, 5V output
* [Microchip PIC16F684](http://ww1.microchip.com/downloads/en/devicedoc/41202c.pdf): 8-bit microcontroller

I connected my development intercom unit to [my SCS bus lab
setup](/posts/2020-11-30-scs-processing-microcontroller/#scs-lab-setup) and used
my oscilloscope to confirm expected signal levels based on the pinout from the
IC datasheets.

I settled on the following 4 relatively easily accessible signals and soldered
jumper wires to them:

* `5V` and `GND`: 5V, 100mA. Our QT Py microcontroller uses 7mA.
* `OPEN5V`: activates the button which unlocks the door
* `SCSRX5V`: converted SCS signal

{{< img src="signals.jpg" alt="BTicino signals" >}}

## Converting the signals

Because the BTicino intercom units runs at 5V, but more modern microcontrollers
run at 3.3V, we need to convert between the two voltages:

1. We need to convert a 3.3V signal to `OPEN5V` to trigger opening the door.

1. We need to convert `SCSRX5V` signal to 3.3V so that I can use an ESP32
   microcontroller to read the signal and place it on MQTT.

Here’s the corresponding schematic:

{{< img src="schematic.png" alt="schematic" >}}

## Microcontroller selection

I eventually decided to task a dedicated microcontroller with the signal
conversion, instead of having the WiFi-enabled microcontroller do everything,
for multiple reasons:

* Reliability. It turns out that using a hardware analog comparator results in a
  much higher signal quality than continuously sampling an ADC yourself, even
  when using the ESP32’s [ULP (Ultra Low Power)
  co-processor](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/ulp.html)
  to do the sampling.

* Easy implementation. Converting an SCS signal to a serial signal is literally
  [a single `delayMicroseconds(20);` call in the right
  place](/posts/2020-11-30-scs-processing-microcontroller/#analog-comparator-modification). Having
  a whole microcontroller for only this task eliminates any concurrency
  concerns. I have not had to debug or change the software even once in the last
  few months.

* Easy debugging/introspection. I can connect a standard USB-to-serial adapter
  and verify the signal is read correctly. This quickly narrows down issues on
  either side of the serial interface. Issues with the microcontroller side can
  be reproduced by sending serial data.

Here are the 2 microcontrollers I’m using in this project, plus the Teensy I
used previously:

| Microcontroller | WiFi | Analog Comparator | Price |
|-----------------|------|-------------------|-------|
| [Teensy 4.0](https://www.pjrc.com/store/teensy40.html)      | no   | yes               | 19 USD |
| [Adafruit QT Py](https://www.adafruit.com/product/4600)  | no   | yes               | 6 USD |
| [TinyPICO](https://www.tinypico.com/)        | yes  | no                | 20 USD |

If ESP32 boards such as the TinyPICO had a hardware Analog Comparator, I would
likely use just one microcontroller, but keep the serial interface on a GPIO for
easy debugging.

### Why the Adafruit QT Py?

The minimal function we need for our signal conversion device is to convert an
SCS signal (5V) to a serial signal (3.3V). For this conversion, we need a
hardware analog comparator and an output GPIO that we can drive independently,
so that we can modify the signal.

Additionally, the device should use as little power as possible so that it can
comfortably fit in the left-over energy budget of the intercom unit’s power
supply.

The smallest microcontroller I know of that comes with a hardware analog
comparator is the [Adafruit QT Py](https://www.adafruit.com/product/4600). It’s
a 32-bit Cortex M0+ (SAMD21) that can be programmed using the Arduino IDE, or
MicroPython (hence the name).

{{< img src="qtpy.jpg" alt="Adafruit QT Py" >}}

There are other SAMD21 boards with the same form factor, such as the [Seeeduino
XIAO](https://wiki.seeedstudio.com/Seeeduino-XIAO/).

### Why the TinyPICO ESP32 board?

When looking for a WiFi-enabled microcontroller, definitely go with something
ESP32-based!

The community around the Espressif ESP32 (and its predecessor ESP8266) is
definitely one of its biggest pluses: there are tons of Arduino sketches,
troubleshooting tips, YouTube videos, reference documentation, forum posts, and
so on.

The ESPs have been around since ≈2014, so many (largely-compatible) boards are
available. In fact, I started this project on an [M5Stack ESP32 Basic Core IoT
Development
Kit](https://m5stack.com/collections/m5-core/products/basic-core-iot-development-kit),
deployed it on an [Adafruit HUZZAH32 Breakout
Board](https://www.adafruit.com/product/4172) and ultimately ported it to the
[TinyPICO](https://www.tinypico.com/). Porting between the different
microcontrollers was really smooth: the only adjustments were pin numbers and
dropping in a TinyPICO helper library for its RGB LED, which I chose to use as a
power LED.

I chose the TinyPICO ESP32 board specifically for its small form factor and
convenience:

{{< img src="tinypico-comparison.jpg" alt="TinyPICO comparison with Adafruit Huzzah32 and Teensy 4.0" >}}

The TinyPICO is only 18mm × 32mm, slightly smaller than the Teensy 4.0’s 18mm × 35mm.

In comparison, the [Adafruit HUZZAH32 breakout
board](https://www.adafruit.com/product/4172) is gigantic with its 25mm ×
44mm. And that’s without the extra USB-to-serial adapter (FT232H in the picture
above) you need for programming, serial console and powering the board!

The TinyPICO does not need an extra adapter. You can plug it in and program it
immediately, just like the Teensy!

I’d like it if the next revision of the TinyPICO switched from Micro USB to USB
C.

If the TinyPICO is not for you (or unavailable), search for other boards that
contain the ESP32-PICO-D4 chip. For example, [DFRobot’s
ESP32-PICO-KIT](https://www.dfrobot.com/product-1941.html) or [Espressif’s own
ESP32-PICO-KIT](https://www.amazon.de/Espressif-ESP32-ESP32-PICO-KIT-Board-ESP32-PICO-D4/dp/B07J1YMB8R).

## Prototype

After testing everything on a breadboard, I soldered a horizontal pin header
onto the QT Py, connected it to my Sparkfun level shifter board and soldered the
remaining voltage divider components “flying”. The result barely fit into the
case, but worked flawlessly for weeks:

{{< img src="prototype.jpg" alt="prototype" >}}

## Backpack PCB for the QT Py

After verifying this prototype works well in practice, I miniaturized it into a
“backpack” PCB.

The backpack contains all the same parts as the prototype, but with fewer bulky
wires and connectors, and using only SMD parts. The build you see below uses
0602 SMD parts, but if I made another revision I would probably chose the larger
0805 parts for easier soldering.

{{< note >}}

If you only wanted to drive the Nuki Opener (without any networking), you could
easily do that from the QT Py itself and skip the TinyPICO.

{{< /note >}}

{{< img src="backpack.jpg" alt="QT Py with backpack" >}}

{{< img src="backpack-pcb.jpg" alt="QT Py with backpack PCB" >}}

## Assembly

To save some space in the intercom unit case, I decided to solder the jumper
wires directly onto the TinyPICO instead of using a pin header. I could have
gone one step further by cutting the wires at length and soldering them directly
on both ends, without any connectors, but I wanted to be able to easily unplug
and re-combine the parts of this project.

{{< img src="tinypico-wires.jpg" alt="wires soldered directly into the TinyPICO" >}}

From top to bottom, I made the following connections:

Pin | Color | Function
----|-------|----------
25  | <span style="background-color: #ff4136; padding: 0 .5em 0 .5em">red</span>   | `SCSRX_3V3`
27  | <span style="background-color: #2ecc40; padding: 0 .5em 0 .5em">green</span> | `OPEN_3V3`
15  | <span style="background-color: #0074d9; color: white; padding: 0 .5em 0 .5em">blue</span>  | Nuki Opener blue cable
14  | <span style="background-color: #ffdc00; padding: 0 .5em 0 .5em">yellow</span> | Nuki Opener yellow cable
4   | <span style="background-color: #b10dc9; color: white; padding: 0 .5em 0 .5em">purple</span> | floor ring button pushed
3V3 | <span style="background-color: white; padding: 0 .5em 0 .5em">white</span> | 3.3V for the floor ring button
5V  | <span style="background-color: #ff851b; padding: 0 .5em 0 .5em">orange</span> | power for the TinyPICO
GND | <span style="background-color: brown; color: white; padding: 0 .5em 0 .5em">brown</span> | ground for the TinyPICO
GND | <span style="background-color: brown; color: white; padding: 0 .5em 0 .5em">brown</span> | ground to the QT Py
GND | <span style="background-color: brown; color: white; padding: 0 .5em 0 .5em">brown</span> | ground to the Nuki Opener

The TinyPICO USB port is still usable for updating the software and serial console
debugging.

Here’s the TinyPICO connected to the QT Py inside the intercom unit:

{{< img src="intercom-modified-featured.jpg" alt="modified BTicino" >}}

The QT Py is powered by the intercom unit’s supply, and the TinyPICO I’m
powering with an external USB power supply and a cut-open USB cable. This allows
me to route the jumper wires through the intercom unit’s hole in the back,
through which a USB plug doesn’t fit:

{{< img src="final-installation.jpg" alt="final installation" >}}

## Software / Artifacts

You can find the Arduino sketches and KiCad files for this project at
https://github.com/stapelberg/intercom-backpack

For debugging, I found it useful to publish every single byte received from the
SCS bus on the `doorbell/debug/scsrx` MQTT topic. Full SCS telegrams are
published to `doorbell/events/scs`, so by observing both, you can verify that
retransmission suppression and SCS decoding work correctly.

Similarly, signaling a doorbell ring to the Nuki Opener can be debugged by
sending a message to MQTT topic `doorbell/debug/cmd/ring`.

Initially, it wasn’t clear to me whether the WiFi library would maintain the
connection indefinitely. After observing my microcontroller eventually
disappearing from my network, I added the `taskreconnect` FreeRTOS task, and
things have been stable since.

## Nuki Opener: verdict

I now have a Nuki Opener running next to my own microcontroller, so I can see
how well it works.

### setup

Setting up the Nuki is the worst part: their colorful cable is super flimsy and
loose, often losing contact. They should definitely switch to a cable with a
mechanical lock.

The software part of the setup is okay, but the compatibility with the SCS bus
is poor: I couldn’t get the device to work at all (see my initial post), and had
to resort to using my own microcontroller to drive the Nuki in analogue mode.

I’m disappointed that the Nuki developers aren’t interested in improving their
device’s compatibility and reliability with the SCS bus. They seem to
capture/replay the entire signal (including re-transmissions) instead of
actually decoding the signal.

### in my day-to-day

The push notifications I get on my iPhone from the Nuki are often
delayed. Usually the delay is a few seconds, but sometimes notifications arrive
hours later or just don’t arrive at all!

While the push notifications are sent from a Nuki server and hence need the
internet to function, the Nuki Bridge (translating Bluetooth Low Energey from
the Nuki Opener to WiFi) allows configuring notifications in the local network
via web hooks.

The Nuki Bridge’s notifications are much more reliable in my experience.

People sometimes ask why I use the Nuki Opener at all, given that I have some
infrastructure of my own, too. While opening the door and receiving
notifications is something I can do without the Nuki, too, I don’t want to spend
my spare time re-implementing the Nuki app (on multiple platforms) with its geo
fencing, friend invitations, ring to open, etc. In addition, the Nuki Opener
physical device has a nice ring sound and large push button to open the door,
both of which are convenient.

## Conclusion

My intercom is now much smarter! Doorbell notifications make their way to my
various devices via MQTT, and I can conveniently open the door from any device,
as opposed to rushing to the intercom unit in the hallway.

Compared to the previous proof-of-concepts and development installations, I feel
more confident in the current solution because it re-uses the intercom unit for
the nitty-gritty SCS bus communication details.

The overall strategy should be widely applicable regardless of the specific
intercom vendor/unit you have. Be sure to buy your own unit (don’t solder into
your landlord’s intercom unit!) and test in a separate lab setup first, of
course!
