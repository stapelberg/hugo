---
layout: post
title:  "Restore-DVD mit grml Linux erstellen"
date:   2007-11-11 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Restore_DVD
---



<p>
Für eines meiner Projekte wollte ich eine Restore-DVD erstellen, damit der
Kunde mithilfe dieser DVD immer zu einem definierten (und funktionierenden)
Ausgangszustand zurückkehren kann, falls mal etwas schiefläuft.
</p>

<p>
Die Partition mit dem Betriebssystem und dem eigentlichen Programm wurde daher
extra nur mit 10 GB bemessen, damit man sie möglichst einfach sichern kann.
</p>

<p>
Als Mittel der Wahl kommt hier <a href="http://www.grml.org/" title="grml.org"
target="_blank">grml</a> zum Einsatz, kombiniert mit einem dd-image und einem
kleinen Shellscript…
</p>

<p>
Zum Erstellen der CD benötigen wir mindestens 10 GB (Größe des Backups) + 2.5
GB (Komprimiertes Backup) + 50 MB (GRML-CD) + 2.5 GB (Komprimiertes Backup in
dmcrypt eingepackt) + 2.5 GB (fertiges DVD-Image), also insgesamt rund 20 GB.
</p>

<h2>Anfertigen des Backups</h2>

<p>
Hierzu legen wir eine ganz normale grml-CD (ich habe Version 1.0 verwendet, das
spielt aber keine Rolle) ins Laufwerk und starten davon. Mithilfe von
<code>dmesg | grep "^\(hd\|sd\)"</code> finden wir die Festplatte:
</p>
<pre>hda: VMware Virtual IDE Hard Drive, ATA DISK drive
hdc: VMware Virtual IDE CDROM Drive, ATAPI CD/DVD-ROM drive
hda: max request size: 128KiB
hda: 16777216 sectors (8589 MB) w/32KiB Cache, CHS=17753/15/63, UDMA(33)
hdc: ATAPI 1X CD-ROM drive, 32kB Cache, UDMA(33)</pre>
<p>
In diesem Fall ist also /dev/hda die Festplatte (mit 8 GB Kapazität).
</p>

<p>
Wir brauchen nun noch ein Ziel für das Backup, hierfür kann man einen NFS-Mount
nehmen oder (einfacher, wenn man mit NFS noch nichts zu tun hatte) eine externe
USB-Festplatte anschließen. Bei SMB-Mounts sollte man überprüfen, ob diese eine
2GB-Dateigrenze haben, denn dann wird das Backup sehr umstädnlich.
</p>

<p>
Nun sichern wir den Bootsektor (Master Boot Record und Partition Table) und
danach die erste Partition:
</p>
<pre># cd /mnt/usbhdd
# dd if=/dev/hda of=boot.img bs=512 count=1
# dd if=/dev/hda1 of=hda1.img bs=5M</pre>

<p>
Anschließend entfernen wir die USB-Festplatte, fahren wir das System herunter
und begeben uns an eine Workstation um die GRML-CD zu remastern.
</p>


<h2>Anforderungen</h2>

<p>
Wir benötigen nun die Tools <code>mkisofs</code> und <code>mksquashfs</code>,
außerdem die Kernelmodule <code>loop</code> und <code>dmcrypt</code> sowie das
Tool <code>cryptsetup-luks</code> (siehe <a
href="/Artikel/Festplattenverschluesselung_unter_Linux"
title="Festplattenverschlüsselung unter Linux">Festplattenverschlüsselung unter
Linux</a>). Falls diese Tools/Module nicht ohnehin schon installiert sind, ist
es möglicherweise einfacher, die grml-small-CD zu installieren (in eine vmware
oder eine andere Partition), denn diese bringt alle benötigen Tools bereits mit
(und die Installation geht recht schnell, im Gegensatz zur normalen
grml-Installation).
</p>

<h2>Verschlüsseln und Komprimieren des Backups</h2>

<p>
Damit das Backup, welches zwar aus 10 GB Daten, aber nur ca 2,5 GB Nutzdaten
besteht, überhaupt auf DVD passt, komprimieren wir es mit <code>gzip</code>:
</p>
<pre># gzip -c hda1.img &gt; hda1c.img</pre>
<p>
Falls das resultierende Image zu groß werden sollte, kann man natürlich eine
stärke <code>gzip</code>-Kompression versuchen oder zum Beispiel
<code>bzip2</code> verwenden.
</p>

<p>
Damit die CD in falschen Händen keine Firmengeheimnisse preisgibt, wird das
Backup zusätzlich verschlüsselt (hierbei ist darauf zu achten, dass das
Dateisystem auch Platz wegnimmt, sodass man locker 0,1 GB zusätzlichen Platz
vorsehen sollte):
</p>
<pre># dd if=/dev/zero of=backup.dmcrypt bs=1M count=2600
# losetup /dev/loop0 backup.dmcrypt
# cryptsetup -c blowfish-cbc-essiv:sha256 -y -s 256 luksFormat /dev/loop0
# cryptsetup luksOpen /dev/loop0 backup
# mkfs.ext2 /dev/mapper/backup
# mount /dev/mapper/backup /mnt/backup
# mv hda1c.img boot.img /mnt/backup
# umount /mnt/backup
# cryptsetup luksClose backup
# losetup -d /dev/loop0</pre>

<p>
Wer mehr über die soeben angewendeten Befehle wissen möchte, sollte sich meinen
Artikel <a href="/Artikel/Festplattenverschluesselung_unter_Linux"
title="Festplattenverschlüsselung unter Linux">Festplattenverschlüsselung unter
Linux</a> zu Gemüte führen.
</p>

<h2>Remastering der GRML-CD</h2>

<p>
Als Basis dient uns die grml_small_0.4.iso (zur Zeit des Schreibens aktuell).
Sie wird erst gemountet und anschließend kopiert:
</p>
<pre># mkdir /mnt/iso
# mount -o loop grml_small_0.4.iso /mnt/iso
# mkdir ~/original
# cp -av /mnt/iso/* ~/original/
# umount /mnt/iso</pre>

<p>
Falls wir mehrere verschiedene CDs remastern wollen, ist es sinnvoll, sich
diese Daten zu kopieren, damit man nicht jedes mal die CD mounten muss.
</p>

<p>
Nun mounten wir den eigentlichen Inhalt, welcher in einem squashfs-image steckt
und kopieren diesen ebenfalls:
</p>
<pre># mount -t squashfs -o loop ~/original/GRML/GRML /mnt/iso
# mkdir ~/squashfs
# cp -av /mnt/iso/* ~/squashfs
# umount /mnt/iso</pre>

<p>
Jetzt kopieren wir unsere &Auml;nderungen in das Dateisystem und erstellen ein
neues squashfs-image, welches direkt in den Ordner mit dem CD-Inhalt
gespeichert wird:
</p>
<pre># cp restore ~/squashfs/usr/bin/restore
# echo /usr/bin/restore &gt;&gt; ~/squashfs/etc/zsh/zprofile
# cp backup.dmcrypt ~/squashfs/home/grml/
# rm ~/original/GRML/GRML
# mksquashfs ~/squashfs ~/original/GRML/GRML</pre>

<p>
<code>restore</code> ist das Script, welches später das Backup wiederherstellt,
aber dazu später mehr.
</p>

<p>
Da für alle Dateien auf der CD MD5-Summen gespeichert sind (um die CD
überprüfen zu können), müssen wir diese ebenfalls aktualisieren:
</p>
<pre># cd ~/original/GRML/GRML
# md5sum GRML
# vi md5sums</pre>
<p>
Nun muss die alte MD5-Summe mit der neuen ausgetauscht werden und die Datei
anschließend wieder gespeichert werden.
</p>

<p>
So, fast geschafft, nun wird der Inhalt der CD wieder in ein Image gepackt und
kann danach gebrannt werden:
</p>
<pre># cd
# mkisofs -pad -l -r -J -v -V "grmls 0.4restore" -no-emul-boot -boot-load-size 4 -boot-info-table \
-b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -hide-rr-moved -o grmls0.4restore.iso original</pre>

<h2>Das restore-Script</h2>
<p>
Das folgende Script mountet das verschlüsselte Backup und spielt es nach
Rückfrage auf die Festplatte auf. Sollte auf dem Rechner die Festplatte nicht
<code>/dev/hda</code> sein, so muss sie als Parameter mit angegeben werden.
</p>

<p>
Die Besonderheiten dieses Scripts sind die Fehlerprüfung, die Unterstützung der
Verschlüsselung, das Aufrufen von <code>fdisk</code> zum Erstellen der
passenden Device-Nodes nach dem Wiederherstellen der Partition Table und das
Entpacken des komprimierten Backups.
</p>

<p>
Ich gebe es unter der <a href="/BSD" title="BSD-Lizenz">BSD-Lizenz</a> heraus.
</p>

<pre>#!/bin/sh
# (c) 2007 Michael Stapelberg

if [ ! -z "${1}" ]; then
	RESTORETO=$1
else
	RESTORETO=/dev/hda
fi

clear

echo "***"
echo -e "*** \e[1mrestore-program\e[0m"
echo "*** (c) 2007 Michael Stapelberg"
echo "***"

[ ! -b $RESTORETO ] &amp;&amp; {
	echo -e "\e[1m*** Oops, $RESTORETO was not found. This was not the computer this backup was built for!"
	echo -e "\e[1m*** If you still want to restore the backup, type \"restore &lt;device&gt;\" and replace"
	echo -e "\e[1m*** &lt;device&gt; with the hard disk you want to restore to."
	exit 5
}

[ ! -d /mnt/backup ] &amp;&amp; {
	echo -e "\e[1m*** Creating mountpoint...\e[0m"
	mkdir /mnt/backup || exit 1
}

losetup /dev/loop1 1&gt;&amp;- 2&gt;&amp;- || {
	echo -e "\e[1m*** Loop-mounting backup-file...\e[0m"
	losetup /dev/loop1 /GRML/home/grml/backup.dmcrypt || exit 2
}

[ ! -b /dev/mapper/backup ] &amp;&amp; {
	echo -e "\e[1m*** Cryptmounting block-device, please enter password...\e[0m"
	cryptsetup luksOpen /dev/loop1 backup || exit 3
}

[ ! -f /mnt/backup/hda1.img ] &amp;&amp; {
	echo -e "\e[1m*** Mounting device...\e[0m"
	mount -r /dev/mapper/backup /mnt/backup || exit 4
}

echo ""
echo -e "\e[1m*** Do you REALLY want to restore the backup to this computer? Type uppercase yes if so:\e[0m"
read confirm
if [ "$confirm" = "YES" ]; then
	echo -e "\e[1m*** Restoring Master Boot Record and Partition Table (doesn't take long)...\e[0m"
	dd if=/mnt/backup/boot.img of=$RESTORETO
	echo -e "\e[1m*** Re-syncing disks using fdisk...\e[0m"
	echo w | fdisk ${RESTORETO} 2&gt;&amp;- || {
		echo "\e[1;31m*** Could not re-sync disk!"
		exit 6
	}
	echo -e "\e[1m*** Restoring Partition C: (takes long)...\e[0m"
	zcat /mnt/backup/hda1c.img &gt; ${RESTORETO}1 || {
		echo "\e[1;31m*** Could not restore backup to C:"
		exit 7
	}
	echo -e "\e[1;32m*** Done!\e[0m"
	echo -e "\e[1m*** Trying to reboot the system now. You will be asked to take the DVD and press Enter"
	echo -e "\e[1m*** It may happen that the system does not reboot after you pressed Enter."
	echo -e "\e[1m*** Just press the reboot-switch in this case or hold the power-switch for 4 seconds."
	umount /mnt/backup &amp;&amp; cryptsetup luksClose backup &amp;&amp; losetup -d /dev/loop1
	echo ""
	echo -e "\e[1m*** Press enter now to reboot"
	read confirm
	reboot
fi</pre>

<h2>Fertig!</h2>
<p>
Das war’s auch schon. Nach einem gründlichen Test geben wir dem Kunden die
fertige DVD und sind gewappnet für die nächste Hands-On-Session, wenn das
System eine Macke haben sollte… :-)
</p>
