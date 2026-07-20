---
layout: post
date: 2013-07-20 14:25:00 +0200
title: "systemd 204 in Debian experimental"
categories: Artikel
tags:
- debian
---
<p>
As of today, <a href="http://packages.debian.org/experimental/systemd">systemd
204 is available in Debian experimental</a>. If you are interested in systemd,
please install it and report any issues to the BTS — merely reporting them on
IRC is not sufficient, we need to have them in the BTS so we don’t forget about
them.
</p>

<p>
In case you’ve been using the unofficial 204 packages from
http://people.debian.org/~biebl/systemd, please downgrade first to systemd
44-12 and udev 175-7.2, then upgrade to the versions in Debian experimental.
This will ensure that during the upgrade all obsolete conffiles are upgraded
properly.
</p>

<p>
Thanks for helping with testing!
</p>
