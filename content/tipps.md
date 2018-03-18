---
title: "Tipps"
date: 2017-05-25T11:38:28+02:00
aliases:
  - /Tipps
---

Die folgenden Programme finde ich empfehlenswert:

### cgit

[cgit](http://git.zx2c4.com/cgit/) ist ein schnelles
und gut-aussehendes Webinterface für git, welches in C geschrieben ist. Im
Vergleich zu gitweb, trac oder anderen Interfaces ist es mindestens doppelt
so schnell und (meiner Meinung nach) um Längen komfortabler.

### notmuch

[notmuch](https://notmuchmail.org/) ist ein netter Mailclient für die
Kommandozeile (benutzt curses), der besonders für Nutzer von Google
Mail interessant sein dürfte. Die Philosophie ist, dass man generell
mit Threads arbeitet und nicht mit einzelnen Mails (letztendlich ist
eine einzelne Nachricht auch nur ein Spezialfall eines
Threads). Weiterhin ist die Oberfläche sehr intelligent gestaltet,
zeigt also die wichtigen Dinge an (den ersten Teil der letzten
Nachricht eines Threads in der Übersicht, bei Nachrichten wird die
Signatur und Zitate aus vorherigen Mails standardmäßig ausgeblendet).

Statt Nachrichten in Ordner einzusortieren, vergibt man in notmuch
einfach Tags. Das Ordnerkonzept kann dadurch abgebildet werden, dass
man einer Nachricht einfach genau einen Tag gibt. Man kann dann
entweder nach Tags filtern oder direkt die Nachrichten
durchsuchen. Beides dauert (bis zu einer gewissen Grenze an
Nachrichten) nicht wirklich lange und ermuntert daher zum Vergeben von
Tags.

### collectd

Mit [collected](http://collectd.org/) kann man Statistiken über das
eigene System (oder entfernte Rechner via `network`-Plugin) sammeln
lassen. Mit einem der Frontends oder eigenen rrdtool-Aufrufen kann man
daraus dann hübsche Graphen bauen lassen. Ideal, um es in eine eigene
Monitoring-Lösung einzubinden.

### ncdu

[ncdu](http://dev.yorhel.nl/ncdu) ist ein Programm,
das einem die Größe der einzelnen Ordner anzeigt. Nie wieder
`du -hs *` ;-).

### asciidoc

[asciidoc](http://www.methods.co.nz/asciidoc/) ist ein Programm,
welches aus Textdateien Dokumentation erzeugt (wahlweise HTML, LaTeX,
manpages, …). Die Eingabe kann man sehr schnell lernen, die Ausgabe
sieht gut aus. Mit asciidoc werden zum Beispiel die Manpages von git
gemacht und auch dessen
[Online-Dokumentation](http://www.kernel.org/pub/software/scm/git/docs/).

### pmount

Mit pmount kann man Geräte im Userspace mounten. Diese werden dann in
`/media` gemounted. Anstelle von fixen Einträgen in der `/etc/fstab`
oder dem Arbeiten als root heißt es nun also:

    $ pmount sdb1
    $ cp foo.pdf /media/sdb1/
    $ pumount sdb1

### App::Ack

[ack](http://betterthangrep.com/) ist ein Programm, das besser als
grep ist, wenn es darum geht, Quelltext zu durchsuchen. Es durchsucht
standardmäßig rekursiv und ignoriert Dateien von
Versionskontrollsystemen (git, svn, …). ack macht das Zurechtfinden in
Sourcecode wirklich enorm viel einfacher.

**UPDATE:** Mittlerweile gibt es einige deutlich schnellere
Alternativen wie
z.B. [silversearcher](https://github.com/ggreer/the_silver_searcher)
oder [ripgrep](https://github.com/BurntSushi/ripgrep).

### vnstat

[vnstat](http://humdi.net/vnstat/) ist ein kleines Tool, welches den
Traffic auf Netzwerkschnittstellen unter Linux oder BSD misst und
speichert. Wer ein schlankes Tool ohne viel Schnickschnack für ein
bisschen Übersicht beim verbrauchten Traffic braucht ist hiermit gut
beraten.

### NEO-Layout

Das [NEO-Layout](http://www.neo-layout.org/) ist ein besonders
ergonomisches Layout, welches für deutsche Texte optimiert
wurde. Insbesondere sind dabei nicht nur Algorithmen, sondern auch
praktische Erfahrungen in die Positionierung der Buchstaben
geflossen. Weiter interessant ist die große Menge an Sonderzeichen auf
den zusätzlichen Ebenen. So wird zum Beispiel korrekte Typographie
(mit Unicode) oder das Aufschreiben mathematischer Formeln zum
Kinderspiel.

Über meine Erfahrungen mit dem NEO-Layout gehe ich in meinem Artikel
[NEO-Layout auf einer Kinesis
Advantage-Tastatur](/Artikel/Neo_Kinesis) genauer ein.
