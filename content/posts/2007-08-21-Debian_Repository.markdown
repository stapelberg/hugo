---
layout: post
title:  "Kurz-Howto: Eigenes Debian-Repository aufbauen"
date:   2007-08-21 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Debian_Repository
---

{{< note >}}

Linux/UNIX-kenntnisse erforderlich! (in den Bereichen dpkg, apt-get und gpg)

{{< /note >}}

<h3>Worum geht’s?</h3>
<p>
Ein eigenes Debian-Repository ist nützlich, wenn man privat Pakete verteilen
möchte – zum Beispiel an den Freundeskreis oder in der Firma um die
Installation zu erleichtern. Die Installation verläuft recht einfach, wenn man
mal raus hat, wie’s geht.
</p>
<p>
Wir werden uns also ein eigenes Debian-Repository einrichten, was nach
entsprechendem Eintrag in der <code>/etc/apt/sources.list</code> via
<code>apt-get</code> auf Debian- und debianbasierten Systemen (wie zum Beispiel
Ubuntu) benutzt werden kann. Dies beeinhaltet auch das Signieren mit <a
href="http://gnupg.org/" title="GnuPG" target="_blank">GnuPG</a>, sodass keine
Warnung angezeigt wird.
</p>

<h3>Datei/Ordner-Struktur</h3>
<p>
Am besten legt man sich einen neuen Ordner an, in dem die Pakete selbst und die
notwendigen zusätzlichen Dateien abgelegt werden. Dies kann direkt im
httpdocs-Verzeichnis sein, verrät jedoch neugierigen Besuchern dann sofort,
wenn man einen Fehler gemacht hat. Ich bevorzuge es daher, lokal alle Dateien
abzulegen und diese erst am Ende auf den Webserver zu übertragen/ins
httpdocs-Verzeichnis zu verschieben.
</p>
<p>
Ich gehe davon aus, dass wir mindestens ein <code>.deb</code>-Paket haben
(sonst würde ein Repository auch Unsinn sein ;-)), das wir verteilen möchten.
Schauen wir uns an, was wir für Dateien am Ende haben werden:
</p>
<ul>
	<li>
	<b>Packages</b>(.gz): Diese (komprimierte) Datei enthält den Inhalt der
	<code>control</code>-Dateien der Packages sowie deren MD5-Summe zur
	Verifikation des Downloads.
	</li>
	<li>
	<b>Release</b>: Diese Datei enthält die MD5- und SHA1-Hashes sowie die
	Größe der Packages-Datei.
	</li>
	<li>
	<b>Release.gpg</b>: Dies ist die Signatur für die Release-Datei.
	Dadurch kann <code>apt-get</code> verifizieren, dass die Datei
	vertrauenswürdig ist (bei entsprechendem Vorhandensein des Publickeys).
	</li>
	<li>
	…und natürlich die Pakete selbst.
	</li>
</ul>

<h3>1.) Die Packages- und Release-Datei erzeugen</h3>
<p>
Hierzu benutzen wir das Programm <code>apt-ftparchive</code>, nachdem wir in
unser vorhin angelegtes Packageverzeichnis gewechselt haben:
</p>
<pre>$ cd Repository
$ apt-ftparchive packages . &gt; Packages</pre>
<p>
Diese Datei müssen wir nun noch mit <code>gzip</code> komprimieren:
</p>
<pre>$ gzip -9 Packages</pre>
<p>
Nun erzeugen wir mit dem selben Programm noch die Release-Datei:
</p>
<pre>$ apt-ftparchive release . &gt; Release</pre>

<h3>2.) GPG-Signatur erstellen</h3>
<h4>2.1) Schlüssel erzeugen</h4>
<p>
Wenn man GPG bereits verwendet hat, hat man höchstwahrscheinlich bereits einen
Schlüssel erzeugt, wenn nicht, kann man das folgendermaßen nachholen:
</p>
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
<p>
Wir haben uns hierbei nun einen DSA/ElGamal-Schlüssel erzeugt, der 2048 Bits
groß ist und 5 Jahre gültig sein wird. Er ist auf meinen Namen ausgestellt und
die E-Mail-Adresse sollte durch eine gültige ersetzt werden ;-).
</p>
<p>
Hinweis: Man sollte sich auch eine Widerrufsurkunde via <code>gpg --output
revoke.asc --gen-revoke "Michael Stapelberg"</code> erstellen, falls man das
eingegeben Mantra irgendwann vergisst und der Schlüssel daher nicht mehr
benutzt werden soll. Details gibts in der <a
href="http://www.gnupg.org/gph/de/manual/c146.html"
title="GPG-Anleitung">(deutschen) GPG-Anleitung</a>.
</p>
<p>
<b>Wichtig:</b> Der öffentliche Teil des Schlüssels muss natürlich irgendwie
zugänglich sein, man sollte ihn daher auf einem Keyserver oder auf dem eigenen
Server ablegen. Exportieren kann man diesen Teil mit folgendem Befehl (der
öffentliche Teil befindet sich dann in der Datei <code>PublicKey</code>):
</p>
<pre>$ gpg --armor --export "Michael Stapelberg" &gt; PublicKey</pre>

<h4>2.2) Release-Datei signieren</h4>
<p>
Nun signieren wir mit unserem Schlüssel noch die Release-Datei:
</p>
<pre>$ gpg --output Release.gpg -ba Release</pre>
<p>
…und schon haben wir’s geschafft. Jetzt müssen die Dateien nur noch in das
httpdocs-Verzeichnis des Webservers und fertig ist unser Repository.
</p>

<h3>Das Repository benutzen</h3>
<p>
Nehmen wir an, dass wir die Dateien irgendwie nach
<code>http://michael.stapelberg.de/Debian</code> geschafft haben, so können wir
das Repository benutzen, in dem wir den folgenden Eintrag in die Datei
<code>/etc/apt/sources.list</code> hinzufügen:
</p>
<pre>deb http://michael.stapelberg.de/Debian ./</pre>
<p>
Einmalig muss auch der öffentliche Teil des Schlüssels, den wir zum Signieren
mit GPG verwendet haben, <code>apt-get</code> bekannt gemacht werden (ich gehe
davon aus, dass er sich in der Datei <code>PublicKey</code> befindet):
</p>
<pre>apt-key add PublicKey</pre>
<p>
Nach einem <code>apt-get update</code> können wir nun die neuen Pakete
installieren :-).
</p>
