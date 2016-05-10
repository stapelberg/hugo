---
layout: post
title:  "Supermicro X11SSZ-QF workstation mainboard"
date:   2016-05-10 18:46:00
categories: Artikel
---

<h3>Context</h3>

<p>
For the last 3 years I’ve used <a
href="/Artikel/buying_linux_computer_2012/">the hardware described in my 2012
article</a>. In order to drive a hi-dpi display, I needed to install an nVidia
graphics card, since only the nVidia hardware/software supported multi-tile
displays requiring MST (Multiple Stream Transport) such as the Dell UP2414Q.
While I’ve switched to <a href="/Artikel/viewsonic_vx2475smhl_4k_linux/">a
Viewsonic VX2475Smhl-4K</a> in the meantime, I still needed a recent-enough
DisplayPort output that could deliver 3840x2160@60Hz. This is not the case for
the Intel Core i7-2600K’s integrated GPU, so I needed to stick with the nVidia
card.
</p>

<p>
I then stumbled over a video file which, when played back using the nouveau
driver’s <a href="https://en.wikipedia.org/wiki/VDPAU">VDPAU</a> functionality,
would lock up my graphics card entirely, so that only a cold reboot helped.
This got me annoyed enough to upgrade my hardware.
</p>

<h3>Why the Supermicro X11SSZ-QF?</h3>

<p>
Intel, my standard pick for mainboards with good Linux support, unfortunately
<a
href="http://gizmodo.com/5978232/intel-to-stop-making-desktop-motherboards">stopped
producing desktop mainboards</a>. I looked around a bit for <a
href="https://en.wikipedia.org/wiki/Skylake_(microarchitecture)">Skylake</a>
mainboards and realized that the Intel Q170 Express chipset actually supports 2
DisplayPort outputs that each support 3840x2160@60Hz, enabling a multi-monitor
hi-dpi display setup. While I don’t currently have multiple monitors and don’t
intend to get another monitor in the near future, I thought it’d be nice to
have that as a possibility.
</p>

<p>
Turns out that there are only two mainboards out there which use the Q170
Express chipset and actually expose two DisplayPort outputs: the <a
href="http://www.fujitsu.com/global/products/computing/peripheral/mainboards/extended-lifecycle-main/pmod-177971.html">Fujitsu
D3402-B</a>, and the <a
href="http://www.supermicro.com/products/motherboard/core/q170/x11ssz-qf.cfm">Supermicro
X11SSZ-QF</a>. The Fujitsu one doesn’t have an integrated S/PDIF output, which
I need to play audio on my <a
href="http://usa.denon.com/us/product/hometheater/avreceiversht/avrx1100w">Denon
AVR-X1100W</a> without a constant noise level. Also, I wasn’t able to find
software downloads or even a manual for the board on the Fujitsu website. For
Supermicro, you can find the manual and software very easily on their website,
and because I bought Supermicro hardware in the past and was rather happy with
it, I decided to go with the Supermicro option.
</p>

<p>
I’ve been using the board for half a year now, without any stability issues.
</p>

<h3>Mechanics and accessories</h3>

<p>
The X11SSZ-QF ships with a printed quick reference sheet, an I/O shield and 4
SATA cables. Unfortunately, Supermicro apparently went for the cheapest SATA
cables they could find, as they do not have a clip to ensure they don’t slide
off of the hard disk connector. This is rather disappointing for a mainboard
that costs more than 300 CHF. Further, an S/PDIF bracket is not included, so I
needed to <a
href="http://www.amazon.com/SPDIF-Optical-Plate-Cable-Bracket/dp/B003AV944Y">order
one from the USA</a>.
</p>

<p>
The I/O shield comes with covers over each port, which I assume is because the
X11SSZ mainboard family has different ports (one model has more ethernet ports,
for example). When removing the covers, push them through from the rear side of
the case (if you had installed it already). If you do it from the other side, a
bit of metal will remain in each port.
</p>

<p>
Due to the positioning of the CPU socket, with my Fractal Design Define R3
case, one cannot reach the back of the CPU fan bracket when the mainboard is
installed in the case. Hence, you need to first install the CPU fan, then
install the mainboard. This is doable, you just need to realize it early enough
and think about it, otherwise you’ll install the mainboard twice.
</p>

<h3>Integrated GPU not initialized</h3>

<p>
The integrated GPU is not initialized by default. You need to either install an
external graphics card or use IPMI to enter the BIOS and change <code>Advanced
→ Chipset Configuration → Graphics Configuration → Primary Display</code> to
“IGFX”.
</p>

<p>
For using IPMI, you need to connect the ethernet port <code>IPMI_LAN</code>
(top right on the back panel, see <a
href="http://www.supermicro.com/QuickRefs/motherboard/Q170/QRG-1744.pdf">the
X11SSZ-QF quick reference guide</a>) to a network which has a DHCP server, then
connect to the IPMI’s IP address in a browser.
</p>

<h3>Overeager Fan Control</h3>

<p>
When I first powered up the mainboard, I was rather confused by the behavior: I got no picture (see above), but <code>LED2</code> was blinking, meaning “PWR Fail or Fan Fail”. In addition, the computer seemed to turn itself off and on in a loop. After a while, I realized that it’s just the fan control which thinks my slow-spinning Scythe Mugen 3 Rev. B CPU fan is broken because of its low RPM value. The fan control subsequently spins up the fan to maximum speed, realizes the CPU is cool enough, spins down the fan, realizes the fan speed is too low, spins up the fan, etc.
</p>

<p>
Neither in the BIOS nor in the IPMI web interface did I find any options for the fan thresholds. Luckily, you can actually introspect and configure them using IPMI:
</p>

<pre>
# apt-get install freeipmi-tools
# ipmi-sensors-config --filename=ipmi-sensors.config --checkout
</pre>

<p>
In the human-readable text file <code>ipmi-sensors.config</code> you can now introspect the current configuration. You can see that <code>FAN1</code> and <code>FAN2</code> have sections in that file:
</p>
<pre>
Section 607_FAN1
 Enable_All_Event_Messages Yes
 Enable_Scanning_On_This_Sensor Yes
 Enable_Assertion_Event_Lower_Critical_Going_Low Yes
 Enable_Assertion_Event_Lower_Non_Recoverable_Going_Low Yes
 Enable_Assertion_Event_Upper_Critical_Going_High Yes
 Enable_Assertion_Event_Upper_Non_Recoverable_Going_High Yes
 Enable_Deassertion_Event_Lower_Critical_Going_Low Yes
 Enable_Deassertion_Event_Lower_Non_Recoverable_Going_Low Yes
 Enable_Deassertion_Event_Upper_Critical_Going_High Yes
 Enable_Deassertion_Event_Upper_Non_Recoverable_Going_High Yes
 Lower_Non_Critical_Threshold 700.000000
 Lower_Critical_Threshold 500.000000
 Lower_Non_Recoverable_Threshold 300.000000
 Upper_Non_Critical_Threshold 25300.000000
 Upper_Critical_Threshold 25400.000000
 Upper_Non_Recoverable_Threshold 25500.000000
 Positive_Going_Threshold_Hysteresis 100.000000
 Negative_Going_Threshold_Hysteresis 100.000000
EndSection
</pre>

<p>
When running <code>ipmi-sensors</code>, you can see the current temperatures,
voltages and fan readings. In my case, the fan spins with 700 RPM during normal
operation, which was exactly the <code>Lower_Non_Critical_Threshold</code> in
the default IPMI config. Hence, I modified my config file as illustrated by the
following diff:
</p>

<pre>
--- ipmi-sensors.config	2015-11-13 11:53:00.940595043 +0100
+++ ipmi-sensors-fixed.config	2015-11-13 11:54:49.955641295 +0100
@@ -206,11 +206,11 @@
 Enable_Deassertion_Event_Upper_Non_Recoverable_Going_High Yes
- Lower_Non_Critical_Threshold 700.000000
+ Lower_Non_Critical_Threshold 400.000000
- Lower_Critical_Threshold 500.000000
+ Lower_Critical_Threshold 200.000000
- Lower_Non_Recoverable_Threshold 300.000000
+ Lower_Non_Recoverable_Threshold 0.000000
 Upper_Non_Critical_Threshold 25300.000000
</pre>

<p>
You can install the new configuration using the <code>--commit</code> flag:
</p>

<pre>
# ipmi-sensors-config --filename=ipmi-sensors-fixed.config --commit
</pre>

<p>
You might need to shut down your computer and disconnect power for this change to take effect, since the BMC is running even when the mainboard is powered off.
</p>

<h3>S/PDIF output</h3>

<p>
The S/PDIF pin header on the mainboard just doesn’t work at all. It does not work
in Windows 7 (for which the board was made), and it doesn’t work in Linux.
Neither the digital nor the analog part of an S/PDIF port works. When
introspecting the Intel HDA setup of the board, the S/PDIF output is not even
hooked up correctly. Even after fixing that, it doesn’t work.
</p>

<p>
Of course, I’ve contacted the Supermicro support. After making clear to them
what my use-case is, they ordered (!) an S/PDIF header and tested the analog
part of it. Their technical support claims that their port is working, but they
never replied to my question with which operating system they tested that,
despite me asking multiple times.
</p>

<p>
It’s pretty disappointing to see that the support is unable to help here or at
least confirm that it’s broken.
</p>

<p>
To address the issue, I’ve bought an <a
href="https://www.asus.com/us/Sound-Cards/Xonar_DX/specifications/">ASUS Xonar
DX</a> sound card. It works out of the box on Linux, and its S/PDIF port works.
The S/PDIF port is shared with the Line-in/Mic-in jack, but a suitable adapter
is shipped with the card.
</p>

<h3>Wake-on-LAN</h3>

<p>
I haven’t gotten around to using Wake-on-LAN or Suspend-to-RAM yet. I will
amend this section when I get around to it.
</p>

<h3>Conclusion</h3>

<p>
It’s clear that this mainboard is not for consumers. This begins with the
awkward graphics and fan control setup and culminates in the apparently
entirely untested S/PDIF output.
</p>

<p>
That said, once you get it working, it works reliably, and it seems like the
only reasonable option with two onboard DisplayPort outputs.
</p>
