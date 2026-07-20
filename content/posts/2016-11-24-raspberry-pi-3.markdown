---
layout: post
date: 2016-11-24 09:45:00 +0200
title: "Debian stretch on the Raspberry Pi 3"
categories: Artikel
tags:
- debian
---
<p>
The last couple of days, I worked on getting Debian to run on the Raspberry Pi
3.
</p>

<p>
Thanks to the work of many talented people, the Linux kernel in version 4.8 is
_almost_ ready to run on the Raspberry Pi 3. The only missing thing is the
bcm2835 MMC driver, which is required to read the root file system from the SD
card. I’ve asked our maintainers to <a
href="https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=845422">include the
patch</a> for the time being.
</p>

<p>
Aside from the kernel, one also needs a working bootloader, hence I used
Ubuntu’s linux-firmware-raspi2 package and uploaded the <a
href="https://anonscm.debian.org/cgit/pkg-raspi/linux-firmware-raspi3.git/">linux-firmware-raspi3
package</a> to Debian. The package is currently in the NEW queue and needs to
be accepted by ftp-master before entering Debian.
</p>

<p>
The most popular method of providing a Linux distribution for the Raspberry Pi
is to provide an image that can be written to an SD card. I made two little
changes to vmdebootstrap (<a
href="https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=845439">#845439</a>, <a
href="https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=845526">#845526</a>)
which make it easier to create such an image.
</p>

<p>
The Debian wiki page <a
href="https://wiki.debian.org/RaspberryPi3">https://wiki.debian.org/RaspberryPi3</a>
describes the current state of affairs and should be updated, as this blog post
will not be updated.
</p>

<p>
As a <strong>preview version</strong> (i.e. unofficial, unsupported, etc.)
until all the necessary bits and pieces are in place to build images in a
proper place in Debian, I built and uploaded the resulting image. Find it at <a
href="https://people.debian.org/~stapelberg/raspberrypi3/">https://people.debian.org/~stapelberg/raspberrypi3/</a>.
To install the image, insert the SD card into your computer (I’m assuming it’s
available as <code>/dev/sdb</code>) and copy the image onto it:
</p>

<pre>
$ wget https://people.debian.org/~stapelberg/raspberrypi3/2016-11-24-raspberry-pi-3-stretch-PREVIEW.img
$ sudo dd if=2016-11-24-raspberry-pi-3-stretch-PREVIEW.img of=/dev/sdb bs=5M
</pre>

<p>
I hope this initial work on getting Debian booted will motivate other people to
contribute little improvements here and there. A list of current limitations
and potential improvements can be found on the <a
href="https://wiki.debian.org/RaspberryPi3">RaspberryPi3 Debian wiki page</a>.
</p>
