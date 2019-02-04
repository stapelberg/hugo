---
layout: post
date: 2012-10-14 19:32:00 +0200
title: "My recent systemd activity"
categories: Artikel
tags:
- debian
---
<p>
I recently worked on the following systemd-related issues:
</p>

<ul>

<li>
<a href="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=686115">#686115 - CanReload is set to yes unconditionally for legacy SysV services</a><br>
I wrote a patch which uses a heuristic to figure out whether a SysV init script
supports the reload option or not. Not perfect, but a whole lot better than
defaulting to "yes" :-). This should also fix <a
href="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=650382">#650382 -
force-reload translated to reload for SysV services</a>.
</li>

<li>
<a href="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=688635">#688635 - Don’t kill libvirt VMs when restarting libvirt</a><br>
I ported a patch from the Fedora systemd packaging which avoids killing all
processes of a cgroup when restarting a service. This is necessary for
libvirtd, otherwise all virtual machines get killed when you restart
libvirt-bin.service. libvirt-bin 0.10.2-4 (experimental) ships systemd service
files.
</li>

<li>
<a href="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=635777">#635777 - 90-seconds delay on reboot/shutdown when postfix is installed</a><br>
I tracked down the cause of several 90-second delay on shutdown causes and
provided a patch (which is a workaround…).
</li>

<li>
<a href="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=624599">#624599 - systemd: DHCP hook scripts calling invoke-rc.d causes boot hang</a><br>
I tracked down the cause of a deadlock at boot time when dhcp hooks call
invoke-rc.d (as does samba). Several workarounds are known but we have not yet
taken any action.
</li>

</ul>
