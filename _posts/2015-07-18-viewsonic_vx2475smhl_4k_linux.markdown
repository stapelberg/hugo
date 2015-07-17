---
layout: post
title:  "ViewSonic VX2475Smhl-4K HiDPI display on Linux"
date:   2015-07-18 00:30:00
categories: Artikel
---

<p>
I have been using a <a
href="http://accessories.us.dell.com/sna/productdetail.aspx?c=us&l=en&cs=19&sku=860-BBCD&baynote_bnrank=0&baynote_irrank=1&~ck=dellSearch&~srd=true&sk=UP2414Q&scat=prod">Dell
UP2414Q monitor</a> for a little over a year now. The Dell UP2414Q was the
first commercially available display that qualified as what Apple calls <a
href="https://en.wikipedia.org/wiki/Retina_Display">a Retina Display</a>,
meaning it has such a high resolution that you cannot see the individual pixels
in normal viewing distance. In more technical terms, this is called a HiDPI
display. To be specific, Dell’s UP2414Q has a 527mm wide and 296mm high screen,
hence it has 185 dpi (3840 px / (527 mm / 25.4 mm)). I configured my system to
use 192 dpi instead of the actual 185 dpi, because 192 is a clean multiple of
96 dpi, so scaling gets easier for software.
</p>

<p>
The big drawback of the Dell UP2414Q, and all other 4K displays with
sufficiently high dpi, is that the display uses multiple scalers (also called
multiple tiles) internally. This makes use of a DisplayPort feature called
Multiple Stream Transport (MST): in layman’s terms, the display communicates to
the graphics card that there are actually two displays with a resolution of
1920x1080&nbsp;px each, both connected via the same DisplayPort cable. The
graphics card then needs to split each frame into two halves and send them over
the DisplayPort connection to the monitor. The reason all display vendors used
this technique is that at the time, there simply were no scalers on the market
which supported a resolution of 3840x2160&nbsp;px.
</p>

<h3>Driver support for tiled displays</h3>
<p>
The problem with MST is that it’s poorly supported in the Linux ecosystem: for
the longest time, the only driver supporting it at all was the closed-source
nVidia driver, and you had to live without RandR when using it. With linux 4.1,
MST support was added for the radeon driver, but I’m not sure if that is all
that’s necessary to support 4K MST displays as there are other use-cases for
MST. The intel driver still doesn’t have any MST support whatsoever, as of now
(linux 4.1).
</p>

<h3>(RandR) Software support for tiled displays</h3>
<p>
Regardless of the driver you are using, you’ll need the very latest RandR 1.5,
otherwise software will just see multiple monitors instead of one big monitor.
Keith Packard <a href="http://keithp.com/blogs/MST-monitors/">published a blog
post with a proposal to address this shortcoming</a>, and the actual
implementation work was included in the <a
href="http://cgit.freedesktop.org/xorg/proto/randrproto/commit/?id=79b63f0e57cd5baf06ff24252d3f1675dcb64467">randrproto
1.5 release at 2015-05-17</a>. I think it will take a while until all relevant
software is updated, with your graphics driver, the X server and your desktop
environment being the most important pieces of software. It’s unclear to me
when/if Wayland will support tiled 4K displays.
</p>

<p>
Having to disable RandR means you’ll be unable to use tools like redshift to
dim your monitor’s backlight, and you won’t be able to reconfigure or rotate
your monitor without restarting your X session. Especially on a laptop, this is
a big deal.
</p>

<h2>The ViewSonic VX2475Smhl-4K</h2>

<p>
I’m not sure why ViewSonic chose such a long product name, especially when
comparing it with the competition’s names like HP z24s or BenQ BL2420U. This
makes it pretty hard to talk about the product in real life, because nobody is
going to remember that cryptic name. In that sense, it’s a good thing I won’t
need to recommend this product.
</p>

<p>
Let’s start with the positive, and the main reason why I bought this monitor:
the screen itself is great. It entirely fulfills my needs for extended periods
of office work and occasionally watching a movie. I don’t play games on this
monitor. With regards to connectivity, it comes with 2 HDMI ports (one of which
is MHL-capable for connecting smartphones and tablets) and 1 DisplayPort. Since
most graphics cards don’t support HDMI 2.0 yet (which you need for the native
resolution of 3840x2160px at 60Hz), I am driving the monitor using DisplayPort,
which works perfectly fine so far.
</p>

<p>
Unfortunately, the screen is the only good thing about this entire monitor. If
you are using it in an office setting, you might be used to a lot more comfort.
Here is a list of shortcomings, sorted by how severe I think each issue is:
</p>

<ol>
<li>
The monitor does not contain a USB hub at all. This is a big shortcoming I
can’t understand at all. From plugging in wireless receivers for mouse/keyboard
over <a href="https://www.yubico.com/products/yubikey-hardware/">Yubikeys for
second-factor authentification</a> to the occasional USB thumb drives, I don’t
understand how anyone would not see the lack of USB ports as a big minus.
</li>
<li>
The case of the monitor is painted in a glossy black, reflecting light. This is
ironic, since the screen itself is matte, but you still have light reflections
in your field of vision. I’ll need to see what I can do about that.
</li>
<li>
The monitor feels a lot cheaper than other monitors. The stand it comes with is
flimsy and does not allow for rotating the monitor or adjusting the height at
all, so I’ve already ordered an Ergotron LX 45-241-026 to replace the stand.
The buttons to power off/on and navigate the on-screen display don’t feel
comfortable, and the power LED is bright blue, reflecting multiple times in the
glossy stand.
</li>
</ol>

<h2>Using the ViewSonic VX2475Smhl-4K with Linux</h2>

<h3>Using DisplayPort with the nouveau open-source driver</h3>

<p>
Connecting the <a
href="http://www.viewsonic.com/us/vx2475smhl-4k.html">ViewSonic
VX2475Smhl-4K</a> to my Gainward GeForce GTX 660 using DisplayPort works
perfectly fine with the nouveau open-source driver version 1.0.11, meaning the
driver detects the full native resolution of 3840x2160&nbsp;px with a refresh
rate of 60&nbsp;Hz and does not use YUV 4:2:0 compression. As I understand it,
you need to have a graphics card with DisplayPort 1.2 or newer in order to
achieve 3840x2160&nbsp;px at 60&nbsp;Hz. Here’s the output of xrandr:
</p>

<pre style="width: 60em">
$ xrandr
Screen 0: minimum 320 x 200, current 3840 x 2160, maximum 8192 x 8192
DVI-I-1 disconnected (normal left inverted right x axis y axis)
HDMI-1 disconnected (normal left inverted right x axis y axis)
DP-1 connected 3840x2160+0+0 (normal left inverted right x axis y axis) 521mm x 293mm
   3840x2160     60.00*+  30.00    25.00    24.00    29.97    23.98  
   1920x1080     60.00    50.00    59.94  
   1920x1080i    60.00    50.00    59.94  
   1600x1200     60.00  
   1680x1050     59.95  
   1400x1050     59.98  
   1600x900      59.98  
   1280x1024     75.02    60.02  
   1440x900      59.89  
   1152x864      75.00  
   1280x720      60.00    50.00    59.94  
   1024x768      75.08    70.07    60.00  
   832x624       74.55  
   800x600       72.19    75.00    60.32    56.25  
   720x576       50.00  
   720x480       60.00    59.94  
   640x480       75.00    72.81    66.67    60.00    59.94  
   720x400       70.08  
DVI-D-1 disconnected (normal left inverted right x axis y axis)
</pre>

<h3>Using DisplayPort with the nVidia closed-source driver</h3>

<p>
Connecting the <a
href="http://www.viewsonic.com/us/vx2475smhl-4k.html">ViewSonic
VX2475Smhl-4K</a> to my Gainward GeForce GTX 660 using DisplayPort works
perfectly fine with the nVidia closed-source driver version 352.21 (haven’t
tested it with other versions), meaning the driver detects the full native
resolution of 3840x2160&nbsp;px with a refresh rate of 60&nbsp;Hz and does not
use YUV 4:2:0 compression. As I understand it, you need to have a graphics card
with DisplayPort 1.2 or newer in order to achieve 3840x2160&nbsp;px at
60&nbsp;Hz. Here’s the output of xrandr:
</p>

<pre style="width: 60em">
Screen 0: minimum 8 x 8, current 3840 x 2160, maximum 16384 x 16384
DVI-I-0 disconnected primary (normal left inverted right x axis y axis)
DVI-I-1 disconnected (normal left inverted right x axis y axis)
HDMI-0 disconnected (normal left inverted right x axis y axis)
DP-0 disconnected (normal left inverted right x axis y axis)
DVI-D-0 disconnected (normal left inverted right x axis y axis)
DP-1 connected 3840x2160+0+0 (normal left inverted right x axis y axis) 521mm x 293mm
   3840x2160     60.00*+  29.97    25.00    23.98  
   1920x1080     60.00    59.94    50.00    60.00    50.04  
   1680x1050     59.95  
   1600x1200     60.00  
   1600x900      60.00  
   1440x900      59.89  
   1400x1050     59.98  
   1280x1024     75.02    60.02  
   1280x720      60.00    59.94    50.00  
   1024x768      75.03    70.07    60.00  
   800x600       75.00    72.19    60.32    56.25  
   720x576       50.00  
   720x480       59.94  
   640x480       75.00    72.81    59.94    59.93  
</pre>

<p>
And here’s the relevant block of verbose log output generated by the nVidia
driver in <code>/var/log/Xorg.0.log</code> when starting X11 with
<code>-logverbose 6</code>:
</p>

<pre style="width: 60em">
[ 87934.515] (II) NVIDIA(GPU-0): --- Building ModePool for ViewSonic VX2475 SERIES (DFP-4) ---
[ 87934.515] (II) NVIDIA(GPU-0):   Validating Mode "3840x2160_60":
[ 87934.515] (II) NVIDIA(GPU-0):     Mode Source: EDID
[ 87934.515] (II) NVIDIA(GPU-0):     3840 x 2160 @ 60 Hz
[ 87934.515] (II) NVIDIA(GPU-0):       Pixel Clock      : 533.25 MHz
[ 87934.515] (II) NVIDIA(GPU-0):       HRes, HSyncStart : 3840, 3888
[ 87934.515] (II) NVIDIA(GPU-0):       HSyncEnd, HTotal : 3920, 4000
[ 87934.515] (II) NVIDIA(GPU-0):       VRes, VSyncStart : 2160, 2163
[ 87934.515] (II) NVIDIA(GPU-0):       VSyncEnd, VTotal : 2168, 2222
[ 87934.515] (II) NVIDIA(GPU-0):       H/V Polarity     : +/-
[ 87934.515] (II) NVIDIA(GPU-0):     Viewport                 3840x2160+0+0
[ 87934.515] (II) NVIDIA(GPU-0):       Horizontal Taps        0
[ 87934.515] (II) NVIDIA(GPU-0):       Vertical Taps          0
[ 87934.515] (II) NVIDIA(GPU-0):       Base SuperSample       x1
[ 87934.515] (II) NVIDIA(GPU-0):       Base Depth             32
[ 87934.515] (II) NVIDIA(GPU-0):       Distributed Rendering  1
[ 87934.515] (II) NVIDIA(GPU-0):       Overlay Depth          32
[ 87934.515] (II) NVIDIA(GPU-0):     Mode "3840x2160_60" is valid.
</pre>


<h3>Using HDMI with the nVidia closed-source driver</h3>

<p>
In order to drive the ViewSonic VX2475Smhl-4K with its native resolution of
3840x2160&nbsp;px at a refresh rate of 60&nbsp;Hz, you’ll need to have a
graphics card that supports HDMI 2.0. As of 2015-07-17, the only cards I can
find that feature HDMI 2.0 are nVidia’s Maxwell cards (NV110), e.g. the models
GeForce GTX 960, 970 or 980. These models <a
href="http://www.phoronix.com/scan.php?page=news_item&px=NVIDIA-Unfriendly-OSS-Hardware">need
a signed firmware blob, which nVidia has not yet released</a>, hence you cannot
use them with the open-source nouveau driver at all. I’ll not buy them until
this issue is resolved.
</p>

<p>
Even though I know that it’s not supported, I was curious to see what happens
when I try to connect the display to my GeForce GTX 660, which only has HDMI
1.4.
</p>

<p>
With the nVidia closed-source driver version 346.47, by default, you will end
up with a resolution of 1920x1080&nbsp;px. The X11 logfile
<code>/var/log/Xorg.0.log</code> contains the following verbose log output when
starting X11 with <code>-logverbose 6</code>:
</p>

<pre style="width: 60em">
[  8265.425] (II) NVIDIA(GPU-0):   Validating Mode "3840x2160":
[  8265.425] (II) NVIDIA(GPU-0):     3840 x 2160 @ 60 Hz
[  8265.425] (II) NVIDIA(GPU-0):     Mode Source: EDID
[  8265.425] (II) NVIDIA(GPU-0):       Pixel Clock      : 533.25 MHz
[  8265.425] (II) NVIDIA(GPU-0):       HRes, HSyncStart : 3840, 3888
[  8265.425] (II) NVIDIA(GPU-0):       HSyncEnd, HTotal : 3920, 4000
[  8265.425] (II) NVIDIA(GPU-0):       VRes, VSyncStart : 2160, 2163
[  8265.425] (II) NVIDIA(GPU-0):       VSyncEnd, VTotal : 2168, 2222
[  8265.425] (II) NVIDIA(GPU-0):       H/V Polarity     : +/-
[  8265.425] (WW) NVIDIA(GPU-0):     Mode is rejected: PixelClock (533.2 MHz) too high for
[  8265.426] (WW) NVIDIA(GPU-0):     Display Device (Max: 340.0 MHz).

[  8265.429] (II) NVIDIA(GPU-0):   Validating Mode "3840x2160":
[  8265.429] (II) NVIDIA(GPU-0):     3840 x 2160 @ 30 Hz
[  8265.429] (II) NVIDIA(GPU-0):     Mode Source: EDID
[  8265.429] (II) NVIDIA(GPU-0):       Pixel Clock      : 296.70 MHz
[  8265.429] (II) NVIDIA(GPU-0):       HRes, HSyncStart : 3840, 4016
[  8265.429] (II) NVIDIA(GPU-0):       HSyncEnd, HTotal : 4104, 4400
[  8265.429] (II) NVIDIA(GPU-0):       VRes, VSyncStart : 2160, 2168
[  8265.429] (II) NVIDIA(GPU-0):       VSyncEnd, VTotal : 2178, 2250
[  8265.429] (II) NVIDIA(GPU-0):       H/V Polarity     : +/+
[  8265.429] (WW) NVIDIA(GPU-0):     Mode is rejected: Mode requires YUV 4:2:0 compression.
</pre>

<p>
When setting <code>Option "ModeValidation" "AllowNonEdidModes"</code> and
configuring the custom modeline <code>Modeline "3840x2160" 307.00 3840 4016
4104 4400 2160 2168 2178 2250 +hsync +vsync</code>, you can get a resolution of
3840x2160&nbsp;px, but a refresh rate of only 30&nbsp;Hz. Such a low refresh
rate is only okay for watching movies — any sort of regular computer work is
very inconvenient, as the mouse pointer is severely jumpy/lagging.
</p>

<p>
Since driver version 349.12, nVidia <a
href="https://devtalk.nvidia.com/default/topic/821171">added support for YUV
4:2:0 compression</a>. See <a
href="http://www.anandtech.com/show/8191/nvidia-kepler-cards-get-hdmi-4k60hz-support-kind-of">this
anandtech article about how nVidia cards achieve 4k@60 Hz over HDMI 1.4</a> and
<a href="https://en.wikipedia.org/wiki/Chroma_subsampling">the wikipedia
article on chroma subsampling</a> in general.
</p>

<p>
I upgraded my driver to version 352.21, and indeed, by default, it will now
drive the monitor with 3840x2160&nbsp;px at a refresh rate of 60&nbsp;Hz, but
using YUV 4:2:0 compression. This compression is immediately visible as the
picture quality is so much worse. You can even see it in simple things such as
a GMail tab. To me, it looks similar to when you accidentally misconfigure your
system to use 16-bit colors instead of 24-bit colors. I recommend you try to
avoid YUV 4:2:0 compression as much as possible, unless maybe if you’re just
trying to watch movies and aren’t interested in best quality.
</p>

<p>
With version 352.21, the X11 logfile <code>/var/log/Xorg.0.log</code> contains
the following verbose log output when starting X11 with <code>-logverbose
6</code>:
</p>

<pre style="width: 60em">
[   123.402] (WW) NVIDIA(GPU-0):   Validating Mode "3840x2160_60":
[   123.402] (WW) NVIDIA(GPU-0):     Mode Source: EDID
[   123.402] (WW) NVIDIA(GPU-0):     3840 x 2160 @ 60 Hz
[   123.402] (WW) NVIDIA(GPU-0):       Pixel Clock      : 533.25 MHz
[   123.402] (WW) NVIDIA(GPU-0):       HRes, HSyncStart : 3840, 3888
[   123.402] (WW) NVIDIA(GPU-0):       HSyncEnd, HTotal : 3920, 4000
[   123.402] (WW) NVIDIA(GPU-0):       VRes, VSyncStart : 2160, 2163
[   123.402] (WW) NVIDIA(GPU-0):       VSyncEnd, VTotal : 2168, 2222
[   123.402] (WW) NVIDIA(GPU-0):       H/V Polarity     : +/-
[   123.402] (WW) NVIDIA(GPU-0):     Mode is rejected: PixelClock (533.2 MHz) too high for
[   123.402] (WW) NVIDIA(GPU-0):     Display Device (Max: 340.0 MHz).
[   123.402] (WW) NVIDIA(GPU-0):     Mode "3840x2160_60" is invalid.

[   123.406] (II) NVIDIA(GPU-0):   Validating Mode "3840x2160_60":
[   123.406] (II) NVIDIA(GPU-0):     Mode Source: EDID
[   123.406] (II) NVIDIA(GPU-0):     3840 x 2160 @ 60 Hz
[   123.406] (II) NVIDIA(GPU-0):       Pixel Clock      : 593.41 MHz
[   123.406] (II) NVIDIA(GPU-0):       HRes, HSyncStart : 3840, 4016
[   123.406] (II) NVIDIA(GPU-0):       HSyncEnd, HTotal : 4104, 4400
[   123.406] (II) NVIDIA(GPU-0):       VRes, VSyncStart : 2160, 2168
[   123.406] (II) NVIDIA(GPU-0):       VSyncEnd, VTotal : 2178, 2250
[   123.406] (II) NVIDIA(GPU-0):       H/V Polarity     : +/+
[   123.406] (II) NVIDIA(GPU-0):     Viewport                 1920x2160+0+0
[   123.406] (II) NVIDIA(GPU-0):       Horizontal Taps        0
[   123.406] (II) NVIDIA(GPU-0):       Vertical Taps          0
[   123.406] (II) NVIDIA(GPU-0):       Base SuperSample       x1
[   123.406] (II) NVIDIA(GPU-0):       Base Depth             32
[   123.406] (II) NVIDIA(GPU-0):       Distributed Rendering  1
[   123.406] (II) NVIDIA(GPU-0):       Overlay Depth          32
[   123.406] (II) NVIDIA(GPU-0):     Mode "3840x2160_60" is valid.
</pre>

<h2>Conclusion</h2>

<p>
With its single scaler, the ViewSonic VC2475Smhl-4K works just fine on Linux
when using DisplayPort, which is a big improvement over the finicky Dell
UP2414Q.  Everything else about this monitor is pretty bad, so I would
recommend you have a close look at the competition’s models, which as of
2015-07-17 are the HP&nbsp;z24s and the BenQ&nbsp;BL2420U. Neither of these are
currently available in Switzerland, so it will take a while until I have the
possibility to review either of them.
</p>
