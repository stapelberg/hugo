---
layout: post
date: 2018-01-08 22:55:00 +0100
title: "Debian buster on the Raspberry Pi 3 (update)"
categories: Artikel
tags:
- debian
---
<p>
I previously wrote about <a
href="https://people.debian.org/~stapelberg/2017/10/08/raspberry-pi-3.html">my
Debian buster preview image for the Raspberry Pi 3</a>.
</p>

<p>
Now, I’m publishing an updated version, containing the following changes:
</p>
<ul>
<li>
WiFi works out of the box. Use e.g. <code>ip link set dev wlan0 up</code>, and <code>iwlist wlan0 scan</code>.
</li>
<li>
Kernel boot messages are now displayed on an attached monitor (if any), not just on the serial console.
</li>
<li>
Root file system resizing will now not touch the partition table if the user modified it.
</li>
<li>
The image is now compressed using xz, reducing its size to 170M.
</li>
</ul>

<p>
As before, the image is built
with <a href="https://github.com/larswirzenius/vmdb2">vmdb2</a>, the successor
to vmdebootstrap. The input files are available
at <a href="https://github.com/Debian/raspi3-image-spec">https://github.com/Debian/raspi3-image-spec</a>.
</p>

<p>
Note that Bluetooth is still untested
(see <a href="https://wiki.debian.org/RaspberryPi3">wiki:RaspberryPi3</a> for
details).
</p>

<p>
Given that Bluetooth is the only known issue, I’d like to work towards getting
this image built and provided on official Debian infrastructure. If you know how
to make this happen, please send me an email. Thanks!
</p>

<p>
As a <strong>preview version</strong> (i.e. unofficial, unsupported, etc.)
until that’s done, I built and uploaded the resulting image. Find it at <a
href="https://people.debian.org/~stapelberg/raspberrypi3/2018-01-08/">https://people.debian.org/~stapelberg/raspberrypi3/2018-01-08/</a>.
To install the image, insert the SD card into your computer (I’m assuming it’s
available as <code>/dev/sdb</code>) and copy the image onto it:
</p>

<pre>
$ wget https://people.debian.org/~stapelberg/raspberrypi3/2018-01-08/2018-01-08-raspberry-pi-3-buster-PREVIEW.img.xz
$ xzcat 2018-01-08-raspberry-pi-3-buster-PREVIEW.img.xz | dd of=/dev/sdb bs=64k oflag=dsync status=progress
</pre>

<p>
If resolving client-supplied DHCP hostnames works in your network, you should
be able to log into the Raspberry Pi 3 using SSH after booting it:
</p>

<pre>
$ ssh root@rpi3
# Password is “raspberry”
</pre>
