---
layout: post
title:  "Positive Erfahrungen mit dem irischen ISP Magnet"
date:   2011-10-26 20:47:00
categories: Artikel
Aliases:
  - /Artikel/magnet_erfahrungen
---



<h2>Überblick und Verfügbarkeit</h2>

<p>
Wasser, Strom und Heizung sind bei Apartments in Irland oftmals standardmäßig
im Mietpreis enthalten, weiterhin sind Wohnungen normalerweise möbliert. Das
einzige, was also offensichtlich fehlt, ist Breitband-Internet :-). Es gibt
einige ISPs, die in Dublin verschiedenste Arten von Internetzugang anbieten.
Deutlich weiter als auf dem deutschen Markt (soweit ich das beurteilen kann)
ist WiMAX, was von <a href="http://www.imagine.ie/">imag!ne</a> angeboten wird.
Ansonsten gibt es Kabel, UMTS, Fiber to the home (in wenigen Gebieten) und
natürlich ADSL. Interessanterweise ist das UMTS-Netz übrigens sehr latenzarm im
Vergleich zu den deutschen Netzen, die ich bisher benutzte. In der Regel hatte
ich Pingzeiten von ca. 75 ms (bei <a href="http://www.three.ie/">Three</a>) bis
zu 50 ms (bei <a href="http://www.vodafone.ie/">vodafone</a>). Einige Iren
haben deshalb garkeinen drahtgebundenen Internetanschluss, sondern gehen über
USB-Modems online.
</p>

<p>
Leider sind die Verfügbarkeitstests auf den Websites der meisten ISPs so
ausgelegt, dass man entweder eine Festnetzrufnummer braucht (in meiner Wohnung
ist kein Telefon angeschlossen) oder der Test kannte meine Adresse nicht. Am
Telefon konnte man mir dann aber weiterhelfen: ADSL2+ mit <strong>bis
zu</strong> 24 MBit/s sei verfügbar. Am 30. September habe ich also bestellt
(telefonisch, man muss nichts unterschreiben oder sonstige Nachweise erbringen,
was für irische Verhältnisse untypisch ist) und erhielt kurze Zeit später die
Bestätigung via E-Mail. Überrascht war ich, als ich am selben Tag auch eine SMS
bekam, in der mich Magnet (der ISP) als Kunde begrüßte und mir versprach,
binnen 10 Werktagen die Leitung zu schalten. Von einem deutschen Unternehmen
hätte ich das nicht erwartet, oder, wenn überhaupt, für eine zusätzliche
SMS-Gebühr ;-).
</p>

<h2>Anschluss der Leitung</h2>

<p>
Wenige Tage später erreichte mich dann per Post das Welcome Pack - ein Modem,
Telefonkabel, Netzwerkkabel, Netzteil und ein spärliches Handbuch, wie man mit
Windows und Mac OS X die WLAN-Verbindung einstellt. Zu diesem Zeitpunkt
funktionierte der Anschluss noch nicht; die Link-LED blinkte noch nichtmal
(laut Handbuch blinkt sie beim Versuch, sich zu synchronisieren). Auf
telefonische Nachfrage hin teilte man mir mit, dass am 13. Oktober der
Anschluss von Eircom (dem Äquivalent zur Telekom) geschaltet würde und dass die
Leitung vorher einfach tot sei, ein ausbleibender Synchronisierungsversuch also
normal.
</p>

<p>
Am 13. rief mich dann gegen Mittag auch tatsächlich ein Techniker von Eircom an
und fragte, ob ich zuhause sei. Das sei zwar nicht unbedingt nötig, aber es
würde ihm helfen, denn er hat die Leitung im Exchange geschaltet und würde nun
gerne testen, ob bei mir auch etwas ankommt. Wenige Minuten später demontierte
er dann die Buchse an meinem Telefonanschluss und stellte fest, dass das
Testsignal (ein Piepsen) ankommt. Er schraubte die Buchse wieder an und
erklärte mir, dass er in ca. 30 Minuten wieder beim Exchange sei, das
Testsignal abstellen werde, und anschließend mein Zugang funktionieren sollte.
</p>

<p>
Genauso verhielt sich das dann auch. Etwa 30 Minuten später blinkte die
Link-LED und stellte eine Verbindung her :-). Die ganze Erfahrung fand ich
ziemlich positiv. Bei deutschen Anbietern meldet sich (meiner Erfahrung nach)
bei der Leitungsanschaltung kein Techniker und das Signal wird auch nicht
verifiziert. Dass die Leitungsanschaltung problemlos klappte, hätte ich auch
nicht unbedingt erwartet. Die Garantie von 10 Werktagen wurde damit einwandfrei
eingehalten.
</p>

<h2>Das Modem</h2>

<p>
Das von Magnet bereitgestellte Modem stellt WLAN bereit und bietet
Anschlussmöglichkeiten für 4 Ethernet-Kabel, ein USB-Gerät und zwei Telefone.
Von der Funktionalität her zu urteilen ist es also Router und Modem in einem.
Allerdings bekam ich (bevor die Leitung geschaltet war) keine Adresse via DHCP
zugewiesen. Beim Starten des Modems meldet es sich kurz unter der Adresse
192.168.1.1, antwortet aber nur auf einen Ping und ist danach unerreichbar.
Auch das WLAN-Netz hieß (entgegen anderslautender Information in der
Willkommens-Email) einfach MAGNET.
</p>

<p>
Des Rätsels Lösung ist, dass Magnet die Firmware so modifiziert hat, dass die
Funktionen dem Nutzer nicht direkt über eine Schnittstelle zur Verfügung
stehen. Stattdessen konfiguriert sich das Modem nach der ersten Verbindung
selbstständig (die SSID ändert sich, ein Passwort wird konfiguriert).
Anschließend spuckt es für jedes anfragende Gerät via DHCP je eine öffentliche
IP-Adresse aus. Ich habe das mit drei Geräten gleichzeitig getestet,
Adressmangel scheint es bei Magnet also nicht zu geben ;-). PPPoE-Zugangsdaten
musste ich übrigens nicht eingeben. Das Gerät funktioniert einfach direkt nach
dem Einstecken, ohne dass der Hersteller die Firmware für jeden Kunden anpassen
muss.
</p>

<p>
Der Ansatz, das Gerät komplett fernzuwarten und keinerlei durch den Benutzer
einzustellende Optionen zu haben, macht es für Magnet natürlich deutlich
einfacher. Ein offensichtlicher Nachteil ist natürlich, dass der Benutzer das
WLAN-Passwort nicht ändern kann, ohne den Provider zu bitten. Weiterhin ist die
Tatsache, dass das Gerät kein NAT macht aus technischer Sicht zu begrüßen, hat
aber den unangenehmen Nebeneffekt, dass man, nachdem man den Computer aus dem
Standby aufweckt, erstmal einige Zeit warten muss, bis man eine aktuelle
IP-Adresse bekommt (die alte wurde zwischenzeitlich neu vergeben). Eine bessere
Lösung ist die von deutschen Kabel-Anbietern, nämlich die IP-Adresse(n) auf dem
Modem zu behalten und immer wieder herauszugeben. Auch schon eine deutlich
höhere Leasetime würde hier helfen.
</p>

<p>
Abschließend finde ich den von Magnet gewählten Ansatz technisch simpel und
bestechend, er ist aber in der Praxis nicht ganz so komfortabel (für meine
Anwendung) wie andere Lösungen. Insbesondere die Tatsache, dass viele Iren
letztendlich einen zusätzlichen Router kaufen und somit quasi zwei identische
Geräte betreiben, kann man (u.a. aus Energiespargründen) nicht wirklich als
sinnvoll erachten.
</p>

<h2>Geschwindigkeit und Stabilität</h2>

<p>
Von meinen Kollegen wurde ich gewarnt, dass die Internetleitungen hier oftmals
überbucht sind. Offenbar betrifft das nicht nur inhärent geteilte Medien wie
Kabel sondern auch die Anbindung der DSLAMs. An der Latenz und Stabilität habe
ich nichts zu bemängeln. Interaktive Anwendungen auf deutschen Servern sind
problemlos zu benutzen. Stabilitätsprobleme hatte ich lediglich einmal, als
sich das Modem für ca. 5 Minuten nicht synchronisieren konnte.
</p>

<p>
Die erreichte Bandbreite auf meinem (bis zu 24 MBit/s-)Anschluss liegt bei ca.
9 MBit/s. Auf telefonische Nachfrage hin wurde mir mitgeteilt, dass mein
Anschluss (vermutlich aufgrund von Entfernung zum DSLAM) ca. 10 MBit/s
unterstützt und deshalb auf 9.2 MBit/s eingestellt wurde, damit er stabil
läuft. Mit so einer direkten Aussage hätte ich nicht gerechnet – bei deutschen
ISPs kriegt man die, meiner Erfahrung zufolge, nur als Geschäftskunde wenn man
etwas nachhakt. Der Upload beträgt übrigens 1 MBit/s.
</p>

<h2>Fazit</h2>

<p>
Magnet hat ein attraktives Angebot und ist ganz klar ein eher technischer ISP
(in der Art, wie sie mit ihren Kunden kommunizieren). Positiv überrascht war
ich von der Offenheit und dem technischen Verständnis des Supports. Einen
leicht negativen Beigeschmack hat das Modem, die Beweggründe dafür sind aber
verständlich. Bisher hat alles gut geklappt und ich hoffe, dass das so bleibt
:-).
</p>
