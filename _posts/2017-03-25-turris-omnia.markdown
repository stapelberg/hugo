---
layout: post
title:  "Review: Turris Omnia (with Fiber7)"
date:   2017-03-25 09:40:00
categories: Artikel
---
<p>
The <a href="https://omnia.turris.cz/en/">Turris Omnia</a> is an open source
(an <a href="https://openwrt.org/">OpenWrt</a> fork) open hardware internet
router created and supported by nic.cz, the registry for the Czech Republic.
It’s the successor to their <a
href="https://project.turris.cz/en/">Project Turris</a>, but with better specs.
</p>

<p>
I was made aware of the Turris Omnia while it was being crowd-funded on
Indiegogo and decided to support the cause. I’ve been using OpenWrt on my
wireless infrastructure for many years now, and finding a decent router with
enough RAM and storage for the occasional experiment used to not be an easy
task. As a result, I had been using a very stable but also very old tp-link
WDR4300 for over 4 years.
</p>

<p>
For the last 2 years, I had been using <a href="/Artikel/fiber7_ubnt_erlite">a
Ubiquiti EdgeRouter Lite (Erlite-3)</a> with a tp-link MC220L media converter
and the aforementioned tp-link WDR4300 access point. Back then, that was one of
the few setups which delivered 1 Gigabit in passively cooled (quiet!) devices
running open source software.
</p>

<p>
With its hardware specs, the Turris Omnia promised to be a big upgrade over my
old setup: the project pages described the router to be capable of processing 1
Gigabit, equipped with a 802.11ac WiFi card and having an SFP slot for the
fiber transceiver I use to get online. Without sacrificing performance, the
Turris Omnia would replace 3 devices (media converter, router, WiFi access
point), which yields nice space and power savings.
</p>


<h3>Performance</h3>

<h4>Wired performance</h4>

<p>
As expected, the Turris Omnia delivers a full Gigabit. A typical <a
href="http://www.speedtest.net/result/6158405365">speedtest.net result</a> is
2ms ping, 935 Mbps down, 936 Mbps up. Speeds displayed by <code>wget</code> and
other tools max out at the same values as with the Ubiquiti EdgeRouter Lite.
Latency to well-connected targets such as Google remains at 0.7ms.
</p>

<h4>WiFi performance</h4>

<p>
I did a few quick tests on speedtest.net with the devices I had available, and
here are the results:
</p>

<table width="100%" style="max-width: 40em">
<tr>
<th>Client</th>
<th>Down (WDR4300)</th>
<th>Down (Omnia)</th>
<th>Up</th>
</tr>
<tr>
<td>ThinkPad X1 Carbon 2015</td>
<td>35 Mbps</td>
<td>470 Mbps</td>
<td>143 Mbps</td>
</tr>
<tr>
<td>MacBook Pro 13" Retina 2014</td>
<td>127 Mbps</td>
<td>540 Mbps</td>
<td>270 Mbps</td>
</tr>
<tr>
<td>iPhone SE</td>
<td>—</td>
<td>226 Mbps</td>
<td>227 Mbps</td>
</tr>
</table>

<h3>Compatibility (software/setup)</h3>

<p>
OpenWrt’s default setup at the time when I set up this router was the most
pleasant surprise of all: using <strong>the Turris Omnia with fiber7 is
literally Plug & Play</strong>. After opening the router’s wizard page in your
web browser, you literally need to click “Next” a few times and you’re online
with IPv4 and IPv6 configured in a way that will be good enough for many
people.
</p>

<p>
I realize this is due to Fiber7 using “just” DHCPv4 and DHCPv6 without
requiring credentials, but man is this nice to see. Open source/hardware
devices which just work out of the box are not something I’m used to :-).
</p>

<p>
One thing I ended up changing, though: in the default setup (at the time when I
tried it), hostnames sent to the DHCP server would not automatically
<strong>resolve locally via DNS</strong>. I.e., I could not use <code>ping
beast</code> without any further setup to send ping probes to my gaming
computer. To fix that, for now one needs <a
href="https://forum.turris.cz/t/how-to-configure-local-address-dns-resoultion-on-omnia/1000/4">to
disable KnotDNS in favor of dnsmasq’s built-in DNS resolver</a>. This will
leave you without KnotDNS’s DNSSEC support. But I prefer ease of use in this
particular trade-off.
</p>

<h3>Compatibility (hardware)</h3>

<p>
Unfortunately, the <a
href="https://forum.turris.cz/t/fiber7-switzerland-sfp-compatibility/995">SFPs
which Fiber7 sells/requires are not immediately compatible with the Turris
Omnia</a>. If I understand correctly, the issue is related to speed
negotiation.
</p>

<p>
After months of discussion in the Turris forum and not much success on fixing
the issue, Fiber7 now offers to disable speed negotiation on your port if you
send them an email. Afterwards, your SFPs will work in media converters such as
the tp-link MC220L <strong>and</strong> the Turris Omnia.
</p>

<p>
The downside is that debugging issues with your port becomes harder, as Fiber7
will no longer be able to see whether your device correctly negotiates speed,
the link will just always be forced to “up”.
</p>

<h3>Updates</h3>

<p>
The Turris Omnia’s automated updates are a big differentiator: without
having to do anything, the Turris Omnia will install new software versions
automatically. This feature alone will likely improve your home network’s
security and this feature alone justifies buying the router in my eyes.
</p>

<p>
Of course, automated upgrades constitute a certain risk: if the new software
version or the upgrade process has a bug, things might break. This <a
href="https://forum.turris.cz/t/turris-os-3-6-out-now/3605/69?u=secure">happened
once to me</a> in the 6 months that I have been using this router. I still
haven’t seen a statement from the Turris developers about this particular
breakage — I wish they would communicate more.
</p>

<p>
Since you can easily restore your configuration from a backup, I’m not too
worried about this. In case you’re travelling and really need to access your
devices at home, I would recommend to temporarily disable the automated
upgrades, though.
</p>

<h3>Product Excellence</h3>

<p>
One feature I love is that the <strong>brightness of the LEDs</strong> can be
controlled, to the point where you can turn them off entirely. It sounds
trivial, but the result is that I don’t have to apply tape to this device to
dim its LEDs. To not disturb watching movies, playing games or having guests
crash on the living room couch, I can turn the LEDs off and only turn them back
on when I actually need to look at them for something — in practice, that’s
never, because the router just works.
</p>

<p>
<strong>Recovering</strong> the software after horribly messing up an
experiment is pretty easy: when holding the reset button for a certain number
of seconds, the device enters a mode where a new firmware file is flashed to
the device from a plugged-in USB memory stick. What’s really nice is that the
mode is indicated by the color of the LEDs, saving you other device’s tedious
counting which I tend to always start at the wrong second. This is a very good
compromise between saving cost and pleasing developers.
</p>

<p>
The Turris Omnia has a <strong>serial port</strong> readily accessible via a
pin header that’s reachable after opening the device. I definitely expected an
easily accessible serial port in a device which targets open source/hardware
enthusiasts. In fact, I have two ideas to make that serial port even better:
</p>
<ol>
<li>
Label the pins on the board — that doesn’t cost a cent more and spares some
annoying googling for a page which isn’t highly ranked in the search results.
Sparing some googling is a good move for an internet router: chances are that
accessing the internet will be inconvenient while you’re debugging your
router.
</li>
<li>
Expose the serial port via USB-C. The HP 2530-48G switch does this: you don’t
have to connect a USB2serial to a pin header yourself, rather you just plug in
a USB cable which you’ll probably carry anyway. Super convenient!
</li>
</ol>

<h3>Conclusion</h3>

<p>
tl;dr: if you can afford it, buy it!
</p>

<p>
I’m very satisfied with the Turris Omnia. I like how it is both open source and
open hardware. I rarely want to do development with my main internet router,
but when I do, the Turris Omnia makes it pleasant. The performance is as good
as advertised, and I have not noticed any stability problems with neither the
router itself nor the WiFi.
</p>

<p>
I outlined above how the next revision of the router could be made ever so
slightly more perfect, and I described the issues I ran into (SFP compatibility
and an update breaking my non-standard setup). If these aren’t deal-breakers to
you, which sounds unlikely, you should definitely consider the Turris Omnia!
</p>
