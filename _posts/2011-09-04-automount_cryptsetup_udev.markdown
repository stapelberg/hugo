---
layout: post
title:  "Automount von LUKS-verschlüsselten Festplatten"
date:   2011-09-04 22:22:22
categories: Artikel
---


<p>
In <a href="/Artikel/Festplattenverschluesselung_unter_Linux">meinem Artikel
über Festplattenverschlüsselung unter Linux</a> habe ich unter anderem erklärt,
wie man eine komplette Partition verschlüsselt. Nun möchte ich ergänzen, wie
man eine externe Festplatte automatisch mountet, sobald man sie einsteckt.
</p>

<h2>Voraussetzung: Einzelne Partition ist verschlüsselt</h2>

<p>
Ich gehe davon aus, dass auf der Festplatte eine Partition Table existiert mit
genau einer Partition, welche via dmcrypt+LUKS verschlüsselt wurde. Die Ausgabe
von <code>fdisk -l /dev/sdb</code> sollte also folgendermaßen aussehen:
</p>

<pre>
# fdisk -l /dev/sdb
Disk /dev/sdb: 1000.2 GB, 1000202043392 bytes
248 heads, 55 sectors/track, 143219 cylinders, total 1953519616 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00021631

Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048  1953519615   976758784   83  Linux
</pre>

<h2>Voraussetzung: Keyfile kann zum Entschlüsseln benutzt werden</h2>

<p>
Weiterhin muss natürlich eine Schlüsseldatei vorhanden sein, welche die
Partition entschlüsseln kann, sonst kann man die Festplatte natürlich nicht
vollautomatisch mounten (sondern müsste eine Passphrase eingeben).
</p>

<p>
Eine solche Datei kann man folgendermaßen anlegen und zu einer bestehenden
dmcrypt+LUKS-Partition hinzufügen:
</p>

<pre>
$ mkdir keyfiles; cd keyfiles
$ dd if=/dev/urandom of=backup-hdd bs=256 count=1
# cryptsetup luksAddKey /dev/sdc1 ~/keyfiles/backup-hdd
</pre>

<h2>Eintrag in /etc/fstab</h2>

<p>
Damit die udev-Regel aus dem nächsten Kapitel weiß, wohin sie die Festplatte
mounten soll, legen wir einen entsprechenden Eintrag in der <code>/etc/fstab</code>
an:
</p>

<pre>
/dev/mapper/backup-crypt /mnt/backup		ext4	defaults,user,users	0	0
</pre>

<h2>Seriennummer herausfinden</h2>

<p>
Um später die Festplatte eindeutig identifizieren zu können, brauchen wir die
Seriennummer des Geräts. Wenn sie eingesteckt ist, kriegen wir sie mit dem
folgenden Befehl heraus:
</p>

<pre>
$ udevadm info -a -p $(udevadm info -q path -n /dev/sdb) | grep serial
    ATTRS{serial}=="66623425ABCDEF"
    ATTRS{serial}=="0000:00:1a.7"
</pre>

<p>
Der erste Wert ist hierbei die Seriennummer (der zweite ein interner Pfad zum
Gerät).
</p>

<h2>udev-Regel</h2>

<p>
Nun muss man dem System begreiflich machen, dass er zwei Sachen erledigen soll:
</p>

<ol>
<li>Beim Einstecken der USB-Festplatte soll er via <code>cryptsetup</code> die Partition entschlüsseln</li>
<li>Sobald <code>cryptsetup</code> fertig ist, soll die Partition gemountet werden</li>
</ol>

<p>
Das erledigt folgende udev-Regel, die man in
<code>/etc/udev/rules.d/85-usb-backup-hdd.rules</code> ablegt:
</p>

<pre>
$ cat /etc/udev/rules.d/85-usb-backup-hdd.rules 

##################################################################################
# rule 1: decrypt the disk once it gets plugged in
##################################################################################

# matches partitions (there is precisely one) of block devices with the serial
# number of my backup external hard disk

ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ATTRS{serial}=="<strong>66623425ABCDEF</strong>", \
RUN+="/sbin/cryptsetup --key-file <strong>/home/michael/keyfiles/backup-hdd</strong> luksOpen $env{DEVNAME} <strong>backup-crypt</strong>"

##################################################################################
# rule 2: as soon as the crypt container is opened, mount the filesystem inside it
##################################################################################

# we (also) match on change because the device name is known only after some time
ACTION=="add|change", SUBSYSTEM=="block", ENV{DM_NAME}=="<strong>backup-crypt</strong>", \
RUN+="/bin/mount /dev/mapper/$env{DM_NAME}"
</pre>

<p>
Die fettgedruckten Stellen sind diejenigen, die ggf. ersetzt werden müssen. Die
erste mit der Seriennummer der Festplatte, die wir zuvor herausgefunden haben.
Die zweite mit dem Ort zum LUKS-keyfile und die letzten beiden mit dem Namen,
unter dem die Partition entschlüsselt werden soll.
</p>

<h2>Einstecken testen</h2>

<p>
Das war’s schon (zumindest fürs automatische mounten). Ohne neuladen oder
neustarten von irgendeinem Dienst sollte jetzt, sobald die Festplatte
eingesteckt wird, automatisch die Partition gemountet werden. Mithilfe des
Befehls <code>udevadm monitor --property</code> kann man sich die Events, die der
Linux-Kernel bzw. udev gerade erzeugen, anzeigen lassen.
</p>

<h2>Umounten</h2>

<p>
Bevor man die Festplatte nun abziehen kann, muss man sie natürlich umounten.
Anschließend müsste man dann noch via <code>cryptsetup luksClose</code> die
Entschlüsselung wieder schließen, aber das kann man sich auch wegoptimieren
:-).
</p>

<p>
Ich habe dazu ein kleines Script geschrieben, welches ein Wrapper für umount
ist. Das Script prüft, ob das gemountete Gerät in <code>/dev/mapper/</code> liegt
und ruft nach dem eigentlich umount gleich ein passendes <code>cryptsetup
luksClose</code> auf. Weiterhin zeigt es, während der umount läuft, an, wieviele
Bytes noch auf die Platte(n) geschrieben werden müssen (man kann hier leider
nur den Wert für alle Platten anzeigen).
</p>

<p>
Nachdem man sich <a href="/umount.pl">das umount-wrapper-script
heruntergeladen</a> hat, legt man es einfach nach <code>~/.bin/umount</code> und
fügt <code>~/.bin</code> ganz vorn in den <code>PATH</code> ein.
</p>
