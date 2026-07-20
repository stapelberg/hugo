---
layout: post
date: 2013-07-14 18:10:00 +0200
title: "How many packages does Debian Code Search contain?"
categories: Artikel
tags:
- debian
---
<p>
The German computer magazine <a href="http://www.heise.de/ct/">c't</a> has
covered <a href="http://sources.debian.net/">Debsources</a> in its most recent
edition (c't 16/2013). In that article, they also state:
</p>

<pre>
Debsources integriert auch eine Code-Suche, allerdings werden lediglich die
Quellen des Unstable-Zweigs durchsucht, der zirka ein Drittel des Quellcodes
von Debsources ausmacht.
</pre>

<p>
This loosely translates to:
</p>

<pre>
Debsources also integrates a code search engine, but it only searches the
sources of the unstable tree, which makes up for roughly one third of the
sources that Debsources covers.
</pre>

<p>
I suspect the author of the article arrived at this conclusion because
Debsources talks about 400 GiB of source code, whereas <a
href="http://codesearch.debian.net/">Debian Code Search</a> talks about 130 GiB
of source code.
</p>

<p>
However, it still struck me as odd and giving the wrong impression. I thought
that packages don’t differ that much between stable, testing and unstable. So I
fired up <code>psql</code> and pounded <a href="http://udd.debian.org/">UDD</a>
until it revealed how many packages are different between stable, testing and
unstable:
</p>

<ul>
<li>
3581 of wheezy’s packages have a newer upstream version in testing. The total
amount of packages in wheezy is 17576, so this makes about 20.3%.
</li>

<li>
1131 (6%) of these packages are even newer in unstable.
</li>

<li>
13092 packages (74%) have identical upstream versions in wheezy, testing and
unstable.
</li>
</ul>

<h3>Conclusion</h3>

<p>
So, in conclusion, Debian Code Search covers 74% of wheezy, testing and
unstable. Debsources also covers contrib and non-free, which explains the
higher disk usage. In particular, there might be big blobs in non-free that
account for a lot of disk space. Also, Debsources keeps sources around for a
few weeks whereas Debian Code Search only keeps the most recent snapshot.
</p>

<h3>Query</h3>

<pre>

SELECT
  COUNT(*)
FROM
  (SELECT
     migrations.source,
     sources.version AS stable_version,
     testing_version,
     unstable_version
   FROM sources
   LEFT JOIN migrations
   USING (source)
   WHERE sources.release = 'wheezy') AS x
WHERE
  regexp_replace(stable_version::text, E'-([0-9.]+)$', '') = regexp_replace(testing_version::text, E'-([0-9.]+)$', '');
</pre>
