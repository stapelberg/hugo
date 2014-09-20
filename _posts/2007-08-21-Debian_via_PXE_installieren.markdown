---
layout: post
title:  "Kurz-Howto: Debian via PXE installieren"
date:   2007-08-21 10:00:00
categories: Artikel
---



<h3>Worum geht's?</h3>
<p>
Wir werden ein System via PXE installieren. Das ist nett, wenn man zum Beispiel
ein System hat, das nicht von CD oder sonstigen Medien booten kann, wie es mir
mit einem Fujitsu Siemens Laptop passiert ist...
</p>
<p>
Wir brauchen:
</p>
<ul>
	<li>Ein Debian-system, mit dem eine Netzwerkverbindung hergestellt werden kann</li>
	<li>Die Debian-woody Installations-CD (in meinem Fall hat's mit woody 3.0 r2 funktioniert)</li>
</ul>

<h3>Pakete installieren</h3>
<p>
Wir brauchen einen DHCP-Server, da PXE sich beim Boot via DHCP eine Adresse
holen möchte, sowie einen TFTP-Server, über den PXE die Dateien herunterlädt
(pxeconfig und bootimages) und syslinux, hier ist die Datei pxelinux.0 dabei.
</p>
<p>
<code>apt-get install dhcp tftpd-hpa syslinux</code>
</p>
<h3>DHCP-Server</h3>
<p>
Zuerst konfigurieren wir den DHCP-Server, da beim Installieren eine Meldung
angezeigt wird, dass er nicht gestartet werden konnte...
</p>
<p>
Dazu öffnen wir die Datei <code>/etc/dhcpd.conf</code> mit einem Texteditor und
passen den Inhalt an, sodass er am Ende so aussieht:
</p>
<pre>option domain-name "local";
option subnet-mask 255.255.255.0;
default-lease-time 600;
max-lease-time 7200;

# Gilt für mein 192.168.1.-er Netz, bei anderen Netzen entsprechend anpassen
subnet 192.168.1.0 netmask 255.255.255.0 {
	# Wir vergeben IPs von 192.168.1.90 bis 192.168.1.100
	range 192.168.1.90 192.168.1.100;
	option broadcast-address 192.168.1.1;
	option routers 192.168.1.1;
}

host pxeinstall {
	# Hier muss natürlich die MAC-Adresse angepasst werden.
	hardware ethernet 0:0:E2:A0:36:D8;
	filename "pxelinux.0";
}
</pre>
<p>
Der DHCP-Server wird nun noch via <code>/etc/init.d/dhcp start</code> gestartet.
</p>

<h3>TFTP-Server</h3>
<p>
Der TFTP-Server muss nicht speziell konfiguriert werden, er legt die Dateien
standardmäßig in <code>/var/lib/tftpboot</code> ab.
</p>
<p>
Zum Starten muss jedoch der inetd neugestartet werden: <code>killall -HUP inetd
&amp;&amp; inetd</code>
</p>

<h3>Bootimages</h3>
<p>
Wir wechseln zuerst via <code>cd /var/lib/tftpboot</code> in das Verzeichnis
für den TFTP-Server.
</p>
<p>
Die notwendigen Bootimages gibt's auf jedem Debian mirror:
</p>
<pre>wget http://mirrors.kernel.org/debian/dists/woody/main/disks-i386/current/images-1.44/root.bin
wget http://http.us.debian.org/debian/dists/woody/main/disks-i386/current/bf2.4/tftpboot.img</pre>
<p>
Außerdem brauchen wir die Datei <code>pxelinux.0</code> von syslinux: <code>cp
/usr/lib/syslinux/pxelinux.0 .</code>
</p>
<h3>PXELinux konfigurieren</h3>
<p>
Wir erstellen uns erst via <code>mkdir pxelinux.cfg</code> das Verzeichnis
pxelinux.cfg, wechseln mit <code>cd pxelinux.cfg</code> hinein und editieren
die Datei <code>default</code>, sodass sie so aussieht:
</p>
<pre>PROMPT 1
LABEL pxe
KERNEL tftpboot.img
APPEND initrd=root.bin flavor=bf2.4
IPAPPEND 1</pre>

<h3>Booten</h3>
<p>
OK, auf Serverseite war's das. Nun müsst ihr nur noch im BIOS umstellen, dass
der Rechner via PXE booten soll und ein wenig Geduld haben. Nach dem Empfang
des DHCP-Lease fordert euch der Rechner auf, einzugeben, was ihr booten wollt.
Tippt hier „pxe” ein und betet :-).
</p>

