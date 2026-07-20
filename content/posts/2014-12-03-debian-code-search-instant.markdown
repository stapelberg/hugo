---
layout: post
date: 2014-12-03 21:30:00 +0100
title: "Announcing the new Debian Code Search Instant"
categories: Artikel
tags:
- debian
---
<p>
For the last few months, I have been working on a new version of Debian Code
Search, and today it’s going live! I call it <a
href="http://codesearch.debian.net/">Debian Code Search Instant</a>, for
multiple reasons, see below.
</p>

<h3>A lot faster</h3>

<p>
The new Debian Code Search is still hosted by <a
href="http://rackspace.com/">Rackspace</a> (thank you!), but our new
architecture finally allows us to use their <a
href="http://www.rackspace.com/blog/got-the-need-for-speed-meet-performance-cloud-servers/">“Performance
Cloud Servers” hardware generation</a>.
</p>

<p>
The old code search architecture was split across 5 different servers, however
the search itself was only performed on a single machine with a network
attached block volume backed by SSD. The new Code Search spreads
out both the trigram index and the source code onto 6 different servers, and
thanks to the new hardware generation, we have a locally connected SSD drive in
each of them. So, we now get more than 6 times the IOPS we’ve had before, at
much lower latency :).
</p>

<h3>Grouping by Debian source package</h3>

<p>
<a href="https://github.com/Debian/dcs/issues/1">The first feature request</a>
we ever got for Code Search was to group results by Debian source package. I’ve
tried tackling that before, but it’s a pretty hard problem. With the new
architecture and capacity, this finally becomes feasible.
</p>

<p>
After your query completes, there is a checkbox called “Group search results by
Debian source package”. Enable it, and you’ll get neatly grouped results. For
each package, there is a link at the bottom to refine the search to only
consider that package.
</p>

<p>
In case you are more interested in the full list of packages, for example
because you are doing large-scale changes across Debian, that’s also possible:
Click on the ▾ symbol right next to the “Filter by package” list, and a curl
command will be revealed with which you can download the full list of packages.
</p>

<h3>Expensive queries (with lots of results) now possible</h3>

<p>
Previously, we had a 60 second timeout during which queries must complete. This
timeout has been completely lifted, and long-running queries with tons and tons
of results are now possible. We kindly ask you to not abuse this feature — it’s
not very exciting to play with complexity explosion in regular expression
engines by preventing others from doing their work. If you’re interested in
that sort of analysis, go grab <a href="https://github.com/Debian/dcs">the
source code</a> and play with it on your own machine :).
</p>

<h3>Instant results</h3>

<p>
While your query is running, you will almost immediately see the top 10
results, even though the search may still take a while. This is useful to
figure out if your regular expression matches what you thought it would, before
having to wait until your 5 minute query is finished.
</p>

<p>
Also, the new progress bar tells you how far the system is with your search.
</p>

<h3>Instant indexing</h3>

<p>
Previously, Code Search was deployed to a new set of machines from scratch
every week in order to update the index. This was necessary because the
performance would severely degrade while building the index, so we were
temporarily running with twice the amount of machines until the new version was
up.
</p>

<p>
In the new architecture, we store an index for each source package and then <a
href="https://github.com/Debian/dcs/blob/master/index/concatn.go">merge these
into one big index shard</a>. This currently takes about 4 minutes with the
code I wrote, but I’m sure this can be made even faster if necessary. So,
whenever new packages are uploaded to the Debian archive, we can just index the
new version and trigger a merge. We get notifications about new package uploads
from <a href="https://wiki.debian.org/FedMsg">FedMsg</a>. Packages that are not
seen on FedMsg for some reason are backfilled every hour.
</p>

<p>
The time between uploading a package and being able to find it in Debian Code
Search therefore now ranges from a couple of minutes to about an hour, instead
of about a week!
</p>

<h3>New, beautiful User Interface</h3>

<p>
Since we needed to rewrite the User Interface anyway thanks to the new
architecture, we also spent some effort on making it modern, polished and
beautiful.
</p>

<p>
Smooth CSS animations make you aware of what’s going on, and the search results
look cleaner than ever.
</p>

<h3>Conclusion</h3>

<p>
At least to me, the new Debian Code Search seems like a significant improvement
over the old one. I hope you enjoy the new features into which I put a lot of
work. In case you have any feedback, I’m happy to hear it (see the “contact”
link at the bottom of every Code Search site).
</p>
