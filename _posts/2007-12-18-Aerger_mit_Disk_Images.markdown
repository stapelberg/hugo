---
layout: post
title:  "Ärger mit Disk Images auf dem Mac"
date:   2007-12-18 10:00:00
categories: Artikel
---



<h3>Wie alles begann</h3>

<p>
Nachdem ich das Firewirekabel einer Digitalkamera aus meinem Macbook zog,
zeigte dieses den sonst eher selten anzutreffenden „Greyscreen” – er war also
abgestürzt. Klar, niemand ist fehlerfrei und gerade bei Hardware wird’s
kritisch. Das sei dem MacBook also verziehen. <strong>Nach dem Neustart ließ
sich jedoch das Sparseimage mit meiner Musik nicht mehr öffnen, es sei defekt
heißt es.</strong> Ich habe natürlich ein Backup, aber komisch ist das schon.
Schließlich könnte mir das ja dann auch mit dem FileVault-Image passieren und
da wäre das schon schlimmer.
</p>

<h3>Sparseimage, FileVault?</h3>

<p>
Ein Sparseimage ist ein mitwachsender Container, in dem man Dateien und Ordner
ablegen kann. Da er Verschlüsselung unterstützt, kann man somit bestimmte
Dateien mit einem Passwortschutz versehen.
</p>

<p>
FileVault nennt sich die Technik, wie Apple Verschlüsselung für das komplette
Heimverzeichnis (wo also alle Dateien abgelegt werden) realisiert. Das ist auch
nichts anderes, als ein Sparseimage mit dem Namen des Benutzers in seinem
Heimverzeichnis (<code>/Users/michael/michael.sparseimage</code>) in meinem
Fall. Dieses Image wird dann beim Anmelden als Benutzer automatisch eingebunden
und wieder freigegeben, sobald man sich abmeldet.
</p>

<p>
Wenn man Dateien in einem solchen mitwachsenden Image löscht, wird der freie
Speicherplatz nicht sofort zur Verfügung gestellt. Stattdessen wird er beim
Herunterfahren des Rechners aufgeräumt – las ich zumindest in verschiedenen
Foren. Bei mir kam diese Aufforderung nie, sodass langsam aber sicher meine
Festplatte immer voller wurde.
</p>

<h3>Manuell aufräumen</h3>

<p>
Da ich mich ja nicht als Benutzer anmelden konnte, da sonst das Image verwendet
werden würde, startete ich meinen Mac in den Single-User-mode. Dadurch landet
man auf einer Konsole und kann dort – wenn man ein bisschen mit UNIX-Systemen
vertraut ist – normal arbeiten. Das verkleinern meines Images via <code>hdiutil
compact michael.sparseimage</code> tat jedoch garnichts. Im Nachhinein weiß
ich, wieso das so ist: Die Abfrage nach dem Passwort für das verschlüsselte
Image kommt standardmäßig in der grafischen Oberfläche und nicht an der
Konsole. Die grafische Oberfläche ist im Single-User-mode allerdings nicht
gestartet.
</p>

<p>
Ich legte also einen neuen Benutzer an, unter dem ich dann via
Festplattendienstprogramm wie ein Otto-normal-Macuser auch unter der grafischen
Oberfläche das Volume aufrämen wollte.  </p>

<p>
Da das Image normalerweise nur vom Benutzer michael gelesen werden darf, musste
ich noch kurz die Rechte via <code>sudo chmod 555 /Users/michael/*</code>
ändern (das muss man danach auch wieder ändern, nicht vergessen!).
</p>

<p>
Nachdem ich das Festplattendienstprogramm geöffnet hatte, machte ich mich
vergebens auf die Suche nach einer Option um Images aufzurämen. Falls jemand
weiß, wie man das über dieses Programm erledigt, so möge er mir das bitte
mitteilen. Was ich allerdings fand, was ein Knopf um „Freien Speicher [zu]
löschen”. Da ich das mit der gewünschten Funktion verwechselte, führte ich es
eben durch.
</p>

<p>
Der Mac legt hier nun eine sehr große Datei mit dem UNIX-Befehl „dd” an, sodass
die komplette Festplatte gefüllt und die freien Stellen auf der Datei somit
überschrieben werden. <strong>Allerdings hört dieser Befehl nicht auf, wenn die
Platte voll ist – nein, er schreibt einfach munter weiter!</strong> Die einzige
Möglichkeit bestand darin, via Terminal und „kill -9” den Prozess zu töten.
Daraufhin arbeitete das Festplattendienstprogramm etwas weiter, verweigerte
dann aber aufgrund Platzmangels (0 freie Bytes) den Dienst. Erst nachdem man
auch das Programm über die selbe Methode abschießt, kann man weiterarbeiten.
</p>

<p>
Aufräumen konnte ich das Diskimage schließlich im Terminal mit dem Befehl
<code>hdiutil compact -verbose /Users/michael/michael.sparseimage</code>. Das
dauerte ca 30 Minuten um 35 GB aufzurämen.
</p>

<p>
Einen Bugreport dazu habe ich bei Apple natürlich geschrieben, ich werde
bekanntgeben, sobald sich etwas ergibt.
</p>
