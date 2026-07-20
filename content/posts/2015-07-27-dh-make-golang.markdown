---
layout: post
date: 2015-07-27 08:50:00 +0200
title: "dh-make-golang: creating Debian packages from Go packages"
categories: Artikel
tags:
- debian
---
<p>
Recently, the <a href="https://pkg-go.alioth.debian.org/">pkg-go team</a> has
been quite busy, uploading dozens of Go library packages in order to be able to
package <a href="https://github.com/googlecloudplatform/gcsfuse">gcsfuse</a> (a
user-space file system for interacting with Google Cloud Storage) and <a
href="https://influxdb.com/">InfluxDB</a> (an open-source distributed time
series database).
</p>

<p>
Packaging Go library packages (!) is a fairly repetitive process, so before
starting my work on the dependencies for gcsfuse, I started writing a tool
called <a href="https://github.com/Debian/dh-make-golang">dh-make-golang</a>.
Just like dh-make itself, the goal is to automatically create (almost) an
entire Debian package.
</p>

<p>
As I worked my way through the dependencies of gcsfuse, I refined how the tool
works, and now I believe it’s good enough for a first release.
</p>

<p>
To demonstrate how the tool works, let’s assume we want to package the Go
library <a href="https://github.com/jacobsa/ratelimit">github.com/jacobsa/ratelimit</a>:
</p>

<pre style="background-color: black; color: white; padding: 0.1em; overflow-x: scroll">
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp</span> $ dh-make-golang github.com/jacobsa/ratelimit
2015/07/25 18:25:39 Downloading "github.com/jacobsa/ratelimit/..."
2015/07/25 18:25:53 Determining upstream version number
2015/07/25 18:25:53 Package version is "0.0~git20150723.0.2ca5e0c"
2015/07/25 18:25:53 Determining dependencies
2015/07/25 18:25:55 
2015/07/25 18:25:55 Packaging successfully created in /tmp/golang-github-jacobsa-ratelimit
2015/07/25 18:25:55 
2015/07/25 18:25:55 Resolve all TODOs in itp-golang-github-jacobsa-ratelimit.txt, then email it out:
2015/07/25 18:25:55     sendmail -t -f < itp-golang-github-jacobsa-ratelimit.txt
2015/07/25 18:25:55 
2015/07/25 18:25:55 Resolve all the TODOs in debian/, find them using:
2015/07/25 18:25:55     grep -r TODO debian
2015/07/25 18:25:55 
2015/07/25 18:25:55 To build the package, commit the packaging and use gbp buildpackage:
2015/07/25 18:25:55     git add debian && git commit -a -m 'Initial packaging'
2015/07/25 18:25:55     gbp buildpackage --git-pbuilder
2015/07/25 18:25:55 
2015/07/25 18:25:55 To create the packaging git repository on salsa, use:
2015/07/25 18:25:55     dh-make-golang create-salsa-project golang-github-jacobsa-ratelimit
2015/07/25 18:25:55 
2015/07/25 18:25:55 Once you are happy with your packaging, push it to alioth using:
2015/07/25 18:25:55     git remote set-url origin git@salsa.debian.org:go-team/packages/golang-github-jacobsa-ratelimit.git
2015/07/25 18:25:55     gbp push
</pre>

<p>
The ITP is often the most labor-intensive part of the packaging process,
because any number of auto-detected values might be wrong: the repository owner
might not be the “Upstream Author”, the repository might not have a short
description, the long description might need some adjustments or the license
might not be auto-detected.
</p>

<pre style="background-color: black; color: white; padding: 0.1em">
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp</span> $ cat itp-golang-github-jacobsa-ratelimit.txt
From: "Michael Stapelberg" &lt;stapelberg AT debian.org&gt;
To: submit@bugs.debian.org
Subject: ITP: golang-github-jacobsa-ratelimit -- Go package for rate limiting
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit

Package: wnpp
Severity: wishlist
Owner: Michael Stapelberg &lt;stapelberg AT debian.org&gt;

* Package name    : golang-github-jacobsa-ratelimit
  Version         : 0.0~git20150723.0.2ca5e0c-1
  Upstream Author : Aaron Jacobs
* URL             : https://github.com/jacobsa/ratelimit
* License         : Apache-2.0
  Programming Lang: Go
  Description     : Go package for rate limiting

 GoDoc (https://godoc.org/github.com/jacobsa/ratelimit)
 .
 This package contains code for dealing with rate limiting. See the
 reference (http://godoc.org/github.com/jacobsa/ratelimit) for more info.

TODO: perhaps reasoning
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp</span> $
</pre>

<p>
After filling in all the TODOs in the file, let’s mail it out and get a sense
of what else still needs to be done:
</p>

<pre style="background-color: black; color: white; padding: 0.1em">
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp</span> $ sendmail -t -f &lt; itp-golang-github-jacobsa-ratelimit.txt
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp</span> $ cd golang-github-jacobsa-ratelimit
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ grep -r TODO debian
debian/changelog:  * Initial release (Closes: TODO) 
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $
</pre>

<p>
After filling in these TODOs as well, let’s have a final look at what we’re
about to build:
</p>

<pre style="background-color: black; color: white; padding: 0.1em; overflow-x: scroll">
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ head -100 debian/**/*
==&gt; debian/changelog &lt;==                            
golang-github-jacobsa-ratelimit (0.0~git20150723.0.2ca5e0c-1) unstable; urgency=medium

  * Initial release (Closes: #793646)

 -- Michael Stapelberg &lt;stapelberg@debian.org&gt;  Sat, 25 Jul 2015 23:26:34 +0200

==&gt; debian/compat &lt;==
9

==&gt; debian/control &lt;==
Source: golang-github-jacobsa-ratelimit
Section: devel
Priority: extra
Maintainer: pkg-go &lt;pkg-go-maintainers@lists.alioth.debian.org&gt;
Uploaders: Michael Stapelberg &lt;stapelberg@debian.org&gt;
Build-Depends: debhelper (&gt;= 9),
               dh-golang,
               golang-go,
               golang-github-jacobsa-gcloud-dev,
               golang-github-jacobsa-oglematchers-dev,
               golang-github-jacobsa-ogletest-dev,
               golang-github-jacobsa-syncutil-dev,
               golang-golang-x-net-dev
Standards-Version: 3.9.6
Homepage: https://github.com/jacobsa/ratelimit
Vcs-Browser: http://anonscm.debian.org/gitweb/?p=pkg-go/packages/golang-github-jacobsa-ratelimit.git;a=summary
Vcs-Git: git://anonscm.debian.org/pkg-go/packages/golang-github-jacobsa-ratelimit.git

Package: golang-github-jacobsa-ratelimit-dev
Architecture: all
Depends: ${shlibs:Depends},
         ${misc:Depends},
         golang-go,
         golang-github-jacobsa-gcloud-dev,
         golang-github-jacobsa-oglematchers-dev,
         golang-github-jacobsa-ogletest-dev,
         golang-github-jacobsa-syncutil-dev,
         golang-golang-x-net-dev
Built-Using: ${misc:Built-Using}
Description: Go package for rate limiting
 This package contains code for dealing with rate limiting. See the
 reference (http://godoc.org/github.com/jacobsa/ratelimit) for more info.

==&gt; debian/copyright &lt;==
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ratelimit
Source: https://github.com/jacobsa/ratelimit

Files: *
Copyright: 2015 Aaron Jacobs
License: Apache-2.0

Files: debian/*
Copyright: 2015 Michael Stapelberg &lt;stapelberg@debian.org&gt;
License: Apache-2.0
Comment: Debian packaging is licensed under the same terms as upstream

License: Apache-2.0
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 .
 http://www.apache.org/licenses/LICENSE-2.0
 .
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 .
 On Debian systems, the complete text of the Apache version 2.0 license
 can be found in "/usr/share/common-licenses/Apache-2.0".

==&gt; debian/gbp.conf &lt;==
[DEFAULT]
pristine-tar = True

==&gt; debian/rules &lt;==
#!/usr/bin/make -f

export DH_GOPKG := github.com/jacobsa/ratelimit

%:
	dh $@ --buildsystem=golang --with=golang

==&gt; debian/source &lt;==
head: error reading ‘debian/source’: Is a directory

==&gt; debian/source/format &lt;==
3.0 (quilt)
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $
</pre>

<p>
Okay, then. Let’s give it a shot and see if it builds:
</p>

<pre style="background-color: black; color: white; padding: 0.1em; overflow-x: scroll">
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ git add debian &amp;&amp; git commit -a -m 'Initial packaging'
[master 48f4c25] Initial packaging                                                      
 7 files changed, 75 insertions(+)
 create mode 100644 debian/changelog
 create mode 100644 debian/compat
 create mode 100644 debian/control
 create mode 100644 debian/copyright
 create mode 100644 debian/gbp.conf
 create mode 100755 debian/rules
 create mode 100644 debian/source/format
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ gbp buildpackage --git-pbuilder
[…]
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ lintian ../golang-github-jacobsa-ratelimit_0.0\~git20150723.0.2ca5e0c-1_amd64.changes
I: golang-github-jacobsa-ratelimit source: debian-watch-file-is-missing
P: golang-github-jacobsa-ratelimit-dev: no-upstream-changelog
I: golang-github-jacobsa-ratelimit-dev: extended-description-is-probably-too-short
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $
</pre>

<p>
This package just built (as it should!), but occasionally one might need to disable a test and file an upstream bug about it. So, let’s push this package to pkg-go and upload it:
</p>

<pre style="background-color: black; color: white; padding: 0.1em; overflow-x: scroll">
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ ssh git.debian.org "/git/pkg-go/setup-repository golang-github-jacobsa-ratelimit 'Packaging for golang-github-jacobsa-ratelimit'"
Initialized empty shared Git repository in /srv/git.debian.org/git/pkg-go/packages/golang-github-jacobsa-ratelimit.git/
HEAD is now at ea6b1c5 add mrconfig for dh-make-golang
[master c5be5a1] add mrconfig for golang-github-jacobsa-ratelimit
 1 file changed, 3 insertions(+)
To /git/pkg-go/meta.git
   ea6b1c5..c5be5a1  master -&gt; master
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ git push git+ssh://git.debian.org/git/pkg-go/packages/golang-github-jacobsa-ratelimit.git --tags master pristine-tar upstream
Counting objects: 31, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (25/25), done.
Writing objects: 100% (31/31), 18.38 KiB | 0 bytes/s, done.
Total 31 (delta 2), reused 0 (delta 0)
To git+ssh://git.debian.org/git/pkg-go/packages/golang-github-jacobsa-ratelimit.git
 * [new branch]      master -&gt; master
 * [new branch]      pristine-tar -&gt; pristine-tar
 * [new branch]      upstream -&gt; upstream
 * [new tag]         upstream/0.0_git20150723.0.2ca5e0c -&gt; upstream/0.0_git20150723.0.2ca5e0c
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ cd ..
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp</span> $ debsign golang-github-jacobsa-ratelimit_0.0\~git20150723.0.2ca5e0c-1_amd64.changes
[…]
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp</span> $ dput golang-github-jacobsa-ratelimit_0.0\~git20150723.0.2ca5e0c-1_amd64.changes   
Uploading golang-github-jacobsa-ratelimit using ftp to ftp-master (host: ftp.upload.debian.org; directory: /pub/UploadQueue/)
[…]
Uploading golang-github-jacobsa-ratelimit_0.0~git20150723.0.2ca5e0c-1.dsc
Uploading golang-github-jacobsa-ratelimit_0.0~git20150723.0.2ca5e0c.orig.tar.bz2
Uploading golang-github-jacobsa-ratelimit_0.0~git20150723.0.2ca5e0c-1.debian.tar.xz
Uploading golang-github-jacobsa-ratelimit-dev_0.0~git20150723.0.2ca5e0c-1_all.deb
Uploading golang-github-jacobsa-ratelimit_0.0~git20150723.0.2ca5e0c-1_amd64.changes
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp</span> $ cd golang-github-jacobsa-ratelimit 
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ git tag debian/0.0_git20150723.0.2ca5e0c-1
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $ git push git+ssh://git.debian.org/git/pkg-go/packages/golang-github-jacobsa-ratelimit.git --tags master pristine-tar upstream
Total 0 (delta 0), reused 0 (delta 0)
To git+ssh://git.debian.org/git/pkg-go/packages/golang-github-jacobsa-ratelimit.git
 * [new tag]         debian/0.0_git20150723.0.2ca5e0c-1 -&gt; debian/0.0_git20150723.0.2ca5e0c-1
<span style="background-color: #04B5B8; color: black">midna</span> <span style="color: #8AE234">/tmp/golang-github-jacobsa-ratelimit</span> <span style="color: #04B5B8">master</span> $
</pre>

<p>
Thanks for reading this far, and I hope dh-make-golang makes your life a tiny
bit easier. As <a
href="https://packages.debian.org/sid/dh-make-golang">dh-make-golang just
entered Debian unstable</a>, you can install it using <code>apt-get install
dh-make-golang</code>. If you have any feedback, I’m eager to hear it.
</p>
