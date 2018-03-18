---
title: "c128_kasse"
date: 2014-11-07T09:49:22+01:00
---

<img src="/Bilder/c128_kasse.jpg" align="right" width="400" height="358"
 title="Kassensystem auf der RGB2Rv5" alt="Kassensystem auf der RGB2Rv5"
 style="margin: 1em; border: 1px solid #b5b5b5;">

<p>
Zum Abrechnen auf unserer Retrogames-Party <a href="http://rgb2r.noname-ev.de/"
title="RGB2R">RGB2R</a> haben Matthias, Jakob und ich ein Kassensystem für den
Commodore C128 (1985 – der ist älter als ich!) in C geschrieben.
</p>

<p>
Das System nutzt einige Funktionen des C128 aus: Die Verkäufe werden auf Papier
via Nadeldrucker und auf einer Diskette mitgeloggt. Außerdem werden beide
Bildschirme benutzt (damit der Kunde sieht, dass sein Guthaben belastet wurde
und wieviel er noch hat). Wie schon angedeutet ist damit bargeldloses Zahlen
möglich, sofern man vorher ein Guthaben einzahlt :-).
</p>

<p>
Selbstverständlich ist das System in VICE lauffähig, aber das richtige Feeling
kommt erst auf Original-Hardware auf. Einige Leute fanden das charakteristische
Geräusch von Floppy und Nadeldrucker so cool, dass sie fast nur deswegen noch
mehr Getränke kauften ;-).
</p>

<h2>Die Uhrzeit</h2>

<p>
Der C128 hat eine eingebaute Uhr, die allerdings zuerst initialisiert werden
muss. Bei jedem Start des Kassenprogramms muss man also die aktuelle Uhrzeit
eingeben. Die lustigen Berechnungen in set_time und get_time (c128time.c) haben
wir übrigens aus BASIC übersetzt und in einer alten C64-Zeitschrift gefunden
:-).
</p>

<h2>Effizientes Programmieren</h2>

<p>
Interessant ist es, sich die Dokumentation zu cc65 anzuschauen, die wirklich
sehr starke Richtlinien gibt, wie man den Prozessor/Speicher am besten
ausnutzen kann, zum Beispiel durch das Zusammenfassen der Variablen gleichen
Typs, Zusammenfassen von zu initialisierenden und nicht zu initialisierenden
Variablen. Außerdem muss man natürlich extrem sparsam sein was die Datentypen
angeht. Zudem macht es hier einen Unterschied, ob man pre-inkrement oder
post-inkrement verwendet (++i gegen i++) etc…
</p>

<h2>Die Qual der Wahl</h2>

<p>
Bei der C-Library von cc65 muss man sich für manche Funktionen entscheiden:
Wenn man cprintf() verwenden will, kann man kein open() mehr verwenden, sondern
muss auf die cbm_open-Funktionen zurückgreifen. Ebenso funktionierte unser
Programm nicht mehr, sobald wir unistd.h eingebunden hatten, daher mussten wir
den Prototyp für sysremove direkt einbinden.
</p>

<h3>Herunterladen</h3>
<ul id="downloads"><li><a class="download_filename" href="/c128_kasse-1.1.tar.gz"><span class="download_name">c128-kasse 1.1 (SVN r91)</span></a> (<span class="download_size">18K</span>, <a class="download_gpg" href="/c128_kasse-1.1.tar.gz.asc">GPG-Signatur</a>)</li><li><a class="download_filename" href="http://code.stapelberg.de/git/c128-kasse/snapshot/rgb2rv9.tar.bz2"><span class="download_name">Stand von der RGB2Rv9</span></a></li></ul>

<h3>Lizenz</h3>
<p><span class="name">c128_kasse</span> ist freie Open-Source-Software unter der <span class="license">BSD-Lizenz</span>.</p>
<div id="development">
	<h3>Entwicklung</h3>
	<p>Der aktuelle Entwicklungsstand kann <a class="dev_url" href="http://code.stapelberg.de/git/c128-kasse/">in gitweb</a> verfolgt werden.</p>
</div>

<h3>Feedback</h3>
<p>Solltest du mir eine Nachricht zukommen lassen wollen, <a href="/Impressum">schreib mir doch bitte eine E-Mail</a>.</p>
</div>
