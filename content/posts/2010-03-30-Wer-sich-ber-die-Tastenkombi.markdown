---
permalink: /post/5
layout: post
date: 2010-03-30 13:55:48 +02:00
title: "
Wer sich über die Tastenkombi…"
---
<p>
Wer sich über die Tastenkombination <code>Shift+Insert</code> zum Pasten
ärgert (auf manchen Tastaturen schwer erreichbar), kann folgendermaßen eine
beliebige Taste mit der mittleren Maustaste (also effektiv Pasten) belegen:
</p>

<pre>
xmodmap -e 'keycode 115 = Pointer_Button2'
xkbset m
xkbset exp =m
</pre>

<p>
Die <code>xkbset</code>-Aufrufe aktivieren den Mousekeys-Modus und sind nötig,
damit das spezielle Keysym Pointer_Button2 zur Verfügung steht. Keycodes der
einzelnen Tasten findet man übrigens mit <code>xev(1)</code> raus.
</p>

