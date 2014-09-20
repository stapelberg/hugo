---
layout: post
title:  "VoIP mit congster und asterisk"
date:   2007-08-21 10:00:00
categories: Artikel
---



<h2>Vorwort</h2>
<ul>
	<li>
	<a href="http://www.asterisk.org/" title="asterisk"
	target="_blank">Asterisk</a> ist eine freie Open-Source-Telefonanlage, die eine
	sehr flexible Konfiguration und somit sehr viele Möglichkeiten bietet.
	</li>
	<li>
	<a href="http://www.congster.de/" title="congster" target="_blank">Congster</a>
	ist eine Tochterfirma der Telekom, die Internet-Flatrates/Zugänge und nun auch
	eine VoIP-Flatrate ins deutsche Festnetz anbietet.
	</li>
</ul>

<h2>VoIP mit congster und asterisk</h2>
<p>
Da congster auf der Website nur die Einrichtung der Internettelefonie auf den
DSL-Routern der Speedport-Serie beschreibt und ich den ganzen Abend lang –
letztendlich doch noch erfolgreich – damit verbrachte, asterisk zu
konfigurieren, habe ich diese Schritte zu einem Artikel zusammengefasst, damit
das lange Herumprobieren dem geneigten Benutzer erspart bleibt.
</p>

<h2>Die Zugangsdaten</h2>
<p>
Nachdem man im Kundenbereich bei congster die TelefonFlat zum Tarif
hinzugebucht hat (oder diese neu bestellt, falls man noch keine Flatrate bei
congster hat), wird man um die Einrichtung einer E-Mail-Adresse gebeten. Diese
E-Mailadresse dient später auch zur Identifikation am Telefonieserver von
congster.
</p>

<p>
congster teilt einem also folgende Daten mit:
</p>
<ul>
	<li>
	Die eigene VoIP-Rufnummer, beginnend mit +49-32 oder 032: in unserem
	Beispiel 032123456789
	</li>
	<li>
	Die vollständige E-Mail-Adresse sowie das Passwort: in unserem Beispiel
	„heinz@congster.de” und „geheim”
	</li>
	<li>
	Die Serveradressen tel.congster.de und stun.congster.de
	</li>
</ul>

<p>
Soweit, so gut. Für Asterisk ist der stun-Server unwichtig, wir benötigen
lediglich tel.congster.de. Dieser Server ist übrigens (momentan?) der selbe wie
der, den T-Online verwendet:
</p>
<pre>tel.congster.de has address 217.0.132.118
tel.t-online.de has address 217.0.132.118</pre>

<h2>Einrichtung des Asteriskservers: sip.conf</h2>

<p>
In der Datei <code>sip.conf</code> muss im Bereich <code>general</code> die
Einstellung <code>defaultexpirey</code> auf einen Wert, der größer oder gleich
240 ist (standardmäß sind es 120 bei Asterisk) gesetzt werden, sonst akzeptiert
der Server die Registration nicht mit der Fehlermeldung <code>423: Timeout too
brief</code>:
</p>
<pre>defaultexpirey =&gt; 240</pre>

<p>
Der register-Eintrag, der ebenfalls in den general-Bereich muss, ist nach
diesem Schema aufgebaut:
</p>
<pre>register =&gt; nummer:mail-passwort:mail-adresse@tel.congster.de/nummer</pre>
<p>
Für unseren Beispielnutzer sähe das dann also so aus:
</p>
<pre>register =&gt; 032123456789:geheim:heinz@congster.de@tel.congster.de/032123456789</pre>

<p>
Nach dem Starten des Asterisks kann man sich nun auf der
Kommandozeilenoberfläche mit dem Befehl sip show registry den Status anzeigen
lassen. Das sollte in etwa so aussehen:
</p>
<pre>*CLI&gt; sip show registry
Host                            Username       Refresh State               
tel.congster.de:5060            032123456789   1785    Registered</pre>

<p>
Anschließend legen wir uns noch den Abschnitt für ausgehende Gespräche an:
</p>
<pre>[congster.de]
type        = friend
secret      = passwort
username    = email-adresse
fromuser    = nummer
fromdomain  = tel.congster.de
host        = tel.congster.de
canreinvite = no
qualify     = no
insecure    = port,invite</pre>

<h2>Einrichtung des Asteriskservers: extensions.conf</h2>

<p>
In der Datei <code>extensions.conf</code> definieren wir dann noch, dass wir
alle Anrufe über congster abwickeln möchten und beheben unsere Caller-ID:
</p>
<pre>exten =&gt; _X.,1,SetCallerID,nummer
exten =&gt; _X.,2,Dial(SIP/${EXTEN}@congster.de,30,trg)
exten =&gt; _X.,3,Hangup()</pre>

<p>
Viel Spaß beim Telefonieren! :-)
</p>
