---
permalink: /post/3
layout: post
date: 2010-03-21 04:04:37 +01:00
title: "
Auf meinem Server nutze ich X…"
---
<p>
Auf meinem Server nutze ich Xen zur Virtualisierung, netterweise kann das
Logical Volumes (LVM) für die Festplatten der Gastsysteme nutzen. Damit ich nun
nicht auf jeder virtuellen Maschine bacula konfigurieren muss und beim
Wiederherstellen des Backups direkt alle Gastsysteme auf einen Schlag
restauriert habe, habe ich mir vor einiger Zeit ein Script geschrieben, welches
einen Snapshot der LVs mountet, der dann gesichert wird:
<a href="http://code.stapelberg.de/git/xen-lvm-snapshot/">
http://code.stapelberg.de/git/xen-lvm-snapshot/</a>.
</p>

<p>
Da ich den Snapshot zu einem beliebigen Zeitpunkt (dann, wenn das Backup eben
läuft) anfertige, ist das Dateisystem des Gastsystems natürlich nicht
notwendigerweise in einem konsistenten Zustand (bereits weil <code>ext3</code>
ein Journaling Filesystem ist, kann man den Snapshot nicht einfach mounten).
Deswegen nutze ich <code>fsck</code> um das Journal abspielen zu lassen und
somit einen sauberen Zustand des Dateisystems für die Sicherung zu erlangen.
</p>

<p>
Das funktionierte auch bis gestern einwandfrei. Dann allerdings meinte
<code>fsck</code>, dass 183 Tage ohne Überprüfung des Dateisystems zu lange
seien und dass er jetzt mal prüfen müsse. Soweit ist das ja eigentlich
kein Problem, allerdings gibt <code>fsck</code> einen anderen Returncode
zurück, wenn er im Zuge dieser Überprüfung das Dateisystem verändert. Das
wiederum veranlasst die Shell, das Script abzubrechen (durch <code>set -e
</code>), bevor der Snapshot gemountet wird, was wiederum <code>bacula</code>
stört (immerhin wurde der Fehler bis hin zu mir durchgereicht).
</p>

<p>
Die <a href="http://code.stapelberg.de/git/xen-lvm-snapshot/commit/?id=c89ef0d0687cf3dd65d5c7ac409c2d46548fe6b2">
Lösung des Problems</a> ist trivial, gleichzeitig sieht man hier aber schön,
wie selbst vermeintlich simple Programme monatelang funktionieren können, bevor
ein Fehler bemerkt wird.
</p>

