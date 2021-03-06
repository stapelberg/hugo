---
layout: post
title:  "NetBSD 4.0 mit Xen 3"
date:   2008-06-18 10:00:00
categories: Artikel
Aliases:
  - /Artikel/NetBSD_Xen
---



<p>
Da Linux-Vserver auf zwei meiner Rechner aus irgendwelchen Gründen instabil
lief (Freeze bei Last, beide Male auf AMD64, aktuelle Version mit IPv6), ließ
ich mich zu einem Versuch mit NetBSD statt Linux und Xen statt Linux-Vserver
als Virtualisierungslösung überreden ;-).
</p>

<p>
Da das offizielle Howto allerdings leicht outdated und nicht ganz so
ausführlich ist, habe ich hier meine Erfahrungen dokumentiert. Viel Spaß beim
Ausprobieren, Feedback ist willkommen :-).
</p>

<p>
Ich gehe davon aus, dass grundlege Kenntnis über Xen besteht, ansonsten
informiere dich bitte zuerst anderweitig. Außerdem solltest du diese Anleitung
nicht sofort 1:1 auf einem Server umsetzen, sondern erstmal lokal ausprobieren.
</p>

<h2>Vorwort</h2>
<p>
Diese Anleitung bezieht sich auf NetBSD 4.0 mit aktuellem pkgsrc, welches
momentan xen-3.1.4 beinhaltet. Falls xen-3.1.4 mittlerweile outdated ist, such
lieber nach einer anderen Anleitung, diese könnte mittlerweile falsch sein…
</p>

<h2>Installation</h2>
<p>
Bei der Installation sollte man beachten, dass das Dateisystem ein FFSv1 sein
muss, von FFSv2 wollte GRUB bei mir nicht booten (mir wurde allerdings gesagt,
dass es bei jemand anders funktioniert – nunja, sicher ist sicher…). Ansonsten
habe ich einfach ein normales NetBSD/i386 installiert mit den Sets comp, misc,
text und man. Bei der Partitionierung habe ich pro domU einen Slice ohne
Dateisystem und Mountpoint angelegt.
</p>

<p>
Als Mirror war bei mir <code>ftp7.de.netbsd.org</code> der schnellste und
zuverlässigste. Leider kann man nicht jeden beliebigen FTP verwenden, der
Backup-Server meines Hosters beispielsweise kann keine Wildcards und taugt
daher nicht als Installationsquelle.
</p>

<p>
Nach der Installation via Remote-KVM sollte man zuerst SSH aktivieren und einen
User anlegen (root-login ist standardmäßig abgeschaltet und das ist auch
sinnvoll so):
</p>
<pre>echo sshd=YES &gt;&gt; /etc/rc.conf
/etc/rc.d/sshd start
useradd -m -G wheel michael
passwd michael</pre>

<p>
Die Optionen <code>-m</code> und <code>-G wheel</code> sorgen dafür, dass das
homedirectory erstellt wird beziehungsweise dass der neue Benutzer automatisch
der Gruppe <code>wheel</code> zugeordnet wird, damit er später <code>su</code>
benutzen darf.
</p>

<p>
Anschließend loggt man sich via SSH ein, da das doch deutlich komfortabler als
ein Remote-KVM ist, und installiert xenkernel3 sowie xentools3:
</p>
<pre>$ su -
# cd /usr
# cvs -z9 -d anoncvs@anoncvs.netbsd.se:/cvsroot co pkgsrc
# cd pkgsrc/sysutils/xentools3
# make install clean
# cp /usr/pkg/share/examples/rc.d/xendomains /etc/rc.d/xendomains
# cp /usr/pkg/share/examples/rc.d/xend /etc/rc.d/xend
# cp /usr/pkg/share/examples/rc.d/xenbackendd /etc/rc.d/xenbackendd
# cd ../xenkernel3
# make install clean
# gunzip -c /usr/pkg/xen3-kernel/xen.gz &gt; /xen</pre>
<p>
Das ganze dauert ca. 30 Minuten. Mithilfe des CVS-Checkouts haben wir auf jeden
Fall die aktuelle Version von pkgsrc. Hierbei wurde mir dazu geraten, netbsd.se
zu verwenden statt netbsd.org, da netbsd.se in der Regel problemloser
funktioniert. Das Entpacken des Kernels ist nicht unbedingt notwendig, aber
damit GRUB auf jeden Fall bootet, gehen wir lieber den sicheren Weg ;-).
Apropos GRUB, den brauchen wir auch noch:
</p>

<pre># cd ../grub
# make install clean
# grub-install --no-floppy '(hd0)'</pre>

<p>Die Datei <code>/grub/menu.lst</code> erstellen wir nun mit folgendem Inhalt:</p>
<pre>default=0
timeout=5
 
title Xen 3.0 / NetBSD 4.0 
        root (hd0,0)
        kernel (hd0,a)/xen dom0_mem=131072
        module (hd0,a)/netbsd-XEN3_DOM0 bootdev=wd0a ro console=tty0
        
title NetBSD 4.0
        root (hd0,a)
        chainloader +1</pre>

<p>
Zu beachten ist, dass dom0_mem mit der Menge an Arbeitsspeicher, den die dom0,
also der Hostrechner, bekommen soll, gesetzt wird (in Kilobytes). Der Speicher
für die einzelnen domUs ist hier nicht mit eingerechnet. Außerdem muss
gegebenenfalls wd0a gegen den Namen deiner Festplatte/Slice ausgetauscht
werden. Sofern eine serielle Konsole verfügbar ist, sollte tty0 gegen ttyS0
ausgetauscht werden. Der zweite Eintrag startet den Original-NetBSD-Bootloader,
was sehr nützlich ist, wenn doch etwas schiefgelaufen ist (wie zum Beispiel ein
FFSv2-Dateisystem, wobei man dann ohnehin neu installieren muss…).
</p>

<p>
Vor dem folgenden Neustart brauchen wir noch die Kernel-Images für die dom0 und
die domUs, außerdem nützlich ist das INSTALL_XEN3_DOMU-Image, bei welchem
gleich ein NetBSD-Installer integriert ist:
</p>

<pre># cd /
# ftp -a ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-4.0/i386/binary/kernel/netbsd-XEN3_DOM0.gz
# ftp -a ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-4.0/i386/binary/kernel/netbsd-XEN3_DOMU.gz
# ftp -a ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-4.0/i386/binary/kernel/netbsd-INSTALL_XEN3_DOMU.gz
# gunzip netbsd*gz</pre>

<p>
Nun startet man das System via <code>reboot</code> neu und hofft, dass alles
klappt. Sollte das der Fall sein, ist man nun mit der Remote-KVM fertig. Nun
legen wir noch die Devicenodes an und aktivieren/starten die beiden Daemons:
</p>

<pre># cd /dev
# sh MAKEDEV xen
# echo xend=YES &gt;&gt; /etc/rc.conf
# echo xenbackendd=YES &gt;&gt; /etc/rc.conf
# /etc/rc.d/xend start
# /etc/rc.d/xenbackendd start</pre>

<p>
Außerdem brauchen wir eine bridge, damit der Netzwerktraffic von der dom0 zu
den domUs gelangt. Diese konfigurieren wir in der Datei
<code>/etc/ifconfig.bridge0</code>:
</p>
<pre>create
!brconfig $int add re0 up</pre>

<p>
Hierbei muss <code>re0</code> gegebenenfalls gegen den Namen deiner
Netzwerkkarte ausgetauscht werden. Diesen findest du mit <code>ifconfig
-a</code> heraus. Gestartet wird die bridge mit folgenden Befehlen (bei einem
Neustart nicht nötig):
</p>
<pre># ifconfig bridge0 create
# brconfig bridge0 add re0 up</pre>

<h2>domU einrichten</h2>
<p>
Die Konfiguration für die einzelnen domUs findest du in
<code>/usr/pkg/etc/xen/</code>. Wir legen hier eine Datei namens
<code>ircd</code> an (mit dem Namen für deine domU ersetzen):
</p>
<pre>kernel = "/netbsd-INSTALL_XEN3_DOMU"
memory = 256
name = "ircd"
vif = [ 'mac=00:16:3e:70:02:01, bridge=bridge0' ]
disk = [ 'phy:/dev/wd0e,0x1,w' ]
root = "xbd0"</pre>

<p>
Die Konfiguration beinhaltet gleich mehrere Stolperfallen: Die MAC-Adresse
<strong>MUSS</strong> mit 00:16:3e anfangen. Beispielsweise 00:16:3e:70:02:01
ist eine gültige Adresse. Der Anfang 00:16:3e ist offiziell Xensource
zugeordnet und Xen weigert sich ansonsten zu starten – ohne hilfreiche
Fehlermeldung allerdings :-(.
</p>

<p>
Des Weiteren sollte man bei der Angabe der disk unbedingt den richtigen Slice
erwischen. Bei den Slices ist es so, dass es einen Slice gibt, der die
komplette Festplatte umfasst, den man – sofern man das Konzept noch nicht kennt
– eventuell verwechseln könnte. Daher: Mit <code>disklabel /dev/rwd0</code>
findest du heraus, welche Slices du vorher angelegt hast. Bei einer geführten
Installation durch den NetBSD-Installer ist in der Regel wd0e der ersten
Daten-Slice.
</p>

<p>
Sobald die Konfiguration überprüft wurde, starten wir die domU mit
<code>-c</code>, was bedeutet, dass wir direkt auf die Konsole gelangen:
</p>

<pre># xm create -c /usr/pkg/etc/xen/ircd</pre>

<p>
Hier installiert man nun ein Standardsystem. Anschließend funktionierte das
<code>shutdown -h now</code> in der domU allerdings nur insofern, als dass die
domU zwar heruntergefahren war, aber nicht „ausgeschaltet”. Also nochmal in die
dom0 einloggen und mittels <code>xm destroy ircd</code> die domU anhalten um in
der Konfiguration den kernel von INSTALL-XEN3_DOMU auf XEN3-DOMU zu ändern. Nun
startet man die domU nochmals mit <code>-c</code>, aktiviert SSH wie oben
gezeigt, fährt sie wieder herunter und startet sie dann ohne Parameter.
</p>

<p>
Das war’s – die domU läuft. Allerdings gibt es noch ein paar nützliche
Dinge…
</p>

<h2>pkg_comp</h2>

<p>
Mittels <code>pkg_comp</code> kann man in einer chroot-Umgebung Pakete und
deren Abhängigkeiten bauen, die man dann auf seinem Server verwenden kann.
Somit hat man den Vorteil anpassbarer Pakete und umgeht den Nachteil des
langwierigen Kompilierens auf dem Server (vor allem muss man nicht auf jeder
domU nochmal kompilieren). Außerdem kann es beim Kompilieren passieren, dass
eine von mehreren Paketen genutzte Abhängigkeit aktualisiert wird und einer der
Dienste, die das Paket benutzen, noch nicht aktualisiert sind und somit nicht
mehr funktionieren. Das wird durch die schnelle Installation der Binärpakete
vermieden. Die offiziellen Binärpakete sind allerdings nicht gut gepflegt,
daher bauen wir uns einfach unsere eigenen…
</p>

<p>
<code>pkg_comp</code> wird also ganz normal installiert (ich habe dafür eine
domU auf einem lokalen Rechner erstellt):
</p>
<pre># cd /usr/pkgsrc/pkgtools/pkg_comp
# make install clean</pre>

<p>Anschließend wird eine Beispielkonfiguration erstellt (maketemplate):</p>
<pre># pkg_comp maketemplate</pre>

<p>In dieser Konfigurationsdatei (pkg_comp/default.conf) ändern wir nun folgende Variablen:</p>
<ul>
	<li><code>DISTRIBDIR</code> – wohin die fertigen Pakete abgelegt werden, also <code>/var/pub/NetBSD</code> in diesem Beispiel</li>
	<li><code>REAL_PKGSRC</code> – wo unser pkgsrc liegt, also /usr/pkgsrc</li>
	<li><code>SETS</code> – welche sets verfügbar sind</li>
	<li><code>SETS_X11</code> – ob die X11-sets verfügbar sind, also NO ;-)</li>
</ul>

<p>
Dann wird die chroot-Umgebung eingerichtet (makeroot). Ich habe dabei auch
gleich die sets kopiert, falls ich sie später noch einmal brauche (für eine
neue domU zum Beispiel):
</p>
<pre># mkdir -p /var/pub/NetBSD/binary/sets
# cp /usr/INSTALL/*.tgz /var/pub/NetBSD/binary/sets/
# mkdir /var/chroot/pkg_comp
# pkg_comp makeroot</pre>

<p>Hier eine Liste mit der Paketkonfiguration, die ich verwende:</p>

<ul>
<li>mail/postfix</li>
<li>www/apache22</li>
<li>security/cy2-plain</li>
<li>net/bind9</li>
<li>mail/mailman (hierbei sollte man im Makefile vorher <code>MAILMAN_MAILGROUP=nobody</code> setzen, sofern man mailman mit Postfix verwenden will)</li>
<li>devel/scmgit</li>
<li>www/gitweb</li>
<li>www/trac</li>
<li>net/wget</li>
<li>shells/zsh</li>
<li>editors/vim</li>
<li>net/vsftpd</li>
<li>misc/gnuls (sorgt für <code>gls --color=auto</code> :-))</li>
<li>databases/mysql5-server</li>
<li>lang/php5</li>
<li>databases/php-pdo</li>
<li>databases/php-pdo_mysql</li>
<li>graphics/php-gd</li>
<li>databases/phpmyadmin</li>
<li>misc/screen</li>
</ul>

<h2>Eigene Kernel bauen</h2>
<p>
Da der XEN_DOMU-Kernel mit Debugoptionen kompiliert wurde, kann man die
Standard-Module nicht in den Kernel laden und hat somit kein <code>pf</code>.
Da ich <code>pf</code> benötige, musste ich also einen eigenen Kernel bauen.
Das klingt aufwändiger als es tatsächlich ist.
</p>

<p>
Hierzu brauchen wir zuerst das set <code>syssrc.tgz</code>:
</p>
<pre># ftp -a ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-4.0/source/sets/syssrc.tgz
# cd /; tar xvzpf ~/syssrc.tgz</pre>

<p>
Im Prinzip kopieren wir uns dann die XEN3_DOMU-Konfiguration, die
freundlicherweise mitgeliefert wird, und ergänzen die Optionen für
<code>pf</code> sowie das Filtern auf bridges. Folgende Schritte sind dafür
notwendig:
</p>
<pre># cd /usr/src/sys/arch/i386/conf
# cp XEN3_DOMU XEN3_DOMU_PF
# echo pseudo-device pf &gt;&gt; XEN3_DOMU_PF
# echo pseudo-device pflog &gt;&gt; XEN3_DOMU_PF
# echo options ALTQ &gt;&gt; XEN3_DOMU_PF
# echo options BRIDGE_IPF &gt;&gt; XEN3_DOM0_PF
# config XEN3_DOMU_PF
# cd ../compile/XEN3_DOMU_PF
# make depend
# make
# cp netbsd /netbsd-XEN3_DOMU_PF</pre>

<p>Und schon haben wir einen eigenen Kernel mit dem Namen netbsd-XEN3_DOMU_PF :-).</p>

<h2>Generelle Tipps</h2>
<ul>
<li>
Für die Netzwerkkarte, die in meinem Server steckt (Intel e100), ist <a
href="http://mail-index.netbsd.org/netbsd-bugs/2004/09/08/0003.html"
target="_blank">dieser Patch</a> notwendig, dass sie ohne Fehlermeldungen
funktioniert. Da lohnt sich das Kompilieren eines eigenen Kernels umsomehr ;-).
</li>

<li>
Bei beiden von mir getesteten Systemen hat APIC-, ACPI- und PnP-Support nur
Probleme gemacht. Sobald man sie im BIOS ausschaltete, funktionierte das
System. Ich weiß, das ist nicht die saubere Art, aber mit dem Debuggen von
solchen Dingen möchte ich mich als NetBSD-Anfänger noch nicht befassen ;-).
</li>

<li>
Bei meinem Provider ist es so, dass man, sofern man keine Virtualisierung
verwendet, alle IPs eines Subnetzes verwenden kann. Bei Xen ist es dann aber
so, dass die erste IP als Network-Adress gehandhabt wird und somit nicht
verwendet werden kann. Wer also darüber seine Default-Route legen möchte und
nur DUP-pings zurückbekommt – nächste Adresse probieren.
</li>

</ul>

<h2>Links</h2>
<ul>
	<li>
	<a href="http://www.netbsd.org/ports/xen/howto.html"
	target="_blank">http://www.netbsd.org/ports/xen/howto.html</a> – Das
	offizielle Xen-Howto
	</li>
	<li>
	<a href="https://wiki.bfh.ch/index.php/XEN"
	target="_blank">https://wiki.bfh.ch/index.php/XEN</a> – Xen-Seite im
	Wiki der Berner Fachhochschule
	</li>
</ul>
