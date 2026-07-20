---
layout: post
date: 2013-08-30 21:30:00 +0200
title: "How git performs when you throw all of Debian at it"
categories: Artikel
tags:
- debian
---
<p>
During DebConf, Asheesh presented the idea of using git instead of the file
system for storing the contents of Debian Code Search. The hope was that it
would lead to fewer disk seeks and less data due to gits delta-encoding. Maybe
the reduction would be big enough that enough data could be held in RAM to
allow for fast retrieval.
</p>

<p>
Joey Hess helped me out with a couple of details: he revealed that using
<code>git repack -a -d</code> will lead to a single packfile that optimally
contains HEAD, not caring about the history. Also, he showed me how to use
<code>git cat-file</code>. We did a small-scale experiment and the results were
promising. I told him I’ll do the experiment of just committing the entire
unpacked source mirror to git and promised to follow up with the results, so
here goes:
</p>

<pre>
stapelberg@couper ~/unpacked master $ time cat &lt;&lt;EOT | git cat-file --batch &gt;/dev/null
:linux_3.2.32-1/sound/pci/ice1712/aureon.c
:linux_3.2.32-1/sound/soc/codecs/sgtl5000.c
:linux_3.2.32-1/sound/pci/hda/patch_conexant.c
EOT
cat &lt;&lt;&lt;''  0,00s user 0,00s system 62% cpu 0,006 total
git cat-file --batch &gt; /dev/null  4,38s user 1,08s system 99% cpu 5,477 total

stapelberg@couper ~/unpacked master $ time cat linux_3.2.32-1/sound/pci/ice1712/aureon.c linux_3.2.32-1/sound/soc/codecs/sgtl5000.c linux_3.2.32-1/sound/pci/hda/patch_conexant.c &gt;/dev/null
cat linux_3.2.32-1/sound/pci/ice1712/aureon.c   &gt; /dev/null  0,00s user 0,00s system 69% cpu 0,006 total

stapelberg@couper ~/unpacked master $ time cat &lt;&lt;EOT | git cat-file --batch &gt;/dev/null
:i3-wm_4.6-1/libi3/font.c
EOT
cat &lt;&lt;&lt;':i3-wm_4.6-1/libi3/font.c'  0,00s user 0,00s system 51% cpu 0,008 total
git cat-file --batch &gt; /dev/null  4,30s user 1,18s system 99% cpu 5,533 total

stapelberg@couper ~/unpacked master $ time cat i3-wm_4.6-1/libi3/font.c &gt;/dev/null
cat i3-wm_4.6-1/libi3/font.c &gt; /dev/null  0,00s user 0,00s system 0% cpu 0,004 total
</pre>

<p>
Even after repeating those tests a couple of times to get a warm page cache,
the result stays the same: git takes about 5 seconds to resolve the deltas in a
large repository. Even if this was 5 seconds startup time and a very small
amount of additional time per file, it would not be acceptable for our use
case.
</p>

<p>
The conclusion is that git is clearly not suitable for this kind of usage,
which is not surprising after having heard a couple of times that git does not
scale :-). For the curious, the <code>.git/objects</code> directory is 29 GiB
for roughly 140 GiB of source code, so the delta encoding is quite impressive
in terms of saving space. However, keep in mind that the compressed (!) Debian
source archive is about 35 GiB, so the savings are not that huge.
</p>
