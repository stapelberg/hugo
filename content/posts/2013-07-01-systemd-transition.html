---
layout: post
date: 2013-07-01 20:00:00 +0200
title: "Survey answers part 2: the transition"
categories: Artikel
tags:
- debian
---
<p>
This blog post is the second of a series of posts dealing with the results of <a
href="http://people.debian.org/~stapelberg//2013/05/27/systemd-survey-results.html">the
Debian systemd survey</a>. I intend to give a presentation at DebConf 2013,
too, so you could either read my posts, or watch the talk, or both :-).
</p>

<p>
It seems that it is unclear how Debian’s transition to systemd is intended to
work. By “transition”, we mean going from the current state (sysvinit is the
default and fully supported) to <i>systemd is fully supported</i>. Then by
merely installing systemd by default and letting it provide
<code>/sbin/init</code>, we can make it the default init system. If and when
that happens is a different matter and it’s not necessary for all packages to
have systemd support.
</p>

<h3>sysvinit compatibility</h3>

<p>
systemd natively supports sysvinit scripts, meaning your existing package will work as-is — but you cannot utilize all the features that systemd provides. The sysvinit support works very well, as you can try in a fresh Debian wheezy VM. In the output of “systemctl list-units”, every entry which has an “LSB: ” prefix is actually a sysvinit script.
</p>

<p>
The mechanism with which systemd decides whether to use an init script or a
service file is by looking whether a service file with a corresponding name
exists. That is, if e.g. <code>apache2.service</code> exists, systemd will
prefer it over <code>/etc/init.d/apache2</code>.
</p>

<p>
To make this crystal clear: it is not necessary to ship service files for all
services in some kind of <a
href="http://en.wikipedia.org/wiki/Flag_day_%28software%29">flag day</a>.
systemd supports a “mixed” installation where some services use init scripts
and some services use service files.
</p>

<h3>Adding systemd support to your package</h3>

<p>
In a nutshell, it usually works like this:
</p>

<ol>
<li>
Install a service file to <code>/lib/systemd/system/foo.service</code>.<br>
Often, upstream already provides and installs a <code>.service</code> file.<br>
If not, you can place your file at <code>debian/package.service</code><br>
Make sure that your service file name corresponds to the sysvinit script name<br>
(e.g. <code>apache2.service</code> for <code>/etc/init.d/apache2</code>)
</li>

<li>
Ensure your service file(s) are enabled and started.<br>
We strongly recommend you to use our package dh-systemd.<br>
If you use <a href="http://joeyh.name/blog/entry/cdbs_killer___40__design_phase__41__/">dh(1)</a>, add <code>--with=systemd</code> in <code>debian/rules</code> and Build-Dep on dh-systemd
</li>

<li>
Test your package, see the next section.
</li>
</ol>

<p>
For details see <a href="http://wiki.debian.org/Systemd/Packaging">wiki.debian.org/Systemd/Packaging</a>.
</p>

<h3>Testing systemd</h3>

<p>
We carefully made sure that you can install the systemd Debian package on your
machine alongside sysvinit without breaking anything. The systemd package does
not conflict with any other packages, it will not replace
<code>/sbin/init</code> and systemd will not be enabled right away. It is only
after you specify the kernel parameter <code>init=/bin/systemd</code> in
<code>/etc/default/grub</code> that you switch to systemd. In case you want to
go back, simply boot without this kernel parameter.
</p>

<h3>Conclusion</h3>

<p>
In conclusion, the transition is straight-forward and the necessary
infrastructure is in place. systemd is available in Debian and can be used
today. Packages can add systemd support whenever their maintainer(s) feel like
it. There is no need for a <a
href="http://en.wikipedia.org/wiki/Flag_day_%28software%29">flag day</a>. We
can switch the default whenever we think we are ready.
</p>
