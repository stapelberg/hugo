---
layout: post
date: 2011-06-13 19:13:00 +01:00
title: "adb als non-root unter Debian"
---
<p>
Um via <tt>adb</tt> mit seinem Android-Gerät sprechen zu können, habe ich
bisher den adb-Server immer als root starten müssen. Daran konnte auch die
udev-Regel von android.com nichts ändern.
</p>

<p>
Da mir das nun aber auf die Nerven ging, habe ich das Problem debugged. Als
Test habe ich hierbei den Befehl <tt>adb devices</tt> verwendet, es sind aber
alle Befehle gleichermaßen betroffen.
</p>

<p>
<a href="http://developer.android.com/guide/developing/device.html">Die
Anleitung auf android.com</a> beschreibt, dass man eine Datei
<tt>/etc/udev/rules.d/51-android.rules</tt> anlegen soll, mit folgendem Inhalt:
</p>

<pre>
SUBSYSTEM=="usb_device", SYSFS{idVendor}=="0bb4", MODE="0666"
</pre>

<p>
Hieran stören mehrere Punkte:
</p>
<ol>
<li>
Die MODE-Direktive funktioniert nicht auf meinem System (Debian testing),
ich weiß nicht genau warum. Stattdessen hat man bei Debian aber eine Gruppe
namens <tt>plugdev</tt>, die man für diesen Zweck verwenden kann.
</li>
<li>
Der Zugriff auf Attribute via SYSFS{} ist deprecated, stattdessen sollte man
ATTR{} verwenden.
</li>
<li>
Auf android.com wird erklärt, dass das subsystem auf manchen Systemen usb und
auf manchen usb_device heißt. Das kann man mittels
<tt>SUBSYSTEM=="usb|usb_device"</tt> bereits in der Regel erschlagen.
</li>
</ol>

<p>
Meine udev-Regel sieht also folgendermaßen aus:
</p>

<pre>
SUBSYSTEM=="usb|usb_device",ATTR{idVendor}=="0bb4",MODE="0666",GROUP="plugdev"
</pre>

<p>
Das resultiert beim Anstecken des Telefons dann in folgendem Device Node:
</p>

<pre>
crw-rw-r-- 1 root plugdev 189, 144 2011-06-13 19:13 017
</pre>

<p>
…wodurch ein <tt>adb devices</tt> fortan auch als non-root klappt :).
</p>
