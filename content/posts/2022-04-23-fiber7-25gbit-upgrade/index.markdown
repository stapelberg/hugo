---
layout: post
title:  "My upgrade to 25 Gbit/s Fiber To The Home"
date:   2022-04-23 16:00:00 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1517872128602914816"
tags:
- fiber
---

My favorite internet service provider, init7, is rolling out faster speeds with their infrastructure upgrade. Last week, the point of presence (POP) that my apartment’s fiber connection terminates in was upgraded, so now I am enjoying a 25 Gbit/s fiber internet connection!

## My first internet connections {#firstinternet}

(Feel free to skip right to the [25 Gbit/s announcement](#announcement) section, but I figured this would be a good point to reflect on the last 20 years of internet connections for me!)

The first internet connection that I consciously used was a symmetric DSL connection that [my dad († 2020)](https://rent-a-guru.de) shared between his home office and the rest of the house, which was around the year 2000. My dad was an early adopter and was connected to the internet well before then using dial up connections, but the SDSL connection in our second house was the first connection I remember using myself. It wasn’t particularly fast in terms of download speed — I think it delivered 256 Kbit/s or something along those lines.

I encountered two surprises with this internet connection. The first surprise was that the upload speed (also 256 Kbit/s — it was a symmetric connection) was faster than other people’s. At the time, even DSL connections with much higher download speeds were asymmetric (ADSL) and came with only 128 Kbit/s upload. I learnt this while making first contact with file sharing: people kept asking me to stay online so that their transfers would complete more quickly.

The second surprise was the concept of a metered connection, specifically one where you pay more the more data you transfer. During the aforementioned file sharing experiments, it never crossed my mind that down- or uploading files could result in extra charges.

These two facts combined resulted in a 3000 € surprise bill for my dad!

Luckily, his approach to solve this problem wasn’t to restrict my internet usage, but rather to buy a cheap, separate ADSL flatrate line for the family (from Telekom, which he hated), while he kept the good SDSL metered line for his business.

I still vividly remember the first time that ADSL connection synchronized. It was a massive upgrade in download speed (768 Kbit/s!), but a downgrade in upload speed (128 Kbit/s). But, because it was a flatrate, it made possible new use cases for my dad, who would jump on this opportunity to download a number of CD images to upgrade the software of his SGI machines.

The different connection speeds and characteristics have always interested me, and I used several other connections over the years, all of which felt limiting. The ADSL connection at my parent’s place started at 1 Mbit/s, was upgraded first to 3 Mbit/s, then 6 Mbit/s, and eventually reached its limit at 16 Mbit/s. When I spent one semester in Ireland, I had a 9 Mbit/s ADSL connection, and then later in Zürich I started out with a 15 Mbit/s ADSL connection.

All of these connections have always felt limiting, like peeking through the keyhole to see a rich world behind, but not being able to open the door. We’ve had to set up (and tune) traffic shaping, and coordinate when large downloads were okay.

## My first fiber connection {#firstfiber}

The dream was always to leave ADSL behind and get a fiber connection. The
advantages are numerous: lower latency (ADSL came with 40 ms at the time), much
higher bandwidth (possibly Gigabit/s?) and typically the connection was
established via ethernet (instead of PPPoE). Most importantly, once the fiber is
there, you can upgrade both ends to achieve higher speeds.

In Zürich, I managed to get a fiber connection set up in my apartment after fighting bureaucracy for many months. The issue was that there was no permission slip on file at Swisscom. Either the owner of my apartment never signed it to begin with, or it got lost. This is not a state that the online fiber availability checker can represent, but once you know it, the fix is easy: just have Swisscom send out the form again, have the owner sign it, and a few weeks later, you can order!

One wrinkle was that availability was only fixed in the Swisscom checker, and it was unclear when EWZ or other providers would get an updated data dump. Hence, I ordered Swisscom fiber to get things moving as quick as possible, and figured I could switch to a different provider later.

Here’s a picture of when the electrician pulled the fiber from the building entry endpoint (BEP) in the basement into my flat, from March 2014:

{{< img src="2014-03-26-fiber-apartment.jpg" >}}

## Switching to fiber7 {#switching}

Only two months after I first got my fiber connection, init7 launched their fiber7 offering, and I switched from Swisscom to fiber7 as quickly as I could.

The switch was worth it in every single dimension:

* Swisscom charged over 200 CHF per month for a 1 Gbit/s download, 100 Mbit/s upload fiber connection. fiber7 costs only 65 CHF per month and comes with a symmetric 1 Gbit/s connection. (Other providers had to follow, so now symmetric is standard.)
* init7’s network performs much better than Swisscom’s: ping times dropped when I switched, and downloads are generally much faster. Note that this is with *the same physical fiber line*, so the difference is thanks to the numerous peerings that init7 maintains.
* init7 gives you a static IPv6 prefix (if you want) for free, and even delegates reverse DNS to your servers of choice.
* I enjoy init7’s unparalleled transparency. For example, check out [the blog post about cost calculation](https://blog.init7.net/de/rentabilitatsrechnung/) if you’re ever curious if there could be a fiber7 POP in your area.

I have been very happy with my fiber7 connection ever since. [What I wrote in 2014 regarding its performance](/posts/2014-09-05-fiber7_performance/) remained true over the years — downloads were always fast for me, latencies were low, outages were rare (and came with good explanations).

I switched hardware multiple times over the years:

* First, I started with the [Ubiquiti EdgeRouter Lite](/posts/2014-08-11-fiber7_ubnt_erlite/) which could handle the full Gigabit line rate (the MikroTik router I originally ordered maxed out at about 500 Mbit/s!).
* In 2017, I switched to the [Turris Omnia](/posts/2017-03-25-turris-omnia/), an open hardware, open source software router that comes with automated updates.
* In July 2018, after my connectivity was broken due to an incompatibility between the DHCPv6 client on the Turris Omnia and fiber7, I started developing my own [router7](https://router7.org) in Go, [my favorite programming language](/posts/2017-08-19-golang_favorite/), mostly for fun, but also as a proof of concept for some cool features I think routers should have. For example, you can retro-actively start up Wireshark and open up a live ring buffer of the last few hours of network configuration traffic.

Notably, init7 encourages people to use their preferred router ([Router
Freedom](https://fsfe.org/activities/routers/routers.en.html)).

## The 25 Gbit/s announcement {#announcement}

Over the years, other Swiss internet providers such as Swisscom and Salt introduced 10 Gbit/s offerings, so an obvious question was when init7 would follow suit.

People who were following init7 closely already knew that an infrastructure upgrade was coming. In 2020, init7 CEO Fredy Künzler [disclosed that in 2021, init7 would start offering 10 Gbit/s](https://twitter.com/kuenzler/status/1317841532813254659).

What nobody expected before init7 announced it on their seventh birthday, however, was that init7 started offering not only 10 Gbit/s (Fiber7-X), but also 25 Gbit/s connections (Fiber7-X2)! 🤯

This was init7’s announcement on Twitter:

{{< tweet user="init7" id="1397111796914327552" >}}

With this move, init7 has done it again: they introduced an offer that is better than anything else in the Swiss internet market, perhaps even world-wide!

One interesting aspect is init7’s so-called «[MaxFix principle](https://www.init7.net/en/internet/offer/)»: maximum speed for a fixed price. No matter if you’re using 1 Gbit/s or 25 Gbit/s, you pay the same monthly fee. init7’s approach is to make the maximum bandwidth available to you, limited only by your physical connection. This is such a breath of fresh air compared to other ISPs that think rate-limiting customers to ridiculously low speeds is somehow acceptable on an FTTH offering 🙄 ([recent example](https://twitter.com/kuenzler/status/1515062457731063815)).

If you’re curious about the infrastructure upgrade that enabled this change,
check out [init7’s blog post about their new POP
infrastructure](https://blog.init7.net/de/neue-infrastruktur/).

## What for? The use-case {#usecase}

A common first reaction to fast network connections is the question: “For what do you need so much bandwidth?”

Interestingly enough, I heard this question as recently as last year, in the context of a Gigabit internet connection! Some people can’t imagine using more than 100 Mbit/s. And sure, from a certain perspective, I get it — that 100 Mbit/s connection will not be overloaded any time soon.

But, looking at when a line is overloaded is only one aspect to take into account when deciding how fast of a connection you want.

There is a lower limit where you notice your connection is slow. Back in 2014, a 2 Mbit/s connection was noticeably slow for regular web browsing. These days, even a 10 Mbit/s connection is noticeably slow when re-opening my browser and loading a few tabs in parallel.

So what should you get? A 100 Mbit/s line? 500 Mbit/s? 1000 Mbit/s? Personally, I like to not worry about it and just get the fastest line I can, to reduce any and all wait times as much as possible, whenever possible. It’s a freeing feeling! Here are a few specific examples:

* If I have to wait only [17 minutes](https://twitter.com/zekjur/status/1494569749195468813) to download a PS5 game, that can make the difference between an evening waiting in frustration, or playing the title I’ve been waiting for.
* If I can run a daily backup (over the internet) of all servers I care about without worrying that the transfers interfere with my work video calls, that gives me peace of mind.
* If I can transfer a Debian Code Search index to my computer for debugging when needed, that might make the difference between being able to use the limited spare time I have to debug or improve Debian Code Search, or having to postpone that improvement until I find more time.

Aside from my distaste for waiting, a fast and reliable fiber connection enables self-hosting. In particular for my [distri Linux](https://distr1.org/) project where I explore fast package installation, it’s very appealing to connect it to the internet on as fast a line as possible. I want to optimize all the parts: software architecture and implementation, hardware, and network connectivity. But, for my hobby project budget, getting even a 10 Gbit/s line at a server hoster is too expensive, let alone a 25 Gbit/s line!

Lastly, even if there isn’t really a *need* to have such a fast connection, I hope you can understand that after spending so many years of my life limited by slow connections, that I’ll happily *take the opportunity* of a faster connection whenever I can. Especially at no additional monthly cost!

## Getting ready {#gettingready}

Right after the announcement dropped, I wanted to prepare my side of the connection and therefore ordered a MikroTik CCR2004, the only router that init7 lists as compatible. I [returned the MikroTik CCR2004 shortly afterwards](/posts/2021-05-28-configured-and-returned-mikrotik-ccr2004-for-fiber7/), mostly because of its annoying fan regulation (spins up to top speed for about 1 minute every hour or so), and also because MikroTik seems to have made no progress at all since I last used their products almost 10 years ago. Table-stakes features such as DNS resolution for hostnames within the local network are still not included!

{{< img src="mikrotik-ccr2004.jpg" >}}

I expect that more and more embedded devices with SFP28 slots (like the MikroTik CCR2004) will become available over the next few years (hopefully with better fan control!), but at the moment, the selection seems to be rather small.

For my router, I instead went with a [custom PC build](/posts/2021-07-10-linux-25gbit-internet-router-pc-build/). Having more space available means I can run larger, slow-spinning fans that are not as loud. Plugging in high-end Intel network cards (2 × 25 Gbit/s, and 4 × 10 Gbit/s on the other one) turns a PC into a 25 Gbit/s capable router.

{{< img src="2021-06-27-router25.jpg" >}}


With my equipment sorted out, I figured it was time to actually place the order. I wasn’t in a hurry to order, because it was clear that it would be months before my POP could be upgraded. But, it can’t hurt to register my interest (just in case it influences the POP upgrade plan). Shortly after, I got back this email from init7 where they promised to send me the SFP module via post:

{{< img src="2021-08-16-confirmation.jpg" >}}

And sure enough, a few days later, I received the SFP28 module in the mail:

{{< img src="2021-08-19-sfp-mail.jpg" >}}

With my router build, and the SFP28 module, I had everything I needed for my side of the connection.

The other side of the connection was originally planned to be upgraded in fall 2021, but [the global supply shortage imposed various delays on the schedule](https://twitter.com/init7/status/1403287499175235584).

Eventually, the [fiber7 POP list](https://www.init7.net/en/infrastructure/fiber7-pops/) showed an upgrade date of April 2022 for my POP, and that turned out to be correct.

## The night of the upgrade {#upgrade}

I had read [Pim’s blog post on the upgrade of the 1790BRE POP in Brüttisellen](https://ipng.ch/s/articles/2021/08/28/fiber7-x.html), which contains a lot of super interesting details, so definitely check that one out, too! 

Being able to plug in the SFP module into the new POP infrastructure yourself (like Pim did) sounded super cool to me, so I decided to reach out, and init7 actually agreed to let me stop by to plug in “my” fiber and SFP module!

Giddy with excitement, I left my place at just before 23:00 for a short walk to the POP building, which I had seen many times before, but never from the inside.

[Patrick](https://twitter.com/patte8), the init7 engineer met me in front of the building and explained “Hey! You wrote my [window manager](https://i3wm.org/)!” — what a coincidence :-). Luckily I had packed some i3 stickers that I could hand him as a small thank you.

Inside, I met the other init7 employee working on this upgrade. Pascal, init7’s CTO, was coordinating everything remotely.

Standing in front of init7’s rack, I spotted the old Cisco switch (at the bottom), and the new Cisco C9500-48Y4C switches that were already prepared (at the top). The SFP modules are for customers who decided to upgrade to 10 or 25 Gbit/s, whereas for the others, the old SFP modules would be re-used:

{{< img src="2022-04-12-pop-before.jpg" >}}

We then spent the next hour pulling out fiber cables and SFP modules out of the old Cisco switch, and plugging them back into the new Cisco switch.

Just like the init7 engineer working with me (who is usually a software guy, too, he explained), I enjoy doing physical labor from time to time for variety. Especially with nice hardware like this, and when it’s for a good cause (faster internet)! It’s almost meditative, in a way, and I enjoyed the nice conversation we had while we were both moving the connections.

After completing about half of the upgrade (the top half of the old Cisco switch), I walked back to my place — still blissfully smiling all the way — to turn up my end of the connection while the others were still on site and could fix any mistakes.

After switching my `uplink0` network interface to the faster network card, it also took a full reboot of my router for some reason, but then it recognized the SFP28 module without trouble and successfully established a 25 Gbit/s link! 🎉 🥳

I did a quick speed test to confirm and called it a night.

## Speed tests / benchmarks {#speedtest}

Just like in the early days of Gigabit connections, my internet connection is
now faster than the connection of many servers. It’s a luxury problem to be
sure, but in case you’re curious how far a 25 Gbit/s connection gets you in the
internet, in this section I collected some speed test results.

### Ookla speedtest.net

speedtest.net (run by Ookla) is the best way to measure fast connections that I’m aware of.

Here is [my first 25 Gbit/s
speedtest](https://www.speedtest.net/result/c/ed97e48a-3655-4fc8-8e7f-4d18d48f10f5),
which was run using the [init7 speedtest server](https://speedtest.init7.net/):

{{< img src="2022-04-14-speedtest-ookla-featured.png" >}}

I also ran speedtests to all other servers that were listed for the broader
Zürich area at the time, using the
[tamasboros/ookla-speedtest](https://hub.docker.com/r/tamasboros/ookla-speedtest)
Docker image. As you can see, most speedtest servers are connected with a 10
Gbit/s port, and some (GGA Maur) even only with a 1 Gbit/s port:

| Speedtest server             | latency | download (mbps) | upload (mbps) |
|------------------------------|---------|-----------------|---------------|
| Init7 AG - Winterthur        | 1.45    | 23530.27        | 23031.24      |
| fdcservers.net               | 18.15   | 9386.29         | 1262.92       |
| GIB-Solutions AG - Schlieren | 6.64    | 9154.12         | 2207.68       |
| Monzoon Networks AG          | 0.74    | 8874.85         | 6427.66       |
| Glattwerk AG                 | 0.92    | 8719.04         | 4008.28       |
| AltusHost B.V.               | 0.80    | 8373.34         | 8518.90       |
| iWay AG - Zurich             | 2.13    | 8337.56         | 8194.89       |
| Sunrise Communication AG     | 9.04    | 8279.60         | 3109.34       |
| 31173 Services AB            | 18.69   | 8279.75         | 1503.92       |
| Wingo                        | 4.25    | 6179.57         | 5248.36       |
| Netrics Zürich AG            | 0.74    | 7910.78         | 8770.19       |
| Cloudflare - Zurich          | 1.14    | 7410.97         | 2218.88       |
| Netprotect - Zurich          | 0.87    | 7034.62         | 8948.01       |
| C41.ch - Zurich              | 9.90    | 6792.60         | 690.33        |
| Goldenphone GmbH             | 18.91   | 3116.32         | 659.23        |
| GGA Maur                     | 0.99    | 940.24          | 941.24        |

### Linux mirrors

For a few popular Linux distributions, I went through the mirror list and tried
all servers in Switzerland and Germany. Only one or two would be able to deliver
files at more than 1 Gigabit/s. Other miror servers were either capped at 1
Gigabit/s, or wouldn’t even reach that (slow disks?).

Here are the fast ones:

* **Debian:** `mirror1.infomaniak.com` and `mirror2.infomaniak.com`
* **Arch Linux:** `mirror.puzzle.ch`
* **Fedora Linux:** `mirrors.xtom.de`
* **Ubuntu Linux:** `mirror.netcologne.de` and `ubuntu.ch.altushost.com`

### iperf3

Using `iperf3 -P 2 -c speedtest.init7.net`, iperf3 shows 23 Gbit/s:

```
[SUM]   0.00-10.00  sec  26.9 GBytes  23.1 Gbits/sec  597             sender
[SUM]   0.00-10.00  sec  26.9 GBytes  23.1 Gbits/sec                  receiver
```

It’s hard to find public iperf3 servers that are connected with a fast-enough
port. I could only find one that claims to be connected via a 40 Gbit/s port,
but it was unavailable when I wanted to test.

### Interested in a speed test?

Do you have a ≥ 10 Gbit/s line in Europe, too? Are you interested in a speed
test? Reach out to me and we can set something up.

## Conclusion

What an exciting time to be an init7 customer! I still can’t quite believe that
I now have a 25 Gbit/s connection in 2022, and it feels like I’m living 10 years
in the future.

Thank you to [Fredy](https://twitter.com/kuenzler),
[Pascal](https://twitter.com/spale75), [Patrick](https://twitter.com/patte8),
and all the other former and current init7 employees for showing how to run an
amazing Internet Service Provider. Thank you for letting me peek behind the
curtains, and keep up the good work! 💪

If you want to learn more, check out Pascal’s talk at DENOG:

{{< youtube id="fmzst6I5LwQ" title="Wie wir unabsichtlich das schnellste residential Internet access gebaut haben - Pascal Gloor" >}}
