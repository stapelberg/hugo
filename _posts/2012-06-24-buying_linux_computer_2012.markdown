---
layout: post
title:  "Buying a Linux computer (2012)"
date:   2012-06-24 22:10:00
categories: Artikel
---



<div style="float: right; margin-right: 4em; margin-left: 1em; background-color: #eee; padding: 1em; border-radius: 5px">
<a href="/Bilder/linux-computer-2012.jpg"><img src="/Bilder/linux-computer-2012.thumb.jpg" width="200" height="141" alt="Linux computer 2012" border="0" style="box-shadow: 3px 3px 5px 1px #000"></a><br>
<small>the finished box (1024x720 px)</small>
</div>

<p>
It’s been roughly three years since I upgraded my last workstation and I felt
it was time for a new computer. With a new CPU, a fast SSD and lots of RAM,
compilation times should be much faster and annoying waiting for my computer to
do stuff should be much reduced.
</p>

<p>
Anyone who reads my website will know that I am not interested in running
anything except Linux on my computers, so different criteria apply when buying
a new computer. Since a few people asked me about my new hardware configuration
and which hardware works well with Linux, I thought I’d write this article :-).
</p>

<h2>Requirements for that computer</h2>

<p>
An ideal workstation fulfills the following criteria for me:
</p>

<ul>
<li>
It is silent. I don’t want to hear some fan or hard drive humming when I need
to concentrate over some code or during the quiet parts of a movie. This
implies a good case, possibly a fanless or very silent power supply and a
silent CPU fan.
</li>

<li>
It’s fast for tasks which are important to me. This is mostly working on the
command line, compiling code, debugging, browsing. In particular, it is not
gaming, rendering videos or other computationally intensive tasks which
<strong>really</strong> need the fastest CPU and GPU out there. It does imply a
Solid State Drive however :-).
</li>

<li>
It doesn’t consume much energy. I don’t need to have the very lowest power
hardware which is available, but I don’t want to spend a lot of money on
electricity either (plus using lots of electricity is bad, mhkay?).
</li>

<li>
It needs to support two monitors without an external graphics card (that is,
with its onboard graphics). It also needs to support display configuration with
XRandR and a FOSS driver is a plus.
</li>

<li>
It needs to support suspend to RAM on Linux so that I don’t need to leave it
running while I sleep.
</li>
</ul>

<h2>The case</h2>

<p>
After reading a <a
href="http://www.techpowerup.com/reviews/Fractal_Design/Define_R3/">very good
review about the <code>Fractal Design Define R3</code></a>, I decided to buy one of
these. I am very happy with it: It doesn’t contain any sharp edges, building
the computer was fun, all screws are included and properly labeled (!) and it
feels like a product which is well worth its 86&nbsp;€.
</p>

<p>
This case comes with noise absorbing material included so you don’t have to
order it separately and cut it to fit the case. Also, it has many places where
you can place (slow-running, big) fans in case you need to. In order to
maintain a steady air flow, you should have at least one fan constantly moving
air through your whole case — motherboards are built under the assumption that
this kind of implicit cooling is available.
</p>

<p>
One thing to watch out for is the SATA cables: Using standard cables works, but
you will be much better off with 90 degree cables.
</p>

<h2>The Motherboard and CPU</h2>

<p>
Since my requirements for a motherboard are pretty strict, the only thing I can
buy are boards with Intel chipsets and therefore Intel CPUs. The current
generation of Intel CPUs is called Sandy Bridge with CPU model names like the
Intel Core i7-2600K.
</p>

<p>
Intel usually has a few CPU models which are extremely performant and some
which consume less power. In this generation, an extremely performant one has
the label Core i7 Extreme Edition, while the ones that consume less power are
the Core i5-2300 and upwards. Usually, you want to find the middle ground here
(which varies for your specific demands).
</p>

<p>
It’s pretty hard to find independent benchmarks which have good numbers on the
overall power consumption of a system with a specific CPU model, so I didn’t
spend a lot of time comparing <strong>all the CPUs</strong> against each other.
However, I found <a
href="http://www.legionhardware.com/articles_pages/intel_core_i5_2500k_and_core_i7_2600k_sandy_bridge,10.html">one
article on legionhardware.com</a> and <a
href="http://www.tomshardware.com/reviews/sandy-bridge-core-i7-2600k-core-i5-2500k,2833-21.html">one
on tomshardware.com</a> which lead me to the conclusion that the difference in
power consumption between the i5-2500K and the i7-2600K are negligable: In the
legionhardware review the difference is one watt when idle, so let’s assume two
watts.  For the duration of three years, that’s 10&nbsp;€ difference in your
electricity bill (I used the idle value because a computer is idle most of the
time, and even when you usually compile stuff you still have the nights where
you don’t use the computer at all). While the difference in power consumption
is small, the difference in performance is not. Therefore, I decided for the
i7-2600K.
</p>

<p>
Note that I am talking about the 2600K instead of the 2600. Why is that? One
reason is that the 2600K is (or was, at the time of buying the computer)
actually cheaper than the 2600, apparently because there is a lot more demand.
The K means that it has an unlocked multiplier and is better for overclocking.
That’s not interesting to me, but the K version also has the better on-chip
graphics, which <strong>is</strong> interesting (for an occasional game).
</p>

<p>
For the reference: When comparing CPUs, there is a handy tool on the Intel
website, with which <a
href="http://ark.intel.com/compare/52210,52213,52209,52207,52206">I compared
various CPUs</a> regarding their clock speed, cache size and feature set
(AES-NI, which is hardware acceleration for AES cryptography, which you want).
It doesn’t have the power consumption numbers I found earlier, so you
have to combine it with some research. I also cross-referenced the interesting
CPUs with <a
href="http://www.heise.de/preisvergleich/?cat=cpu1155&xf=25_4~5_AES-NI&sort=p">a
price comparison site</a>, manually.
</p>

<p>
So now that we have a CPU, we need a good motherboard for it. Intel offers a
few different chipsets in each generation, and you should read up <a
href="http://www.pugetsystems.com/blog/2011/06/09/h67-p67-and-z68-which-one-is-right-for-you/">on
the difference between the chipsets</a>. The short version is that the H67 is
the one which actually lets you use the on-chip graphics of the i7-2600K, so
that you can connect two monitors.
</p>

<p>
I picked the <a
href="http://www.intel.com/content/www/us/en/motherboards/desktop-motherboards/desktop-board-dh67gd.html">Intel
DH67GD</a> due to price and features, and then searched the web for its power
consumption and Linux support. The <a
href="http://www.avsforum.com/t/1334483/whats-your-power-consumption">overall
power consumption</a> of a system with the DH67GD and i7-2600K seems te be
around 35 to 40 watts (idle). Note that these values are different from the
ones in the benchmark above because that one had a separate graphics card in
the system! These graphics cards draw <strong>a lot</strong> of power, even
when you’re not actually using 3D acceleration.
</p>

<p>
For the Linux support I found <a
href="http://www.ruinelli.ch/sandy-bridge-cpu-and-the-hd3000-gpu-in-linux">a
blogpost about the DH67GD and a sandy bridge i5 CPU</a>, which showed that you
can use XRandR to configure the screens and it works fine out of the box
starting with Linux 2.6.38. I also found <a
href="https://bugs.freedesktop.org/show_bug.cgi?id=35462#c12">a comment in a
bugtracker about suspend/resume working fine after a BIOS upgrade with Linux
2.6.38</a>. I can confirm that it works just fine (I have been using it for 4
months, suspending/resuming at least once every day). These are the only
important things to verify, since general support for Intel chipsets in Linux
is excellent.
</p>

<h2>The RAM</h2>

<p>
When buying RAM, you usually compare the timing, clock speed (performance) and
voltage (power consumption). It turns out that the <a
href="http://www.tomshardware.com/reviews/lovo-ddr3-power,2650-2.html">voltage
difference is negligable on modern DDR3 RAMs</a> and so <a
href="http://www.tomshardware.com/reviews/core-i7-870-1156,2482-9.html">is the
timing and clock speed</a> for my use cases.
</p>

<p>
Therefore, I just settled for the biggest amount of RAM which I could afford,
which in my case was the <code>G.Skill RipJaws-X DIMM Kit 16GB PC3-10667U
CL7-7-7-21</code>. I could have chosen 24GB for a bit more money, but I rather
wait some amount of time until the price for that amount of RAM is lower and I
actually need it. I mean, you can fill any amount of memory you have, but I
won’t notice the difference between 16GB and 24GB in everyday work for some
time…
</p>

<h2>The SSD</h2>

<p>
Let me state one thing upfront: In case you are not using an SSD right now, you
absolute have to switch to one. Otherwise, the hard disk will be a huge bottle
neck for your daily computing and you won’t be able to enjoy that fast CPU.
</p>

<p>
Buying SSDs is a bit like chosing an internet provider: There are people who
have bad experiences and there are people who have good experiences with every
possible option :-). Therefore, I won’t say "SSDs from Vendor X break all the
time" nor "SSDs from Vendor Y will last for decades". Instead, I bought the SSD
with the best performance per euro in the affordable price range, which was the
<code>OCZ Vertex 3 90GB</code>, see <a
href="http://www.tomshardware.com/reviews/buy-ssd-recommendation-value,3088-6.html">tomshardware’s
SSD hierarchy chart</a>.
</p>

<h2>The power supply (PSU)</h2>

<p>
When buying power supplies you want to buy one with a high efficiency and low
noise. I can recommend the Enermax brand because of their good quality. I
previously bought a fanless PSU from Etasis (with an "emergency fan" that turns
on when it gets too hot), but it died recently (after about three years of
usage).  Since fanless ones tend to be not cooled appropriately, you have to be
careful.
</p>

<p>
However, I read <a
href="http://www.silentpcreview.com/article1062-page2.html">a review about a
new series of fanless PSUs from Seasonic</a> and the conclusion of that review
was very positive. Therefore I bought the <code>Seasonic X-Series Fanless
X-400FL</code> and I’m pretty happy with it so far. It works fine and I can’t
hear it. Time will tell how good it really is :-). I have to note that when the
room is absolutely quiet and you have suspended the computer, the PSU will emit
a quiet high-frequency sound (humming of some components probably). Since you
are hopefully not sleeping less than 1m away from your computer, this shouldn’t
bother you at all. You absolutely can’t hear it when the computer is under your
desk and in a closed case.
</p>

<p>
There is another fanless PSU with even better ratings: the Kingwin Stryker
STR-500. However, it seems like it’s only available to the US market, I
couldn’t find a single German shop where I could order it.
</p>

<h2>The CPU fan</h2>

<p>
I originally ordered a Thermalright Archon which should have fit just fine in
my case, but unfortunately, it didn’t (and it was off by about 2cm or so, not
just a few milimeters). Therefore, I cannot recommend it for this setup. Things
to look out for in general are that the fan is silent and that it leaves enough
space for your RAM (some fans don’t!).
</p>

<p>
Instead, I’ve been using the Intel fan which came with my CPU for a few weeks.
For my taste, it is clearly too load, so I looked around and bought the "Scythe
Mugen 3 Rev. B". Installing it took me about an hour, but afterwards the system
is <strong>much</strong> quieter and 5 to 10 degrees celsius cooler (in every
temperature sensor). I can confirm that the Scythe Mugen 3 Rev B fits perfectly
fine into the Fractal Design Define R3. You can even install the fan facing in
the direction of the G.Skill RipJaws-X.
</p>

<h2>Conclusion</h2>

<p>
The research on this cost me about 4 to 5 hours. That’s quite a bit, but the
result was that I got a computer which works fine with Linux out of the box and
provides all features I wanted. So, I invested a bit of time before buying
rather than ending up with non-working drivers and pain and agony after buying
:-).
</p>

<p>
Some people might argue that they don’t want to spend time or do that kind of
research before buying. Instead, they just want a few simple choices like Apple
offers (can you even call that simple anymore?) and buy one of that.
Personally, I’m fine with that, but it’s just not for me. I want to chose
exactly which hardware I use. 
</p>

<p>
The computer I was describing has been running for about 4 months by now. It’s
rock-solid and works very well out of the box with a Debian testing
installation using Linux 3.2. There’s only one minor thing which you should
be aware of: You might have tearing in X11 under certain circumstances, as
described <a href="https://bugs.freedesktop.org/show_bug.cgi?id=37686">in this
bugreport</a>. The problems seems to affect all of Sandy Bridge, so there is no
way to get around this given my requirements. It’s not <strong>that
bad</strong> (beware: subjective impression), so I’m not too sad about it.
</p>

<p>
For the people not reading the whole article, here is a list of the parts which
make up my new computer:
</p>

<ul>
<li>Intel Core i7-2600K (~ 260 €)</li>
<li>G.Skill RipJaws-X DIMM Kit 16GB PC3-10667U CL7-7-7-21 (DDR3-1333)
(F3-10666CL7Q-16GBXH) (~ 85 €)</li>
<li>Intel DH67GD (~ 80 €)</li>
<li>OCZ Vertex 3 90GB (~ 126 €)</li>
<li>Fractal Design Define R3 (86 €)</li>
<li>Seasonic X-Series Fanless X-400FL (~ 111 €)</li>
<li>Scythe Mugen 3 Rev. B (~ 40 €)</li>
</ul>

<p>
In case you’re on a tighter budget, I’d recommend to save money by chosing a
cheaper CPU. Don’t try to "save" money on the other parts, they’re well worth
their money.
</p>
