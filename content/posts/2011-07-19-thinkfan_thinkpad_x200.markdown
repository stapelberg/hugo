---
layout: post
title:  "Thinkfan mit einem ThinkPad X200"
date:   2011-07-19 14:30:00
categories: Artikel
Aliases:
  - /Artikel/thinkfan_thinkpad_x200
---



<p>
Mein ThinkPad X200 hat das Problem, dass die Lüftersteuerung nicht gut
funktioniert. Soll heißen: Er dreht gefühlt häufiger hoch als er eigentlich
müsste. Insbesondere wenn sich das Notebook in der Dockingstation befindet,
bemerke ich diesen Effekt – der Lüfter ist dann dauerhaft an.
</p>

<p>
Eine Lösung für das Problem stellt die Software <code>thinkfan</code> dar,
welche die Lüftersteuerung selbst übernimmt (und nicht mehr dem BIOS
überlässt). Ich habe <code>thinkfan</code> die letzten Wochen verwendet und bin
begeistert: Der Lüfter dreht deutlich seltener hoch und dreht schnell wieder
runter. Dabei wird das Notebook zwar etwas heißer, aber wem das zu heiß wird,
der kann ja die Schwelltemperatur niedriger konfigurieren.
</p>

<p>
Auf einem Debian-System kriegt man thinkfan mit dem ThinkPad X220
folgendermaßen zum laufen:
</p>

<ol>
<li>
Thinkfan via <code>apt-get install thinkfan</code> installieren ;-).
</li>

<li>
Kernel-Modul <code>thinkpad_acpi</code> mit passenden Parametern laden. Dazu
erstellt man die Datei <code>/etc/modprobe.d/thinkpad_acpi.conf</code> und
befüllt sie mit folgendem Inhalt: <pre>options thinkpad_acpi
fan_control=1</pre> Anschließend lädt man das Modul via <code>rmmod
thinkpad_acpi; modprobe thinkpad_acpi</code> neu.
</li>

<li>
In <code>/etc/thinkfan.conf</code> trägt man nun folgende Zeile ein:
<pre>
sensor /sys/class/hwmon/hwmon0/temp1_input 
</pre>
</li>

<li>
Nun startet man thinkfan via <code>thinkfan -n</code>. Bei Änderungen an der
Temperatur zeigt er an, wie er nun den Lüfter einstellt.
</li>

</ol>

<p>
(Dieser Artikel basiert auf <a
href="http://forum.notebookreview.com/7460759-post28.html">einem Kommentar</a>
über thinkfan mit dem ThinkPad X220 (!).)
</p>
