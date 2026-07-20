---
permalink: /post/28
layout: post
date: 2010-09-07 08:12:23 +02:00
title: "
Und nun die Patches von heute…"
---
<p>
Und nun die Patches von heute, Montag, dem 2010-09-06:
</p>

<ul>
  <li>
    <a href="https://issues.apache.org/jira/browse/COUCHDB-878">Korrekte
    Validierung der Zertifikate bei Replikation via SSL sicherstellen</a>
    (Erlang kommt standardmäßig mit der Einstellung, dass der Fehler
     unknown_ca einfach ignoriert wird)
  </li>
  <li>
    <a href="https://issues.apache.org/jira/browse/COUCHDB-879">Replikation
    kommt bei Transfer-Encoding: Chunked (Standard bei CouchDB) und SSL ins
    Stocken</a> (wir sind uns noch nicht ganz sicher, was das eigentliche
    Problem ist)
  </li>
  <li>
    <a href="https://issues.apache.org/jira/browse/COUCHDB-665">Replikation
    via IPv6 ermöglichen</a> (überarbeitet, da der alte Patch bindv6only=0
    voraussetzte, was mir nicht bewusst war)
  </li>
  <li>
    <a
    href="http://wiki.apache.org/couchdb/Apache_As_a_Reverse_Proxy?action=diff&rev1=15&rev2=16">Erklärung
    wie man Replikation hinter einem SSL-Proxy (z.B. Apache) zum Laufen
    bekommt</a> (CouchDBs Handling des <code>X-Forwarded-Host</code>-Headers
    kommt hier ProxyPassReverse in die Quere)
  </li>
</ul>

<p>
Wem es nicht aufgefallen ist: Ja, alles CouchDB, ja, alles von mir. Dabei wollte
ich vorhin doch nur mal eben die Datenbank replizieren…
</p>

