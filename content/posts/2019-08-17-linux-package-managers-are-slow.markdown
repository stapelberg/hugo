---
layout: post
title:  "Linux package managers are slow"
date:   2019-08-17 18:27:00 +02:00
categories: Artikel
tags:
- distri
- debian
summary: "I measured how long the most popular Linux distribution’s package manager take to install small and large packages."
---

{{< note >}}
**Pending feedback:** [Allan McRae pointed
out](http://allanmcrae.com/2020/10/distri-comparing-apples-and-oranges/) that I
should be more precise with my terminology: strictly speaking, *distributions*
are slow, and package managers are only part of the puzzle.

I’ll try to be clearer in future revisions/posts.
{{< /note >}}

{{< note >}}

**Pending feedback:** For a more accurate picture, [it would be good to take the
network out of the
picture](https://twitter.com/mueslix/status/1311581199723368448), or at least
measure and report network speed separately. Ideas/tips for an easy way very
welcome!

{{< /note >}}

I measured how long the most popular Linux distribution’s package manager take
to install small and large packages (the
[`ack(1p)`](https://manpages.debian.org/ack.1p) source code search Perl script
and [qemu](https://en.wikipedia.org/wiki/QEMU), respectively).

Where required, my measurements include metadata updates such as transferring an
up-to-date package list. For me, requiring a metadata update is the more common
case, particularly on live systems or within Docker containers.

All measurements were taken on an `Intel(R) Core(TM) i9-9900K CPU @ 3.60GHz`
running Docker 1.13.1 on Linux 4.19, backed by a Samsung 970 Pro NVMe drive
boasting many hundreds of MB/s write performance. The machine is located in
Zürich and connected to the Internet with a 1 Gigabit fiber connection, so the
expected top download speed is ≈115 MB/s.

See [Appendix C](#appendix-c) for details on the measurement method and command
outputs.

### Measurements

Keep in mind that these are one-time measurements. They should be indicative of
actual performance, but your experience may vary.

#### ack (small Perl program)

distribution | package manager | data   | wall-clock time | rate
-------------|-----------------|--------|-----------------|-----
Fedora       | dnf             | 84 MB  | 25s             | 3.4 MB/s
NixOS        | Nix             | 15 MB  | 7s              | 2.3 MB/s
Debian       | apt             | 16 MB  | 3s              | 4.9 MB/s
Arch Linux   | pacman          | 25 MB  | 1s              | 18.4 MB/s
Alpine       | apk             | 10 MB  | 1s              | 11.9 MB/s

#### qemu (large C program)

distribution | package manager | data   | wall-clock time | rate
-------------|-----------------|--------|-----------------|-----
Fedora       | dnf             | 350 MB | 56s             | 6.25 MB/s
Debian       | apt             | 256 MB | 39s             | 6.5 MB/s
Arch Linux   | pacman          | 128 MB | 10s             | 12.1 MB/s
NixOS        | Nix             | 251 MB | 36s             | 6.8 MB/s
Alpine       | apk             | 34 MB  | 1.8s            | 18.6 MB/s

(Looking for older measurements? See [Appendix B (2019)](#appendix-b) or [Appendix C (2020)](#appendix-c)).

The difference between the slowest and fastest package managers is 30x!

How can Alpine’s apk and Arch Linux’s pacman be an order of magnitude faster
than the rest? They are doing a lot less than the others, and more efficiently,
too.

#### Pain point: too much metadata

For example, Fedora transfers a lot more data than others because its main
package list is 60 MB (compressed!) alone. Compare that with Alpine’s 734 KB
`APKINDEX.tar.gz`.

Of course the extra metadata which Fedora provides helps some use case,
otherwise they hopefully would have removed it altogether. The amount of
metadata seems excessive for the use case of installing a single package, which
I consider the main use-case of an interactive package manager.

I expect any modern Linux distribution to **only transfer absolutely required
data** to complete my task.

#### Pain point: no concurrency

Because they need to sequence executing arbitrary package maintainer-provided
code (hooks and triggers), all tested package managers need to install packages
sequentially (one after the other) instead of concurrently (all at the same
time).

In my blog post [“Can we do without hooks and
triggers?”](/posts/2019-07-20-hooks-and-triggers/), I outline that hooks and
triggers are not strictly necessary to build a working Linux distribution.

### Thought experiment: further speed-ups

Strictly speaking, the only required feature of a package manager is to make
available the package contents so that the package can be used: a program can be
started, a kernel module can be loaded, etc.

By only implementing what’s needed for this feature, and nothing more, a package
manager could likely beat `apk`’s performance. It could, for example:

* skip archive extraction by mounting file system images (like AppImage or snappy)
* use compression which is light on CPU, as networks are fast (like `apk`)
* skip fsync when it is safe to do so, i.e.:
  * package installations don’t modify system state
  * atomic package installation (e.g. an append-only package store)
  * automatically clean up the package store after crashes

### Current landscape {#current-landscape}

Here’s a table outlining how the various package managers listed on Wikipedia’s
[list of software package management
systems](https://en.wikipedia.org/wiki/List_of_software_package_management_systems#Linux)
fare:

name | scope | package file format | hooks/triggers
-----|-------|---------------------|------------------
AppImage | apps | image: ISO9660, SquashFS | no
[snappy](https://snapcraft.io/) | apps | image: SquashFS | yes: [hooks](https://docs.snapcraft.io/build-snaps/hooks)
FlatPak | apps | archive: [OSTree](https://ostree.readthedocs.io/en/latest/) | no
0install | apps | archive: tar.bz2 | no
nix, guix  | distro | archive: nar.{bz2,xz} | [activation script](https://github.com/NixOS/nixos/blob/master/modules/system/activation/activation-script.nix)
dpkg | distro | archive: tar.{gz,xz,bz2} in ar(1) | yes
rpm  | distro |archive: cpio.{bz2,lz,xz} | [scriptlets](https://fedoraproject.org/wiki/Packaging:Scriptlets)
pacman | distro | archive: tar.xz | [install](https://wiki.archlinux.org/index.php/PKGBUILD#install)
slackware | distro | archive: tar.{gz,xz} | yes: doinst.sh
apk | distro | archive: tar.gz | yes: .post-install
Entropy | distro | archive: tar.bz2          | yes
ipkg, opkg | distro | archive: tar{,.gz} | yes

### Conclusion

As per the [current landscape](#current-landscape), there is no
distribution-scoped package manager which uses images and leaves out hooks and
triggers, not even in smaller Linux distributions.

I think that space is really interesting, as it uses a minimal design to achieve
significant real-world speed-ups.

I have explored this idea in much more detail, and am happy to talk more about
it in my post “Introducing the distri research linux distribution".

### Appendix A: related work

There are a couple of recent developments going into the same direction:

* [“Revisiting How We Put Together Linux Systems”](http://0pointer.net/blog/revisiting-how-we-put-together-linux-systems.html) describes mounting app bundles
* [Android Q uses ext4 loopback images](https://android.googlesource.com/platform/system/apex/+/refs/heads/master/docs/README.md)
* The Haiku Operating System’s package manager [Haiku
  Depot](https://en.wikipedia.org/wiki/Haiku_Depot) uses images

### Appendix D: measurement details (2021) {#appendix-c}

#### ack

You can expand each of these:

<details>
<summary>
Fedora’s dnf takes almost 25 seconds to fetch and unpack 84 MB.
</summary>

```
% docker run --security-opt=seccomp:unconfined -t -i fedora /bin/bash
[root@62d3cae2e2f9 /]# time dnf install -y ack
Fedora 35 - x86_64                         25 MB/s |  61 MB
Fedora 35 openh264 (From Cisco) - x86_64  3.5 kB/s | 2.5 kB
Fedora Modular 35 - x86_64                5.0 MB/s | 2.6 MB
Fedora 35 - x86_64 - Updates              6.0 MB/s | 9.3 MB
Fedora Modular 35 - x86_64 - Updates      4.1 MB/s | 3.3 MB
Dependencies resolved.
[…]
real	0m24.882s
user	0m17.377s
sys	0m0.835s
```

</details>

<details>
<summary>
NixOS’s Nix takes a little under 7s to fetch and unpack 15 MB.
</summary>

```
% docker run -t -i nixos/nix
39e9186422ba:/# time sh -c 'nix-channel --update && nix-env -iA nixpkgs.ack'
unpacking channels...
created 1 symlinks in user environment
installing 'perl5.34.0-ack-3.5.0'
these paths will be fetched (15.78 MiB download, 86.82 MiB unpacked):
  /nix/store/11xpmmwy95396nkhih3qc3814lqhqb8f-libunistring-0.9.10
  /nix/store/1h18nl3gisw89znbzbmnxhd7jk20xlff-perl5.34.0-File-Next-1.18
  /nix/store/1mpxs3109cjrbhmi3q1vmvc0djz102pl-libidn2-2.3.2
  /nix/store/jr35z7n8jbv9q89my50vhyndqd3y541i-attr-2.5.1
  /nix/store/krc4xirbvjnff8m62snqdbayg46z5l5b-acl-2.3.1
  /nix/store/mij848h2x5wiqkwhg027byvmf9x3gx7y-glibc-2.33-50
  /nix/store/wq38iqzdh40dzfsndb927kh7y5bqh457-perl5.34.0-ack-3.5.0-man
  /nix/store/xyn0240zrpprnspg3n0fi8c8aw5bq0mr-coreutils-8.32
  /nix/store/y8r9ymbz59yjm1bwr3fdvd23jvcb2bzj-perl5.34.0-ack-3.5.0
  /nix/store/ypr273yvmr07n5n1w1gbcqnhpw7lbbvz-perl-5.34.0
copying path '/nix/store/wq38iqzdh40dzfsndb927kh7y5bqh457-perl5.34.0-ack-3.5.0-man' from 'https://cache.nixos.org'...
copying path '/nix/store/11xpmmwy95396nkhih3qc3814lqhqb8f-libunistring-0.9.10' from 'https://cache.nixos.org'...
copying path '/nix/store/1h18nl3gisw89znbzbmnxhd7jk20xlff-perl5.34.0-File-Next-1.18' from 'https://cache.nixos.org'...
copying path '/nix/store/1mpxs3109cjrbhmi3q1vmvc0djz102pl-libidn2-2.3.2' from 'https://cache.nixos.org'...
copying path '/nix/store/mij848h2x5wiqkwhg027byvmf9x3gx7y-glibc-2.33-50' from 'https://cache.nixos.org'...
copying path '/nix/store/jr35z7n8jbv9q89my50vhyndqd3y541i-attr-2.5.1' from 'https://cache.nixos.org'...
copying path '/nix/store/krc4xirbvjnff8m62snqdbayg46z5l5b-acl-2.3.1' from 'https://cache.nixos.org'...
copying path '/nix/store/xyn0240zrpprnspg3n0fi8c8aw5bq0mr-coreutils-8.32' from 'https://cache.nixos.org'...
copying path '/nix/store/ypr273yvmr07n5n1w1gbcqnhpw7lbbvz-perl-5.34.0' from 'https://cache.nixos.org'...
copying path '/nix/store/y8r9ymbz59yjm1bwr3fdvd23jvcb2bzj-perl5.34.0-ack-3.5.0' from 'https://cache.nixos.org'...
building '/nix/store/pwlxhy7kry56z6593rh397fc49x5avlw-user-environment.drv'...
created 49 symlinks in user environment
real	0m 6.82s
user	0m 3.47s
sys	0m 2.11s
```

</details>

<details>
<summary>
Debian’s apt takes about 3 seconds to fetch and unpack 16 MB.
</summary>

```
% docker run -t -i debian:sid
root@40a3899b1f2f:/# time (apt update && apt install -y ack-grep)
Get:1 http://deb.debian.org/debian sid InRelease [165 kB]
Get:2 http://deb.debian.org/debian sid/main amd64 Packages [8800 kB]
Fetched 8965 kB in 1s (9495 kB/s)
[…]
The following NEW packages will be installed:
  ack libfile-next-perl libgdbm-compat4 libgdbm6 libperl5.32 netbase perl perl-modules-5.32
0 upgraded, 8 newly installed, 0 to remove and 24 not upgraded.
Need to get 7479 kB of archives.
After this operation, 47.7 MB of additional disk space will be used.
[…]
real	0m3.260s
user	0m2.463s
sys	0m0.352s
```

</details>

<details>
<summary>
Arch Linux’s pacman takes a little over 1s to fetch and unpack 25 MB.
</summary>

```
% docker run -t -i archlinux:base
[root@9f6672688a64 /]# time (pacman -Sy && pacman -S --noconfirm ack)
:: Synchronizing package databases...
 core                                                                                              138.8 KiB  1542 KiB/s
 extra                                                                                            1569.8 KiB  26.9 MiB/s
 community                                                                                           5.8 MiB  92.2 MiB/s
resolving dependencies...
looking for conflicting packages...

Packages (5) db-5.3.28-5  gdbm-1.22-1  perl-5.34.0-2  perl-file-next-1.18-3  ack-3.5.0-2

Total Download Size:   16.77 MiB
Total Installed Size:  66.21 MiB
[…]
real	0m1.403s
user	0m0.484s
sys	0m0.211s
```

</details>

<details>
<summary>
Alpine’s apk takes a little under 1 second to fetch and unpack 10 MB.
</summary>

```
% docker run -t -i alpine
# time apk add ack
fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/community/x86_64/APKINDEX.tar.gz
(1/4) Installing libbz2 (1.0.8-r1)
(2/4) Installing perl (5.32.1-r0)
(3/4) Installing perl-file-next (1.18-r2)
(4/4) Installing ack (3.5.0-r1)
Executing busybox-1.33.1-r3.trigger
OK: 43 MiB in 18 packages
real	0m 0.76s
user	0m 0.27s
sys	0m 0.09s
```

</details>

#### qemu

You can expand each of these:

<details>
<summary>
Fedora’s dnf takes about 1 minute to fetch and unpack 350 MB.
</summary>

```
% docker run -t -i fedora /bin/bash
[root@6a52ecfc3afa /]# time dnf install -y qemu
Fedora 35 - x86_64                           15 MB/s |  61 MB
Fedora 35 openh264 (From Cisco) - x86_64    3.0 kB/s | 2.5 kB
Fedora Modular 35 - x86_64                  5.2 MB/s | 2.6 MB
Fedora 35 - x86_64 - Updates                6.6 MB/s | 9.3 MB
Fedora Modular 35 - x86_64 - Updates        2.2 MB/s | 3.3 MB
Dependencies resolved.
[…]

Total download size: 274 M
Downloading Packages:
[…]

real	0m56.031s
user	0m31.275s
sys	0m3.868s
```

</details>

<details>
<summary>
NixOS’s Nix takes almost 36s to fetch and unpack 230 MB.
</summary>

```
% docker run -t -i nixos/nix
83971cf79f7e:/# time sh -c 'nix-channel --update && nix-env -iA nixpkgs.qemu'
unpacking channels...
created 1 symlinks in user environment
installing 'qemu-6.1.0'
these paths will be fetched (230.72 MiB download, 1424.84 MiB unpacked):
[…]
real	0m 36.55s
user	0m 19.83s
sys	0m 3.34s
```

</details>

<details>
<summary>
Debian’s apt takes almost 39 seconds to fetch and unpack 256 MB.
</summary>

```
% docker run -t -i debian:sid
root@b7cc25a927ab:/# time (apt update && apt install -y qemu-system-x86)
Get:1 http://deb.debian.org/debian sid InRelease [146 kB]
Get:2 http://deb.debian.org/debian sid/main amd64 Packages [8400 kB]
Fetched 8965 kB in 1s (9048 kB/s)
[…]
Fetched 247 MB in 4s (64.9 MB/s)
[…]
real	0m38.875s
user	0m21.282s
sys	0m5.298s
```

</details>

<details>
<summary>
Arch Linux’s pacman takes about 10s to fetch and unpack 128 MB.
</summary>

```
% docker run -t -i archlinux:base
[root@58c78bda08e8 /]# time (pacman -Sy && pacman -S --noconfirm qemu)
:: Synchronizing package databases...
 core                                                                                              138.7 KiB  1541 KiB/s
 extra                                                                                            1569.8 KiB  35.7 MiB/s
 community                                                                                           5.8 MiB  92.2 MiB/s
[…]
Total Download Size:   118.97 MiB
Total Installed Size:  586.68 MiB
[…]
real	0m10.542s
user	0m3.092s
sys	0m1.569s
```

</details>

<details>
<summary>
Alpine’s apk takes only about 1.8 seconds to fetch and unpack 26 MB.
</summary>

```
% docker run -t -i alpine
/ # time apk add qemu-system-x86_64
fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/community/x86_64/APKINDEX.tar.gz
[…]
OK: 281 MiB in 66 packages
real	0m 1.83s
user	0m 0.77s
sys	0m 0.24s
```

</details>

### Appendix C: measurement details (2020) {#appendix-c}

#### ack

You can expand each of these:

<details>
<summary>
Fedora’s dnf takes almost 33 seconds to fetch and unpack 114 MB.
</summary>

```
% docker run -t -i fedora /bin/bash
[root@62d3cae2e2f9 /]# time dnf install -y ack
Fedora 32 openh264 (From Cisco) - x86_64     1.9 kB/s | 2.5 kB     00:01
Fedora Modular 32 - x86_64                   6.8 MB/s | 4.9 MB     00:00
Fedora Modular 32 - x86_64 - Updates         5.6 MB/s | 3.7 MB     00:00
Fedora 32 - x86_64 - Updates                 9.9 MB/s |  23 MB     00:02
Fedora 32 - x86_64                            39 MB/s |  70 MB     00:01
[…]
real	0m32.898s
user	0m25.121s
sys	0m1.408s
```

</details>

<details>
<summary>
NixOS’s Nix takes a little over 5s to fetch and unpack 15 MB.
</summary>

```
% docker run -t -i nixos/nix
39e9186422ba:/# time sh -c 'nix-channel --update && nix-env -iA nixpkgs.ack'
unpacking channels...
created 1 symlinks in user environment
installing 'perl5.32.0-ack-3.3.1'
these paths will be fetched (15.55 MiB download, 85.51 MiB unpacked):
  /nix/store/34l8jdg76kmwl1nbbq84r2gka0kw6rc8-perl5.32.0-ack-3.3.1-man
  /nix/store/9df65igwjmf2wbw0gbrrgair6piqjgmi-glibc-2.31
  /nix/store/9fd4pjaxpjyyxvvmxy43y392l7yvcwy1-perl5.32.0-File-Next-1.18
  /nix/store/czc3c1apx55s37qx4vadqhn3fhikchxi-libunistring-0.9.10
  /nix/store/dj6n505iqrk7srn96a27jfp3i0zgwa1l-acl-2.2.53
  /nix/store/ifayp0kvijq0n4x0bv51iqrb0yzyz77g-perl-5.32.0
  /nix/store/w9wc0d31p4z93cbgxijws03j5s2c4gyf-coreutils-8.31
  /nix/store/xim9l8hym4iga6d4azam4m0k0p1nw2rm-libidn2-2.3.0
  /nix/store/y7i47qjmf10i1ngpnsavv88zjagypycd-attr-2.4.48
  /nix/store/z45mp61h51ksxz28gds5110rf3wmqpdc-perl5.32.0-ack-3.3.1
copying path '/nix/store/34l8jdg76kmwl1nbbq84r2gka0kw6rc8-perl5.32.0-ack-3.3.1-man' from 'https://cache.nixos.org'...
copying path '/nix/store/czc3c1apx55s37qx4vadqhn3fhikchxi-libunistring-0.9.10' from 'https://cache.nixos.org'...
copying path '/nix/store/9fd4pjaxpjyyxvvmxy43y392l7yvcwy1-perl5.32.0-File-Next-1.18' from 'https://cache.nixos.org'...
copying path '/nix/store/xim9l8hym4iga6d4azam4m0k0p1nw2rm-libidn2-2.3.0' from 'https://cache.nixos.org'...
copying path '/nix/store/9df65igwjmf2wbw0gbrrgair6piqjgmi-glibc-2.31' from 'https://cache.nixos.org'...
copying path '/nix/store/y7i47qjmf10i1ngpnsavv88zjagypycd-attr-2.4.48' from 'https://cache.nixos.org'...
copying path '/nix/store/dj6n505iqrk7srn96a27jfp3i0zgwa1l-acl-2.2.53' from 'https://cache.nixos.org'...
copying path '/nix/store/w9wc0d31p4z93cbgxijws03j5s2c4gyf-coreutils-8.31' from 'https://cache.nixos.org'...
copying path '/nix/store/ifayp0kvijq0n4x0bv51iqrb0yzyz77g-perl-5.32.0' from 'https://cache.nixos.org'...
copying path '/nix/store/z45mp61h51ksxz28gds5110rf3wmqpdc-perl5.32.0-ack-3.3.1' from 'https://cache.nixos.org'...
building '/nix/store/m0rl62grplq7w7k3zqhlcz2hs99y332l-user-environment.drv'...
created 49 symlinks in user environment
real	0m 5.60s
user	0m 3.21s
sys	0m 1.66s
```

</details>

<details>
<summary>
Debian’s apt takes almost 10 seconds to fetch and unpack 16 MB.
</summary>

```
% docker run -t -i debian:sid
root@1996bb94a2d1:/# time (apt update && apt install -y ack-grep)
Get:1 http://deb.debian.org/debian sid InRelease [146 kB]
Get:2 http://deb.debian.org/debian sid/main amd64 Packages [8400 kB]
Fetched 8546 kB in 1s (8088 kB/s)
[…]
The following NEW packages will be installed:
  ack libfile-next-perl libgdbm-compat4 libgdbm6 libperl5.30 netbase perl perl-modules-5.30
0 upgraded, 8 newly installed, 0 to remove and 23 not upgraded.
Need to get 7341 kB of archives.
After this operation, 46.7 MB of additional disk space will be used.
[…]
real	0m9.544s
user	0m2.839s
sys	0m0.775s
```

</details>

<details>
<summary>
Arch Linux’s pacman takes a little under 3s to fetch and unpack 6.5 MB.
</summary>

```
% docker run -t -i archlinux/base
[root@9f6672688a64 /]# time (pacman -Sy && pacman -S --noconfirm ack)
:: Synchronizing package databases...
 core            130.8 KiB  1090 KiB/s 00:00
 extra          1655.8 KiB  3.48 MiB/s 00:00
 community         5.2 MiB  6.11 MiB/s 00:01
resolving dependencies...
looking for conflicting packages...

Packages (2) perl-file-next-1.18-2  ack-3.4.0-1

Total Download Size:   0.07 MiB
Total Installed Size:  0.19 MiB
[…]
real	0m2.936s
user	0m0.375s
sys	0m0.160s
```

</details>

<details>
<summary>
Alpine’s apk takes a little over 1 second to fetch and unpack 10 MB.
</summary>

```
% docker run -t -i alpine
fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/community/x86_64/APKINDEX.tar.gz
(1/4) Installing libbz2 (1.0.8-r1)
(2/4) Installing perl (5.30.3-r0)
(3/4) Installing perl-file-next (1.18-r0)
(4/4) Installing ack (3.3.1-r0)
Executing busybox-1.31.1-r16.trigger
OK: 43 MiB in 18 packages
real	0m 1.24s
user	0m 0.40s
sys	0m 0.15s
```

</details>

#### qemu

You can expand each of these:

<details>
<summary>
Fedora’s dnf takes over 4 minutes to fetch and unpack 226 MB.
</summary>

```
% docker run -t -i fedora /bin/bash
[root@6a52ecfc3afa /]# time dnf install -y qemu
Fedora 32 openh264 (From Cisco) - x86_64     3.1 kB/s | 2.5 kB     00:00
Fedora Modular 32 - x86_64                   6.3 MB/s | 4.9 MB     00:00
Fedora Modular 32 - x86_64 - Updates         6.0 MB/s | 3.7 MB     00:00
Fedora 32 - x86_64 - Updates                 334 kB/s |  23 MB     01:10
Fedora 32 - x86_64                            33 MB/s |  70 MB     00:02
[…]

Total download size: 181 M
Downloading Packages:
[…]

real	4m37.652s
user	0m38.239s
sys	0m6.321s
```

</details>

<details>
<summary>
NixOS’s Nix takes almost 34s to fetch and unpack 180 MB.
</summary>

```
% docker run -t -i nixos/nix
83971cf79f7e:/# time sh -c 'nix-channel --update && nix-env -iA nixpkgs.qemu'
unpacking channels...
created 1 symlinks in user environment
installing 'qemu-5.1.0'
these paths will be fetched (180.70 MiB download, 1146.92 MiB unpacked):
[…]
real	0m 33.64s
user	0m 16.96s
sys	0m 3.05s
```

</details>

<details>
<summary>
Debian’s apt takes over 95 seconds to fetch and unpack 224 MB.
</summary>

```
% docker run -t -i debian:sid
root@b7cc25a927ab:/# time (apt update && apt install -y qemu-system-x86)
Get:1 http://deb.debian.org/debian sid InRelease [146 kB]
Get:2 http://deb.debian.org/debian sid/main amd64 Packages [8400 kB]
Fetched 8546 kB in 1s (5998 kB/s)
[…]
Fetched 216 MB in 43s (5006 kB/s)
[…]
real	1m25.375s
user	0m29.163s
sys	0m12.835s
```

</details>

<details>
<summary>
Arch Linux’s pacman takes almost 44s to fetch and unpack 142 MB.
</summary>

```
% docker run -t -i archlinux/base
[root@58c78bda08e8 /]# time (pacman -Sy && pacman -S --noconfirm qemu)
:: Synchronizing package databases...
 core          130.8 KiB  1055 KiB/s 00:00
 extra        1655.8 KiB  3.70 MiB/s 00:00
 community       5.2 MiB  7.89 MiB/s 00:01
[…]
Total Download Size:   135.46 MiB
Total Installed Size:  661.05 MiB
[…]
real	0m43.901s
user	0m4.980s
sys	0m2.615s
```

</details>

<details>
<summary>
Alpine’s apk takes only about 2.4 seconds to fetch and unpack 26 MB.
</summary>

```
% docker run -t -i alpine
/ # time apk add qemu-system-x86_64
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/community/x86_64/APKINDEX.tar.gz
[…]
OK: 78 MiB in 95 packages
real	0m 2.43s
user	0m 0.46s
sys	0m 0.09s
```

</details>


### Appendix B: measurement details (2019) {#appendix-b}

#### ack

You can expand each of these:

<details>
<summary>
Fedora’s dnf takes almost 30 seconds to fetch and unpack 107 MB.
</summary>

```
% docker run -t -i fedora /bin/bash
[root@722e6df10258 /]# time dnf install -y ack
Fedora Modular 30 - x86_64            4.4 MB/s | 2.7 MB     00:00
Fedora Modular 30 - x86_64 - Updates  3.7 MB/s | 2.4 MB     00:00
Fedora 30 - x86_64 - Updates           17 MB/s |  19 MB     00:01
Fedora 30 - x86_64                     31 MB/s |  70 MB     00:02
[…]
Install  44 Packages

Total download size: 13 M
Installed size: 42 M
[…]
real	0m29.498s
user	0m22.954s
sys	0m1.085s
```

</details>

<details>
<summary>
NixOS’s Nix takes 14s to fetch and unpack 15 MB.
</summary>

```
% docker run -t -i nixos/nix
39e9186422ba:/# time sh -c 'nix-channel --update && nix-env -i perl5.28.2-ack-2.28'
unpacking channels...
created 2 symlinks in user environment
installing 'perl5.28.2-ack-2.28'
these paths will be fetched (14.91 MiB download, 80.83 MiB unpacked):
  /nix/store/57iv2vch31v8plcjrk97lcw1zbwb2n9r-perl-5.28.2
  /nix/store/89gi8cbp8l5sf0m8pgynp2mh1c6pk1gk-attr-2.4.48
  /nix/store/gkrpl3k6s43fkg71n0269yq3p1f0al88-perl5.28.2-ack-2.28-man
  /nix/store/iykxb0bmfjmi7s53kfg6pjbfpd8jmza6-glibc-2.27
  /nix/store/k8lhqzpaaymshchz8ky3z4653h4kln9d-coreutils-8.31
  /nix/store/svgkibi7105pm151prywndsgvmc4qvzs-acl-2.2.53
  /nix/store/x4knf14z1p0ci72gl314i7vza93iy7yc-perl5.28.2-File-Next-1.16
  /nix/store/zfj7ria2kwqzqj9dh91kj9kwsynxdfk0-perl5.28.2-ack-2.28
copying path '/nix/store/gkrpl3k6s43fkg71n0269yq3p1f0al88-perl5.28.2-ack-2.28-man' from 'https://cache.nixos.org'...
copying path '/nix/store/iykxb0bmfjmi7s53kfg6pjbfpd8jmza6-glibc-2.27' from 'https://cache.nixos.org'...
copying path '/nix/store/x4knf14z1p0ci72gl314i7vza93iy7yc-perl5.28.2-File-Next-1.16' from 'https://cache.nixos.org'...
copying path '/nix/store/89gi8cbp8l5sf0m8pgynp2mh1c6pk1gk-attr-2.4.48' from 'https://cache.nixos.org'...
copying path '/nix/store/svgkibi7105pm151prywndsgvmc4qvzs-acl-2.2.53' from 'https://cache.nixos.org'...
copying path '/nix/store/k8lhqzpaaymshchz8ky3z4653h4kln9d-coreutils-8.31' from 'https://cache.nixos.org'...
copying path '/nix/store/57iv2vch31v8plcjrk97lcw1zbwb2n9r-perl-5.28.2' from 'https://cache.nixos.org'...
copying path '/nix/store/zfj7ria2kwqzqj9dh91kj9kwsynxdfk0-perl5.28.2-ack-2.28' from 'https://cache.nixos.org'...
building '/nix/store/q3243sjg91x1m8ipl0sj5gjzpnbgxrqw-user-environment.drv'...
created 56 symlinks in user environment
real	0m 14.02s
user	0m 8.83s
sys	0m 2.69s
```

</details>

<details>
<summary>
Debian’s apt takes almost 10 seconds to fetch and unpack 16 MB.
</summary>

```
% docker run -t -i debian:sid
root@b7cc25a927ab:/# time (apt update && apt install -y ack-grep)
Get:1 http://cdn-fastly.deb.debian.org/debian sid InRelease [233 kB]
Get:2 http://cdn-fastly.deb.debian.org/debian sid/main amd64 Packages [8270 kB]
Fetched 8502 kB in 2s (4764 kB/s)
[…]
The following NEW packages will be installed:
  ack ack-grep libfile-next-perl libgdbm-compat4 libgdbm5 libperl5.26 netbase perl perl-modules-5.26
The following packages will be upgraded:
  perl-base
1 upgraded, 9 newly installed, 0 to remove and 60 not upgraded.
Need to get 8238 kB of archives.
After this operation, 42.3 MB of additional disk space will be used.
[…]
real	0m9.096s
user	0m2.616s
sys	0m0.441s
```

</details>

<details>
<summary>
Arch Linux’s pacman takes a little over 3s to fetch and unpack 6.5 MB.
</summary>

```
% docker run -t -i archlinux/base
[root@9604e4ae2367 /]# time (pacman -Sy && pacman -S --noconfirm ack)
:: Synchronizing package databases...
 core            132.2 KiB  1033K/s 00:00
 extra          1629.6 KiB  2.95M/s 00:01
 community         4.9 MiB  5.75M/s 00:01
[…]
Total Download Size:   0.07 MiB
Total Installed Size:  0.19 MiB
[…]
real	0m3.354s
user	0m0.224s
sys	0m0.049s
```

</details>

<details>
<summary>
Alpine’s apk takes only about 1 second to fetch and unpack 10 MB.
</summary>

```
% docker run -t -i alpine
/ # time apk add ack
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/community/x86_64/APKINDEX.tar.gz
(1/4) Installing perl-file-next (1.16-r0)
(2/4) Installing libbz2 (1.0.6-r7)
(3/4) Installing perl (5.28.2-r1)
(4/4) Installing ack (3.0.0-r0)
Executing busybox-1.30.1-r2.trigger
OK: 44 MiB in 18 packages
real	0m 0.96s
user	0m 0.25s
sys	0m 0.07s
```

</details>

#### qemu

You can expand each of these:

<details>
<summary>
Fedora’s dnf takes over a minute to fetch and unpack 266 MB.
</summary>

```
% docker run -t -i fedora /bin/bash
[root@722e6df10258 /]# time dnf install -y qemu
Fedora Modular 30 - x86_64            3.1 MB/s | 2.7 MB     00:00
Fedora Modular 30 - x86_64 - Updates  2.7 MB/s | 2.4 MB     00:00
Fedora 30 - x86_64 - Updates           20 MB/s |  19 MB     00:00
Fedora 30 - x86_64                     31 MB/s |  70 MB     00:02
[…]
Install  262 Packages
Upgrade    4 Packages

Total download size: 172 M
[…]
real	1m7.877s
user	0m44.237s
sys	0m3.258s
```

</details>

<details>
<summary>
NixOS’s Nix takes 38s to fetch and unpack 262 MB.
</summary>

```
% docker run -t -i nixos/nix
39e9186422ba:/# time sh -c 'nix-channel --update && nix-env -i qemu-4.0.0'
unpacking channels...
created 2 symlinks in user environment
installing 'qemu-4.0.0'
these paths will be fetched (262.18 MiB download, 1364.54 MiB unpacked):
[…]
real	0m 38.49s
user	0m 26.52s
sys	0m 4.43s
```

</details>

<details>
<summary>
Debian’s apt takes 51 seconds to fetch and unpack 159 MB.
</summary>

```
% docker run -t -i debian:sid
root@b7cc25a927ab:/# time (apt update && apt install -y qemu-system-x86)
Get:1 http://cdn-fastly.deb.debian.org/debian sid InRelease [149 kB]
Get:2 http://cdn-fastly.deb.debian.org/debian sid/main amd64 Packages [8426 kB]
Fetched 8574 kB in 1s (6716 kB/s)
[…]
Fetched 151 MB in 2s (64.6 MB/s)
[…]
real	0m51.583s
user	0m15.671s
sys	0m3.732s
```

</details>

<details>
<summary>
Arch Linux’s pacman takes 1m2s to fetch and unpack 124 MB.
</summary>

```
% docker run -t -i archlinux/base
[root@9604e4ae2367 /]# time (pacman -Sy && pacman -S --noconfirm qemu)
:: Synchronizing package databases...
 core       132.2 KiB   751K/s 00:00
 extra     1629.6 KiB  3.04M/s 00:01
 community    4.9 MiB  6.16M/s 00:01
[…]
Total Download Size:   123.20 MiB
Total Installed Size:  587.84 MiB
[…]
real	1m2.475s
user	0m9.272s
sys	0m2.458s
```

</details>

<details>
<summary>
Alpine’s apk takes only about 2.4 seconds to fetch and unpack 26 MB.
</summary>

```
% docker run -t -i alpine
/ # time apk add qemu-system-x86_64
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/community/x86_64/APKINDEX.tar.gz
[…]
OK: 78 MiB in 95 packages
real	0m 2.43s
user	0m 0.46s
sys	0m 0.09s
```

</details>
