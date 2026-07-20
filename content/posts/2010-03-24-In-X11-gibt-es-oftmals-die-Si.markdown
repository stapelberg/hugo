---
permalink: /post/4
layout: post
date: 2010-03-24 03:03:04 +01:00
title: "
In X11 gibt es oftmals die Si…"
---
<p>
In X11 gibt es oftmals die Situation, dass es eine alte API gibt, die aufgrund
einer neuen Extension obsolet wurde. So beispielsweise auch bei Mauszeigern:
Es gibt eine spezielle Schriftart namens „cursor”, welche Masken enthält, die
Vordergrund und Hintergrund der jeweiligen Cursor bestimmen (siehe
<a href="http://www.cs.arizona.edu/icon/docs/images/gipd9.gif">
http://www.cs.arizona.edu/icon/docs/images/gipd9.gif</a>). Es gibt also eine
Funktion, mit der man aus einem solchen „Zeichen” innerhalb der Font einen
X11-Cursor erzeugen kann und diesen auf seinem Fenster setzen kann.
</p>

<p>
Die neue Variante, die dann auch Cursor-Themes unterstützt
(<code>~/.icons/*/cursors</code> und <code>Xcursor.theme</code> in den
Xresources) funktioniert über die RENDER-Extension: Man lädt die Cursor
manuell aus der entsprechenden Datei, kopiert diese dann in eine X11-Pixmap
und lässt via RENDER einen X11-Cursor daraus erzeugen. In Xlib wird diese
Variante transparent benutzt, wenn man die alte API-Funktion aufruft. Solche
Umleitungen gibt es dort zuhauf, wohingegen XCB wirklich nur das Protokoll
implementiert und solche Hacks nicht beinhaltet (weswegen ich mich überhaupt
mit Mauszeigern beschäftige…).
</p>

<p>
Bei den Recherchen zu diesem Sachverhalt bin ich auf folgenden lustigen
Hack gestoßen:
<a href="http://vektor-sigma.livejournal.com/1137.html">
http://vektor-sigma.livejournal.com/1137.html</a> (ab dem 2. Absatz).
Kurz gesagt hat Mozilla einen eigenen Mauszeiger (sog. „left_ptr_watch”)
während des Ladens, der nicht in den Cursor-Themes enthalten ist. Keith
Packard (ein X11-Entwickler) wollte diesen aber unbedingt via Theme ändern und
hat deswegen implementiert, dass, wenn man <strong>genau die Pixmap des
Mozilla-Cursors </strong> nutzt, der Cursor auf die Theme-Variante mit Namen
„left_ptr_watch” geändert wird.
</p>

