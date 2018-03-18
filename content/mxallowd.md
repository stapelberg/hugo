---
title: "mxallowd"
date: 2014-11-07T09:49:22+01:00
---

<div id="ml">
		<p> To my english speaking visitors: There is an <a href="/mxallowd.en" id="ml_link">english version</a> of this page. </p>
	</div>
	<div id="content">
<p>
  <code>mxallowd</code> ist ein Daemon für Linux/Netfilter (via
  <code>libnetfilter_queue</code>) oder BSD/pf (via pflog), der eine Verfeinerung
  der <a href="http://nolisting.org/" title="nolisting.org">nolisting</a>-
  Methode darstellt. Hierbei werden für eine Domain zwei MX-Einträge vom
  Nameserver ausgeliefert, wobei auf der IP-Adresse des ersten MX-Eintrags kein
  Mailserver läuft. Einige Spammer versuchen nun, nur auf den ersten Mailserver
  Spam auszuliefern und werden damit keinen Erfolg haben. Auf der IP-Adresse des
  zweiten MX-Eintrags läuft dann ein richtiger Mailserver, der die E-Mails
  entgegennimmt. Echte Mailserver probieren – im Gegensatz zu Spammern – alle
  MX-Einträge in der angegeben Reihenfolge (geordnet nach Priorität) durch, bis
  sie die Mail zustellen können. Somit kommen echte Mails an und Spam bleibt
  draußen.
</p>

<p>
  Das Problem beim nolisting ist nun, dass einige Spammer (vermutlich
  aufgrunddessen) direkt den zweiten MX-Eintrag benutzen („direct-to-second-mx”).
  Hier kommt nun <code>mxallowd</code> ins Spiel: Auf den zweiten Mailserver darf
  man sich nicht verbinden (das Paket wird einfach via <code>netfilter/iptables</code>
  verworfen), außer, wenn man es zuvor beim ersten Mailserver probiert hat.
</p>

<p>
  Dieses Problem hätte man prinzipiell auch nur via <code>iptables</code> mit
  dem Modul <code>ipt_recent</code> lösen können, wenn es nicht ein kleines
  Problem dabei gäbe: Einige Anbieter (wie zum Beispiel Google Mail) verwenden
  zwar den gleichen DNS-Namen, aber unterschiedliche IP-Adressen im selben
  Zustellzyklus. Das heißt, dass <code>ipt_recent</code>, welches ausschließlich
  auf IP-Adress-Basis arbeitet, E-Mails von Google nicht durchlässt.
  <code>mxallowd</code> fügt daher alle IP-Adressen des DNS-Eintrags in die
  Whitelist ein (außer, wenn man die Option <code>--no-rdns-whitelist</code>
  angibt).
</p>

<h2>Installation unter Linux</h2>

<p>
  Damit neue Verbindungen an <code>mxallowd</code> geleitet werden, muss man
  folgende <code>iptables</code>-Regel hinzufügen:
</p>
<pre>iptables -A INPUT -p tcp --dport 25 -m state --state NEW -j NFQUEUE --queue-num 23</pre>

<p>
  Falls das Einfügen dieser Regel nicht klappt, muss zuvor via <code>modprobe
  nfnetlink_queue</code> das Queue-Modul geladen werden.
</p>
<p>
  Die Regel kann man selbstverständlich anpassen, sodass zum Beispiel nur an
  bestimmte IP-Adressen gerichtete Verbindungen gefiltert werden, oder dass
  Verbindungen von bestimmten IP-Adressen von vorneherein akzeptiert werden
  (<code>-j ACCEPT</code> am Ende).
</p>

<h2>Installation unter BSD</h2>

<p>Eine <code>/etc/pf.conf</code> könnte so aussehen:</p>

<pre>table <mx-white> persist

real_mailserver="192.168.1.4"
fake_mailserver="192.168.1.3"

real_mailserver6="2001:dead:beef::1"
fake_mailserver6="2001:dead:beef::2"

pass in quick log on fxp0 proto tcp from <mx-white> \
             to $real_mailserver port smtp
pass in quick log on fxp0 inet6 proto tcp from <mx-white> \
             to $real_mailserver6 port smtp
block in log on fxp0 proto tcp \
              to { $fake_mailserver $real_mailserver } port smtp
block in log on fxp0 inet6 proto tcp \
              to { $fake_mailserver6 $real_mailserver6 } port smtp
</pre>

<p>
  Wichtig dabei ist, dass die Table <code>mx-white</code> existiert und dass
  sowohl die pass- als auch die block-Regeln loggen.
</p>

<p>
  Wenn man ein anderes pflog-interface verwendet, kann man mxallowd das via Parameter mitteilen.
</p>

<h2>Hilfe, ich kann keine Mails mehr versenden!</h2>

<p>
  Das stimmt – wenn du den selben Mailserver auch verwendest, um Mails zu
  versenden, probiert dein Mailclient in der Regel nur eine Verbindung. Ich würde
  raten, die Mails über SMTPS (SSL) zu versenden, denn dieser Port (465) wird
  nicht von <code>mxallowd</code> gefiltert. Ansonsten kannst du deinen
  Mailserver auch zusätzlich auf einem anderen Port laufen lassen, den nur zu
  benutzt (Spammer treiben nicht den Aufwand, einen Portscan durchzuführen,
  wenn sie nicht mal standardkonforme Mailer verwenden…). Falls du eine fixe
  IP-Adresse hast, kannst du diese natürlich auch via <code>iptables</code>
  whitelisten:
</p>
<pre>iptables -I INPUT 1 -p tcp --dport 25 --s 192.168.2.3 -j ACCEPT</pre>
</div>
	<h3>Herunterladen</h3>
	<ul id="downloads"><li><a class="download_filename" href="/mxallowd/mxallowd.1.9.tar.bz2"><span class="download_name">mxallowd 1.9</span></a> (<span class="download_size">33K</span>, <a class="download_gpg" href="/mxallowd/mxallowd.1.9.tar.bz2.asc">GPG-Signatur</a>)</li></ul>
	<h3>Lizenz</h3>
	<p><span class="name">mxallowd</span> ist freie Open-Source-Software unter der <span class="license">GPL2</span>.</p>
	<div id="development">
		<h3>Entwicklung</h3>
		<p>Der aktuelle Entwicklungsstand kann <a class="dev_url" href="http://code.stapelberg.de/git/mxallowd">in gitweb</a> verfolgt werden.</p>
	</div>
	<h3>Feedback</h3>
	<p>Solltest du mir eine Nachricht zukommen lassen wollen, <a href="/Impressum">schreib mir doch bitte eine E-Mail</a>.</p>
</div>
