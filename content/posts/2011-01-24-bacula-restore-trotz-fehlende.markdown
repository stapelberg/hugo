---
permalink: /post/40
layout: post
date: 2011-01-24 14:10:59 +01:00
title: "
bacula-restore trotz fehlende…"
---
<p>
bacula-restore trotz fehlender Datenbankeinträge (weil ich mir das sonst immer
wieder zusammenreimen muss):
</p>

<pre>
# Keine weiteren Jobs laufen lassen, sonst werden die neuen Einträge gleich
# wieder gelöscht
$ /etc/init.d/bacula-dir stop

# Volumes foo-1 bis foo-3 scannen, Einträge aktualisieren (-m) und tatsächlich
# in der Datenbank speichern (-s), dabei Fortschritt anzeigen (-S)
$ bscan -P bacula -S -s -m -c /etc/bacula/bacula-sd.conf -V 'foo-1|foo-2|foo-3' foo-files

# Workaround, purgedfiles wird nicht richtig aktualisiert in der DB
$ echo 'UPDATE job SET purgedfiles = 0 WHERE jobid IN (123, 456, 789)' | psql -U bacula bacula
</pre>

