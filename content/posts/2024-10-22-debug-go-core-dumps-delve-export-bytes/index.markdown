---
layout: post
title:  "Debug Go core dumps with delve: export byte slices"
date:   2024-10-22 17:22:23 +02:00
categories: Artikel
tags:
- golang
- debug
---

Not all bugs can easily be reproduced — sometimes, all you have is a core dump
from a crashing program, but no idea about the triggering conditions of the bug
yet.

When using Go, we can use [the delve
debugger](https://github.com/go-delve/delve) for core dump debugging, but I had
trouble figuring out how to save byte slice contents (for example: the incoming
request causing the crash) from memory into a file for further analysis, so this
article walks you through how to do it.

## Simple Example

Let’s imagine the following scenario: You are working on a performance
optimization in [Go Protobuf](https://pkg.go.dev/google.golang.org/protobuf) and
have accidentally badly broken the [`proto.Marshal`
function](https://pkg.go.dev/google.golang.org/protobuf/proto#Marshal). The
function is now returning an error, so let’s run one of the failing tests with
delve:

```
~/protobuf/proto master % dlv test
(dlv) b ExampleMarshal
(dlv) c
> [Breakpoint 1] google.golang.org/protobuf/proto_test.ExampleMarshal() ./encode_test.go:293 (hits goroutine(1):1 total:1) (PC: 0x9d6c96)
(dlv) next 4
> google.golang.org/protobuf/proto_test.ExampleMarshal() ./encode_test.go:297 (PC: 0xb54495)
   292: // [google.golang.org/protobuf/types/known/durationpb.New].
   293: func ExampleMarshal() {
   294: b, err := proto.Marshal(&durationpb.Duration{
   295: Nanos: 125,
   296: })
=> 297: if err != nil {
   298: panic(err)
   299: }
   300:
   301: fmt.Printf("125ns encoded into %d bytes of Protobuf wire format:\n% x\n", len(b), b)
   302:
```

Go Protobuf happens to return the already encoded bytes even when returning an
error, so we can inspect the `b` byte slice to see how far the encoding got
before the error happened:

```
(dlv) print b
[]uint8 len: 2, cap: 2, [16,125]
```

In this case, we can see that the entire (trivial) message was encoded, so our
error must happen at a later stage — this allows us to rule out a large chunk of
code in our search for the bug.

But what would we do if a longer part of the message was displayed and we wanted
to load it into a different tool for further analysis, e.g. the excellent
[protoscope](https://github.com/protocolbuffers/protoscope)?

The low-tech approach is to print the contents and copy&paste from the delve
output into an editor or similar. This stops working as soon as your data
contains non-printable characters.

We have multiple options to export the byte slice to a file:

1. We could add `os.WriteFile("/tmp/b.raw", b, 0644)` to the source code and
   re-run the test. This is definitely the simplest option, as it works with or
   without a debugger.
1. As long as delve is connected to a running program, we can use delve’s call
   command to just execute the same code without having to add it to our source:

   ```
   (dlv) call os.WriteFile("/tmp/b.raw", b, 0644)
   (dlv)
   ```

Notably, both options only work when you can debug interactively. For the first
option, you need to be able to change the source. The second option requires
that delve is attached to a running process that you can afford to pause and
interactively control.

These are trivial requirements when running a unit tests on your local machine,
but get much harder when debugging an RPC service that crashes with specific
requests, as you need to only run your changed debugging code for the
troublesome requests, skipping the unproblematic requests that should still be
handled normally.

## Core dump debugging with Go

So let’s switch example: we are no longer working on Go Protobuf. Instead, we
now need to debug an RPC service where certain requests crash the service. We’ll
use core dump debugging!

{{< img src="core-memory-featured.jpg" alt="Core memory" >}}

In case you’re wondering: The name “[core
dump](https://en.wikipedia.org/wiki/Core_dump)” comes from [magnetic-core
memory](https://en.wikipedia.org/wiki/Magnetic-core_memory). These days we
should probably say “memory dump” instead. The picture above shows an exhibit
from the [MIT Museum](https://mitmuseum.mit.edu/) (*Core Memory Unit, Bank C
(from Project Whirlwind, 1953-1959))*, a core memory unit with 4 KB of capacity.

To make Go write a core dump when panicing, run your program with the
environment variable `GOTRACEBACK=crash` set (all possible values are documented
[in the `runtime` package](https://pkg.go.dev/runtime)).

You also need to ensure your system is set up to collect core dumps, as they are
typically discarded by default:

* On Linux, the easiest way is to install {{< man name="systemd-coredump"
  section="8" >}}, after which core dumps will automatically be collected. You
  can use {{< man name="coredumpctl" section="1" >}} to list and work with them.
* On macOS, you can enable core dump collection, but [delve cannot open macOS
  core dumps](https://github.com/go-delve/delve/issues/2026). Luckily, macOS is
  rarely used for production servers.
* I don’t know about Windows and other systems.

You can find more details and options in the [CoreDumpDebugging page of the Go
wiki](https://go.dev/wiki/CoreDumpDebugging). For this article, we will stick to
the `coredumpctl` route:

We’ll use the [gRPC Go Quick start
example](https://grpc.io/docs/languages/go/quickstart/), a greeter client/server
program, and add a `panic()` call to the server `SayHello` handler:

```
% cd greeter_server
% go build -gcflags=all="-N -l"  # disable optimizations
% GOTRACEBACK=crash ./greeter_server
2024/10/19 21:48:01 server listening at [::]:50051
2024/10/19 21:48:03 Received: world
panic: oh no!

goroutine 5 gp=0xc000007c00 m=5 mp=0xc000100008 [running]:
panic({0x83ca60?, 0x9a3710?})
	/home/michael/sdk/go1.23.0/src/runtime/panic.go:804 +0x168 fp=0xc000169850 sp=0xc0001697a0 pc=0x46fe88
main.(*server).SayHello(0xcbb840?, {0x877200?, 0xc000094900?}, 0x4a6f25?)
	/home/michael/go/src/github.com/grpc/grpc-go/examples/helloworld/greeter_server/main.go:45 +0xbf fp=0xc0001698c0 sp=0xc000169850 pc=0x8037ff
[…]
signal: aborted (core dumped)
```

The last line is what we want to see: it should say “core dumped”.

We can now use {{< man name="coredumpctl" section="1" >}} to launch delve for
this program + core dump:

```
% coredumpctl debug --debugger=dlv --debugger-arguments=core
           PID: 1729467 (greeter_server)
           UID: 1000 (michael)
           GID: 1000 (michael)
        Signal: 6 (ABRT)
     Timestamp: Sat 2024-10-19 21:50:12 CEST (1min 49s ago)
  Command Line: ./greeter_server
    Executable: /home/michael/go/src/github.com/grpc/grpc-go/examples/helloworld/greeter_server/greeter_server
 Control Group: /user.slice/user-1000.slice/session-1.scope
          Unit: session-1.scope
         Slice: user-1000.slice
       Session: 1
     Owner UID: 1000 (michael)
       Storage: /var/lib/systemd/coredump/core.greeter_server.1000.zst (present)
  Size on Disk: 204.7K
       Message: Process 1729467 (greeter_server) of user 1000 dumped core.
                
                Module /home/michael/go/src/github.com/grpc/grpc-go/examples/helloworld/greeter_server/greeter_server without build-id.
                Stack trace of thread 1729470:
                #0  0x0000000000479461 n/a (greeter_server + 0x79461)
[…]
                ELF object binary architecture: AMD x86-64

Type 'help' for list of commands.
(dlv) bt
 0  0x0000000000479461 in runtime.raise
    at /home/michael/sdk/go1.23.0/src/runtime/sys_linux_amd64.s:154
 1  0x0000000000451a85 in runtime.dieFromSignal
    at /home/michael/sdk/go1.23.0/src/runtime/signal_unix.go:942
 2  0x00000000004520e6 in runtime.sigfwdgo
    at /home/michael/sdk/go1.23.0/src/runtime/signal_unix.go:1154
 3  0x0000000000450a85 in runtime.sigtrampgo
    at /home/michael/sdk/go1.23.0/src/runtime/signal_unix.go:432
 4  0x0000000000479461 in runtime.raise
    at /home/michael/sdk/go1.23.0/src/runtime/sys_linux_amd64.s:153
 5  0x0000000000451a85 in runtime.dieFromSignal
    at /home/michael/sdk/go1.23.0/src/runtime/signal_unix.go:942
 6  0x0000000000439551 in runtime.crash
    at /home/michael/sdk/go1.23.0/src/runtime/signal_unix.go:1031
 7  0x0000000000439551 in runtime.fatalpanic
    at /home/michael/sdk/go1.23.0/src/runtime/panic.go:1290
 8  0x000000000046fe88 in runtime.gopanic
    at /home/michael/sdk/go1.23.0/src/runtime/panic.go:804
 9  0x00000000008037ff in main.(*server).SayHello
    at ./main.go:45
10  0x00000000008033a6 in google.golang.org/grpc/examples/helloworld/helloworld._Greeter_SayHello_Handler
    at /home/michael/go/src/github.com/grpc/grpc-go/examples/helloworld/helloworld/helloworld_grpc.pb.go:115
11  0x00000000007edeeb in google.golang.org/grpc.(*Server).processUnaryRPC
    at /home/michael/go/src/github.com/grpc/grpc-go/server.go:1394
12  0x00000000007f2eab in google.golang.org/grpc.(*Server).handleStream
    at /home/michael/go/src/github.com/grpc/grpc-go/server.go:1805
13  0x00000000007ebbff in google.golang.org/grpc.(*Server).serveStreams.func2.1
    at /home/michael/go/src/github.com/grpc/grpc-go/server.go:1029
14  0x0000000000477c21 in runtime.goexit
    at /home/michael/sdk/go1.23.0/src/runtime/asm_amd64.s:1700
(dlv) 
```

Alright! Now let’s switch to frame 9 (our server’s `SayHello` handler) and
inspect the `Name` field of the incoming RPC request:

```
(dlv) frame 9
> runtime.raise() /home/michael/sdk/go1.23.0/src/runtime/sys_linux_amd64.s:154 (PC: 0x482681)
Warning: debugging optimized function
Frame 9: ./main.go:45 (PC: aaabf8)
    40:	}
    41:	
    42:	// SayHello implements helloworld.GreeterServer
    43:	func (s *server) SayHello(_ context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
    44:		log.Printf("Received: %v", in.GetName())
=>  45:		panic("oh no!")
    46:		return &pb.HelloReply{Message: "Hello " + in.GetName()}, nil
    47:	}
    48:	
    49:	func main() {
    50:		flag.Parse()
(dlv) p in
("*google.golang.org/grpc/examples/helloworld/helloworld.HelloRequest")(0xc000120100)
*google.golang.org/grpc/examples/helloworld/helloworld.HelloRequest {
[…]
	unknownFields: []uint8 len: 0, cap: 0, nil,
	Name: "world",}
```

In this case, it’s easy to see that the `Name` field was set to `world` in the
incoming request, but let’s assume the request contained lots of binary data
that was not as easy to read or copy.

How do we write the byte slice contents to a file? In this scenario, we cannot
modify the source code and delve’s `call` command does not work on core dumps
(only when delve is attached to a running process):

```
(dlv) call os.WriteFile("/tmp/name.raw", in.Name, 0644)
> runtime.raise() /home/michael/sdk/go1.23.0/src/runtime/sys_linux_amd64.s:154 (PC: 0x482681)
Warning: debugging optimized function
Command failed: can not continue execution of core process
```

Luckily, we can extend delve with a custom Starlark function to write byte slice
contents to a file.

## Exporting byte slices with writebytestofile

You need a version of dlv that contains commit
https://github.com/go-delve/delve/commit/52405ba86bd9e14a2e643db391cbdebdcbdb3368. Until
the commit is part of a released version, you can install the latest dlv
directly from git:

```
% go install github.com/go-delve/delve/cmd/dlv@master
```

Save the following Starlark code to a file, for example `~/dlv_writebytestofile.star`:

```python
# Syntax: writebytestofile <byte slice var> <output file path>
def command_writebytestofile(args):
	var_name, filename = args.split(" ")
	s = eval(None, var_name).Variable
	mem = examine_memory(s.Base, s.Len).Mem
	write_file(filename, mem)
```

Then, in delve, load the Starlark code and run the function to export the byte
slice contents of `in.Name` to `/tmp/name.raw`:

```
% coredumpctl debug --debugger=dlv --debugger-arguments=core
(dlv) frame 9
(dlv) source ~/dlv_writebytestofile.star
(dlv) writebytestofile in.Name /tmp/name.raw
```

Let’s verify that we got the right contents:

```
% hexdump -C /tmp/name.raw
00000000  77 6f 72 6c 64                                    |world|
00000005
```

## Core dump debugging with `net/http` servers

When you want to apply the core dump debugging technique on a `net/http` server
(instead of a gRPC server, as above), you will notice that panics in your HTTP
handlers do not actually result in a core dump! This code in
`go/src/net/http/server.go` recovers panics and logs a stack trace:

```go
defer func() {
    if err := recover(); err != nil && err != ErrAbortHandler {
        const size = 64 << 10
        buf := make([]byte, size)
        buf = buf[:runtime.Stack(buf, false)]
        c.server.logf("http: panic serving %v: %v\n%s", c.remoteAddr, err, buf)
    }
}()
```

Or, in other words: the `GOTRACEBACK=crash` environment variable configures what
happens for unhandled signals, but this signal is handled with the `recover()`
call, so no core is dumped.

This default behavior of `net/http` servers [is now considered regrettable but
cannot be changed for
compatibility](https://github.com/golang/go/issues/25245). (We probably can add
a struct field to optionally not recover panics, though. I’ll update this
paragraph once there is a proposal.)

So, what options do we have in the meantime?

We could recover panics in our own code (before `net/http`’s panic handler is
called), but then how do we produce a core dump from our own handler?

A closer look reveals that the Go runtime’s `crash` function is defined in
`signal_unix.go` and [sends signal `SIGABRT` with the `dieFromSignal`
function](https://cs.opensource.google/go/go/+/refs/tags/go1.23.2:src/runtime/signal_unix.go;l=938)
to the current thread:

```go
//go:nosplit
func crash() {
        dieFromSignal(_SIGABRT)
}
```

The default action for `SIGABRT` is to “terminate the process and dump core”,
see {{< man name="signal" section="7" >}}.

We can follow the same strategy and send `SIGABRT` to our process:

```go
func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				proc, err := os.FindProcess(syscall.Getpid())
				if err != nil {
					panic(fmt.Sprintf("could not find own process (pid %d): %v", syscall.Getpid(), err))
				}
				proc.Signal(syscall.SIGABRT)
				// Ensure the stack triggering the core dump sticks around
				proc.Wait()
			}
		}()
		// …buggy handler code goes here; for illustration we panic
		panic("this should result in a core dump")
	})
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

There is one caveat: If you have any non-Go threads running in your program,
e.g. by using cgo, they might pick up the signal, so ensure they do not install
a `SIGABRT` handler (see also: [cgo-related documentation in
`os/signal`](https://pkg.go.dev/os/signal#hdr-Go_programs_that_use_cgo_or_SWIG)).

If this is a concern, you can make the above code more platform-specific and use
the {{< man name="tgkill" section="2" >}} syscall to direct the signal to the
current thread, as [the Go runtime
does](https://cs.opensource.google/go/go/+/refs/tags/go1.23.2:src/runtime/sys_linux_amd64.s;l=143).

## Conclusion

Core dump debugging can be a very useful technique to quickly make progress on
otherwise hard-to-debug problems. In small environments (single to few Linux
servers), core dumps are easy enough to turn on and work with, but in larger
environments you might need to invest into central core dump collection.

I hope the technique shown above comes in handy when you need to work with core
dumps.
