---
layout: post
title:  "Interfaces-Magie (/etc/network/interfaces auf Debian)"
date:   2009-09-22 14:36:20
categories: Artikel
---



<p>
  Einer der Punkte, die eine Linux-Distribution wirklich auszeichnet, ist die Methode der Konfiguration.
  Insbesondere interessant ist zurzeit die Konfiguration der Netzwerk- und WLAN-Karten, besonders wenn es
  sich um ein Notebook handelt.
</p>

<p>
  Bei Debian gibt es hierfür die Datei <code>/etc/network/interfaces</code>, die mehr kann, als man auf
  den ersten Blick vermuten würde. In diesem Artikel möchte ich kurz beschreiben, was man damit alles erreichen
  kann und warum das sogar noch toller ist, als die Netzwerkumgebungen bei Mac OS X ;-).
</p>

<p>
  Zunächst einmal sollte man folgende Pakete nachinstallieren:
</p>
<ul>
  <li>
    <code>resolvconf</code> für die Verwaltung der Datei <code>/etc/resolv.conf</code>, welche die
    Nameserver beinhaltet (ansonsten kann man die Nameserver nicht über <code>interfaces</code>
    konfigurieren).
  </li>
  <li>
    <code>ifplugd</code> damit automatisch die Netzwerkkarte konfiguriert wird, sobald man ein
    Kabel einsteckt
  </li>
  <li>
    <code>guessnet</code> damit man automatisch eine Konfiguration aufgrund verschiedener
    Annahmen aktivieren lassen kann (zum Beispiel das Netz zuhause).
  </li>
</ul>

<p>
  Bei der Konfiguration von <code>ifplugd</code> (die man mit <code>dpkg-reconfigure ifplugd</code>
  erneut aufrufen kann) habe ich folgende Optionen angegeben: <code>-q -f -u0 -d2 -w -I -b</code>
</p>

<p>
  Der Unterschied zu den Standardoptionen ist nur, dass er schneller (2 statt 10 Sekunden) nach
  Entfernen des Netzwerkkabels die Konfiguration deaktiviert und dass er nicht mehr piepst (<code>-b</code>).
</p>

<h2>WLAN von wpa_supplicant konfigurieren lassen</h2>

<p>
  Wer schonmal WPA-Netze mit Linux benutzt hat, ist sicherlich mit wpa_supplicant in Berührung gekommen.
  wpa_supplicant kann aber nicht nur WPA-Netze konfigurieren, sondern auch WEP- und offene Netze.
</p>

<p>
  Konfiguriert wird wpa_supplicant über die Datei <code>/etc/wpa_supplicant/wpa_supplicant.conf</code>.
  Bei Debian sind die Standardeinstellungen sinnvoll, sodass man sich darauf beschränken kann, die Netze
  an sich einzurichten. Folgendes Beispiel dient dazu, sich mit einem offenen Netz zu verbinden:
</p>

<pre>
network={
	ssid="FirmenNetz"
	key_mgmt=NONE
}
</pre>

<p>
  Wenn man in alle Netze möchte, die offen sind:
</p>

<pre>
network={
	key_mgmt=NONE
}
</pre>

<p>
  Für ein WEP-Netz sieht das ganze ähnlich aus:
</p>
<pre>
network={
	ssid="FirmenNetz"
	wep_key0="passwort"
	key_mgmt=NONE
}
</pre>

<p>
  Bei WPA-Netzen hat man nun zwei Möglichkeiten: Entweder, man gibt das Passwort (ich gehe hier nur auf
  WPA-PSK, also mit Passwort ein) im Klartext an oder man benutzt wpa_passphrase, um einen Hash zu
  erzeugen, den man dann ebenso verwenden kann. Der Vorteil am Hash ist, dass man die Datei öffnen kann
  (um beispielsweise ein neues Netz zu konfigurieren), ohne dass direkt alle Passwörter auf dem Bildschirm
  stehen. Im folgenden also zwei Beispiele, einmal mit Klartext-Passwort, einmal mit Hash:
</p>

<pre>
network={
	ssid="FirmenNetz"
	psk="GeheimesPasswort"
}

network={
	ssid="FirmenNetz"
	psk=ae2c2eda8f85d336542ad773504d6290a63153e0d4bd139f18fe32c8f7802855
}
</pre>

<h2>wpa_supplicant einbinden</h2>

<p>
  Damit wpa_supplicant automatisch gestartet wird, sobald das WLAN-Interface da ist, trägt man folgende
  Konfiguration in /etc/network/interfaces ein (wlan0 muss natürlich durch den Namen des WLAN-Interfaces
  ersetzt werden):
</p>

<pre>
iface wlan0 inet manual
	wpa-driver wext
	wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
</pre>

<h2>IP-Konfiguration bei WLAN festlegen</h2>

<p>
  Der Vorteil ist nun, dass man bei wpa_supplicant pro Netz angeben kann, wie es heißen soll (id_str) und
  man für jedes Netz in der /etc/network/interfaces dann separate Einstellungen machen kann. Falls man
  keinen Namen angegeben hat, wird „default” benutzt. Folgende Änderungen machen wir also an der
  /etc/wpa_supplicant/wpa_supplicant.conf:
</p>

<pre>
network={
	ssid="FirmenNetz"
	psk=ae2c2eda8f85d336542ad773504d6290a63153e0d4bd139f18fe32c8f7802855
	id_str="firma"
}
</pre>

<p>
  Und die /etc/network/interfaces passen wir folgenderweise an:
</p>

<pre>
iface firma inet static
	address 192.168.1.42
	netmask 255.255.255.0
	gateway 192.168.1.1
	dns-search firma.lan
	dns-nameservers 192.168.1.1
</pre>

<p>
  Sobald sich wpa_supplicant also nun mit dem WLAN „FirmenNetz” verbindet, werden automatisch die oben
  genannten Einstellungen vorgenommen.
</p>

<h2>IP-Konfiguration für LANs</h2>

<p>
  Um guessnet zu aktivieren fügen wir folgende Zeilen in die /etc/network/interfaces ein:
</p>

<pre>
mapping eth0
	script guessnet-ifupdown
	map default: default
</pre>

<p>
  Anschließend kann man zum Beispiel (für weitere Optionen siehe Manpage von guessnet) folgende
  Konfiguration benutzen:
</p>

<pre>
iface home inet static
	address 192.168.1.23
	netmask 255.255.255.0
	gateway 192.168.1.1
	dns-nameservers 192.168.1.1
	test peer address 192.168.1.1 mac 00:a3:23:51:2c:42

iface default inet dhcp
</pre>

<p>
  Bevor nun eine IP-Konfiguration vorgenommen wird, läuft guessnet an und prüft, ob der Rechner mit
  der IP-Adresse die angegebene MAC-Adresse hat. Falls ja, werden die Einstellungen von diesem
  Konfigurationsblock benutzt („home” in diesem Fall).
</p>

<h2>Eigene Scripts (VPN-Client starten)</h2>

<p>
  Für manche Netze (Uni) braucht man einen VPN-Client oder ähnliches. Um beim Aktivieren/Deaktivieren
  eines Interfaces beliebige Aktionen zu starten, gibt es die up/down-Direktive. Folgendes Beispiel
  sollte es klarmachen, wie das funktioniert.
</p>

<pre>
iface uni inet dhcp
	dns-nameservers 129.206.100.126 129.206.210.127
	dns-search urz.uni-heidelberg.de
	# Wir starten vpnc in einer Schleife, weil das Ding so oft abschmiert (schlechtes WLAN)
	up /home/michael/Uni/VPN/wrapper.sh &
	down /home/michael/Uni/VPN/killwrapper.sh
</pre>

<p>
  Das Wrapperscript sieht so aus:
</p>

<pre>
#!/bin/sh

while [ 1 ]; do
	# As long as the vpn server is reachable...
	ping -c 1 -W 5 vpn.uni-heidelberg.de
	if [ $? -eq 0 ]; then
		# ...check if we need the VPN
		ping -c 1 -W 5 www.google.de
		[ $? -eq 0 ] && { exit; }

		# or run the VPN
		/usr/local/sbin/vpnc --no-detach /etc/vpnc/unihd.conf
	fi
	sleep 1
done
</pre>

<p>
  Und das Killscript so:
</p>

<pre>
#!/bin/sh
killall wrapper.sh
/usr/local/sbin/vpnc-disconnect || exit 0
</pre>

<h2>Automatische Erkennung überschreiben</h2>

<p>
  Sollte die Erkennung mal versagen, oder man ist zu faul um alles korrekt aufzusetzen, kann man
  zum Beispiel die Benutzung der IP-Einstellungen für das Uni-Interface folgendermaßen enforcieren:
</p>

<pre>
# ifup eth0=uni
</pre>

<h2>Vollständiges Beispiel</h2>

<p>
  Die Datei <code>/etc/network/interfaces</code>:
</p>

<pre>
auto lo
iface lo inet loopback

allow-hotplug wlan2 eth0

# Bei LAN bestimmt guessnet den Namen des Interfaces
mapping eth0
        script guessnet-ifupdown
        map default: default

# Bei WLAN bestimmt wpa_supplicant den Namen des Interfaces
iface wlan2 inet manual
        wpa-driver wext
        wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf

# Standardinterface, einfach DHCP
iface default inet dhcp

# Kein Kabel? Dann keine Konfiguration
iface eth0 inet manual
        test missing-cable
        pre-up echo No link present.
        pre-up false

# Zuhause
iface home inet static
        address 192.168.1.42
        netmask 255.255.255.0
        network 192.168.1.0
        broadcast 192.168.1.255
        gateway 192.168.1.1
        dns-nameservers 192.168.1.1
        test peer address 192.168.1.1 mac 00:a3:23:51:2c:42

iface uni inet dhcp
        dns-nameservers 129.206.100.126 129.206.210.127
        dns-search urz.uni-heidelberg.de
        # Wir starten vpnc in einer Schleife, weil das Ding so oft abschmiert (schlechtes WLAN)
        up /home/michael/Uni/VPN/wrapper.sh &
        down /home/michael/Uni/VPN/killwrapper.sh

</pre>

<p>
  Die Datei <code>/etc/wpa_supplicant/wpa_supplicant.conf</code>:
</p>

<pre>
network={
	ssid="UNI-HEIDELBERG"
	key_mgmt=NONE
	id_str="uni"
}

network={
	ssid="foo"
	psk="bar"
	id_str="home"
}
</pre>
