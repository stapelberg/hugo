---
permalink: /post/21
layout: post
date: 2010-07-23 20:35:25 +02:00
title: "
Auf dem N900 kann man Fotos/V…"
---
<p>
Auf dem N900 kann man Fotos/Videos via flickr und anderen Diensten direkt ins
Netz stellen. Gestern fiel mir auf, dass flickr bei kostenlosen Accounts
allerdings ein Limit von 2 Videos pro Monat hat, was ein bisschen stört, wenn
man gerade das dritte Video hochladen möchte. Neben flickr und ovi, den
einzigen beiden Plugins, die standardmäßig installiert sind, gibt es natürlich
auch ein youtube-Plugin (für das man sich im Ovi Store registrieren muss,
obwohl es kostenlos ist). Leider konnte ich das youtube-Plugin nicht nutzen, da
es mir immer wieder sagte, mein Benutzername/Passwort seien falsch, obwohl ich
beides mehrfach verifiziert und alle Varianten durchprobiert habe (im Browser
klappt der Login).
</p>

<p>
Knappe 24 Stunden später ist nun ein Plugin programmiert, welches sich in die
Share-Funktion einbindet und es erlaubt, Dateien auf beliebige WebDAV-Server
hochzuladen.
</p>

<p>
Screenshots und Download gibts auf <a
href="http://michael.stapelberg.de/webdav-plugin.html">meiner Website</a>, den
Sourcecode findet man <a href="http://code.stapelberg.de/git/webdav-plugin/">
im git</a> (letztendlich ein bisschen Glue Code zwischen Nokias libsharing und
libneon für die WebDAV-requests). Ein Upload in das extras-devel-Repository auf
maemo.org folgt.
</p>

