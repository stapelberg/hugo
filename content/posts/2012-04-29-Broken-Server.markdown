---
layout: post
date: 2012-04-29 23:23:00 +02:00
title: "Kaputter Server: Verschiedene Tipps"
---
<p>
Gestern kriegte ich bescheid gesagt, dass ein Server, den ich mitbetreue,
kaputt gegangen sei. Die Hardware wurde vom Hoster getauscht, allerdings wurden
auch neue Platten eingebaut. Der Hoster bot an, zusätzlich die alte Platte
anzuschließen, um die Daten zu kopieren. Warum er die Daten nicht einfach
selbst kopierte, verstehe ich nicht ganz.
</p>

<p>
Im Rescue-System (ein grml) konnten wir dann die alte Platte (7 Jahre
Betriebsstunden, uff) und die neuen Platten sehen. Nach einem kurzen
<code>dd</code> waren die Daten dann kopiert, danach ging das Anpassen und
Debuggen los. Hier eine Checkliste, was man beachten sollte:
</p>

<ol>
	<li>In <code>/etc/udev/rules.d/70-persistent-net.rules</code> muss man
	einen entsprechenden Eintrag für die neue Netzwerkkarte hinzufügen und
	die alten entfernen, damit die neue Netzwerkkarte nicht als eth1
	erkannt wird und plötzlich keine Konfiguration mehr hat.
	Praktischerweise kann man den nötigen Inhalt direkt aus der
	<code>/etc/udev/rules.d/70-persistent-net.rules</code> des
	Rescue-systems kopieren.</li>

	<li>Die <code>/etc/mtab</code> sollte, sofern sie existiert und noch
	eine reguläre Datei ist, durch einen Symlink auf
	<code>/proc/mounts</code> ersetzt werden.</li>

	<li>Die initramdisk sollte via <code>update-initramfs -k all -u</code>
	aktualisiert werden.</li>

	<li>Der Bootloader sollte via <code>grub-install --recheck
	/dev/sda</code> mit aktueller device map installiert werden.</li>

	<li>Die <code>/etc/fstab</code> sollte angepasst werden.</li>
</ol>

<p>
Alle diese Punkte hatten wir befolgt, aber nach einem Neustart kam der Server
trotzdem nicht hoch. Eine serielle Schnittstelle, KVM, Remote-Hands o.ä. hatten
wir nicht zur Verfügung.
</p>

<p>
Als nächstes habe ich dann netconsole probiert, um auf einem anderen Rechner
die Bootmeldungen zu lesen. Das kriegt man unter Debian folgendermaßen hin:
</p>
<pre>
echo 'forcedeth' &gt;&gt; /etc/initramfs-tools/modules
echo 'netconsole netconsole=6655@111.222.333.444/eth0,6644@555.666.777.888/00:0c:db:4e:e8:00' &gt;&gt; /etc/initramfs-tools/modules
update-initramfs -k all -u
</pre>
<p>
Wobei hier 111.222.333.444 die IP des Servers ist und 555.666.777.888 die IP
ist, an welche die Nachrichten geschickt werden. Wichtig ist hier noch, dass
die MAC-Adresse diejenige des Gateways ist, damit die Pakete ins Internet
gelangen. Die kann man mit <code>ip -4 neighbor show</code> herausfinden.
</p>

<p>
Des Rätsels Lösung war dann, dass im BIOS des Rechners die alte Festplatte
zuerst gelistet war, sodass er wieder ins alte System startete. Gelöst haben
wir das dann mit <code>dd if=/dev/zero of=/dev/sdc bs=5M count=10</code>, womit
man den MBR und die Partition Table (und Daten!) der alten Platte überschreibt,
sodass das BIOS diese beim Starten überspringt.
</p>
