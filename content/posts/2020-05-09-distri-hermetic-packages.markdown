---
layout: post
title:  "Hermetic packages (in distri)"
date:   2020-05-09 18:48:00 +02:00
categories: Artikel
tags:
- distri
- debian
---

In [distri](https://distr1.org/), packages (e.g. `emacs`) are hermetic. By
hermetic, I mean that the dependencies a package uses (e.g. `libusb`) don’t
change, even when newer versions are installed.

For example, if package `libusb-amd64-1.0.22-7` is available at build time, the
package will always use that same version, even after the newer
`libusb-amd64-1.0.23-8` will be installed into the package store.

Another way of saying the same thing is: *packages in distri are always
co-installable*.

This makes the package store more robust: additions to it will not break the
system. On a technical level, the package store is implemented as a directory
containing distri SquashFS images and metadata files, into which packages are
installed in an atomic way.

## Out of scope: plugins are not hermetic by design

One exception where hermeticity is not desired are plugin mechanisms: optionally
loading out-of-tree code at runtime obviously is not hermetic.

As an example, consider [glibc’s Name Service Switch
(NSS)](https://www.gnu.org/software/libc/manual/html_node/Name-Service-Switch.html)
mechanism. Page [29.4.1 Adding another Service to
NSS](https://www.gnu.org/software/libc/manual/html_node/Adding-another-Service-to-NSS.html#Adding-another-Service-to-NSS)
describes how glibc searches `$prefix/lib` for shared libraries at runtime.

Debian [ships about a dozen NSS
libraries](https://packages.debian.org/search?suite=buster&arch=amd64&mode=filename&searchon=contents&keywords=libnss_%20.so.2)
for a variety of purposes, and enterprise setups might add their own into the
mix.

systemd (as of v245) accounts for 4 NSS libraries,
e.g. [nss-systemd](https://www.freedesktop.org/software/systemd/man/nss-systemd.html)
for user/group name resolution for users allocated through [systemd’s
`DynamicUser=`](https://www.freedesktop.org/software/systemd/man/systemd.exec.html)
option.

Having packages be as hermetic as possible remains a worthwhile goal despite any
exceptions: I will gladly use a 99% hermetic system over a 0% hermetic system
any day.

Side note: Xorg’s driver model (which can be characterized as a plugin
mechanism) does not fall under this category because of its tight API/ABI
coupling! For this case, where drivers are only guaranteed to work with
precisely the Xorg version for which they were compiled, distri uses per-package
exchange directories.

## Implementation of hermetic packages in distri

On a technical level, the requirement is: all paths used by the program must
always result in the same contents. This is implemented in distri via the
read-only package store mounted at `/ro`, e.g. files underneath
`/ro/emacs-amd64-26.3-15` never change.

To change all paths used by a program, in practice, three strategies cover most
paths:

### ELF interpreter and dynamic libraries

Programs on Linux use the [ELF file
format](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format), which
contains two kinds of references:

First, **the ELF interpreter** (`PT_INTERP` segment), which is used to start the
program. For dynamically linked programs on 64-bit systems, this is typically
[`ld.so(8)`](https://manpages.debian.org/testing/manpages/ld.so.8.en.html).

Many distributions use system-global paths such as
`/lib64/ld-linux-x86-64.so.2`, but distri compiles programs with
`-Wl,--dynamic-linker=/ro/glibc-amd64-2.31-4/out/lib/ld-linux-x86-64.so.2` so
that the full path ends up in the binary.

The ELF interpreter is shown by `file(1)`, but you can also use `readelf -a
$BINARY | grep 'program interpreter'` to display it.

And secondly, [**the rpath**, a run-time search
path](https://en.wikipedia.org/wiki/Rpath) for dynamic libraries. Instead of
storing full references to all dynamic libraries, we set the rpath so that
`ld.so(8)` will find the correct dynamic libraries.

Originally, we used to just set a long rpath, containing one entry for each
dynamic library dependency. However, we have since [switched to using a single
`lib` subdirectory per
package](https://github.com/distr1/distri/commit/19f342071283f4d78353bdbac8d6849809927f93)
as its rpath, and placing symlinks with full path references into that `lib`
directory, e.g. using `-Wl,-rpath=/ro/grep-amd64-3.4-4/lib`. This is better for
performance, as `ld.so` uses a per-directory cache.

Note that program load times are significantly influenced by how quickly you can
locate the dynamic libraries. distri uses a FUSE file system to load programs
from, so [getting proper `-ENOENT` caching into
place](https://github.com/distr1/distri/commit/b6a0e43368d54d5ed0e03af687158dc3e2106e38)
drastically sped up program load times.

Instead of compiling software with the `-Wl,--dynamic-linker` and `-Wl,-rpath`
flags, one can also modify these fields after the fact using `patchelf(1)`. For
closed-source programs, this is the only possibility.

The rpath can be inspected by using e.g. `readelf -a $BINARY | grep RPATH`.

### Environment variable setup wrapper programs

Many programs are influenced by environment variables: to start another program,
said program is often found by checking each directory in the `PATH` environment
variable.

Such search paths are prevalent in scripting languages, too, to find
modules. Python has `PYTHONPATH`, Perl has `PERL5LIB`, and so on.

To set up these search path environment variables at run time, distri employs an
indirection. Instead of e.g. `teensy-loader-cli`, you run a small wrapper
program that calls precisely one `execve` system call with the desired
environment variables.

Initially, I used shell scripts as wrapper programs because they are easily
inspectable. This turned out to be too slow, so I switched to [compiled
programs](https://github.com/distr1/distri/blob/3ee4437f88605174fd82144381cfa726fc683ccb/internal/build/build.go#L1085-L1112). I’m
linking them statically for fast startup, and I’m linking them against [musl
libc](https://musl.libc.org/) for significantly smaller file sizes than glibc
(per-executable overhead adds up quickly in a distribution!).

Note that the wrapper programs prepend to the `PATH` environment variable, they
don’t replace it in its entirely. This is important so that users have a way to
extend the `PATH` (and other variables) if they so choose. This doesn’t hurt
hermeticity because it is only relevant for programs that were not present at
build time, i.e. plugin mechanisms which, by design, cannot be hermetic.

### Shebang interpreter patching

The [Shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) of scripts contains
a path, too, and hence needs to be changed.

[We don’t do this in distri yet](https://github.com/distr1/distri/issues/67)
(the number of packaged scripts is small), but we should.

### Performance requirements

The performance improvements in the previous sections are not just good to have,
but practically required when many processes are involved: without them, you’ll
encounter second-long delays in [magit](https://magit.vc/) which spawns many git
processes under the covers, or in
[dracut](https://en.wikipedia.org/wiki/Dracut_(software)), which spawns one
`cp(1)` process per file.

## Downside: rebuild of packages required to pick up changes

Linux distributions such as Debian consider it an advantage to roll out security
fixes to the entire system by updating a single shared library package
(e.g. `openssl`).

The flip side of that coin is that changes to a single critical package can
break the entire system.

With hermetic packages, all reverse dependencies must be rebuilt when a
library’s changes should be picked up by the whole system. E.g., when `openssl`
changes, `curl` must be rebuilt to pick up the new version of `openssl`.

This approach trades off using more bandwidth and more disk space (temporarily)
against reducing the blast radius of any individual package update.

## Downside: long env variables are cumbersome to deal with

This can be partially mitigated by [removing empty directories at build
time](https://github.com/distr1/distri/commit/6ac53cac4a5027622ae8622be2a208778dd54e74),
which will result in shorter variables.

In general, there is no getting around this. One little trick is to use `tr :
'\n'`, e.g.:

```
distri0# echo $PATH
/usr/bin:/bin:/usr/sbin:/sbin:/ro/openssh-amd64-8.2p1-11/out/bin

distri0# echo $PATH | tr : '\n'
/usr/bin
/bin
/usr/sbin
/sbin
/ro/openssh-amd64-8.2p1-11/out/bin
```

## Edge cases

The implementation outlined above works well in hundreds of packages, and only a
small handful exhibited problems of any kind. Here are some issues I encountered:

### Issue: accidental ABI breakage in plugin mechanisms

NSS libraries built against glibc 2.28 and newer [cannot be loaded by glibc
2.27](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=928769). In all
likelihood, such changes do not happen too often, but it does illustrate that
glibc’s [published interface
spec](https://www.gnu.org/software/libc/manual/html_node/Adding-another-Service-to-NSS.html#Adding-another-Service-to-NSS)
is not sufficient for forwards and backwards compatibility.

In distri, we could likely use a per-package exchange directory for glibc’s NSS
mechanism to prevent the above problem from happening in the future.

### Issue: wrapper bypass when a program re-executes itself

Some programs try to arrange for themselves to be re-executed outside of their
current process tree. For example, consider building a program with the `meson`
build system:

1. When `meson` first configures the build, it generates `ninja` files (think
   Makefiles) which contain command lines that run the `meson --internal`
   helper.

2. Once `meson` returns, `ninja` is called as a separate process, so it will not
   have the environment which the `meson` wrapper sets up. `ninja` then runs the
   previously persisted `meson` command line. Since the command line uses the
   full path to `meson` (not to its wrapper), it bypasses the wrapper.

Luckily, not many programs try to arrange for other process trees to run
them. Here is a table summarizing how affected programs might try to arrange for
re-execution, whether the technique results in a wrapper bypass, and what we do
about it in distri:

| technique to execute itself | uses wrapper | mitigation |
|-----------------------------|--------------|------------|
| run-time: find own basename in `PATH` | yes | wrapper program |
| compile-time: embed expected path | no; bypass! | configure or patch |
| run-time: `argv[0]` or `/proc/self/exe` | no; bypass! | [patch](https://github.com/distr1/distri/commit/f45ee9ac1121da284f2943c80e2c30afa24ca80d) |

One might think that setting `argv[0]` to the wrapper location seems like a way
to side-step this problem. We tried doing this in distri, but [had to
revert](https://github.com/distr1/distri/commit/b517cb33ed827d358b00737434c7a09dd75583b7)
and [go the other
way](https://github.com/distr1/distri/commit/9fd34936d4415f9963202bbb9ee454c970874b18).

### Misc smaller issues

* Login shells are [started by convention with a `-` character prepended to
  `argv[0]`](https://unix.stackexchange.com/a/46856/181634), so [shells like
  bash or zsh cannot use wrapper
  programs](https://github.com/distr1/distri/commit/3c3a9d6ef4fc76edca6fb8351a716b18b83ff3af).
* [LDFLAGS leaked to
  pkgconfig](https://github.com/distr1/distri/commit/cefded2b2ce39407cc2d75936ec6cb018d533846)
  ([upstream
  reports](https://github.com/distr1/distri/commit/434b7298ad7ef8d4ae229df84dd2353badf48fa1))
* [mozjs tries to run autoconf with the shell directly, but should use
  autoconf’s wrapper](https://bugzilla.mozilla.org/show_bug.cgi?id=1635036)

## Appendix: Could other distributions adopt hermetic packages?

At a very high level, adopting hermetic packages will require two steps:

1. Using fully qualified paths whose contents don’t change
(e.g. `/ro/emacs-amd64-26.3-15`) generally requires rebuilding programs,
e.g. with `--prefix` set.

2. Once you use fully qualified paths you need to make the packages able to
exchange data. distri solves this with exchange directories, implemented in the
`/ro` file system which is backed by a FUSE daemon.

The first step is pretty simple, whereas the second step is where I expect
controversy around any suggested mechanism.

## Appendix: demo (in distri)

This appendix contains commands and their outputs, run on upcoming distri
version `supersilverhaze`, but verified to work on older versions, too.

Large outputs have been collapsed and can be expanded by clicking on the output.

The `/bin` directory contains symlinks for the union of all package’s `bin` subdirectories:
<details class="output" open><summary><code>distri0# readlink -f /bin/teensy_loader_cli</code></summary><pre><code>/ro/teensy-loader-cli-amd64-2.1+g20180927-7/bin/teensy_loader_cli</code></pre></details>

The wrapper program in the `bin` subdirectory is small:
<details class="output" open><summary><code>distri0# ls -lh $(readlink -f /bin/teensy_loader_cli)</code></summary><pre><code>-rwxr-xr-x 1 root root 46K Apr 21 21:56 /ro/teensy-loader-cli-amd64-2.1+g20180927-7/bin/teensy_loader_cli</code></pre></details>

Wrapper programs execute quickly:
<details class="output"><summary><code>distri0# strace -fvy /bin/teensy_loader_cli |& head | cat -n</code></summary><pre><code>     1  execve("/bin/teensy_loader_cli", ["/bin/teensy_loader_cli"], ["USER=root", "LOGNAME=root", "HOME=/root", "PATH=/ro/bash-amd64-5.0-4/bin:/r"..., "SHELL=/bin/zsh", "TERM=screen.xterm-256color", "XDG_SESSION_ID=c1", "XDG_RUNTIME_DIR=/run/user/0", "DBUS_SESSION_BUS_ADDRESS=unix:pa"..., "XDG_SESSION_TYPE=tty", "XDG_SESSION_CLASS=user", "SSH_CLIENT=10.0.2.2 42556 22", "SSH_CONNECTION=10.0.2.2 42556 10"..., "SSH_TTY=/dev/pts/0", "SHLVL=1", "PWD=/root", "OLDPWD=/root", "_=/usr/bin/strace", "LD_LIBRARY_PATH=/ro/bash-amd64-5"..., "PERL5LIB=/ro/bash-amd64-5.0-4/ou"..., "PYTHONPATH=/ro/bash-amd64-5.b0-4/"...]) = 0
     2  arch_prctl(ARCH_SET_FS, 0x40c878)       = 0
     3  set_tid_address(0x40ca9c)               = 715
     4  brk(NULL)                               = 0x15b9000
     5  brk(0x15ba000)                          = 0x15ba000
     6  brk(0x15bb000)                          = 0x15bb000
     7  brk(0x15bd000)                          = 0x15bd000
     8  brk(0x15bf000)                          = 0x15bf000
     9  brk(0x15c1000)                          = 0x15c1000
    10  execve("/ro/teensy-loader-cli-amd64-2.1+g20180927-7/out/bin/teensy_loader_cli", ["/ro/teensy-loader-cli-amd64-2.1+"...], ["USER=root", "LOGNAME=root", "HOME=/root", "PATH=/ro/bash-amd64-5.0-4/bin:/r"..., "SHELL=/bin/zsh", "TERM=screen.xterm-256color", "XDG_SESSION_ID=c1", "XDG_RUNTIME_DIR=/run/user/0", "DBUS_SESSION_BUS_ADDRESS=unix:pa"..., "XDG_SESSION_TYPE=tty", "XDG_SESSION_CLASS=user", "SSH_CLIENT=10.0.2.2 42556 22", "SSH_CONNECTION=10.0.2.2 42556 10"..., "SSH_TTY=/dev/pts/0", "SHLVL=1", "PWD=/root", "OLDPWD=/root", "_=/usr/bin/strace", "LD_LIBRARY_PATH=/ro/bash-amd64-5"..., "PERL5LIB=/ro/bash-amd64-5.0-4/ou"..., "PYTHONPATH=/ro/bash-amd64-5.0-4/"...]) = 0</code></pre></details>

Confirm which ELF interpreter is set for a binary using `readelf(1)`:
<details class="output" open><summary><code>distri0# readelf -a /ro/teensy-loader-cli-amd64-2.1+g20180927-7/out/bin/teensy_loader_cli | grep 'program interpreter'</code></summary><pre><code>[Requesting program interpreter: /ro/glibc-amd64-2.31-4/out/lib/ld-linux-x86-64.so.2]</code></pre></details>

Confirm the rpath is set to the package’s lib subdirectory using `readelf(1)`:
<details class="output" open><summary><code>distri0# readelf -a /ro/teensy-loader-cli-amd64-2.1+g20180927-7/out/bin/teensy_loader_cli | grep RPATH</code></summary><pre><code> 0x000000000000000f (RPATH)              Library rpath: [/ro/teensy-loader-cli-amd64-2.1+g20180927-7/lib]</code></pre></details>

…and verify the lib subdirectory has the expected symlinks and target versions:
<details class="output"><summary><code>distri0# find /ro/teensy-loader-cli-amd64-*/lib -type f -printf '%P -> %l\n'</code><pre>libc.so.6 -> /ro/glibc-amd64-2.31-4/out/lib/libc-2.31.so</pre></summary><pre><code>libpthread.so.0 -> /ro/glibc-amd64-2.31-4/out/lib/libpthread-2.31.so
librt.so.1 -> /ro/glibc-amd64-2.31-4/out/lib/librt-2.31.so
libudev.so.1 -> /ro/libudev-amd64-245-11/out/lib/libudev.so.1.6.17
libusb-0.1.so.4 -> /ro/libusb-compat-amd64-0.1.5-7/out/lib/libusb-0.1.so.4.4.4
libusb-1.0.so.0 -> /ro/libusb-amd64-1.0.23-8/out/lib/libusb-1.0.so.0.2.0</code></pre></details>

To verify the correct libraries are actually loaded, you can set the `LD_DEBUG`
environment variable for `ld.so(8)`:

<details class="output"><summary><code>distri0# LD_DEBUG=libs teensy_loader_cli</code></summary><pre><code>[…]
       678:     find library=libc.so.6 [0]; searching
       678:      search path=/ro/teensy-loader-cli-amd64-2.1+g20180927-7/lib            (RPATH from file /ro/teensy-loader-cli-amd64-2.1+g20180927-7/out/bin/teensy_loader_cli)
       678:       trying file=/ro/teensy-loader-cli-amd64-2.1+g20180927-7/lib/libc.so.6
       678:
[…]</code></pre></details>

NSS libraries that distri ships:
<details class="output"><summary><code>find /lib/ -name "libnss_*.so.2" -type f -printf '%P -> %l\n'</code><pre>libnss_myhostname.so.2 -> ../systemd-amd64-245-11/out/lib/libnss_myhostname.so.2</pre></summary><pre><code>libnss_mymachines.so.2 -> ../systemd-amd64-245-11/out/lib/libnss_mymachines.so.2
libnss_resolve.so.2 -> ../systemd-amd64-245-11/out/lib/libnss_resolve.so.2
libnss_systemd.so.2 -> ../systemd-amd64-245-11/out/lib/libnss_systemd.so.2
libnss_compat.so.2 -> ../glibc-amd64-2.31-4/out/lib/libnss_compat.so.2
libnss_db.so.2 -> ../glibc-amd64-2.31-4/out/lib/libnss_db.so.2
libnss_dns.so.2 -> ../glibc-amd64-2.31-4/out/lib/libnss_dns.so.2
libnss_files.so.2 -> ../glibc-amd64-2.31-4/out/lib/libnss_files.so.2
libnss_hesiod.so.2 -> ../glibc-amd64-2.31-4/out/lib/libnss_hesiod.so.2</code></pre></details>
