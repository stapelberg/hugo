---
permalink: /post/26
layout: post
date: 2010-07-31 03:00:07 +02:00
title: "
Nachdem Rakudo Star am Donner…"
---
<p>
Nachdem <a href="http://www.rakudo.org/">Rakudo Star</a> am Donnerstag
herausgekommen ist, habe ich hier mal schnell ein paar Zeilen zusammengehackt,
um ein Dokument aus CouchDB zu holen. LWP::Simple und JSON::Tiny kommen bei
Rakudo direkt mit:
</p>

<pre>
#!/usr/bin/env perl6
use v6;
use JSON::Tiny;
use LWP::Simple;

my $dburl = 'http://localhost:5984/foo';

my $json = LWP::Simple.new.get("$dburl/b616376f0add14a2feda9ad46b0025f3");
my $doc = from-json($json);
say $doc.perl;
</pre>

<p>
Das Programm sollte relativ klar sein, mit LWP::Simple kommuniziert man mit
CouchDB, das Ergebnis decoded man mit from-json und das Analogon zu
Data::Dumper ist die <code>.perl</code>-Method auf beliebige Datenstrukturen.
</p>

<p>
Die Ausgabe sieht dann so aus:
</p>

<pre>
$ time /home/michael/rakudo-star/rakudo-star-2010.07/install/bin/perl6 poc.pl
{"added" => "2010/07/29 14:29:57 +0200", "_id" => "b616376f0add14a2feda9ad46b0025f3", "_rev" => "1-57f31860902c59c53be8c06ee9556ee8", "text" => "fnord", "tags" => ["meh"]}
perl6 poc.pl  1,47s user 0,15s system 90% cpu 1,794 total
</pre>

<p>
Dass es noch ein bisschen langsam ist (zum Vergleich: 0,138s mit Perl 5), wurde
ja mit angekündigt bei dem Release.
</p>

