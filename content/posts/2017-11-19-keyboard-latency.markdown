---
layout: post
title:  "Keyboard input latency"
date:   2017-11-19 22:45:00 +01:00
categories: Artikel
draft: yes
---

I positioned my keyboard as close as possible to the monitor, then used my
iPhone to shoot a slo-mo video of me pressing keys while running `sm(1)`.

To quickly get an unmodified copy, I opened Apple Photos (TODO) and shared the
file with Google Drive and downloaded it from there. Side note: an upspin
dirserver+fileserver iOS app would be amazing. TODO

Converted the video from Apple’s H264 into individual JPG frames:
```
ffmpeg -i IMG_1748.MOV frame%05d.png
```

For conveniently moving through the recording frame-by-frame, I opened the file
in `avidemux3_qt5`. Here is a timeline of frames:

1. frame 1595 LED off, no characters
2. frame 1596 LED on, no characters
3. frame 1600 LED on, screen starts updating
4. frame 1609 LED on, character appears (after animation)
1610
1611
1612
1613
1614
frame 1615 LED off

Each frame is 4.16ms long, so a latency of 4 frames is equivalent to 16.6ms.

frame 2796 led off
frame 2797 led on
frame 2798 led on, screen update
2799
2800
frame 2801 led off (10ms after led on)
latency of one is equivalent to 4.16ms

### Connectivity

TODO: measure whether the teensy code runs in <1ms, otherwise we delay the poll rate
TODO: change code to permanently scan, so that buffer is already full at poll time, and polls are shorter

TODO: teensy++ 2.0 (which i’m using currently) has no DMA.

Currently used pins: D0-D7, B0-B6, F0-F3 (leds), C0-C6
8+7+7(+4) = 26

Teensy 3.6 has: A9-A10 (10) + A22-A14 (8)
