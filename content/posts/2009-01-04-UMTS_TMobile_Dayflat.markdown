---
layout: post
title:  "UMTS mit T-Mobile web'n'walk DayFlat und einer Vodafone Mobile Connect-Expresscard"
date:   2009-01-04 10:00:00
categories: Artikel
Aliases:
  - /Artikel/UMTS_TMobile_Dayflat
---



<p>
  Da Fonic (o2) in manchen Gegenden kein Netz ausgebaut hat (so auch bei meinen Verwandten),
  kaufte ich mir kürzlich eine T-Mobile xtra web'n'walk DayFlat. Der Tarif ist ganz
  ähnlich zu dem Fonic-Tarif: Für 4,95 € pro Kalendertag (!) kann man das
  T-Mobile-Netz verwenden. Das Guthaben wird ebenfalls im Voraus aufgeladen, eine
  Grundgebühr oder Einrichtungsgebühr gibt es nicht. Für die Karte inklusive
  10 € Startguthaben zahlt man 20 €. Man muss sich dabei mit dem Personalausweis
  identifizieren, gespeichert werden Vorname, Nachname, Straße, Hausnummer,
  Postleitzahl, Wohnort, Ablaufdatum- und Nummer des Personalausweises.
</p>

<h2>Aktivierung</h2>

<p>
  Bis die Karte benutzt (und auch aufgeladen) werden kann, vergehen mindestens ein paar
  Minuten bis hin zu einem Tag. Falls du die Karte in einem T-Mobile-Laden kaufst, können
  die Mitarbeiter dir nicht sagen, wie lange die Karte noch braucht, bis sie benutzbar ist
  – bei ihnen wird angezeigt, dass die Karte bereits aktiv sei.
</p>

<p>
  Bei der ersten Verbindung wird man entweder auf www.t-mobile.de geleitet oder muss diese
  Seite manuell aufrufen, das weiß ich nicht, da dies der Mitarbeiter im T-Mobile-Laden
  für mich erledigte. Dort bekommt man dann die Auswahl gestellt, ob man den Speed-
  Manager benutzen möchte, was ich unter Linux natürlich nicht möchte ;-).
  Vermutlich schaltet diese Option einen transparenten Proxy ein, der Grafiken und
  Dateien zusätzlich komprimiert, sodass alles schneller geladen wird.
</p>

<h2>Hardware/Konfiguration</h2>
<p>
  Ich benutze die SIM-Karte in einer Vodafone Mobile Connect UMTS-Expresscard (Qualcomm 3G,
  Merlin U630), mit der ich bereits die Fonic-Karte benutzte.
</p>

<p>
  Die Konfiguration (<a href="/Config/wvdial.conf">wvdial.conf, direkt herunterladen</a>)
  stammt von <a href="http://www.xxzz.de" target="_blank">SdK</a> und wurde nur unwesentlich
  verändert:
</p>
<pre>
[Dialer defaults]
Init1 = ATZ
Init2 = AT Q0 V1 E1 S0=0 &C1 &D2 &V +FCLASS=0
Init3 = AT+CGEQMIN=1,4,64,384,64,384
Init4 = AT+CGEQREQ=1,4,64,384,64,384
Init5 = AT+CGQREQ=1,3,4,3,7,31
Init6 = AT+IFC=2,2
Init7 = AT+CGDCONT=3,"IP","internet.t-mobile","",0,0
Dial Command = ATDT
Phone = "*99***1#"
Modem = /dev/ttyUSB0
 
Baud = 230400
Stupid Mode = 1
FlowControl = NOFLOW
SetVolume = 0
ISDN = 0
Password = tm
Username = t-mobile
Model Type = Analog Model
Modem Type = Analog Modem
Dial Attempts = 3
Auto DNS = 0
Check DNS = 0
New PPPD = yes
 
[Dialer sig]
Modem = /dev/ttyUSB0
Init2 = AT+CSQ
</pre>

<h2>Fakten</h2>

<ul class="wide_list">
  <li>
    Entgegen der Aussage einer Mitarbeiterin beim T-Mobile-Support (Kurzwahl 2202) funktioniert
    die Karte nicht nur mit dem Surfstick von T-Mobile, sondern mit jeder Karte (mindestens
    mit der oben erwähnten Vodafone Mobile Connect und der Ericsson F3507g).
  </li>
  <li>
    Eine Zwangstrennung um 24:00 (Beginn einer neuen Abrechnungsphase) findet nicht statt
    (bei Fonic übrigens auch nicht).
  </li>
  <li>
    Der Support, an den sich die Mitarbeiter bei T-Mobile wenden (die übrigens sehr nett
    waren), bezeichnet Linux als „Selbstbau-Betriebssystem”. Dass einige große
    Firmen hinter Linux stehen und auch T-Mobile vermutlich mehr Linux verwendet als sie
    denken, kam ihnen wohl nicht in den Sinn.
  </li>
  <li>
    Wenn man die Karte in ein normales Mobiltelefon (Nokia 6230i) steckt, kommt nach kurzer
    Zeit eine Abfrage, ob die SIM-Karte eine Nachricht senden dürfe. Weiterhin kommt
    später eine Nachricht, die die eigene Nummer beinhaltet. Wenn jemand weiß,
    was das ist und wozu es gut ist, möge er mich bitte informieren ;-).
  </li>
</ul>
