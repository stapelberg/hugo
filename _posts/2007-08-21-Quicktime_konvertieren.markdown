---
layout: post
title:  "Quicktime-Dateien für das Brennen auf DVD konvertieren"
date:   2007-08-21 10:00:00
categories: Artikel
---



<h3>Einleitung</h3>
<p>
Wer kennt es nicht, das Problem mit den Formaten an Computern? Jeder Hersteller
hält das eigene Format für das Beste und einige legen überhaupt keinen Wert
darauf, zu anderen kompatibel zu sein. Das fängt bei Textdokumenten an
(Microsoft Word) und hört bei Multimediaformaten auf: für mich ist ein solches
Format zum Beispiel Quicktime oder Realvideo: Bei beiden Formaten muss man
anstelle eines Codecs direkt einen ganzen Player installieren, um sie ansehen
zu können (vom Bearbeiten sehen wir momentan mal komplett ab). DivX oder das
freie XviD hingegen funktionieren prima in allen Programmen, die auf Codecs
aufbauen, sobald man den passenden Codec installiert.
</p>

<p>
Wenn man nun aber auf ein solches Format angewiesen ist, hilft alles nichts,
man muss in den saueren Apfel (könnte man bei Quicktime sogar als Wortspiel
interpretieren ;-)) beißen und das Format in ein verwendbareres konvertieren.
Genau darum geht es hier: Formate mithilfe des freien Open-Source-Projekts VLC
und dem ebenfalls freien Open-Source-Projekt VirtualDubMod konvertieren.
</p>

<h3>Was brauchen wir?</h3>
<ul>
	<li>
	<a href="http://www.videolan.org/" target="_blank">VideoLAN-Client</a>
	(VLC, frei, Open-Source, für viele Platformen verfügbar)
	</li>
	<li>
	<a href="http://virtualdubmod.sourceforge.net/"
	target="_blank">VirtualDubMod</a> (frei, Open-Source, für Windows
	verfügbar)
	</li>
</ul>

<h3>OK, dann mal los</h3>
<p>
Zuerst müsst ihr die Quicktime-Dateien (ich werde hier immer Quicktime-Dateien
sagen, solltet ihr das Ganze mit einem anderen Format durchführen, denkt euch
einfach dessen Namen an die jeweilige Stelle) irgendwie auf die Festplatte
bringen. In meinem Fall habe ich mehrere CDs erhalten. Wenn das CD-Laufwerk
schnell genug ist, kann man die Dateien auf CD belassen, ansonsten ist es
vielleicht besser, sie vorher auf die Festplatte zu kopieren.
</p>

<p>
Anschließend solltet ihr sichergehen, dass ihr genug Speicher frei habt. Wir
werden im Laufe des Konvertierens im Indeo-Video-Format speichern, welches für
3 Minuten bei 400x300 ca 60 MB benötigt.
</p>

<a href="/Bilder/Quicktime-Konvertieren/qtc1.png"><img
src="/Bilder/Quicktime-Konvertieren/thumbs/qtc1t.png" style="float: left;
padding-right: 5px"></a>

<p>
Nun startet ihr VLC. Wählt „Datei → Datei öffnen” oder drückt einfach
Strg+F. Der sich öffnende Dialog mag anfangs verwirrend erscheinen, für uns ist
hier nur das Feld „Datei” wichtig. Klickt also auf Durchsuchen und wählt die
Quicktime-Datei oder gebt den Pfad manuell in die Editbox ein. Klickt jetzt auf
„OK” und vergewissert euch, dass VLC die Datei problemlos abspielen kann.
Sollte dies nicht der Fall sein, fehlt euch eventuell der Quicktime-Player oder
- falls ihr ein anderes Format konvertiert - ein Codec.
</p>

<a href="/Bilder/Quicktime-Konvertieren/qtc2.png"><img
src="/Bilder/Quicktime-Konvertieren/thumbs/qtc2t.png" style="clear: left;
float: right; padding-left: 5px"></a>
<p>
Stoppt das Abspielen und öffnet erneut den „Datei öffnen”-Dialog. Lasst den
Dateinamen wie er ist und kümmert euch um die sogenannte Streamausgabe. Dazu
aktiviert ihr im unteren Teil des Dialoges die Option „Streamausgabe” und
klickt auf den Button „Einstellungen” direkt rechts daneben. Auch hier wird man
wieder mit Optionen überflutet, lasst euch nicht verwirren und setzt ein Häcken
bei „Datei”. Sucht euch über den Durchsuchen-Button einen Speicherort aus oder
gebt diesen manuell in das Editfeld ein. Ich empfehle, als Dateinamen der
Original-Dateinamen (zum Beispiel „KinoTrailer.mov”) zu verwenden und die
Erweiterung mit .mpg zu ersetzen (also „KinoTrailer.mpg”). <b>Nun wird es
wichtig: Bei „Verkapslungsmethode” wählt ihr „MPEG PS”, als Videocodec „mp2v”,
als Audiocodec „mp2a”.</b> Alle anderen Einstellungen werden so gelassen, wie
ihr sie vorgefunden habt. Klickt nun auf OK und bestätigt auch den anderen
Dialog mit OK.
</p>

<p>
VLC wird nun die Datei intern abspielen und an den eingestellten Speicherort
streamen. Es ist normal, dass VLC während dieses Vorgangs nicht beziehungsweise
nur sporadisch reagiert, verliert also nicht die Geduld und wartet einige Zeit.
</p>

<p>
Diese Schritte wiederholt ihr nun mit allen Dateien, die ihr konvertieren
möchtet. Vielleicht kann jemand hierfür ja eine Batch-Datei schreiben und mir
zusenden oder anderweitig veröffentlichen.
</p>

<p>
VLC hat nun seinen Job (hoffentlich erfolgreich ;-)) erledigt, widmen wir uns
also VirtualDubMod. Im Gegensatz zu VirtualDub kann VirtualDubMod besser mit
MPEG-Dateien umgehen, welche wir ja eben mit VLC erzeugt haben.
</p>

<p>
Startet also VirtualDubMod und wählt „File → Open video file ...” oder
drückt Strg+O. Hier wählt ihr nun die MPG-Datei aus. Nachdem VirtualDubMod die
MPG-Datei geparsed hat, könnt ihr diese mit den zahlreichen Funktionen dieses
Programms bearbeiten. Wer die Datei 1:1 (wenn man das beim Re-encodieren so
sagen darf ;-)) übernehmen möchte, lässt dies aus.
</p>

<p>
Wir haben nun mehrere Möglichkeiten der Weiterverarbeitung: Die einen
bevorzugen DivX oder XviD um die Datei im Internet möglichst klein zur
Verfügung zu stellen. Wieder andere wollen sie als AVI-Datei speichern, um sie
für andere Programme zu verwenden. Wir entscheiden uns für den letzten Weg.
Prinzipiell sind jedoch alle Formate möglich, die VirtualDub(Mod) unterstützt.
</p>

<a href="/Bilder/Quicktime-Konvertieren/qtc3.png"><img
src="/Bilder/Quicktime-Konvertieren/thumbs/qtc3t.png" style="float: left;
padding-right: 5px"></a>
<p>
Der aufmerksame Leser wird such nun fragen: Warum speichern wir denn eine
AVI-Datei mit VirtualDubMod, wenn VLC uns schon eine MPG-Datei erzeugt hat, die
doch auch verwendbar ist? Die Antwort ist einfach: Die Dateien, die VLC
erzeugt, lassen sich zum Beispiel nicht korrekt mit dem Windows Media Player
abspielen, was darauf hindeutet, dass sie nicht standardkonform sind (dies
sollte man nicht verallgemeinern, ich weiß nicht, wie sehr standardkonforme
Dateien der WMP verlangt, es fiel mir nur mit diesem Player auf). In Nero
(Vision Express) äßert sich das dann zum Beispiel mit Hängern beim Encodieren,
die allerdings nicht bei jeder Datei auftreten. Dies ist vor allem dann
ärgerlich, wenn die anderen 5 Dateien ohne Probleme durchliefen, und die letzte
Datei nach 4 Stunden encodieren dann doch nicht will (ich spreche leider aus
Erfahrung ;-)). Wir gehen also auf „Video → Compression” (oder drücken
Strg+P) und wählen „Intel indeo® Video 4.5” (sollte auf allen aktuellen
Systemen installiert sein). Hier können wir nun noch die Qualität auswählen,
dies kann man je nach Qualität des Eingangsmaterials einstellen. Außerdem ist
es eventuell empfehlenswert, die Option „Quick Compress” unter „Configure” zu
aktivieren, wenn man nicht viel Zeit hat.
</p>

<p>
Wenn alle Einstellungen gemacht wurden und die offenen Dialoge mit OK bestätigt
wurden, klicken wir auf „File → Save As...” oder drücken F7. Wie vorhin
empfehle ich auch hier wieder, den Originaldateinamen zu verwenden und
lediglich die Erweiterung zu ändern, in diesem Fall in .avi. Bestätigt auch
diesen Dialog, macht euch etwas zu essen oder schaltet den Monitor aus und
tut irgendetwas sinnvolles - das Encoding kann etwas dauern.
</p>

<p>
Nachdem auch Virtualdub seine Arbeit beendet hat, könnt ihr kurz Überprüfen, ob
die Dateien auch abspielbar sind, und dann die .mpg-Datei und ggf die
Originaldatei(en) (wenn ihr Platz braucht) löschen. Die fertige .avi-Datei kann
nun zum Beispiel mit NeroVision Express auf DVD oder (Super)VideoCD gebrannt
werden :-).
</p>
