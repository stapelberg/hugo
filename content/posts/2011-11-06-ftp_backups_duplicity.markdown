---
layout: post
title:  "FTP-Backups mit duplicity"
date:   2011-11-06 17:30:00
categories: Artikel
Aliases:
  - /Artikel/ftp_backups_duplicity
---


<p>
Aufmerksame Leser meiner Website wissen, dass ich normalerweise mit <a
href="http://www.bacula.org/">bacula</a> Daten sichere. Es gibt allerdings ein
Szenario, für das meine bacula-Installation nicht sonderlich gut geeignet ist:
Die Sicherung meines Servers. Ich habe seit einiger Zeit bei <a
href="http://www.vollmar.net/">vollmar.net</a> einen Dedicated Server und bin
sehr zufrieden mit dem Angebot und dem Service. Ein Dienst, den ich bisher noch
nicht bei vollmar in Anspruch genommen habe, ist der Backup-FTP-Server.
Stattdessen habe ich mit bacula die Daten auf meinen Fileserver zuhause
gesichert; ich habe also ein Offsite-Backup durchgeführt. Das ist zwar
prinzipiell eine gute Sache (meine Daten sind sicher, wenn das Rechenzentrum
abbrennt), hat allerdings den Nachteil, dass ein Restore sehr lange dauert (da
meine Internetleitung keinen schnellen Upstream hat) und dass mein Backup nicht
verfügbar ist, wenn mein Fileserver zuhause irgendwelche Probleme hat.
</p>

<p>
Das ist also meine Motivation, um zusätzlich ein Onsite-Backup bei meinem
Hoster durchzuführen. Zwar könnte man das nun mit bacula machen (auf
verschiedene Wege), aber sonderlich ausgereift ist bacula in Kombination mit
FTP nicht (stattdessen hauptsächlich mit Bändern und Festplatten). Weiterhin
ist bacula relativ komplex, sprich ich muss bei Ausfall meines Fileservers
zunächst ein funktionsfähiges bacula-Setup mit Director, File Daemon und
Storage Daemon aufbauen, bevor ich Dateien retten kann. Zudem schadet es nie,
sich auch mal nach anderen Programmen umzusehen, um einen Realitätsabgleich
durchzuführen ;-).
</p>

<h2>duplicity</h2>

<p>
Mehrfach bekam ich auf Nachfrage <a
href="http://duplicity.nongnu.org/">duplicity</a> empfohlen (die Anforderungen
waren: FOSS, FTP-Backup, zuverlässig). duplicity nutzt librsync und kann via
ncftp auf FTP-Server zugreifen (was in der Praxis besser funktioniert als man
zuerst vermuten möchte). Die Bedienung ist relativ einfach und
die Standardeinstellungen sind sinnvoll. Etwas missfallen hat mir die nicht
sonderlich ausführliche Dokumentation.
</p>

<p>
Folgenden Aufruf benutze ich, um meinen Server (der nur ein Dateisystem nutzt),
zu sichern:
</p>

<pre>
export FTP_PASSWORD=foobar
export PASSPHRASE=qux
BASEPATH=ftp://backup9999@9999.backup.vollmar.net/duplicity/

/usr/bin/duplicity incr \
	--exclude-other-filesystems \
	--exclude '/tmp/*' \
	--full-if-older-than 7D \
	--gpg-options '--compress-algo=zlib --compress-level 2' \
	/ \
	"$BASEPATH/root"

/usr/bin/duplicity remove-all-but-n-full 4 --force "$BASEPATH/root"
</pre>

<p>
Die Variable <code>FTP_PASSWORD</code> gibt das Passwort zum Backup-FTP-Server
an. Dieses wird nicht als Parameter übergeben, da jeder Benutzer auf dem System
sich die laufenden Prozesse inklusive Parameter anschauen kann (und somit an
das Passwort gelangt), was nicht mehr klappt, wenn man eine Umgebungsvariable
benutzt. Die Variable <code>PASSPHRASE</code> enthält einen Schlüssel, mit dem
GPG (mit symmetrischer Verschlüsselung) die Daten verschlüsselt. Man sollte
hierbei im Hinterkopf behalten, wogegen die Verschlüsselung schützt: Davor,
dass jemand ohne Zugriff auf den Server (wo der Schlüssel gespeichert ist) die
Daten des Backup-FTPs liest. Sie dient also nicht dafür, euch vor dem Hoster zu
schützen (was witzlos ist), sondern nur dagegen, dass zufällig (ausversehen?)
jemand über eure Daten stolpert. Oder dass Daten bei eurem Hoster auf Bänder
geschrieben und zulange aufbewahrt werden (deutsche Gesetze). Bedenken sollte
man auch, dass man für <strong>das Wiederherstellen den Schlüssel
braucht</strong>! Wenn der Schlüssel also einzig auf dem Server gespeichert
ist, hat man im Ernstfall verloren. Daher unbedingt auf genügend Maschinen
verteilen.
</p>

<p>
Die Aktion <code>incr</code> gibt an, dass ein inkrementelles Backup
durchgeführt werden soll. Sofern noch kein volles Backup besteht, wird
natürlich eins erstellt. Weiterhin wird durch die Option
<code>--full-if-older-than 7D</code> erzwungen, dass alle 7 Tage ein volles
Backup durchgeführt wird. Das ist praktisch um <a
href="http://en.wikipedia.org/wiki/Bit_rot">bit rot</a> sowohl auf dem Server,
als auch auf dem Backup-Server zu vermeiden. Mit den
<code>--exclude</code>-Optionen wird angegeben, dass nur das Dateisystem
gesichert werden soll, auf dem <code>/</code> liegt. Weiterhin wird
<code>/tmp/</code> von der Sicherung ausgenommen. Zu guter letzt machen wir den
Kompromiss bei CPU/Speicherplatz zugunsten eines CPU-schonenderen Backups (wir
sprechen hier von weniger als 50 MB Mehrverbrauch bei einem ca. 1 GB großen
Backup), indem wir an GPG die passenden Kompressionsoptionen angeben.
</p>

<p>
Der zweite duplicity-Aufruf löscht alles bis auf die letzten 4 vollen Backups
(inklusive zugehöriger inkrementellen Backups). Effektiv werden die Daten also
für ca. 1 Monat gesichert.
</p>

<p>
Ein volles Backup hat bei mir für 3 GB Daten (die auf 986 MB komprimiert
wurden) 6 Minuten und 33 Sekunden gedauert. Inkrementelle Backups dauern ca. 10
Sekunden. Die Zeiten sind durchaus akzeptabel, insbesondere wenn man bedenkt,
dass der Server nicht zu sehr belastet wird dadurch – die durchschnittliche
CPU-Auslastung lag bei 57%.
</p>

<h2>VMs sichern</h2>

<p>
Natürlich habe ich mir ein passendes Script geschrieben, welches auch gleich
die virtuellen Maschinen sichert (siehe <a
href="/Artikel/xen_lvm_snapshot">Xen-Server sichern mit LVM-Snapshots</a>). Das
Script kannst du dir via git herunterladen:
</p>
<pre>
# git clone git://code.stapelberg.de/duplicity-backup
</pre>
<p>
…oder <a href="http://code.stapelberg.de/git/duplicity-backup">im
Webinterface</a> anschauen.
</p>

<h2>Daten wiederherstellen</h2>

<p>
Wie man die aktuelle gespeicherten Backups einsieht und Daten wiederherstellt
ist in der Manpage und in folgenden Anleitungen hinreichend beschrieben:
</p>

<ul>
<li><a href="https://help.ubuntu.com/community/DuplicityBackupHowto">https://help.ubuntu.com/community/DuplicityBackupHowto</a></li>
<li><a href="http://www.debian-administration.org/articles/209">http://www.debian-administration.org/articles/209</a></li>
</ul>
