---
layout: post
date: 2017-10-08 22:45:00 +0200
title: "Debian stretch on the Raspberry Pi 3 (update)"
categories: Artikel
tags:
- debian
---
<p>
I previously wrote about <a
href="https://people.debian.org/~stapelberg/2017/03/22/raspberry-pi-3.html">my
Debian stretch preview image for the Raspberry Pi 3</a>.
</p>

<p>
Now, I’m publishing an updated version, containing the following changes:
</p>
<ul>
<li>
SSH host keys are generated on first boot.
</li>
<li>
Old kernel versions are now removed from /boot/firmware when purged.
</li>
<li>
The image is built
with <a href="https://github.com/larswirzenius/vmdb2">vmdb2</a>, the successor
to vmdebootstrap. The input files are available
at <a href="https://github.com/Debian/raspi3-image-spec">https://github.com/Debian/raspi3-image-spec</a>.
</li>
<li>
The image uses the linux-image-arm64 4.13.4-3 kernel, which provides HDMI output.
</li>
<li>
The image is now compressed using bzip2, reducing its size to 220M.
</li>
</ul>

<p>
A couple of issues remain, notably the lack of WiFi and bluetooth support
(see <a
href="https://wiki.debian.org/RaspberryPi3">wiki:RaspberryPi3</a> for details.
Any help with fixing these issues is very welcome!
</p>

<p>
As a <strong>preview version</strong> (i.e. unofficial, unsupported, etc.)
until all the necessary bits and pieces are in place to build images in a
proper place in Debian, I built and uploaded the resulting image. Find it at <a
href="https://people.debian.org/~stapelberg/raspberrypi3/2017-10-08/">https://people.debian.org/~stapelberg/raspberrypi3/2017-10-08/</a>.
To install the image, insert the SD card into your computer (I’m assuming it’s
available as <code>/dev/sdb</code>) and copy the image onto it:
</p>

<pre>
$ wget https://people.debian.org/~stapelberg/raspberrypi3/2017-10-08/2017-10-08-raspberry-pi-3-buster-PREVIEW.img.bz2
$ bunzip2 2017-10-08-raspberry-pi-3-buster-PREVIEW.img.bz2
$ sudo dd if=2017-10-08-raspberry-pi-3-buster-PREVIEW.img of=/dev/sdb bs=5M
</pre>

<p>
If resolving client-supplied DHCP hostnames works in your network, you should
be able to log into the Raspberry Pi 3 using SSH after booting it:
</p>

<pre>
$ ssh root@rpi3
# Password is “raspberry”
</pre>
