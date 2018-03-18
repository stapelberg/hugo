---
layout: post
title:  "Kurze Info: Wintec WBT300 GPS unter Linux"
date:   2008-09-17 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Info_WBT300_Linux
---


<p>
Hier eine kurze Info, dass der WBT300 GPS problemlos unter Linux funktioniert.
Im Inneren steckt ein Antaris 4, der auch als u-blox 0625 bekannt ist.
</p>

<p>
Erhältlich ist der WBT300 zum Beispiel bei <a
href="http://www.pdamax.de/">www.pdamax.de</a> für 69 €.
</p>

<h2>USB</h2>

<p>
Nach dem Anstecken via USB meldet sich der Empfänger in dmesg:
</p>

<pre>
usb 6-1: new full speed USB device using uhci_hcd and address 2
usb 6-1: configuration #1 chosen from 1 choice
cdc_acm 6-1:1.0: ttyACM0: USB ACM device
usbcore: registered new interface driver cdc_acm
cdc_acm: v0.26:USB Abstract Control Model driver for USB modems and ISDN adapters
</pre>

<p>
Echtes Plug und Play eben. Unter Windows braucht man dafür einen Treiber :-).
</p>

<p>
<strong>UPDATE:</strong> Da war ich wohl etwas zu sehr geprägt von der
Bluetooth-Methode. Die hotplug-Scripts funktionieren natürlich auch ohne dass
man sie manuell aufruft. Also: WBT300 einschalten und alles läuft. Höchstens
xgps muss man noch per Hand starten ;-). Der Vollständigkeit halber und zum
Debuggen lasse ich die beiden Scripts aber noch hier stehen:
</p>

<p>
Mit folgendem simplen Script aktiviere ich gpsd und lasse mir die GPS-Daten in
xgps anzeigen:
</p>

<pre>
#!/bin/sh
sudo gpsd -F /var/run/gpsd.sock
sudo /lib/udev/gpsd.hotplug add /dev/ttyACM0
xgps &
</pre>

<p>
Ebenso kann man ihn natürlich auch wieder deaktivieren:
</p>

<pre>
#!/bin/sh
sudo killall gpsd
killall xgps
</pre>

<h2>Bluetooth</h2>

<p>
Via Bluetooth wird die Sache natürlich etwas komplizierter, allerdings braucht
man dafür kein lästiges Kabel und kann zum Beispiel das Notebook im Rucksack
verstauen oder den GPS-Empfänger am Autodach befestigen. Ich empfehle aber
dringend, vor längeren Mappingtouren zu testen, ob das mit dem Bluetooth
wirklich gut klappt (bei mir hat er anfangs gelegentlich einen kurzen
Aussetzer, woraufhin man Bluetooth neu aktivieren muss), bevor man am Ende
umsonst durch die Gegend gefahren ist ;-).
</p>

<pre>
#!/bin/sh
# Folgende Zeile ist nur bei Thinkpads notwendig:
sudo sh -c "echo enable > /proc/acpi/ibm/bluetooth"
sudo /etc/init.d/bluetooth start
# Hier die Bluetooth-Adresse deines Geräts einsetzen, du findest sie via hcitool scan:
sudo rfcomm bind 0 00:01:22:33:44:55
sudo gpsd -F /var/run/gpsd.sock
sudo /lib/udev/gpsd.hotplug add /dev/rfcomm0
xgps &
</pre>

<p>
Ebenso das deaktivieren:
</p>

<pre>
#!/bin/sh
sudo rfcomm release 0
sudo /etc/init.d/bluetooth stop
sudo killall gpsd
sudo sh -c "echo disable > /proc/acpi/ibm/bluetooth"
</pre>

<h2>Screenshot</h2>

<p>Mit vergleichsweise schlechtem, aber ausreichendem Empfang in der Wohnung (am Fensterbrett):</p>
<img src="/Bilder/wbt300_xgps.png" alt="Wintec WBT300 in xgps" width="536" height="788">

<h2>Weitere Links</h2>

<ul>
<li><a href="http://www.insidepda.de/gps-empfaenger,Wintec-G-Rays-I-WBT300,testbericht,198.html">http://www.insidepda.de/gps-empfaenger,Wintec-G-Rays-I-WBT300,testbericht,198.html</a></li>
<li><a href="http://www.karomue.homepage.t-online.de/nav/WBT300.pdf">http://www.karomue.homepage.t-online.de/nav/WBT300.pdf</a></li>
</ul>
