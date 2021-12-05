---
layout: post
title:  "Fixing the Logitech MX Ergo Trackball mouse buttons"
date:   2021-12-05 13:23:20 +01:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1467471183700545539"
---

The mouse I use daily for many hours is Logitech’s [MX Ergo
trackball](https://www.logitech.com/en-ch/products/mice/mx-ergo-wireless-trackball-mouse.910-005179.html)
and I generally consider it the best trackball one can currently buy.

Unfortunately, after only a year or two of usage, the trackball’s mouse buttons
no longer function correctly. When clicking and dragging, they won’t hold down
the selection reliably.

The mouse buttons first broke in my private trackball, and later also the ones
in my work one!

After just buying a new one when the mouse buttons broke the first time, I
figured this time I wanted to try and fix the trackball myself.

{{< img src="logitech-mx-ergo-kailh.jpg" alt="Logitech MX Ergo and Kailh replacement switches" >}}

## Video recording

In this 27 minute video, you can look over my shoulder as I swap out the
worn-out Omron mouse buttons with Kailh replacement mouse buttons:

{{< youtube TBaYEFkk2RU >}}

The basic steps are:

1. Unscrew the outside Torx screws.
1. Unscrew the inside Philips screws.
1. Remove the PCB from the case and fix it securely for desoldering.
1. Desolder the switch: heat up all 3 pads as simultaneously as possible (add
   more solder → more flux!), then gently push down on the pins to make the
   switch fall out.
1. Cleanly remove all remaining solder, then insert the replacement switch,
   double-check you aligned it will on the PCB, and solder it.
1. Put everything back together.

## Replacement switches: Kailh GM 8.0

The replacement mouse buttons I’m using are [Kailh GM 8.0 from the Kailh
Official Store on
AliExpress](https://www.aliexpress.com/item/1005001286852407.html?spm=a2g0s.12269583.0.0.4a421ccfNFILvA),
which are advertised as “ultra high life”. Even if their life span is also only
a few years, I bought enough of them to probably replace them another 2 to 3
times per trackball.

The Kailh mouse buttons behave very similarly to the original Omron mouse
buttons. The click is very satisfying now, and reminds me of a brand-new
Logitech MX Ergo trackball. I wouldn’t call the Kailh ones better than the Omron
ones, but maybe others notice a difference?

One interesting side note: I noticed that when wearing noise canceling
headphones, it was very hard to tell the worn-out Omron mouse buttons from the
Kailh mouse buttons. The difference really is mostly in the sound, not in the
feel when pressing the button down!

## Why is the MX Ergo so unreliable?

There is a [1-hour video by Alex
Kenis](https://www.youtube.com/watch?v=v5BhECVlKJA) saying that Logitech
switched from 5V to 3.3V logic voltages, and this violates the minimum
electrical condition for the Omron D2FC-F, which causes oxidation.

Indeed, when I merely opened the switches and cleaned them up with a screw
driver, this seemed to help. But, opening everything up is so fiddly that one
might as well solder in new switches altogether :)
