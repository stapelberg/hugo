---
layout: post
title:  "Conditionally tunneling SSH connections"
date:   2016-06-16 17:20:00
categories: Artikel
---

<p>
Whereas most of the networks I regularly use (home, work, hackerspace, events,
…) provide native IPv6 connectivity, sometimes I’m in a legacy-only network,
e.g. when tethering via my phone on some mobile providers.
</p>

<p>
By far the most common IPv6-only service I use these days is SSH to my
computer(s) at home. On philosophical grounds, I refuse to set up a dynamic DNS
record and port-forwardings, so the alternative I use is either <a
href="https://en.wikipedia.org/wiki/Miredo">Miredo</a> or tunneling through a
dual-stacked machine. For the latter, I used to use the following SSH config:
</p>

<pre>
Host home
        Hostname home.zekjur.net
        ProxyCommand ssh -4 dualstack nc %h %p
</pre>

<p>
The issue with that setup is that it’s inefficient when I’m in a network which
does support IPv6, and it requires me to authenticate to both machines. These
are not huge issues of course, but they bother me enough that I’ve gotten into
the habit of commenting out/in the <code>ProxyCommand</code> directive
regularly.
</p>

<p>
I’ve discovered that SSH can be told to use a <code>ProxyCommand</code> only
when you don’t have a route to the public IPv6 internet, though:
</p>

<pre>
Match host home exec "ip -6 route get 2001:7fd::1 | grep -q unreachable"
        ProxyCommand ssh -4 dualstack nc %h %p

Host home
        Hostname home.zekjur.net
</pre>

<p>
The IPv6 address used is from <code>k.root-servers.net</code>, but no packets
are being sent — we merely ask the kernel for a route. When you don’t have an
IPv6 address or default route, the <code>ip</code> command will print
<code>unreachable</code>, which enables the <code>ProxyCommand</code>.
</p>

<p>
For debugging/verifying the setup works as expected, use <code>ssh -vvv</code>
and look for lines prefixed with “Debug3”.
</p>
