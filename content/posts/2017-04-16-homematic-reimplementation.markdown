---
layout: post
title:  "HomeMatic re-implementation"
date:   2017-04-16 10:20:00
categories: Artikel
Aliases:
  - /Artikel/homematic-reimplementation
---

<p>
A while ago, I got myself a bunch of HomeMatic home automation gear (valve drives, temperature and humidity sensors, power switches). The gear itself works reasonably well, but I found the management software painfully lacking. Hence, I re-implemented my own management software. In this article, I’ll describe my method, in the hope that others will pick up a few nifty tricks to make future re-implementation projects easier.
</p>

<h3>Motivation</h3>

<p>
When buying my HomeMatic devices, I decided to use the wide-spread <a href="http://www.eq-3.com/products/homematic/control-units-and-gateways/homematic-central-control-unit-ccu2.html">HomeMatic Central Control Unit (CCU2)</a>. This embedded device runs the proprietary <code>rfd</code> wireless daemon, which offers an XML-RPC interface, used by the web interface.
</p>

<p>
I find the CCU2’s web interface really unpleasant. It doesn’t look modern, it takes ages to load, and it doesn’t indicate progress. I frequently find myself clicking on a button, only to realize that my previous click was still not processed entirely, and then my current click ends up on a different element that I intended to click. Ugh.
</p>

<p>
More importantly, even if you avoid the CCU2’s web interface altogether and only want to extract sensor values, you’ll come to realize that the device crashes every few weeks. Due to memory pressure, the <code>rfd</code> is killed and doesn’t come back. As a band-aid, I wrote a watchdog cronjob which would just reboot the device. I also reported the bug to the vendor, but never got a reply.
</p>

<p>
When I tried to update the software to a more recent version, things went so wrong that I decided to downgrade and not touch the device anymore. This is not a good state to be in, so eventually I started my project to replace the device entirely. The replacement is <a href="https://github.com/stapelberg/hmgo">hmgo</a>, a central control unit implemented in Go, deployed to a Raspberry Pi running <a href="https://gokrazy.github.io/">gokrazy</a>. The radio module I’m using is HomeMatic’s <a href="https://www.elv.de/homematic-funkmodul-fuer-raspberry-pi-bausatz.html">HM-MOD-RPI-PCB</a>, which is connected to a serial port, much like in the CCU2 itself.
</p>

<h3>Preparation: gather and visualize traces</h3>

<p>
In order to compare the behavior of the CCU2 stock firmware against my software, I wanted to capture some traces. Looking at what goes on over the air (or on the wire) is also a good learning opportunity to understand the protocol.
</p>

<ol>
<li>I wrote a <a href="https://www.wireshark.org">Wireshark</a> dissector (see <a href="https://github.com/stapelberg/hmgo/blob/master/contrib/wireshark/homematic.lua">contrib/homematic.lua</a>). It is a quick &amp; dirty hack, does not properly dissect everything, but it works for the majority of packets. This step alone will make the upcoming work so much easier, because you won’t need to decode packets in your head (and make mistakes!) so often.</li>
<li>I captured traffic from the working system. Conveniently, the CCU2 allows SSH'ing in as <code>root</code> after setting a password. Once logged in, I used <code>lsof</code> and <code>ls /proc/$(pidof rfd)/fd</code> to identify the file descriptors which <code>rfd</code> uses to talk to the serial port. Then, I used <code>strace -e read=7,write=7 -f -p $(pidof rfd)</code> to get hex dumps of each read/write. These hex dumps can directly be fed into <code>text2pcap</code> and can be analyzed with Wireshark.</li>
<li>I also wrote a little Perl script to extract and convert packet hex dumps from homegear debug logs to text2pcap-compatible format. More on that in a bit.</li>
</ol>

<h3>Preparation: research</h3>

<p>
Then, I gathered as much material as possible. I found and ended up using the following resources (in order of frequency):
</p>
<ol>
<li><a href="https://github.com/Homegear/Homegear">homegear source</a></li>
<li><a href="https://svn.fhem.de/">FHEM source</a></li>
<li><a href="https://media.ccc.de/v/30C3_-_5444_-_en_-_saal_g_-_201312301600_-_attacking_homematic_-_sathya_-_malli">homegear presentation</a></li>
<li><a href="https://git.zerfleddert.de/cgi-bin/gitweb.cgi/hmcfgusb">hmcfgusb source</a></li>
<li><a href="https://wiki.fhem.de/wiki/Hauptseite">FHEM wiki</a></li>
</ol>

<h3>Preparation: lab setup</h3>

<p>
Next, I got the hardware to work with a known-good software. I set up homegear on a Raspberry Pi, which took a few hours of compilation time because there were no pre-built Debian stretch arm64 binaries. This step established that the hardware itself was working fine.
</p>

<p>
Also, I got myself another set of traces from homegear, which is always useful.
</p>

<h3>Implementation</h3>

<p>
Now the actual implementation can begin. Note that up until this point, I hadn’t written a single line of actual program code. I defined a few milestones which I wanted to reach:
</p>

<ol>
<li>Talk to the serial port.</li>
<li>Successfully initialize the HM-MOD-RPI-PCB</li>
<li>Receive any BidCoS broadcast packet</li>
<li>Decode any BidCoS broadcast packet (can largely be done in a unit test)</li>
<li>Talk to an already-paired device (re-using the address/key from my homegear setup)</li>
<li>Configure an already-paired device</li>
<li>Pair a device</li>
</ol>

<p>
To make the implementation process more convenient, I changed the compilation command of my editor to cross-compile the program, <code>scp</code> it to the Raspberry Pi and run it there. This allowed me to test my code with one keyboard shortcut, and I love quick feedback.
</p>

<h3>Retrospective</h3>

<p>
The entire project took a few weeks of my spare time. If I had taken some time off of work, I’m confident I could have implemented it in about a week of full-time work.
</p>

<p>
Consciously doing research, preparation and milestone planning was helpful. It gave me good sense of my progress and achievable goals.
</p>

<p>
As I’ve learnt previously, investing in tools pays off quickly, even for one-off projects like this one. I’d recommend everyone who’s doing protocol-related work to invest some time in learning to use Wireshark and writing custom Wireshark dissectors.
</p>