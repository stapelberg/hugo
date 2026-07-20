---
permalink: /post/16
layout: post
date: 2010-05-31 22:28:13 +02:00
title: "
Da ich mich häufig dabei erwi…"
---
<p>
Da ich mich häufig dabei erwische, im aktuellen Verzeichnis nach dem letzten
Coredump zu suchen um ihn inklusive zugehörigem Programm in den Debugger zu
laden, habe ich diese Aufgabe in ein Script ausgelagert. Die folgenden Zeilen
Perl suchen den letzten Coredump (dazu muss das Coredump-Pattern mit
<code>sysctl -w kernel.core_pattern = %e.core.%p</code> sinnvoll definiert
sein) und starten gdb mit den passenden Optionen:
</p>

<pre>
#!/usr/bin/env perl                                      
# vim:ts=4:sw=4:expandtab:ft=perl

use strict;
use warnings;
use File::stat;
use List::Util qw(max);
use v5.10;

# Get mtime/filename of all core dumps matching core.*.([0-9]+)$
my %files = map { (stat($_)->mtime, $_) } grep { /\.([0-9]+)$/ } &lt;*.core.*&gt;;
my $newest_dump = $files{max keys %files};

# Get the program which generated this core dump using file(1)
my $output = qx(file $newest_dump);
my ($call) = ($output =~ /'([^']+)'/);
my ($program, $args) = ($call =~ /([^ ]+) (.+)/);

# Call gdb
say "Running: gdb $program -c $newest_dump --args $program $args";
system "gdb $program -c $newest_dump --args $program $args";
</pre>

