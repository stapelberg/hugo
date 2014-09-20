---
layout: post
title:  "Kurz-Howto: Videos für PDAs konvertieren"
date:   2007-08-21 10:00:00
categories: Artikel
---




<h3>Worum geht’s?</h3>
<p>
Da die meisten PDAs nur begrenzten Speicher haben (in meinem Fall eine 512
MB-SD-Karte) und außerdem ohnehin weniger Pixel darstellen können, als PCs,
lohnt es sich, vorhandene Videos zu konvertieren. Wir werden dies mithilfe von
<code>mencoder</code> durchühren, der für alle gängigen Betriebssysteme
verfügbar ist.
</p>

<p>
Ich werde die Schritte am Beispiel eines Linuxsystems durchführen, für andere
Systeme können also eventuell Zusatzschritte notwendig sein.
</p>

<h3>Pakete installieren</h3>

<p>
Bei meinem (Ubuntu-)System ist der mencoder aus dem MPlayer-paket leider ohne
libmp3lame kompiliert, sodass wir nicht die bequeme Methode wählen können. die
libmp3lame können wir jedoch via <code>apt-get</code> installieren:
<code>apt-get install liblame-dev</code>.
</p>

<p>
Anschließend laden wir uns die aktuelle MPlayer-version von <a
href="http://www.mplayerhq.hu" title="MPlayer-Website">der MPlayer-Website</a>
herunter. Wie bei anderen Programmen können wir nach dem entpacken via
<code>tar xfj MPlayer-1.0pre8.tar.bz2</code> in das entsprechende Verzeichnis
wechseln und via <code>./configure &amp;&amp; make mencoder</code> das Programm
kompilieren. Ich persönlich habe es manuell nach <code>/usr/local/bin</code>
verschoben und vorher die bestehende (Ubuntu-)Version umbenannt – einfach
<code>make install</code> benutzen sollte aber auch gehen, gerade wenn man
keinen MPlayer via <code>apt-get</code> installiert hat.
</p>

<h3>Datei konvertieren</h3>

<p>
Unterstützt werden alle Dateitypen/Codecs, die auch MPlayer kann – installiert
euch also die passenden Codecs, wenn es nicht klappen sollte (Anleitungen dazu
gibt’s im Web).
</p>

<p>
Wir rufen nun <code>mencoder input.avi -ovc lavc -lavcopts
vcodec=mpeg4:vbitrate=224 -ffourcc divx -srate 22050 -af resample=22050,volnorm
-vf crop=480:288 -oac mp3lame -lameopts cbr:br=32 -o output.avi</code> auf. Das
klingt zunächst kompliziert, doch pflücken wir die ganzen Optionen in Ruhe
auseinander:
</p>
<ul>
	<li><strong>input.avi</strong>: Dies ist die Eingangsdatei.</li>
	<li><strong>-ovc lavc</strong>: Die Bibliothek libavcodec soll benutzt werden.</li>
	<li><strong>-lavcopts vcodec=mpeg4:vbitrate=224</strong>: Als Codec verwenden wir MPEG4 (DivX) mit der Bitrate 224 kbit/s.</li>
	<li><strong>-ffourcc divx</strong>: Als FourCC soll „divx” gesetzt werden. Daran erkennt der Player später, dass es sich um eine DivX-Datei handelt.</li>
	<li><strong>-srate 22050</strong>: Die Sounddatenrate wird auf 22 kHz heruntergesetzt, das langt für Kopfhörer.</li>
	<li><strong>-af resample=22050,volnorm</strong>: Der Audiofilter „resample” wird benutzt um die Bitrate zu senken, die Lautstärke wird dabei auf den Normalpegel gesetzt.</li>
	<li><strong>-vf crop=480:288</strong>: Der Videofilter „crop” verkleinert das Bild auf 480x288 Pixel.</li>
	<li><strong>-oac mp3lame</strong>: Die libmp3lame wird zum Encodieren des Tons verwendet.</li>
	<li><strong>-lameopts cbr:br=32</strong>: Wir verwenden Constant Bitrate mit 32 kbit/s (niedrigere Bitrates machen ab und zu Probleme).</li>
	<li><strong>-o output.avi</strong>: Und ausgegeben wird die fertige Datei in output.avi</li>
</ul>
<p>
OK – nun lassen wir ihn durchlaufen; das Encodieren dauert natürlich eine
Weile. Bei mir waren es ungefähr 10 Minuten für 550 MB (1 Stunde Video im
DivX-Format, meinen Rechner findet man auf der <a href="/MeinePCs" title="Meine
PCs">Meine PCs-Seite</a>, die Konvertierung fand auf A64x statt). Die fertige
Datei war dann 100 MB groß, es lassen sich also auf eine SD-Karte ca 4-5
Stunden Video abspeichern.
</p>

<p>
Man kann diesen Befehl natürlich auch als Alias in der Shell definieren oder
sich ein kleines Script erstellen, das könnte zum Beispiel so aussehen:
</p>
<pre>
#!/bin/sh

MENC_PATH=/usr/local/bin/mencoder

if [ -z "${2}" ]; then
	echo "Keine Parameter angegeben, Syntax: ${0} &lt;Eingangsdatei&gt; &lt;Ausgabedatei&gt;"
	exit 0
fi

echo "Konvertiere ${1} für PDAs in Datei ${2}..."
${MENC_PATH} "${1}" -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=224 -ffourcc divx -srate 22050 \
-af resample=22050,volnorm -vf crop=480:288 -oac mp3lame -lameopts cbr:br=32 -o "${2}"
</pre>

<h3>Abspielen auf dem PDA</h3>
<p>
Der Player <a href="http://www.hpcfactor.com/downloads/tcpmp/"
title="TCPMP-Website">TCPMP</a> ist hierfür meine Empfehlung. Er beherrscht –
soweit ich das testen konnte – die meisten Formate und kommt mit den von
<code>mencoder</code> erstellen Dateien problemlos klar.
</p>

<p>
Mein PDA hat eine 300 MHz-CPU und Windows Mobile 5.01. Die Wiedergabe läuft
sehr flüssig, ich konnte bisher kein Stocken erkennen.
</p>
