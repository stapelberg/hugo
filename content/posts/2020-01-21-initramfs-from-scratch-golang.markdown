---
layout: post
title:  "distri: 20x faster initramfs (initrd) from scratch"
date:   2020-01-21 17:50:00 +01:00
categories: Artikel
tags:
- distri
- debian
---

In case you are not yet familiar with why an initramfs (or initrd, or initial
ramdisk) is typically used when starting Linux, let me quote the [wikipedia
definition](https://en.wikipedia.org/wiki/Initial_ramdisk):

“[…] initrd is a scheme for loading a temporary root file system into memory,
which may be used as part of the Linux startup process […] to make preparations
before the real root file system can be mounted.”

Many Linux distributions do not compile all file system drivers into the kernel,
but instead load them on-demand from an initramfs, which saves memory.

Another common scenario, in which an initramfs is required, is full-disk
encryption: the disk must be unlocked from userspace, but since userspace is
encrypted, an initramfs is used.

## Motivation

Thus far, building a [distri](https://distr1.org/) disk image was quite slow:

This is on an AMD Ryzen 3900X 12-core processor (2019):
```
distri % time make cryptimage serial=1
80.29s user 13.56s system 186% cpu 50.419 total # 19s image, 31s initrd
```

Of these 50 seconds,
[`dracut`](https://en.wikipedia.org/wiki/Dracut_(software))’s initramfs
generation accounts for 31 seconds (62%)!

Initramfs generation time drops to 8.7 seconds once `dracut` no longer needs to
use the single-threaded {{< man name="gzip" section="1" >}}, but the
multi-threaded replacement {{< man name="pigz" section="1" >}}:

This brings the total time to build a distri disk image down to:

```
distri % time make cryptimage serial=1
76.85s user 13.23s system 327% cpu 27.509 total # 19s image, 8.7s initrd
```

Clearly, when you use `dracut` on any modern computer, you should make pigz
available. `dracut` should fail to compile unless one explicitly opts into the
known-slower gzip. For more thoughts on optional dependencies, see [“Optional
dependencies don’t work”](/posts/2019-05-23-optional-dependencies/).

But why does it take 8.7 seconds still? Can we go faster?

The answer is **Yes**! I recently built a distri-specific initramfs I’m calling
`minitrd`. I wrote both big parts from scratch:

1. the initramfs generator program ([`distri initrd`](https://github.com/distr1/distri/blob/master/cmd/distri/initrd.go))
2. a custom Go userland ([`cmd/minitrd`](https://github.com/distr1/distri/blob/master/cmd/minitrd/minitrd.go)), running as `/init` in the initramfs.

`minitrd` generates the initramfs image in ≈400ms, bringing the total time down
to:

```
distri % time make cryptimage serial=1
50.09s user 8.80s system 314% cpu 18.739 total # 18s image, 400ms initrd
```

(The remaining time is spent in preparing the file system, then installing and
configuring the distri system, i.e. preparing a disk image you can [run on real
hardware](https://distr1.org/#run-distri-on-real-hardware).)

How can `minitrd` be 20 times faster than `dracut`?

`dracut` is mainly written in shell, with a C helper program. It drives the
generation process by spawning lots of external dependencies (e.g. `ldd` or the
`dracut-install` helper program). I assume that the combination of using an
interpreted language (shell) that spawns lots of processes and precludes a
concurrent architecture is to blame for the poor performance.

`minitrd` is written in Go, with speed as a goal. It leverages concurrency and
uses no external dependencies; everything happens within a single process (but
with enough threads to saturate modern hardware).

Measuring early boot time using qemu, I measured the `dracut`-generated
initramfs taking 588ms to display the full disk encryption passphrase prompt,
whereas `minitrd` took only 195ms.

The rest of this article dives deeper into how `minitrd` works.

## What does an initramfs do?

Ultimately, the job of an initramfs is to make the root file system available
and continue booting the system from there. Depending on the system setup, this
involves the following 5 steps:

### 1. Load kernel modules to access the block devices with the root file system

Depending on the system, the block devices with the root file system might
already be present when the initramfs runs, or some kernel modules might need to
be loaded first. On my Dell XPS 9360 laptop, the NVMe system disk is already
present when the initramfs starts, whereas in qemu, we need to load the
`virtio_pci` module, followed by the `virtio_scsi` module.

How will our userland program know which kernel modules to load? Linux kernel
modules declare patterns for their supported hardware as an alias, e.g.:

```
initrd# grep virtio_pci lib/modules/5.4.6/modules.alias
alias pci:v00001AF4d*sv*sd*bc*sc*i* virtio_pci
```

Devices in `sysfs` have a `modalias` file whose content can be matched against
these declarations to identify the module to load:

```
initrd# cat /sys/devices/pci0000:00/*/modalias
pci:v00001AF4d00001005sv00001AF4sd00000004bc00scFFi00
pci:v00001AF4d00001004sv00001AF4sd00000008bc01sc00i00
[…]
```

Hence, for the initial round of module loading, it is sufficient to locate all
`modalias` files within `sysfs` and load the responsible modules.

Loading a kernel module can result in new devices appearing. When that happens,
the kernel sends a uevent, which the uevent consumer in userspace receives via a
netlink socket. Typically, this consumer is {{< man name="udev" section="7" >}},
but in our case, it’s `minitrd`.

For each uevent messages that comes with a `MODALIAS` variable, `minitrd` will
load the relevant kernel module(s).

When loading a kernel module, its dependencies need to be loaded
first. Dependency information is stored in the `modules.dep` file in a
`Makefile`-like syntax:

```
initrd# grep virtio_pci lib/modules/5.4.6/modules.dep
kernel/drivers/virtio/virtio_pci.ko: kernel/drivers/virtio/virtio_ring.ko kernel/drivers/virtio/virtio.ko
```

To load a module, we can open its file and then call the Linux-specific {{< man
name="finit_module" section="2" >}} system call. Some modules are expected to
return an error code, e.g. `ENODEV` or `ENOENT` when some hardware device is not
actually present.

Side note: next to the textual versions, there are also binary versions of the
`modules.alias` and `modules.dep` files. Presumably, those can be queried more
quickly, but for simplicitly, I have not (yet?) implemented support in
`minitrd`.

### 2. Console settings: font, keyboard layout

Setting a legible font is necessary for hi-dpi displays. On my Dell XPS 9360
(3200 x 1800 QHD+ display), the following works well:

```
initrd# setfont latarcyrheb-sun32
```

Setting the user’s keyboard layout is necessary for entering the LUKS full-disk
encryption passphrase in their preferred keyboard layout. I use the [NEO
layout](https://www.neo-layout.org):

```
initrd# loadkeys neo
```

### 3. Block device identification

In the Linux kernel, block device enumeration order is not necessarily the same
on each boot. Even if it was deterministic, device order could still be changed
when users modify their computer’s device topology (e.g. connect a new disk to a
formerly unused port).

Hence, it is good style to refer to disks and their partitions with stable
identifiers. This also applies to boot loader configuration, and so most
distributions will set a kernel parameter such as
`root=UUID=1fa04de7-30a9-4183-93e9-1b0061567121`.

Identifying the block device or partition with the specified `UUID` is the
initramfs’s job.

Depending on what the device contains, the UUID comes from a different
place. For example, `ext4` file systems have a UUID field in their file system
superblock, whereas LUKS volumes have a UUID in their LUKS header.

Canonically, probing a device to extract the UUID is done by `libblkid` from the
`util-linux` package, but the logic can easily be [re-implemented in other
languages](https://github.com/distr1/distri/blob/master/cmd/minitrd/blkid.go)
and changes rarely. `minitrd` comes with its own implementation to avoid
[cgo](https://golang.org/cmd/cgo/) or running the {{< man name="blkid"
section="8" >}} program.

### 4. LUKS full-disk encryption unlocking (only on encrypted systems)

Unlocking a
[LUKS](https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup)-encrypted volume
is done in userspace. The kernel handles the crypto, but reading the metadata,
obtaining the passphrase (or e.g. key material from a file) and setting up the
device mapper table entries are done in user space.

```
initrd# modprobe algif_skcipher
initrd# cryptsetup luksOpen /dev/sda4 cryptroot1
```

After the user entered their passphrase, the root file system can be mounted:

```
initrd# mount /dev/dm-0 /mnt
```

### 5. Continuing the boot process (switch_root)

Now that everything is set up, we need to pass execution to the init program on
the root file system with a careful sequence of {{< man name="chdir" section="2"
>}}, {{< man name="mount" section="2" >}}, {{< man name="chroot" section="2"
>}}, {{< man name="chdir" section="2" >}} and {{< man name="execve" section="2"
>}} system calls that is explained in [this busybox switch_root
comment](https://github.com/mirror/busybox/blob/9ec836c033fc6e55e80f3309b3e05acdf09bb297/util-linux/switch_root.c#L297).

```
initrd# mount -t devtmpfs dev /mnt/dev
initrd# exec switch_root -c /dev/console /mnt /init
```

To conserve RAM, the files in the temporary file system to which the initramfs
archive is extracted are typically deleted.

## How is an initramfs generated?

An initramfs “image” (more accurately: archive) is a compressed
[cpio](https://en.wikipedia.org/wiki/Cpio) archive. Typically, gzip compression
is used, but the kernel supports a bunch of different algorithms and
distributions such as [Ubuntu are switching to lz4](https://www.phoronix.com/scan.php?page=news_item&px=LZ4-Initramfs-Ubuntu-Go-Ahead).

Generators typically prepare a temporary directory and feed it to the {{< man
name="cpio" section="1" >}} program. In `minitrd`, we read the files into memory
and generate the cpio archive using the
[go-cpio](https://github.com/cavaliercoder/go-cpio) package. We use the
[pgzip](https://github.com/klauspost/pgzip) package for parallel gzip
compression.

The following files need to go into the cpio archive:

### minitrd Go userland

The `minitrd` binary is copied into the cpio archive as `/init` and will be run
by the kernel after extracting the archive.

Like the rest of distri, `minitrd` is built statically without cgo, which means
it can be copied as-is into the cpio archive.

### Linux kernel modules

Aside from the `modules.alias` and `modules.dep` metadata files, the kernel
modules themselves reside in e.g. `/lib/modules/5.4.6/kernel` and need to be
copied into the cpio archive.

Copying all modules results in a ≈80 MiB archive, so it is common to only copy
modules that are relevant to the initramfs’s features. This reduces archive size
to ≈24 MiB.

The filtering relies on hard-coded patterns and module names. For example, disk
encryption related modules are all kernel modules underneath `kernel/crypto`,
plus `kernel/drivers/md/dm-crypt.ko`.

When generating a host-only initramfs (works on precisely the computer that
generated it), some initramfs generators look at the currently loaded modules
and just copy those.

### Console Fonts and Keymaps

The `kbd` package’s {{< man name="setfont" section="8" >}} and {{< man
name="loadkeys" section="1" >}} programs load console fonts and keymaps from
`/usr/share/consolefonts` and `/usr/share/keymaps`, respectively.

Hence, these directories need to be copied into the cpio archive. Depending on
whether the initramfs should be generic (work on many computers) or host-only
(works on precisely the computer/settings that generated it), the entire
directories are copied, or only the required font/keymap.

### cryptsetup, setfont, loadkeys

These programs are (currently) required because `minitrd` does not implement
their functionality.

As they are dynamically linked, not only the programs themselves need to be
copied, but also the ELF dynamic linking loader (path stored in the `.interp`
ELF section) and any ELF library dependencies.

For example, `cryptsetup` in distri declares the ELF interpreter
`/ro/glibc-amd64-2.27-3/out/lib/ld-linux-x86-64.so.2` and declares dependencies
on shared libraries `libcryptsetup.so.12`, `libblkid.so.1` and others. Luckily,
in distri, packages contain a `lib` subdirectory containing symbolic links to
the resolved shared library paths (hermetic packaging), so it is sufficient to
mirror the lib directory into the cpio archive, recursing into shared library
dependencies of shared libraries.

`cryptsetup` also requires the GCC runtime library `libgcc_s.so.1` to be present
at runtime, and will abort with an error message about not being able to call
{{< man name="pthread_cancel" section="3" >}} if it is unavailable.

### time zone data

To print log messages in the correct time zone, we copy `/etc/localtime` from
the host into the cpio archive.

## minitrd outside of distri?

I currently have no desire to make `minitrd` available outside of
[distri](https://distr1.org/). While the technical challenges (such as extending
the generator to not rely on distri’s hermetic packages) are surmountable, I
don’t want to support people’s initramfs remotely.

Also, I think that people’s efforts should in general be spent on rallying
behind `dracut` and making it work faster, thereby benefiting all Linux
distributions that use dracut (increasingly more). With `minitrd`, I have
demonstrated that significant speed-ups are achievable.

## Conclusion

It was interesting to dive into how an initramfs really works. I had been
working with the concept for many years, from small tasks such as “debug why the
encrypted root file system is not unlocked” to more complicated tasks such as
“set up a root file system on DRBD for a high-availability setup”. But even with
that sort of experience, I didn’t know all the details, until I was forced to
implement every little thing.

As I suspected going into this exercise, `dracut` is much slower than it needs
to be. Re-implementing its generation stage in a modern language instead of
shell helps a lot.

Of course, my `minitrd` does a bit less than `dracut`, but not drastically
so. The overall architecture is the same.

I hope my effort helps with two things:

1. As a teaching implementation: instead of wading through the various
   components that make up a modern initramfs (udev, systemd, various shell
   scripts, …), people can learn about how an initramfs works in a single place.

2. I hope the significant time difference motivates people to improve `dracut`.

## Appendix: qemu development environment

Before writing any Go code, I did some manual prototyping. Learning how other
people prototype is often immensely useful to me, so I’m sharing my notes here.

First, I copied all kernel modules and a statically built busybox binary:

```
% mkdir -p lib/modules/5.4.6
% cp -Lr /ro/lib/modules/5.4.6/* lib/modules/5.4.6/
% cp ~/busybox-1.22.0-amd64/busybox sh
```

To generate an initramfs from the current directory, I used:

```
% find . | cpio -o -H newc | pigz > /tmp/initrd
```

In distri’s `Makefile`, I append these flags to the `QEMU` invocation:
```
-kernel /tmp/kernel \
-initrd /tmp/initrd \
-append "root=/dev/mapper/cryptroot1 rdinit=/sh ro console=ttyS0,115200 rd.luks=1 rd.luks.uuid=63051f8a-54b9-4996-b94f-3cf105af2900 rd.luks.name=63051f8a-54b9-4996-b94f-3cf105af2900=cryptroot1 rd.vconsole.keymap=neo rd.vconsole.font=latarcyrheb-sun32 init=/init systemd.setenv=PATH=/bin rw vga=836"
```

The `vga=` mode parameter is required for loading font `latarcyrheb-sun32`.

Once in the `busybox` shell, I manually prepared the required mount points and
kernel modules:

```
ln -s sh mount
ln -s sh lsmod
mkdir /proc /sys /run /mnt
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs dev /dev
modprobe virtio_pci
modprobe virtio_scsi
```

As a next step, I copied `cryptsetup` and dependencies into the initramfs directory:

```
% for f in /ro/cryptsetup-amd64-2.0.4-6/lib/*; do full=$(readlink -f $f); rel=$(echo $full | sed 's,^/,,g'); mkdir -p $(dirname $rel); install $full $rel; done
% ln -s ld-2.27.so ro/glibc-amd64-2.27-3/out/lib/ld-linux-x86-64.so.2
% cp /ro/glibc-amd64-2.27-3/out/lib/ld-2.27.so ro/glibc-amd64-2.27-3/out/lib/ld-2.27.so
% cp -r /ro/cryptsetup-amd64-2.0.4-6/lib ro/cryptsetup-amd64-2.0.4-6/
% mkdir -p ro/gcc-libs-amd64-8.2.0-3/out/lib64/
% cp /ro/gcc-libs-amd64-8.2.0-3/out/lib64/libgcc_s.so.1 ro/gcc-libs-amd64-8.2.0-3/out/lib64/libgcc_s.so.1
% ln -s /ro/gcc-libs-amd64-8.2.0-3/out/lib64/libgcc_s.so.1 ro/cryptsetup-amd64-2.0.4-6/lib
% cp -r /ro/lvm2-amd64-2.03.00-6/lib ro/lvm2-amd64-2.03.00-6/
```

In `busybox`, I used the following commands to unlock the root file system:

```
modprobe algif_skcipher
./cryptsetup luksOpen /dev/sda4 cryptroot1
mount /dev/dm-0 /mnt
```
