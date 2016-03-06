---
layout: post
title:  "Docker on Travis for new tools and fast runs"
date:   2016-03-06 19:00:00
categories: Artikel
---

<p>
Like many other open source projects, the <a href="https://i3wm.org/">i3 window
manager</a> is using <a href="https://travis-ci.org/">Travis CI</a> for <a
href="https://en.wikipedia.org/wiki/Continuous_integration">continuous
integration (CI)</a>. In our specific case, we not only verify that every pull
request compiles and the test suite still passes, but we also ensure the code
is auto-formatted using <a
href="http://clang.llvm.org/docs/ClangFormat.html">clang-format</a>, does not
contain detectable spelling errors and does not accidentally use C functions
like <code>sprintf()</code> without error checking.
</p>

<p>
By offering their CI service for free, Travis provides a great service to the
open source community, and I’m very thankful for that. Automatically running
the test suite for contributions and displaying the results alongside the pull
request is a feature that I’ve long wanted, but would have never gotten around
to implementing in the home-grown code review system we used before moving to
GitHub.
</p>

<h3>Motivation (more recent build environment)</h3>

<p>
Nothing is perfect, though, and some aspects of Travis can make it hard to work
with. In particular, the build environment they provide is rather old: at the
time of writing, the latest you can get is <a
href="https://en.wikipedia.org/wiki/Ubuntu_(operating_system)#Releases">Ubuntu
Trusty</a>, which was released almost two years ago. I realize that Ubuntu
Trusty is the current Ubuntu Long-Term Support release, but we want to move a
bit quicker than being able to depend on new packages roughly once every two
years.
</p>

<p>
For quite a while, we had to make do with that old environment. As a
mitigation, in <a
href="https://github.com/i3/i3/blob/065ce6b8fcd3510033d81f5f3731a765e1324b91/.travis.yml">our
<code>.travis.yml</code></a> file, we added the <a
href="https://github.com/travis-ci/apt-source-whitelist">whitelisted
ubuntu-toolchain-r-test source</a> for newer versions of clang (notably also
clang-format) and GCC. For integrating lintian’s spell checking into our CI
infrastructure, we needed a newer lintian version, as the version in Ubuntu
Trusty doesn’t have an interface for external scripts to use. Trying to make
our <code>.travis.yml</code> file install a newer version of lintian (and only
lintian!) was really challenging. To get a rough idea, take a look at <a
href="https://github.com/i3/i3/blob/dd33cd36dd0d28f0b60fbc0366bb468c645e9e55/.travis.yml">our
<code>.travis.yml</code></a> before we upgraded to Ubuntu Trusty and were stuck
with Ubuntu Precise. Cherry-picking a newer lintian version into Trusty would
have been even more complicated.
</p>

<p>
With Travis <a
href="https://blog.travis-ci.com/2015-08-19-using-docker-on-travis-ci/">starting
to offer Docker in their build environment</a>, and by looking at Docker’s <a
href="https://docs.docker.com/opensource/project/set-up-dev-env/">contribution
process, which also makes heavy use of containers</a>, we were able to put
together a better solution:
</p>

<h3>Implementation</h3>

<p>
The basic idea is to build a Docker container based on Debian testing and then
run all build/test commands inside that container. Our <a
href="https://github.com/i3/i3/blob/fbfbdb8e124480bc90bbd6a8b59c1692c4ebd531/travis-build.Dockerfile">Dockerfile</a>
installs compilers, formatters and other development tools first, then installs
all build dependencies for i3 based on the <code>debian/control</code> file, so
that we don’t need to duplicate build dependencies for Travis and for Debian.
</p>

<p>
This solves the immediate issue nicely, but comes at a significant cost:
building a Docker container adds quite a bit of wall clock time to a Travis
run, and we want to give our contributors quick feedback. The solution to long
build times is caching: we can simply upload the Docker container to the <a
href="https://hub.docker.com/">Docker Hub</a> and make subsequent builds use
the cached version.
</p>

<p>
We decided to cache the container for a month, or until inputs to the build
environment (currently the <code>Dockerfile</code> and
<code>debian/control</code>) change. Technically, this is implemented by a
little shell script called <a
href="https://github.com/i3/i3/blob/fbfbdb8e124480bc90bbd6a8b59c1692c4ebd531/travis/ha.sh">ha.sh</a>
(get it? hash!) which prints the SHA-256 hash of the input files. This hash,
appended to the current month, is what we use as tag for the Docker container,
e.g. <code>2016-03-3d453fe1</code>.
</p>

<p>
See our <a
href="https://github.com/i3/i3/blob/42f5a6ce479968a8f95dd5a827524865094d6a5c/.travis.yml">.travis.yml</a>
for how to plug it all together.
</p>

<h3>Conclusion</h3>

<p>
We’ve been successfully using this setup for a bit over a month now. The
advantages over pure Travis are:
</p>

<ol>
<li>
Our build environment is more recent, so we do not depend on Travis when we
want to adopt tools that are only present in more recent versions of
Linux.
</li>
<li>
CI runs are faster: what used to take about 5 minutes now takes only 1-2
minutes.
</li>
<li>
As a nice side effect, contributors can now easily run the tests in the same
environment that we use on Travis.
</li>
</ol>

<p>
There is some potential for even quicker CI runs: currently, all the different
steps are run in sequence, but some of them could run in parallel.
Unfortunately, Travis currently doesn’t provide a nice way to specify the
dependency graph or to expose the different parts of a CI run in the pull
request itself.
</p>
