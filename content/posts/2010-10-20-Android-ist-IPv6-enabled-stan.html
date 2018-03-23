---
permalink: /post/31
layout: post
date: 2010-10-20 23:13:46 +02:00
title: "
Android ist IPv6-enabled stan…"
---
<p>
Android ist IPv6-enabled standardmäßig. Was man braucht, um das zu verifizieren
und eventuell die Einstellungen zu ändern, ist Busybox:
<a href="http://zedomax.com/android/busybox.zip">http://zedomax.com/android/busybox.zip</a>
(von <a href="http://zedomax.com/blog/2010/07/07/android-hack-how-to-install-busybox-on-your-android/">diesem Blogpost</a>)
</p>

<p>
Die Installation ging bei mir einfacher als im mitgelieferten Script:
</p>

<pre>
x200 $ unzip busybox.zip
x200 $ adb push busybox /sdcard/busybox
x200 $ adb shell
$ su
# mount -o remount,rw /dev/block/mtdblock6 /system
# mv /sdcard/busybox /system/xbin/busybox
# cd /system/xbin
# chmod 755 busybox
# ./busybox --install -s /system/xbin
# mount -o remount,ro /dev/block/mtdblock6 /system
</pre>

<p>
Vermutlich arbeitet das Script vergleichsweise umständlich, weil ältere
Android-Versionen kein <code>cp</code> hatten. Zu beachten ist, dass die Nummer
des MTD-devices je nach Firmware unterschiedlich sein kann.
</p>

<p>
Nun kann man verifizieren, dass man eine IPv6-Adresse hat:
</p>

<pre>
# ip -6 a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
15: tiwlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qlen 100
    inet6 2001:xxxx:yyyy:zzzz:a6ed:4eff:fef8:eedd/64 scope global dynamic 
       valid_lft 86399sec preferred_lft 14399sec
    inet6 fe80::a6ed:4eff:fef8:f2dd/64 scope link 
       valid_lft forever preferred_lft forever
</pre>

