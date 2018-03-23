---
layout: post
date: 2012-09-24 15:54:00 +02:00
title: "lvm-snapshots: fixing lvremove"
---
<p>
On an up-to-date Debian testing system, lvremove fails sporadically when
removing snapshots. The cause is not yet fully debugged, see <a
href="http://bugs.debian.org/549691">Debian bug 549691</a>. The symptom looks
like this:
</p>

<pre>
$ lvremove -f plana/snap_web
  Unable to deactivate open plana-domu--web-real (253:3)
  Failed to resume domu-web.
</pre>

<p>
To work around this, use the following commands (works reliably, tested for a
few days):
</p>

<pre>
$ dmsetup remove /dev/mapper/plana-snap_web
$ dmsetup remove /dev/mapper/plana-snap_web-cow
$ lvremove -f plana/snap_web
</pre>

<p>
Since they only remove the snapshot-mappings, this does not touch the data on
the original LV at all.
</p>
