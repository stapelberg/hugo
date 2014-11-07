---
layout: post
title:  "Configuring a Ubiquiti EdgeRouter Lite (Erlite-3) for Fiber7"
date:   2014-08-11 09:55:00
categories: Artikel
---


<p>
I immediately ordered a <a href="http://www.fiber7.ch/">fiber7</a> internet
connection once it became available, and I’ve been connected since a few weeks.
They offer a 1 Gbps symmetrical fiber connection, with native (static) IPv6 and
no traffic limit — for 65 CHF per month (about 54 €).
</p>

<p>
In the order form, they let you choose whether you want to order a
pre-configured MikroTik RB2011UiAS-2HnD including fiber optic and fiber patch
cable. I assumed this would be an excellent choice, so I ordered it.
</p>

<p>
I really like the MikroTik device. Its CLI and web interface are well
thought-out and easy to use once you understand their way of thinking. It’s
small, absolutely silent and just works. However, there’s one shortcoming: it
doesn’t do IPv4 hardware acceleration (they call it “fast path”) when you
enable NAT, which you need for a fiber7 connection. Thus, the top bandwidth
maxes out at 500 to 600 Mbps, so effectively you only use half of your
available bandwidth.
</p>

<p>
Therefore, I looked around for other routers which can do a full Gigabit
WAN-to-LAN, i.e. with IPv4-NAT enabled. The selection of routers that can do
that is very small, see for example <a
href="http://www.smallnetbuilder.com/lanwan/router-charts/view">the
smallnetbuilder WAN-to-LAN router charts</a>.
</p>

<p>
In my first try, I went with the Netgear R7000 (“Nighthawk”) which is the
highest-performing router with regards to WAN-to-LAN bandwidth on
smallnetbuilder. It indeed does hardware acceleration for IPv4-NAT, so you
<strong>can</strong> reach the full 118 MB/s TCP bandwidth that a Gigabit line
offers. However, the firmware does not do DHCPv6-PD (Prefix Delegation), even
though it’s certified as IPv6-ready. There are alternative firmwares, e.g.
Tomato and DD-WRT. Tomato (v121 as of writing) comes with the kernel module
that enables IPv4-NAT hardware acceleration, but has a nasty bug: the latency
jumps up to 500ms for most of your packets, which is clearly not acceptable.
DD-WRT does not come with such a kernel module because they use a newer kernel,
so the speed maxes out at 400 Mbps (that’s what they claim, I didn’t even
bother testing it).
</p>

<h2>Ubiquiti EdgeRouter Lite (Erlite-3)</h2>

<p>
So, as a second try, I ordered what everyone recommended me in the first place:
the <a href="http://www.ubnt.com/edgemax/edgerouter-lite/">Ubiquiti EdgeRouter
Lite (Erlite-3)</a>.
</p>

<p>
The EdgeRouter Lite (with firmware v1.5.0) offers IPv4 and IPv6 offloading, and
in fact reaches Gigabit line rate (118 MB/s measured TCP performance). An
unwelcome surprise is that hardware acceleration only works when
<strong>not</strong> using bridging at all, so if you want to connect two
devices to your router in the same subnet, like a computer and a switch, you
cannot do that. Effectively, the EdgeRouter needs to sit between the internet
connection and a switch.
</p>

<p>
With regards to the web interface of EdgeOS: the web interface feels very
polished and modern, but it seems to lack a number of features that are only
accessible in the CLI interface. The MikroTik web interface had a much higher
coverage of features. In general, I like how Ubiquiti does many things right,
though: firmware updates are quick and painless, the model selection and
download on their website is very simple to find and use, and you even get a
link to the relevant GPL tarball without asking :).
</p>

<h2>Configuring the EdgeRouter Lite for fiber7</h2>

<p>
First of all, you should disconnect the MikroTik (or your current router) from
the network. I recommend doing that by explicitly disabling both DHCP clients,
so that the fiber7 router knows you are not using the old device any more. This
is important because fiber7 uses a Cisco feature called “IP source guard”,
which will disable any MAC address on your port that does not have a DHCP
lease. Therefore, if you just switch routers, you need to wait for the old
lease to expire before you get a new lease. In my first tests, this worked
relatively well, but then a lease got stuck for some reason and I had to
escalate the problem to their NOC. So, better disable the DHCP:
</p>
<pre>
/ip dhcp-client set disabled=yes numbers=0
/ipv6 dhcp-client set disabled=yes numbers=0
</pre>

<p>
In my configuration, I connect a switch to eth0 and a media converter (the
TP-LINK MC220L) to eth1. As a general tip: if you mess up your configuration,
you can always use the link-local address of the EdgeRouter and SSH into that.
Find the link-local address using <code>ping6 ff02::1%eth0</code>.
</p>

<p>
After logging into the web interface, set the eth1 address to DHCP and it
should get a public IPv4 address from fiber7. Afterwards, enable NAT by
clicking on NAT → Add Source NAT Rule. Set the outbound interface to eth1 and
select the “masquerade” radio button. You’ll also need to switch to the
“services” tab and enable a DHCP and DNS server. This should give you IPv4
connectivity to the internet.
</p>

<p>
IPv6 is a bit harder, since EdgeOS in its current version (1.5.0) does not
support DHCPv6-PD via its Web or CLI interface. The necessary software
(wide-dhcpv6) is included, though, so we can configure it manually.
</p>

<p>
For the next steps, you need to know the transfer network IP range, which seems
to be different for every fiber7 POP (location). You can get it by either using
DHCPv6 and looking at the address you get, by checking your MikroTik
configuration (if you have one) or by asking fiber7. In my case, the range is
<code>2a02:168:2000:5::/64</code>, but I’ve heard from others that they have
<code>2a02:168:2000:9::/64</code>.
</p>

<p>
Use <code>ssh ubnt@192.168.1.1</code> to log into the CLI. In order to set the
proper IPv6 address on the transfer network, run <code>ip -6 address show dev
eth1</code> and look for a line that says <code>inet6
fe80::de9f:dbff:fe81:a906/64 scope link</code>. Copy everything after the
<code>::</code> and prefix it with <code>2a02:168:2000:5:</code> (your fiber7
transfer network range), then configure that as static IPv6 address on eth1 and
set the default route (and enable IPv6 offloading):
</p>
<pre>
configure
set system offload ipv6 forwarding enable
set interfaces ethernet eth1 address 2a02:168:2000:5:de9f:dbff:fe81:a906/64
set protocols static route6 ::/0 next-hop 2a02:168:2000:5::1 interface eth1
commit
save
exit
</pre>

<p>
Now you should be able to run <code>ping6 google.ch</code> and get a reply.
We still need to enable DHCPv6 though so that the router gets a prefix and
hands that out to its clients. Run <code>sudo -s</code> to get a root shell and
configure DHCPv6:
</p>
<pre>
cat >/etc/wide-dhcpv6/dhcp6c-script-zkj <<'EOT'
#!/bin/sh
# wide-dhcpv6-client 20080615-12 does not properly close
# file descriptors when starting the script.
# https://bugs.debian.org/757848
exec 4>&- 5>&- 6>&- 7>&-
# To prevent radvd from sending the final router advertisment
# that unconfigures the prefixes.
killall -KILL radvd
/etc/init.d/radvd restart
exit 0
EOT
chmod +x /etc/wide-dhcpv6/dhcp6c-script-zkj

cat >/etc/wide-dhcpv6/dhcp6c.conf <<'EOT'
interface eth1 {
        send ia-pd 0;
        request domain-name-servers;
        script "/etc/wide-dhcpv6/dhcp6c-script-zkj";
};

id-assoc pd 0 {
        prefix-interface eth0 {
                sla-id 1;
                sla-len 0;
        };
};
EOT

sed -i 's/eth0/eth1/g' /etc/default/wide-dhcpv6-client

cat >/config/scripts/post-config.d/dhcpv6.sh <<'EOT'
#!/bin/sh
/etc/init.d/wide-dhcpv6-client start
EOT
chmod +x /config/scripts/post-config.d/dhcpv6.sh

/config/scripts/post-config.d/dhcpv6.sh
</pre>

<p>
Now, when running <code>ip -6 address show dev eth0</code> you should see that
the router added an IPv6 address like
<code>2a02:168:4a09:0:de9f:dbff:fe81:a905/48</code> to eth0. Let’s enable
router advertisments so that clients get an IPv6 address, route and DNS server:
</p>
<pre>
configure
set interfaces ethernet eth0 ipv6 router-advert prefix ::/64
set interfaces ethernet eth0 ipv6 router-advert radvd-options
  "RDNSS 2001:4860:4860::8888 {};"
commit
save
exit
</pre>

<p>
That’s it! On clients you should be able to <code>ping6 google.ch</code> now and get replies.
</p>

<h2>Bonus: Configuring a DHCPv6-DUID</h2>

<p>
fiber7 wants to hand out static IPv6 prefixes based on the DHCPv6 option 37,
but that’s not ready yet. Until then, they offer you to set a static prefix
based on your DUID (a device identifier based on the MAC address of your
router). Since I switched from the MikroTik, I needed to port its DUID to the
EdgeRouter to keep my static prefix.
</p>

<p>
Luckily, wide-dhcpv6 reads a file called dhcp6c_duid that you can create with
the proper DUID. The file starts with a 16-bit integer containing the length of
the DUID, followed by the raw DUID:
</p>

<pre>
echo -en '\x00\x0a\x00\x03\x00\x01\x4c\x5e\x0c\x43\xbf\x39' > /var/lib/dhcpv6/dhcp6c_duid
</pre>

<h2>Conclusion</h2>

<p>
I can see why fiber7 went with the MikroTik as their offer for customers: it
combines a media converter (for fiber to ethernet), a router, a switch and a
wifi router. In my configuration, those are now all separate devices: the
TP-LINK MC220L (27 CHF), the Ubiquiti EdgeRouter Lite Erlite-3 (170 CHF) and
the TP-LINK WDR4300 (57 CHF). The ping latency to google.ch has gone up from
0.6ms to 0.7ms due to the additional device, but the download rate is about
twice as high, so I think this is the setup that I’ll keep for a while — until
somebody comes up with an all-in-one device that provides the same features and
achieves the same rates :-).
</p>
