---
permalink: /post/20
layout: post
date: 2010-07-21 01:22:41 +02:00
title: "
Wer i3lock nutzt ist herzlich…"
---
<p>
Wer <a href="http://i3.zekjur.net/i3lock/">i3lock</a> nutzt ist herzlich dazu
eingeladen, den <a
href="http://code.stapelberg.de/git/i3lock/log/?h=xcb">xcb-Branch</a> von
i3lock auszuprobieren. Der Code darin wurde komplett auf <a
href="http://xcb.freedesktop.org/">xcb</a> portiert und ist dadurch zum einen
hübscher und geringfügig schneller, zum anderen wurden einige Probleme behoben.
Eine kurze Übersicht:
</p>

<ul>
<li>Man kann Bilddateien im PNG-Format statt im XPM-Format laden</li>
<li>Beim Suspend-to-RAM verschwindet das Bild nicht mehr gelegentlich</li>
<li>Popups überlagern nun nicht mehr das i3lock-Fenster (sondern i3lock bleibt permanent im Vordergrund)</li>
</ul>

<p>
Für diejenigen, die nicht fließend git sprechen:
</p>

<pre>
$ git clone git://code.stapelberg.de/i3lock -b xcb
$ cd i3lock
$ sudo apt-get install libpam0g-dev libcairo2-dev libxcb1-dev libxcb-dpms0-dev libxcb-keysyms1-dev libxcb-image0-dev
$ make
$ sudo make install
</pre>

