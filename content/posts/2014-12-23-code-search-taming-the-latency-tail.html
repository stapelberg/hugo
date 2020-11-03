---
layout: post
date: 2014-12-23 08:45:00 +0100
title: "Debian Code Search: taming the latency tail"
categories: Artikel
tags:
- debian
---
<p>
It’s been a couple of weeks since I’ve launched <a href="../../Bilder/2014/12/03/debian-code-search-instant.html">Debian Code Search Instant</a>,
so people have had the chance to use it for a while and that gives me plenty of
data points to look at :-). For every query, I log the search term itself as
well as the duration the query took to execute. That way, I can easily identify
queries that take a long time and see why that is.
</p>

<p>
There is a class of queries for which Debian Code Search (DCS) doesn’t perform
so well, and that’s queries that consist of trigrams which are extremely
common. Whenever DCS receives such a query, it needs to search through a lot of
files. Note that it doesn’t really matter if there are plenty of results or not
— it’s the number of files that potentially contain a result which matters.
</p>

<p>
One such query is “arse” (we get a lot of curse words). It consists of only two
trigrams (“ars” and “rse”), which are extremely common in program source code.
As a couple of examples, the terms “parse”, “sparse”, “charset” and “coarse”
are all matched by that. As an aside, if you really want to search for just
“arse”, use word boundaries, i.e. “<code>\barse\b</code>”, which also makes the query
significantly faster.
</p>

<h3>Fixing the overloaded frontend</h3>

<p>
When DCS first received the query, “arse” would lead to our frontend server
crashing. That was due to (intentionally) unoptimized code — we were
aggregating all search results from all 6 source backends in memory, sorted
them, and then wrote them out to disk.
</p>

<p>
I addressed this in <a href="https://github.com/Debian/dcs/commit/d2922fe92a2c80da4442447040ca21d6fb342d55">commit d2922fe92</a> with the following measures:
</p>
<ol>
<li>
Instead of keeping the entire result in memory, just write the result to a
temporary file on disk (“unsorted.json”) and store pointers into that file in
memory, i.e. (offset, length) tuples. In order to sort the results, we also
need to store the ranking and the path (to resolve ties and thereby guarantee a
stable result order over multiple search queries). For grouping the results by
source package, we need to keep the package name.
</li>

<li>
If you think about it, you don’t need the entire path in order to break a tie —
the hash is enough, as it defines an ordering. That ordering may be different,
but any ordering is good enough for the purpose of merely breaking a tie in a
deterministic way. I’m using Go’s <a
href="http://golang.org/pkg/hash/fnv/">hash/fnv</a>, the only non-cryptographic
(fast!) hash function that is included in Go’s standard library.
</li>

<li>
Since this was still leading to Out Of Memory errors, I decided to not store a
copy of the package name in each search result, but rather use a pointer into a
string pool containing all package names. The number of source package names is
relatively small, in the order of 20,000, whereas the number of search results
can be in the millions. Using the stringpool is a clear win — the overhead in
the case where #results &lt; #srcpackages is negligible, but as soon as
#results &gt; #srcpackages, you save memory.
</li>
</ol>

<p>
With all of that fixed, the query became at all possible, albeit with a runtime
of around 20 minutes.
</p>

<h3>Double Writing</h3>

<p>
When running such a long-running query, I noticed that the query ran smooth for
a while, but then it took multiple seconds without any visible progress at the
end of the query before the results appeared. This was due to the frontend
ranking the results and then converting “unsorted.json” into actual result
pages. Since we provide results ordered by ranking, but also results grouped by
source packages, it was writing every result twice to disk. What’s even worse
is that due to re-ordering, every read was essentially random (as opposed to
sequential reads).
</p>

<p>
What’s even worse is that nobody will ever click through all the hundreds of
thousands of result pages, so they are prepared entirely in vain. Therefore,
with <a
href="https://github.com/Debian/dcs/commit/c744b236e29225b6658b97a1a0debfcf76eb3b1f">commit
c744b236e</a> I made the frontend generate these result pages on demand. This
cut down the time for the ranking phase at the end of each query from 20-30
seconds (for big queries) to typically less than one second.
</p>

<h3>Profiling/Monitoring</h3>

<p>
After adding monitoring to each of the source-backends, I realized that during
these long-running queries, the disk I/O and network I/O was nowhere near my
expectations: each source-backend was sending only a low single-digit number of
megabytes per second back to the frontend (typically somewhere between 1&nbsp;MB/s
and 3&nbsp;MB/s). This didn’t match up at all with the bandwidth I observed in
earlier performance tests, so I used <code>wget -O /dev/null</code> to send a
query and discard the result in order to get some theoretical performance
numbers. Suddenly, I was getting more than 10&nbsp;MB/s worth of results, maxing
out the disks with a read rate of about 200&nbsp;MB/s.
</p>

<p>
So where is the bottleneck? I double-checked that neither the CPU on any of our
VMs, nor the network between them was saturated. Note that as of this point,
the CPU of the frontend was at roughly 70% (of one core), which didn’t seem a
lot to me. Then, I followed <a
href="http://blog.golang.org/profiling-go-programs">this excellent tutorial on
profiling Go programs</a> to see where the frontend is spending its time. Turns
out, the biggest consumer of CPU time was the <a
href="http://golang.org/pkg/encoding/json">encoding/json Go package</a>, which
is used for deserializing results received from the backend and serializing
them again before sending them to the client.
</p>

<p>
Since I was curious about it for a while already, I decided to give <a
href="http://kentonv.github.io/capnproto/">cap’n proto</a> a try to replace
JSON as serialization mechanism for communication between the source backends
and the frontend. <a
href="https://github.com/Debian/dcs/commit/8efd3b41ed17912e320d180ff1033cb7203e44e2">Switching
to it (commit 8efd3b41)</a> brought down the CPU load immensely, and made the
query a bit faster. In addition, I killed the next biggest consumer: the
<code>lseek(2)</code> syscall, which we used to call with <code>SEEK_CUR</code>
and an offset of 0 so that it would tell us the current position. This was
necessary in the first place because we don’t know in advance how many bytes
we’re going to write when serializing a result to disk. The replacement is a
neat little trick:
</p>

<pre>
type countingWriter int64

func (c *countingWriter) Write(p []byte) (n int, err error) {
    *c += countingWriter(len(p))
    return len(p), nil
}

// […]
// Then, use an io.MultiWriter like this:
var written countingWriter
w := io.MultiWriter(s.tempFiles[backendidx], &amp;written)
result.WriteJSON(w)
</pre>

<p>
With some more profiling, the new bottleneck was suddenly the
<code>read(2)</code> syscall, issued by the cap’n proto deserialization,
operating directly on the network connection buffer. <code>strace</code>
revealed that crunching through the results of one source backend for a long
query, <code>read(2)</code> was called about 250,000 times. By simply <a
href="https://github.com/Debian/dcs/commit/684467aef59ac4b3c2488666c54cdd865b254f49">using
a buffered reader (commit 684467ae)</a>, I could reduce that to about 2,000
times.
</p>

<p>
Another bottleneck was the fact that for every processed result, the frontend
needed to update the query state, which is shared amongst all goroutines (there
is one goroutine for each source backend). All that parallelism isn’t very
effective if you need to synchronize the state updates in the end. So with <a
href="https://github.com/Debian/dcs/commit/5d46a572a762c2e2ccf8b7b4322cb140c8aa9f0b">commit
5d46a572</a>, I refactored the state to be per-backend, so that locking is only
necessary for the first couple of results, and the vast vast majority of
results can be processed entirely without locking.
</p>

<p>
This brought down the query time from 20 minutes to about 5 minutes, but I
still wasn’t happy with the bandwidth: the frontend was doing a bit over
10&nbsp;MB/s of reads from all source backends combined, whereas with
<code>wget</code> I could get around 40&nbsp;MB/s with the same query. At this
point, the CPU utilization was around 7% of one core on the frontend, and
profiling didn’t immediately reveal an obvious culprit.
</p>

<p>
After a bit of experimenting (by commenting out code here and there ;-)), I
figured out that the problem was that the frontend was still converting these
results from capnproto buffers to JSON. While that doesn’t take a lot of CPU
time, it delays the network stream from the source-backend: once the local and
remote TCP buffers are full, the source-backend will (intentionally!) not
continue with its search, so that it doesn’t run out of memory. I’m still
convinced that’s a good idea, and in fact I was able to solve the problem in an
elegant way: instead of writing JSON to disk and generating result pages on
demand, we now <a
href="https://github.com/Debian/dcs/commit/466b7f3ee1aecfdbc78b5dcf9f860aaae22b7e00">write
capnproto directly to disk (commit 466b7f3e)</a> and convert it to JSON only
before sending out the result pages. That decreases the overall CPU time since
we only need to convert a small fraction of the results to JSON, but most
importantly, the frontend is now not in the critical path anymore. It can
directly pass the data through, and in fact it uses an
<code>io.TeeReader</code> to do exactly that.
</p>

<h3>Conclusion</h3>

<p>
With all of these optimizations, we’re now down to about 2.5 minutes for the
search query “arse”, and the architecture of the system actually got simpler to
reason about.
</p>

<p>
Most importantly, though, the optimizations don’t only play out for a single
query, but for many different queries. I’ve deployed the optimized version at
the 15th of December 2014, and you can see that the 99th, 95th and 90th
<a href="http://en.wikipedia.org/wiki/Percentile">percentile</a> latency
dropped significantly, i.e. there are a lot fewer spikes than before, and more
queries are processed faster, which is particularly obvious in the third graph
(which is capped at 2 minutes):
</p>


<img src="../../Bilder/screenshots/dcs-99th-2014-12-22.1x.png" srcset="../../Bilder/screenshots/dcs-99th-2014-12-22.2x.png" width="800" height="312">

<img src="../../Bilder/screenshots/dcs-95th-2014-12-22.1x.png" srcset="../../Bilder/screenshots/dcs-95th-2014-12-22.2x.png" width="800" height="312">

<img src="../../Bilder/screenshots/dcs-90th-2014-12-22.1x.png" srcset="../../Bilder/screenshots/dcs-90th-2014-12-22.2x.png" width="800" height="312">

