---
permalink: /post/9
layout: post
date: 2010-04-18 00:00:23 +02:00
title: "
Heute in „Warum ich die GNU a…"
---
<p>
Heute in „Warum ich die GNU autotools nicht mag”: Warum unter IRIX PHP5 nicht
gelinkt werden kann. Die autotools sind eigentlich dazu da, Besonderheiten
bestimmter Systeme zu ermitteln, damit man als Programmierer beispielsweise
andere Funktionen nutzen kann, wenn auf einem System eine bestimmte Funktion
fehlt. Weiterhin prüfen die autotools, ob alle nötigen Libraries auf dem
System in hinreichend aktueller Version verfügbar sind und sie stellen mit
libtool ein Script bereit, mit dem man systemunabhängig shared libraries
erstellen kann.
</p>

<p>
Das Problem bei PHP5 ist nun, dass die Länge des Befehls zum Linken aufgrund
der vielen .o-Dateien so lang ist, dass libtool glaubt, den Befehl in
mehrere aufteilen zu müssen und anschließend scheitert. Aber eigentlich ist der
Befehl nicht zu lang, sondern das Makro in libtool.m4 prüft falsch. Wer sich
ein bisschen an grässlichem Code ergötzen möchte kann sich das Makro
LT_CMD_MAX_LEN <a
href="http://git.savannah.gnu.org/cgit/libtool.git/tree/libltdl/m4/libtool.m4#n1457">gerne
mal ansehen</a>. Ansonsten hier der Patch, mit dem das Problem gelöst wird:
</p>

<pre>
--- a/libltdl/m4/libtool.m4
+++ b/libltdl/m4/libtool.m4
@@ -1465,6 +1465,10 @@ AC_CACHE_VAL([lt_cv_sys_max_cmd_len], [dnl
   teststring="ABCD"
 
   case $build_os in
+  irix*)
+    lt_cv_sys_max_cmd_len=`getconf ARG_MAX`
+    ;;
+
   msdosdjgpp*)
     # On DJGPP, this test can blow up pretty badly due to problems in libc
     # (any single argument exceeding 2000 bytes causes a buffer overrun
</pre>

<p>
<code>getconf</code> ist übrigens in POSIX.2, also 1992 (!) spezifiziert. Es
ist mir ein Rätsel, warum man das nicht in erster Linie verwendet. Verwendet
jemand ernsthaft noch 20 Jahre alte Systeme und denkt, er könne sich
beschweren, wenn aktuelle Software nicht mehr läuft?
</p>

<p>
Übrigens: Wenn du dein System (für ein paar Minuten?) aufhängen möchtest,
kannst du mal den Teil des LT_CMD_MAX_LEN-Makros ausführen, der für unbekannte
Systeme verwendet wird…
</p>

