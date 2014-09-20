---
layout: post
title:  "Startschwierigkeiten"
date:   2007-09-07 10:00:00
categories: Artikel
---



<p>
Als ich meinen neuen Rechner „A64” gekauft und zusammengebastelt habe,
erwarteten mich im Laufe der Zeit so einige Probleme. Damit nicht jeder mit
einer ähnlichen Zusammenstellung (könnt ihr euch bei „Meine PCs” ansehen, am
wichtigsten ist wohl aber das Mainboard: ASUS A8N-SLI) die selben Schritte
durchlaufen muss, habe ich mich entschlossen, die Probleme und deren Lösung
niederzuschreiben.
</p>

<h2>nForce 4: „Nee, die Audigy 2 ZS mag ich nicht, nimm gefälligst meine Onboardkarte!”</h2>
<p>
Das erste Problem äußerte sich durch sporadische Bluescreens, bei denen
allerdings kein sinnvoller Hinweis auf die verursachende Komponente zu finden
war, lediglich der Name eines Treibers meines Mainboards tauchte auf. Ein
Absturz, der durch das Mainboard selbst hervorgerufen wird, wäre meiner Meinung
nach aber äußerst ungewöhnlich, gerade bei dem (damals?) beliebten nForce
4-Chipsatz.
</p>
<p>
Um dies trotzdem als Fehlerquelle auszuschließen beschloss ich, die Software
(sprich: Treiber, Firmware) auf den neuesten Stand zu bringen. Leider gestalte
sich dies aufgrund der Verbreitungsmethode/Internetanbindung der Server von
ASUS als etwas schwierig: Die benötigten Dateien waren auf dem europäischen und
auf dem USA-Mirrorserver nicht vorhanden. So musste ich dann mit ganzen 3 KB/s
(bei 720 möglichen KB/s!) das Update laden, nur um später festzustellen, dass
sich angeblich gar kein ASUS-Board in diesem Rechner befindet. Was hab ich denn
dann eingebaut?
</p>
<p>
Nun gut, also kein BIOS-Update. Stattdessen überlegte ich also, was ich denn
zeitweise ausbauen könnte. Außer der Soundkarte (eine Creative Audigy 2 ZS)
wurden aber alle Komponenten zwingend zum Betrieb benötigt. Ich habe also die
Soundkarte ausgebaut und hatte seitdem tatsächlich keine Abstürze mehr. Eine
kurze Google-Suche verriet mir, dass nicht nur ich mit dieser Soundkarte in
Kombination mit diesem Board Probleme hatte: Die Treiber von Creative seien
Schuld an den Abstürzen, eine Lösung nicht bekannt. Seitdem benutze ich die
Onboard-Soundkarte…
</p>

<p>
<strong>Update:</strong> Seitdem ich Linux benutze, funktioniert die Soundkarte
wunderbar :-).
</p>

<h2>„Beim ersten Rufen reagiere ich grundsätzlich nicht…”</h2>
<p>
Nach einiger Zeit trat dann ein ganz anderes Problem auf: Als ich den Rechner
wie üblich morgens vor der Schule einschalten wollte, blieb der Bildschirm
einfach schwarz. Erst nachdem ich den Einschaltknopf mehrmals betätigte (mit
Strom aus-/einschalten zwischendrin) fuhr der Rechner wieder hoch. Nach einigen
Auftritten des Problems tat er das jedoch gar nicht mehr. Nach dem
obligatorischen Prüfen, ob denn alle Kabel festsitzen, die Grafikkarte richtig
eingesteckt ist und der CPU-Kühler läuft, baute ich den RAM aus und wieder ein
und siehe da: Es geht wieder.
</p>

<p>
Doch das Problem sollte nicht nur einmal auftreten. In unregelmäßigen Abständen
zeigten sich die selben Symptome, die durch die selbe „Lösung” wieder
verschwanden. Ich suchte also im BIOS nach Einstellmöglichkeiten und stolperte
über die RAM-Timings. Diese standen bislang auf „Auto”, also stellte ich sie
einfach fix ein, aber mit genau den Werten, die auch Everest vom SPD ausließt.
Seitdem trat auch dieses Problem nicht mehr auf.
</p>

<p>
Als ich dann im März 2006 neuen, zusätzlichen RAM einbauen wollte, traf ich auf
ein ähnliches Problem: Nach einigen Stunden erfolgreichem Betrieb teilte
Windows mit, dass ein Speicherfehler in Opera aufgetreten sei, kurz darauf im
Explorer und nach Bestätigung des Dialogs folgte der Bluescreen. Statt
hochzufahren piepste der Rechner nur noch bei erneutem Einschalten. Sobald ich
die neuen Speichermodule ausbaute, funktionierte es wieder. Auch das
Zurückstellen der Timings auf „Auto” brachte nichts.
</p>

<p>
<strong>Im PC-Laden wurde mir dann geraten, die Spannung etwas hochzusetzen,
das funktioniert auch sehr gut und scheint die Lösung für alle meine bisherigen
Speicherprobleme zu sein.</strong>
</p>

<h2>„Zwei Grafikkarten? Dann kriegst du aber nur 1,5 GB von 2 GB RAM!”</h2>

<p>
Seitdem ich eine zweite Grafikkarte (identischen Typs, also zwei GeForce
7600GS) eingebaut habe, erkennt das Mainboard nur noch 1,5 von 2 GB verbautem
Speicher. Im BIOS steht zwar, dass 2048 MB installed sind, beim Starten
erscheinen jedoch nur 1536 MB OK.
</p>

<p>
Zuerst dachte ich, dass einer der RAM-Riegel kaputt sei, was ich dann durch
einzelnes Testen in <a href="http://www.memtest86.com/" title="Memtest 86"
target="_blank">memtest86</a> ausschließen konnte.
</p>

<p>
Das Ausbauen der Grafikkarte brachte dann komische Effekte mit sich. So
startete der PC bei ausgebauter Grafikkarte gar nicht mehr (obwohl er vorher
problemlos funktionierte – wird da etwa ein Zustand irgendwo gespeichert oder
wie kann man sich das erklären?!).
</p>

<p>
Zu guter letzt half mir dann ein BIOS-Update (auf das aktuelle Beta-BIOS 1604
von der ASUS-Website). Geflasht habe ich es mit einer <a
href="http://www.freedos.org/" title="FreeDOS"
target="_blank">FreeDOS-Installations-CD</a>, welche meinen USB-Stick erkannte
– superpraktisch, wenn man kein Diskettenlaufwerk mehr hat :-).
</p>

<p>
Nach dem problemlosen Update (vorher lief übrigens Version 1001) erkannte das
Board wieder die vollen 2048 MB und das sogar im Dual-Channel mit DDR400!
Vorher ging in der Konfiguration nur DDR333. Auch mit den neuen Timings, die
nach dem BIOS-Update automatisch von „Auto” auf eine feste, schnellere
Konfiguration erhöht wurden, laufen stabil.
</p>

<p>
<strong>Fazit:</strong> Aktuelles BIOS und eine leicht erhöhte RAM-Spannung
helfen bei Modul-Vollausbau :-).</strong>
</p>

<h2>Suspend-to-RAM unter Linux</h2>
<p>
Damit ich den Rechner nicht immer komplett hochfahren muss und ihn trotzdem
abends ausschalten kann, möchte ich Suspend-to-RAM benutzen. Unter Linux mit
aktuellen Kernel sollte das recht einfach funktionieren:
</p>
<pre>echo mem &gt; /sys/power/state</pre>
<p>
Allerdings kommt der Rechner dann zwar nach betätigen des Einschaltknopfs
wieder hoch, jegliche Befehle, die mit Festplattenzugriffen zu tun haben,
hängen jedoch einfach so (also leider auch dmesg, strace, und sonstige
hilfreiche Tools zum Fehlerfinden).
</p>

<p>
Das könnte an der Kernel-Version liegen, dachte ich (2.6.20-gentoo-r8), und
installierte 2.6.22.6 (der neuste stabile Kernel zum Zeitpunkt des Schreibens).
Allerdings funktioniert hier das Suspend gar nicht, ich sehe nur einen
blinkenden Cursor auf schwarzem Bildschirm, der Rechner schaltet sich aber
nicht aus.
</p>

<p>
Jegliche Optionen wie <code>noapic</code> oder
<code>acpi_sleep=s3_bios,s3_mode</code> halfen nichts, Tipps, die auf X oder
proprietäre Grafiktrieber anspielten, ignorierte ich erstmal, denn die
grafische Oberfläche war zum Zeitpunkt des Testens noch nicht mal geladen.
</p>

<p>
Des Rätsels Lösung fand ich dann schließlich auf der Kernel-Mailingliste: <a
href="http://lkml.org/lkml/2007/1/3/249" title="Linux Kernel Mailingliste:
Patch für sata_nv" target="_blank"><strong>Ein Patch für den Treiber
<code>sata_nv</code>, welcher Suspend/Resume-Unterstützung
bereitstellt</strong></a>. Nachdem ich diesen dann angewendet hatte und den
neuen Kernel installierte, funktioniert’s auch einwandfrei wie oben beschrieben
mit dem Suspend :-). (Die <code>acpi_sleep</code>-Option hab’ ich trotzdem
dringelassen, ich weiß leider nicht, ob’s auch ohne geht).
</p>
