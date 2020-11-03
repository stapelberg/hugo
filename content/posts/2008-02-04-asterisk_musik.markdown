---
layout: post
title:  "Asterisk & cmus: Musik automatisch unterbrechen"
date:   2008-02-04 10:00:00
categories: Artikel
Aliases:
  - /Artikel/asterisk_musik
---

Wer gerne Musik hört und oftmals angerufen wird kennt sicherlich das Problem,
dass man die Musik immer leiser macht oder ausschaltet und nach dem Gespräch
wieder anschaltet. Einer der Gründe, wieso ich freie Telefonanlagen (wie zum
Beispiel <code>asterisk</code>) so mag, ist, dass man dieses Problem nun lösen
kann. Ich hab’ das mit zwei einfachen Scripts und ein paar Einstellungen für
meinen MP3-Player <code>cmus</code> erreicht.

In der folgenden Anleitung gehe ich also davon aus, dass <code>cmus</code> oder
ein ähnlich funktionierender MP3-Player verwendet wird sowie dass
<code>asterisk</code> auf einem separaten Rechner läuft (wenn nicht, kann man
sich den Webserver- und den Socket-Schritt sparen).

## cmus’ Status speichern und abrufen

Da <code>cmus</code> standardmäßig keine externe „now playing”-Anzeige bietet,
aber Scripts aufrufen kann, wenn sich der Status ändert, brauchen wir ein
kleines Script, welches den Status behält:

**~/.cmus/status.sh**:
```
#!/bin/sh
# Saves the cmus status

while test $# -ge 2
do
	eval _$1='$2'
	shift
	shift
done

echo $_status > ~/.cmus/play_status/status
```

Um dieses Script aufrufen zu lassen, muss die Einstellung <code>:set
status_display_program=/home/michael/.cmus/status.sh</code> getätigt werden in
<code>cmus</code>. Außerdem muss das Verzeichnis
<code>~/.cmus/play_status/</code> existieren.

## Den Status über’s Netz abrufbar machen

Mithilfe deines Lieblingswebservers oder über eine beliebige andere Art (NFS,
FTP, Samba, …) kannst du nun die Datei <code>~/.cmus/play_status/status</code>
im Netz verfügbar machen, damit der (asterisk-)Server erkennt, ob momentan
Musik läuft oder nicht (wenn diese nämlich nicht läuft und man den Pause-Befehl
an <code>cmus</code> schickt, fängt dieser an zu spielen – genau das Gegenteil
würde also erreicht).

<p>
Ich hab’ das über einen <code>apache</code>-Vhost gelöst, da
<code>apache</code> ohnehin zum Testen auf meinem Rechner läuft:
</p>
<pre>&lt;VirtualHost 192.168.1.23:2424&gt;
	ServerAdmin none@localhost
	DocumentRoot /home/michael/.cmus/play_status/
	CustomLog /var/log/apache2/cmus.access common
	ErrorLog /var/log/apache2/cmus.error
	&lt;Directory /home/michael/.cmus/play_status/&gt;
		Options FollowSymlinks
		Allow from all
	&lt;/Directory&gt;
&lt;/VirtualHost&gt;
</pre>

<h2>cmus über’s Netz steuerbar machen</h2>
<p>
Das mitgelieferte Programm <code>cmus-remote</code> greift standardmäßig via
UNIX-Socket auf <code>cmus</code> zu. Damit <code>cmus</code> nun TCP-Sockets
verwendet, muss man es mit folgender Option starten (das kann man leider
(noch?) nicht fix einstellen):
</p>
<pre>cmus --listen 192.168.1.23:2525</pre>
<p>
Die IP-Adresse und den gewünschten Port natürlich gegebenenfalls ersetzen ;-).
</p>

<p>
Doch das war noch nicht alles: Bei Zugriff über TCP erhält man nun (zu recht!)
die Meldung, dass das – komplett ohne Authentifizierung – unsicher sei.
Mithilfe von <code>:set passwd=foo</code> kann man das Passwort setzen, welches
die Gegenseite braucht, um <code>cmus</code> fernsteuern zu können.
</p>

## Scripts für eingehende Anrufe und aufgelegte Anrufe

Das Script für eingehende Anrufe holt sich via <code>wget</code> den
<code>cmus</code>-Status von meinem Rechner, hält (falls Musik läuft) den
momentanen Song an und merkt sich, dass er eingegriffen hat, indem er
<code>/tmp/call_broke_song</code> anlegt.

**~/.pbx/cmus-incoming.sh**:
```
#!/bin/sh
# This should be called on an incoming call from asterisk

playstatus=$(wget -qO- http://192.168.1.23:2424/status)
[ $playstatus = "playing" ] && {
	touch /tmp/call_broke_song
	echo -e "foo\nplayer-pause" | nc -q0 192.168.1.23 2525
}

exit 0
```

<p>
Das Script für aufgelegte Anrufe ist genauso simpel: Es prüft, ob zuvor
eingegriffen wurde, schaut nach, ob der Status noch immer auf Pause steht
(falls man sich während des Telefongesprächs dafür entscheidet, die Musik via
Stop ganz auszuschalten, könnte das nicht der Fall sein) und setzt sie dann
fort.
</p>

**~/.pbx/cmus-hangup.sh**:
```
#!/bin/sh
# This should be called when the call is over from asterisk

[ -f /tmp/call_broke_song ] && {
	rm /tmp/call_broke_song
	playstatus=$(wget -qO- http://192.168.1.23:2424/status)
	[ $playstatus = "paused" ] && {
		echo -e "foo\nplayer-pause" | nc -q0 192.168.1.23 2525
	}
}

exit 0
```

<p>
Hier sieht man übrigens auch, dass <code>cmus-remote</code> gar nicht verwendet
wurde. Stattdessen kommt <code>nc</code> zum Einsatz, welches einfach den Text
(Passwort und den entsprechenden Befehl in der nächsten Zeile) an den Socket
sendet, welchen wir vorhin in <code>cmus</code> konfiguriert haben.
</p>

<h2>Vor und nach dem Anruf Scripts einbauen</h2>

<p>
Der Mechanismus basiert darauf, dass vor und nach einem Anruf, egal wie er
endet, ein Script ausgeführt wird. Ich würde sagen, dass das eigentlich der
schwierigste Teil der ganzen Installation war ;-).
</p>

<p>
Durch die Option <code>g</code> hört asterisk nicht mit der Abarbeitung des
aktiven Kontexts auf, sondern führt die nachfolgenden Aktionen aus. Das gilt
gleichermaßen für angenommene und nicht beantwortete Anrufe, sodass man manuell
prüfen muss.
</p>

<p>
Außerdem springt asterisk (nach Angabe der <code>j</code>-Option bei
<code>Dial()</code> auf jeden Fall) zu Priorität + 101 im Dialplan, falls die
Leitung gerade belegt ist. Dort startet man üblicherweise die Mailbox, hier
muss aber auch unser Script aufgerufen werden.
</p>

<p>
Zu guter letzt wird man feststellen, dass der Kontext direkt beendet wird,
falls der Anrufer auflegt. Hier bearbeitet asterisk den Dialplan gar nicht
weiter – außer man definiert den Dialplan für die Extension <code>h</code> (für
„hangup”).
</p>

<p>So sieht ein solcher Dialplan dann aus:</p>

**extensions.conf**:

```
[default]
exten =&gt; 23,1,System(/home/michael/.pbx/cmus-incoming.sh)
exten =&gt; 23,2,Dial(SIP/23,30,gj)
exten =&gt; 23,3,System(/home/michael/.pbx/cmus-hangup.sh)
exten =&gt; 23,4,GotoIf($[ ${DIALSTATUS} = "NOANSWER" ]?103)
exten =&gt; 23,5,Hangup()

exten =&gt; 23,103,System(/home/michael/.pbx/cmus-hangup.sh)
exten =&gt; 23,104,VoiceMail(b23)

exten =&gt; h,1,System(/home/michael/.pbx/cmus-hangup.sh)
```
