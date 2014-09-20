---
layout: post
title:  "Kurz-HowTo: Video-DVDs unter Linux erstellen und brennen"
date:   2007-08-21 10:00:00
categories: Artikel
---


<h2>Worum geht’s?</h2>

<p>
Oft habe ich Filme in verschiedensten Formaten (AVI, MPEG, DV, QuickTime), die
ich gerne möglichst einfach vorführen möchte. Dazu ist meines Erachtens eine
(Video-)DVD sehr geeignet. Eine Video-DVD unterscheidet sich von einer normalen
DVD, indem sie kein Menü hat und direkt startet – wie bei einem Video, oder
einer (S)VCD eben.
</p>

<p>
Unter Windows funktioniert das mit Nero ganz gut, unter Linux funktioniert es
genauso problemlos mit Open-Source-Programmen. Dabei handelt es sich bei uns um
avidemux, dvdauthor und gegebenenfalls mencoder. Zum Brennen verwenden wir
growisofs.
</p>

<h2>Pakete installieren</h2>

<p>
Wie eben erwähnt benötigen wir avidemux, was – entgegen seines Namens – ein
VirtualDub-Clone ist, dvdauthor, damit wir um die erstellte MPEG-Datei die
DVD-Dateistruktur erstellen können und eventuell mencoder um die Dateien vorher
in das richtige Format zu bringen.
</p>

<p>
Auf einem Ubuntu-System mit eingetragenen Multiverse-Quellen bekommt ihr die
benötigten Pakete via <code>apt-get install mplayer avidemux dvdauthor growisofs</code>.
</p>

<h2>Dateien bearbeiten und konvertieren</h2>

<p>
Mit avidemux kann man zum Beispiel Intros und/oder Abspänne bequem selektieren
und löschen, sodass auf der DVD nur das landet, was man wirklich sehen will.
</p>

<p>
Die Hauptaufgabe von avidemux wird in diesem HowTo allerdings sein, die Datei
ins „DVD-Format” zumzuwandeln (720x576 Pixel, MPEG-2). Dazu starten wir
avidemux, öffnen die entsprechende Datei und wählen im Menü „Tools” -> „DVD”
aus. avidemux trifft nun automatisch die benötigten Einstellungen und nach
einem Klick auf „Save” und dem Auswählen eines Dateinamens (die Erweiterung ist
„mpg” oder „mpeg”; avidemux schlägt dies weder vor noch ergänzt es die
Erweiterung automatisch) öffnet sich ein Fortschrittsfenster und nach einer
Weile – je nach CPU und Festplatte – haben wir eine fertige MPG-Datei auf
unserem Rechner.
</p>

<p>
Die Bitrate war in meinem Fall sehr gut automatisch eingestellt, bei ca 4000
kbit/s kann man nicht meckern. Zu beachten ist ohnehin, dass das Quellmaterial
im Falle von DivX eine niedrigere Qualität hat.
</p>

<h2>DVD-Authoring</h2>

<p>
Nun werden wir die Verzeichnisstruktur und die restlichen für DVDs notwendigen
Dateien erzeugen lassen. Dazu gibt es das Kommandozeilenprogramm dvdauthor. Es
gibt außerdem eine grafische Oberfläche namens qdvdauthor, die für unsere
Zwecke allerdings fast schon übertrieben ist und bei mir anfangs mehrmals
abstürzte. Außerdem habe ich keine Möglichkeit gefunden, die fälschlicherweise
auf 16:9 gesetzte Aspect Ratio auf 4:3 zu setzen – in der XML-Konfiguration für
dvdauthor funktioniert das problemlos.
</p>

<p>
Wir erstellen uns also eine Datei namens „dvdauthor.xml” (die Oberfläche
qdvdauthor tut nichts anderes). Diese hat zum Beispiel folgenden Inhalt:
</p>

<pre>
&lt;dvdauthor dest="/home/michael/Movies/Projekttage/DVD-Ausgabe"&gt;
 &lt;vmgm/&gt;
 &lt;titleset&gt;
  &lt;titles&gt;
   &lt;video format="pal" aspect="4:3" resolution="720x576" /&gt;
   &lt;pgc pause="0" &gt;
    &lt;vob file="/home/michael/Movies/Projekttage/Projekttage06.mpeg" pause="0" /&gt;
   &lt;/pgc&gt;
  &lt;/titles&gt;
 &lt;/titleset&gt;
&lt;/dvdauthor&gt;
</pre>

<p>
Für unsere Zwecke (Video-DVD ohne Menü oder Ähnliches) langt eine solch simple
Datei aus. Wichtig ist hier Zielordner und die Quelldatei, sowie das
Videoformat (PAL), die Aspect Ratio (4:3) und die Auflösung (bei DVD 720x576
Pixel).
</p>

<p>
Ausgetauscht werden muss hier bei jeder DVD eigentlich nur die Quelldatei und
der Zielordner, man kann sich also ein einfaches Script dafür schreiben.
</p>

<p>
Aufgerufen wird dvdauthor dann schließlich mit:
</p>
<pre>
dvdauthor -x &lt;path/to/dvdauthor.xml&gt;
</pre>

<h2>DVD brennen</h2>

<p>
Die fertige DVD kann man sich dann zum Beispiel mit vlc oder mplayer anschauen.
Gebrannt wird sie zum Beispiel mit growisofs, welches wiederum auf mkisofs
aufsetzt:
</p>

<pre>
growisofs -Z /dev/dvd -dvd-video /home/michael/Movies/Projekttage/DVD-Ausgabe
</pre>

<h2>Fertig</h2>

<p>
OK, das war’s auch schon. Jetzt sollte man die fertige DVD am besten noch in
einem Standalone-Player testen, damit man sich sicher sein kann, dass das
Brennen erfolgreich war. Sollte die DVD nicht laufen, würde ich es mit einem
anderen Rohling probieren oder zur Not mit einem anderen Brenner oder Player.
</p>
