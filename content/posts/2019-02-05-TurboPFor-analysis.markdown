---
layout: post
title:  "TurboPFor: an analysis"
date:   2019-02-05 09:00:00 +01:00
categories: Artikel
tags:
- debian
tweet_url: "https://twitter.com/zekjur/status/1092699610718580736"
---

### Motivation

I have recently been looking into speeding up Debian Code Search. As a quick
reminder, search engines answer queries by consulting an inverted index: a map
from term to documents containing that term (called a “posting list”). See [the
Debian Code Search Bachelor
Thesis](https://codesearch.debian.net/research/bsc-thesis.pdf) (PDF) for a lot
more details.

Currently, Debian Code Search does not store positional information in its
index, i.e. the index can only reveal *that* a certain trigram is present in a
document, not *where* or *how often*.

From analyzing Debian Code Search queries, I knew that identifier queries (70%)
massively outnumber regular expression queries (30%). When processing identifier
queries, storing positional information in the index enables a significant
optimization: instead of identifying the possibly-matching documents and having
to read them all, we can determine matches from querying the index alone, no
document reads required.

This moves the bottleneck: having to read all possibly-matching documents
requires a lot of expensive random I/O, whereas having to decode long posting
lists requires a lot of cheap sequential I/O.

Of course, storing positions comes with a downside: the index is larger, and a
larger index takes more time to decode when querying.

Hence, I have been looking at various posting list compression/decoding
techniques, to figure out whether we could switch to a technique which would
retain (or improve upon!) current performance despite much longer posting lists
and produce a small enough index to fit on our current hardware.

### Literature

I started looking into this space because of Daniel Lemire’s [Stream
VByte](https://lemire.me/blog/2017/09/27/stream-vbyte-breaking-new-speed-records-for-integer-compression/)
post. As usual, Daniel’s work is well presented, easily digestible and
accompanied by not just one, but multiple implementations.

I also looked for scientific papers to learn about the state of the art and
classes of different approaches in general. The best I could find is
[Compression, SIMD, and Postings
Lists](https://dl.acm.org/citation.cfm?doid=2682862.2682870). If you don’t have
access to the paper, I hear that
[Sci-Hub](https://en.wikipedia.org/wiki/Sci-Hub) is helpful.

The paper is from 2014, and doesn’t include all algorithms. If you know of a
better paper, please let me know and I’ll include it here.

Eventually, I stumbled upon an algorithm/implementation called TurboPFor, which
the rest of the article tries to shine some light on.

### TurboPFor

If you’re wondering: PFor stands for Patched Frame Of Reference and describes a
family of algorithms. The principle is explained e.g. in [SIMD Compression and
the Intersection of Sorted Integers (PDF)](https://arxiv.org/pdf/1401.6399.pdf).

The [TurboPFor project’s README file](https://github.com/powturbo/TurboPFor)
claims that TurboPFor256 compresses with a rate of 5.04 bits per integer, and
can decode with 9400 MB/s on a single thread of an Intel i7-6700 CPU.

For Debian Code Search, we use unsigned integers of 32 bit (uint32), which
TurboPFor will compress into as few bits as required.

Dividing Debian Code Search’s file sizes by the total number of integers, I get
similar values, at least for the docid index section:

* 5.49 bits per integer for the docid index section
* 11.09 bits per integer for the positions index section

I can confirm the order of magnitude of the decoding speed, too. My benchmark
calls TurboPFor from Go via cgo, which introduces some overhead. To exclude disk
speed as a factor, data comes from the page cache. The benchmark sequentially
decodes all posting lists in the specified index, using as many threads as the
machine has cores¹:

* ≈1400 MB/s on a  1.1 GiB docid index section
* ≈4126 MB/s on a 15.0 GiB position index section

I think the numbers differ because the position index section contains larger
integers (requiring more bits). I repeated both benchmarks, capped to 1 GiB, and
decoding speeds still differed, so it is not just the size of the index.

Compared to Streaming VByte, a TurboPFor256 index comes in at just over half the
size, while still reaching 83% of Streaming VByte’s decoding speed. This seems
like a good trade-off for my use-case, so I decided to have a closer look at how
TurboPFor works.

① See [cmd/gp4-verify/verify.go](https://github.com/stapelberg/goturbopfor/blob/d7954fb81e66080941891dccc27407d8496f65d9/cmd/gp4-verify/verify.go) run on an Intel i9-9900K.

### Methodology

To confirm my understanding of the details of the format, I implemented a
pure-Go TurboPFor256 decoder. Note that it is intentionally *not optimized* as
its main goal is to use simple code to teach the TurboPFor256 on-disk format.

If you’re looking to use TurboPFor from Go, I recommend using cgo. cgo’s
function call overhead is about 51ns [as of Go
1.8](https://go-review.googlesource.com/c/go/+/30080), which will easily be
offset by TurboPFor’s carefully optimized, vectorized (SSE/AVX) code.

With that caveat out of the way, you can find my teaching implementation at
https://github.com/stapelberg/goturbopfor

I verified that it produces the same results as TurboPFor’s `p4ndec256v32`
function for all posting lists in the Debian Code Search index.

### On-disk format

Note that TurboPFor does not fully define an on-disk format on its own. When
encoding, it turns a list of integers into a byte stream:

```
size_t p4nenc256v32(uint32_t *in, size_t n, unsigned char *out);
```

When decoding, it decodes the byte stream into an array of integers, but needs
to know the number of integers in advance:

```
size_t p4ndec256v32(unsigned char *in, size_t n, uint32_t *out);
```

Hence, you’ll need to keep track of the number of integers and length of the
generated byte streams separately. When I talk about on-disk format, I’m
referring to the byte stream which TurboPFor returns.

The TurboPFor256 format uses blocks of 256 integers each, followed by a trailing
block — if required — which can contain fewer than 256 integers:

<img src="/turbopfor/ondisk.svgo.svg">

SIMD bitpacking is used for all blocks but the trailing block (which uses
regular bitpacking). This is not merely an implementation detail for decoding:
the on-disk structure is different for blocks which can be SIMD-decoded.

Each block starts with a 2 bit header, specifying the type of the block:

* 11: [constant](#block-constant)
* 00: [bitpacking](#block-bitpack)
* 10: [bitpacking with exceptions (bitmap)](#block-bitpackex)
* 01: [bitpacking with exceptions (variable byte)](#block-bitpackvb)

Each block type is explained in more detail in the following sections.

Note that none of the block types store the number of elements: you will always
need to know how many integers you need to decode. Also, you need to know in
advance how many bytes you need to feed to TurboPFor, so you will need some sort
of container format.

Further, TurboPFor automatically choses the best block type for each block.

#### Constant block {#block-constant}

A constant block (all integers of the block have the same value) consists of a
single value of a specified bit width ≤ 32. This value will be stored in each
output element for the block. E.g., after calling `decode(input, 3, output)`
with `input` being the constant block depicted below, output is `{0xB8912636,
0xB8912636, 0xB8912636}`.

<img src="/turbopfor/block-constant.svgo.svg">

The example shows the maximum number of bytes (5). Smaller integers will use
fewer bytes: e.g. an integer which can be represented in 3 bits will only use 2
bytes.

#### Bitpacking block {#block-bitpack}

A bitpacking block specifies a bit width ≤ 32, followed by a stream of
bits. Each value starts at the Least Significant Bit (LSB), i.e. the 3-bit
values 0 (`000b`) and 5 (`101b`) are encoded as `101000b`.

<img src="/turbopfor/block-bitpack.svgo.svg">

#### Bitpacking with exceptions (bitmap) block {#block-bitpackex}

The constant and bitpacking block types work well for integers which don’t
exceed a certain width, e.g. for a series of integers of width ≤ 5 bits.

For a series of integers where only a few values exceed an otherwise common
width (say, two values require 7 bits, the rest requires 5 bits), it makes sense
to cut the integers into two parts: value and exception.

In the example below, decoding the third integer `out2` (`000b`) requires
combination with exception `ex0` (`10110b`), resulting in `10110000b`.

The number of exceptions can be determined by summing the 1 bits in the bitmap
using the [popcount instruction](https://en.wikipedia.org/wiki/Hamming_weight).

<img src="/turbopfor/block-bitpackex.svgo.svg">

#### Bitpacking with exceptions (variable byte) {#block-bitpackvb}

When the exceptions are not uniform enough, it makes sense to switch from
bitpacking to a variable byte encoding:

<img src="/turbopfor/block-bitpackvb.svgo.svg">

### Decoding: variable byte

The variable byte encoding used by the TurboPFor format is similar to the one
[used by SQLite](https://sqlite.org/src4/doc/trunk/www/varint.wiki), which is
described, alongside other common variable byte encodings, at
[github.com/stoklund/varint](https://web.archive.org/web/20201119135834/https://github.com/stoklund/varint).

Instead of using individual bits for dispatching, this format classifies the
first byte (`b[0]`) into ranges:

* [0—176]: the value is `b[0]`
* [177—240]: a 14 bit value is in `b[0]` (6 high bits) and `b[1]` (8 low bits)
* [241—248]: a 19 bit value is in `b[0]` (3 high bits), `b[1]` and `b[2]` (16 low bits)
* [249—255]: a 32 bit value is in `b[1]`, `b[2]`, `b[3]` and possibly `b[4]`

Here is the space usage of different values:

* [0—176] are stored in 1 byte (as-is)
* [177—16560] are stored in 2 bytes, with the highest 6 bits added to 177
* [16561—540848] are stored in 3 bytes, with the highest 3 bits added to 241
* [540849—16777215] are stored in 4 bytes, with 0 added to 249
* [16777216—4294967295] are stored in 5 bytes, with 1 added to 249

An overflow marker will be used to signal that encoding the
values would be less space-efficient than simply copying them
(e.g. if all values require 5 bytes).

This format is very space-efficient: it packs 0-176 into a single byte, as
opposed to 0-128 (most others). At the same time, it can be decoded very
quickly, as only the first byte needs to be compared to decode a value (similar
to PrefixVarint).

### Decoding: bitpacking

#### Regular bitpacking

In regular (non-SIMD) bitpacking, integers are stored on disk one after the
other, padded to a full byte, as a byte is the smallest addressable unit when
reading data from disk. For example, if you bitpack only one 3 bit int, you will
end up with 5 bits of padding.

<img src="/turbopfor/bitpacking.svgo.svg">

#### SIMD bitpacking (256v32)

SIMD bitpacking works like regular bitpacking, but processes 8 uint32
little-endian values at the same time, leveraging the [AVX instruction
set](https://en.wikipedia.org/wiki/Advanced_Vector_Extensions). The following
illustration shows the order in which 3-bit integers are decoded from disk:

<img src="/turbopfor/bitpacking256v32.svgo.svg">

### In Practice

For a Debian Code Search index, 85% of posting lists are short enough to only
consist of a trailing block, i.e. no SIMD instructions can be used for decoding.

The distribution of block types looks as follows:

* 72% bitpacking with exceptions (bitmap)
* 19% bitpacking with exceptions (variable byte)
* 5% constant
* 4% bitpacking

Constant blocks are mostly used for posting lists with just one entry.

### Conclusion

The TurboPFor on-disk format is very flexible: with its 4 different kinds of
blocks, chances are high that a very efficient encoding will be used for most
integer series.

Of course, the flip side of covering so many cases is complexity: the format and
implementation take quite a bit of time to understand — hopefully this article
helps a little! For environments where the C TurboPFor implementation cannot be
used, smaller algorithms might be simpler to implement.

That said, if you can use the TurboPFor implementation, you will benefit from a
highly optimized SIMD code base, which will most likely be an improvement over
what you’re currently using.
