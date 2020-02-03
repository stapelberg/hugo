---
layout: post
title:  "One reason for SIGILL with Go (golang)"
date:   2012-11-07 17:50:00
categories: Artikel
Aliases:
  - /Artikel/sigill_golang
tags:
- golang
---


<p>
After launching <a href="http://codesearch.debian.net/">Debian Code Search</a>,
sometimes its index-backend processes would crash when presented with some
class of queries. The queries itself did not show an interesting pattern, and
in fact, it wasn’t their fault.
</p>

<p>
Looking at the system’s journal, I noticed that the processes were crashing
with SIGILL, the signal when an illegal instruction for the CPU is encountered:
</p>

<pre>
Nov 07 00:11:33 codesearch index-backend[10517]: SIGILL: illegal instruction
Nov 07 00:11:33 codesearch index-backend[10517]: PC=0x42558d
</pre>

<p>
Interestingly, on my workstation, I could not reproduce this issue.
</p>

<p>
Therefore, I fired up gdb and reproduced the problem. After gdb stopped due to
SIGILL, I examined the current instruction:
</p>

<pre>
gdb $ x/4i $pc
0x42558d <cPostingOr+509>:	vzeroupper 
0x425590 <cPostingOr+512>:	retq   
0x425591 <cPostingOr+513>:	nopl   0x0(%rax)
0x425598 <cPostingOr+520>:	cmp    %ebx,%r10d
</pre>

<p>
Some quick googling revealed that <code>vzeroupper</code> is an instruction
which is pretty new, but supported by Intel’s i7 and AMD’s Bulldozer CPUs. I am
using an AMD CPU in the server on which Debian Code Search is hosted, but why
would the Go compiler add such an instruction to the code in the first place?
</p>

<p>
Then it struck me: It’s GCC, invoked because I use cgo for a small part of
the code! To get the most performance out of my code when benchmarking, I had
setup the cflags like this:
</p>

<pre>
#cgo CFLAGS: -std=gnu99 -O3 -march=native
</pre>

<p>
…leading to GCC putting in instructions which are only available on my
workstation, but not on my server. The fix was to simply remove
<code>-march=native</code>.
</p>

<p>
Therefore: Be careful with optimizations (doh), especially when you are
compiling code on a different machine than you intend to run it on.
</p>
