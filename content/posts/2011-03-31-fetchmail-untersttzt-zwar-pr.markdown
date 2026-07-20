---
permalink: /post/45
layout: post
date: 2011-03-31 11:38:01 +02:00
title: "
fetchmail unterstützt zwar pr…"
---
<p>
fetchmail unterstützt zwar prinzipiell die IDLE-Funktion von IMAP um bei neuen
Nachrichten sofort benachrichtigt zu werden (im Vergleich zu periodischem
Nachfragen), aber nicht wenn man mehrere Accounts konfiguriert hat.
</p>

<p>
Abhilfe schafft ein kleines Script und n einzelne fetchmail-Prozesse:
</p>

<pre>
#!/bin/sh

for config in $(ls /home/michael/.fetchmail)
do      
	fetchmail -f /home/michael/.fetchmail/$config --pidfile /tmp/fetchmail.$config.pid --idle
done
</pre>

<p>
Anschließend darf man sich über nahezu sofortige E-Mail-Zustellung freuen ;-).
</p>

