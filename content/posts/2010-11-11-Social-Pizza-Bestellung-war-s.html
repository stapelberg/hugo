---
permalink: /post/33
layout: post
date: 2010-11-11 21:28:10 +01:00
title: "
Social Pizza-Bestellung war s…"
---
<p>
Social Pizza-Bestellung war schon lange eine Funktionalität, die wir auf dem
Chaostreff haben wollten. Das bedeutet, dass jeder am eigenen Rechner sich
seine Wunschpizza klicken kann und wir dann genau eine Bestellung abschicken.
Aufgrund mangelnder Computerfähigkeiten der Jungs bei (bzw. hinter) Hallo
Pizza (Bestellungen gehen per Fax ein und werden dann abgetippt!), kommt dieses
Feature natürlich nicht.
</p>

<p>
Daher sind wir das mal selbst angegangen. Unsere Lösung besteht aus einem
Proxy-Server auf unserem Router, der Requests an hallopizza.de weiterleitet und
dabei das Cookie ersetzt. Wir haben dazu zwei vhosts: Einer mit hübschem
DNS-Namen, der dann auf den anderen mit korrekter URL weiterleitet (damit man
nicht auf der Eingangsseite landet).
</p>

<pre>
&lt;VirtualHost 172.22.37.2:80&gt;
        DocumentRoot /var/www
        &lt;Directory /&gt;
                Options FollowSymLinks
                AllowOverride None
        &lt;/Directory&gt;

        RewriteEngine on
        RewriteRule / http://172.22.37.1/bestellen/ [L]
&lt;/VirtualHost&gt;
</pre>

<p>
Der andere vhost ist dann Proxy-Server für hallopizza.de. Dabei gilt es zu
beachten, dass Antworten von hallopizza.de üblicherweise komprimiert sind
(gzip), d.h. via SetOutputFilter ausgepackt werden müssen. Anschließend
ersetzen wir die URL http://hallopizza.de/ durch http://172.22.37.1/ und fügen
ein Cookie hinzu (das holt man sich vorher von hallopizza.de, z.B. via wget):
</p>

<pre>
&lt;VirtualHost 172.22.37.1:80&gt;
        DocumentRoot /var/www
        &lt;Directory /&gt;
                Options FollowSymLinks
                AllowOverride None
        &lt;/Directory&gt;

        ProxyPass / http://hallopizza.de/
        ProxyPassReverse / http://hallopizza.de/

        AddOutputFilterByType SUBSTITUTE text/html
        Substitute "s|http://hallopizza.de|http://172.22.37.1/|in"

        SetOutputFilter INFLATE;substitute;DEFLATE
        RequestHeader set Cookie "hallopizza=blargh"
&lt;/VirtualHost&gt;
</pre>

<p>
Man sollte darauf achten, dass man nicht gleichzeitig im Warenkorb rumklickt,
hallopizza.de verträgt das nicht so gut. Wenn man das aber nacheinander macht,
funktioniert es einwandfrei.
</p>

