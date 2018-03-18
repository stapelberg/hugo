---
layout: post
title:  "Fiber7 performance"
date:   2014-09-05 12:00:00
categories: Artikel
Aliases:
  - /Artikel/fiber7_performance
---


<p>
Ever since I moved to Zürich, I wanted to get a fiber internet connection. I’ve
lived with a 6 Mbps DSL line at my parent’s place for about 10 years, so I was
looking forward to a lot more Megabits and a lot less latency. For reasons that
I won’t go into in this article, it took me about a year to get a fiber
connection, and in the end I had to go with Swisscom (instead of <a
href="http://www.init7.ch/">init7</a> on top of EWZ).
</p>

<p>
But then <a href="http://www.fiber7.ch/">fiber7</a> launched. They provide a 1
Gbps symmetrical connection (Swisscom provided a 1 Gbps/100 Mbps down/up
connection) for a lot less money than Swisscom, and with native, static IPv6.
</p>

<p>
A couple of people are interested in how fiber7 performs, and after being
connected for about 2 months, I think I can answer this question by now :-).
</p>

<h2>Latency</h2>

<p>
I started running smokeping to see how my internet connection performs back
when I was with Swisscom, because they had some routing issues to certain
networks. This would manifest itself with getting 50 KB/s transfer rates,
which is unacceptable for image boards or any other demanding application.
</p>

<p>
So, here is the smokeping output for google.ch during the time period that
covers both my Swisscom line, the temporary cablecom connection and finally
fiber7:
</p>

<img src="/Bilder/fiber_ping_google_ch_annotated.png" width="800" height="424"
 alt="smokeping latency to google.ch (annotated)">

<p>
What you can see is that with Swisscom, I had a 6 ms ping time to google.ch.
Interestingly, once I used the MikroTik RB2011 instead of the Swisscom-provided
internet box, the latency improved to 5&nbsp;ms.
</p>

<p>
Afterwards, latency changed twice. For the first change, I’m not sure what
happened. It could be that Swisscom turned up a new, less loaded port to peer
with Google. Or perhaps they configured their systems in a different way, or
exchanged some hardware. The second change is relatively obvious: Swisscom
enabled GGC, the <a href="https://peering.google.com/about/ggc.html">Google
Global Cache</a>. GGC is a caching server provided by Google that is placed
within the ISP’s own network, typically providing much better latencies (due to
being placed very close to the customer) and reducing the traffic between the
ISP and Google. I’m confident that Swisscom uses that because of the reverse
pointer record of the IP address to which google.ch resolves to. So with that,
latency is between 1&nbsp;ms and 3&nbsp;ms.
</p>

<p>
Because switching to Fiber7 involves recabling the physical fiber connection in
the POP, there is a 2-day downtime involved. During that time I used <a
href="http://www.upc-cablecom.ch/en/get-cable/cable-information/basic-digital-offer/">UPC
cablecom’s free offering</a>, which is a 2&nbsp;Mbps cable connection that you can
use for free (as long as you pay for the cable connection itself, and after
paying 50 CHF for the modem itself).
</p>

<p>
As you can see on the graph, the cable connection has a surprisingly good
latency of around 8&nbsp;ms to google.ch — until you start using it. Then it’s
clear that 2 Mbps is not enough and the latency shoots through the roof.
</p>

<p>
The pleasant surprise is that fiber7’s ping time to google.ch is about
0.6&nbsp;ms (!). They achieve such low latency <a
href="https://twitter.com/fiber7_ch/status/508344516622159872">with a dedicated
10 gig interconnect to Google at the Interxion in Glattbrugg</a>.
</p>

<h2>Longer-term performance</h2>

<img src="/Bilder/fiber_ping_google_ch_week.png" width="697" height="315"
 alt="smokeping latency measurements to google.ch over more than a week">

<p>
Let me say that I’m very happy with the performance of my internet connection.
Some of the measurements where packet loss is registered may be outside of
fiber7’s control, or even caused by me, when recabling my equipment for
example. Overall, the latency is fine and consistent, much more so than with
Swisscom. I have never experienced an internet outage during the two months
I’ve been with fiber7 now.
</p>

<p>
Also, while I am not continuously monitoring my bandwidth, rest assured that
whenever I download something, I am able to utilize the full Gigabit, meaning I
get an aggregate speed of 118 MB/s from servers that support it. Such servers
are for example one-click hosters like uploaded, but also Debian mirrors (as
soon as you download from multiple ones in parallel).
</p>

<h2>Conclusion</h2>

<p>
tl;dr: fiber7 delivers. Incredible latency, no outages (yet), full download speed.
</p>
