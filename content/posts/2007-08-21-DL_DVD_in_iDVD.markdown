---
layout: post
title:  "Tipp: Double-Layer DVDs auch ohne DL-Superdrive in iDVD"
date:   2007-08-21 10:00:00
categories: Artikel
Aliases:
  - /Artikel/DL_DVD_in_iDVD
---



<p>
In iDVD (ich beziehe mich hierbei auf Version 6) kann man ohne
Double-Layer-fähiges Superdrive (so nennt sich der CD/DVD-Brenner im Mac) keine
Double-Layer-DVDs erstellen, das Auswahlfeld dazu ist deaktiviert.
</p>

<p>
Da iDVD aber die Möglichkeit bietet, die fertige DVD als ISO-Image zu sichern,
könnte man sie doch an einem anderen Rechner brennen, somit würde die Option
sehr sinnvoll sein.
</p>

<p>
Wer sich ein bisschen mit Apple-Programmen beschäftigt, weiß, dass es oft unter
der Haube noch mehr Einstellmöglichkeiten gibt. Diese werden in XML Preference
List-Dateien (plist) gespeichert.
</p>

<p>
Leider blieb eine Suche im Web nach der passenden Einstellung erfolglos, sodass
ich selbst versuchte, herauszufinden, welche Einstellung das sein könnte.
</p>

<p>
Die erste Möglichkeit dazu ist, das Programm (welches sich in
<code>/Applications/iDVD.app/Contents/MacOS/iDVD</code> befindet), in einem
Debugger wie <code>gdb</code> zu starten, und sich die Funktionsnamen anzusehen
(Das geht mit dem Befehl <code>info functions</code>). Es sieht jedoch so aus,
als hätte Apple hier die notwendigen Informationen aus dem Programm entfernt.
</p>

<p>
Eine etwas brachialere Möglichkeit ist, das Programm <code>strings</code> auf
iDVD loszulassen. Dieses zeigt alle Ketten von Zeichen an, die länger als 4
Zeichen sind. Da irgendwo im Programm ja der Name sämtlicher Einstellungen
festgehalten sein muss (oder ansonsten über üble Tricks, die Apple bisher nie
nötig hatte, versteckt werden müssten), ist die gesuchte Einstellung – sofern
es sie überhaupt gibt! – in der Ausgabe von <code>strings</code> dabei.
</p>

<p>
Eine Suche nach „DualLayer” ergab dann schließlich das gewünschte Ergebnis: die
Zeichenkette „SupportDualLayerProjects”.
</p>

<p>
Die Einstellungsdatei für iDVD ist <code>com.apple.iDVD</code>. Mit dem
<code>defaults</code>-Befehl können wir im Terminal alle Werte, die dort
gespeichert sind, auslesen. Wer die Developer-Tools installiert hat, kann diese
Datei auch mit dem mitgelieferten Editor grafisch öffnen.
</p>

<p>
Das Überprüfen via <code>defaults read com.apple.iDVD
SupportDualLayerProjects</code> ergibt, dass dieser Wert standardmäßig nicht
gesetzt ist. Setzen wir ihn doch einfach mal via <strong><code>defaults write
com.apple.iDVD SupportDualLayerProjects -bool true</code></strong>. Und wenn
man nun ein neues Projekt öffnet, kann man bei den Projekteinstellungen
„Doppelschichtig” auswählen :-).
</p>
