---
layout: post
title:  "Can Dell’s 6K monitor beat their 8K monitor?"
date:   2023-07-03 20:47:00 +02:00
categories: Artikel
---

For the last 10 years, I have been interested in hi-DPI monitors, and recently I
read about an interesting new monitor: [Dell’s 32-inch 6K monitor
(U3224KBA)](https://www.dell.com/de-ch/shop/dell-ultrasharp-32-6k-monitor-u3224kba/apd/210-bhnx/monitore-und-monitorzubeh%C3%B6r),
a productivity monitor that offers plenty of modern connectivity options like
DisplayPort 2, HDMI 2 and Thunderbolt 4.

My current monitor is a [Dell 32-inch 8K monitor
(UP3218K)](/posts/2017-12-11-dell-up3218k/), which has a brilliant picture, but
a few annoying connectivity limitations and quirks — it needs two (!)
DisplayPort cables on a GPU with MST support, meaning that in practice, it only
works with nVidia graphics cards.

I was curious to try out the new 6K monitor to see if it would improve the
following points:

* Does the 6K monitor work well with most (all?) of my PCs and laptops?
* Is 6K resolution enough, or would I miss the 8K resolution?
* Is a matte screen the better option compared to the 8K monitor’s glossy finish?
* Do the built-in peripherals work with Linux out of the box?

I read [a review on
heise+](https://www.heise.de/tests/32-Zoll-Display-mit-6K-und-USB-C-Dock-Dell-UltraSharp-U3224KBA-im-Test-9189751.html)
(also included in their c't magazine), but the review can’t answer these
subjective questions of mine.

So I ordered one and tried it out!

{{< img src="IMG_2383_featured.jpg" >}}

## Compatibility

The native resolution of this monitor is 6144x3456 pixels.

To drive that resolution at 60 Hz, about 34 Gbps of data rate is needed.

DisplayPort 1.4a only offers a data rate of 25 Gbps, so your hardware and driver
need to support [Display Stream Compression
(DSC)](https://en.wikipedia.org/wiki/Display_Stream_Compression) to reach the
full resolution at 60 Hz. I tried using DisplayPort 2.0, which supports 77 Gbps
of data rate, but the only GPU I have that supports DisplayPort 2 is the Intel
A380, which I could not get to work well with this monitor (see the next
section).

HDMI 2.1 offers 42 Gbps of data rate, but in my setup, the link would still
always use DSC.

Here are the combinations I have successfully tried:

| Device                                 | Cable  | OS / Driver                   | Resolution                        |
|----------------------------------------|--------|-------------------------------|-----------------------------------|
| MacBook Air M1                         | TB 3   | macOS 13.4.1                  | native @ 60 Hz,<br> 8.1Gbps       |
| GeForce RTX 4070<br>(DisplayPort 1.4a) | mDP-DP | Windows 11 21H2               | native @ 60 Hz,<br> 12Gbps DSC    |
| GeForce RTX 4070                       | mDP-DP | Linux 6.3<br>nVidia 535.54.03 | native @ 60 Hz,<br> 8.1Gbps DSC   |
| GeForce RTX 4070<br>(HDMI 2.1a)        | HDMI   | Windows 11 21H2               | native @ 60 Hz,<br> 8.1Gbps DSC   |
| GeForce RTX 4070                       | HDMI   | Linux 6.3<br>nVidia 535.54.03 | native @ 60 Hz,<br> 6Gbps 3CH DSC |
| GeForce RTX 3060                       | HDMI   | Linux 6.3<br>nVidia 535.54.03 | native @ 60 Hz,<br> 6Gbps 3CH DSC |
| ThinkPad X1 Extreme                    | TB 4   | Linux 6.3<br>nVidia 535.54.03 | native @ 60 Hz,<br> 8.1Gbps DSC   |

{{< note >}}

**Note:** on the ThinkPad X1 Extreme, I had to [set the nVidia GPU as primary
GPU](https://docs.fedoraproject.org/en-US/quick-docs/how-to-set-nvidia-as-primary-gpu-on-optimus-based-laptops/). When
the nVidia GPU is available, but routed through the Intel GPU, the native
resolution can be configured, but without hardware acceleration applications
like Chrome or Firefox are unusably slow.

{{< /note >}}

The MacBook Air is the only device in my test that reaches full resolution
without using DSC.

## Compatibility issues

Let’s talk about the combinations that did not work well.

### Too old nVidia driver (< 535.54.03): not at native resolution

You need a quite recent version of the nVidia driver, as they **just recently**
[shipped support for
DSC](https://github.com/NVIDIA/open-gpu-kernel-modules/discussions/238) at high
resolutions. I successfully used DSC with 535.54.03.

With the “older” 530.41.03, I could only select 6016x3384 at 60 Hz, which is not
the native resolution of 6144x3456 at 60 Hz.

| Device                                 | Cable  | OS / Driver                            | Resolution                            |
|----------------------------------------|--------|----------------------------------------|---------------------------------------|
| GeForce RTX 4070<br>(DisplayPort 1.4a) | mDP-DP | Linux 6.3<br>nVidia 530.41.03          | native @ 30 Hz only,<br> 6016x3384@60 |
| GeForce RTX 4070<br>(HDMI 2.1a)        | HDMI   | Linux 6.3<br>nVidia 530.41.03          | native @ 30 Hz only,<br> 6016x3384@60 |

### Intel GPU: no picture or only 4K?!

I was so excited when Intel announced that they are entering the graphics card
business. With all the experience and driver support for their integrated
graphics, I hoped for good Linux support.

Unfortunately, the Intel A380 I bought months ago continues to disappoint.

I could not get the 6K monitor to work at any resolution higher than 4K, not
even under Windows. Worse, when connecting the monitor using DisplayPort, I
wouldn’t get a picture at all (in Linux)!

| Device                                 | Cable  | OS / Driver                            | Resolution                            |
|----------------------------------------|--------|----------------------------------------|---------------------------------------|
| ASRock Intel A380<br>(DisplayPort 2.0) | mDP-DP | Windows 11 21H2<br>Intel 31.0.101.4502 | only 4K @ 60 Hz                       |
| ASRock Intel A380<br>(HDMI 2.0b)       | HDMI   | Windows 11 21H2<br>Intel 31.0.101.4502 | only 4K @ 60 Hz                       |
| ASRock Intel A380<br>(DisplayPort 2.0) | mDP-DP | Linux 6.4                              | no picture in Xorg!                   |
| ASRock Intel A380<br>(HDMI 2.0b)       | HDMI   | Linux 6.4                              | only 4K @ 60 Hz                       |

### No picture after resume from suspend-to-RAM {#resume}

I suspend my PC to RAM at least once per day, sometimes even more often.

With my current 8K monitor, I have nailed the suspend/wakeup procedure. With the
help of a smart plug, I’m automatically turning the monitor off (on suspend) and
on (on wakeup). After a couple of seconds of delay, I configure the correct
resolution using `xrandr`.

I had hoped that the 6K monitor would make any sort of intricate automation
superfluous.

Unfortunately, when I resumed my PC, I noticed that the monitor would not show a
picture at all! I had to log in from my laptop via SSH to change the resolution
with `xrandr` to 4K, then power the monitor off and on again, then change
resolution back to the native 6K.

## Scaling

Once you have a physical connection established, how do you configure your
computer? With 6K at 32 inches, you’ll need to enable some kind of scaling in
order to comfortably read text.

This section shows what options Linux and macOS offer.

### i3 (X11)

Just like many other programs on Linux, you configure i3’s scaling by [setting
the `Xft.dpi` X
resource](https://wiki.archlinux.org/title/HiDPI#X_Resources). The default is 96
dpi, so to get 200% scaling, set `Xft.dpi: 192`.

Personally, I found 240% scaling more comfortable, i.e. `Xft.dpi: 230`.

This corresponds to a logical resolution of 2560x1440 pixels.

### GNOME (Wayland)

I figured I’d also give Wayland a shot, so I ran GNOME in Fedora 38 on my
ThinkPad X1 Extreme.

Here’s what the settings app shows in its “Displays” tab:

{{< img src="Screenshot from 2023-07-02 12-25-57.png" border="0" >}}

I tried [enabling fractional
scaling](https://www.omglinux.com/how-to-enable-fractional-scaling-fedora/), but
then GNOME froze until I disconnected the Dell monitor.

### macOS

When connecting the monitor to my MacBook Air M1 (2020), it defaults to a
logical resolution of 3072x1728, i.e. 200% scaling.

{{< img src="2023-07-02-macOS-displays.png" border="0" >}}

For comparison, with [Apple’s (5K) Studio
Display](https://www.apple.com/studio-display/), the default setting is
2560x1440 (200% scaling), or 2880x1620 (“More Space”, 177% scaling).


## Observations

### Matte screen

I remember the uproar when Lenovo introduced ThinkPads with glossy screens. At
the time, I thought I prefer matte screens, but over the years, I heard that
glossy screens are getting better and better, and consumers typically prefer
them for their better picture quality.

The 8K monitor I’m using has a glossy screen on which reflections are quite
visible. The MacBook Air’s screen shows fewer reflections in comparison.

Dell’s 6K monitor offers me a nice opportunity to see which option I prefer.

Surprisingly, I found that I don’t like the matte screen better!

It’s hard to describe, but somehow the picture seems more “dull”, or less bright
(independent of the actual brightness of the monitor), or more toned down. The
colors don’t pop as much.

### Philosophical question: peripherals powered on by default?

One thing that I did not anticipate beforehand is the difference in how
peripherals are treated when they are built into the monitor vs. when they are
plugged into a USB hub.

I like to have my peripherals off-by-default, with “on” being the exceptional
state. In fact, I leave my microphone disconnected and only plug its USB cable
in when I need it. I also recently realized that I want sound to only be played
on headphones, so I disconnected my normal speakers in favor of my Bluetooth
dongle.

The 6K monitor, on the other hand, has all of its peripherals on-by-default, and
bright red LEDs light up when the speaker or microphone is muted.

This is the opposite of how I want my peripherals to behave, but of course I
understand why Dell developed the monitor with on-by-default peripherals.


## Conclusion

Let’s go back to the questions I started the article with and answer them one by one:

1. Does the 6K monitor work well with most (all?) of my PCs and laptops?

   → **Answer:** The 6K monitor works a lot better than the 8K monitor, but that’s a
   low bar to clear. I would still call the 6K monitor finicky. Even when you
   run a latest-gen GPU with latest drivers, the monitor does not reliably show
   a picture after a suspend/resume cycle.

1. Is 6K resolution enough, or would I miss the 8K resolution?

   → **Answer:** I had really hoped that 6K would turn out to be enough, but the
   difference to 8K is visible with the bare eye. Just like 200% scaling is a
   nice step up from working at 96 dpi, 300% scaling (what I use on 8K) is
   another noticeable step up.

1. Is a matte screen the better option compared to the 8K monitor’s glossy finish?

   → **Answer:** While I don’t like the reflections in Dell’s 8K monitor, the
   picture quality is undeniably better compared to a matte screen. The 6K
   monitor just doesn’t look as good, and it’s not just about the difference in
   text sharpness.

1. Do the built-in peripherals work with Linux out of the box?

   → **Answer:** Yes, as far as I can tell. The webcam works fine with the
   generic `uvcvideo` USB webcam driver, the microphone and speakers work out of
   the box. I have not tested the presence sensor.

So, would I recommend the monitor? Depends on what you’re using as your current
monitor and as the device you want to connect!

If you’re coming from a 4K display, the 6K resolution will be a nice step
up. Connecting a MacBook Air M1 or newer is a great experience. If you want to
connect PCs, be sure to use a new-enough nVidia GPU with latest drivers. Even
under these ideal conditions, you might run into quirks like the [no picture
after resume](#resume) problem. If you don’t mind early adopter pains like that,
and are looking for a monitor that includes peripherals, go for it!

For me, switching from my 8K monitor would be a downgrade without enough
benefits.

The ideal monitor for me would be a mixture between Dell’s 8K and 6K models:

* 8K resolution
  * …but with more modern connectivity options (one cable! works out of the box!).
* without built-in peripherals like webcam, microphone and speaker
  * …but with the USB KVM switch concept (monitor input coupled to USB upstream).
* glossy finish for best picture quality
  * …but with fewer reflections.

Maybe they’ll develop an updated version of the 8K monitor at some point?
