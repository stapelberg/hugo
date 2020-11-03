---
layout: post
date: 2020-02-02
title: "Readiness notifications in Go"
categories: Artikel
tags:
- golang
tweet_url: "https://twitter.com/zekjur/status/1223982851944845318"
---

When spawning a child program, for example in an integration test, it is often
helpful to know when the child program is ready to receive requests.

### Delaying

A brittle strategy is to just add a delay (say, `time.Sleep(2 * time.Second)`)
and hope the child program finishes initialization in that time. This is brittle
because it depends on timing, so when the computer running the test is slow for
whichever reason, your test starts failing. Many CI/CD systems have less
capacity (and/or are more heavily utilized) than developer machines, so timeouts
frequently need to be adjusted.

Also, relying on timing is a race to the bottom: your delay needs to work on the
slowest machine that runs your code. Ergo, tests waste valuable developer time
on your high-end workstation, just so that they pass on some under-powered
machine.

### Polling

A slightly better strategy is polling, i.e. repeatedly checking whether the
child program is ready. As an example, in the `dnsmasq_exporter` test, [I need
to
poll](https://github.com/google/dnsmasq_exporter/blob/646ded9be82e26a4c6450da8d7128d12e0e11e3a/dnsmasq_test.go#L46-L61)
to find out when {{< man name="dnsmasq" section="8" >}} is ready.

This approach is better because it automatically works well on both high-end and
under-powered machines, without wasting time on either.

Finding a good frequency with which to poll is a bit of an art, though: the more
often you poll, the less time you waste, but also the more resources you spend
on polling instead of letting your program initialize. The overhead may be
barely noticeable, but when starting lots of programs (e.g. in a microservice
architecture) or when individual polls are costly, the overhead can add up.

### Readiness notifications

The most elegant approach is to use readiness notifications: you don’t waste any
time or resources.

It only takes a few lines of code to integrate this approach into your
application. The specifics might vary depending on your environment,
e.g. whether an environment variable is preferable to a command-line flag; my
goal with this article is to explain the approach in general, and you can take
care of the details.

The key idea is: the child program inherits a pipe file descriptor from the
parent and closes it once ready. The parent program knows the child program is
ready because an otherwise blocking read from the pipe returns once the pipe is
closed.

This is similar to using a `chan struct{}` in Go and closing it. It doesn’t have
to remain this simple, though: you can also send arbitrary data over the pipe,
ranging from a simple string being sent in one direction and culminating in
speaking a framed protocol in a client/server fashion. In [Debian Code
Search](https://codesearch.debian.net/), I’m [writing the chosen network
address](https://github.com/Debian/dcs/blob/3baaecabca2d6c56799012c40c1245fc389cb6e6/internal/addrfd/addrfd.go)
before closing the pipe, so that the parent program knows where to connect to.

#### Parent Program

So, how do we go about readiness notifications in Go? We create a new pipe and
specify the write end in the `ExtraFiles` field of `(os/exec).Cmd`:

```go
r, w, err := os.Pipe()
if err != nil {
  return err
}

child := exec.Command("child")
child.Stderr = os.Stderr
child.ExtraFiles = []*os.File{w}
```

It is good practice to explicitly specify the file descriptor number that we
passed via some sort of signaling, so that the child program does not need to be
modified when we add new file descriptors in the parent, and also because this
behavior is usually opt-in.

In this case, we’ll do that via an environment variable and start the child
program:

```go
// Go dup2()’s ExtraFiles to file descriptor 3 and counting.
// File descriptors 0, 1, 2 are stdin, stdout and stderr.
child.Env = append(os.Environ(), "CHILD_READY_FD=3")

// Note child.Start(), not child.Run():
if err := child.Start(); err != nil {
  return fmt.Errorf("%v: %v", child.Args, err)
}
```

At this point, both the parent and the child process have a file descriptor
referencing the write end of the pipe. Since the pipe will only be closed once
*all* processes have closed the write end, we need to close the write end in the
parent program:

```go
// Close the write end of the pipe in the parent:
w.Close()
```

Now, we can blockingly read from the pipe, and know that once the read call
returns, the child program is ready to receive requests:

```go
// Avoid hanging forever in case the child program never becomes ready;
// this is easier to diagnose than an unspecified CI/CD test timeout.
// This timeout should be much much longer than initialization takes.
r.SetReadDeadline(time.Now().Add(1 * time.Minute))
if _, err := ioutil.ReadAll(r); err != nil {
  return fmt.Errorf("awaiting readiness: %v", err)
}

// …send requests…

// …tear down child program…
```

#### Child Program

In the child program, we need to recognize that the parent program requests a
readiness notification, and ensure our signaling doesn’t leak to child programs
of the child program:

```go
var readyFile *os.File

func init() {
  if fd, err := strconv.Atoi(os.Getenv("CHILD_READY_FD")); err == nil {
    readyFile = os.NewFile(uintptr(fd), "readyfd")
    os.Unsetenv("CHILD_READY_FD")
  }
}

func main() {
  // …initialize…

  if readyFile != nil {
    readyFile.Close() // signal readiness
    readyFile = nil   // just to be prudent
  }
}
```

### Conclusion

Depending on what you’re communicating from the child to the parent, and how
your system is architected, it might be a good idea to use [systemd socket
activation](http://0pointer.de/blog/projects/socket-activation.html) ([socket
activation in
Go](https://vincent.bernat.ch/en/blog/2018-systemd-golang-socket-activation)). It
works similarly in concept, but passes a listening socket and readiness is
determined by the child process answering requests. We introduced this technique
in the [i3
testsuite](https://i3wm.org/docs/testsuite.html#_appendix_b_socket_activation)
and reduced the total wallclock time from >100 seconds to a mere 16 seconds back
then (even faster today).

The technique described in this blog post is a bit more generic than systemd’s
socket activation. In general, passing file descriptors between processes is a
powerful idea. For example, in debiman, we’re [passing individual pipe file
descriptors](https://github.com/Debian/debiman/blob/32eac1bc6182f68c7443a56b85c33522dc3d5d70/internal/convert/mandoc.go#L118)
to a persistent {{< man name="mandocd" section="8" >}} process to quickly
convert lots of man pages without encurring process creation overhead.
