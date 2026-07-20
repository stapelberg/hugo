---
layout: post
date: 2013-07-14 19:19:19 +0200
title: "Systemd support in Debian packages: how to help"
categories: Artikel
tags:
- debian
---
<p>
Sometimes, people show up in our IRC channel #debian-systemd or on our mailing
list pkg-systemd-maintainers@lists.alioth.debian.org and ask how they can help. 
This blog post answers that question.
</p>

<p>
<strong>First of all, whatever you end up doing, please coordinate with us
first!</strong> Saying hi in our IRC channel or on our mailing list and
explaining what you intend to do is all we ask for. In the past, people have
filed bug reports with service files that are not idiomatic, and we really need
to avoid that.
</p>

<p>
Currently, our biggest task is to add/improve systemd support to individual
Debian packages, and this is where we can use a lot of help.
</p>

<p>
We have <a href="http://people.debian.org/~stapelberg/dashboard/">a dashboard</a> which contains two lists:
</p>
<ol>
<li>
Packages that ship a service file, but don’t use dh-systemd yet.<br>
These need to be updated to get proper maintscripts (e.g. deb-systemd-helper
enable/disable calls, possibly start/stop/restart calls).
</li>
<li>
Packages that ship an init script but no service file yet.<br>
These need a service file plus dh-systemd support.
</li>
</ol>

<h3>Adding a service file and dh-systemd support</h3>

<p>
After you picked a service from the second list in <a
href="http://people.debian.org/~stapelberg/dashboard/">our dashboard</a>, first
double-check that there is no bug filed against it yet (the dashboard might be
a few hours behind).
</p>

<p>
Then, search for a service file, either upstream or in other distributions such
as Arch Linux, Fedora, Gentoo, etc. In case there is no service file yet, write
one. Please carefully test the service file (e.g. does
starting/stopping/restarting and reloading work) and send it to us for review.
</p>

<p>
Be careful to avoid obvious regressions from the sysvinit init script. That is,
don’t just write a very simplistic service file that breaks a use-case which
formerly worked. If in doubt, ask pkg-systemd-maintainers or chose a different
package to work on.
</p>

<p>
Afterwards, add systemd support by using the dh-systemd helper, see
<a
href="https://wiki.debian.org/Systemd/Packaging">https://wiki.debian.org/Systemd/Packaging</a>.
</p>

<p>
The last step is to file a proper bug report against the package that uses our
usertag and CCs pkg-systemd-maintainers. See <a
href="http://bugs.debian.org/714190">http://bugs.debian.org/714190</a> for an
example.
</p>

<h3>Replacing custom maintscripts with dh-systemd</h3>

<p>
Check if the package currently has any direct systemctl calls in its
maintscripts and remove them if so (see <a
href="http://bugs.debian.org/713853">http://bugs.debian.org/713853</a> for an
example).
</p>

<p>
Follow <a
href="https://wiki.debian.org/Systemd/Packaging">https://wiki.debian.org/Systemd/Packaging</a>
to add systemd support using the dh-systemd helper.
</p>

<p>
Check whether the maintscripts look good and generate a debdiff to highlight
the differences between the old and the new version:
</p>
<pre>
debdiff --controlfiles=ALL OLD_amd64.changes NEW_amd64.changes
</pre>

<p>
Then file a bug report which uses our usertag and CCs pkg-systemd-maintainers.
See <a href="http://bugs.debian.org/713853">http://bugs.debian.org/713853</a>
for an example.
</p>

<h3>Thanks!</h3>

<p>
Thank you for helping us and Debian in general!
</p>
