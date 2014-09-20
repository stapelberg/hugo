---
layout: post
title:  "Kurz-Howto: Baculas Konfiguration stark vereinfachen"
date:   2007-12-16 10:00:00
categories: Artikel
---



<p>
Mit Baculas hoher Flexibilität einher geht auch eine hohe Komplexität bei den
Konfigurationsdateien. Letztendlich landet man aber, nachdem man sich mal damit
befasst hat, bei einer Konfiguration, die für jeden Rechner weitestgehend
gleich ist. Bei einigen Resourcen muss man sogar nur den Namen austauschen.
</p>

<p>
In meinem Setup habe ich 10 Rechner, die gesichert werden sollen. Mit dem
normalen Ansatz müsste ich nun 10 Mal die komplette Konfiguration durchführen,
die weitestgehend gleich ist.
</p>

<p>
Als Alternative würde schon eine Direktive genügen, mit der ich in der
Konfiguration, die ja das Einbinden von anderen Dateien erlaubt, Variablen
angeben könnte, die ersetzt würden, dachte ich mir. Nachdem ich mir anschaute,
wie man das am besten implementieren könnte, bemerkte ich, dass Bacula auch mit
Pipes umgehen kann beim Laden von Konfigurationsdateien, sprich man kann andere
Programme ausführen und deren Ausgabe verwenden.
</p>

<p>
In bester UNIX-Manier kann man also <code>sed</code> und Shell-Scripts
verwenden, um sich die Konfiguration zu abstrahieren. Jedoch gab es zwei kleine
Probleme:
</p>
<ul>
	<li>
	Ein Bug verhinderte, dass Pipes richtig ausgeführt werden, denn das
	Pipe-Zeichen wurde nicht übersprungen und somit wurde das auszuführende
	Programm nicht gefunden.
	</li>
	<li>
	Der Parser behandelte Anführungszeichen bei Include-Direktiven als
	Trennzeichen und erlaubte keine Angabe eines Befehls, der Leerzeichen
	enthielt und daher in Anführungszeichen eingeschlossen werden muss.
	Somit könnte man zwar ein Shellscript ausführen, ihm jedoch keine
	Parameter mitgeben, wodurch man nichts gewonnen hätte.
	</li>
</ul>
<p>
Beide Fehler konnte ich für Version 2.2.7 von Bacula beheben.
</p>

<h2>Templates</h2>
<p>
Wie die Templates nun aussehen, die man sich selbst macht, ist weitestgehend
beliebig. Ich habe als Variable zum Beispiel <code>%name</code> verwendet. Mit
<code>sed</code> wird diese Variable dann ersetzt.
</p>

<h3>Template-Datei default-pool.inc</h3>
<pre>Pool {
	Name = %name
	Pool Type = Backup
	Maximum Volume Jobs = 1
	Volume Retention = %ret
	Maximum Volume Bytes = 0
	Volume Use Duration = 0
}
</pre>

<h3>Einbindung in bacula-dir.conf</h3>
<pre>@&quot;|sed 's/%name/codebox/g;s/%ret/2 weeks/g' /etc/bacula/default-pool.inc&quot;</pre>
<p>Hier wurde also <code>%name</code> durch „codebox” ersetzt und die Volume Retention-Variable <code>%ret</code> durch „2 weeks”. Nach diesem Schema kann man nun mehrere Rechner sehr einfach einbinden:</p>
<pre>@&quot;|sed 's/%name/codebox/g;s/%ret/2 weeks/g' /etc/bacula/default-pool.inc&quot;
@&quot;|sed 's/%name/ibook/g;s/%ret/4 weeks/g' /etc/bacula/default-pool.inc&quot;
@&quot;|sed 's/%name/macbook/g;s/%ret/4 weeks/g' /etc/bacula/default-pool.inc&quot;</pre>
<p>Das macht dann 3 Zeilen im Vergleich zu 24 Zeilen Konfigurationsaufwand…</p>

<h3>Template-Datei default-client.inc</h3>
<pre>Client {
	Name = %name-fd
	Address = %address
	FDPort = 9102
	Catalog = MyCatalog
	Password = "%pass"
	File Retention = %ret
	Job Retention = %ret
	AutoPrune = yes
}</pre>
<p>
Hierbei ist darauf zu achten, dass man – da <code>sed</code> manche Zeichen
anders interpretiert – manche Zeichen escapen muss. Da der Parser von Bacula
jedoch auch escaped, muss man sogar doppeltes Escaping vornehmen:
</p>
<pre>@&quot;|sed 's/%name/codebox/g;s/%address/codebox/g;s/%ret/2 weeks/g;s/%pass/password mit \\/ slash/g' /etc/bacula/default-client.inc&quot;</pre>
<p>Dieser Aufruf entspricht dem Passwort „password mit / slash”.</p>

<h3>Template-Datei default-device.inc</h3>
<pre>Device {
	Name = %name-files
	Media Type = File
	Archive Device = /raid/%name
	LabelMedia = yes
	Random Access = Yes
	AutomaticMount = no
	RemovableMedia = no
	AlwaysOpen = no
}</pre>

<p>
Natürlich klappt diese Technik auch beim Storage Daemon, sodass man sich hier –
je nach Setup – auch wieder enorm viele Zeilen sparen kann.
</p>

<h3>Include-Datei default-fs-exclude-linux.inc</h3>
<p>
Wenn wir gerade beim Einbinden von Dateien sind, ist es auch sinnvoll, die
standardmäß auszulassenden Files auszulagern:
</p>
<pre>File = /proc
File = /tmp
File = /.journal
File = /.fsck
File = /media
File = /mnt
File = /sys
File = /lost+found</pre>

<h3>Include-Datei default-fs-exclude-mac.inc</h3>
<pre>File = /Volumes
File = /tmp
File = /private/tmp
File = /cdrom
File = /automount
File = /Network
File = /.vol</pre>

<h3>Template-Datei default-job.inc</h3>
<pre>Job {
	Name = "%name"
	Type = Backup
	Client = %name-fd
	FileSet = "%name-set"
	Schedule = "%name-sched"
	Storage = %name-storage
	Messages = Standard
	Priority = 10
	Write Bootstrap = "/raid/%name/bootstrap"
	Pool = %name
}</pre>
<p>
Diese Datei fügt quasi die anderen Dateien zusammen und hat die größte
Ausbeute, was Zeilen und Ersetzungen angeht.
</p>

<h3>Template-Datei default-storage.inc</h3>
<pre>Storage {
	Name = %name-storage
	# Use VPN address here to enable clients connecting via VPN to back up
	Address = fs.vpn
	SDPort = 9103
	Password = "secret"
	Device = %name-files
	Media Type = File
}</pre>

<h3>Template-Datei/Script default-fs.inc/default-fs.sh</h3>
<pre># Variable FileSet-Definition
#
# Parameters:
# %name - name of the machine to be backed up
# %compression - leave blank or set to 'compression = gzip'
# %mac - leave blank or set to 'hfsplussupport = yes'
# %os - set mac or linux or windows

FileSet {
	Name = "%name-set"
	Include {
		Options {
			signature = MD5
			%compression
			%mac
		}
		File = /
		%extrafiles
	}
	Exclude {
		@/etc/bacula/default-fs-excludes-%os.inc
	}
}</pre>
<p>
Da die Konfiguration des Filesets etwas umfangreicher werden kann, habe ich sie
in den meisten Fällen im gewohnten Format gelassen. Allerdings konnte ich die
Hälfte der Konfigurationen abstrahieren, auch wenn das aufwändiger ist als
bisher. Damit die Zeilen nicht so lang werden, habe ich folgendes Script dazu
gebaut:
</p>
<pre>#!/bin/sh
# Returns a default FileSet-resource
# Syntax: default-fs.sh &lt;name&gt; &lt;os&gt; [compression] [extra-files]

[ &quot;${2}&quot; = &quot;mac&quot; ] &amp;&amp; mac=&quot;hfsplussupport = yes&quot;
[ ! -z &quot;${3}&quot; -a &quot;${3}&quot; = &quot;yes&quot; ] &amp;&amp; comp=&quot;compression = gzip&quot;
extra=${@:4}
sed &quot;s/%name/${1}/g;s/%compression/${comp}/g;s/%mac/${mac}/g;s/%os/${2}/g;s/%extrafiles/${extra}/g&quot; /etc/bacula/default-fs.inc
</pre>

<p>Eingebunden wird das Script folgendermaßen:</p>
<pre>@&quot;|/etc/bacula/default-fs.sh ibook mac yes&quot;
@&quot;|/etc/bacula/default-fs.sh tv linux yes&quot;
@&quot;|/etc/bacula/default-fs.sh fs linux&quot;

