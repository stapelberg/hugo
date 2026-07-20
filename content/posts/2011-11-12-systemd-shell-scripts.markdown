---
layout: post
date: 2011-11-12 23:12:00 +00:00
title: "systemd ist lange überfällig…"
---
<p>
<a href="http://freedesktop.org/wiki/Software/systemd">systemd</a> ist lange
überfällig, denn die Schmerzen beim Überführen eines quick'n'dirty shell
scripts in einen ordentlich wartbaren Dienst sind mit sysvinit einfach viel zu
groß. 
</p>

<p>
Vor ziemlich langer Zeit habe ich den RaumZeitMPD geschrieben, einen IRC-Bot,
welcher bei !stream anzeigt, welches Lied gerade gespielt wird und bei !stream
&lt;url&gt; die angegebene URL abspielt. Später wurde er erweitert um bei !ping
die <a href="http://www.youtube.com/watch?v=JoGhlOhAuno">Rundumleuchte für 5
Sekunden aufleuchten zu lassen</a>, damit einer der Anwesenden seine
Aufmerksamkeit auf das IRC richtet.
</p>

<p>
Dieser Bot lief bislang in einer screen-Session auf der Blackbox. Dieses Setup
ist natürlich nicht ideal, denn sofern die Blackbox neugestartet wird, muss
jemand mit Zugriff auf die Blackbox diese Session neustarten. Das ist
unzuverlässig und erfordert, dass permanent mindestens eine Person das Wissen
haben muss, wie man den RaumZeitMPD startet. Eine bessere Lösung ist es, ihn
bei Systemstart zu starten und als Daemon laufen zu lassen.
</p>

<p>
Das kriegt man natürlich mit sysvinit hin. Ein Initscript, welches anhand des
minimale Debian-Beispiels angefertigt wurde, ist allerdings 140 Zeilen lang.
Zum Vergleich: Der (Perl-)Code für RaumZeitMPD ist 173 Zeilen, inklusive 30
Zeilen Dokumentation! Mein Projekt hat sich also gerade um fast 100%
aufgeblasen, nur damit ich es bei Systemstart starten lassen kann.
</p>

<p>
Doch das ist nicht das eigentliche Problem, daran hat man sich ja gewöhnt. Die
richtigen Schmerzen spürt man, wenn man sich um das daemonizing kümmert. Hierzu
gibt es zwei Möglichkeiten:
</p>

<ol>
<li>
  Man benutzt <code>--background</code> und <code>--make-pidfile</code> beim
  Aufruf von <code>start-stop-daemon(8)</code> im Initscript. Der Nachteil:
  <code>start-stop-daemon</code> setzt <code>/dev/null</code> als stdin, stdout
  und stderr. Plötzlich braucht man also eigenes Logging, und damit verbunden
  wieder Parameter, also auch Parameterverarbeitung, eine Hilfefunktion,
  Dokumentation.
</li>
<li>
  Man implementiert das daemonizing selbst und benutzt Ausgabeumlenkung im
  Initscript. Hierzu gibt es zwar das Modul <code>Proc::Daemon</code>, das
  stellt aber eine zusätzliche Dependency dar, da es nicht mit perl
  mitgeliefert wird. In der Vergangenheit habe ich die Erfahrung gemacht, dass
  sehr viele Nutzer (auch erfahrene Nutzer) vor CPAN zurückschrecken. Das
  Modulsystem von Perl ist leider zu unbekannt. Daraus resultiert, dass ich
  daemonizing selbst implementieren müsste, was zwar möglich ist (und auch
  nicht mehr als ca. 50 Zeilen Code sind), aber das ist Code, der nicht in mein
  Script (!) gehört. Das soll kurz und prägnant bleiben, ohne Code, der nicht
  dem eigentlichen Zweck dient.
</li>
</ol>

<p>
Nun kann man natürlich einen Kompromiss wählen und
<code>start-stop-daemon</code> zum daemonizing benutzen, aber via
<code>Sys::Syslog</code> nach syslog loggen. Das ist gut, denn damit bekommen
wir die aktuelle Uhrzeit, den Programmnamen, die PID und flexible
Umlenkungsmöglichkeiten (remote logging) beim Logging geschenkt. Allerdings
sind viele Scripts so gestaltet, dass sie relativ viel loggen. Das syslog ist
(meiner Ansicht nach) wichtigen Meldungen vorbehalten. Ich würde also deutlich
weniger loggen als in meiner ursprünglichen Version in der screen-Session, was
schlecht ist – logs helfen enorm beim Verstehen/Analysieren von Problemen. Die
Lösung dafür ist also, <code>rsyslogd</code> so zu konfigurieren, dass er die
Ausgabe für den RaumZeitMPD in eine eigene Datei schreibt:
</p>

<pre>
$ cat /etc/rsyslog.d/raumzeitmpd.conf
# Log all lines from RaumZeitMPD to /var/log/raumzeitmpd.log (without syncing)
# and discard them.
:programname, isequal, "RaumZeitMPD"  -/var/log/raumzeitmpd.log
:programname, isequal, "RaumZeitMPD" ~
</pre>

<p>
Doch damit ist aus dem Script auf einmal ein vollwertiger Daemon geworden, den
ein Gelegenheitshacker nicht mehr interaktiv "mal eben" erweitern kann – nach
dem aufwändigen Clonen des Codes und Installieren der Abhängigkeiten müsste er
nun auch noch seinen syslog-daemon umkonfigurieren, neustarten und permanent
<code>tail -f /var/log/raumzeitmpd.log</code> in einem anderen Fenster laufen
lassen.
</p>

<p>
Wie hilft hier nun systemd? Es nimmt mir die ganze Arbeit ab. Ich muss mich
nicht darum kümmern, beim starten zu daemonizen (oder im Vordergrund zu
bleiben, wenn man interaktiv debuggen will). Ich kann in meinem Script einfach
nach stdout und stderr loggen, im service-file <code>raumzeitmpd.service</code>
langt der Eintrag <code>StandardOutput=syslog</code> damit bei Systemstart nach
syslog geloggt wird – interaktive Aufrufe schreiben dennoch nach stdout. Ich
brauche keine Optionen einführen. Mein Script bleibt hübsch und konzentriert
sich auf das Wesentliche.
</p>

<p>
Sobald systemd etwas verbreiteter ist, können wir uns endlich von daemonizing,
logging und anderem obsoleten Unsinn trennen und ohne viel Aufwand einfache
Scripts in sinnvoller Weise deployen.
</p>
