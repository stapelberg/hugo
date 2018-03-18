---
layout: post
title:  "Windows Server retten mit grml Linux"
date:   2007-08-21 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Windows_Server_retten_mit_grml
---



<p>
<a href="http://grml.org" title="grml.org"
target="_blank"><code>grml</code></a> ist eine Linux-Live-CD für Nutzer, die
lieber textbasierte Programme als grafische benutzen. Es basiert auf Debian
GNU/Linux, ist aber deutlich aktueller. Meiner Meinung nach eignet sich
<code>grml</code> am besten, wenn es darum geht, Rechner zu retten.
</p>

<h2>Die Problematik</h2>
<p>
Der zu rettende Rechner war ein Windows Small Business Server 2003. Dort laufen
zahlreiche Dienste, unter anderem auch ein Exchange-Server, welcher seine Daten
auf <code>C:\</code> ablegt. Nun sammelten sich dort mit der Zeit immer mehr
Daten an, sodass auf <code>C:\</code> nur noch 100 MB frei waren. Die Daten
sollen daher auf zwei neue SATA-Festplatten übertragen werden und die
Partitionen anschließend vergrößert werden (sowohl <code>C:\</code> als auch
<code>D:\</code>).
</p>

<p>
Verschiedene Windows-Programme konnten die Daten nicht übertragen, da sie nicht
mit dynamischen Datenträgern (ein Windows-spezifisches Partitionsformat,
welches zum Beispiel für Software-RAID unter Windows benötigt wird) umgehen
können. Außerdem fuhr der Windows Server nicht mehr hoch, sobald der
SATA-Controller (von Promise) eingebaut war und die Festplatten angeschlossen
waren (wenn sie nicht angeschlossen sind, funktioniert es).
</p>

<h2>Rettung</h2>
<p>
Beim Booten von der grml-CD (Version 1.0) wurden alle Controller und
Festplatten ordnungsgemäß erkannt. Ein Blick in die Ausgabe von <code>fdisk
-l</code> zeigte dann, dass zwei Partitionen vorhanden waren, mit Typ SFS (42).
Dies ist der Typ, den Windows beim Erstellen eines dynamischen Datenträgers
setzt.
</p>

<p>
Ein Kopieren auf Partitionsebene brachte keinen Erfolg, sprich: Der Server
bootete wieder nicht (dies äußert sich übrigens darin, dass er nach ca 15
Sekunden einfach einen Neustart durchführt, ohne Fehlermeldung, Bluescreen,
Logeintrag oder sonstige Informationen).
</p>

<p>
Eine 1:1-Kopie der Festplatte (<code>dd if=/dev/sdc of=/dev/sda bs=5M</code>)
klappte dann letztendlich.
</p>

<p>
Das neue Problem, was sich nun stellte, war, dass die üblichen
Partitionsprogramme unter Windows kaum mit dynamischen Partitionen umgehen
können (Acronis Disk Director Server und Paragon Partition Manager). Die
windowseigene Datenträgerverwaltung kann leider keine Partitonen erweitern, die
erstellt wurden, bevor der Datenträger in einen dynamischen umgewandelt wurde.
Somit konnte zwar <code>D:\</code> vergrößert werden, nicht aber
<code>C:\</code>.
</p>

<p>
Glücklicherweise gibt es das Linux-Programm <code>testdisk</code>, welches
Partitionen erkennt und auch dynamische Partitionstabellen in normale
Partitionstabellen umwandeln kann. Dies klappte problemlos und anschließend
konnten mit den oben genannten Programmen die Partitionen vergrößert werden.
</p>

<h2>Bemerkungen</h2>

<p>
Der Promise-Controller möchte, wenn das RAID-1 inkonsistent ist, und man es
auflösen will, den MBR (Master Boot Record) der Festplatte löschen. Das RAID-1
kann man, ohne dass die Festplatte angeschlossen ist, nicht löschen, da es gar
nicht in der Liste auftaucht. Somit muss man sich also den MBR löschen lassen
und anschließend via <code>fixmbr</code> und <code>fixboot</code> von der
Windows Installations-CD wiederherstellen. <code>fixmbr</code> funktioniert
übrigens bei dynamischen Datenträgern anscheinend nicht (zumindest bringt es
keine Ausgabe und repariert auch nichts).
</p>

<p>
Außerdem taucht das angebliche RAID-1 bei <code>grml</code> nicht als solches
auf; die Festplatten werden einzeln erkannt (<code>/dev/sda</code> und
<code>/dev/sdb</code>). Der „RAID-Controller” macht also kein Hardware-RAID,
sondern über einen Windows-Treiber ein Software-RAID – na super. Ob man ihm
unter Linux vorspielen kann, dass das RAID in Ordnung sei, indem man einfach
den Inhalt von <code>/dev/sda</code> auf <code>/dev/sdb</code> kopiert, habe
ich nicht ausprobiert (wäre aber interessant zu wissen).
</p>

<h2>Fazit</h2>

<p>
Mit Linux-Live-CDs kann man einige Dinge (1:1-Kopien, Umwandlung dynamischer
Datenträger) ohne großen Aufwand, komplett ohne Kosten und sehr zuverlässig
durchführen. Für Windows-Admins lohnt sich also der Blick über den Tellerrand
;-).
</p>
