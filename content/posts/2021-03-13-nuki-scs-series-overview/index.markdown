---
layout: post
title:  "Nuki Opener on SCS bus: Series Overview"
date:   2021-03-14 08:12:00 +01:00
categories: Artikel
---

When I bought a Nuki Opener, I had a lot of trouble getting it to work — it
turns out the device doesn’t properly decode the SCS bus at all, and only
captures and replays the signals with a generic code path. This approach does
not work well with the SCS bus, where every signal is repeated three times. The
repetition is good for reliability *when decoding SCS*, but bad for the pattern
matching and replaying approach the Nuki uses.

I wrote three blog posts about this issue:

* In September 2020, I first wrote about the [Nuki Opener with an SCS bus
  intercom (bTicino 344212)](/posts/2020-09-28-nuki-scs-bticino-decoding/). When
  I got the Nuki Opener, I discovered that it doesn’t work on the SCS bus in our
  house. In this article, I show how to capture and decode SCS bus signals.

* In November 2020, I published a workaround: [Fixing the Nuki Opener smart
  intercom IOT device (on the BTicino SCS bus intercom
  system)](/posts/2020-11-30-scs-processing-microcontroller/). The workaround
  consists of programming a separate microcontroller which decodes SCS bus
  signals and is connected to the Nuki Opener’s “analog doorbell” GPIO wiring
  method.

* In March 2021, I describe how I cleaned up my workaround in [Make your
  intercom smarter with an MQTT
  backpack](/posts/2021-03-13-smart-intercom-backpack/). Instead of having an
  exposed microcontroller replacing my intercom unit, in this article I show how
  to connect a microcontroller to the intercom unit’s SCS signal and “Open”
  button, which allows for a more reliable, more compact and actually simpler
  solution.
