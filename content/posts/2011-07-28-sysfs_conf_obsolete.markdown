---
layout: post
title:  "/etc/sysfs.conf ist obsolet"
date:   2011-07-28 17:10:00
categories: Artikel
Aliases:
  - /Artikel/sysfs_conf_obsolete
---



<p>
Unter Linux kann man einige Treiber-Einstellungen über <a
href="http://en.wikipedia.org/wiki/Sysfs"><code>sysfs</code></a>, ein vom Kernel
bereitgestelltes Pseudo-Dateisystem, erledigen. Auf meinem ThinkPad kann ich
darüber beispielsweise einstellen, wie schnell mein Trackpoint reagieren soll
oder ab welchem Füllstand mein Akku geladen werden soll (damit er nicht gleich
wieder einen Ladezyklus anfängt, wenn ich ihn 5 Minuten nicht am Strom habe).
</p>

<p>
Diese Einstellungen nimmt man zur Laufzeit z.B. folgendermaßen vor:
</p>
<pre>
# echo 75 > /sys/devices/platform/smapi/BAT0/start_charge_thresh
</pre>

<p>
Nach einem Neustart sind sie natürlich verloren, denn der Kernel hält sie nur
im Speicher. Daher gibt es unter Debian das Paket <code>sysfsutils</code>, welches
die Möglichkeit bot, diese Einstellungen in <code>/etc/sysfs.conf</code> zu
konfigurieren. Beim Systemstart wurden diese über ein Init-Script dann nach
<code>/sys</code> übertragen.
</p>

<h2>Probleme</h2>

<p>
Mit diesem Ansatz stimmen mehrere Sachen nicht:
</p>
<ul>

<li>
Die Einstellungen werden an einem „beliebigen“ Zeitpunkt beim Systemstart
gesetzt, nämlich dann, wenn das Initscript an der Reihe ist. Für die oben
genannte Batterie-Einstellung ist das möglicherweise schon zu spät, das heißt,
der Ladezyklus wurde bereits angefangen.
</li>

<li>
Dadurch, dass es ein Script ist, verzögert es den Systemstart mit
<a href="http://en.wikipedia.org/wiki/Systemd"><code>systemd</code></a> (welcher
ansonsten keine Shellscripts mehr benutzt). Die Verzögerung ist zwar minimal,
aber es geht ums Prinzip… :-)
</li>

<li>
Der Mechanismus ist distributions-spezifisch, was schlecht ist. Generell gibt
es auf allen Linux-Distributionen <code>/sys</code> und es ist unnötig, mehrere
verschiedene Mechanismen zu haben.
</li>

<li>
Der wichtigste Punkt ist aber, dass die Einstellungen nicht greifen, wenn man
neue Geräte anschließt oder angeschlossene Geräte entfernt und wieder
anschließt. Das ist bei USB-Geräten beispielsweise relativ üblich, kann aber
auch mit Akkus passieren (ich habe zwei).
</li>

</ul>

<h2>Die Lösung: udev-Regeln</h2>

<p>
Besser wäre es also, die Einstellungen dann zu setzen, wenn das Gerät
tatsächlich im System auftaucht – und was könnte dafür besser geeignet sein als
<a href="http://en.wikipedia.org/wiki/Udev"><code>udev</code></a>?
</p>

<p>
Nehmen wir also das Beispiel von oben, mit der Akku-Einstellung. Zunächst
suchen wir uns das passende udev-Gerät. Dazu fangen wir mit dem Pfad an, unter
dem die entsprechende sysfs-Datei liegt:
</p>
<pre>
# udevadm info -p /sys/devices/platform/smapi/BAT0 -a
device path not found                                         
</pre>

<p>
Das hat nicht geklappt, also probieren wir es eine Ebene höher. Es gilt die
Faustregel: Jeder Ordner, der eine <code>uevent</code>-Datei enthält, repräsentiert
ein Gerät.
</p>

<pre>
# udevadm info -p /sys/devices/platform/smapi/ -a     
  looking at device '/devices/platform/smapi':
    KERNEL=="smapi"
    SUBSYSTEM=="platform"
    DRIVER=="smapi"
    ATTR{ac_connected}=="1"

  looking at parent device '/devices/platform':
    KERNELS=="platform"
    SUBSYSTEMS==""
    DRIVERS==""
</pre>

<p>
Hierbei werden alle Attribute angezeigt, die man in einer udev-Regel matchen
kann. Hierbei werden also <strong>nicht</strong> alle Attribute angezeigt, es
fehlen diejenigen, die man nur beschreiben kann.
</p>

<p>
Wir legen nun die Datei <code>/etc/udev/rules.d/11-battery.rules</code> mit folgendem Inhalt an:
</p>
<pre>
# start charging as soon as the battery is below 75% capacity
ACTION!="remove",SUBSYSTEM=="platform",DRIVER=="smapi", \
ATTR{BAT0/start_charge_thresh}="75"
</pre>

<p>
Das bedeutet, dass für den smapi-Treiber bei allen Aktionen außer dem Entfernen
die Einstellung <code>BAT0/start_charge_thresh</code> auf <code>75</code> gesetzt wird.
</p>

<p>
Wir testen diese Regel nun folgendermaßen:
</p>

<pre>
# udevadm test /sys/devices/platform/smapi

udev_rules_new: rules use 216324 bytes tokens (18027 * 12 bytes), 28809 bytes buffer
udev_rules_new: temporary index used 52580 bytes (2629 * 20 bytes)
udev_device_new_from_syspath: device 0x7f4c810df170 has devpath '/devices/platform/smapi'
udev_device_new_from_syspath: device 0x7f4c810eebe0 has devpath '/devices/platform/smapi'
udev_device_read_db: no db file to read /run/udev/data/+platform:smapi: No such file or directory
udev_rules_apply_to_event: ATTR '/sys/devices/platform/smapi/BAT0/start_charge_thresh'
writing '75' /etc/udev/rules.d/11-battery.rules:6
udev_device_new_from_syspath: device 0x7f4c810ec4e0 has devpath '/devices/platform'
udev_rules_apply_to_event: RUN 'socket:@/org/freedesktop/hal/udev_event' /lib/udev/rules.d/90-hal.rules:2
</pre>

<p>
Dabei achten wir auf die Zeile, die mit <code>udev_rules_apply_to_event:
ATTR</code> beginnt: Sie zeigt uns an, dass unsere Regel wohlgeformt ist und die
Einstellung gesetzt wurde. Anschließend kann man mit <code>cat
/sys/devices/platform/smapi/BAT0/start_charge_thresh</code> nochmal nachschauen
und wird feststellen, dass der Wert korrekt gesetzt wurde.
</p>

<p>
Nun deinstalliert man <code>sysfsutils</code> und freut sich über einen schnelleren
Systemstart ;-).
</p>

<h2>Meine udev-Regeln</h2>

<pre>
$ cat /etc/udev/rules.d/10-trackpoint.rules
ACTION!="remove",SUBSYSTEM=="serio",DRIVER=="psmouse",ATTR{sensitivity}="150",ATTR{speed}="150"

$ cat /etc/udev/rules.d/11-battery.rules   
# start charging as soon as the battery is below 75% capacity
# wait 2 minutes before charging to make battery changes easy

ACTION!="remove",SUBSYSTEM=="platform",DRIVER=="smapi", \
ATTR{BAT0/start_charge_thresh}="75", \
ATTR{BAT0/inhibit_charge_minutes}="2"
</pre>
