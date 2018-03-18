---
layout: post
title:  "3WARE 9550S-4LP mit Gentoo GNU/Linux"
date:   2008-03-17 10:00:00
categories: Artikel
Aliases:
  - /Artikel/3ware_gentoo
---



<p>
In meinem Fileserver betreibe ich den <a
href="http://3ware.com/products/Serial_ata2-9000.asp"
title="3WARE-Website">3WARE 9500S-4LP SATA-RAID-Controller</a> mit <a
href="http://www.gentoo.org/" target="_blank" title="Gentoo GNU/Linux">Gentoo
GNU/Linux</a>. Auf dem neuen Mainboard, das etwas mehr Durchsatz ermöglicht und
somit keinen Flaschenhals mehr darstellt, war die Auslastung während Backups
allerdings deutlich zu hoch (load von 10-15, hauptsächlich IO-Wait). Daher
probierte ich allerlei Dinge aus, die ich hier der Vollständigkeit halber (und
natürlich als Tipp für diejenigen mit ähnlichen Problemen) niederschreibe.
</p>

<h2>dstat</h2>
<p>
<code>dstat</code> ist ein Python-Programm, welches <code>vmstat</code> ähnelt.
Es hat allerdings deutlich mehr Optionen und eine schönere, farbige Ausgabe.
Mit <code>dstat</code> kann man sehr schön sehen, welche der PCI-Karten
momentan Last verursachen (Interrupts) und wie sehr das System gerade
ausgelastet ist (CPU, RAM, Swap, Network, Disk Read/Write, …).
</p>

<p>
Was mich allerdings störte, war, dass man den Interrupts keine eigenen Namen
geben kann, sodass man leicht durcheinander kommt, wenn man viele
Karten/Controller im System hat. Mein Ansatz ist daher, die Titelleiste des
Terminals mit den nötigen Zuordnungen auszustatten, was aber daran scheiterte,
dass <code>dstat</code> unbedingt seinen eigenen Titel setzen will…
</p>

<p>
In Zeile 1744 in /usr/bin/dstat (Version 0.6.6) findet sich der Code, welcher
den Titel setzt. Diese 5 Zeilen können einfach entfernt werden und schon kann
man zum Beispiel folgendermaßen seine eigene Titelleiste setzen:
</p>

<pre>echo -ne "\033]0;16 = GBIT-E, 18 = SCSI, 19 = RAID, 21 = SATA, 25 = DVB-S, 26 = ISDN\007" &amp;&amp; \
dstat -C 0,1,total -dimsnlc -I 16,18,19,21,25,26</pre>

<p>
Die einzelnen Geräte und deren Interrupts lassen sich übrigens über ein
<code>lspci -v</code> in Erfahrung bringen.
</p>

<h2>irqbalance</h2>
<p>
Zufällig bin ich über <code>irqbalance</code> gestolpert, welches bei
Multiprozessorsystemen die Interrupts besser verteilen soll (wenn die
entsprechende Kerneloption CONFIG_IRQBALANCE gesetzt ist). Einen messbaren
Effekt brachte es mir nicht, aber vielleicht hilft es ja in anderen
Situationen?
</p>

<h2>tw_cli installieren</h2>
<p>
Zur Verwaltung des Controllers gibt es das <code>tw_cli</code>-Programm von
3WARE. Natürlich hat Gentoo dafür ein ebuild, allerdings muss man das
Programm-Archiv selbst herunterladen und dann in das DISTFILE-Verzeichnis
legen, da 3WARE es unter einer eigenen Lizenz vertreibt.
</p>

<p>
Das Programm kann einige Informationen (Version der Firmware, BIOS, …)
auslesen und wird unter Anderem dazu verwendet, degraded Arrays wieder
aufzubauen. Man sollte es also auf jeden Fall parat haben.
</p>

<h2>Systemparameter bei jedem Start setzen</h2>
<p>
In der <a href="http://www.3ware.com/kb/article.aspx?id=11050"
target="_blank">3WARE-Knowledge-Base</a> werden verschiedene Parameter
empfohlen und erklärt. Grob gesagt beeinflussen sie das Verhalten des
Linux-Kernels, der somit dem Controller die Daten besser zuspielt.
</p>
<p>
Damit diese Parameter bei jedem Systemstart gesetzt werden und dabei auch noch
die udev-Namen benutzt werden (damit man munter Laufwerke vertauschen kann)
benutze ich folgendes Script:
</p>
<pre># /etc/conf.d/local.start

# This is a good place to load any misc programs
# on startup (use &amp;&gt;/dev/null to hide output)


REALDEV=$(readlink /dev/disk/by-id/scsi-1AMCC_W51517585EC0DB000531 | tr -d ./)
if [ "${REALDEV}" != "" ]
then
	ebegin "Tuning 3WARE-Controller (/dev/${REALDEV})"
		echo 64 &gt; /sys/block/${REALDEV}/queue/max_sectors_kb &amp;&amp; \
		echo 512 &gt; /sys/block/${REALDEV}/queue/nr_requests &amp;&amp; \
		echo deadline &gt; /sys/block/${REALDEV}/queue/scheduler &amp;&amp; \
		blockdev --setra 16384 /dev/disk/by-id/scsi-1AMCC_W51517585EC0DB000531
	eend $?
else
	echo "ERROR: 3WARE-Controller could not be found!"
fi</pre>
<p>Testen kann man das mit <code>/etc/init.d/local restart</code>, was dann so aussehen sollte:
<pre>
 * Caching service dependencies ...         [ ok ]
 * Stopping local ...                       [ ok ]
 * Starting local ...
 * Tuning 3WARE-Controller (/dev/sdb) ...   [ ok ]</pre>


<h2>Cache aktivieren</h2>
<p>
Die Hauptlösung für das Lastproblem war der nicht aktivierte Cache des
Controllers (128 MB). 3WARE empfiehlt, sofern man keine Battery Backup Unit
installiert hat, den Cache zu deaktivieren. Da für mich allerdings das Risiko,
dass bei einem Stromausfall Daten verloren gehen, geringer wiegt als einen
nicht benutzbaren Server zu Backupzeiten, habe ich mich für das Aktivieren
entschieden.
</p>

<p>
Den Cache kann man mit folgendem Befehl aktivieren (sofern <code>c2</code> die
korrekte Controllerbezeichnung im System ist):
</p>

<pre>/c2/u0 set cache=on
Setting Write Cache Policy on /c2/u0 to [on] ... Done.</pre>
