---
layout: post
title:  "Port-weiterleitungen bei OpenWRT"
date:   2007-08-21 10:00:00
categories: Artikel
---



<div class="warning" style="min-height: 50px">
<img src="/Bilder/Warning.png" class="backButton">
<p style="margin-top: 15px" class="strong">Linux/UNIX-kenntnisse erforderlich!
(in den Bereichen ssh, Dateisystem, vi)</p>
</div>

<h3>Einleitung</h3>

<p>
Der Linksys WRT54(G(S)) ist ein sehr beliebter Router, was auf die Verwendung
von Linux als Firmware zurückzuführen ist. Durch einen Bug im
Webinterface der Originalfirmware gelang es Hackern, alternative Firmwares
aufzuspielen (den Sourcecode musste Linksys herausrücken, da Linux unter
der GPLv2 steht, sodass man sich selbst ein Firmware-Image erstellen kann).
</p>

<p>
Die Distribution meiner Wahl ist OpenWRT, da sie modular erweiterbar ist (über
das Paketmanagementsystem „ipkg”, das an Debians „apt-get” angelehnt ist).
</p>

<p>
Dieses Tutorial wurde auf einem Linksys WRT54GS v4 mit OpenWRT RC4 White
Russian getestet. Prinzipiell sollte es auf jedem Router mit OpenWRT- oder
generell Linux-firmware funktionieren, die Pfade zu den einzelnen Dateien
können sich aber unterscheiden.
</p>

<h3>SSH-config anpassen</h3>
<p>
Damit man nicht immer soviel zu tippen hat (ssh root@192.168.1.x), kann man
sich einen Alias in der SSH-config anlegen. Diese Datei bearbeitet
beziehungsweise erzeugt man unter ~/.ssh/config. Der benötigte Eintrag sieht so
aus:
</p>
<pre>
Host wrt
    HostName 192.168.1.1
    User root
</pre>
<p>
Mittels „ssh wrt” kann man dann schnell und bequem auf den OpenWRT-Router
zugreifen.
</p>

<p>
Nachdem wir uns eingeloggt haben, sollte die Ausgabe in etwa so aussehen:
</p>
<pre>$ ssh wrt
The authenticity of host '192.168.1.1 (192.168.1.1)' can't be established.
RSA key fingerprint is f9:92:ab:la:34:le:64:lu:40:nu:3f:rd:bc:er:41:ma.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.1.1' (RSA) to the list of known hosts.
root@192.168.1.1's password: 


BusyBox v1.00 (2005.11.23-21:46+0000) Built-in shell (ash)
Enter 'help' for a list of built-in commands.

  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 WHITE RUSSIAN (RC4) -------------------------------
  * 2 oz Vodka   Mix the Vodka and Kahlua together
  * 1 oz Kahlua  over ice, then float the cream or
  * 1/2oz cream  milk on the top.
 ---------------------------------------------------
root@OpenWrt:~# </pre>

<h3>Firewall</h3>
<p>
OpenWRT leitet standardmäßig keine Pakete vom WAN (Wide Area Network) auf die
LAN-Schnittstelle weiter.<br>
Dieses Verhalten können wir in der Datei /etc/firewall.user ändern.
Normalerweise sieht diese Datei so aus:
</p>
<pre>!/bin/sh
. /etc/functions.sh

WAN=$(nvram get wan_ifname)
LAN=$(nvram get lan_ifname)

iptables -F input_rule
iptables -F output_rule
iptables -F forwarding_rule
iptables -t nat -F prerouting_rule
iptables -t nat -F postrouting_rule

### BIG FAT DISCLAIMER
### The "-i $WAN" literally means packets that came in over the $WAN interface;
### this WILL NOT MATCH packets sent from the LAN to the WAN address.

### Allow SSH on the WAN interface
# iptables -t nat -A prerouting_rule -i $WAN -p tcp --dport 22 -j ACCEPT
# iptables        -A input_rule      -i $WAN -p tcp --dport 22 -j ACCEPT

### Port forwarding
# iptables -t nat -A prerouting_rule -i $WAN -p tcp --dport 22 -j DNAT --to 192.168.1.2
# iptables        -A forwarding_rule -i $WAN -p tcp --dport 22 -d 192.168.1.2 -j ACCEPT

### DMZ (should be placed after port forwarding / accept rules)
# iptables -t nat -A prerouting_rule -i $WAN -j DNAT --to 192.168.1.2
# iptables        -A forwarding_rule -i $WAN -d 192.168.1.2 -j ACCEPT</pre>
<p>
Außerdem ist sie im Read-only-Teil des Routers gespeichert, das heißt, in
/rom/etc/firewall.user. Die Datei /etc/firewall.user ist lediglich eine
Verknüpfung.
</p>

<h3>Modifizieren</h3>
<p>
Wir müssen zuerst einmal die Verknüpfung löschen und stattdessen die echte
Datei kopieren:
</p>
<pre>
root@OpenWrt:~# rm /etc/firewall.user
root@OpenWrt:~# cp /rom/etc/firewall.user /etc/firewall.user
</pre>
<p>
Anschließend öffnen wir die Datei mit einem Texteditor (zum Beispiel mit „vi” -
nicht so erfahrene Benutzer können sich die Datei auch via „scp
wrt:/etc/firewall.user ~” in ihr Homeverzeichnis kopieren und mit einem
beliebigen, lokalen Editor öffnen).
</p>

<p>
Eine Portweiterleitung sieht so aus:
</p>
<pre>iptables -t nat -A prerouting_rule -i $WAN -p tcp -j DNAT --dport <b>&lt;PORT&gt;</b> --to <b>&lt;IP&gt;</b>
iptables -A forwarding_rule -i $WAN -p tcp -j ACCEPT --dport <b>&lt;PORT&gt;</b> -d <b>&lt;IP&gt;</b></pre>
<p>
Hierbei fällt natürlich auf, dass der erste Teil beider Regeln immer gleich
bleibt und das Ganze bei vielen Weiterleitungen entsprechend viel Schreibarbeit
ist. Wir legen uns also zwei Variablen an (direkt am Anfang der Datei):
</p>
<pre>#!/bin/sh
. /etc/functions.sh

WAN=$(nvram get wan_ifname)
LAN=$(nvram get lan_ifname)
PRE_STR="iptables -t nat -A prerouting_rule -i $WAN -p tcp -j DNAT"
FOR_STR="iptables -A forwarding_rule -i $WAN -p tcp -j ACCEPT"</pre>
Nun können wir eine Portweiterleitung so anlegen:
<pre>$PRE_STR --dport <b>&lt;PORT&gt;</b> --to <b>&lt;IP&gt;</b>
$FOR_STR --dport <b>&lt;PORT&gt;</b> -d <b>&lt;IP&gt;</b></pre>
<p>
Die Platzhalter <b>&lt;PORT&gt;</b> und <b>&lt;IP&gt;</b> müssen natürlich
ersetzt werden. Für den Fall, dass wir nun aber verschiedene Quell- und
Zielports haben (was häufig der Fall ist, wenn man mehrere Rechner hat, auf
denen jeweils der gleiche Port freizugeben ist), müssen wir die Regel anpassen
(am Beispiel von Quellport 2002 und Zielport 22 auf Zielrechner 192.168.1.3):
</p>
<pre>$PRE_STR --dport 2002 --to 192.168.1.3:22
$FOR_STR --dport 22 -d 192.168.1.3</pre>
<p>
Auch Portbereiche anzugeben ist möglich, „3000:3500” steht zum Beispiel für die
Ports 3000 bis 3500 (einschließlich jeweils). Eine solche Weiterleitung sieht
dann so aus:
</p>
<pre>$PRE_STR --dport 3000:3500 --to 192.168.1.3
$FOR_STR --dport 3000:3500 -d 192.168.1.3</pre>
<p>
Eine komplett fertige /etc/firewall.user sieht dann zum Beispiel so aus (die
Änderungen habe ich kursiv und fettgedruckt gekennzeichnet):
</p>
<pre>#!/bin/sh
. /etc/functions.sh

WAN=$(nvram get wan_ifname)
LAN=$(nvram get lan_ifname)
<b><i>PRE_STR="iptables -t nat -A prerouting_rule -i $WAN -p tcp -j DNAT"
FOR_STR="iptables -A forwarding_rule -i $WAN -p tcp -j ACCEPT"</i></b>

iptables -F input_rule
iptables -F output_rule
iptables -F forwarding_rule
iptables -t nat -F prerouting_rule
iptables -t nat -F postrouting_rule

### BIG FAT DISCLAIMER
### The "-i $WAN" literally means packets that came in over the $WAN interface;
### this WILL NOT MATCH packets sent from the LAN to the WAN address.

### Allow SSH on the WAN interface
# iptables -t nat -A prerouting_rule -i $WAN -p tcp --dport 22 -j ACCEPT
# iptables        -A input_rule      -i $WAN -p tcp --dport 22 -j ACCEPT

### Port forwarding
<b><i># SSH auf Webserver (port 2002->22)
$PRE_STR --dport 2002 --to 192.168.1.3:22
$FOR_STR --dport 22 -d 192.168.1.3</i></b>
</pre>

<h3>Änderungen übernehmen</h3>
<p>
Sobald wir fertig mit editieren sind, müssen wir die Änderungen natürlich
übernehmen, das geschieht mit dem Aufruf von
<code>/etc/init.d/S45firewall</code> (auf neueren Versionen ist das
<code>/etc/init.d/S35firewall</code>). Sollten keine Fehler gemeldet werden
(das heißt, dass keine Tippfehler gemacht wurden), wurden die neuen Regeln
angewandt und die Weiterleitung existiert.
</p>
