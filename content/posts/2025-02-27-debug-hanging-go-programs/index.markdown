---
layout: post
title:  "Tips to debug hanging Go programs"
date:   2025-02-27 17:51:38 +01:00
categories: Artikel
tags:
- golang
- rsync
- debug
---

I was helping someone get my [gokrazy/rsync](https://github.com/gokrazy/rsync)
implementation set up to synchronize [RPKI
data](https://en.wikipedia.org/wiki/Resource_Public_Key_Infrastructure) (used
for securing BGP routing infrastructure), when we discovered that with the right
invocation, my rsync receiver would just hang indefinitely.

This was a quick problem to solve, but in the process, I realized that I should
probably write down a few Go debugging tips I have come to appreciate over the
years!

## Scenario: hanging Go program

If you want to follow along, you can reproduce the issue by building an older
version of gokrazy/rsync, just before the bug fix commit (you’ll need [Go 1.22
or newer](https://go.dev/dl/)):

```
git clone https://github.com/gokrazy/rsync
cd rsync
git reset --hard 6c89d4dda3be055f19684c0ed56d623da458194e^
go install ./cmd/...
```

Now we can try to sync the repository:

```
% gokr-rsync \
  -rtO \
  --delete \
  rsync://rsync.paas.rpki.ripe.net/repository/ \
  /tmp/rpki-repo
[…]
2025/02/08 09:35:10 Opening TCP connection to rsync.paas.rpki.ripe.net:873
2025/02/08 09:35:10 rsync module "repo", path "repo/"
2025/02/08 09:35:10 (Client) Protocol versions: remote=31, negotiated=27
2025/02/08 09:35:10 Client checksum: md4
2025/02/08 09:35:10 sending daemon args: [--server --sender -tr . repo/]
2025/02/08 09:35:10 exclusion list sent
2025/02/08 09:35:10 receiving file list
2025/02/08 09:35:11 [Receiver] i=0 ? . mode=40755 len=4096 uid=0 gid=0 flags=?
[…]
2025/02/08 09:35:11 [Receiver] i=89 ? clonoth/1/3139332e33322e3130302e302f32342d3234203d3e203537313936.roa mode=100644 len=1747 uid=0 gid=0 flags=?
```

…and then the program just sits there.

## Tip 1: Press Ctrl+\ (SIGQUIT) to print a stack trace {#sigquit-stack-trace}

The easiest way to look at where a Go program is hanging is to press `Ctrl+\`
(backslash) to [make the terminal send it a `SIGQUIT`
signal](https://en.wikipedia.org/wiki/Signal_(IPC)#SIGQUIT). When the Go runtime
receives `SIGQUIT`, it prints a stack trace to the terminal before exiting the
process. This behavior is enabled by default and can be customized via the
`GOTRACEBACK` environment variable, see the [`runtime` package
docs](https://pkg.go.dev/runtime).

Here is what the output looks like in our case. I have made the font small so
that you can recognize the shape of the output (the details are not important,
continue reading below):

<div style="font-size: 60%">

```
^\SIGQUIT: quit
PC=0x47664e m=0 sigcode=128

goroutine 0 gp=0x6e6020 m=0 mp=0x6e6ec0 [idle]:
internal/runtime/syscall.Syscall6()
	/home/michael/sdk/go1.23.0/src/internal/runtime/syscall/asm_linux_amd64.s:36 +0xe fp=0x7ffc58665090 sp=0x7ffc58665088 pc=0x47664e
internal/runtime/syscall.EpollWait(0x586651e0?, {0x7ffc5866511c?, 0x3000000018?, 0x7ffc586651f0?}, 0x58665110?, 0x7ffc?)
	/home/michael/sdk/go1.23.0/src/internal/runtime/syscall/syscall_linux.go:32 +0x45 fp=0x7ffc586650e0 sp=0x7ffc58665090 pc=0x4765e5
runtime.netpoll(0xc0000000c0?)
	/home/michael/sdk/go1.23.0/src/runtime/netpoll_epoll.go:116 +0xd2 fp=0x7ffc58665768 sp=0x7ffc586650e0 pc=0x432332
runtime.findRunnable()
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:3580 +0x8c5 fp=0x7ffc586658e0 sp=0x7ffc58665768 pc=0x43f045
runtime.schedule()
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:3995 +0xb1 fp=0x7ffc58665918 sp=0x7ffc586658e0 pc=0x4405b1
runtime.park_m(0xc0000061c0)
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:4102 +0x1eb fp=0x7ffc58665970 sp=0x7ffc58665918 pc=0x4409cb
runtime.mcall()
	/home/michael/sdk/go1.23.0/src/runtime/asm_amd64.s:459 +0x4e fp=0x7ffc58665988 sp=0x7ffc58665970 pc=0x470e2e

goroutine 1 gp=0xc0000061c0 m=nil [IO wait]:
runtime.gopark(0x452658?, 0x0?, 0x98?, 0xb3?, 0xb?)
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:424 +0xce fp=0xc0000eb358 sp=0xc0000eb338 pc=0x46bc0e
runtime.netpollblock(0x4a01b8?, 0x4058e6?, 0x0?)
	/home/michael/sdk/go1.23.0/src/runtime/netpoll.go:575 +0xf7 fp=0xc0000eb390 sp=0xc0000eb358 pc=0x4318f7
internal/poll.runtime_pollWait(0x7ef586628808, 0x72)
	/home/michael/sdk/go1.23.0/src/runtime/netpoll.go:351 +0x85 fp=0xc0000eb3b0 sp=0xc0000eb390 pc=0x46af05
internal/poll.(*pollDesc).wait(0xc0000ce180?, 0xc00020e99c?, 0x0)
	/home/michael/sdk/go1.23.0/src/internal/poll/fd_poll_runtime.go:84 +0x27 fp=0xc0000eb3d8 sp=0xc0000eb3b0 pc=0x4b0ce7
internal/poll.(*pollDesc).waitRead(...)
	/home/michael/sdk/go1.23.0/src/internal/poll/fd_poll_runtime.go:89
internal/poll.(*FD).Read(0xc0000ce180, {0xc00020e99c, 0x4, 0x4})
	/home/michael/sdk/go1.23.0/src/internal/poll/fd_unix.go:165 +0x27a fp=0xc0000eb470 sp=0xc0000eb3d8 pc=0x4b17da
net.(*netFD).Read(0xc0000ce180, {0xc00020e99c?, 0x6eeea0?, 0x1?})
	/home/michael/sdk/go1.23.0/src/net/fd_posix.go:55 +0x25 fp=0xc0000eb4b8 sp=0xc0000eb470 pc=0x4f7e85
net.(*conn).Read(0xc000206000, {0xc00020e99c?, 0xc000212000?, 0x6e6ec0?})
	/home/michael/sdk/go1.23.0/src/net/net.go:189 +0x45 fp=0xc0000eb500 sp=0xc0000eb4b8 pc=0x5001a5
net.(*TCPConn).Read(0x0?, {0xc00020e99c?, 0xc0000eb568?, 0x46d449?})
	<autogenerated>:1 +0x25 fp=0xc0000eb530 sp=0xc0000eb500 pc=0x50bb25
io.ReadAtLeast({0x5d9640, 0xc000206000}, {0xc00020e99c, 0x4, 0x4}, 0x4)
	/home/michael/sdk/go1.23.0/src/io/io.go:335 +0x90 fp=0xc0000eb578 sp=0xc0000eb530 pc=0x4957d0
io.ReadFull(...)
	/home/michael/sdk/go1.23.0/src/io/io.go:354
encoding/binary.Read({0x5d9640, 0xc000206000}, {0x5da8b0, 0x7059a0}, {0x55e7c0, 0xc0000eb6a0})
	/home/michael/sdk/go1.23.0/src/encoding/binary/binary.go:244 +0xa5 fp=0xc0000eb670 sp=0xc0000eb578 pc=0x5102a5
github.com/gokrazy/rsync/internal/rsyncwire.(*MultiplexReader).ReadMsg(0xc00020a100)
	/home/michael/kr/rsync/internal/rsyncwire/wire.go:50 +0x48 fp=0xc0000eb6e8 sp=0xc0000eb670 pc=0x514428
github.com/gokrazy/rsync/internal/rsyncwire.(*MultiplexReader).Read(0x7ef5869b9a68?, {0xc000280000, 0x40000, 0x4dd4fb?})
	/home/michael/kr/rsync/internal/rsyncwire/wire.go:72 +0x2f fp=0xc0000eb788 sp=0xc0000eb6e8 pc=0x5145af
bufio.(*Reader).Read(0xc0002020c0, {0xc00020e998, 0x4, 0x40ece5?})
	/home/michael/sdk/go1.23.0/src/bufio/bufio.go:241 +0x197 fp=0xc0000eb7c0 sp=0xc0000eb788 pc=0x4d5a57
io.ReadAtLeast({0x5d93e0, 0xc0002020c0}, {0xc00020e998, 0x4, 0x4}, 0x4)
	/home/michael/sdk/go1.23.0/src/io/io.go:335 +0x90 fp=0xc0000eb808 sp=0xc0000eb7c0 pc=0x4957d0
io.ReadFull(...)
	/home/michael/sdk/go1.23.0/src/io/io.go:354
github.com/gokrazy/rsync/internal/rsyncwire.(*Conn).ReadInt32(0xc000208060)
	/home/michael/kr/rsync/internal/rsyncwire/wire.go:163 +0x4a fp=0xc0000eb850 sp=0xc0000eb808 pc=0x51490a
github.com/gokrazy/rsync/internal/receiver.(*Transfer).recvIdMapping1(0xc000202120, 0x5a9b58)
	/home/michael/kr/rsync/internal/receiver/uidlist.go:16 +0x3d fp=0xc0000eb8c0 sp=0xc0000eb850 pc=0x51fc7d
github.com/gokrazy/rsync/internal/receiver.(*Transfer).RecvIdList(0xc000202120)
	/home/michael/kr/rsync/internal/receiver/uidlist.go:52 +0x1dd fp=0xc0000eba08 sp=0xc0000eb8c0 pc=0x51ffbd
github.com/gokrazy/rsync/internal/receiver.(*Transfer).ReceiveFileList(0xc000202120)
	/home/michael/kr/rsync/internal/receiver/flist.go:229 +0x378 fp=0xc0000ebb10 sp=0xc0000eba08 pc=0x51c5b8
github.com/gokrazy/rsync/internal/receivermaincmd.clientRun({{0x5d9280, 0xc000078058}, {0x5d92a0, 0xc000078060}, {0x5d92a0, 0xc000078068}}, 0xc0000d0d90, {0x7ef53d47efc8, 0xc000206000}, {0x7ffc5866600e, ...}, ...)
	/home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:341 +0x5cd fp=0xc0000ebc10 sp=0xc0000ebb10 pc=0x550c2d
github.com/gokrazy/rsync/internal/receivermaincmd.socketClient({{0x5d9280, 0xc000078058}, {0x5d92a0, 0xc000078060}, {0x5d92a0, 0xc000078068}}, 0xc0000d0d90, {0x7ffc58665ff4?, 0x1?}, {0x7ffc5866600e, ...})
	/home/michael/kr/rsync/internal/receivermaincmd/clientserver.go:44 +0x425 fp=0xc0000ebcd0 sp=0xc0000ebc10 pc=0x54c205
github.com/gokrazy/rsync/internal/receivermaincmd.rsyncMain({{0x5d9280, 0xc000078058}, {0x5d92a0, 0xc000078060}, {0x5d92a0, 0xc000078068}}, 0xc0000d0d90, {0xc00007e440, 0x1, 0x2}, ...)
	/home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:160 +0x5d7 fp=0xc0000ebdf0 sp=0xc0000ebcd0 pc=0x54f697
github.com/gokrazy/rsync/internal/receivermaincmd.Main({0xc0000160a0, 0x5, 0x5}, {0x5d9280?, 0xc000078058?}, {0x5d92a0?, 0xc000078060?}, {0x5d92a0?, 0xc000078068?})
	/home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:394 +0x272 fp=0xc0000ebee8 sp=0xc0000ebdf0 pc=0x5510d2
main.main()
	/home/michael/kr/rsync/cmd/gokr-rsync/rsync.go:12 +0x4e fp=0xc0000ebf50 sp=0xc0000ebee8 pc=0x5515ae
runtime.main()
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:272 +0x28b fp=0xc0000ebfe0 sp=0xc0000ebf50 pc=0x438d4b
runtime.goexit({})
	/home/michael/sdk/go1.23.0/src/runtime/asm_amd64.s:1700 +0x1 fp=0xc0000ebfe8 sp=0xc0000ebfe0 pc=0x472e61

goroutine 2 gp=0xc000006c40 m=nil [force gc (idle)]:
runtime.gopark(0x0?, 0x0?, 0x0?, 0x0?, 0x0?)
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:424 +0xce fp=0xc000074fa8 sp=0xc000074f88 pc=0x46bc0e
runtime.goparkunlock(...)
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:430
runtime.forcegchelper()
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:337 +0xb3 fp=0xc000074fe0 sp=0xc000074fa8 pc=0x439093
runtime.goexit({})
	/home/michael/sdk/go1.23.0/src/runtime/asm_amd64.s:1700 +0x1 fp=0xc000074fe8 sp=0xc000074fe0 pc=0x472e61
created by runtime.init.7 in goroutine 1
	/home/michael/sdk/go1.23.0/src/runtime/proc.go:325 +0x1a
```

</div>

Phew! This output is pretty dense.

We can use the https://github.com/maruel/panicparse program to present this
stack trace in a more colorful and much shorter version:

{{< img src="2025-02-08-panicparse.jpg" >}}

The functions helpfully highlighted in red are where the problem lies: My rsync
receiver implementation was incorrectly expecting the server to send a uid/gid
list, despite the PreserveUid and PreserveGid options not being enabled. [Commit
`6c89d4d`](https://github.com/gokrazy/rsync/commit/6c89d4dda3be055f19684c0ed56d623da458194e)
fixes the issue.

## Tip 2: Attach the delve debugger to the process {#attach-dlv}

If dumping the stack trace in the moment is not sufficient to diagnose the
problem, you can go one step further and reach for an interactive debugger.

The most well-known Linux debugger is probably GDB, but when working with Go, I
recommend using [the delve debugger](https://github.com/go-delve/delve) instead
as it typically works better. Install delve if you haven’t already:

```
% go install github.com/go-delve/delve/cmd/dlv@latest
```

In this article, I am using delve v1.24.0.

{{< note >}}

**Note:** If you want to explore local variables, you should rebuild your
program without optimizations and inlining (see the [`dlv exec`
docs](https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_exec.md)):

```
% go install -gcflags=all="-N -l" ./cmd/...
```

{{< /note >}}

While you can run a new child process in a debugger (use `dlv exec`) without any
special permissions, attaching existing processes in a debugger is [disabled by
default in Linux](https://www.kernel.org/doc/Documentation/security/Yama.txt)
for security reasons. We can allow this feature (remember to turn it off later!)
using:


```
% sudo sysctl -w kernel.yama.ptrace_scope=0
kernel.yama.ptrace_scope = 0
```

…and then we can just `dlv attach` to the hanging `gokr-rsync` process:


```
% dlv attach $(pidof gokr-rsync)
Type 'help' for list of commands.
(dlv)
```

Great. But if we just print a stack trace, we only see functions from the
`runtime` package:

```
(dlv) bt
0  0x000000000047bb83 in runtime.futex
   at /home/michael/sdk/go1.23.6/src/runtime/sys_linux_amd64.s:558
1  0x00000000004374d0 in runtime.futexsleep
   at /home/michael/sdk/go1.23.6/src/runtime/os_linux.go:69
2  0x000000000040d89d in runtime.notesleep
   at /home/michael/sdk/go1.23.6/src/runtime/lock_futex.go:170
3  0x000000000044123e in runtime.mPark
   at /home/michael/sdk/go1.23.6/src/runtime/proc.go:1866
4  0x000000000044290d in runtime.stopm
   at /home/michael/sdk/go1.23.6/src/runtime/proc.go:2886
5  0x00000000004433d0 in runtime.findRunnable
   at /home/michael/sdk/go1.23.6/src/runtime/proc.go:3623
6  0x0000000000444e1d in runtime.schedule
   at /home/michael/sdk/go1.23.6/src/runtime/proc.go:3996
7  0x00000000004451cb in runtime.park_m
   at /home/michael/sdk/go1.23.6/src/runtime/proc.go:4103
8  0x0000000000477eee in runtime.mcall
   at /home/michael/sdk/go1.23.6/src/runtime/asm_amd64.s:459
```

The reason is that no goroutine is running (the program is waiting indefinitely
to receive data from the server), so we see one of the OS threads waiting in the
Go scheduler.

We first need to switch to the goroutine we are interested in (`grs` prints all
goroutines), and then the stack trace looks like what we expect:

```
(dlv) gr 1
Switched from 0 to 1 (thread 414327)
(dlv) bt
 0  0x0000000000474ebc in runtime.gopark
    at /home/michael/sdk/go1.23.6/src/runtime/proc.go:425
 1  0x000000000043819e in runtime.netpollblock
    at /home/michael/sdk/go1.23.6/src/runtime/netpoll.go:575
 2  0x000000000047435c in internal/poll.runtime_pollWait
    at /home/michael/sdk/go1.23.6/src/runtime/netpoll.go:351
 3  0x00000000004ed15a in internal/poll.(*pollDesc).wait
    at /home/michael/sdk/go1.23.6/src/internal/poll/fd_poll_runtime.go:84
 4  0x00000000004ed1f1 in internal/poll.(*pollDesc).waitRead
    at /home/michael/sdk/go1.23.6/src/internal/poll/fd_poll_runtime.go:89
 5  0x00000000004ee351 in internal/poll.(*FD).Read
    at /home/michael/sdk/go1.23.6/src/internal/poll/fd_unix.go:165
 6  0x0000000000569bb3 in net.(*netFD).Read
    at /home/michael/sdk/go1.23.6/src/net/fd_posix.go:55
 7  0x000000000057a025 in net.(*conn).Read
    at /home/michael/sdk/go1.23.6/src/net/net.go:189
 8  0x000000000058fcc5 in net.(*TCPConn).Read
    at <autogenerated>:1
 9  0x00000000004b72e8 in io.ReadAtLeast
    at /home/michael/sdk/go1.23.6/src/io/io.go:335
10  0x00000000004b74d3 in io.ReadFull
    at /home/michael/sdk/go1.23.6/src/io/io.go:354
11  0x0000000000598d5f in encoding/binary.Read
    at /home/michael/sdk/go1.23.6/src/encoding/binary/binary.go:244
12  0x00000000005a0b7a in github.com/gokrazy/rsync/internal/rsyncwire.(*MultiplexReader).ReadMsg
    at /home/michael/kr/rsync/internal/rsyncwire/wire.go:50
13  0x00000000005a0f17 in github.com/gokrazy/rsync/internal/rsyncwire.(*MultiplexReader).Read
    at /home/michael/kr/rsync/internal/rsyncwire/wire.go:72
14  0x0000000000528de8 in bufio.(*Reader).Read
    at /home/michael/sdk/go1.23.6/src/bufio/bufio.go:241
15  0x00000000004b72e8 in io.ReadAtLeast
    at /home/michael/sdk/go1.23.6/src/io/io.go:335
16  0x00000000004b74d3 in io.ReadFull
    at /home/michael/sdk/go1.23.6/src/io/io.go:354
17  0x00000000005a19ef in github.com/gokrazy/rsync/internal/rsyncwire.(*Conn).ReadInt32
    at /home/michael/kr/rsync/internal/rsyncwire/wire.go:163
18  0x00000000005b77d2 in github.com/gokrazy/rsync/internal/receiver.(*Transfer).recvIdMapping1
    at /home/michael/kr/rsync/internal/receiver/uidlist.go:16
19  0x00000000005b7ea8 in github.com/gokrazy/rsync/internal/receiver.(*Transfer).RecvIdList
    at /home/michael/kr/rsync/internal/receiver/uidlist.go:52
20  0x00000000005b18db in github.com/gokrazy/rsync/internal/receiver.(*Transfer).ReceiveFileList
    at /home/michael/kr/rsync/internal/receiver/flist.go:229
21  0x0000000000605390 in github.com/gokrazy/rsync/internal/receivermaincmd.clientRun
    at /home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:341
22  0x00000000005fe572 in github.com/gokrazy/rsync/internal/receivermaincmd.socketClient
    at /home/michael/kr/rsync/internal/receivermaincmd/clientserver.go:44
23  0x0000000000602f10 in github.com/gokrazy/rsync/internal/receivermaincmd.rsyncMain
    at /home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:160
24  0x0000000000605e7e in github.com/gokrazy/rsync/internal/receivermaincmd.Main
    at /home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:394
25  0x0000000000606653 in main.main
    at /home/michael/kr/rsync/cmd/gokr-rsync/rsync.go:12
26  0x000000000043fa47 in runtime.main
    at /home/michael/sdk/go1.23.6/src/runtime/proc.go:272
27  0x000000000047bd01 in runtime.goexit
    at /home/michael/sdk/go1.23.6/src/runtime/asm_amd64.s:1700
```

## Tip 3: Save a core dump for later {#save-core-dump}

If you don’t have time to poke around in the debugger now, you can save a core
dump for later.

{{< note >}}

**Tip:** Check out my [debugging Go core dumps with
delve](/posts/2024-10-22-debug-go-core-dumps-delve-export-bytes/) blog post from
2024 for more details! This section just explains how to collect core dumps.

{{< /note >}}

In addition to printing the stack trace on `SIGQUIT`, we can make the Go runtime
crash the program, which in turn makes the Linux kernel write a core dump, by
running our program with the environment variable
[`GOTRACEBACK=crash`](https://pkg.go.dev/runtime).

Modern Linux systems typically include {{< man name="systemd-coredump"
section="8" >}} (but you might need to explicitly install it, for example on
Ubuntu) to collect core dumps (and remove old ones). You can use {{< man
name="coredumpctl" section="1" >}} to list and work with them. On macOS,
[collecting cores is more
involved](https://developer.apple.com/forums/thread/694233#695943022). I don’t
know about Windows.

In case your Linux system does not use `systemd-coredump`, you can use `ulimit
-c unlimited` and set the kernel’s `kernel.core_pattern` sysctl setting. You can
find more details and options in the [CoreDumpDebugging page of the Go
wiki](https://go.dev/wiki/CoreDumpDebugging). For this article, we will stick to
`coredumpctl`:

```
% GOTRACEBACK=crash gokr-rsync -rtO --delete rsync://rsync.paas.rpki.ripe.net/repo/ /tmp/rpki-repo
[…]
^\SIGQUIT: quit
[…]
zsh: IOT instruction (core dumped)  GOTRACEBACK=crash gokr-rsync -rtO […]

```

The last line is what we want to see: it should say “core dumped”.

This core should now show up in {{< man name="coredumpctl" section="1" >}}:


```
% coredumpctl info
           PID: 414607 (gokr-rsync)
           UID: 1000 (michael)
           GID: 1000 (michael)
        Signal: 6 (ABRT)
     Timestamp: Sat 2025-02-08 10:18:27 CET (12s ago)
  Command Line: gokr-rsync -rtO --delete rsync://rsync.paas.rpki.ripe.net/repo/ /tmp/rpki-repo
    Executable: /bin/gokr-rsync
 Control Group: /user.slice/user-1000.slice/session-1.scope
          Unit: session-1.scope
         Slice: user-1000.slice
       Session: 1
     Owner UID: 1000 (michael)
       Boot ID: 6158dd3b52af4b8384c103a8a336fc02
    Machine ID: ecb5a44f1a5846ad871566e113bf8937
      Hostname: midna
       Storage: /var/lib/systemd/coredump/core.gokr-rsync.1000.6158dd3b52af4b8384c103a8a336fc02.414607.1739006307000000.zst (present)
  Size on Disk: 158.3K
       Message: Process 414607 (gokr-rsync) of user 1000 dumped core.
                
    Module [dso] without build-id.
    Module [dso]
    Stack trace of thread 1604447:
    #0  0x0000000000475a41 runtime.raise.abi0 (/bin/gokr-rsync + 0x75a41)
    #1  0x0000000000451d85 runtime.dieFromSignal (/bin/gokr-rsync + 0x51d85)
    #2  0x00000000004522e6 runtime.sigfwdgo (/bin/gokr-rsync + 0x522e6)
    #3  0x0000000000450c45 runtime.sigtrampgo (/bin/gokr-rsync + 0x50c45)
    #4  0x0000000000475d26 runtime.sigtramp.abi0 (/bin/gokr-rsync + 0x75d26)
    #5  0x0000000000475e20 n/a (/bin/gokr-rsync + 0x75e20)
    ELF object binary architecture: AMD x86-64
```

If you see only hexadecimal addresses followed by `n/a (n/a + 0x0)`, that means
`systemd-coredump` could not symbolize (= resolve addresses to function names)
your core dump. Here are a few possible reasons for missing symbolization:

* Linux 6.12 and 6.13 [produced core dumps that elfutils cannot
  symbolize](https://sourceware.org/bugzilla/show_bug.cgi?id=32713). `systemd-coredump`
  uses elfutils for symbolization, so avoid 6.12/6.13 in favor of using 6.14 or
  newer.
* With systemd v234-v256, `systemd-coredump` did not have permission to look
  into programs living in the `/home` directory (fixed with [commit
  `4ac1755`](https://github.com/systemd/systemd/commit/4ac1755be2d6c141fae7e57c42936e507c5b54e3)
  in systemd v257+).
  * Similarly, `systemd-coredump` runs with
    [`PrivateTmp=yes`](http://manpages.debian.org/systemd.exec), meaning it
    won’t be able to access programs you place in `/tmp`.
* Go builds with debug symbols by default, but maybe you are explicitly
  stripping debug symbols in your build, by building with `-ldflags=-w`?

We can now use {{< man name="coredumpctl" section="1" >}} to launch delve for
this program + core dump:

```
% coredumpctl debug --debugger=dlv --debugger-arguments=core
[…]
Type 'help' for list of commands.
(dlv) gr 1
Switched from 0 to 1 (thread 414607)
(dlv) bt
[…]
16  0x00000000004b74d3 in io.ReadFull
    at /home/michael/sdk/go1.23.6/src/io/io.go:354
17  0x00000000005a19ef in github.com/gokrazy/rsync/internal/rsyncwire.(*Conn).ReadInt32
    at /home/michael/kr/rsync/internal/rsyncwire/wire.go:163
18  0x00000000005b77d2 in github.com/gokrazy/rsync/internal/receiver.(*Transfer).recvIdMapping1
    at /home/michael/kr/rsync/internal/receiver/uidlist.go:16
19  0x00000000005b7ea8 in github.com/gokrazy/rsync/internal/receiver.(*Transfer).RecvIdList
    at /home/michael/kr/rsync/internal/receiver/uidlist.go:52
20  0x00000000005b18db in github.com/gokrazy/rsync/internal/receiver.(*Transfer).ReceiveFileList
    at /home/michael/kr/rsync/internal/receiver/flist.go:229
21  0x0000000000605390 in github.com/gokrazy/rsync/internal/receivermaincmd.clientRun
    at /home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:341
22  0x00000000005fe572 in github.com/gokrazy/rsync/internal/receivermaincmd.socketClient
    at /home/michael/kr/rsync/internal/receivermaincmd/clientserver.go:44
23  0x0000000000602f10 in github.com/gokrazy/rsync/internal/receivermaincmd.rsyncMain
    at /home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:160
24  0x0000000000605e7e in github.com/gokrazy/rsync/internal/receivermaincmd.Main
    at /home/michael/kr/rsync/internal/receivermaincmd/receivermaincmd.go:394
25  0x0000000000606653 in main.main
    at /home/michael/kr/rsync/cmd/gokr-rsync/rsync.go:12
26  0x000000000043fa47 in runtime.main
    at /home/michael/sdk/go1.23.6/src/runtime/proc.go:272
27  0x000000000047bd01 in runtime.goexit
    at /home/michael/sdk/go1.23.6/src/runtime/asm_amd64.s:1700
```

## Conclusion

In my experience, in the medium to long term, it always pays off to set up your
environment such that you can debug your programs conveniently. I strongly
encourage every programmer (and even users!) to invest time into your
development and debugging setup.

Luckily, Go comes with stack printing functionality by default (just press
`Ctrl+\`) and we can easily get a core dump out of our Go programs by running
them with `GOTRACEBACK=crash` — provided the system is set up to collect core
dumps.

Together with the delve debugger, this gives us all we need to effectively and
efficiently diagnose problems in Go programs.
