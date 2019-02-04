---
layout: post
date: 2018-03-19 08:00:00 +0100
title: "sbuild-debian-developer-setup(1)"
categories: Artikel
tags:
- debian
---
<p>
  I have heard a number of times that sbuild is too hard to get started with,
  and hence people don’t use it.
</p>

<p>
  To reduce hurdles from using/contributing to Debian, I wanted to make sbuild
  easier to set up.
</p>

<p>
  sbuild ≥ 0.74.0 provides a Debian package
  called <a href="https://packages.debian.org/sid/sbuild-debian-developer-setup">sbuild-debian-developer-setup</a>. Once
  installed, run
  the <a href="https://manpages.debian.org/unstable/sbuild/sbuild-debian-developer-setup.1">sbuild-debian-developer-setup(1)</a>
  command to create a chroot suitable for building packages for Debian unstable.
</p>

<p>
  On a system without any sbuild/schroot bits installed, a transcript of the
  full setup looks like this:
</p>

<pre>
% sudo apt install -t unstable sbuild-debian-developer-setup
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following additional packages will be installed:
  libsbuild-perl sbuild schroot
Suggested packages:
  deborphan btrfs-tools aufs-tools | unionfs-fuse qemu-user-static
Recommended packages:
  exim4 | mail-transport-agent autopkgtest
The following NEW packages will be installed:
  libsbuild-perl sbuild sbuild-debian-developer-setup schroot
0 upgraded, 4 newly installed, 0 to remove and 1454 not upgraded.
Need to get 1.106 kB of archives.
After this operation, 3.556 kB of additional disk space will be used.
Do you want to continue? [Y/n]
Get:1 http://localhost:3142/deb.debian.org/debian unstable/main amd64 libsbuild-perl all 0.74.0-1 [129 kB]
Get:2 http://localhost:3142/deb.debian.org/debian unstable/main amd64 sbuild all 0.74.0-1 [142 kB]
Get:3 http://localhost:3142/deb.debian.org/debian testing/main amd64 schroot amd64 1.6.10-4 [772 kB]
Get:4 http://localhost:3142/deb.debian.org/debian unstable/main amd64 sbuild-debian-developer-setup all 0.74.0-1 [62,6 kB]
Fetched 1.106 kB in 0s (5.036 kB/s)
Selecting previously unselected package libsbuild-perl.
(Reading database ... 276684 files and directories currently installed.)
Preparing to unpack .../libsbuild-perl_0.74.0-1_all.deb ...
Unpacking libsbuild-perl (0.74.0-1) ...
Selecting previously unselected package sbuild.
Preparing to unpack .../sbuild_0.74.0-1_all.deb ...
Unpacking sbuild (0.74.0-1) ...
Selecting previously unselected package schroot.
Preparing to unpack .../schroot_1.6.10-4_amd64.deb ...
Unpacking schroot (1.6.10-4) ...
Selecting previously unselected package sbuild-debian-developer-setup.
Preparing to unpack .../sbuild-debian-developer-setup_0.74.0-1_all.deb ...
Unpacking sbuild-debian-developer-setup (0.74.0-1) ...
Processing triggers for systemd (236-1) ...
Setting up schroot (1.6.10-4) ...
Created symlink /etc/systemd/system/multi-user.target.wants/schroot.service → /lib/systemd/system/schroot.service.
Setting up libsbuild-perl (0.74.0-1) ...
Processing triggers for man-db (2.7.6.1-2) ...
Setting up sbuild (0.74.0-1) ...
Setting up sbuild-debian-developer-setup (0.74.0-1) ...
Processing triggers for systemd (236-1) ...

% sudo sbuild-debian-developer-setup
The user `michael' is already a member of `sbuild'.
I: SUITE: unstable
I: TARGET: /srv/chroot/unstable-amd64-sbuild
I: MIRROR: http://localhost:3142/deb.debian.org/debian
I: Running debootstrap --arch=amd64 --variant=buildd --verbose --include=fakeroot,build-essential,eatmydata --components=main --resolve-deps unstable /srv/chroot/unstable-amd64-sbuild http://localhost:3142/deb.debian.org/debian
I: Retrieving InRelease 
I: Checking Release signature
I: Valid Release signature (key id 126C0D24BD8A2942CC7DF8AC7638D0442B90D010)
I: Retrieving Packages 
I: Validating Packages 
I: Found packages in base already in required: apt 
I: Resolving dependencies of required packages...
[…]
I: Successfully set up unstable chroot.
I: Run "sbuild-adduser" to add new sbuild users.
ln -s /usr/share/doc/sbuild/examples/sbuild-update-all /etc/cron.daily/sbuild-debian-developer-setup-update-all
Now run `newgrp sbuild', or log out and log in again.

% newgrp sbuild

% sbuild -d unstable hello
sbuild (Debian sbuild) 0.74.0 (14 Mar 2018) on x1

+==============================================================================+
| hello (amd64)                                Mon, 19 Mar 2018 07:46:14 +0000 |
+==============================================================================+

Package: hello
Distribution: unstable
Machine Architecture: amd64
Host Architecture: amd64
Build Architecture: amd64
Build Type: binary
[…]
</pre>

<p>
  I hope you’ll find this useful.
</p>
