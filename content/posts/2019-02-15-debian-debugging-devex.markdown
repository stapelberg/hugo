---
layout: post
date: 2019-02-15
title: "Debugging experience in Debian"
categories: Artikel
tags:
- debian

---

Recently, a user reported that [they don’t see window titles in i3 when running
i3 on a Raspberry Pi with Debian](https://bugs.debian.org/918925).

I copied the latest [Raspberry Pi Debian
image](https://wiki.debian.org/RaspberryPi3) onto an SD card, booted it, and was
able to reproduce the issue.

Conceptually, at this point, I should be able to install and start `gdb`, set a
break point and step through the code.

### Enabling debug symbols in Debian

Debian, by default, strips debug symbols when building packages to conserve disk
space and network bandwidth. The motivation is very reasonable: most users will
never need the debug symbols.

Unfortunately, obtaining debug symbols when you do need them is unreasonably hard.

We begin by configuring an additional apt repository which contains
automatically generated debug packages:

```
raspi# cat >>/etc/apt/sources.list.d/debug.list <<'EOT'
deb http://deb.debian.org/debian-debug buster-debug main contrib non-free
EOT
raspi# apt update
```

Notably, not all Debian packages have debug packages. As [the DebugPackage
Debian Wiki page](https://wiki.debian.org/DebugPackage) explains,
`debhelper/9.20151219` started generating debug packages (ending in `-dbgsym`)
automatically. Packages which have not been updated might come with their own
debug packages (ending in `-dbg`) or might not preserve debug symbols at all!

Now that we **can** install debug packages, how do we know **which ones** we need?

### Finding debug symbol packages in Debian

For debugging i3, we obviously need at least the `i3-dbgsym` package, but i3
uses a number of other libraries through whose code we may need to step.

The `debian-goodies` package ships a tool called
[find-dbgsym-packages](https://manpages.debian.org/testing/debian-goodies/find-dbgsym-packages.1.en.html)
which prints the required packages to debug an executable, core dump or running
process:

```
raspi# apt install debian-goodies
raspi# apt install $(find-dbgsym-packages $(which i3))
```

Now we should have symbol names and line number information available in
`gdb`. But for effectively stepping through the program, access to the source
code is required.

### Obtaining source code in Debian

Naively, one would assume that `apt source` should be sufficient for obtaining
the source code of any Debian package. However, `apt source` defaults to the
package candidate version, not the version you have installed on your
system.

I have addressed this issue with the
[`pk4`](https://manpages.debian.org/testing/pk4/pk4.1.en.html) tool, which
defaults to the installed version.

Before we can extract any sources, we need to configure yet another apt
repository:

```
raspi# cat >>/etc/apt/sources.list.d/source.list <<'EOT'
deb-src http://deb.debian.org/debian buster main contrib non-free
EOT
raspi# apt update
```

Regardless of whether you use `apt source` or `pk4`, one remaining problem is
the directory mismatch: the debug symbols contain a certain path, and that path
is typically not where you extracted your sources to. While debugging, you will
need to tell `gdb` about the location of the sources. This is tricky when you
debug a call across different source packages:

```
(gdb) pwd
Working directory /usr/src/i3.
(gdb) list main
229     * the main loop. */
230     ev_unref(main_loop);
231   }
232 }
233
234 int main(int argc, char *argv[]) {
235  /* Keep a symbol pointing to the I3_VERSION string constant so that
236   * we have it in gdb backtraces. */
237  static const char *_i3_version __attribute__((used)) = I3_VERSION;
238  char *override_configpath = NULL;
(gdb) list xcb_connect
484	../../src/xcb_util.c: No such file or directory.
```

See [Specifying Source
Directories](https://sourceware.org/gdb/onlinedocs/gdb/Source-Path.html) in the
gdb manual for the `dir` command which allows you to add multiple directories to
the source path. This is pretty tedious, though, and does not work for all
programs.

### Positive example: Fedora

While Fedora conceptually shares all the same steps, the experience on Fedora is
so much better: when you run `gdb /usr/bin/i3`, it will tell you what the next
step is:

```
# gdb /usr/bin/i3
[…]
Reading symbols from /usr/bin/i3...(no debugging symbols found)...done.
Missing separate debuginfos, use: dnf debuginfo-install i3-4.16-1.fc28.x86_64
```

Watch what happens when we run the suggested command:
```
# dnf debuginfo-install i3-4.16-1.fc28.x86_64
enabling updates-debuginfo repository
enabling fedora-debuginfo repository
[…]
Installed:
  i3-debuginfo.x86_64 4.16-1.fc28
  i3-debugsource.x86_64 4.16-1.fc28
Complete!
```

A single command understood our intent, enabled the required repositories and
installed the required packages, both for debug symbols and source code (stored
in e.g. `/usr/src/debug/i3-4.16-1.fc28.x86_64`). Unfortunately, `gdb` doesn’t
seem to locate the sources, which seems like a bug to me.

One downside of Fedora’s approach is that `gdb` will only print all required
dependencies once you actually run the program, so you may need to run multiple
`dnf` commands.

### In an ideal world

Ideally, none of the manual steps described above would be necessary. It seems
absurd to me that so much knowledge is required to efficiently debug programs in
Debian. Case in point: I only learnt about `find-dbgsym-packages` a few days ago
when talking to one of its contributors.

Installing `gdb` should be all that a user needs to do. Debug symbols and
sources can be transparently provided through a lazy-loading FUSE file
system. If our build/packaging infrastructure assured predictable paths and
automated debug symbol extraction, we could have transparent, quick and reliable
debugging of all programs within Debian.

NixOS’s dwarffs is an implementation of this idea:
https://github.com/edolstra/dwarffs

### Conclusion

While I agree with the removal of debug symbols as a general optimization, I
think every Linux distribution should strive to provide an entirely transparent
debugging experience: you should not even have to know that debug symbols are
not present by default. Debian really falls short in this regard.

Getting Debian to a fully transparent debugging experience requires a lot of
technical work and a lot of social convincing. In my experience,
programmatically working with the Debian archive and packages is tricky, and
ensuring that *all* packages in a Debian release have debug packages (let alone
predictable paths) seems entirely unachievable due to the fragmentation of
packaging infrastructure and holdouts blocking any progress.

My go-to example is [rsync’s
debian/rules](https://sources.debian.org/src/rsync/3.1.3-5/debian/rules/), which
intentionally (!) still has not adopted debhelper. It is not a surprise that
there are no debug symbols for `rsync` in Debian.
