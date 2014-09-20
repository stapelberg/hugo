---
layout: post
title:  "Kurztipp: Vergrößern einer NetBSD-domU (mit NetBSD-dom0)"
date:   2008-10-31 10:00:00
categories: Artikel
---



<p>
Vor kurzem hatte ich das Problem, dass ich einer domU zu wenig
Festplattenspeicher zugewiesen habe. Hinterher ist man immer schlauer, und
merkt dann auch, dass man mit 256 MB swap nicht weit kommt, wenn man die domU
auslastet ;-). Blöderweise hat NetBSD (noch) kein funktionierendes Programm um
das Dateisystem live zu verkleinern/vergrößern, sonst wäre die Änderung relativ
kurz und schmerzlos.
</p>

<p>
Das bestehende <code>resize_ffs</code> (aus NetBSD-current vom 31.10.2008) ist
leider nicht stabil und stürzte bei mir mit einem coredump ab.
</p>

<p>
Meine Installation, <a href="/Artikel/NetBSD_Xen" title="NetBSD 4 mit Xen
3">die ich hier beschrieben habe</a>, setzt darauf, dass man Partitionen
erstellt und xen diese direkt übergibt, sodass sozusagen „unter-partitioniert”
wird, also in einer Partition erneut in der domU ein disklabel erstellt wird.
Daher gibt es keine Möglichkeit (zumindest keine mir bekannte), auf der dom0
die Daten 1:1 zu kopieren auf ein neues, größeres Dateisystem.
<code>vnconfig</code> möchte zumindest keine Partitionen „loop-mounten”.
</p>

<p>
Die Lösung ist etwas umständlich und setzt voraus, dass du genug freien
Speicherplatz auf der Festplatte hast:
</p>

<ol>
	<li>
	Angenommen, die Festplatte heißt <code>/dev/wd0</code>, dann erstellen
	wir eine neue Partition, sagen wir <code>/dev/wd0f</code>, welche groß
	genug ist.
	</li>
	<li>
	In der Konfiguration der domU ergänzen wir das disk-Array mit dem
	Eintrag für die neue Festplatte, sodass es zum Beispiel so aussieht:
	<pre>disk = [ 'phy:/dev/wd0e,0x2,w', 'phy:/dev/wd0f,0x3,w' ]</pre>
	Wichtig ist dabei, dass die zweite Nummer nicht dieselbe ist, da sie zur Identifikation dient.
	</li>
	<li>
	In der domU haben wir dann ein neues block device namens
	<code>/dev/xbd1</code>. Diesem verpassen wir ein disklabel mit
	ausreichend Speicherplatz und Swapspace.
	</li>
	<li>
	Anschließend erstellen wir das Dateisystem mit <code>newfs
	/dev/xbd1a</code> und mounten es mit <code>mount /dev/xbd1a
	/mnt</code>. Via <code>df -h</code> können wir uns noch vergewissern,
	dass diesmal genügend Platz da ist.
	</li>
	<li>
	Sollte es sich um ein Live-System handeln, also um ein System mit
	kritischen Daten, die sich im Moment verändern, solltest du alle
	Dienste stoppen, sodass du einen möglichst konstanten Status des
	Systems hast, während du kopierst.
	</li>
	<li>
	Mithilfe von dump und restore kopieren wir das Dateisystem 1:1 auf das
	neue device:
	<pre>cd /; dump 0f - . | (cd /mnt; restore -rf - )</pre>
	Nach ca. 20 Minuten für 4 GB (auf meinem System) hat man dann eine exakte Kopie.
	</li>
	<li>
	Wir entfernen den alten Eintrag aus der domU-Konfiguration und starten
	die domU neu. Nun nochmal mit <code>df -h</code> und <code>swapctl
	-l</code> vergewissern das alles geklappt hat.
	</li>
</ol>

<p>
Logischerweise hat man anschließend zwar ein „Loch” in seiner Festplatte durch
den nunmehr ungenutzten Speicher, den die domU vorher hatte, sofern man den
nicht irgendwie wiederverwerten kann. Dafür hat man aber relativ problemlos
seine domU migriert.
</p>

<p>
Möglicherweise gibt es eine geschicktere Variante mit dem
Live-Migration-Feature von xen. Sofern du damit Erfahrungen gemacht hast,
insbesondere unter NetBSD, kontaktiere mich bitte.
</p>
