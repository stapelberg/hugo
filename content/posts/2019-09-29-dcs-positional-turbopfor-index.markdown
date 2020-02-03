---
layout: post
date: 2019-09-29
title: "Debian Code Search: positional index, TurboPFor-compressed"
categories: Artikel
tags:
- debian
- golang
---
<style type="text/css">
.bar {
  display: inline-block;
  padding: 0.25em;
  text-align: center;
  vertical-align: middle;
}

.barcon {
  width: 40em;
  display: flex;
}
</style>

See the [Conclusion](#conclusion) for a summary if you’re impatient :-)

### Motivation

Over the last few months, I have been developing a new index format for Debian
Code Search. This required a lot of careful refactoring, re-implementation,
debug tool creation and debugging.

Multiple factors motivated my work on a new index format:

1. The existing index format has a 2G size limit, into which we have bumped a
   few times, requiring manual intervention to keep the system running.

2. Debugging the existing system required creating ad-hoc debugging tools, which
   made debugging sessions unnecessarily lengthy and painful.

3. I wanted to check whether [switching to a different integer compression
   format](https://github.com/Debian/dcs/issues/85) would improve performance
   (it does not).

4. I wanted to check whether storing positions with the posting lists would
   improve performance of identifier queries (= queries which are not using any
   regular expression features), which make up 78.2% of all Debian Code Search
   queries (it does).

I figured building a new index from scratch was the easiest approach, compared
to refactoring the existing index to increase the size limit (point ①).

I also figured it would be a good idea to develop the debugging tool in lock
step with the index format so that I can be sure the tool works and is useful
(point ②).

### Integer compression: TurboPFor

As a quick refresher, search engines typically store document IDs (representing
source code files, in our case) in an ordered list (“posting list”). It usually
makes sense to apply at least a rudimentary level of compression: our existing
system used variable integer encoding.

[TurboPFor](https://github.com/powturbo/TurboPFor), the self-proclaimed “Fastest
Integer Compression” library, combines an advanced on-disk format with a
carefully tuned SIMD implementation to reach better speeds (in micro benchmarks)
at less disk usage than [Russ Cox’s varint implementation in
`github.com/google/codesearch`](https://github.com/google/codesearch/blob/4fe90b597ae534f90238f82c7b5b1bb6d6d52dff/index/write.go#L561).

If you are curious about its inner workings, check out my “[TurboPFor: an
analysis](/posts/2019-02-05-turbopfor-analysis/)”.

Applied on the Debian Code Search index, TurboPFor indeed compresses integers better:

#### Disk space

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 100%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">8.9G</span>
codesearch varint index

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 61%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">5.5G</span>
TurboPFor index

Switching to TurboPFor (via cgo) for storing and reading the index results in a
slight speed-up of a `dcs replay` benchmark, which is more pronounced the more
i/o is required.

#### Query speed (regexp, cold page cache)

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 100%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">18s</span>
codesearch varint index

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 77.7%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">14s</span>
TurboPFor index (cgo)

#### Query speed (regexp, warm page cache)

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 100%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">15s</span>
codesearch varint index

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 93.3%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">14s</span>
TurboPFor index (cgo)

Overall, TurboPFor is an all-around improvement in efficiency, albeit with a
high cost in implementation complexity.

### Positional index: trade more disk for faster queries

This section builds on the previous section: all figures come from the TurboPFor
index, which can optionally support positions.

Conceptually, we’re going from:

```
type docid uint32
type index map[trigram][]docid
```

…to:

```
type occurrence struct {
    doc docid
    pos uint32 // byte offset in doc
}
type index map[trigram][]occurrence
```

The resulting index consumes more disk space, but can be queried faster:

1. We can do fewer queries: instead of reading all the posting lists for all
   the trigrams, we can read the posting lists for the query’s first and last
   trigram only.
   <br>
   This is one of the tricks described in the paper
   “<a href="https://cedric.cnam.fr/fichiers/art_3216.pdf">AS-Index: A
   Structure For String Search Using n-grams and Algebraic Signatures</a>”
   (PDF), and goes a long way without incurring the complexity, computational
   cost and additional disk usage of calculating algebraic signatures.

2. Verifying the delta between the last and first position matches the length
   of the query term significantly reduces the number of files to read (lower
   false positive rate).

3. The matching phase is quicker: instead of locating the query term in the
   file, we only need to compare a few bytes at a known offset for equality.

4. More data is read sequentially (from the index), which is faster.

#### Disk space


A positional index consumes significantly more disk space, but not so much as
to pose a challenge: a Hetzner EX61-NVME dedicated server (≈ 64 €/month)
provides 1 TB worth of fast NVMe flash storage.

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 5.2%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">&nbsp;6.5G</span>
non-positional

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 100%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">123G</span>
positional

<div style="display: inline-block">
	<div class="barcon">
		<div class="bar" style="width: 75.6%; background-color: blue; color: white">
			&nbsp;
		</div>
	</div>
</div>
<span style="margin-right: 2em">&nbsp;&nbsp;93G</span>
positional (posrel)

The idea behind the positional index (posrel) is to not store a `(doc,pos)`
tuple on disk, but to store positions, accompanied by a stream of doc/pos
relationship bits: 1 means this position belongs to the next document, 0 means
this position belongs to the current document.

This is an easy way of saving some space without modifying the TurboPFor
on-disk format: the posrel technique reduces the index size to about ¾.

With the increase in size, the Linux page cache hit ratio will be lower for
the positional index, i.e. more data will need to be fetched from disk for
querying the index.

As long as the disk can deliver data as fast as you can decompress posting
lists, this only translates into one disk seek’s worth of additional
latency. This is the case with modern NVMe disks that deliver thousands of MB/s,
e.g. the Samsung 960 Pro (used in Hetzner’s aforementioned EX61-NVME server).

The values were measured by running `dcs du -h /srv/dcs/shard*/full`
without and with the `-pos` argument.

#### Bytes read

A positional index requires fewer queries: reading only the first and last
trigram’s posting lists and positions is sufficient to achieve a lower (!) false
positive rate than evaluating **all** trigram’s posting lists in a
non-positional index.

As a consequence, fewer files need to be read, resulting in fewer bytes required
to read from disk overall.

As an additional bonus, in a positional index, more data is read sequentially
(index), which is faster than random i/o, regardless of the underlying disk.

<div style="display: inline-block">
<div class="barcon">
<div class="bar" style="width: calc(2 * 1.2em); background-color: blue; color: white">
  1.2G
</div>
<div class="bar" style="width: calc(2 * 19.8em); background-color: green; color: white">
  19.8G
</div>
</div>
</div>
<span style="margin-right: 2em">21.0G</span>
regexp queries

<div style="display: inline-block">
<div class="barcon">
<div class="bar" style="width: calc(2 * 4.2em); background-color: blue; color: white">
  4.2G (index)
</div>
<div class="bar" style="width: calc(2 * 10.8em); background-color: green; color: white">
  10.8G (files)
</div>
</div>
</div>
<span style="margin-right: 2em">15.0G</span>
identifier queries

The values were measured by running `iostat -d 25` just before running
[`bench.zsh`](https://codesearch.debian.net/research/2019-08-03-dcs-new-index/)
on an otherwise idle system.

#### Query speed

Even though the positional index is larger and requires more data to be read at
query time (see above), thanks to the C TurboPFor library, the 2 queries on a
positional index are roughly as fast as the n queries on a non-positional index
(≈4s instead of ≈3s).

This is more than made up for by the combined i/o matching stage, which shrinks
from ≈18.5s (7.1s i/o + 11.4s matching) to ≈1.3s.

<div style="display: inline-block">
<div class="barcon">
<div class="bar" style="width: calc(2 * 3.3em); background-color: blue; color: white">
  3.3s (index)
</div>
<div class="bar" style="width: calc(2 * 7.1em); background-color: green; color: white">
  7.1s (i/o)
</div>
<div class="bar" style="width: calc(2 * 11.4em); background-color: purple; color: white">
  11.4s (matching)
</div>
</div>
</div>
<span style="margin-right: 2em">21.8s</span>
regexp queries

<div style="display: inline-block">
<div class="barcon">
<div class="bar" style="width: calc(2 * 3.92em); background-color: blue; color: white">
  3.92s (index)
</div>
<div class="bar" style="width: calc(2 * 1.3em); background-color: green; color: white">
  ≈1.3s
</div>
</div>
</div>
<span style="margin-right: 2em">5.22s</span>
identifier queries

Note that identifier query i/o was sped up not just by needing to read fewer
bytes, but also by only having to verify bytes at a known offset instead of
needing to locate the identifier within the file.

### Conclusion

The new index format is overall slightly more efficient. This disk space
efficiency allows us to introduce a positional index section for the first
time.

Most Debian Code Search queries are positional queries (78.2%) and will be
answered much quicker by leveraging the positions.

Bottomline, it is beneficial to use a positional index on disk over a
non-positional index in RAM.
