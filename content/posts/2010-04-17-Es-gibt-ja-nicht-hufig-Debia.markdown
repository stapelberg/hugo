---
permalink: /post/8
layout: post
date: 2010-04-17 11:27:00 +02:00
title: "
Es gibt ja nicht häufig Debia…"
---
<p>
Es gibt ja nicht häufig Debian-Bugs, bei denen ein Facepalm angebracht wäre,
aber das hier ist einer: Im Schriftpaket ttf-linux-libertine gab es <a
href="http://bugs.debian.org/523186">Bug #523186</a>, bei dem es um ein
OpenOffice.org-Problem mit dieser Schriftart geht. Die „Lösung” war dann, die
Schriftart umzubenennen, und zwar zu „Linux Libertine O” (das ist der
OpenFont-Name, nicht der TrueType-Name!). Wenn man sich also diese Schriftart
von SourceForge lädt, heißt sie anders, als wenn man sie aus Debian
installiert. Dass sowas nicht lange gut geht, ist eigentlich klar, und
natürlich macht es XeTeX-Dokumente, die als Schriftart „Linux Libertine”
verwenden, grandios kaputt:
</p>

<pre>
! Font \zf@basefont="Linux Libertine" at 10.0pt not loadable: Metric (TFM) file
 or installed font not found.
 \zf@fontspec ...ntname \zf@suffix " at \f@size pt
                                                   \unless \ifzf@icu \zf@set@...
l.3 \setmainfont{Linux Libertine}
</pre>

<p>
Der Workaround ist also zunächst, sich <a
href="http://www.sourceforge.net/projects/linuxlibertine">Linux Libertine von
SourceForge</a> zu laden, dann die .ttf-Dateien nach <code>~/.fonts/</code> zu
kopieren und via <code>fc-cache -fv</code> den Fontconfig-cache zu
aktualisieren. Natürlich habe ich einen <a
href="http://bugs.debian.org/578141">Debian-Bugreport</a> dazu aufgemacht.
</p>

