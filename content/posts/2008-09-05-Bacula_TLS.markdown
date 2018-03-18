---
layout: post
title:  "Kurz-Howto: Bacula und TLS mit CACert"
date:   2008-09-05 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Bacula_TLS
---



<p>
Da das Einrichten von Bacula mit TLS einige kleine Hürden beinhaltet, möchte
ich hier eine Anleitung geben. Ich werde nur auf Zertifikate, die durch <a
href="http://www.cacert.org/" target="_blank" title="CACert">CACert</a>
ausgestellt wurden, eingehen.
</p>

<p>
Wir benötigen auf dem Director, dem Storage Daemon und dem zu sichernden Client
jeweils ein Zertifikat, bestehend aus Private Key und Certificate. Diese
sollten jeweils auf den Full Qualified Domain Name ausgestellt werden, der
ohnehin benutzt werden muss, da der File Daemon den Storage Daemon unter der
selben Adresse erreichen muss, wie der Director. Früher kam hier ein VPN ins
Spiel, mittlerweile verwende ich statische IPv6-Adressen dafür.
</p>

<p>
Bezüglich IPv6 ist anzumerken, dass Bacula bei Hostnames die IPv4-Adressen
bevorzugt. Man muss sich also einen extra Hostname für IPv6 anlegen oder direkt
die Adresse verwenden.
</p>

<p>
<strong>Update:</strong> Mittlerweile (Mai 2009) wurde dieses Problem in der
aktuellen Bacula-SVN-Version behoben und Bacula bevorzugt nun IPv6-Adressen.
</p>

<h2>Erzeugen der Zertifikate</h2>

<p>
Auf Debian- und Gentoo-Systemen gibt es das Paket <code>ca-certificates</code>,
welches unter Anderem die CACert-Zertifikate enthält. Dieses sollte man vorher
installieren.
</p>

<p>
Folgendermaßen wird ein Private Key und ein Certificate Request erstellt (auf
jedem Rechner ausführen):
</p>
<pre>cd /etc/ssl/private
openssl req -newkey rsa:4096 -subj /CN=ipv6.server.de -nodes -keyout ipv6.server.de.key -out ipv6.server.de.csr</pre>

<p>
Den Certificate Request aus ipv6.server.de.csr geben wir nun bei CACert ein und
lassen ihn als Server-Zertifikat mit dem Level 1-Zertifikat signieren.
Theoretisch ginge auch ein Level 3-Zertifikat, dabei muss man dann allerdings
in Bacula ein ganzes Verzeichnis an Zertifikaten angeben, statt nur einer
CA-Zertifikat-Datei. Da wir ohnehin keinen Benutzer im Spiel haben, der mit
größerer Wahrscheinlichkeit nur ein Level 3-Zertifikat hat, nehmen wir also der
Einfachheit wegen ein Level 1-Zertifikat.
</p>

<p>
(Hinweis: Andere Tutorials erstellen Private Key und Certificate Request
aufwändiger, mit drei Befehlen und dem Entfernen eines zuvor gesetzten
Passworts &ndash; das ist nicht nötig. Außerdem beschleunigt die Angabe von
<code>-subj /CN=</code> das Verfahren, da alle anderen Informationen von CACert
ohnehin nicht ausgewertet werden und daher beliebig gesetzt werden können.)
</p>

<p>
Das von CACert signierte Zertifikat wird nun in
<code>/etc/ssl/certs/ipv6.server.de.crt</code> abgelegt.
</p>

<h2>Konfiguration von Bacula</h2>

<p>
In meinem Szenario möchte ich mindestens einen Server sichern, der via Internet
verbunden ist und daher eine sichere Verbindung benötigt. Die anderen Rechner
im LAN sollen jedoch kein SSL verwenden, da es nicht nötig ist. Bacula hat hier
glücklicherweise die Option, TLS beim Director und Storage Daemon zwar zu
aktivieren, jedoch nicht vorauszusetzen. Auf dem File Daemon (also auf dem
Internet-Server) stellt man <code>TLS Require</code> dann aber auf yes und die
beiden anderen Daemons spielen entsprechend mit.
</p>

<h3>Director (bacula-dir.conf)</h3>
<pre>Director {
        Name = fs-dir
        DIRport = 9101
        QueryFile = "/usr/libexec/bacula/query.sql"
        WorkingDirectory = "/var/lib/bacula"
        PidDirectory = "/var/run"
        Maximum Concurrent Jobs = 4
        Password = ""
        Messages = Daemon

        <strong>TLS Enable = yes
        TLS Require = no
        TLS Verify Peer = no
        TLS Certificate = /etc/ssl/certs/stability.crt
        TLS Key = /etc/ssl/private/stability.key
        TLS CA Certificate File = /etc/ssl/certs/root.pem</strong>
}</pre>

<pre>Client {
        Name = server-fd
        Address = ipv6.server.de
        FDPort = 9102 
        Catalog = MyCatalog
        Password = ""
        File Retention = 2 weeks
        Job Retention = 2 weeks
        AutoPrune = yes

        <strong>TLS Enable = yes
        TLS Require = no
        TLS CA Certificate File = /etc/ssl/certs/root.pem</strong>
}</pre>

<p>
Hinweis: Sollte der Storage-Daemon auf einem anderen Rechner laufen als der
Director und die Verbindung zwischen beiden ebenfalls gesichert werden, so muss
man in der Storage-Resource <code>TLS Require</code> auf yes setzen.
</p>

<h3>Storage Daemon (bacula-sd.conf)</h3>

<pre>Storage {
        Name = fs-sd
        SDAddresses = {
      		ipv6 = { addr = 2001:xx:yy:zz; port = 9103; }
	}
        WorkingDirectory = "/var/lib/bacula"
        Pid Directory = "/var/run"
        Maximum Concurrent Jobs = 20

        <strong>TLS Enable = yes
        TLS Require = no
        TLS Verify Peer = no
        TLS Certificate = /etc/ssl/certs/stability.crt
        TLS Key = /etc/ssl/private/stability.key
	TLS CA Certificate File = /etc/ssl/certs/root.pem</strong>
}</pre>

<h3>File Daemon (bacula-fd.conf)</h3>

<pre>Director {
  Name = fs-dir
  Password = ""

  <strong>TLS Enable = yes
  TLS Require = yes
  TLS Verify Peer = no
  TLS CA Certificate File = /etc/ssl/certs/root.pem
  TLS Certificate = /etc/bacula/ipv6.server.de.crt
  TLS Key = /etc/ssl/private/ipv6.server.de.key</strong>
}</pre>


<pre>FileDaemon {
  Name = server-fd
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /var/run/bacula
  Maximum Concurrent Jobs = 20
  FDAddresses = {
  	ipv6 = { addr = 2001:xx:yy:zz; port = 9102; }
  }
  <strong>TLS Enable = yes
  TLS Require = yes
  TLS CA Certificate File = /etc/ssl/certs/root.pem
  TLS Certificate = /etc/bacula/ipv6.server.de.crt
  TLS Key = /etc/ssl/private/ipv6.server.de.key</strong>
}</pre>

<h2>Verify Peer/Allowed CN</h2>
<p>
Im Test hat die Verbindung mit aktiviertem <code>TLS Verify Peer</code> (auf
dem File Daemon) nicht geklappt, die Fehlermeldung <code>Fatal error: TLS
negotiation failed with FD</code> fand ich nicht sehr aussagekräftig. Wer das
Problem bereits behoben hat, möge mir bitte mitteilen, wie. Die Common Names in
den Zertifikaten stimmen mit den Full Qualified Domain Names aus der
Bacula-Konfiguration überein, ich weiß nicht, was da schiefläuft. Ich
persönlich habe dann <code>TLS Verify Peer</code> ausgeschaltet, da mir die
Authentifikation via Passwort und IP-Adresse (ip6tables) ausreicht.
</p>

<p>
Die Angabe von <code>TLS Allowed CN</code> entfällt daher ebenso, das würde die
gültigen Zertifikate nur noch mehr einschränken.
</p>

<h2>Mögliche Probleme</h2>

<p>
Eine Stolperfalle ist es, wenn man Direktiven ändert, dabei aber vergisst, eine
Konfigurationsdatei anzupassen (wenn man die Konfiguration, so wie ich, in
verschiedenen Dateien hat). Kleiner Tipp: <code>fgrep</code> benutzen :-).
</p>

<p>
<strong>Fehler „unable to get local issuer certificate”</strong>: Du hast ein
Level 3-Zertifikat benutzt (oder ähnliches, jedenfalls nicht direkt von der CA
signiert) und lediglich das Root-Zertifikat oder das Level 3-Zertifikat als
<code>TLS CA Certificate File</code> angegeben. Du musst jedoch <code>TLS CA
Certificate Dir</code> auf ein Verzeichnis einstellen, welches beide
Zertifikate enthält, sodass OpenSSL eine gültige Certificate Chain bilden kann
und diese später überträgt.
</p>

<p>
<strong>Fehler „self signed certificate in certificate chain”</strong>: Das
bedeutet, dass du bei einem der Konfigurationseinträge die <code>TLS CA
Certificate File</code>-Direktive nicht richtig gesetzt hast (zum Beispiel auf
class3.pem statt root.pem). OpenSSL bekommt nun vom Server zwar das richtige
CA-Zertifikat zugesandt, denkt aber, dass es selbstsigniert sei, weil es das
Zertifikat vorher nicht selbst geladen hat.
</p>

<h2>Links</h2>
<ul>
	<li>
	<a href="http://www.devco.net/pubwiki/Bacula/TLS/"
	target="_blank">http://www.devco.net/pubwiki/Bacula/TLS/</a> - Gute
	englische Anleitung
	</li>
	<li>
	<a href="http://bacula.org/en/rel-manual/Bacula_TLS_Communication.html"
	target="_blank">http://bacula.org/en/rel-manual/Bacula_TLS_Communication.html</a>
	- Offizielles Handbuch
	</li>
</ul>
