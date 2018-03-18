---
layout: post
title:  "Automatisch Mounten"
date:   2007-08-21 10:00:00
categories: Artikel
Aliases:
  - /Artikel/Automatisch_Mounten
---



<p>
Da ich an meiner Schule vier PCs mit Linux betreue, suchte ich vor kurzem nach
einer Möglichkeit, einen Ordner auf allen PCs gleichermaßen freizugeben und
diesen auf allen anderen PCs einzubinden.
</p>

<p>
Ich entschied mich für <a href="http://www.samba.org/" title="Samba"
target="_blank">Samba</a>, weil eventuell auch Windows-PCs auf die Freigabe
zugreifen sollen und NFS nicht auf Anhieb funktionieren wollte ;-). Auf die
Installation von Samba möchte ich hier jedoch nicht näher eingehen, darüber
gibt es bereits <a
href="http://www.pro-linux.de/work/server/samba_installation.html"
title="Artikel über das Installieren von Samba" target="_blank">gute
Artikel</a>.
</p>

<p>
Die verwendete Linuxdistribution ist <a href="http://www.ubuntulinux.org/"
title="Ubuntu" target="_blank">Ubuntu</a>, auf welcher standardmäßig das
benötigte Paket <span class="linuxcommand">„smbfs”</span> nicht installiert
ist.
</p>

<p>
Nach dem Installieren via <span class="linuxcommand">„sudo apt-get install
smbfs”</span> sollte man den vollen Pfad in die /etc/fstab eintragen, damit man
nicht so viel zu tippen hat beim mounten ;-): <span
class="linuxcommand">„//&lt;hostname&gt;/&lt;freigabenname&gt;
/home/schueler/&lt;mountpoint&gt; smbfs
username=schueler,password=&lt;passwort&gt; 0 0”</span>.
</p>

<p>
Nun werden die Mountpoints automatisch eingebunden, sobald der PC hochgefahren
wird - allerdings nur, wenn die zu mountenden Laufwerke und deren PCs bereits
eingeschaltet sind. Das Problem ist schnell erkannt: Wenn man zwei Rechner
anmacht, hat der zuerst hochgefahrene Rechner die Freigabe des zweiten Rechners
nicht eingebunden.
</p>

<p>
Bisher haben sich anscheinend wenige Leute diesem Problem angenommen, was auch
meine Frage im Ubuntuforum bestätigte. Allerdings wurde mir dort ein Script ans
Herz gelegt, mit welchem man prüfen kann, ob ein Rechner online ist. Dieses
wiederum kann man so abwandeln, dass es die Freigabe automatisch mountet,
sobald der Rechner online ist.
</p>

<p>
Nachdem man das folgende Script abgespeichert hat, kann man noch einen
passenden Crontab-Eintrag hinzufügen, damit das Script minütlich ausgeführt
wird:
</p>

<p>
<span class="linuxcommand">„* * * * * /home/schueler/checkhost.sh”</span>
</p>
<p class="filenameHeader">checkhost.sh</p>
<pre>
#!/bin/bash
<span class="DelphiComment"># a² - aquadraht@notmail.org 25.05.2005</span>
<span class="DelphiComment"># Modifiziert von Michael Stapelberg @ 19.10.2005</span>

FLAG=<span class="DelphiNumeric">/tmp/ping-alarm-$1</span>

<span class="DelphiComment"># check, ob FLAG älter als 12h</span>
<b>if</b> [ -f $FLAG ]; <b>then</b>
        find /tmp -name $FLAG -mmin +720 -exec rm -f {} \;
<b>fi</b>

<b>if</b> [ ! -f $FLAG ]; <b>then</b>
        ping -c 1 <span class="DelphiNumeric">"$1"</span> > /dev/null 2>&1
        <b>if</b> [ <span class="DelphiNumeric">"$?"</span> = <span class="DelphiNumeric">"0"</span> ]; <b>then</b>
                ./mount_it ${1}
        <b>fi</b>
<b>else</b>
        ping -c 1 <span class="DelphiNumeric">"$1"</span> > /dev/null 2>&1
        <b>if</b> [ <span class="DelphiNumeric">"$?"</span> = <span class="DelphiNumeric">"0"</span> ]; <b>then</b>
                ./mount_it ${1}
                cd /tmp
                rm $FLAG
        <b>else</b>
                echo "off"
        <b>fi</b>

<b>fi</b>

cd /tmp
touch $FLAG
</pre>
<p class="filenameHeader">mount_it.sh</p>
<pre>
#!/bin/sh

AMOUNT=<span class="DelphiNumeric">`mount | grep //${1}/${MOUNTPOINT} | wc -l`</span>
<span class="DelphiComment"># TODO: An dieser Stelle muss man den Mounpoint (=Freigabenname) anpassen</span>
MOUNTPOINT=<span class="DelphiNumeric">"Schuelerdateien"</span>

<b>if</b> [ ${AMOUNT} -gt 1 ]; <b>then</b>
        echo <span class="DelphiNumeric">"This share is already mounted many times, unmounting and remounting..."</span>
        i=${AMOUNT}
        <b>while</b> [ ${i} -gt 0 ]; <b>do</b>
                i=$((i-1))
                umount //${1}/${MOUNTPOINT}
        <b>done</b>
        mount //${1}/${MOUNTPOINT}
<b>elif</b> [ ${AMOUNT} -gt 0 ]; <b>then</b>
        echo <span class="DelphiNumeric">"Mount is already mounted one time, not mounting..."</span>
<b>else</b>
        echo <span class="DelphiNumeric">"Not mounted, mounting..."</span>
        mount //${1}/${MOUNTPOINT}
<b>fi</b>
echo <span class="DelphiNumeric">"Mounts now: `mount | grep //${1}/${MOUNTPOINT} | wc -l`"</span>
</pre>
<p>
Die Dateien sollten beide im selben Verzeichnis liegen, ansonsten muss der Pfad
angepasst werden.
</p>
