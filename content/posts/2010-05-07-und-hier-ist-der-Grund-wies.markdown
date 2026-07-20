---
permalink: /post/13
layout: post
date: 2010-05-07 21:45:07 +02:00
title: "
…und hier ist der Grund, wies…"
---
<p>
…und hier ist der Grund, wieso alle qt-Programme in der falschen Sprache angezeigt werden: Die Klasse QLocale <a href="http://qt.gitorious.org/qt/qt/blobs/5ae330b6546dabada53c394b53ce9513f552a8a5/src/corelib/tools/qlocale.cpp#line364">macht das system-locale (welches die meisten Programme an QTranslator verfüttern) an <code>LC_NUMERIC</code> (!) fest</a>. Normalerweise ist dafür <code>LC_MESSAGES</code> zuständig.
</p>

<p>
<a href="http://bugreports.qt.nokia.com/browse/QTBUG-1313">Hier ist der passende Bugreport</a>, der übrigens seit 2007-11-12 offen ist…
</p>

