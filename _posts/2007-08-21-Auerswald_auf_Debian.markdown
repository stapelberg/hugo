---
layout: post
title:  "Kurz-Howto: Auerswald-Telefonanlage unter Debian benutzen"
date:   2007-08-21 10:00:00
categories: Artikel
---



<p>
Da die Installation der Programme zum Verwalten einer Auerswald-Telefonanlage
(COMpact 4410 USB in meinem Fall) dank eigenem Auerswald-Kerneltreiber, nicht
verfügbarem Debian-Modul und Javas problematischer Lizenz nicht ganz so trivial
ist, werde ich hier eine kurze Anleitung geben.
</p>

<h3>Kernel-Quelltext installieren</h3>

<p>
<i>Benutzer, die einen eigenen Kernel verwenden, können diesen Schritt
überspringen.</i>
</p>

<p>
Zuerst benötigen wir den Quelltext des Kernels, den wir benutzen. Welche
Version installiert ist, sieht man mit dem Befehl <code>uname -r</code>. Unter
Debian kann man sich nun den Quelltext mittels <code>apt-get install
kernel-source-&lt;version&gt;</code>, also bei mir zum Beispiel
<code>kernel-source-2.4.27</code>, installieren. (Hinweis: Auf Ubuntu heißt das
Paket <code>linux-source</code>.)
</p>

<p>
Anschließend kopieren wir die Konfiguration mit <code>cp
/boot/config-&lt;version&gt; /usr/src/linux/.config</code> (bei mir also
<code>cp /boot/config-2.4.27 /usr/src/linux</code>), sodass wir uns nun einen
identischen Kernel kompilieren könnten.
</p>

<h3>Auerswald-USB-Kernel-Modul installieren</h3>

<p>
Den entsprechenden aktuellen Treiber kann man sich auf <a
href="http://www.auerswald.de" target="_blank">www.auerswald.de</a>
herunterladen (unter „Service”, „Download”, „Software, Treiber”). Zum Zeitpunkt
dieser Anleitung sind Version 2.1.12 für Kernel 2.6 und Version 1.2.8 für
Kernel 2.4 aktuell.
</p>

<p>
Die Installation verläuft hier noch problemlos (<code>make &amp;&amp; make
install</code>), geladen wird das Kernelmodul dann mit <code>modprobe
auerswald</code>, wenn er in <code>lsmod | grep auerswald</code> aufgeführt
wird, hat’s geklappt.
</p>

<p>
Falls die Devicenodes <code>/dev/usb/auer*</code> nicht existieren, muss man
sie mit dem Befehl <code>for i in `seq 0 15` ; do mknod -m 666 /dev/usb/auer$i
c 180 `expr 112 + $i` ; done</code> erzeugen.
</p>

<h3>Java installieren</h3>

<p>
So, nun geht’s ans Eingemachte – nicht nur weil Java unter Debian ohnehin schon
umständlich zu installieren ist, sondern auch weil Auerswald anscheinend denkt,
dass Linux ein Synonym für SuSE ist und wir daher die mitgelieferten
Startscripts etwas umbiegen müssen.
</p>

<p>
Da die Lizensbedingungen von Java verhindern, dass daraus ein Debian-Paket
gebaut und zum Download gestellt werden kann, müssen wir uns eben selbst eins
bauen. Dazu installieren wir das Paket <code>java-package</code>, welches das
freundlicherweise für uns erledigt.
</p>

<p>
Von <a href="http://java.sun.com/javase/downloads/index.jsp" title="Java
Download">java.sun.com</a> brauchen wir nun die aktuelle Version des JDK (5.0
Update 7). Die Datei sollte <code>jdk-1_5_0_07-linux-i586.bin</code> heißen.
</p>

<p>
Wir erstellen nun das Paket mit <code>fakeroot make-jpkg
jdk-1_5_0_07-linux-i586.bin</code> und installieren es mit <code>dpkg -i
sun-j2sdk1.5_1.5.0+update07_i386.deb</code>. Nach erfolgreicher Installation
legen wir noch mit <code>ln -s /usr/lib/j2sdk1.5-sun /usr/lib/java</code> einen
Symlink an, der beim Aktualisieren von Java angepasst werden sollte.
</p>

<h3>Auerswald-Scripts anpassen</h3>

<p>
Wenn man nun die einzelnen Programme von Auerswald installiert, kommen diese
mit einem Startscript namens <code>start14.sh</code>, in dem am Anfang die
Umgebungevariable JAVA_HOME erkannt werden soll. Das klappt jedoch anscheinend
nur auf SuSE-Systemen, sodass wir den Pfad einfach manuell setzen. Dazu löschen
wir von der Zeile „# get correct JAVA_HOME entry” bis „if test -z $JAVA_HOME”
alle Zeilen und fügen stattdessen die Zeile „JAVA_HOME=/usr/lib/java” ein. Der
Anfang der Datei sieht dann so aus:
</p>
<pre>#!/bin/sh
#
# start script (java 1.4.x oder neuer)
#
JAVA_HOME=/usr/lib/java
if test -z $JAVA_HOME
then
    echo Die Datei "$JAVA_INC" ist fehlerhaft.
    echo Bitte passen Sie die Datei an Ihr System an.
    exit 1
fi
</pre>

<p>
OK, das war’s – nun können wir die Programme wie in den
<code>LIESMICH</code>-Dateien beschrieben starten.
</p>
