---
layout: post
title:  "Festplattenverschlüsselung unter Linux"
date:   2008-04-03 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Festplattenverschluesselung_unter_Linux
---

{{< note >}}

Linux/UNIX-kenntnisse erforderlich! (in den Bereichen Dateisystem, Konsole)

{{< /note >}}

<p>
Vorab: Ja, ich weiß, dass es schon genügend Anleitungen zu dem Thema gibt, aber
ich möchte es sicherheitshalber noch mal mit allen Hürden, vor die ich gestellt
wurde, aufschreiben.
</p>

## 1) Das System vorbereiten

### 1.1) Module

<p>
Zum Verschlüsseln brauchen wir die Module (oder die fest einkompilierte
Kernelunterstützung) <code>dm_crypt</code>, <code>loop</code>,
<code>blowfish</code> (oder das entsprechende Modul des Ciphers deiner Wahl)
und <code>sha256</code> (oder das entsprechende Modul des Hash-Algorithmus
deiner Wahl).
</p>

<p>
Diese Module werden bei den meisten aktuellen Linux-distributionen
mitgeliefert, sind aber meist nicht aktiviert. Ob die Module geladen sind,
sieht man in der Ausgabe von <code>lsmod</code>. Die fest einkompilierte
Unterstützung sieht man in <code>cat /proc/crypto</code>. Ein Modul lädt man
mit <code>modprobe dm_crypt</code> (beziehungsweise mit dem entsprechenden
Namen des Moduls natürlich.
</p>

<p>
Der typische Ablauf sieht also so aus:
</p>
<pre># modprobe dm_crypt
# modprobe loop
# lsmod | egrep "(^dm_crypt|^loop)"
loop                   17288  4 
dm_crypt               12424  1 </pre>

<p>
Wenn man jedoch seinen eigenen Kernel kompiliert hat und dabei die erwähnten
Module außer Acht gelassen hat, kann man dies nachholen, indem man entweder im
Menü von „make menuconfig” die Module auswählt, oder die Einstellungen direkt
in der Datei <code>.config</code> bearbeiten.
</p>

<p>
Dazu wechselt man in das Verzeichnis <code>/usr/src/linux</code> und öffnet die
Datei <code>.config</code> mit einem Texteditor. Nun sucht man die folgenden
Einstellungen:
</p>
<ul>
	<li>CONFIG_DM_CRYPT</li>
	<li>CONFIG_CRYPTO_SHA256</li>
	<li>CONFIG_CRYPTO_BLOWFISH</li>
	<li>CONFIG_BLK_DEV_LOOP</li>
</ul>
<p>
Sollte bei einem der Einträge ein „=y” dahinterstehen, ist er im Kernel fix
einkompiliert. Ist er auskommentiert (durch ein Raute-Zeichen am Anfang der
Zeile), ist er deaktiviert. Um ihn als Modul zu kompilieren, löscht man nun das
Raute-Zeichen am Anfang der Zeile und fügt ein „=m” ans Ende der Zeile an.
</p>
<p>
Durch ein <code>make modules</code> kann man diese Module nun kompilieren
lassen.
</p>
<p>
Anschließend müssen die Module noch an den richtigen Platz gebracht werden.
Hierzu benötigen wir die momentan verwendete Kernelversion, die man mit einem
<code>uname -r</code> angezeigt bekommt. Der Pfad zu den Kernelmodulen setzt
sich aus <code>/lib/modules/</code> und der Kernelversion zusammen, bie mir
wäre das momentan <code>/lib/modules/2.6.15-25-386/</code>.
</p>

<p>
Das Modul <code>dm_crypt</code> muss in den Modulordner
<code>kernel/drivers/md/</code>, <code>loop</code> nach
<code>kernel/drivers/block/</code> und die Hash- und Cipher-Module müssen in
<code>kernel/drivers/crypto/</code>:
</p>
<pre># cp drivers/md/dm_crypt.ko /lib/modules/2.6.15-25-386/kernel/drivers/md/
# cp drivers/block/loop.ko /lib/modules/2.6.15-25-386/kernel/drivers/block/
# cp crypto/*.ko /lib/modules/2.6.15-25-386/kernel/crypto</pre>

<p>
Nun müssen wir noch <code>depmod</code> ausführen, damit dem System die neuen
Module bekannt werden und die Abhängigkeiten generiert werden.
</p>

<p>
Jetzt laden wir die neuen Module mit <code>modprobe dm_crypt loop sha256
blowfish</code>. Falls das geklappt hat, lassen wir die Module beim nächsten
Start automatisch laden, indem wir sie in der Datei <code>/etc/modules</code>
verewigen. Dies kann man mit einem Texteditor oder mit dem Befehl <code>echo -e
"dm_crypt\nloop\nsha256\nblowfish" &gt;&gt; /etc/modules</code> erledigen. (Die
\n stehen für einen Zeilenumbruch, damit wir nur einen statt vier Befehle
verwenden müssen.)
</p>

### 1.2) Hilfsprogramme

<p>
Da das direkte Aufrufen von <code>dm_crypt</code> ein bisschen kompliziert ist,
hat der Autor ein Programm namens „cryptsetup” geschrieben, welches den Zugriff
vereinfacht.
</p>
<p>
Außerdem gibt es das <a href="http://code.google.com/p/cryptsetup/"
title="Linux Unified Key Setup"><code>Linux Unified Key Setup</code></a>, kurz
LUKS, welches zum einen die Möglichkeit bietet, bis zu 8 Passwörter für ein und
die selbe Partiton/Container festzulegen, und zum anderen alle nötigen
Informationen im Header der selbigen speichert und damit einen Transport der
Daten auf ein anderes System möglich macht.
</p>
<p>
Bei den aktuellen Debian-Versionen oder Versionen von debianbasierten
Distributionen wie zum Beispiel Ubuntu ist entweder das Paket
<code>cryptsetup-luks</code> dabei, oder es heißt nur noch
<code>cryptsetup</code> und enthält trotzdem (siehe <code>apt-cache show
cryptsetup</code>) die LUKS-Erweiterung.
</p>
<p>
Dieses Paket muss für diese Anleitung installiert sein.
</p>

## 2.) Komplette Partition verschlüsseln

<p>
Ich gehe in diesem Beispiel davon aus, dass die zu verschlüsselnde Partition
<code>/dev/hda2</code> heißt.
</p>

<p>
Damit eine eventulle kryptografische Analyse später so schwer wie möglich wird,
beschreiben wir zuerst die komplette Festplatte mit Zufallswerten. Das geht am
einfachsten mit dem Programm <code>wipe</code>: <code>wipe -qk
/dev/hda2</code>. Dadurch wird es schwieriger, für die Analyse relevante Daten
zu finden.
</p>

<p>
Anschließend erstellen wir mit folgendem Befehl das loopdevice:
</p>
<pre>cryptsetup -c blowfish-cbc-essiv:sha256 -y -s 256 luksFormat /dev/hda2</pre>
<p>
Wichtig ist hierbei die Angabe des essiv-Modus, der zwar erst ab Kernel 2.6.10
unterstützt wird, aber nicht – wie seine Alternative plain – gegen <a
href="http://de.wikipedia.org/wiki/Wasserzeichenangriff" title="Wikipedia:
Watermark-Attacke" target="_blank">Watermark-Attacken</a> anfällig ist.
</p>

<p>
Cryptsetup fordert uns nun auf, in Großbuchstaben YES einzutippen und fragt uns
anschließend nach einer Passphrase:
</p>
<pre>
WARNING!
========
Daten auf /dev/hda2 werden unwiderruflich überschrieben.

Are you sure? (Type uppercase yes): YES
Enter LUKS passphrase:
Verify passphrase:</pre>

<p>
Nun hat LUKS uns einen entsprechenden (durch die eben angegebene Option
<code>-s 256</code> 256-Bit großen Schlüssel erzeugt) Schlüssel geschrieben und
den Header auf die Partition geschrieben.
</p>

<p>
Mit dem Befehl <code>cryptsetup luksOpen /dev/hda2 daten</code> öffnen wir die
Partition nun mit dem Namen „daten” (der Name wird nur für den Devicemapper
verwendet). Diesen Schritt müssen wir auch in Zukunft ausführen (ob manuell
oder über ein Startscript bleibt jedem selbst überlassen), wenn wir an die
Daten wollen.
</p>

<p>
Nach Eingabe der richtigen Passphrase sagt uns <code>cryptsetup</code>, dass
alles in Ordnung ist:
</p>
<pre># cryptsetup luksOpen /dev/hda2 daten
Enter LUKS passphrase:
key slot 0 unlocked.
Command successful.</pre>

<p>
Nun steht uns das loopdevice <code>/dev/mapper/daten</code> zur Verfügung, das
wir wie eine ganz normale Festplatte verwenden können. Wir erzeugen uns also
mit <code>mkfs.ext3 /dev/mapper/daten</code> ein Dateisystem, erstellen einen
Mountpoint mit <code>mkdir /mnt/daten</code> und hängen die Festplatte dann mit
<code>mount /dev/mapper/daten /mnt/daten</code> dort ein:
</p>


```
# mkfs.ext3 /dev/mapper/daten
mke2fs 1.39 (29-May-2006)
Dateisystem-Label=
OS-Typ: Linux
Blockgröße=4096 (log=2)
Fragmentgröße=4096 (log=2)
23199744 Inodes, 46397471 Blöcke
2319873 Blöcke (5.00%) reserviert für den Superuser
erster Datenblock=0
Maximum filesystem blocks=50331648
1416 Blockgruppen
32768 Blöcke pro Gruppe, 32768 Fragmente pro Gruppe
16384 Inodes pro Gruppe
Superblock-Sicherungskopien gespeichert in den Blöcken:
32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
4096000, 7962624, 11239424, 20480000, 23887872

Schreibe Inode-Tabellen: erledigt
Erstelle Journal (32768 Blöcke): erledigt
Schreibe Superblöcke und Dateisystem-Accountinginformationen: erledigt

Das Dateisystem wird automatisch alle 27 Mounts bzw. alle 180 Tage überprüft,
je nachdem, was zuerst eintritt. Veränderbar mit tune2fs -c oder -t .

# mkdir /mnt/daten
# mount /dev/mapper/daten /mnt/daten
```

### 2.1) Die Partition wieder aushängen

<p>
Mit folgenden Befehlen hängt man die verschlüsselte Partition wieder aus dem
Dateisystem aus und entfernt das Loopdevice:
</p>

```
# umount /mnt/daten
# cryptsetup luksClose daten
 ```

## 3.) Einen verschlüsselten Container erstellen

<p>
Ein verschlüsselter Container hat verschiedene Vorteile gegenüber einer
komplett verschlüsselten Partition. Zum einen kann man dadurch die
Verschlüsselung nur für bestimmte Systembenutzer aktivieren, ohne dass man
gleich für jeden Benutzer eine eigene Festplatte einbauen muss. Außerdem kann
man den Container auf andere Systeme transportieren, oder natürlich auch – wenn
er klein genug ist – auf CD-ROM sichern.
</p>

<p>
Ein Container ist lediglich eine Datei, die dann über ein Loopdevice eingehängt
wird, also genau wie vorhin…
</p>

<p>
Mit folgendem Befehl schreiben wir uns eine 5GB große Datei, in der wir private
Daten wie Bilder und Dokumente ablegen könnten:
</p>

<pre># dd if=/dev/urandom of=/home/michael/privat.crypt bs=1024 count=5242880
5242880+0 records in
5242880+0 records out</pre>

<p>
In die Datei werden also Zufallswerte aus <code>/dev/urandom</code> gelesen,
davon 5242880 * 1024 Stück, also 5GB. In der Beispielausgabe fehlt eine Zeile,
in der <code>dd</code> angibt, wieviel Bytes das nun waren und wielange das
gedauert hat (Ich habe bei mir das System mit anderen Werten aufgesetzt…).
</p>

<p>
Vor diese Datei klemmen wir nun das Loopdevice <code>/dev/loop0</code> (0-9
stehen zur Verfügung):
</p>
<pre># losetup /dev/loop0 /home/michael/privat.crypt</pre>
<p>
Und schließlich verschlüsseln wir sie wie in Abschnitt 2:
</p>

```
# cryptsetup -c blowfish-cbc-essiv:sha256 -y -s 256 luksFormat /dev/loop0

WARNING!
========
Daten auf /dev/loop0 werden unwiderruflich überschrieben.

Are you sure? (Type uppercase yes): YES
Enter LUKS passphrase:
Verify passphrase:
Command successful.
# cryptsetup luksOpen /dev/loop0 privat
Enter LUKS passphrase:
key slot 0 unlocked.
Command successful.
# mkfs.ext3 /dev/mapper/privat
# mkdir /home/michael/privat/
# mount /dev/mapper/privat /home/michael/privat
```

## 4.) Swapspace verschlüsseln

<p>
Hierfür müssen die Module wie unter Abschnitt erwähnt automatisch geladen werden.
</p>
<p>
Die Verschlüsselung des Swapspace ist wichtig, da dort Daten aus dem Speicher
ausgelagert werden, die möglicherweise sensible Passwörter oder sonstige Daten
enthalten. Wenn der Swapspace verschlüsselt ist, ist er zumindest so sicher wie
ein verschlüsselter Container oder eine verschlüsselte Partition.
</p>
<p>
Da der Swapspace ohnehin einen Neustart des Systems nicht überleben muss,
brauchen wir uns gar kein Passwort ausdenken, sondern benutzen dafür einfach
den Zufallsgenerator <code>/dev/urandom</code>. Ähnlich wie in der Datei
<code>/etc/fstab</code> kann man verschlüsselte Partitionen in der
<code>/etc/crypttab</code> eintragen.
</p>
<p>
Nach dem Hinzufügen der Zeile für die Swappartition sieht die Datei dann so
aus:
</p>
<pre># &lt;target name&gt; &lt;source device&gt;         &lt;key file&gt;      &lt;options&gt;
swap /dev/hda3 /dev/urandom swap,cipher=twofish-cbc-essiv:sha256
</pre>
<p>
<strong>Vorsicht:</strong> <code>/dev/hda3</code> muss natürlich gegebenenfalls
ersetzt werden. Wie die Swappartition heißt, findet man mit dem Befehl
<code>cat /etc/fstab | grep swap</code> heraus.
</p>
<p>
In der <code>/etc/fstab</code> muss „/dev/hda3” durch „/dev/mapper/swap”
ersetzt werden.
</p>


## 5.) Mögliche Fehlermeldungen

<pre>Failed to setup dm-crypt key mapping.
Check kernel for support for the blowfish-cbc-essiv:sha256 cipher spec and verify 
that /dev/hda2 contains at least 258 sectors.
Failed to write to key storage.</pre>
<p>
<strong>Lösung:</strong> Eines oder mehrere der benötigten Kernelmodule wurde
nicht geladen, siehe Abschnitt 1.1.
</p>
