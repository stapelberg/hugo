---
layout: post
title:  "Code Coverage testing in C with gcov and lcov"
date:   2011-05-08 18:36:00
categories: Artikel
Aliases:
  - /Artikel/code_coverage_with_lcov
---


<p style="background-color: #c0c0c0">
This post is in english / Dieser Artikel ist auf Englisch, da er sich an die
internationale Entwicklergemeinschaft richtet.
</p>

<p>
While the <a href="http://i3wm.org/">i3 window manager</a> has a lot of
testcases, I never got around to actually doing code coverage tests. Now I took
the time to get it to work and want to describe the process so that others
don’t do the same mistakes I did.
</p>

<h2>Outline of the process</h2>
<ol>
<li>Compile your source code with <code>-fprofile-arcs -ftest-coverage</code>,
link against <code>-lgcov</code>. In addition to each <code>.o</code> file, you
will have a <code>.gcno</code> file.</li>
<li>Run your program and cleanly exit it! This will produce a
<code>.gcda</code> file for each source file.</li>
<li>Run <code>lcov --base-directory . --directory . --capture --output-file
i3.info</code> to generate an info file.</li>
<li>Run <code>genhtml -o /tmp/i3-coverage i3.info</code> to convert that info
file to HTML.</li>
</ol>

<h2>1: Changing the compilation flags</h2>

<p>
This step should be really straight-forward. Make sure the <code>CFLAGS</code>
include <code>-fprofile-arcs -ftest-coverage</code> and the <code>LDFLAGS</code>
include <code>-lgcov</code>:
</p>

<pre>
CFLAGS += -fprofile-arcs -ftest-coverage
LDFLAGS += -lgcov
</pre>

<h2>2: Run your program</h2>

<p>
Sounds easy, but be aware that you have to exit your program cleanly! Pressing
Ctrl-C to abort it lead to a situation where no <code>.gcda</code> files were
generated for me.
</p>

<h2>3: Run lcov (from CVS)</h2>

<p>
This one was tricky. At the time of writing, <code>lcov</code>’s most recent
release is version 1.9. This version has a bug (it uses Perl’s two-parameter
<code>open</code>) which leads to not opening the file
<code>&lt;built-in&gt;.gcov</code> correctly. Get the <a
href="http://sourceforge.net/projects/ltp/develop">most recent version from
CVS</a>, which includes <a
href="http://ltp.cvs.sourceforge.net/viewvc/ltp/utils/analysis/lcov/bin/geninfo?r1=1.90&r2=1.91&pathrev=MAIN">a
fix for this</a>.
</p>

<p>
Afterwards, run the following command:
</p>

<pre>
lcov --base-directory . --directory src --capture --output-file i3.info
</pre>

<p>
The <code>--base-directory</code> parameter makes sure that relative filenames
(like <code>src/render.c</code>) will be found.
</p>

<p>
Should you do multiple runs of your program, just repeat this command. If you
are done and want to start over with fresh values, run <code>lcov --directory .
--zerocounters</code>.
</p>

<h2>4: Run genhtml</h2>

<p>
The last step is to convert the <code>i3.info</code> file to a nice HTML report
with the following command:
</p>

<pre>
genhtml -o /tmp/i3-coverage/ i3.info
</pre>
