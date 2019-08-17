---
layout: post
date: 2019-08-17 18:36:00 +02:00
title: "distri: a Linux distribution to research fast package management"
categories: Artikel
tags:
- distri
- debian
---

Over the last year or so I have worked on a research linux distribution in my
spare time. It’s not a distribution for researchers (like [Scientific
Linux](https://en.wikipedia.org/wiki/Scientific_Linux)), but my personal
playground project to research linux distribution development, i.e. try out
fresh ideas.

This article focuses on the package format and its advantages, but there is
more to distri, which I will [cover in upcoming blog posts](#more-to-come).

### Motivation

I was a Debian Developer for the 7 years from 2012 to 2019, but using the
distribution often left me frustrated, ultimately [resulting in me winding down
my Debian work](/posts/2019-03-10-debian-winding-down/).

Frequently, I was noticing a large gap between the actual speed of an operation
(e.g. doing an update) and the possible speed based on back of the envelope
calculations. I wrote more about this in my blog post [“Package managers are
slow”](/posts/2019-08-17-linux-package-managers-are-slow/).

To me, this observation means that either there is potential to optimize the
package manager itself (e.g. `apt`), or what the system does is just too
complex. While I remember seeing some low-hanging fruit¹, through my work on
distri, I wanted to explore whether all the complexity we currently have in
Linux distributions such as Debian or Fedora is inherent to the problem space.

I have completed enough of the experiment to conclude that the complexity is not
inherent: I can build a Linux distribution for general-enough purposes which is
much less complex than existing ones.

① Those were low-hanging fruit from a user perspective. I’m not saying that
  fixing them is easy in the technical sense; I know too little about `apt`’s code
  base to make such a statement.

### Key idea: packages are images, not archives

One key idea is to switch from using archives to using **images** for package
contents. Common package managers such as {{< man name="dpkg" section="1" >}}
use {{< man name="tar" section="1" >}} archives with various compression
algorithms.

distri uses [SquashFS images](https://en.wikipedia.org/wiki/SquashFS), a
comparatively simple file system image format that I happen to be familiar with
from my work on the [gokrazy Raspberry Pi 3 Go platform](https://gokrazy.org).

This idea is not novel: [AppImage](https://en.wikipedia.org/wiki/AppImage) and
[snappy](https://en.wikipedia.org/wiki/Snappy_(package_manager)) also use
images, but only for individual, self-contained applications. distri however
uses images for distribution packages with dependencies. In particular, there is
no duplication of shared libraries in distri.

A nice side effect of using read-only image files is that applications are
immutable and can hence not be broken by accidental (or malicious!)
modification.


### Key idea: separate hierarchies

Package contents are made available under a fully-qualified path. E.g., all
files provided by package `zsh-amd64-5.6.2-3` are available under
`/ro/zsh-amd64-5.6.2-3`. The mountpoint `/ro` stands for read-only, which is
short yet descriptive.

Perhaps surprisingly, building software with custom `prefix` values of
e.g. `/ro/zsh-amd64-5.6.2-3` is widely supported, thanks to:

1. Linux distributions, which build software with `prefix` set to `/usr`,
   whereas FreeBSD (and the autotools default), which build with `prefix` set to
   `/usr/local`.

2. Enthusiast users in corporate or research environments, who install software
   into their home directories.

Because using a custom `prefix` is a common scenario, upstream awareness for
`prefix`-correctness is generally high, and the rarely required patch will be
quickly accepted.


### Key idea: exchange directories

Software packages often exchange data by placing or locating files in well-known
directories. Here are just a few examples:

* {{< man name="gcc" section="1" >}} locates the {{< man name="libusb" section="3" >}} headers via `/usr/include`
* {{< man name="man" section="1" >}} locates the {{< man name="nginx" section="1" >}} manpage via `/usr/share/man`.
* {{< man name="zsh" section="1" >}} locates executable programs via `PATH` components such as `/bin`

In distri, these locations are called **exchange directories** and are provided
via FUSE in `/ro`.

Exchange directories come in two different flavors:

1. global. The exchange directory, e.g. `/ro/share`, provides the union of the
   `share` sub directory of all packages in the package store.
\
Global exchange directories are largely used for compatibility, [see
below](#fhs-compat).

2. per-package. Useful for tight coupling: e.g. {{< man name="irssi" section="1"
   >}} does not provide any ABI guarantees, so plugins such as `irssi-robustirc`
   can declare that they want
   e.g. `/ro/irssi-amd64-1.1.1-1/out/lib/irssi/modules` to be a per-package
   exchange directory and contain files from their `lib/irssi/modules`.

{{< note >}}
Only a few exchange directories are also available in the package build
environment (as opposed to run-time).
{{< /note >}}

#### Search paths sometimes need to be fixed

Programs which use exchange directories sometimes use search paths to access
multiple exchange directories. In fact, the examples above were taken from {{<
man name="gcc" section="1" >}}’s `INCLUDEPATH`, {{< man name="man" section="1"
>}}’s `MANPATH` and {{< man name="zsh" section="1" >}}’s `PATH`. These are
prominent ones, but more examples are easy to find: {{< man name="zsh"
section="1" >}} loads completion functions from its `FPATH`.

Some search path values are derived from `--datadir=/ro/share` and require no
further attention, but others might derive from
e.g. `--prefix=/ro/zsh-amd64-5.6.2-3/out` and need to be pointed to an exchange
directory via a specific command line flag.

{{< note >}}

To create the illusion of a writable search path at package build-time,
<code>$DESTDIR/ro/share</code> and <code>$DESTDIR/ro/lib</code> are diverted to
<code>$DESTDIR/$PREFIX/share</code> and <code>$DESTDIR/$PREFIX/lib</code>,
respectively.

{{< /note >}}

#### FHS compatibility {#fhs-compat}

Global exchange directories are used to make distri provide enough of the
[Filesystem Hierarchy Standard
(FHS)](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard) that
third-party software largely just works. This includes a C development
environment.

I successfully ran a few programs from their binary packages such as Google
Chrome, Spotify, or Microsoft’s Visual Studio Code.

### Fast package manager

I previously wrote about how [Linux distribution package managers are too slow](/posts/2019-08-17-linux-package-managers-are-slow/).

distri’s package manager is extremely fast. Its main bottleneck is typically the network link, even at high speed links (I tested with a 100 Gbps link).

Its speed comes largely from an architecture which allows the package manager to
do less work. Specifically:

1. Package images can be added atomically to the package store, so we can safely
   skip {{< man name="fsync" section="2" >}}. Corruption will be cleaned up
   automatically, and durability is not important: if an interactive
   installation is interrupted, the user can just repeat it, as it will be fresh
   on their mind.

1. Because all packages are co-installable thanks to separate hierarchies, there
   are no conflicts at the package store level, and no dependency resolution (an
   optimization problem requiring [SAT
   solving](https://research.swtch.com/version-sat)) is required at all.
\
In exchange directories, we resolve conflicts by selecting the package with the
highest monotonically increasing distri revision number.

1. distri proves that we can build a useful Linux distribution [entirely without
   hooks and triggers](/posts/2019-07-20-hooks-and-triggers/). Not having to
   serialize hook execution allows us to download packages into the package
   store with maximum concurrency.

1. Because we are using images instead of archives, we do not need to unpack
   anything. This means installing a package is really just writing its package
   image and metadata to the package store. Sequential writes are typically the
   fastest kind of storage usage pattern.

Fast installation also make other use-cases more bearable, such as creating disk
images, be it for testing them in {{< man name="qemu" section="1" >}}, booting
them on real hardware from a USB drive, or for cloud providers such as Google
Cloud.
  
{{< note >}}
To saturate links above 1 Gbps, transfer packages without compression.
{{< /note >}}

### Fast package builder

Contrary to how distribution package builders are usually implemented, the
distri package builder does not actually install any packages into the build
environment.

Instead, distri makes available a filtered view of the package store (only
declared dependencies are available) at `/ro` in the build environment.

This means that even for large dependency trees, setting up a build environment
happens in a fraction of a second! Such a low latency really makes a difference
in how comfortable it is to iterate on distribution packages.

### Package stores

In distri, package images are installed from a remote **package store** into the
local system package store `/roimg`, which backs the `/ro` mount.

A package store is implemented as a directory of package images and their
associated metadata files.

You can easily make available a package store by using `distri export`.

To provide a mirror for your local network, you can periodically `distri update`
from the package store you want to mirror, and then `distri export` your local
copy. Special tooling (e.g. `debmirror` in Debian) is not required because
`distri install` is atomic (and `update` uses `install`).

Producing derivatives is easy: just add your own packages to a copy of the
package store.

The package store is intentionally kept simple to manage and distribute. Its
files could be exchanged via peer-to-peer file systems, or synchronized from an
offline medium.

### distri’s first release

distri works well enough to demonstrate the ideas explained above. I have
branched this state into [branch
`jackherer`](https://github.com/distr1/distri/tree/jackherer), distri’s first
release code name. This way, I can keep experimenting in the distri repository
without breaking your installation.

From the branch contents, our autobuilder creates:

1. [disk images](https://repo.distr1.org/distri/jackherer/img/), which…
  * can be [tested on real hardware](https://github.com/distr1/distri#run-distri-on-real-hardware)
  * can be [tested in qemu](https://github.com/distr1/distri#run-distri-in-qemu)
  * can be [tested in virtualbox](https://github.com/distr1/distri#run-distri-in-virtualbox)
  * can be [tested in docker](https://github.com/distr1/distri#run-distri-in-docker)
  * can be [tested on Google Cloud](https://github.com/distr1/distri#run-distri-on-google-cloud)

1. a [package repository](https://repo.distr1.org/distri/jackherer/pkg/). Installations can pick up new packages with
   `distri update`.

1. [documentation for the release](https://repo.distr1.org/distri/jackherer/docs/).
  * Definitely check out the [“Cool things to
    try”](https://github.com/distr1/distri#cool-things-to-try) README section.

The project website can be found at https://distr1.org. The website is just the
README for now, but we can improve that later.

The repository can be found at https://github.com/distr1/distri

### Project outlook

Right now, distri is mainly a vehicle for my spare-time Linux distribution
research. **I don’t recommend anyone use distri for anything but research,** and
there are no medium-term plans of that changing. At the very least, please
contact me before basing anything serious on distri so that we can talk about
limitations and expectations.

I expect the distri project to live for as long as I have blog posts to publish,
and we’ll see what happens afterwards. Note that this is a hobby for me: I will
continue to explore, at my own pace, parts that I find interesting.

My hope is that established distributions might get a useful idea or two from
distri.

### There’s more to come: subscribe to the distri feed {#more-to-come}

I don’t want to make this post too long, but there is much more!

Please subscribe to the following URL in your feed reader to get all posts about
distri:

https://michael.stapelberg.ch/posts/tags/distri/feed.xml

Next in my queue are articles about hermetic packages and good package
maintainer experience (including declarative packaging).

### Feedback or questions?

I’d love to discuss these ideas in case you’re interested!

Please send feedback to the [distri mailing
list](https://www.freelists.org/list/distri) so that everyone can participate!
