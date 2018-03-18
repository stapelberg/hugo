---
layout: post
title:  "SSH-fähiges Terminal"
date:   2007-08-21 10:00:00
categories: Artikel
Aliases:
  - /Artikel/SSH_faehiges_Terminal
---




<h3>Warum? Es gibt doch Terminal.app!</h3>

<p>
Das normale Terminal(.app) funktioniert zwar recht schnell und sieht ganz gut
aus (auch die Farben werden relativ gut dargestellt), doch es hat einige
Probleme, was es für den Einsatz von SSH unbrauchbar macht. Eine Alternative
muss also her. Eine kurze Suche auf <a href="http://www.macupdate.com/"
target="_blank" title="MacUpdate">macupdate.com</a> bringt <a
href="http://www.macupdate.com/info.php/id/10301" target="_blank"
title="MacUpdate: iTerm">iTerm</a> zum Vorschein.
</p>

<p>
iTerm kann man aufgrund seiner "Vielfalt" (naja, nicht wirklich viel, aber im
Vergleich zu Terminal.app... ;-)) empfehlen, ganz klar schlecht ist es jedoch
in der Konfiguration, weshalb ich mich auch dafür entschieden habe, dieses –
zugegebenermaßen kurzes und relativ sinnloses (Programmbedienung erklären?
Nunja...) – Tutorial zu schreiben ;-). Vielleicht hilft’s ja jemandem, der es
zufällig findet...
</p>

<p>
<strong>Update:</strong> Mittlerweile habe ich funktionierende Umlaute für
SSH-Verbindungen auf ein ISO-8559-System auch im normalen Terminal einstellen
können. Dazu muss man einfach „Fenstereinstellungen” → „Darstellung”
→ „Zeichensatz-Codierung” auf Latin-1 umstellen und für die Eingabe von
Sonderzeichen das Häckchen bei „Fenstereinstellungen” → „Emulation” →
„Nicht-ASCII-Zeichen in Escape-Sequenz umwandeln” entfernen. Was das für
Auswirkungen auf die direkt auf Mac OS X laufenden Konsolenanwendungen hat,
kann ich aber (noch) nicht sagen… Für diese Methode müssen übrigens auch die
folgenden Optionen in der Datei <code>~/.inputrc</code> gesetzt sein:
</p>
<pre>
set meta-flag on
set convert-meta off
set output-meta on
set input-meta on
set show-all-if-ambigous on
</pre>


<h3>Installation</h3>
<p>
Sobald man iTerm wie jedes andere OS X-Programm installiert (einfach in den
Programme-Ordner ziehen) und zum ersten mal öffnet, hat man ein dem
Terminal.app-Fenster recht ähnlich aussehendes Fenster vor sich. Gleich
auffallend: die Transparenz.
</p>
<a href="/Bilder/SSH_faehiges_Terminal/iTerm_screenshot1.jpg" title="Screenshot
1" target="_blank"><img width="322" height="120"
src="/Bilder/SSH_faehiges_Terminal/iTerm_screenshot1_thumb.jpg"></a><br>
<small>Standardfenster in iTerm</small>

<h3>Grundsätzliche Konfiguration</h3>
<a href="/Bilder/SSH_faehiges_Terminal/iTerm_screenshot2.jpg" title="Screenshot
2" target="_blank"><img
src="/Bilder/SSH_faehiges_Terminal/iTerm_screenshot2_thumb.jpg" align="left"
style="margin-right: 5px"></a>
<p>
iTerm unterscheidet zwischen Profilen und Einstellungen, die nur für das aktive
Fenster gelten. Die Einstellungen für das aktive Fenster kann man - das ist
noch recht einfach - über Tools → Konfigurieren erreichen. Üblicherweise
stellt man unter Session → Kodierung erstmal UTF-8 aus (zumindest, wenn man
mit etwas älteren Systemen kommunizieren möchte via SSH), empfehlenswert ist zb
„Westeuropäisch (ISO Latin 9)” (deutsche Umlaute mit Eurozeichen) oder gleich
„Westeuropäisch (Windows Latin 1)”. Des Weiteren könnte die geglättete Schrift
nerven (je nach dem, ob man es gewohnt ist, oder eher auf Linux-Terminals/PuTTY
unter Windows gearbeitet hat), die man wie folgt deaktiviert: unter Fenster
→ Schrift und Nicht-ANSI-Schrift die selbe Schrift wählen (um ein
einheitliches Schriftbild zu aktivieren) und anschließend den Haken bei
Schriftglättung entfernen. Ich benutze als Schrift die voreingestellte Monaco
in Größe 10. Wer eine gute Terminalschrift kennt, möge mir doch bitte bescheid
sagen :-).
</p>

<p>
Damit diese Einstellungen nun auch für neue Fenster greifen, muss man sie als
Profil abspeichern. Dazu geht man auf iTerm → Einstellungen → Allgemein
→ Profile. Man findet hier die selben Einstellungen wie bei der
fensterbasierten Konfiguration, es ist noch ein weiteres Tab mit
Tastatureinstellungen vorhanden.
</p>

<h3>Lesezeichen</h3>
<p>
Sobald man mit den Profileinstellungen fertig ist, kann man sich sogenannte
Lesezeichen anlegen. Diese lassen sich mit Tastaturabkürrzungen versehen,
sodass man zum Beispiel durch Alt+Apfel+S ein neues Tab (wenn man Shift drückt,
ein neues Fenster) Öffnet, in dem man sich automatisch mit seinem Server
verbindet und eine screen-session Öffnet. Doch Schritt für Schritt: zuerst
öffnet man die Lesezeichen via iTerm → Einstellungen → Lesezeichen.
Dort kann man nun die vorhandenen Lesezeichen (außer Rendezvous, was eine Art
Autokonfiguration ist) bearbeiten/löschen. Für uns interessant ist das Anlegen
neuer Lesezeichen, was über den Knopf mit dem Plus geschieht. Nun kann man das
Lesezeichen betiteln und einen Befehl eingeben. Hier kann man nun einen ganz
normalen SSH-aufruf verwenden, zum Beispiel "ssh -t benutzer@192.168.1.2 screen
-r" um eine SSH-Verbindung mit 192.168.1.2 unter dem Benutzernamen "benutzer"
herzustellen und dort sofort die letzte Screen-session wiederaufzunehmen. Den
Parameter "-t" muss man angeben, damit ein virtuelles Terminal geöffnet wird -
ohne funktioniert screen nicht. Weiter unten kann man dann die vorher
gespeicherten Terminal- und Darstellungsprofile auswählen. Weiterhin
interessant ist die Option Tastenkürzel. Wir stellen hier "S" ein und
bestätigen die Dialoge mit "OK".
</p>

<p>
So - jetzt können wir iTerm noch im Dock behalten (mit rechter Maustaste/lange
auf das iTerm-Symbol im Dock klicken und "im Dock behalten" wählen) und haben
in Zukunft einen kurzen Weg zur letzten Screensession: iTerm öffnen,
Alt+Apfel+S drücken - fertig :-).
</p>

<p>
Als kurze Hintergrundinformation: screen hat die nützliche Funktion, sessions
zu "speichern", das heißt, wenn man die session mittels "screen -r" wieder
aufnimmt, ist man dort, wo man beim "detachen" aufgehört hat (was automatisch
beim Trennen der Verbindung passiert).
</p>

<h3>Ihr seid dran!</h3>
<p>
Wenn sich jemand gerade denkt, dass iTerm doch wirklich nicht mehr zeitgemäß
ist und es doch viel bessere Terminals gibt: ich hab’ eine Feedback-Funktion zu
jedem meiner Artikel - benutzt sie! :-)
</p>

<h3>Weitere Informationen</h3>
<ul>
	<li>
	<a href="http://www.schlittermann.de/ssh" target="_blank" title="SSH
	ohne Passwort">SSH ohne Passwort (auf Public/Private-Key basierend)</a>
	</li>

	<li>
	<a href="http://www.openssh.com/manual.html" target="_blank"
	title="OpenSSH-Manpages">OpenSSH-Manpages</a> (Englisch; besonders
	ssh/ssh_config ist interessant)</a>
	</li>

	<li>
	<a href="http://www.pl-berichte.de/berichte/hurd/screen.html"
	target="_blank" title="Screen-Einführung auf Deutsch">Screen-Einführung
	auf Deutsch</a>
	</li>
</ul>
