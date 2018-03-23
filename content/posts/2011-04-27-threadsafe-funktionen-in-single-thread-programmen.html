---
layout: post
date: 2011-04-27 17:20:00 +01:00
title: "Threadsafe Funktionen in Single-Thread-Programmen"
---
<p>
<a href="http://i3wm.org/i3status/">i3status</a> ist ein Programm, welches
Systeminformationen wie die aktuelle IP-Adresse, freien Speicherplatz und auch
die Uhrzeit ausgibt. Merovius bemerkte vor einer Weile den Bug, dass die
Uhrzeit unter bestimmten Umständen doppelt ausgegeben wird. Das lag daran, dass
die Uhrzeit zuletzt ausgegeben wurde (also nachdem alle anderen
Systeminformationen ermittelt wurden). Wenn diese Ermittlung zu lange dauert,
resultiert das in einer falschen Zeitausgabe. <a
href="http://code.stapelberg.de/git/i3status/commit/?id=4fa8a4e0ab52d5e804e3d85c04281d392c767b22">Behoben
wurde dieser Fehler</a> also, indem man die Uhrzeit als allererstes speichert
und dann später ausgibt.
</p>

<p>
Mit der neuen Version zeigte sich allerdings ein neuer Fehler: Die Uhr
sprang alle paar Sekunden einfach so mal vor, mal zurück. Außerdem ging sie um
wenige Stunden (!) falsch. Es stellt sich heraus: Wenn kein Netzteil am
Computer angeschlossen war (er also auf Akku lief), wurde statt der Uhrzeit der
Zeitpunkt angezeigt, an welchem der Akku leer ist. Das liegt daran, dass beide
Ausgaben die Funktion <tt>localtime(3)</tt> nutzen, welche einen Pointer auf
eine statisch allokierte <tt>struct tm</tt> zurückgibt. Der zweite Aufruf
überschrieb daher die Uhrzeit des ersten Aufrufs, weswegen zweimal der
Zeitpunkt des leeren Akkus angezeigt wurde.
</p>

<p>
<a
href="http://code.stapelberg.de/git/i3status/commit/?id=28934ef858e094bac998556df85a082bee923a96">Die
Lösung</a> war also, die threadsafe-Variante <tt>localtime_r</tt> zu benutzen –
obwohl in i3status garkeine Threads verwendet werden :-).
</p>
