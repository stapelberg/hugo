---
layout: post
date: 2013-07-13 23:42:17 +0200
title: "Survey answers part 3: systemd is not portable and what this means for our ports"
categories: Artikel
tags:
- debian
---
<p>
This blog post is the third of a series of posts dealing with the results of <a
href="http://people.debian.org/~stapelberg//2013/05/27/systemd-survey-results.html">the
Debian systemd survey</a>. I intend to give a presentation at DebConf 2013,
too, so you could either read my posts, or watch the talk, or both :-).
</p>

<p>
The second-biggest concern in the survey results was that systemd is not
portable to non-Linux systems, for example Debian GNU/kFreeBSD or Debian
GNU/HURD. For convenience, I will from now on write “kFreeBSD” when I really
mean all non-Linux ports.
</p>

<h3>systemd not being portable is not an arbitrary decision</h3>

<p>
Some people seem to think that the systemd upstream is just hostile to users of
other operating systems when they hear that systemd is not portable. However,
keep in mind that Lennart, Kay and other contributors have considerable
experience with writing portable software such as <a
href="http://en.wikipedia.org/wiki/Avahi_(software)">Avahi</a> and <a
href="http://en.wikipedia.org/wiki/PulseAudio">PulseAudio</a>.
</p>

<p>
The decision to only support Linux in systemd was thus not taken lightly.
systemd’s design requires many kernel features and certain semantics (e.g.
<code>procfs</code> is not enough, <code>/proc/$PID/exe</code> needs to be
supported), which are currently only available on Linux. Point 15 of Lennart’s
blog post <a
href="http://0pointer.de/blog/projects/the-biggest-myths.html">0pointer.de/blog/projects/the-biggest-myths.html</a>
contains an incomplete list of these features.
</p>

<h3>Maintaining portable code increases complexity</h3>

<p>
Since systemd is written in C, the canonical way to write portable code is by
using conditional compilation, for example with <a
href="http://en.wikipedia.org/wiki/C_preprocessor#Conditional_compilation">ifdef
statements</a>. That makes the code harder to understand and reason about, but
more importantly it blows up the <a
href="http://en.wikipedia.org/wiki/Traceability_matrix">test matrix</a>. It
also requires any new change to be tested on all supported systems, which is
not feasible for most contributors. I think everybody agrees keeping complexity
low is a good thing.
</p>

<h3>What are the implications for our non-Linux ports?</h3>

<p>
We, the Debian project, have two realistic options in my point of view:
</p>
<ol>
<li>We stay with sysvinit, the least common denominator, forever.</li>
<li>We use a modern init system such as systemd on Debian GNU/Linux.</li>
</ol>

<p>
In case we go with the first option, Debian will diverge more and more from
virtually every other Linux distribution. This also means we are stuck with the
limited features and capabilities that sysvinit has. A modern operating system
needs to be able to adapt to a changing environment and the once static world
in which sysvinit was developed has become much more dynamic.
</p>

<p>
In our opinion, the only reasonable choice is the latter option: use systemd on
Debian GNU/Linux.
</p>

<p>
How will this work?
</p>

<ul>
<li>
In the short-term future, maintainers add systemd support to their packages.
This does not imply dropping sysvinit support. As outlined <a
href="http://people.debian.org/~stapelberg//2013/07/01/systemd-transition.html">in
my post about the transition</a>, systemd service files can coexist with
sysvinit scripts.
</li>

<li>
In the mid-term future, both sysvinit and systemd are supported — this is the
only way we can do a gradual transition, and Debian clearly does not want a
flag day.
</li>

<li>
In the long term, we could switch the default from sysvinit to systemd on
Debian GNU/Linux, in case we agree that’s a reasonable decision at that time.
Non-Linux ports will still use sysvinit.
</li>
</ul>

<p>
For individual maintainers, this means they need to support two init systems.
Luckily, systemd service files are usually really simple, but there still is
additional maintenance work such as testing whether your service actually
starts when using systemd. We think this maintenance overhead is justified due
to the advantages a modern init system brings. Of course, not every maintainer
can arrange it to install systemd and test his/her package. You are invited to
contact us at pkg-systemd-maintainers@lists.alioth.debian.org at any time and
we can help you out.
</p>

<p>
Furthermore, automation can be introduced (and we have a proof of concept) to
make it easier to spot mistakes and perform some simple tests, such as whether
the service can be started.
</p>

<p>
A concern that was voiced is that as sysvinit usage decreases, the init scripts
would bit-rot and stop working at some point. If that happens, we rely on the
users to file appropriate bug reports. This is no different from the situation
today — it is not feasible for maintainers to test every single combination of
features all the time.
</p>

<h3>Ports are different and that diversity is good</h3>

<p>
The FreeBSD kernel and the Linux kernel are different, and each kernel provides
distinct features that the other kernel does not have. As an example, Linux
provides cgroups, which are heavily used by systemd. The FreeBSD kernel in turn
offers the packet filter “pf”, which is not available on Linux. There certainly
is value in having common infrastructure. But there also is value in providing
the best features that each platform has to offer — in case of Linux, that is
clearly systemd as an init system IMO.
</p>

<h3>Conclusion</h3>

<p>
systemd is not portable because it relies on features only the Linux kernel
provides — an example is cgroups, which systemd uses to track processes in a
reliable way. Not embracing these features and staying with sysvinit
indefinitely is not a viable option if Debian wants to remain relevant for
today’s demands. In the short term, the migration to systemd will cause
additional maintenance effort for individual package maintainers, but it will
pay off in the long term.
</p>
