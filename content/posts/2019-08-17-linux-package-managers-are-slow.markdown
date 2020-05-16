---
layout: post
title:  "Linux package managers are slow"
date:   2019-08-17 18:27:00 +02:00
categories: Artikel
tags:
- distri
- debian
---

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

See [Appendix B](#appendix-b) for details on the measurement method and command
outputs.

### Measurements

Keep in mind that these are one-time measurements. They should be indicative of
actual performance, but your experience may vary.

#### ack (small Perl program)

distribution | package manager | data   | wall-clock time | rate
-------------|-----------------|--------|-----------------|-----
Fedora       | dnf             | 107 MB | 29s             | 3.7 MB/s
NixOS        | Nix             | 15 MB  | 14s             | 1.1 MB/s
Debian       | apt             | 15 MB  | 4s              | 3.7 MB/s
Arch Linux   | pacman          | 6.5 MB | 3s              | 2.1 MB/s
Alpine       | apk             | 10 MB  | 1s              | 10.0 MB/s

#### qemu (large C program)

distribution | package manager | data   | wall-clock time | rate
-------------|-----------------|--------|-----------------|-----
Fedora       | dnf             | 266 MB | 1m8s            | 3.9 MB/s
Arch Linux   | pacman          | 124 MB | 1m2s            | 2.0 MB/s
Debian       | apt             | 159 MB | 51s             | 3.1 MB/s
NixOS        | Nix             | 262 MB | 38s             | 6.8 MB/s
Alpine       | apk             | 26 MB  | 2.4s            | 10.8 MB/s


<br>
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

### Appendix B: measurement details {#appendix-b}

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
