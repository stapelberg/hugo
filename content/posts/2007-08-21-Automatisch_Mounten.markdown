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

```
* * * * * /home/schueler/checkhost.sh
```

**checkhost.sh**:
```
#!/bin/bash
# a² - aquadraht@notmail.org 25.05.2005
# Modifiziert von Michael Stapelberg @ 19.10.2005

FLAG=/tmp/ping-alarm-$1

# check, ob FLAG älter als 12h
if [ -f $FLAG ]; then
        find /tmp -name $FLAG -mmin +720 -exec rm -f {} \;
fi

if [ ! -f $FLAG ]; then
        ping -c 1 "$1" > /dev/null 2>&1
        if [ "$?" = "0" ]; then
                ./mount_it ${1}
        fi
else
        ping -c 1 "$1" > /dev/null 2>&1
        if [ "$?" = "0" ]; then
                ./mount_it ${1}
                cd /tmp
                rm $FLAG
        else
                echo "off"
        fi

fi

cd /tmp
touch $FLAG
```

**mount_it.sh**:
```
#!/bin/sh

AMOUNT=`mount | grep //${1}/${MOUNTPOINT} | wc -l`
# TODO: An dieser Stelle muss man den Mountpoint (=Freigabenname) anpassen
MOUNTPOINT="Schuelerdateien"

if [ ${AMOUNT} -gt 1 ]; then
        echo "This share is already mounted many times, unmounting and remounting..."
        i=${AMOUNT}
        while [ ${i} -gt 0 ]; do
                i=$((i-1))
                umount //${1}/${MOUNTPOINT}
        done
        mount //${1}/${MOUNTPOINT}
elif [ ${AMOUNT} -gt 0 ]; then
        echo "Mount is already mounted one time, not mounting..."
else
        echo "Not mounted, mounting..."
        mount //${1}/${MOUNTPOINT}
fi
echo "Mounts now: `mount | grep //${1}/${MOUNTPOINT} | wc -l`"
```

<p>
Die Dateien sollten beide im selben Verzeichnis liegen, ansonsten muss der Pfad
angepasst werden.
</p>
