---
layout: post
title:  "Tracking down a Zsh history data loss bug 🐞"
date:   2026-08-09 10:13:00 +02:00
categories: Artikel
tags:
- debug
---

For many years, I sometimes discovered that commands I was sure I had run were
no longer present in my [Z shell](https://en.wikipedia.org/wiki/Z_shell) history
file (`~/.zsh_history`). In this article, I will show you how I tracked down the
bug. Spoiler: ultimately, patching Zsh to make it crash loudly and analyzing the
crash’s core dump was the winning strategy!

## The good news first {#good-news}

Zsh 5.9.2 (released July 12th, 2026) contains a fix for this issue — open it
*after* reading this investigation to not spoil the fun.

<details>

<summary>Spoiler: link to the upstream fix</summary>

[Zsh fix 53454](https://github.com/zsh-users/zsh/commit/a6760226c75c8a13e78f8b4c7163f1256322531a)

</details>

## The symptom {#symptom}

Occasionally, I noticed that commands I *knew* I executed the day before were
not findable in my shell history, meaning pressing Ctrl+R for backward history
search yielded no results. Whenever I noticed this, my shell history file
contained **only very old** entries, with years of newer entries missing.

The first few times this happened I just restored my shell history from my daily
backup and did not bother investigating any further. But the issue kept happening.

I noticed that there was no visible corruption in the `.zsh_history` (no
non-printable characters or incomplete lines of text), and that the number of
lines in the file was not always the same.

What was not clear to me was whether it was Zsh itself, or some other program,
or perhaps the combination of multiple {{< man name="zsh" section="1" >}}
processes that caused the issue.

## My Zsh history config {#zsh-history-config}

I set the following history-related options in my `~/.zshrc`:

```
# Load 4000 lines of history (for Ctrl+R backward search), but save O(∞)
HISTSIZE=4000
HISTFILE=~/.zsh_history
SAVEHIST=10000000

# Do not save (adjacent) duplicate entries
setopt HIST_IGNORE_DUPS

# Append history entries to `~/.zsh_history` when commands are run.
setopt INC_APPEND_HISTORY
# …but do not share history (enabled by default in NixOS’s /etc/zshrc).
unsetopt SHARE_HISTORY
```

In practice, this means my shells are separate sessions that all stream their
commands into a shared `~/.zsh_history`. The history is intentionally not
shared, so when I want to access entries that another shell wrote, I explicitly
run `exec zsh`.

## Tracing the behavior {#tracing}

When I [asked for help on Mastodon in December
2024](https://mas.to/@zekjur/113646459245348009) (mostly in the hope that
somebody else already encountered and diagnosed this problem), one suggestion I
got was to use file system change monitoring mechanisms like inotify or fsevents
to find the culprit that truncates (or changes?) the Zsh history file.

The next sections walk through the available options on Linux which I tried.

### inotify {#inotify}

The {{< man name="inotify" section="7" >}} Linux kernel subsystem is one of the
oldest file system change monitoring APIs available in Linux (released 2005). To
get a good understanding of how Zsh modifies the history file, it is not
sufficient to monitor just `.zsh_history`:

```
midna ~ % inotifywait --monitor .zsh_history
Setting up watches.
Watches established.
.zsh_history OPEN
.zsh_history ACCESS
.zsh_history ACCESS
[…]
.zsh_history ACCESS
.zsh_history CLOSE_NOWRITE,CLOSE
.zsh_history ATTRIB
.zsh_history CLOSE_WRITE,CLOSE
.zsh_history DELETE_SELF
^C
```

The file is opened, accessed (= read) and then… deleted?!

By monitoring the containing directory, we see the whole picture:

```
midna ~ % inotifywait --monitor ~
/home/michael/ OPEN .zsh_history
/home/michael/ ACCESS .zsh_history
/home/michael/ ACCESS .zsh_history
[…]
/home/michael/ ACCESS .zsh_history
/home/michael/ CLOSE_NOWRITE,CLOSE .zsh_history
/home/michael/ CLOSE_WRITE,CLOSE .zsh_history
/home/michael/ OPEN .zsh_history
/home/michael/ CLOSE_WRITE,CLOSE .zsh_history
/home/michael/ OPEN .zsh_history
/home/michael/ ACCESS .zsh_history
/home/michael/ CLOSE_NOWRITE,CLOSE .zsh_history
/home/michael/ CREATE .zsh_history.new
/home/michael/ OPEN .zsh_history.new
/home/michael/ ATTRIB .zsh_history.new
/home/michael/ MODIFY .zsh_history.new
/home/michael/ CLOSE_WRITE,CLOSE .zsh_history.new
/home/michael/ MOVED_FROM .zsh_history.new
/home/michael/ MOVED_TO .zsh_history
/home/michael/ CLOSE_WRITE,CLOSE .zsh_history
```

So Zsh reads the old history file contents, writes them to a new file, then
renames the new file over the old one, thereby deleting the old one. Now it
makes sense!

Unfortunately, we do not see the process IDs (PIDs) of the responsible process
for the file system event, not even with the sibling utility {{< man
name="fsnotifywait" section="1" >}}, which uses {{< man name="fanotify"
section="7" >}}, an API that does provide this information! I checked, and the
kernel *does send the PID*, but `fsnotifywait` does not display the PID.

### fatrace {#fatrace}

Luckily, there is {{< man name="fatrace" section="8" >}}, which does display the
process name and PID.

Here is what Zsh’s history rewriting looks like with {{< man name="fatrace"
section="8" >}}:

```
zsh(197994): CWO /home/michael/.zsh_history
zsh(197994): O   /home/michael/.zsh_history
zsh(197994): R   /home/michael/.zsh_history
zsh(197994): R   /home/michael/.zsh_history
[…]
zsh(197994): R   /home/michael/.zsh_history
zsh(197994): C   /home/michael/.zsh_history
zsh(197994): +   /home/michael
zsh(197994): O   /home/michael/.zsh_history.new
zsh(197994): W   /home/michael/.zsh_history.new
zsh(197994): W   /home/michael/.zsh_history.new
zsh(197994): W   /home/michael/.zsh_history.new
[…]
zsh(197994): W   /home/michael/.zsh_history.new
zsh(197994): CW  /home/michael/.zsh_history.new
zsh(197994): <>  /home/michael
zsh(197994): CW  (deleted)
zsh(197994): C   /nix/store/80vwnjjgcrbp41pk927r8lzybjhy0k73-zsh-5.9.1/bin/zsh
[…]
```

This gives us the PID, so now we can verify whether multiple processes were
involved in corrupting the shell history. But, we don’t have any insight into
**how much data** each Zsh PID is reading/writing, so even with a `fatrace` log,
it would still not be clear what happened.

### strace {#strace}

Of course, one could use {{< man name="strace" section="1" >}}, in particular
with its `-k` flag, to further look into Zsh behavior, but it seems like a
logistical nightmare to arrange for every (interactive) Zsh process to get a
corresponding strace run, and I was not sure if always-stracing a shell changes
behavior in subtle ways, so I did not pursue the `strace` route.

(Once I had a reproducer, `strace` became easy enough to use and very helpful.)

### bpftrace {#bpftrace}

To get more visibility into Zsh’s read and write operations, we can reach for
{{< man name="bpftrace" section="8" >}}.

To get started, I created the following bpftrace program, which is run on every
{{< man name="open" section="2" >}} syscall and logs which process opened the
`.zsh_history` file, including the user stack trace:

```c
tracepoint:syscalls:sys_enter_open,
tracepoint:syscalls:sys_enter_openat,
tracepoint:syscalls:sys_enter_openat2
/str(args.filename) == "/home/michael/.zsh_history" || str(args.filename) == ".zsh_history"/
{
	printf("%-6d %-16s open(%s)%s", pid, comm, str(args.filename), ustack);
}
```

On NixOS 26.05, I can run the program as follows:

```
midna ~ % nix shell nixpkgs#bpftrace
midna ~ 2 % sudo bpftrace path.bt
Attached 3 probes
212030 zsh              open(/home/michael/.zsh_history)
        __internal_syscall_cancel+142
        __syscall_cancel+20
        __libc_open64+87
        lockhistfile+642
        readhistfile+2213
        zsh_main+1118
        __libc_start_call_main+117
        __libc_start_main_alias_2+136
        _start+37
212030 zsh              open(/home/michael/.zsh_history)
        __internal_syscall_cancel+142
        __syscall_cancel+20
        __libc_open64+87
        _IO_file_open+51
        _IO_file_fopen@@GLIBC_2.2.5+303
        __fopen_internal+134
        readhistfile+2277
        zsh_main+1118
        __libc_start_call_main+117
        __libc_start_main_alias_2+136
        _start+37
212030 zsh              open(/home/michael/.zsh_history)
        __internal_syscall_cancel+142
        __syscall_cancel+20
        __libc_open64+87
        lockhistfile+642
        savehistfile+165
        zexit+204
        zsh_main+1522
        __libc_start_call_main+117
        __libc_start_main_alias_2+136
        _start+37
212030 zsh              open(/home/michael/.zsh_history)
        __internal_syscall_cancel+142
        __syscall_cancel+20
        __libc_open64+87
        savehistfile+752
        zexit+204
        zsh_main+1522
        __libc_start_call_main+117
        __libc_start_main_alias_2+136
        _start+37
212030 zsh              open(/home/michael/.zsh_history)
        __internal_syscall_cancel+142
        __syscall_cancel+20
        __libc_open64+87
        _IO_file_open+51
        _IO_file_fopen@@GLIBC_2.2.5+303
        __fopen_internal+134
        readhistfile+2277
        savehistfile+2498
        zexit+204
        zsh_main+1522
        __libc_start_call_main+117
        __libc_start_main_alias_2+136
        _start+37
^C

```

Encouraged by this early success, I extended the program as follows to cover more system calls:

<details>

<summary>Full <code>zshhisttrace.bt</code> bpftrace code</summary>

```c
#!/usr/bin/bpftrace
#include <fcntl.h>
#include <limits.h>

tracepoint:syscalls:sys_enter_open /comm == "zsh"/ {
     printf("%s(%d) open: %s flags %x mode %x\n", comm, pid, str(args->filename), args->flags, args->mode);
}

tracepoint:syscalls:sys_enter_openat {
     if (!strcontains(str(args->filename), "zsh_history")) {
         delete(@openfn[tid]);
         return;
     }
     @openfn[tid] = 1;
     printf("%s(%d) openat: ", comm, pid);
     if (args->dfd < 0x7fffffff) { /* ought to be != AT_FDCWD, but that does not work !?!? */
         printf("[at fd %d]", args->dfd);
     }
     printf("%s flags %x mode %x\n", str(args->filename), args->flags, args->mode);
}

tracepoint:syscalls:sys_exit_openat /@openfn[tid]/ {
     @reads[tid,(int64)args->ret] = 1; // TODO: bpftrace 0.22 introduces has_key
     @writes[tid,(int64)args->ret] = 1; // TODO: bpftrace 0.22 introduces has_key
}

tracepoint:syscalls:sys_enter_close /@reads[tid,(int64)args->fd]/ {
     printf("%s(%d) close %d (reads: %d, writes: %d)\n", comm, pid, args->fd, @reads[tid,(int64)args->fd]-1, @writes[tid,(int64)args->fd]-1);
     delete(@reads[tid,(int64)args->fd]);
     delete(@writes[tid,(int64)args->fd]);
}

// tracepoint:syscalls:sys_enter_openat2 /comm == "zsh"/ {
//      printf("%s(%d) openat: ", comm, pid);
//      if (args->dfd < INT_MAX) { /* ought to be != AT_FDCWD, but that does not work !?!? */
//          printf("[at fd %d]", args->dfd);
//      }
//      printf("%s \n", str(args->filename));
// }

tracepoint:syscalls:sys_enter_rename /comm == "zsh"/ {
     printf("%s(%d) rename:", comm, pid);
     printf("%s -> %s\n", str(args->oldname), str(args->newname));
}

tracepoint:syscalls:sys_enter_symlink /comm == "zsh"/ {
     printf("%s(%d) symlink ", comm, pid);
     printf("%s -> %s\n", str(args->oldname), str(args->newname));
}

tracepoint:syscalls:sys_enter_unlink /comm == "zsh"/ {
     printf("%s(%d) unlink ", comm, pid);
     printf("%s\n", str(args->pathname));
}

tracepoint:syscalls:sys_enter_unlinkat /comm == "zsh"/ {
     printf("%s(%d) unlinkat ", comm, pid);
     printf("%s\n", str(args->pathname));
}

tracepoint:syscalls:sys_enter_lseek /comm == "zsh"/ {
     printf("%s(%d) lseek fd %d offset %d whence %d\n", comm, pid, args->fd, args->offset, args->whence);
}

tracepoint:syscalls:sys_enter_read /@reads[tid,(int64)args->fd]/ {
     // printf("%s(%d) read fd %d size %d\n", comm, pid, args->fd, args->count);
     @reads[tid,(int64)args->fd] += args->count;
}

tracepoint:syscalls:sys_exit_read /comm == "zsh"/ {
     if (args->ret <= 0) {
          printf("%s(%d) read = %d\n", comm, pid, args->ret);
     }
}

tracepoint:syscalls:sys_exit_write /comm == "zsh"/ {
     if (args->ret <= 0) {
          printf("%s(%d) write = %d\n", comm, pid, args->ret);
     }
}

tracepoint:syscalls:sys_enter_write /@writes[tid,(int64)args->fd]/ {
     // printf("%s(%d) write fd %d size %d\n", comm, pid, args->fd, args->count);
     @writes[tid,(int64)args->fd] += args->count;
}
```

</details>

In case you want to dive deeper into bpftrace, here are a few resources I found useful:

* The [upstream bpftrace docs](https://bpftrace.org/docs/0.21)
* The blog post [“First steps in system-wide Linux tracing” by Martin Pitt (2020)](https://piware.de/post/2020-02-28-bpftrace/)
* The LSFMM presentation [“BPF Observability” by Brendan Gregg (2019)](https://www.brendangregg.com/Slides/LSFMM2019_BPF_Observability.pdf)

I created a systemd unit to run this program in the background permanently
(seems cheap enough), meaning I can check the logs like so:

```
midna % journalctl -fu zshhisttrace
cp(2338700) close 3 (reads: 3407872, writes: 0)
zsh(231222) symlink /pid-231222/host-midna -> /home/michael/.zsh_history.LOCK
zsh(231222) openat: /home/michael/.zsh_history flags 541 mode 180
zsh(231222) close 3 (reads: 0, writes: 0)
zsh(231222) openat: /home/michael/.zsh_history flags 0 mode 0
zsh(231222) lseek fd 3 offset 0 whence 1
zsh(231222) read = 0
zsh(231222) close 3 (reads: 52895744, writes: 0)
zsh(231222) unlink /home/michael/.zsh_history.new
zsh(231222) openat: /home/michael/.zsh_history.new flags c1 mode 180
zsh(231222) close 3 (reads: 0, writes: 52888907)
zsh(231222) rename:/home/michael/.zsh_history.new -> /home/michael/.zsh_history
zsh(231222) unlink /home/michael/.zsh_history.LOCK
```

One day, I noticed my shell history was truncated and checked the logs. This is
what I found. Note how there is no `read = 0` line, i.e. Zsh does not read until
EOF:

```
zsh(231233) symlink /pid-231233/host-midna -> /home/michael/.zsh_history.LOCK
zsh(231233) openat: /home/michael/.zsh_history flags 541 mode 180
zsh(231233) close 3 (reads: 0, writes: 0)
zsh(231233) openat: /home/michael/.zsh_history flags 0 mode 0
zsh(231233) lseek fd 3 offset 0 whence 1
zsh(231233) lseek fd 3 offset 0 whence 1
zsh(231233) lseek fd 3 offset 11572944 whence 0
zsh(231233) close 3 (reads: 11575296, writes: 0)
zsh(231233) unlink /home/michael/.zsh_history.new
zsh(231233) openat: /home/michael/.zsh_history.new flags c1 mode 180
zsh(231233) close 3 (reads: 0, writes: 11572944)
zsh(231233) rename:/home/michael/.zsh_history.new -> /home/michael/.zsh_history
zsh(231233) unlink /home/michael/.zsh_history.LOCK
```

## Making it crash! {#making-it-crash}

From the bpftrace output above we know that Zsh is rewriting my
`.zsh_history` file incorrectly: it reads fewer lines than usual, and then
correctly writes them to `.zsh_history.new`.

At this point I decided to study the code for reasons why `readhistfile` would
not read the full history file or why `savehistfile` would not write the full history file.

The [control flow of
`savehistfile`](https://github.com/zsh-users/zsh/blob/zsh-5.9.1/Src/hist.c#L2899)
is pretty hard to follow, but it is easy to modify the code (zsh-5.9.1) such
that it crashes after it writes a `.zsh_history.new` with fewer than 50000 lines
and before it replaces my `.zsh_history` with that truncated new file:

```diff
--- i/Src/hist.c
+++ w/Src/hist.c
@@ -2994,6 +2994,7 @@ savehistfile(char *fn, int err, int writeflags)
     if (out) {
 	char *history_ignore;
 	Patprog histpat = NULL;
+	int lines_written = 0;
 
 	pushheap();
 
@@ -3048,6 +3049,7 @@ savehistfile(char *fn, int err, int writeflags)
 		ret = fputc(' ', out);
 	    if (ret < 0 || (ret = fputc('\n', out)) < 0)
 		break;
+	    lines_written++;
 	}
 	if (ret >= 0 && start && writeflags & HFILE_USE_OPTIONS) {
 	    struct stat sb;
@@ -3062,6 +3064,10 @@ savehistfile(char *fn, int err, int writeflags)
 	}
 	if (fclose(out) < 0 && ret >= 0)
 	    ret = -1;
+	if (tmpfile && lines_written < 50000) {
+	    char *crashptr = (char*)0x23;
+	    *crashptr = 42;
+	}
 	if (ret >= 0) {
 	    if (tmpfile) {
 		if (rename(tmpfile, unmeta(fn)) < 0) {
```

On Linux, the easiest way to ensure such a crash ends up somewhere useful is to
install {{< man name="systemd-coredump" section="8" >}}, after which systemd
will automatically collect core dumps. You can use {{< man name="coredumpctl"
section="1" >}} to list and work with them. Note that these core dumps contain
your shell history, so do not upload them to third-party services. Fedora’s
[ABRT seems to only send micro
reports](https://abrt.readthedocs.io/en/latest/howitworks.html) (i.e. without
your full shell history), and Ubuntu’s [Apport is
disabled-by-default](https://ubuntu.com/project/docs/contributors/debugging/apport/),
but it’s worth double-checking.

I installed my patched version of Zsh (with debug symbols enabled) and deferred
further investigation until I had a core dump of the issue in action. Sure
enough, when I checked with `coredumpctl` a few days later, I saw a crash! This
was the backtrace:

```
midna % coredumpctl debug
gdb $ bt full
#0  0x000056040d781e19 in savehistfile (fn=0x56040f7a76b0 "/home/michael/.zsh_history", err=1, writeflags=0) at hist.c:3086
        crashptr = 0x23 <error: Cannot access memory at address 0x23>
        history_ignore = 0x0
        histpat = 0x0
        lines_written = 45546
        t = 0x5604102a1f59 ""
        tmpfile = 0x5604100ec210 "/home/michael/.zsh_history.new"
        start = 0x5604102a1f40 "make -j32"
        out = 0x56040f939400
        he = 0x0
        xcurhist = 45546
        extended_history = 0
        ret = 10
#1  0x000056040d781f72 in savehistfile (fn=0x56040f7a76b0 "/home/michael/.zsh_history", err=1, writeflags=32771) at hist.c:3121
        remember_histactive = 0
        history_ignore = 0x0
        histpat = 0x0
        lines_written = 0
        t = 0x0
        tmpfile = 0x0
        start = 0x0
        out = 0x56040f939400
        he = 0x0
        xcurhist = 51183
        extended_history = 0
        ret = 0
#2  0x000056040d751197 in zexit (val=0, from_where=ZEXIT_NORMAL) at builtin.c:6055
        writeflags = 32768
#3  0x000056040d7888e2 in zsh_main (argc=2, argv=0x7ffd370c1758) at init.c:1950
        errexit = 0
        t = 0x7ffd370c1768
        runscript = 0x0
        zsh_name = 0x7ffd370c26bd "zsh"
        cmd = 0x0
        t0 = 162
#4  0x000056040d735d89 in main (argc=2, argv=0x7ffd370c1758) at ./main.c:93
No locals.
```

I returned to the source and realized that most likely, `savehistfile` is just
writing out a shorter history file because `readhistfile` left it a shorter
history!

The [control flow of
`readhistfile`](https://github.com/zsh-users/zsh/blob/zsh-5.9.1/Src/hist.c#L2653)
is easier to follow. Reading through the function, there is one possibility of
an early return: [when Zsh receives a signal](https://github.com/zsh-users/zsh/blob/zsh-5.9.1/Src/hist.c#L2825-L2829),
the read loop is aborted via a `break;`:

```c
	// …
	if (errflag & ERRFLAG_INT) {
		/* Can't assume fast read next time if interrupted. */
		lasthist.interrupted = 1;
		break;
	}
	// …
```

Let’s see what `errflag` and `lasthist.interrupted` contain in our crash:

```
gdb $ p errflag
$1 = 2
gdb $ p lasthist.interrupted
$2 = 1
```

Bingo! So some signal must be involved.

For reasons outside of the scope of this article, I am using a mosh session from
which I am starting a long-running SSH session, over which I multiplex further
sessions. When tearing down this setup at the end of each workday, I press
Ctrl+D in the multiplexed sessions (sends EOF, exits the session), then Ctrl+C
on the long-running SSH, then Ctrl+D to exit the mosh session.

(If you don’t cleanly exit a mosh session, it sticks around on the server and
subsequent logins tell you about these orphaned sessions. I wanted to avoid
accumulating orphaned sessions.)

So in practice I press Ctrl+D, Ctrl+C, Ctrl+D, Ctrl+C etc. until all windows are
gone. As part of that sequence, most likely I am exiting a Zsh session (Ctrl+D)
and then interrupting (Ctrl+C) its `readhistfile` if history rewriting takes
long enough.

With these clues, I built a standalone reproducer and [sent a bug report to the
zsh-workers mailing list in March
2025](https://www.zsh.org/mla/workers/2025/msg00114.html). Bart Schaefer looked
into it and posted [a fix in April
2025](https://www.zsh.org/mla/workers/2025/msg00156.html) (thank you!).

It took a long time for the fix to actually be released because there was a long
time without any Zsh releases. And then, when the 5.9.1 release happened, it
turns out Bart’s fix was missed by the release engineer! I pointed out this
oversight, and Zsh 5.9.2 thankfully includes the fix.

I have been running Zsh 5.9 with Bart’s patch applied, and will keep that
version pinned until 5.9.2 lands on my computers. If you’re pinning zsh on
Debian, pin both, the `zsh` and `zsh-common` packages. Otherwise, you might end
up with no `zsh` package at all one day…

## What was the bug? {#bug-root-cause}

When exiting, `zexit` calls `savehistfile` to compact the history: during a
session, history entries are appended incrementally, but at shell exit, the
history file gets compacted (to apply a size limit, if configured, for example),
so `savehistfile` reads the entire history (`readhistfile`) and writes it out
again.

`readhistfile` could be interrupted when a signal fires (it checks `errflag &
ERRFLAG_INT` and short-circuits its read loop), but `savehistfile` did not check
for interruption when writing the shell history when exiting. Therefore,
`savehistfile` wrote the (incomplete) history, truncating the actual history.

Let’s decipher the `bpftrace` output we collected earlier:

```
zsh(231233) openat: /home/michael/.zsh_history flags 0 mode 0
zsh(231233) lseek fd 3 offset 0 whence 1

# […] reads are aggregated, see below […]
# […] interrupt happens here […]

# lseek(3, 0, SEEK_CUR) = query the current seek offset
zsh(231233) lseek fd 3 offset 0 whence 1
# SEEK_SET at fclose(), as POSIX mandates (see below)
zsh(231233) lseek fd 3 offset 11572944 whence 0

zsh(231233) close 3 (reads: 11575296, writes: 0)
zsh(231233) unlink /home/michael/.zsh_history.new
zsh(231233) openat: /home/michael/.zsh_history.new flags c1 mode 180
zsh(231233) close 3 (reads: 0, writes: 11572944)
zsh(231233) rename:/home/michael/.zsh_history.new -> /home/michael/.zsh_history
```

Why the lseek? From [POSIX.1-2017 on fclose()](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fclose.html)

> If the file is not already at EOF, and the file is one capable of seeking, the
> file offset of the underlying open file description shall be set to the file
> position of the stream if the stream is the active handle to the underlying
> file description.

Zsh uses `fopen()` to get a stream, so glibc reads in chunks of 4096 bytes and
when closing the stream, the underlying file descriptor needs to be sought back
so that the already-read parts of the current 4096-byte chunk will be read
again, correctly by the next stream. (Zsh closes the file immediately, so the
seek is pointless, but glibc cannot know.)

## Conclusion {#conclusion}

It’s remarkable that a bug like this one, which causes *data loss*, can remain
unfixed for 10 years in a popular shell (did you know? Apple switched macOS’s
default login shell to Zsh in 2019).

Granted, most users probably don’t share my habit of killing shell sessions in a
way that makes it likely that `SIGINT` is sent, but I have to imagine that *some
users* have lost parts of their history.

I am very glad that this issue is now fixed! If you are also encountering
history file truncation, and it isn’t the issue I described in this article,
maybe you managed to accidentally export `HISTFILE`? See appendix A for a
`HISTFILE` bonus footgun that I ran into a few years before.

Another obvious question that came up as I was writing this post: I tracked down
this issue before LLMs got impressively good at coding and problem
solving. Would today’s AI coding agents be able to find this bug? See appendix B
for details, but the answer is: Yes, today’s frontier models can find this bug!

## Appendix A: Bonus Footgun: exported HISTFILE {#appendix-a}

When you use Emacs’s [TRAMP mode](https://wikemacs.org/wiki/TRAMP), by default
it exports `HISTFILE`. For example, when using `M-x shell` after starting `emacs
/ssh:keep:/srv/keep`, I see `HISTFILE` in the environment:

```
/ssh:keep:/srv/keep/ #$ env | grep HISTFILE
HISTFILE=/home/michael/.tramp_history
/ssh:keep:/srv/keep/ #$
```

This is a footgun, because most shell configs don’t unexport `HISTFILE`, they
only change it. For example, in my `~/.zshrc`, I set `HISTFILE=~/.zsh_history`.

When running an interactive shell (by typing `zsh` followed by Enter), I end up
with `HISTFILE` in the environment:

```
/ssh:keep:/srv/keep/ #$ zsh
locale: Cannot set LC_CTYPE to default locale: No such file or directory
$ env | grep HISTFILE
HISTFILE=/home/michael/.zsh_history
$
```

…which is not the case when I use {{< man name="ssh" section="1" >}} to log in:

```
midna ~ % ssh keep
Last login: Sat Aug  1 17:38:37 2026 from 100.64.1.1
keep ~ % env | grep HISTFILE
keep ~ %
```

Exporting a shell-specific `HISTFILE` is a footgun on machines where other
shells are configured with other (default) settings. On my work computer, where
the Linux installation sets `HISTSIZE=64000` and `HISTFILESIZE=64000` for `bash`
by default, I once inadvertently truncated my `~/.zsh_history` file to 64000
lines. My suspicion is that it was by running `M-x shell`, then `zsh` (to get my
config), then `bash` (temporarily, to source a config and launch a script).

To prevent such issues in the future, I decided to [actively unexport `HISTFILE`
in my
`~/.zshrc`](https://github.com/stapelberg/configfiles/commit/32dcda0f49ab619592068bf911ffbecc391c8b34).

## Appendix B: Bonus Question: Can AI find this bug? {#appendix-b}

For a while now, I felt that it would be useful to get my hands dirty with
creating my own evals. See [Anthropic’s “Demystifying evals for AI
agents”](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
if you are unfamiliar with the term “eval”.

I started with [Simon Willison’s
smevals](https://primeradiant.com/blog/2026/smevals.html), but found it to be
too minimalistic: without taking extra measures, agents would quickly escape
their eval task and peek at the solution, or use the internet to discover that
the Zsh git version has this bug already fixed.

I ended up with [Inspect, an open-source eval
framework](https://inspect.aisi.org.uk/) by the UK AI Security Institute and
Meridian Labs, and it worked better, though its web UI is very minimalistic.

This eval quickly got very expensive! I paid well over 300 USD in token cost for
about 3 attempts at this eval. The results below are from the latest attempt. A
passing grade is awarded when the model explains the correct sequence of events:
an interrupt sets errflag, which aborts `readhistfile` and results in a
truncated history file.

### Eval setup: symptom + bpftrace {#ai-eval}

<details>

<summary>Full prompt, including normal/truncated bpftrace</summary>

> when i log out, sometimes when i come back the next day my .zsh_history file is mysteriously truncated. why might that be?
>
> I'm on zsh 5.9.1 on Linux. Only zsh ever writes this file. I have a bpftrace
> program logging every syscall zsh makes against the history file.
>
> A NORMAL logout looks like this:
>
>     zsh(231222) symlink /pid-231222/host-midna -> /home/michael/.zsh_history.LOCK
>     zsh(231222) openat: /home/michael/.zsh_history flags 541 mode 180
>     zsh(231222) close 3 (reads: 0, writes: 0)
>     zsh(231222) openat: /home/michael/.zsh_history flags 0 mode 0
>     zsh(231222) lseek fd 3 offset 0 whence 1
>     zsh(231222) read = 0
>     zsh(231222) close 3 (reads: 52895744, writes: 0)
>     zsh(231222) unlink /home/michael/.zsh_history.new
>     zsh(231222) openat: /home/michael/.zsh_history.new flags c1 mode 180
>     zsh(231222) close 3 (reads: 0, writes: 52888907)
>     zsh(231222) rename:/home/michael/.zsh_history.new -> /home/michael/.zsh_history
>     zsh(231222) unlink /home/michael/.zsh_history.LOCK
>
> A logout that TRUNCATED the file looks like this:
>
>     zsh(231233) symlink /pid-231233/host-midna -> /home/michael/.zsh_history.LOCK
>     zsh(231233) openat: /home/michael/.zsh_history flags 541 mode 180
>     zsh(231233) close 3 (reads: 0, writes: 0)
>     zsh(231233) openat: /home/michael/.zsh_history flags 0 mode 0
>     zsh(231233) lseek fd 3 offset 0 whence 1
>     zsh(231233) lseek fd 3 offset 0 whence 1
>     zsh(231233) lseek fd 3 offset 11572944 whence 0
>     zsh(231233) close 3 (reads: 11575296, writes: 0)
>     zsh(231233) unlink /home/michael/.zsh_history.new
>     zsh(231233) openat: /home/michael/.zsh_history.new flags c1 mode 180
>     zsh(231233) close 3 (reads: 0, writes: 11572944)
>     zsh(231233) rename:/home/michael/.zsh_history.new -> /home/michael/.zsh_history
>     zsh(231233) unlink /home/michael/.zsh_history.LOCK
>
> my zshrc is in ./zshrc — the exact config in effect on the affected
> machine, so you can see which options are (and aren't) enabled.
>
> The full zsh 5.9.1 source tree is available in ./zsh-5.9.1 — this is exactly
> the version I'm running. Dig into it as much as you need.
> 
> What's going on, and what in the zsh source would cause it?
> 
> Work only from the zsh 5.9.1 source provided and the evidence above. Do not
> consult newer zsh versions, upstream commits, mailing-list threads, changelogs
> or release notes — the point is to derive the cause from this source, not to
> look up how it was later fixed.
> 
> End your reply with a section headed exactly `## Diagnosis` containing
> your final answer: the root cause, and the specific code responsible.

</details>


| score     | model                                          | tokens     | duration |
|-----------|------------------------------------------------|------------|----------|
| ✅ 3 of 3 | openai/gpt-5.6-sol                             | 497,040    | 2m 29s   |
| ✅ 3 of 3 | anthropic/claude-opus-5                        | 5,440,676  | 26m 43s  |
| ⚠️ 2 of 3  | openai/gpt-5.5                                 | 659,050    | 2m 43s   |
| ⚠️ 1 of 3  | openai/gpt-5.6-terra                           | 673,336    | 1m 57s   |
| ⚠️ 1 of 3  | google/gemini-3.1-pro-preview                  | 3,733,226  | 9m 31s   |
| ⚠️ 1 of 3  | anthropic/claude-sonnet-5                      | 9,323,989  | 29m 18s  |
| ⚠️ 1 of 3  | google/gemini-3.5-flash                        | 6,746,305  | 12m 38s  |
| ⚠️ 1 of 3  | moonshotai/kimi-k3 (open weight!) @ medium     | 2,455,874  | 45m 6s   |
| ⚠️ 1 of 3  | moonshotai/kimi-k3 (open weight!) @ high       | 13,060,937 | 52m 2s   |
| ⚠️ 1 of 3  | google/gemini-3-flash-preview                  | 19,370,711 | 30m 14s  |
| ❌        | openai/gpt-5.1                                 | 118,948    | 1m 12s   |
| ❌        | openai/gpt-5.4                                 | 286,288    | 1m 10s   |
| ❌        | openai/gpt-5.6-luna                            | 549,724    | 1m 14s   |
| ❌        | qwen/qwen3-coder                               | 623,110    | 5m 2s    |
| ❌        | openai/gpt-5.2                                 | 1,306,586  | 1m 49s   |
| ❌        | openai/gpt-5                                   | 2,858,548  | 7m 14s   |
| ❌        | anthropic/claude-opus-4-8                      | 3,402,954  | 9m 5s    |
| ❌        | deepseek/deepseek-v4-flash-0731 (open weight!) | 5,570,798  | 25m 6s   |
| ❌        | google/gemini-3.1-flash-lite                   | 6,945,359  | 2m 7s    |
| ❌        | qwen/qwen3.8-max (open weight!)                | 6,307,959  | 39m 32s  |
| ❌        | deepseek/deepseek-v4-pro (open weight!)        | 8,577,105  | 30m 7s   |
| ❌        | anthropic/claude-haiku-4-5                     | 10,646,235 | 7m 24s   |
| ❌        | qwen/qwen3.6-max-preview                       | 19,689,360 | 27m 12s  |
| ❌        | minimax/minimax-m3 (open weight!)              | 19,937,971 | 46m 28s  |
| ❌        | z-ai/glm-5.2 (open weight!)                    | 21,507,452 | 29m 30s  |

### Eval variant: habit-hinted {#habit-hinted}

In this iteration, I am including this hint about pressing Ctrl+C and Ctrl+D
repeatedly, which is a nudge towards signals and interrupt handling:

> fwiw, my logout habit: i press ctrl+c / ctrl+d repeatedly until all my
> terminal windows are gone, and then see what's left.

This measures how easily the models understand the problem, if at all.

| score     | model                                          | tokens     | duration |
|-----------|------------------------------------------------|------------|----------|
| ✅ 3 of 3 | openai/gpt-5.6-sol                             | 393,895    | 1m 43s   |
| ✅ 3 of 3 | openai/gpt-5.5                                 | 622,081    | 1m 31s   |
| ✅ 3 of 3 | anthropic/claude-opus-5                        | 1,583,601  | 7m 29s   |
| ✅ 3 of 3 | anthropic/claude-opus-4-8                      | 2,338,905  | 6m 4s    |
| ✅ 3 of 3 | anthropic/claude-sonnet-5                      | 3,132,322  | 14m 9s   |
| ✅ 3 of 3 | moonshotai/kimi-k3 @ medium (open weight!)     | 4,642,764  | 32m 25s  |
| ✅ 3 of 3 | moonshotai/kimi-k3 @ high (open weight!)       | 9,631,629  | 32m 17s  |
| ✅ 3 of 3 | z-ai/glm-5.2 (open weight!)                    | 23,654,094 | 22m 37s  |
| ⚠️ 2 of 3  | openai/gpt-5                                   | 2,345,526  | 3m 38s   |
| ⚠️ 2 of 3  | google/gemini-3-flash-preview                  | 6,421,624  | 16m 41s  |
| ⚠️ 2 of 3  | google/gemini-3.5-flash                        | 3,571,679  | 9m 7s    |
| ⚠️ 2 of 3  | qwen/qwen3.8-max (open weight!)                | 4,289,195  | 41m 49s  |
| ⚠️ 1 of 3  | openai/gpt-5.6-luna                            | 426,974    | 1m 26s   |
| ⚠️ 1 of 3  | openai/gpt-5.6-terra                           | 728,604    | 1m 31s   |
| ⚠️ 1 of 3  | google/gemini-3.1-pro-preview                  | 3,525,585  | 6m 23s   |
| ⚠️ 1 of 3  | deepseek/deepseek-v4-flash-0731 (open weight!) | 3,628,997  | 25m 37s  |
| ⚠️ 1 of 3  | deepseek/deepseek-v4-pro (open weight!)        | 7,751,190  | 30m 4s   |
| ❌        | openai/gpt-5.4                                 | 266,719    | 45s      |
| ❌        | openai/gpt-5.1                                 | 287,721    | 1m 9s    |
| ❌        | openai/gpt-5.2                                 | 1,097,940  | 1m 30s   |
| ❌        | qwen/qwen3-coder (open weight!)                | 1,160,681  | 8m 31s   |
| ❌        | anthropic/claude-haiku-4-5                     | 5,663,995  | 5m 47s   |
| ❌        | google/gemini-3.1-flash-lite                   | 5,839,696  | 1m 39s   |
| ❌        | minimax/minimax-m3 (open weight!)              | 10,733,126 | 27m 25s  |
| ❌        | qwen/qwen3.6-max-preview                       | 13,322,764 | 30m 4s   |

### AI Conclusion {#ai-conclusion}

Latest frontier models like Claude Opus 5 or GPT 5.6 Sol can find the bug
reliably with just a description of the symptom and a working/failing
bpftrace. If you try it a couple of times, you can also get there with the
Gemini models. Of the Open Weight models, only Kimi K3 can find this bug without
hinting.

Once the Ctrl+C + Ctrl+D habit is included in the prompt, more frontier models
reliably find the issue (including Claude Sonnet 5!). Of the Open Weight models,
GLM 5.2 and Kimi K3 are the first ones to reliably figure out the issue! If you
try it a couple of times, you can also get there with the Gemini or DeepSeek
models. I could not get Qwen or Minimax models to pass.

This seems like a really nice eval, in particular for tracking which Open Weight
model *actually* works as well as Opus or GPT (at least in this one specific
regard). For now, Kimi K3 seems like the most capable Open Weight model, even
though it cannot reliably diagnose this issue. GLM 5.2 is much smaller and —
with hints — can at least make sense of the issue.

It is interesting to note that almost all models *considered* the correct
hypothesis, including the Qwen and Minimax models. Only Gemini 3.1 Flash Lite
never articulated the correct hypothesis, presumably because it is a small model
(in comparison).

So where did the models go wrong? In verifying/falsifying theories! For example,
GLM 5.2 assumes the `lseek` in the `bpftrace` output *must mean* that
`SHAREHISTORY` is set (it isn’t!):

> glm-5.2 enumerated exactly three causes of a short read — corruption,
> `HFILE_FAST` searching, `errflag & ERRFLAG_INT` — then ruled out the interrupt
> because "Options 1 and 3 don't involve lseek to a non-zero offset. But the
> trace shows `lseek(offset, SEEK_SET)`, which is `HFILE_FAST` behavior. So
> `SHAREHISTORY` must be set" — overriding your `zshrc`'s `unsetopt
> SHARE_HISTORY` to keep the elimination alive.

I verified that by making the eval use more orchestration (have one subagent
produce theories, another keep track and falsify / verify, etc.), the success
rate increases. Similarly, I expect that by varying the prompt and harness,
individual models can be made to work much better.

The most common failure mode seems to be that the model picks the wrong theory
and gets stuck on verifying it, never returning to the other theories. Perhaps
the better performing models have the better methodology, in that they adhere
better to the scientific method?
