---
layout: post
title:  "Tor auf OpenBSD"
date:   2008-08-09 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Tor_auf_OpenBSD
---



<img src="/Bilder/OpenBSD.gif" align="left">
<p>
Da ein Server bei einem Anbieter mit einem neueren Kernel als 2.6.18-4 nicht
bootet und ich nicht nachschauen konnte, woran das lag (der Anbieter bietet
keinen Remote-Zugriff via KVM-over-IP an), der Server mit dem alten Kernel aber
instabil lief, habe ich mich für ein anderes Betriebssystem entscheiden müssen.
Die Wahl fiel auf OpenBSD, da ich keine Wahl hatte :-). Wie man mit OpenBSD nun
einen Tor-Node aufzieht und welche Schwierigkeiten dabei auftreten können,
möchte ich hier dokumentieren.
</p>

<p>
Der Einsatzzweck für den Server ist einzig und allein Tor (in Zukunft könnten
weitere Anonymisierungsdienste folgen), sodass man eine relativ klare und
eindeutige Umgebung hat, was die Fehlersuche erleichtert. Zuerst lief auf dem
Server ein Debian 4.0 mit 2.6.18-4-Kernel. Dummerweise enthält der Treiber für
die SiS-Billignetzwerkkarte (da ist ein ASRock-Mainboard im Server, aber gut,
irgendwo muss der Dumpingpreis ja herkommen) einen Bug, sodass ab einer
gewissen Auslastung beziehungsweise nach einem gewissen Zeitpunkt keine Pakete
mehr angenommen/verarbeitet werden. Stattdessen wird das syslog mit Meldungen
über Null Pointer überflutet („NULL pointer encountered in Rx ring, skipping”).
</p>

<p>
Dieser Fehler ist in neueren Versionen behoben, sodass ein Upgrade anstand.
Dieses ging jedoch schief, aus mir unbekannten Gründen. Die Festplatte wird
anscheinend gar nicht erst gefunden, denn es tauchen keinerlei Meldungen über
den Bootvorgang des neuen Kernels im syslog auf. Die Konfiguration der beiden
Kernel ist identisch, beides sind Debian-Standardkernel.
</p>

<p>
Wenn nun also Linux nicht läuft, warum dann nicht gleich ein BSD? Leider bietet
der Anbieter (zur Zeit) noch kein NetBSD in seinem System an (und auch kein
FreeBSD), sodass ich ein OpenBSD 4.2 installiert habe. Bei BSD habe ich den
Eindruck, dass es so ist, dass sie entweder garnicht oder aber stabil laufen.
Bisher wurde ich in dieser Theorie noch nicht widerlegt ;-).
</p>

<h2>Tor kompilieren</h2>

<p>
Die ersten Schwierigkeiten hat man, wenn man ohne Vorwissen versucht, Software
unter OpenBSD zu kompilieren. Unter OpenBSD gibt es, wie bei den anderen BSDs
auch, das Ports-System, das man sich mit folgenden Befehlen herunterladen kann:
</p>
<pre># cd /usr
# ftp ftp://ftp.openbsd.org/pub/OpenBSD/4.2/ports.tar.gz
# tar xfz ports.tar.gz</pre>

<p>
Bevor man mit dem Kompilieren und Installieren von Software aus den Ports
anfangen kann, sollte man sich jedoch die beiden Sets xbase und xshare
nachinstallieren (es sei denn, man hat sie schon bei der Installation mit
angegeben, was bei einem Standardsystem nicht der Fall ist):
</p>
<pre># cd
# ftp ftp://ftp.bytemine.net/pub/OpenBSD/4.2/i386/xshare42.tgz
# ftp ftp://ftp.bytemine.net/pub/OpenBSD/4.2/i386/xbase42.tgz
# cd /
# tar xfz /root/xshare42.tgz
# tar xfz /root/xbase42.tgz</pre>

<p>
Da die Ports keine aktuelle Version von Tor enthalten, bauen wir uns Tor
einfach komplett selbst, aus dem Subversion-Repository. Dafür brauchen wir
natürlich subversion:
</p>
<pre># cd /usr/ports/devel/subversion
# export FLAVOR="no_ap2 no_bindings"
# make install
# export FLAVOR=""</pre>
<p>
Die FLAVOR-Variable gibt an, mit welchen Optionen wir subversion kompilieren
wollen und ist mit den Use-Flags bei Gentoo vergleichbar. In diesem Falle
brauchen wir keine Bindings für externe Sprachen und möchten auch nicht, dass
automatisch ein Apache 2 mitkommt.
</p>

<p>
Außerdem brauchen wir noch eine aktuelle OpenSSL-Version, da Tor in Kombination
mit OpenSSL unter 0.9.7k einen Bug hat. Leider gibt es OpenSSL nicht in den
Ports, da es Bestandteil von OpenBSD ist. Selbst in OpenBSD 4.3 kommt
allerdings keine Version mit, die aktuell genug ist. Daher bauen wir uns
OpenSSL selbst:
</p>

<pre># ftp http://www.openssl.org/source/openssl-0.9.8h.tar.gz
# tar xfz openssl*
# cd openssl*
# ./config --prefix=/usr/local --openssldir=/usr/local/openssl &amp;&amp; make &amp;&amp; make install</pre>

<p>
Bevor wir Tor nun kompilieren können, brauchen wir noch autoconf und automake:
</p>
<pre># cd /usr/ports/devel/autoconf
# make install
# cd /usr/ports/devel/automake
# make install</pre>


<p>
Aus dem Subversion-Repository ziehen wir uns jetzt Version 0.2.1.2-alpha, und
kompilieren/installieren sie:
</p>
<pre># cd
# svn co -r 15385 https://tor-svn.freehaven.net/svn/tor/trunk tor
# cd tor
# export AUTOMAKE_VERSION=1.9 AUTOCONF_VERSION=2.59
# ./autogen.sh &amp;&amp; ./configure --with-ssl-dir=/usr/local &amp;&amp; make &amp;&amp; make install</pre>

<p>
Ich bin mir nicht sicher, ob es so gedacht ist, die Umgebungsvariablen
AUTOMAKE_VERSION und AUTOCONF_VERSION zu setzen. Jedenfalls funktioniert es
damit und ohne eben nicht ;-). Wer mehr darüber weiß, möge mich erleuchten.
</p>

<h3>Hinweis: LD_CONFIG</h3>

<p>
Für das Kompilieren von anderer Software (zum Beispiel <a
href="http://collectd.org" title="collectd" target="_blank">collectd</a>, ein
schönes und kleines Programm um RRD-Datenbanken mit dem Systemzustand zu
erstellen) kann es nötig sein, die Umgebungsvariable LD_CONFIG so zu setzen,
bevor man configure aufruft:
</p>
<pre># export LDFLAGS="-L/usr/local/lib -L/usr/X11R6/lib"</pre>
<p>
Ansonsten findet der Linker unter Umständen libexpat nicht (der Grund, warum
wir vorhin xbase und xshare installiert haben). Leider ist die Fehlermeldung
von configure in diesem Fall absolut nicht hilfreich, da nicht die
Compilerausgabe, sondern eine lesbare, vordefinierte Fehlermeldung angezeigt
wird (die aber eben nicht zutrifft).
</p>
<p>
Sollte es immer noch nicht funktionieren, kann man noch manuell <code>ldconfig
/usr/X11R6/lib</code> und <code>ldconfig /usr/local/lib</code> anstoßen.
</p>

<h2>Tor konfigurieren</h2>

<p>
Ich werde hier nicht auf die Konfiguration von Tor im Allgemeinen eingehen
(dazu siehe <a href="http://www.torproject.org" target="_blank"
title="Tor">torproject.org</a>), sondern nur auf die Besonderheiten. Was sofort
auffällt, ist die Fehlermeldung beim Starten von Tor, in der gesagt wird, dass
das Limit für file descriptors (darunter fallen auch Sockets, also auch
Verbindungen) zu niedrig sei. Bei OpenBSD ist das standardmäßig tatsächlich auf
128 gesetzt, bei Linux sind es 1024. Tor geht in der Standardkonfiguration von
1000 nutzbaren file descriptors aus, sodass es auf OpenBSD ohne Nachhilfe nicht
klappt.
</p>

<p>
Da auf dem Server nichts anderes als Tor läuft, drehen wir die Anzahl an
Verbindungen ordentlich hoch. In die 512 MB RAM sollte einiges an
Datenstrukturen für Sockets passen :-). Hierzu muss man insbesondere die
Kerneleinstellung <code>kern.maxfiles</code> hochsetzen, sonst kommen später
trotz hohem ulimit Fehlermeldungen, dass er keine file descriptors mehr habe:
</p>
<pre># echo kern.maxfiles=16384 &gt;&gt; /etc/sysctl.conf</pre>
<p>
Für den laufenden Betrieb ändert man den Parameter mit <code>sysctl -w
kern.maxfiles=16384</code>. Anschließend setzt man das Limit hoch:
</p>
<pre># ulimit -n 8192</pre>
<p>
Diese Änderung kann man dann in <code>/etc/login.conf</code> fest eintragen.
</p>

<p>
Ab jetzt kann man sich in der Tor-Konfiguration auch 8000 Verbindungen
(ConnLimit) erlauben.
</p>

<h2>Mehr Bandbreite</h2>

<p>
Wenn man dann Tor eine Weile laufen hat, wird einem auffallen, dass die
Bandbreitenauslastung bei ca. 1 MB/s pro Sekunde aufhört. Unter Linux schaffte
der Server deutlich mehr, also muss man noch ein paar Einstellungen optimieren.
</p>

<p>
Ebenso wie bei den file descriptors kommt OpenBSD bei den TCP Window Sizes mit
sehr altmodischen Einstellungen. Für Verbindungen mit sehr viel Traffic wird in
der FAQ empfohlen, die Window Sizes manuell auf 128 KB zu erhöhen, ich hatte
mit 256 KB bei einer 100 MBit/s-Leitung bessere Erfahrungen. Außerdem erhöhen
wir weitere Limits und setzen die Zeit, die geschlossene Verbindungen offen
bleiben, herunter (ebenfalls in der <code>/etc/sysctl.conf</code>):
</p>
<pre>net.inet.tcp.sendspace=262144
net.inet.tcp.recvspace=262144
net.inet.ip.maxqueue=4096
kern.somaxconn=512
net.inet.tcp.rstppslimit=512
kern.maxclusters=128000
net.inet.tcp.keepinittime=10
net.inet.tcp.keepidle=30
net.inet.tcp.keepintvl=30</pre>

<h2>Fertig</h2>

<p>
So, fertig. Der Server packt nun ca. 9 MB/s Bandbreite statt 1-2 MB/s, außerdem
läuft Tor stabil mit vielen Verbindungen und geringer Systemauslastung (20-30%
CPU auf einem Sempron 2800+, ca. 100 MB RAM). Ich freue mich natürlich über
weitere Tipps/Hinweise und beantworte gerne weitere Fragen.
</p>

<p>
<strong>Update:</strong> Zu früh gefreut. Nach ein paar Tagen steigt die
Auslastung von Tor (wie überall), nur leider skaliert OpenBSD dann nicht mehr
so gut wie Linux auf derselben Hardware. Mittlerweile läuft auf dem Server
wieder Linux (mit neuerem Kernel) und damit erreicht Tor ca. 1 MB/s mehr als
unter OpenBSD. Ähnliche Erfahrungen hat mindestens ein Tor-Entwickler, mit dem
ich darüber gesprochen habe, auch gemacht.
</p>
