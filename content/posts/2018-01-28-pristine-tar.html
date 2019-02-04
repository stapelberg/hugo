---
layout: post
date: 2018-01-28 21:20:00 +0100
title: "pristine-tar considered harmful"
categories: Artikel
tags:
- debian
---
<p>
  If you want to follow along at home, clone this repository:
</p>

<pre>
% GBP_CONF_FILES=:debian/gbp.conf gbp clone https://anonscm.debian.org/git/pkg-go/packages/golang-github-go-macaron-inject.git
</pre>

<p>
  Now, in the <code>golang-github-go-macaron-inject</code> directory, I’m aware
  of three ways to obtain an orig tarball (please correct me if there are more):
</p>

<ol>
  <li>
    Run <code><a href="https://manpages.debian.org/stretch/git-buildpackage/gbp-buildpackage.1.en.html">gbp
    buildpackage</a></code>, creating an orig tarball from git
    (<code>upstream/0.0_git20160627.0.d8a0b86</code>)<br>
    The resulting sha1sum is <code>d085a04b7b35856be24f8cc4a9a6d9799cdb59b4</code>.
  </li>
  <li>
    Run <code><a href="https://manpages.debian.org/stretch/pristine-tar/pristine-tar.1.en.html">pristine-tar</a>
    checkout</code><br>
    The resulting sha1sum is <code>d51575c0b00db5fe2bbf8eea65bc7c4f767ee954</code>.
  </li>
  <li>
    Run <code><a href="https://manpages.debian.org/stretch/devscripts/origtargz.1.en.html">origtargz</a></code><br>
    The resulting sha1sum is <code>d51575c0b00db5fe2bbf8eea65bc7c4f767ee954</code>.
  </li>
</ol>

<p>
  Have a look at the
  archive’s <a href="https://deb.debian.org/debian/pool/main/g/golang-github-go-macaron-inject/golang-github-go-macaron-inject_0.0~git20160627.0.d8a0b86-2.dsc">golang-github-go-macaron-inject_0.0~git20160627.0.d8a0b86-2.dsc</a>,
  however: the file entry orig tarball reads:
</p>

<pre>
f5d5941c7b77e8941498910b64542f3db6daa3c2 7688 golang-github-go-macaron-inject_0.0~git20160627.0.d8a0b86.orig.tar.xz
</pre>

<p>
  So, why did we get a different tarball? Let’s go through the methods:
</p>

<ol>
  <li>
    The uploader must not have used <code>gbp buildpackage</code> to create
    their tarball. Perhaps they imported from a tarball created by
    dh-make-golang, or created manually, and then left that tarball in place
    (which is a perfectly fine, normal workflow).
  </li>

  <li>
    I’m not entirely sure why <code>pristine-tar</code> resulted in a different
    tarball than what’s in the archive. I think the most likely theory is that
    the uploader had to go back and modify the tarball, but forgot to update (or
    made a mistake while updating) the pristine-tar branch.
  </li>
  
  <li>
    <code>origtargz</code>, when it detects pristine-tar data, uses
    pristine-tar, hence the same tarball as ②.
  </li>
</ol>

<p>
  Had we not used pristine-tar for this repository at
  all, <code>origtargz</code> would have pulled the correct tarball from the
  archive.
</p>

<p>
  The above anecdote illustrates the fragility of the pristine-tar approach. In
  my experience from the pkg-go team, when the pristine-tar branch doesn’t
  contain outright incorrect data, it is often outdated. Even when everything is
  working correctly, a number of packagers are disgruntled about the extra
  work/mental complexity.
</p>

<p>
  In the pkg-go team, we have (independently of this specific anecdote)
  collectively decided to have the upstream branch track the upstream remote’s
  master (or similar) branch directly, and get rid of pristine-tar in our
  repositories. This should result in method ① and ③ working correctly.
</p>

<p>
  In conclusion, my recommendation for any repository is: don’t bother with
  pristine-tar. Instead, configure <code>origtargz</code> as a git-buildpackage
  postclone hook in your <code>~/.gbp.conf</code> to always work with archive
  orig tarballs:
</p>

<pre>
[clone]
# Ensure the correct orig tarball is present.
postclone=origtargz

[buildpackage]
# Pick up the orig tarballs created by the origtargz postclone hook.
tarball-dir = ..
</pre>
