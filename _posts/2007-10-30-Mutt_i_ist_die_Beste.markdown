---
layout: post
title:  "Konsolen-Mailprogramm mutt-ng einrichten"
date:   2007-10-30 10:00:00
categories: Artikel
---



<div class="visiblelinks">
<h3>Worum geht’s?</h3>
<p>
Diesmal geht es um das Einrichten und Benutzen des Kommandozeilen-Mailclients
<code>mutt-ng</code> (Weiterentwicklung von <code>mutt</code>). Als System
kommt Linux zum Einsatz, prinzipiell sollte es jedoch auf allen unixoiden
Systemen funktionieren, ich habe sogar mal von einer Portierung von
<code>mutt</code> für Windows gehört… (das soll nicht heißen, dass Windows
unixoid sei, im Gegenteil!)
</p>

<p>
Ich benutze <code>mutt-ng</code> hauptsächlich, da ich meinen Mailclient auf
einem zentralen Rechner laufen lassen möchte, da ich zu viele Rechner habe um
das effizient zu synchronisieren und eventuell auch gerne mal von einem
beliebigen anderen Rechner meine Mails beantworten möchte…
</p>

<h3>Kommandozeile?</h3>
<p>
Ja, <code>mutt-ng</code> hat keine grafische Oberfläche und das macht ihn um
einiges flexibler als andere Mailclients – auch in der allgemeinen Flexibilität
(von der Oberfläche abgesehen) sind Kommandozeilenprogramme meist um Einiges
besser als ihre entsprechenden Pendants mit grafischer Oberfläche. Wieso das so
ist, ist schnell erklärt: Das Erstellen einer guten grafischen Oberfläche
dauert seine Zeit und dann soll das Programm auch noch möglichst einfach
gestaltet sein – klar, dass da einige Funktionen auf der Strecke bleiben.
</p>

<p>
Zu den eben erwähnten Vorteilen gehört zum Beispiel, dass man
<code>mutt-ng</code> auch über eine SSH-Verbindung benutzen kann, ohne dafür
gleich eine schnelle Verbindung zu benötigen (zum Beispiel wenn man nur einen
Internetzugang über ein 56k-Modem hat oder via GPRS online geht). Außerdem ist
<code>mutt-ng</code> <strong>sehr</strong> schnell. Allgemein ist man mit der
Tastatur nach einer gewissen Eingewöhnungsphase schneller, als wenn man dauernd
mit der Maus umhersuchen muss.
</p>

<p>
Zu den Abbildungen: Die Bildschirmfotos wurden gemacht, als
<code>mutt-ng</code> in einer <a href="http://de.wikipedia.org/wiki/GNU_Screen"
title="Wikipedia: GNU screen" target="_blank"><code>screen</code></a>-Session
(daher kommt die zusätzliche Zeile ganz unten) lief. Zu sehen ist die
lojban-beginners-Mailingliste. Da es sich hier um ein Konsolenprogramm handelt,
liegt es in der Natur der Sache, dass man auf den Vorschauversionen der
Abbildungen eigentlich nur schwarz sieht ;-).
</p>

<h3>Inhaltsverzeichnis</h3>

<div class="toc">
<ul>
	<li class="level1"><a href="#installation">1.) Installation von mutt-ng</a></li>
	<li class="level1"><a href="#einrichtung">2.) Einrichtung von procmail, fetchmail (und cyrus-imapd)</a></li>
		<li class="level2"><a href="#ohneimap">2.1) ohne IMAP-Server</a></li>
		<li class="level2"><a href="#mitimap">2.2) Eigener IMAP-Server</a></li>
	<li class="level1"><a href="#config">3.) Konfiguration von mutt-ng</a></li>
		<li class="level2"><a href="#pgp">3.1) PGP</a></li>
		<li class="level2"><a href="#pgpgenkey">3.1.1) Schlüssel erstellen</a></li>

		<li class="level2"><a href="#pgppubkey">3.1.2) Schlüssel veröffentlichen</a></li>
	<li class="level1"><a href="#benutzung">4.) Benutzung</a></li>
		<li class="level2"><a href="#benutzung_lesen">4.1) Mails lesen</a></li>
		<li class="level2"><a href="#benutzung_schreiben">4.2) Mails beantworten/schreiben</a></li>
		<li class="level2"><a href="#benutzung_suchen">4.3) Mails suchen</a></li>
		<li class="level2"><a href="#benutzung_vermischtes">4.4) Vermischtes</a></li>
	<li class="level1"><a href="#links">5.) Weiterführende Links</li>
</ul>
</div>

<h3><a name="installation">1.) Installation</a></h3>
<p>
<code>mutt-ng</code> ist zur Zeit noch in Entwicklung aber durchaus benutzbar.
Die aktuelle Version kann man sich aus dem CVS laden, einen täglichen Snapshot
gibt’s unter <a href="http://nion.modprobe.de/mutt-ng/snapshots/"
title="mutt-ng snapshots">http://nion.modprobe.de/mutt-ng/snapshots/</a>. Ich
persönlich benutze den Snapshot vom 27.03.2006 (mittlerweile ziemlich alt, aber
er funktioniert gut).
</p>

<p>
Die Installation selbst verläuft wie bei den meisten anderen Linuxprogrammen,
die man aus dem Quelltext kompiliert. Allerdings sollte man sich vorher
üerlegen, welche Optionen man in mutt-ng kompilieren möchte, da standardmäßg
wirklich nur die Grundfunktionalität enthalten ist. Ich habe mutt-ng mit den
folgenden Optionen kompiliert:
</p> 
<pre>./configure 	--enable-pgp \
		--enable-smime \
		--with-regex \
		--enable-pop \
		--enable-imap \
		--enable-nntp \
		--enable-imap-edit-threads \
		--with-ssl \
		--enable-hcache \
		--with-libesmtp</pre>
<p>
Die einzelnen Optionen stehen für:
</p>
<ul>
	<li><strong>--enable-pgp</strong>: Aktiviert die Unterstützung für das Verschlüsselungstool PGP</li>
	<li><strong>--enable-smime</strong>: Aktiviert die Unterstützung für S/MIME, was der Standard für Verschlüsseln und Signieren in MIME (was wiederum zum Transport von E-Mails und Unhägen verwendet wird) ist</li>
	<li><strong>--with-regexp</strong>: Erlaubt uns, reguläre Ausdrücke (Regular Expressions) zu verwenden</li>
	<li><strong>--enable-pop, --enable-imap, --enable-nntp</strong>: Aktiviert die eingebaute Üterstützung von POP- und IMAP-Postfächern sowie Newsgroups (NNTP). Zumindest IMAP ist für unser Setup notwendig, POP und NNTP sind optional</li>
	<li><strong>--with-ssl</strong>: Unterstützung für via SSL verschlüsselte Verbindungen fü POP und IMAP</li>
	<li><strong>--enable-hcache</strong>: Unterstützung für das Zwischenspeichern (Caching) der E-Mailkopfzeilen, was die Geschwindigkeit beim Öffnen eines Postfachs enorm erhöht</li>
	<li><strong>--with-libesmtp</strong>: Lässt mutt libesmtp statt einem externen Programm zum Verschicken der E-Mails benutzen</li>
</ul>
<p>
Die komplette Liste der verfügbaren Optionen sieht man via <code>./configure
--help</code>.
</p>
<p>
Nachdem <code>configure</code> fertig ist, kann man mit <code>make &amp;&amp;
make install</code> mutt kompilieren und installieren</code>.
</p>

<h3><a name="einrichtung">2.) Einrichtung</a></h3>
<p>
OK, ab hier wird’s kompliziert ;-). Ich persönlich habe mich dafür entschieden,
einen eigenen IMAP-Server aufzusetzen, damit ich zur Not auch mit anderen
Clients im Netzwerk diesen Server benutzen kann. Man kann aber natürlich auch
ohne einen eigenen IMAP-Server <code>mutt-ng</code> benutzen, ich empfehle
jedoch, nicht direkt auf IMAP-Server zu arbeiten, sondern die E-Mails auf jeden
Fall mit <code>fetchmail</code> abzuholen und lokal zwischenzuspeichern (so
macht man das in der Regel auch mit grafischen Mailclients).
</p>

<p>
Wir fangen also bei <code>fetchmail</code> und <code>procmail</code> an
(<code>procmail</code> filtert E-Mails, wir werden das dazu benutzen, mehrere
Identitäten oder Postfächer zu verwalten). Vorab noch: Der Benutzer, unter dem
wir arbeiten und an den die E-Mails gehen (lokal), nennen wir mal „michael”.
</p>

<p>
In der Datei <code>~/.fetchmailrc</code> muss man nun konfigurieren, von
welchen Servern <code>fetchmail</code> die E-Mails abholt und an welchen
lokalen Benutzer diese zugestellt werden sollen. Wichtig sind hierbei die
Protokoll-, SSL- und Benutzereinstellungen. Ich geb’ hier ein Beispiel für
einen normalen, unverschlüsselten POP3-Server und für das verschlüsselte GMail:
</p>
<pre><b>poll</b> my.pop3.de <b>with</b>
	<b>proto</b> pop3
	<b>user</b> "michaelmy-pop3-de"
	<b>pass</b> "beispiel"
	<b>is</b> "michael"
	<b>mda</b> "/usr/bin/procmail -f %F"
	<b>fetchall</b>
	<b>keep</b>
	
	
<b>poll</b> pop.gmail.com <b>with</b>
	<b>proto</b> pop3
	<b>user</b> "michael"
	<b>pass</b> "natuerlichnichtmeinechtes"
	<b>is</b> "michael"
	<b>mda</b> "/usr/bin/procmail -f %F"
	<b>ssl</b>
	<b>fetchall</b>
	<b>keep</b></pre>
<p>
Die Syntax sollte klar geworden sein, hier werden also zwei Server abgefragt
(„gepolled”), die POP3 sprechen. Benutzername und Passwort sind
unterschiedlich, im Endeffekt werden die E-Mails aber an den selben lokalen
Benutzer via <code>procmail</code> zugestellt. Die Verbindung zum GMail-Server
wird über SSL hergestellt, in beiden Fällen werden die E-Mails aber behalten,
was zu Testzwecken nützlich ist (schließlich will man nicht gerne E-Mails
verlieren), später aber geändert werden sollte (einfach die Option „keep”
entfernen). Die Option „fetchall” sorgt dafür, dass alle E-Mails abgerufen
werden, auch wenn sie bereits von einem anderen Mailer als gelesen markiert
wurden (zum Beispiel vom GMail-webinterface).
</p>
<p>
Hinweis: Wenn man einen eigenen IMAP-Server verwendet, kann man die Zeile mit
<code>procmail</code> auch weglassen, da wir den Mailer <code>exim</code>
ohnehin so anpassen werden, dass er <code>procmail</code> benutzt.
</p>

<h4><a name="ohneimap">2.1) Ohne eigenen IMAP-Server</a></h4>
<p>
Wir werden nun <code>procmail</code> einrichten und im nächsten Abschnitt
schließlich <code>mutt-ng</code> in Betrieb nehmen. Hier direkt ’mal meine
Konfiguration von <code>procmail</code> (<code>~/.procmailrc</code>):
</p>
<pre>DEFAULT=$HOME/Mail/unsorted
MAILDIR=$HOME/Mail
LOGFILE=$MAILDIR/log

:0:
* ^From:gute@freundin\.de
freunde

:0:
* ^TO_michael\.stapelberg@firma\.de
firma

:0:
* ^TO_michael@privat\.de
privat

:0:
* ^TO_mailing@liste\.de
privat</pre>
<p>
Die drei Variablendefinitionen am Anfang sorgen dafür, dass alle Mails
prinzipiell in <code>$HOME/Mail/unsorted</code> landen, in meinem Fall also in
<code>/home/michael/Mail/unsorted</code>. Ein Protokoll über die gefilterten
Mails wird in <code>$MAILDIR/log</code> abgespeichert, und MAILDIR ist wiederum
<code>$HOME/Mail</code>. Effektiv kommen also gefilterte Mails bei mir in
<code>/home/michael/Mail/</code>, ungefilterte in
<code>/home/michael/Mail/unsorted</code> und die Logdatei ist
<code>/home/michael/Mail/log</code>.
</p>

<p>
Auf die ganzen Filtermöglichkeiten von <code>procmail</code> möchte ich an
dieser Stelle nicht eingehen, gerade auch zur Spamvermeidung gibt’s da schon
einige Websites im Netz, die sich damit befassen.
</p>

<h4><a name="mitimap">2.2) Eigener IMAP-Server</a></h4>
<p>
Mit einem eigenen IMAP-Server fungieren wir wie ein kleiner E-Mailprovider –
nur eben lokal. Das bedeutet, dass sich andere Rechner mit dem Server verbinden
und E-Mails ablegen und dass der Anwender sich mit dem Server verbindet und sie
abholt. In unserem Fall sind allerdings sowohl zustellender Rechner, als auch
Server und Benutzer der selbe Computer.
</p>

<p>
Der Vorteil eines IMAP-Servers ist, dass man ihn von mehreren Rechnern benutzen
kann und die kompletten E-Mails mitsamt ihrer Ordner-Zuordnung synchron sind.
Außerdem könnte man dann einfacher das E-Mailprogramm wechseln, wenn man doch
in irgendeiner Weise unzufrieden ist mit mutt ;-).
</p>

<p>
Als Zustellungsprogramm für die E-Mails (SMTP-Server) kommt bei mir
<code>exim</code> zum Einsatz, der bei Debian standardmäßig verwendet wird. Als
IMAP-Server verwenden wir <code>cyrus</code>, der ebenfalls für Debian
verfügbar ist.
</p>

<p>
<code>Cyrus</code> ist nach einem <code>apt-get install cyrus-imapd</code> fast
direkt einsatzbereit, man muss nur noch ein Passwort für den Administrator
setzen und die Mailboxen für die Benutzer anlegen:
</p>
<pre># passwd cyrus
$ cyradm -user cyrus localhost
cm user.michael
cm user.michael.privat
cm user.michael.firma
cm user.michael.freunde
cm user.michael.Trash
cm user.michael.Sent</pre>
<p>
(Ich habe die Einteilung aus der Procmailkonfiguration beibehalten)
</p>

<p>
Bei <code>exim</code> sieht es da schon etwas anders aus. Glücklicherweise wird
man bei der ersten Installation oder nach der Eingabe von
<code>dpkg-reconfigure exim</code> durch einen Assistenten geleitet, der eine
weitestgehend sinnvolle Konfiguration erzeugt. Hinzufügen muss man in der Regel
nur noch die Verwendung von <code>procmail</code>:
</p>
<pre>procmail_pipe:
	driver = pipe
	command = "/usr/bin/procmail -t -d ${local_part}"
	from_hack
	return_path_add
	delivery_date_add
	envelope_to_add
	suffix = ""
	user = $local_part
	group = mail</pre>
<p>
Im Abschnitt <code>localuser</code> muss man dann das Transportmittel auf die
eben erstellte <code>procmail_pipe</code> ändern:
</p>
<pre>localuser:
	driver = localuser
	transport = procmail_pipe</pre>
<p>
So, das war’s auch schon. Nun müssen wir nur noch <code>procmail</code> selbst
einrichten, die Konfiguration für einen IMAP-Server unterscheidet sich leicht
von der obigen.
</p>
<pre>DELIVERMAIL="/usr/sbin/cyrdeliver"
LOGFILE="/var/log/mail/procmail.log"
DEFAULT="$DELIVERMAIL -e -a $LOGNAME -m user.$LOGNAME"
PRIVAT="$DELIVERMAIL -e -a $LOGNAME -m user.$LOGNAME.privat"
FIRMA="$DELIVERMAIL -e -a $LOGNAME -m user.$LOGNAME.firma"
FREUNDE="$DELIVERMAIL -e -a $LOGNAME -m user.$LOGNAME.freunde"
VERBOSE=off

:0 w
* ^From:gute@freundin\.de
| /bin/sed 1d | $FREUNDE

:0 w
* ^TO_michael\.stapelberg@firma\.de
| /bin/sed 1d | $FIRMA

:0 w
* ^TO_michael@privat\.de
| /bin/sed 1d | $PRIVAT

:0 w
* ^TO_mailing@liste\.de
| /bin/sed 1d | $PRIVAT

# Wir loggen das Ergebnis der Zustellung:
:0 w
{
	EXITCODE=$?
	HOST
}</pre>

<h3><a name="config">3.) Konfiguration</a></h3>

<p>
Ich werde hier auf meine Konfiguration eingehen, das heißt, welche Optionen ich
verwende und warum ich sie verwende. Eine komplette Befehlsreferenz für die
Konfigurationsdatei gibt’s im muttng-manual.
</p>

<p>
<strong>Vorsicht:</code> Da in dieser Datei möglicherweise Mailpasswörter im
Klartext abgelegt werden, sollte sie nur für den Benutzer lesbar sein
(<code>chmod 600 ~/.muttngrc</code>).</strong>
</p>

<div style="border: 1px solid black; padding: 5px; background-color: #C0C0C0">
<h4>Allgemeine Einstellungen</h4>

<p><code>set pager_context=1</code><br>
Bestimmt die Anzahl der Zeilen, die beim Umblättern von der vorigen Seite
angezeigt werden sollen, um eine bessere Orientierung beim Umblättern zu
haben.</p>

<p><code>set mail_check=15</code><br>
Schaut alle 15 Sekunden nach, ob neue Mails auf dem Server liegen.<br>
<strong>Vorsicht:</strong> 15 Sekunden ist ein sehr kurzer Intervall, den man
sich nur erlauben kann, wenn der IMAP-Server im lokalen Netz betrieben
wird.</p>

<p><code>set timeout=15</code><br>
Veranlasst <code>muttng</code>, nach 15 Sekunden Nichtstun (= keine Eingaben
vom Benutzer) tatsächlich nach neuen Mails zu schauen (also das Ergebnis des
durch <code>mail_check</code> ausgelösten Checks auszuwerten).</p>

<p><code>set pager_index_lines=10</code><br>
Der Mailindex soll mit 10 Zeilen angezeigt werden, während wir uns im Pager
befinden.</p>

<p><code>set menu_scroll</code><br>
Aktiviert das Hoch/Runter-Bewegen, wenn man eigentlich außerhalb des
Bildschirms wäre.</p>

<p><code>set status_on_top</code><br>
Die Statuszeile soll ganz oben (anstatt ganz unten) angezeigt werden.</p>

<p><code>set header_cache="~/.muttng/header_cache"</code><br>
Aktiviert das Zwischenspeichern der Header, das macht <code>muttng</code> beim
Öffnen einer Mailbox (egal welches Format sie hat) erheblich schneller.</p>

<p><code>set sort=threads</code><br>
Mails sollen in der Threadansicht (Baumstruktur) angezeigt werden. Dies trägt
sehr zur Übersichtlichkeit von Mailinglisten bei.</p>

<p><code>set sort_aux=reverse-date-received</code><br>
Ansonsten sollen Mails nach Datum sortiert werden.</p>

<p><code>set mark_old=no</code><br>
Mails sollen nicht automatisch beim Öffnen der Mailbox auf „alt” gesetzt
werden.</p>

<p><code>set rfc2047_parameters=yes</code><br>
Aktiviert das korrekte Verarbeiten von RFC2047-kodierten Dateinamen (betrifft
Attachments mit Umlauten, eigentlich ist diese Kodierung inkorrekt, daher ist
es nicht standardmäß aktiviert ist).</p>

<h4>Sidebar</h4>
<p><code>set sidebar_width=15</code><br>
Setzt die Breide der Sidebar auf 15 Zeichen.</p>

<p><code>set sidebar_visible=yes</code><br>
Die Sidebar soll angezeigt werden.</p>

<p><code>alternates
"michael@nospamplease\.de|michael\.stapelberg@firma\.de"</code><br>
Die ist eine Auflistung meiner Mailadressen, damit mutt-ng sicher weiß, ob die
jeweilige Mailadresse mir gehört. <a
href="http://mutt-ng.berlios.de/manual/advanced-usage.html#advanced-regexp"
title="mutt-ng-Handbuch: Regular Expressions">Reguläre Ausdrücke</a> sind hier
erlaubt.</p>

<p><code>set record="=Versendet"</code><br>
Legt fest, dass versendete Mails in den Ordner =Versendet abgelegt werden
sollen.</p>

<h4>Ordnerabhängige Einstellungen</h4>
<p><code>folder-hook . source ~/.muttng/fs_defaults</code><br>
<code>folder-hook privat source ~/.muttng/fs_privat</code><br>
<code>folder-hook INBOX source ~/.muttng/fs_ms</code><br>
<code>folder-hook Schule source ~/.muttng/fs_schule</code><br>
Da der erste Befehl für alle Mailboxen gilt, wird zuerst über den Source-Befehl
die Datei <code>~/.muttng/fs_defaults</code> eingebunden, die ein paar
generelle Einetellungen festlegt. Für die anderen Mailboxen werden dann in den
entsprechenden Dateien zum Beispiel andere SMTP-Server festgelegt oder
Einstellungen bezüglich der Kryptographie vorgenommen.</p>

<h4>Einstellungen zum Versenden von Mails</h4>

<p><code>set alias_file=~/.muttng/alises</code><br>
Legt eine Alias-Datei fest, in der Namen wie „stefan” in E-Mailadressen
umgewandelt werden.</p>

<p><code>source ~/.muttng/aliases</code><br>
Diese Datei muss außerdem als Konfigurationsdatei eingelesen werden.</p>

<p><code>set reverse_alias</code><br>
Aktiviert die Anzeige der in der Aliasdatei festgelegten Namen anstelle der
(eventuell kryptischen, schwer zu merkenden) Mailadresse.</p>

<p><code>set attribution = "Guten Tag %n,\n\n* [%(%d.%m.%y %H:%M)]:"</code><br>
Setzt die Standard-anrede. <code>%n</code> steht für den Absender der E-Mail,
auf die man antwortet und ist leer, wenn man eine neue E-Mail schreibt. Eine
Liste der möglichen Variablen findet man <a
href="http://mutt-ng.berlios.de/manual/index-format.html"
title="mutt-ng-Handbuch: mögliche Variablen">im mutt-ng-Handbuch</a>.</p>

<p><code>set editor="vim -c 'set tw=78 nocin noai'"</code><br>
Setzt den Editor, mit dem die Mails geschrieben werden. Ich benutze dafür
<code>vim</code> ohne Einrückungen mit einer Zeilenlänge von 78 Zeichen.</p>

<p><code>set delete=yes</code><br>
Sagt, dass Mails wirklich gelöscht werden sollen, wenn die Änderungen an der
Mailbox gespeichert werden sollen oder eine neue Mailbox geöffnet wird (das ist
hauptsächlich für IMAP-Mailboxen wichtig).</p>

<p><code>set include=yes</code><br>
Bindet bei Antworten die Mail, auf die man antwortet, als Zitat mit ein.</p>

<p><code>set fast_reply=yes</code><br>
<code>muttng</code> soll uns bei Antworten nicht nach Name und Betreff fragen –
ersteres ist ohnehin klar und letzteres ändern wir selbst am Ende bei
Bedarf.</p>

<p><code>unset metoo</code><br>
Dadurch, dass die Variable nicht gesetzt ist, fügt <code>mutt-ng</code> uns
nicht zu den Empfängern unserer eigenen Antworten auf einer Mailingliste
hinzu.</p>

<p><code>unset forward_decrypt</code><br>
Verschlüsselte Mails sollen beim Weiterleiten nicht entschlüsselt werden. (Das
hatte der Versender vermutlich nicht im Sinne, als er die Mail verschlüsselte.
Weiterleitungen von verschlüsselten Mails sind übrigens nur dann sinnvoll, wenn
man sie an sich selbst weiterleitet oder die Mail an den falschen Empfänger
geraten ist.))</p>

<p><code>set beep=yes</code><br>
Erlaubt <code>muttng</code> zu piepsen (wobei viele Benutzer das Piepsen wohl
durch ein Blinken ersetzt haben).</p>

<p><code>set beep_new=yes</code><br>
Lässt <code>muttng</code> bei Bemerken neuer Mails piepsen (nur ein Mal, egal
wieviele neue Mails in einem Rutsch eingegangen sind, keine Sorge ;-)).</p>
<p><code>set markers=no</code><br>
Deaktiviert das Anzeigen von +-Symbolen bei umgebrochenen Zeilen.</p>

<h4>IMAP-Einstellungen</h4>
<p><code>set imap_user="michael"</code><br>
Setzt den Benutzernamen für den IMAP-Server.</p>

<p><code>set imap_pass=""</code><br>
Legt das Passwort für den IMAP-Server fest (nein, mein Passwort ist natürlich
nicht leer ;-)).</p>

<p><code>set folder=imap://localhost/user.michael.</code><br>
<code>folder</code> ist der Basisordner, mit ihm wird nachher das =-Symbol
ersetzt. Wenn <code>folder</code> also „imap://localhost/user.michael.” ist,
wäre die Mailbox <code>=privat</code> voll ausgeschrieben
„imap://localhost/user.michael.privat”.</p>

<p><code>set spoolfile=imap://localhost/INBOX</code><br>
Legt die eigentliche Mailbox fest.</p>

<p><code>set trash="=Trash"</code><br>
Unser Mülleimer ist die IMAP-Mailbox <code>=Trash</code>.</p>

<p><code>mailboxes imap://localhost/INBOX =privat =schule</code><br>
Legt die weiteren Mailboxen fest (die dann auch im Pager angezeigt werden –
mutt zeigt nicht automatisch alle verfüfbaren an).</p>

<h4>Header</h4>
<p><code>ignore *</code><br>
<code>unignore  Date To From: Subject X-Mailer Organization User-Agent</code><br>
<code>hdr_order Date From To Subject X-Mailer User-Agent
Organization</code><br>
Ignoriert zuerst alle Header und schaltet dann diejenigen, die wir sehen
möchten, frei. Letztendlich werden die verbliebenen Header (wenn sie in der
Mail nicht gesetzt sind, werden sie garnicht angezeigt) geordnet.</p>


<h4>Farben</h4>
<pre>color normal     white          black   # Normaler Text
color indicator  black          red     # Die ausgewählte Nachricht
color tree       red            black   # Die Pfeile, die einen Thread zusammenhalten
color status     brightyellow   blue    # Die Statuszeile
color error      brightred      black   # Eine Fehlermeldung
color message    red            black   # Informative Nachrichten
color signature  blue           black   # Die Signatur eines Senders
color attachment brightyellow   red     # MIME attachments
color search     brightyellow   red     # Suchergebnisse
color tilde      black          black   # Die »~« am Anfang einer Nachricht
color markers    red            black   # Das »+« bei umgebrochenen Zeilen
color hdrdefault blue           black   # Standardheaderzeilen
color bold       red            black   # *hervorgehobener* Text im Body
color underline  green          black   # _unterstrichener_ Text im Body
color quoted     blue           black   # gequoteter Text
color quoted1    magenta        black
color quoted2    red            black
color quoted3    green          black
color quoted4    blue           black
color quoted5    cyan           black
color quoted6    magenta        black
color quoted7    red            black
color quoted8    green          black
color quoted9    blue           black
#
#     object     foreground backg.   RegExp
#
color header     green      black  "^(Subject):"
color header     red        black  "^(From|X-Mailer|To|Cc|Reply-To|Date):"
color body       black      white    "((ftp|http|https)://|(file|mailto|news):|www\\.)[-a-z0-9_.:]*
[a-z0-9](/[^][{} \t\n\r\"&lt;&gt;()]*[^][{} \t\n\r\"&lt;&gt;().,:!])?/?"
color body       green      black  "((;|:|8\\:|\\=)(-|=|~|_|-'|%|&lt;|)(\\)|Q|P|\\)%))"
color body       cyan       black  "[-a-z_0-9.+]+@[-a-z_0-9.]+"
color body       red        black  "(^| )\\*[-a-z0-9*]+\\*[,.?]?[ \n]"
color body       green      black  "(^| )_[-a-z0-9_]+_[,.?]?[ \n]"
color index      blue       black  ~F           # geflagged Nachrichte
color index      red        black  ~N           # Neue Nachrichten
color index      magenta    black  ~T           # getaggte Nachrichten
color index      yellow     black  ~D           # Nachrichten, die als gelöscht
                                                # markiert sind</pre>
<p>
Diese Farbkonfiguration stammt von <a
href="http://liesdiemanpage.de/index.php?content=linux%2Fmutt"
title="liesdiemanpage.de">liesdiemanpage.de</a>.
</p>

<h4>Titelleiste</h4>
<p><code>set xterm_set_titles=yes</code><br>
Aktiviert das Setzen der Titelzeile.</p>

<p><code>set xterm_title="muttng [new: %n c/%b o]"</code><br>
Legt das Format der Titelzeile fest.</p>

<h4>Tastenbelegung</h4>
<p><code>bind index \CP sidebar-prev</code><br>
<code>bind pager \CP sidebar-prev</code><br>
Steuerung (Ctrl) und P (Groß-/Kleinschreibung ist hierbei nicht relevant) wählt
den vorhergehenden Eintrag der Sidebar aus, und das sowohl in der
Index-Ansicht, als auch im Pager.</p>

<p><code>bind index \CN sidebar-next</code><br>
<code>bind pager \CN sidebar-next</code><br>
Wie eben, nur mit Steuerung+N für den nächsten Eintrag.</p>

<p><code>bind index \CO sidebar-open</code><br>
<code>bind pager \CO sidebar-open</code><br>
Wie eben, nur mit Steuerung+O, um die jeweilige Mailbox zu öffnen.</p>

<p><code>bind index P purge-message</code><br>
Groß-P löscht die ausgewählte Mail sofort (hier ist Groß-/Kleinschreibung wieder wichtig).</p>

<p><code>bind pager h display-toggle-weed</code><br>
h blendet die kompletten Header ein- oder aus.</p>

<h4>Reguläre Ausdrücke</h4>
<p><code>set quote_regexp="^( {0,4}[&gt;|:%]| {0,4}[a-z0-9]+[&gt;|]+)+"</code><br>
Erkennt Zitate um sie richtig einfärben zu können.</p>

<p><code>set smileys="((:|\\(|;|=)(-|=|-'|%)(\\)|:|\\=))"</code><br>
Erkennt Smilies wie <code>:-)</code>, <code>%-(</code> und so weiter…</p>

<p><code>set reply_regexp="^((re(\\^[0-9])? ?:|a(nt)?w(ort)?:|wg:|\\(fwd\\))[ \t]+)*"</code><br>
Wandelt bei Antworten alle überflüssigen AW, Re, ANTWORT, WG, FWD, etc in ein
simples „Re:” um - besonders nützlich, wenn man mit Outlook-Benutzern
kommuniziert.</p>

<h4>Mailinglisten</h4>
<p><code>subscribe lojban-beginners</code><br>
Sagt <code>muttng</code>, dass man die Mailingliste
<code>lojban-beginners</code> abonniert hat. Dadurch funktioniert der
Reply-to-Befehl und <code>muttng</code> setzt den
<code>followup-to</code>-Header richtig.</p>

<h4>GPG-Einstellungen</h4>
<p><code>source ~/.muttng/gpg.rc</code><br>
Bindet die mitgelieferten Standardwerte mit ein (Die GnuPG aufrufen).</p>

<p><code>unset crypt_autosign</code><br>
<code>unset crypt_autoencrypt</code><br>
Da die Mehrheit der Leute leider kein PGP benutzt, wollen wir Mails nicht
automatisch, sondern nur auf Wunsch verschlüsseln lassen.</p>

<p><code>set crypt_verify_sig=yes</code><br>
Wenn wir signierte Mails erhalten, soll die Signatur geprüft werden.</p>

<p><code>set pgp_sign_as="65B790C2"</code><br>
Der Key mit dieser ID wird aus dem privaten Schlüsselbund geholt und zum
Signieren verwendet.</p>
</div>

<p>
Die komplette Konfiguration könnt ihr euch <a href="/Config/muttngrc"
title="mutt-ng-Config">hier herunterladen</a>.
</p>
<h4><a name="pgp">3.2) PGP</a></h4>
<p>
Selbstverständlich hat mutt auch PGP-Unterstützung, sodass man signierte und
verschlüsselte Mails versenden kann. Dazu verwendet man in der Regel GNUPG,
kurz GPG. Sollte GPG noch nicht installiert sein, kann man dies mit folgendem
Befehl nachholen:
</p>
<pre>$ apt-get install gnupg</pre>
<h5><a name="pgpgenkey">3.2.1) Schlüssel erstellen</a></h5>
<pre>$ gpg --gen-key
Bitte wählen Sie, welche Art von Schlüssel Sie möchten:
   (1) DSA und ElGamal (voreingestellt)
   (2) DSA (nur signieren/beglaubigen)
   (4) ElGamal (signieren/beglaubigen und verschlüsseln)
Ihre Auswahl? <b>1</b>

Der DSA Schlüssel wird 1024 Bits haben.
Es wird ein neues ELG-E Schlüsselpaar erzeugt.
              kleinste Schlüssellänge ist  768 Bit
              standard Schlüssellänge ist 1024 Bit
      größte sinnvolle Schlüssellänge ist 2048 Bit
Welche Schlüssellänge wünschen Sie? (1024) <b>2048</b>

Bitte wählen Sie, wie lange der Schlüssel gültig bleiben soll.
         0 = Schlüssel verfällt nie
      <n>  = Schlüssel verfällt nach n Tagen
      <n>w = Schlüssel verfällt nach n Wochen
      <n>m = Schlüssel verfällt nach n Monaten
      <n>y = Schlüssel verfällt nach n Jahren
Der Schlüssel bleibt wie lange gültig? (0) <b>5y</b>

Sie benötigen eine User-ID, um Ihren Schlüssel eindeutig zu machen; das
Programm baut diese User-ID aus Ihrem echten Namen, einem Kommentar und
Ihrer E-Mail-Adresse in dieser Form auf:
    ``Heinrich Heine (Der Dichter) &lt;heinrichh@duesseldorf.de&gt;''

Ihr Name (``Vorname Nachname''): <b>Michael Stapelberg &lt;michael@nospamplease.de&gt;</b>

Sie benötigen ein Mantra, um den geheimen Schlüssel zu schützen.

Geben Sie das Mantra ein:</pre>
<p>
(Das Mantra sollte ein für Fremde schwer zu erratender, aber für einen selbst
leicht zu merkender, ausreichend langer Satz sein – ca 20 Zeichen sollten
genügen.)
</p>
<h5><a name="pgppubkey">3.2.2) Schlüssel veröffentlichen</a></h5>
<p>
Mit <code>gpg -K</code> kann man sich alle Schlüssel im geheimen Schlüsselbund
anzeigen lassen. In der ersten Zeile sieht man auch die ID, die wir nachher im
GPG-Teil der mutt-Konfiguration verwenden werden:
</p>
<pre>pub   1024D/<b>65B790C2</b> 2006-07-24 [expires: 2011-07-23]</pre>
<p>
&nbsp;
</p>
<p>
Nun kopieren wir uns noch die Standard-GPG-Konfiguration aus
<code>contrib/gpg.rc</code> in dem Verzeichnis in dem der mutt-ng-Quelltext
liegt in unser Konfigurationsverzeichnis.
</p>

<h3><a name="benutzung">4.) Benutzung</a></h3>
<p>
Die meiste Zeit wird man vermutlich Mails lesen, beantworten und verzweifelt
nach Mails suchen ;-), daher habe ich diesen Abschnitt in die entsprechenden
Kapitel unterteilt. Übrigens: In jeder Ansicht sind kontextabhängige
Erklärungen der wichtigsten Befehle unten eingeblendet, über die
<code>?</code>-Taste kommt man zu einer ausführlichen Erklärung, die man dann
mit <code>q</code> wieder schließen kann.
</p>

<p>
Hinweis: Diese Beschreibung ist natürlich nur die Spitze des Eisbergs, für eine
genauere Beschreibung sollte man das <a
href="http://mutt-ng.berlios.de/manual/getting-started.html"
title="mutt-ng-Handbuch">mutt-ng-Handbuch</a> zu Rate ziehen.
</p>

<h4><a name="benutzung_lesen">4.1) Mails lesen</a></h4>
<div style="float: left" class="pictureLink"><a href="/Bilder/mutt-ng/mutt_overview.png" title="Bild „Übersicht” öffnen"><img alt="Vorschau: Übersicht" src="/Bilder/mutt-ng/thumbs/mutt_overview.png" border="0"></a><br><small><i>Abb.: Übersicht</i></small></div>

<p>
In der Nachrichtenübersicht (siehe Abbildung links) werden soviele Nachrichten
angezeigt wie ins Fenster passen (irgendwie logisch ;-)), sortiert nach der
eingestellten Methode (Datum/Thread in meiner Konfiguration).
</p>

<p>
Mit der <code>Enter</code>-Taste öffnet man den Pager, der dann die ausgewählte
Nachricht anzeigt. Er öffnet sich im unteren Teil von <code>mutt-ng</code>,
lässt aber einen Teil des Nachrichtenfensters sichtbar, da man – wie in anderen
Mailclients bei aktivierter Autovorschau – mittels der Pfeiltasten andere
Nachrichten auswählen kann. Den Pager schließt man mit <code>q</code> wieder
(vorsicht, ein großes <code>Q</code> schließt <code>mutt-ng</code>). Innerhalb
des Pagers kommt man mit der Leertaste eine Seite weiter und mit <code>-</code>
eine Seite zurück. Die <code>Page Up/Page Dn</code>-Tasten funktionieren
ebenfalls.
</p>

<h4><a name="benutzung_schreiben">4.2) Mails beantworten/schreiben</a></h4>
<div style="float: right" class="pictureLink"><a href="/Bilder/mutt-ng/mutt_reply.png" title="Bild „Schreiben” öffnen"><img alt="Vorschau: Schreiben" src="/Bilder/mutt-ng/thumbs/mutt_reply.png" border="0"></a><br><small><i>Abb.: Schreiben</i></small></div>
<p>
Sowohl im Pager als auch in der Nachrichtenübersicht kann man der Taste
<code>r</code> eine Mail beantworten. Es öffnet sich dann direkt der
eingestellte Editor mit einem Zitat der ursprünglichen Nachricht. Sobald der
Editor beendet wurde (= man mit dem Schreiben der Mail fertig ist) kommt man
ins <a href="/Bilder/mutt-ng/mutt_send.png" title="Bildschirmfoto:
Absendefenster" target="_blank">übliche Fenster zum Absenden der Mail
(Bildschirmfoto)</a>. Dort kann man gegebenenfalls Empfänger hinzufügen oder
den Titel verändern.
</p>

<h4><a name="benutzung_suchen">4.3) Mails suchen</a></h4>
<p>
<strong>Filtern</strong>: Da wir bei der Installation die <a
href="http://mutt-ng.berlios.de/manual/advanced-usage.html#advanced-regexp"
title="mutt-ng-Handbuch: Regular Expressions">Regular Expressions</a> aktiviert
haben, können wir diese nun verwenden. Mit <code>l</code> (kleines L) fragt
<code>mutt-ng</code> nach dem Filter. Danach werden nur noch Mails angezeigt,
die diesem Filter entsprechen Dieser kann ein einfaches Wort, oder eben ein
regulärer Ausdruck sein. Wenn man „all” eingibt, werden wieder alle Mails
angezeigt.
</p>

<p>
<strong>Suchen</strong>: Wie in den meisten Ansichten kann man mit
<code>/</code> suchen. Falls es Treffer gibt, springt <code>mutt-ng</code> zum
ersten. Durch einen weiteren Druck auf <code>/</code> öffnet sich das Suchfeld
erneut, diesmal mit dem vorher gesuchten Text. Dadurch kann man mit
<code>Enter</code> bestätigen und kommt zum nächsten Treffer.
</p>

<h4><a name="benutzung_vermischtes">4.4) Vermischtes</a></h4>
<ul>
	<li>
	<strong>Mails löschen</strong>: <code>D</code>
	</li>
	<li>
	<strong>Löschen rückgängig machen</strong>: Da gelöschte Nachrichten
	nicht anwählbar sind, muss man sie direkt adressieren: Die Nummer der
	Nachricht drücken und dann <code>Enter</code> drücken. Anschließend
	kann man mit <code>u</code> das Löschen rückgängig machen.
	</li>
</ul>

<h3><a name="links">5.) Weiterführende Links</a></h3>
<ul>
	<li><a href="http://mutt.sourceforge.net/imap/">mutt-Beschreibung zu IMAP</a></li>
	<li><a href="http://mutt-ng.supersized.org/">mutt-ng development blog</a> mit Informationen über den Status des Projekts</li>
	<li><a href="http://mutt-ng.berlios.de/manual/">mutt-ng-Handbuch</a></li>
</ul>
</div>
