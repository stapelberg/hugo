---
layout: post
title:  "Datensicherung mit Bacula und Mac OS X"
date:   2007-08-24 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Bacula_OSX
---



<p>
Bacula ist eine Netzwerk-Backup-Software, die für mich das Mittel der Wahl
ist um alle wichtigen Rechner zu sichern. Die wichtigen Funktionen für
mich ist die Fähigkeit, Linux-, Mac OS X- und Windows-Rechner zu sichern,
die gut konfigurierbaren FileSets, inkrementelle Backups, Benachrichtigung via
Mail und gzip-Kompression.
</p>

<p>
Zur Sicherung und vor allem zur Bare-Metal-Recovery (das Wiederherstellen des
Backups auf eine komplett leere Festplatte) auf Mac OS X spricht sich die <a
href="http://bacula.org/en/?page=documentation"
title="Bacula-Dokumentation">Bacula-Dokumentation</a> leider nicht so sehr aus,
sodass ich diesen Artikel schrieb.
</p>

<p>
Ich gehe davon aus, dass die Prinzipien, Begriffe und Konfiguration von Bacula
bekannt ist und dass der Server einwandfrei läuft.
</p>

<h2>Konfiguration</h2>

<h3>Beteiligte Rechner</h3>
<p>
Der Director und Storage Daemon läuft bei mir auf einem Linux-Server, der
zu sichernde Mac ist ein MacBook.
</p>

<h3>Konfiguration</h3>
<p>
Da das Prinzip der Bacula-Konfiguration auf anderen Websites schon zur
Genüge erklärt ist, beziehe ich mich hier nur auf die Einzelheiten,
die für Mac OS X wichtig sind (<code>hfsplussuport</code>, FileVault und
die Liste der auszuschließenden Dateien).
</p>

<pre>FileSet {
	Name = "macbook-set"
	Include {
		Options {
			signature = MD5
			compression = gzip
			hfsplussupport = yes
		}
		File = /
		# Da FileVault als anderes Dateisystem gilt, muessen wir den Pfad explizit angeben
		File = /Users/michael
	}
	Exclude {
		@/etc/bacula/std_mac_exclude.files
		# Das FileVault-Image hingegen lassen wir aus, da wir ja die Dateien sichern
		File = /Users/.michael/michael.sparseimage
	}
}</pre>

<p>
Damit man die Liste der auszuschließenden Dateien nicht bei jedem Mac, den man
sichert, wiederholen muss, habe ich sie in die Datei
<code>std_mac_exclude.files</code> ausgelagert. Ausgeschlossen werden alle
Mountpoints (für FTP/SMB-Server, USB-Geräte, etc…), die temporären Dateien,
eingelegte CD-ROMs und das automatisch durchsuchte Netzwerk.
</p>

**/etc/bacula/std_mac_exclude.files**:

```
File = /Volumes
File = /tmp
File = /private/tmp
File = /cdrom
File = /automount
File = /Network
File = /.vol
```

<h3>FileVault</h3>
<p>
Wenn man FileVault benutzt, hat man drei Möglichkeiten:
</p>
<ol>
	<li>
	Man gibt keine speziellen Einstellungen an und lässt somit Bacula das
	FileVault-Image sichern.<br>Der Nachteil hierbei ist, dass man keine
	einzelnen Dateien wiederherstellen kann. Der Vorteil ist, dass man
	seine Wiederherstellung 1:1 durchführen kann.
	</li>
	<li>
	Man konfiguriert Bacula wie oben gezeigt und sicher somit den Inhalt
	des FileVault-Images, nicht aber das Image selbst.<br>Der Vorteil
	hierbei ist das Wiederherstellen einzelner Dateien, der Nachteil ist,
	dass man nach einer Bare-Metal-Recovery FileVault erst wieder
	aktivieren muss (oder es manuell währenddessen aktiviert, da weiß ich
	aber nicht, ob das überhaupt funktioniert).
	</li>
	<li>
	Man sichert sowohl den Inhalt, als auch das Image.<br>Der Vorteil ist,
	dass man sowohl einzelne Dateien wiederherstellen, als auch einfach
	eine Bare-Metal-Recovery durchführen kann. Der Nachteil ist, dass man
	doppelt so viel Speicherplatz für das Backup braucht.
	</li>
</ol>

<h2>Bare-Metal-Recovery</h2>
Voraussetzungen:
<ul>
	<li>Mac OS X Installation Disc (10.4)</li>
	<li>Eine vorher kompilierte, statische Version vom Bacula-Client (<code>bacula-fd</code>)</li>
	<li>Die Konfigurationsdatei (<code>bacula-fd.conf</code>) des Clients</li>
	<li>
	Einen USB-Stick oder eine externe Festplatte, um die beiden Dateien
	(<code>bacula-fd</code> und <code>bacula-fd.conf</code>) auf die leere
	Platte zu spielen sowie um das Script <code>rd.sh</code> auszuführen um
	die RAM-Disk zu erstellen
	</li>
</ul>

<h3>Statische Version des Bacula-Clients</h3>
<p>
Auf der Mac OS X Installation Disc sind alle benötigten Libraries vorhanden,
daher brauchen wir keine statische Version (das Kompilieren einer statischen
Version auf Mac OS X funktioniert ohnehin nicht).
</p>
<pre>./configure --enable-client-only
make</pre>
<p>
Anschließend kopieren wir <code>src/filed/bacula-fd</code> und die
Konfigurationsdatei, die wir zuvor schon verwende haben
(<code>bacula-fd.conf</code>) auf den USB-Stick.
</p>

<h3>RAM-Disk</h3>
<p>
Das Script, um eine RAM-Disk unter Mac OS X zu erstellen, habe ich auf <a
href="http://explanatorygap.net/2006/10/30/making-parts-of-the-filesystem-readwrite-from-netboot/"
target="_blank" title="explanatorygap.net">explanatorygap.net</a> gefunden. Es
muss auf dem USB-Stick (oder -Festplatte) gespeichert werden.
</p>

**rd.sh**:
```
echo "Creating RAM Disk for $1"
dev=`hdik -drivekey system-image=yes -nomount ram://2048 `
if [ $? -eq 0 ] ; then
	newfs $dev
	mount -o union $dev $1
fi
```

<h3>Die eigentliche Rettung</h3>
<p>
Ich gehe davon aus, dass eine leere Festplatte (oder eine, deren Daten nicht
mehr benötigt werden) am Computer angeschlossen ist (ob via Firewire, USB, oder
direkt eingebaut spielt keine Rolle).
</p>
<p>
Der erste Schritt besteht nun darin, von der Mac OS X Installation Disc zu
starten, wozu man beim Einschalten des Systems C gedrückt halten muss, bis das
Apfel-Logo erscheint.
</p>
<p>
Nach der Sprachauswahl geht es an das Einrichten einer Partition, auf die
später die Daten wiederhergestellt werden. Diese muss natürlich mindestens
genauso groß sein, kann aber auch größer sein. &Uuml;ber Dienstprogramme,
Festplattendienstprogramm beziehungsweise Utilities, Disk Utility (je nach
Sprache) lässt sich das Programm dazu aufrufen.
</p>
<p>
Die neu erstellte Partition wird dann automatisch gemountet, was man auch mit
<code>mount</code> nachsehen kann. Wir wechseln nun ins Terminal, das sich auch
bei Dienstprogramme finden lässt. In diesem Beispiel habe ich die neue
Partition „MacHD” genannt. Wir wechseln nun in das Verzeichnis und kopieren die
beiden vorbereiteten Dateien vom USB-Stick (der auch automatisch eingebunden
wird, sobald er angeschlossen wird):
</p>
<pre>cd /Volumes/MacHD
cp /Volumes/USB/bacula-fd /Volumes/USB/bacula-fd.conf .</pre>
<p>
Wichtig hierbei ist, dass diese beiden Dateien direkt im Root-Verzeichnis
liegen. Im Backup dürfen diese beiden Dateien nicht existieren, sonst bricht
Bacula bei der Wiederherstellung ab!
</p>
<p>
Wir erstellen nun eine RAM-Disk, die wir über <code>/var</code> legen, sodass
Bacula in <code>/var/bacula/working</code> schreiben kann (auf der Mac OS X
Installation Disc wird <code>/var</code> natürlich nicht schreibbar gemountet).
Man könnte auch ein Verzeichnis auf der neu angelegten Partition erstellen, das
von Bacula als Working-Directory genutzt wird, aber die 1 MB große RAM-Disk
langt aus und wir müssen hinterher weniger aufräumen.
</p>
<pre>/Volumes/USB/rd.sh /var
mkdir -p /var/bacula/working</pre>
<p>
Außerdem müssen wir die Netzwerkschnittstelle konfigurieren, damit wir eine
Verbindung zum Director/Storage Daemon bekommen:
</p>
<pre>ifconfig en0 192.168.1.5</pre>
<p>
Je nach Installation von Bacula muss hier noch ein Standardgateway gesetzt
werden (damit eine Verbindung ins Internet klappt):
</p>
<pre>route add default gw 192.168.1.1</pre>
<p>
Nun starten wir den File Daemon:
</p>
<pre>./bacula-fd</pre>

<p>
Und dann geht’s am anderen Rechner weiter. Nach dem Start von
<code>bconsole</code> zeigen wir uns mit <code>list jobs</code> die letzten
Backups an und wählen die ID des letzten Backups für den zu wiederherstellenden
Rechner.
</p>
<p>
Dann starten wir das Wiederherstellen (beziehungsweise die Dateiauswahl dafür)
mit folgendem Befehl (die JobID muss natürlich ausgetauscht werden):
</p>
<pre>restore jobid=123 all</pre>
<p>
Da wir keine Dateien aus- oder abwählen möchten, beenden wir mit
<code>done</code> die Auswahl und werden nun gefragt, ob Bacula anfangen soll.
Da wir nicht nach <code>/tmp/bacula-restores</code> wiederherstellen wollen,
verändern wir mithilfe von <code>mod</code> den Parameter <code>9)
Where</code>. Hier geben wir den Pfad zu unserer Partition ein, also in diesem
Beispiel <code>/Volumes/MacHD</code> und bestätigen dann mit <code>yes</code>.
</p>
<p>
Je nach Netzverbindung dauert das Wiederherstellen eine Weile (bei mir ca 20
Minuten für 30 GB über ein Gigabit-LAN).
</p>
<p>
Anschließend muss unbedingt noch das von uns im Backup ausgelassene Verzeichnis
<code>/dev</code> angelegt werden, sonst wird Mac OS X beim nächsten Neustart
nicht hochfahren:
</p>
<pre>mkdir dev</pre>
<p>
So, das war’s. Nun schließen wir das Terminal und wählen bei Dienstprogramme
das Programm Startvolume, wo wir „Mac OS X auf MacHD” wählen und auf
„Neustarten” klicken.
</p>
