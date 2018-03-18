---
layout: post
title:  "Rescue-HDD mit grml Linux"
date:   2012-03-01 18:15:00
categories: Artikel
Aliases:
  - /Artikel/rescue_hdd
---


<p>
Vor einiger Zeit <a href="/Artikel/Restore_DVD">habe ich einen Artikel
veröffentlicht</a>, wie man eine DVD zum Wiederherstellen des Systems in einen
definierten Zustand erstellt. Dieser Artikel ist ein Folgeartikel, der nahezu
dasselbe macht, aber auf Basis einer USB-Festplatte statt einer DVD, und mit
einer neueren Version von grml Linux.
</p>

<p>
Die Idee hinter der Sache ist, dass der Anwender ohne Linux-Kenntnisse ein
1:1-Abbild der Festplatte wiederherstellen kann. Die Lösung, dafür Linux zu
nehmen, liegt nahe, wenn man ein wenig mit Windows-Backup-Lösungen zu tun
hatte… :-). Argumente für Linux sind hier, dass es gut funktioniert und zudem
noch kostenfrei verfügbar ist. Wenn ich hier ein Image mache, weiß ich, dass es
wirklich ein 1:1-Abbild ist, und nicht das, was irgendeine spezifische
Backup-Software darunter versteht…
</p>

<h2>Schritt 1: USB-Festplatte mit grml bespielen</h2>

<p>
Ich habe den zu sichernden Rechner mit einem grml-USB-Stick gestartet und die
externe USB-Festplatte angeschlossen. In meinem Fall ist die externe Festplatte
/dev/sdb. Das sollte natürlich genau verifiziert werden, sonst überschreibt man
sich evtl. die falsche Festplatte :-).
</p>

<p>
Zunächst legt man eine Partitionstabelle an, die folgendermaßen aussieht:
<ul>
<li>2 GB FAT16 für grml</li>
<li>1 GB ext2 für Konfigurationsdateien, Scripte und Pakete</li>
<li>den Rest der Festplatte für Daten</li>
</ul>
</p>

<pre>
Disk /dev/sdb: 1000.2 GB, 1000202043392 bytes
16 heads, 32 sectors/track, 3815468 cylinders, total 1953519616 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0xbac99eef

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1   *        2048     4098047     2048000    6  FAT16
/dev/sdb2         4098048     6146047     1024000   83  Linux
/dev/sdb3         6146048  1953519615   973686784   83  Linux
</pre>

<p>
Anschließend erstellt man die Dateisysteme (das Label GRMLCFG ist nötig, damit
grml von dieser Datei die Konfigurationsdateien lädt):
</p>

<pre>
$ mkfs.vfat -F 16 -n "grmlboot" /dev/sdb1
$ mkfs.ext3 -L "GRMLCFG" /dev/sdb2
$ mkfs.ext3 -L "4n6data" /dev/sdb3
</pre>

<p>
Danach installiert man grml auf der externen Festplatte und konfiguriert, dass
ein Script namens startup.sh gestartet werden soll:
</p>

<pre>
$ grml2usb --bootoptions="startup=startup.sh" /live/image /dev/sdb1
</pre>

<h2>Schritt 2: Image erstellen</h2>

<p>
Nun sichert man ein 1:1-Abbild der kompletten Festplatte. Ich benutze hierzu
<code>dd_rescue</code>, weil auf der Festplatte ein Sektor unlesbar war. Im
Fall einer gesunden Festplatte langt natürlich auch <code>dd</code>, aber
lieber gleich auf Nummer sicher gehen.
</p>

<p>
Ich speichere dieses Image komprimiert, weil die Festplatte größtenteils nicht
benutzt ist. Man kann hier natürlich mehr herausholen, wenn man zuvor das
Dateisystem defragmentiert und danach mit Nullen füllt. Außerdem komprimiert
<code>bzip2</code> besser als <code>gzip</code> (im Fall von vielen Nullen),
nutzt aber auch mehr Rechenzeit.
</p>

<pre>
$ cd /mnt/4n6data
$ apt-get update
$ apt-get install ddrescue
$ dd_rescue /dev/sda - | gzip -c > rechner-1.2012-03-01.img.gz
</pre>

<p>
Der Vorgang dauert je nach Größe und Geschwindigkeit der internen sowie
externen Festplatte einige Zeit. In meinem Fall dauerte es etwas mehr als 3
Stunden für 250 GiB von einer Western Digital <code>WD2502ABYS-01B7A0</code>
auf eine <code>WD Elements 1042</code>.
</p>

<h2>Schritt 3: Script zur Wiederherstellung einbauen</h2>

<p>
grml lädt alle Dateien aus dem Archiv <code>config.tbz</code> auf der
GRMLCFG-Partition. Damit grml das Script findet, stecken wir es also nach
usr/bin:
</p>

<pre>
$ mount /mnt/GRMLCFG
$ cd /mnt/GRMLCFG
$ mkdir -p config/usr/bin
$ cd config
$ cat &lt;&lt;&lt;EOF &gt;&gt;usr/bin/startup.sh
#!/bin/sh
echo "Mounting data partition..."
mount /mnt/4n6data
echo "Running restore.sh..."
restore.sh
EOF
$ cat &lt;&lt;&lt;EOF &gt;&gt;usr/bin/restore.sh
#!/usr/bin/zsh
# restores data
# (c) 2012-03-01 Michael Stapelberg

# find destination hard disk
NUMDISKS=$(ls /dev/disk/by-id/scsi-SATA* | grep -v 'part[0-9]$' | wc -l)
if [ $NUMDISKS -ne 1 ]; then
	echo "ERROR: More than one internal hard disk found."
	echo "Please disconnect all hard disk drives except for the one to restore on."
	echo "Please connect the image drive via USB."
	read
	exit 1
fi

DISK=$(ls /dev/disk/by-id/scsi-SATA* | grep -v 'part[0-9]$')
echo "INFO: Restoring to $DISK"

echo "Which image do you want to restore?"
imgnum=""
while [ -z "$imgnum" ]; do
	set -A IMAGES
	IMAGES=($(ls /mnt/4n6data/*.gz))
	for ((c=1; c <= $#IMAGES; c++)) do
		echo "    $c) $(basename ${IMAGES[$c]} .img.gz)"
	done
	echo -n "Enter image number: "
	read imgnum
	echo ""
done

IMGPATH=$IMAGES[$imgnum]

if [[ -z "$IMGPATH" || ! -f "$IMGPATH" ]]; then
	echo "ERROR: You did not enter a valid image number."
	exit 1
fi

# We suppress warnings because of Perl locale problems.
TOTALBYTES=$(fdisk -l $DISK | perl -nlE '/^Disk .* ([0-9]+) bytes$/ && say $1' 2>/dev/null)
echo "INFO: Restoring to a disk with $TOTALBYTES bytes"
echo "INFO: Selected image $IMGPATH"
gunzip -c $IMGPATH | pv -s $TOTALBYTES > $DISK
EOF
$ tar cvjf ../config.tbz .
</pre>

<h2>Schritt 4: Restore testen</h2>

<p>
Als letzten Schritt muss man natürlich die Wiederherstellung testen, damit man
sich sicher sein kann, keinen Fehler gemacht zu haben :-).
</p>

<p>
Dazu startet man einfach von der Festplatte und wählt im restore-script
(welches automatisch gestartet wird) das passende Image aus.
</p>
