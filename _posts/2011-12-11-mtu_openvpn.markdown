---
layout: post
title:  "MTU and OpenVPN: How does it work?"
date:   2011-12-11 11:00:00
categories: Artikel
---


<p>
I use OpenVPN relatively often, for example to get reliable IPv6-connectivity
in places which don’t have IPv6 yet (miredo works well most of the time, but an
own VPN is more stable). One of the things which I previously understood only a
little bit was the MTU (Maximum Transfer Unit). Not configuring it properly
leads to transferring more data than necessary (best case) or losing some
packets entirely (worst case). The evil detail is that it only affects packets
of a certain size – for example Kerberos packets are usually pretty large and
thus often get dropped when your MTU is misconfigured.
</p>

<h3>MTU on the link</h3>

<p>
The MTU is a setting of the IP protocol and specifies how much data can fit
into a single IP packet. Typical values for the MTU are 1500 bytes on
Ethernet links or 1492 bytes on PPPoE links. You can find out the MTU by
looking at your interface configuration:
</p>

<pre>
$ ip link show dev eth0
2: eth0: &lt;BROADCAST,MULTICAST,UP,LOWER_UP&gt; <strong>mtu 1500</strong> state UP qlen 1000
    link/ether 00:1f:16:3a:f9:b8 brd ff:ff:ff:ff:ff:ff
</pre>

<p>
Let’s take an ICMP packet as an example: ICMP sits on top of IP. So, we have
the IP header which is 20 bytes, plus the ICMP header which is 8 bytes (use
Wireshark and look at the "Total Length" field of the IP packet to verify
this). Therefore, with an MTU of 1500 bytes, you can fit 1500 - 20 - 8 = 1472
bytes in one packet. We can use <code>ping(1)</code> to send packets with that
size:
</p>

<pre>
$ ping -M do -c 1 -s 1472 www.heise.de
PING www.heise.de (193.99.144.85) 1472(1500) bytes of data.
1480 bytes from www.heise.de (193.99.144.85): icmp_req=1 ttl=243 time=96.4 ms

--- www.heise.de ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 96.489/96.489/96.489/0.000 ms
</pre>

<p>
As you can see, ping takes the <strong>ICMP payload size</strong> of 1472
bytes, leading to a total size of 1500 bytes. I think that the <code>-s</code>
argument varies between operating systems, because a lot of examples on the web
use <code>-s 1500</code>, which is just wrong (on Linux at least). The <code>-M
do</code> parameter advises ping to set the "do not fragment" bit.
</p>

<p>
Here is an example of the output you will get when you use the wrong MTU for
your link:
</p>

<pre>
$ ping -M do -c 1 -s 1500 www.heise.de
PING www.heise.de (193.99.144.85) 1500(1528) bytes of data.
From 87.198.114.189 icmp_seq=1 Frag needed and DF set (mtu = 1500)

--- www.heise.de ping statistics ---
0 packets transmitted, 0 received, +1 errors
</pre>

<p>
In this case, I got an ICMP error telling me about the correct MTU size to use.
This is called <a href="http://en.wikipedia.org/wiki/Path_MTU_Discovery">"Path
MTU Discovery"</a>, but in some rare cases, administrators block all ICMP
traffic in their firewall and therefore this feature does not work. In that
case, you would just get no ping reply.
</p>

<p>
To find out the right MTU, decrease the ping size until you get a reply, then
set the MTU to the total packet size. Don’t just pick one single host to test
with, though – maybe the host has a misconfigured MTU :-).
</p>

<h3>MTU in OpenVPN</h3>

<p>
Above, we have figured out that the MTU indeed is 1500 bytes for our link. Now
how do we configure OpenVPN for that? I assume you are running OpenVPN using
UDP. The UDP header is 8 bytes (just like ICMP), so we will end up with 1472
bytes as the payload size. In our OpenVPN configuration, we will therefore use
the <code>link-mtu 1472</code> directive. This leads to OpenVPN setting the
correct MTU on its <code>tun0</code> interface:
</p>

<pre>
$ ip link show dev tun0              
35: tun0: &lt;POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP&gt; mtu 1427 state UNKNOWN
    link/none 
</pre>

<p>
The MTU is 1427 due to the OpenVPN overhead. We can verify that packets using
the full MTU will arrive correctly by using ping:
</p>

<pre>
$ sudo ip -4 route add 193.99.144.85 via 10.254.254.254
$ ping -M do -c 1 -s 1399 193.99.144.85
PING 193.99.144.85 (193.99.144.85) 1399(1427) bytes of data.
1407 bytes from 193.99.144.85: icmp_req=1 ttl=246 time=97.4 ms

--- 193.99.144.85 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 97.420/97.420/97.420/0.000 ms
</pre>

<p>
By the way, I’ve sometimes seen OpenVPN error messages saying:
</p>

<pre>
Authenticate/Decrypt packet error: packet HMAC authentication failed
</pre>

<p>
Seeing these only some times (while the VPN itself works) is a hint to
incorrect MTU configuration.
</p>

<h3>See also</h3>

<ul>
<li>
<a href="http://www.netheaven.com/pmtu.html">
http://www.netheaven.com/pmtu.html</a><br>
A good description of Path MTU Discovery.
</li>

<li>
<a href="http://openvpn.net/archive/openvpn-users/2005-10/msg00354.html">
http://openvpn.net/archive/openvpn-users/2005-10/msg00354.html</a><br>
A thread describing the different MTU flags which OpenVPN has.
</li>

</ul>
