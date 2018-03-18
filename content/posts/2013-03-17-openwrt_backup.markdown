---
layout: post
title:  "OpenWrt: Backup/Restore"
date:   2013-03-17 22:42:00
categories: Artikel
Aliases:
  - /Artikel/openwrt_backup
---


<p>
<a href="https://openwrt.org/">OpenWrt</a> is a nice FOSS Linux firmware
(primarily) for wireless routers, which I use for many years. Even though I
never experienced a problem with my routers, I’d like to be prepared for
hardware failures, software failures and getting my router compromised. Here is
a short description of each scenario so that it is clear what I mean:
</p>
<ul>
<li>
<strong>Hardware failure</strong>: The flash in my router dies and after
rebooting, neither the read-only part nor my configuration can be read, so the
device does not work anymore. The only solution is to buy a new router, or have
a hot spare ready. This is the worst case.
</li>

<li>
<strong>Software failure</strong>: After my network provider’s intern decides
to fuzz the customer IP range instead of their testbed, he discovers an
implementation flaw in the router’s PPPoE software and subsequently, the router
deletes all the read/write data (i.e. my configuration). The solution is to
reformat the read/write part of the flash and restore the latest backup. This
story covers not only software failure, but also human failure when upgrading
the router firmware.
</li>

<li>
<strong>Compromised router</strong>: Some software has a security vulnerability
and an attacker obtains access to the router. Since a backdoor might have been
installed, I need to re-flash the firmware image and restore my configuration.
</li>
</ul>

<p>
All of these points imply having a backup. But did you actually verify that
your OpenWrt backup works? What’s your disaster recovery plan for each of the
scenarios above?
</p>

<h2>Backing up</h2>

<p>
OpenWrt ships with a feature to provide a tar archive containing all your
configuration files. You can find it in LUCI’s “System → Backup” tab.
Obviously, you need to repeat this step after every configuration change you
do.
</p>

<p>
If you have installed any additional packages, you also need to save the list
of packages:
</p>
<pre>
opkg list_installed | cut -f 1 -d ' '
</pre>

<p>
If you have installed any services that ship an init script (e.g. OpenVPN), you
also need to keep a note of which ones are enabled/disabled in LUCI’s “System →
Startup” tab.
</p>

<h2>Restoring</h2>

<p>
The correct order in which to restore your router to a working state is this:
</p>

<ol>
<li>
Flash your firmware image (save the original one whenever you flashing, or at
least note which precise version you used).
</li>

<li>
Configure your router so that it can access the internet.
</li>

<li>
Re-install your packages:
<pre>
opkg update && for i in $(cat /tmp/pkgs); do opkg install $i; done
</pre>
</li>

<li>
Restore your configuration by uploading the tar archive in LUCI’s “System →
Backup” tab.
</li>

<li>
Re-enable any services you have installed (e.g. OpenVPN) in LUCI’s “System →
Startup” tab, because that information is not contained in the tar archive.
</li>
</ol>

<h2>Restoring to a different device</h2>

<p>
In case you have a different router, for example because a hardware failure
occured or because you want to setup that hot spare I have been talking about,
you need to watch out for one little subtlety in the process:
</p>

<p>
The MAC addresses of the radio interfaces need to be replaced before restoring
the backup. Otherwise, OpenWrt will not apply your wireless configuration to
the interfaces it finds.
</p>

<p>
In order to do that, simply edit the relevant file with a text editor and
re-pack the tarball:
</p>

<pre>
mkdir /tmp/fix && cd /tmp/fix
tar xf ~/Downloads/backup-OpenWrt-2013-03-13.tar.gz
vi etc/config/wireless
tar czf ~/Downloads/backup-OpenWrt-2013-03-13-fixed.tar.gz *
</pre>

<h2>Building your own firmware image</h2>

<p>
In case you are dissatisfied with the dependency on the internet in step 3 of
the restore procedure, you could build your own firmware image which contains
the extra packages that you use. I don’t want to describe that process in
depth, but it seems worth pointing out that this is one way to go.
</p>

<p>
Alternatively, you could also keep a copy of the extra packages, scp them to
the router and install them with opkg. Depending on your number of extra
packages, one of these will clearly seem easier :-).
</p>
