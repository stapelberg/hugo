---
layout: post
date: 2013-06-09 01:03:23 +0200
title: "Survey answers part 1: systemd has too many dependencies, or it is bloated, or it does too many things, or is too complex"
categories: Artikel
tags:
- debian
---
<p>
This blog post is the first of a series of posts dealing with the results of <a
href="http://people.debian.org/~stapelberg//2013/05/27/systemd-survey-results.html">the
Debian systemd survey</a>. I intend to give a presentation at DebConf 2013,
too, so you could either read my posts, or watch the talk, or both :-).
</p>

<p>
The top concern shared by most people is:
</p>

<blockquote>
systemd has too many dependencies, or it is bloated, or it does too many things, or is too complex
</blockquote>

<p>
Now this concern actually has a lot of different facets, and I am trying to
share my opinion on each of them.
</p>

<h3>systemd has too many dependencies</h3>

<p>
First, let’s start with “too many dependencies”, because that is easy to check
and reason about. I have created  <a
href="http://people.debian.org/~stapelberg/docs/systemd-dependencies.html">a
document which lists all dependencies</a> of the systemd binary itself (pid 1)
and all the binaries which are currently shipped by the systemd Debian package.
If you don’t want to take my word for granted, please read that document.
</p>

<p>
Have you read the document? Very nice! As you can see, the systemd binary
itself has 10 dependencies (excluding libc). Now, the question is, what is bad
about dependencies? Why do people list dependencies as a top concern?
</p>

<ol>
<li>
Cyclic dependencies. When you hear that your init system depends on DBus, you
might argue that there is a cyclic dependency here, because DBus needs to be
started by the init system. However, systemd does NOT depend
on dbus-daemon (!) to boot your machine. Instead of using the system bus, it
uses a private UNIX socket. Therefore, systemd uses DBus merely as a
serialization format for IPC between its different processes. Only when you
want to access systemd via its API as a user (non-root), you actually use the
system bus. Since we are talking about DBus: DBus provides a well-tested
serialization format and IPC mechanism so that systemd doesn’t have to reinvent
the wheel and instead benefits from wide support within languages.
</li>

<li>
Complicated code. I feel like there is the implicit assumption that lots of
dependencies correlate with complicated code that is easy to break. I encourage
you to have a look at systemd’s source code: look for the places where specific
libraries are used, e.g. <a
href="http://cgit.freedesktop.org/systemd/systemd/tree/src/core/execute.c?id=v204#n657"><code>enforce_user</code>
which uses libcap</a>. You’ll notice that the code is not complex and usage of
the libraries is clear.
</li>

<li>
Software dragging in lots of library packages. The libraries which systemd uses
are already in widespread use (e.g. DBus, udev, selinux, libcap, pcre, …). On a
typical Debian installation, only very few of them will be dragged in by
systemd, if at all. As an example, on a fresh Debian Wheezy installation, less
than 10 packages will end up on your machine when running “apt-get install
systemd”.
</li>

<li>
More memory use. The Linux kernel maps libraries into memory only once, no
matter how many processes use them. As stated in the <a
href="http://people.debian.org/~stapelberg/docs/systemd-dependencies.html">dependency
list</a>, on machines where the libraries are not already loaded, systemd
brings in about 500 KiB of additional memory-mapped libraries in the worst
case. On the machines we have these days, this is a reasonable cost to pay for
all the benefits systemd gets us. This holds true on embedded systems with only
a few MiB of RAM and especially on typical workstations with 8+ GiB of RAM.
</li>
</ol>

<h3>systemd is bloated</h3>

<p>
Now, let’s talk about bloat. Again, this is a point which has many facets. I’d
like to quote the <a
href="http://en.wikipedia.org/wiki/Software_bloat">Wikipedia definition of
software bloat</a>:
</p>

<blockquote>
Software bloat is a process whereby successive versions of a computer program
become perceptibly slower, use more memory or processing power, or have higher
hardware requirements than the previous version whilst making only dubious
user-perceptible improvements. 
</blockquote>

<p>
The first part of the definition certainly does not match systemd — it is <a
href="http://web.dodds.net/~vorlon/wiki/blog/Upstart_in_Debian/">measurably
faster</a> than sysvinit. As for memory usage: systemd’s RSS is 1.8 MiB,
whereas sysvinit uses 0.8 MiB. As I argued on the “More memory use” point in
the dependencies section, I think the additional resource cost is well worth
the benefits.
</p>

<p>
Also note that systemd’s features are NOT all implemented in the binary which
is PID 1. As explained in <a
href="http://people.debian.org/~stapelberg/docs/systemd-dependencies.html">the
dependency list</a>, systemd consists of many cleanly separated binaries. So if a new
version of systemd gathers an additional feature, this does not mean that your
PID 1 will be bigger.
</p>

<p>
While systemd runs on any hardware, it has an indirect hardware requirement: it
requires some Linux kernel features (which are all enabled in Debian kernels).
That might rule out usage of systemd on really old embedded hardware where you
don’t have a chance to update the kernel. While it is sad that those machines
cannot profit from systemd, switching to systemd as a default has no downside
either: Debian continues to support sysvinit for quite some time, so these
machines will continue to work even with upcoming Debian versions.
</p>

<h3>systemd does too many things</h3>

<p>
The Wikipedia definition continues:
</p>

<blockquote>
[…] perceived bloat can occur from the software servicing a large, diverse
marketplace with many differing requirements. Most end users will feel they
only need some limited subset of the available functions and will regard the
others as unnecessary bloat, even if people with different requirements do use
them.
</blockquote>

<p>
I think the last part of the Wikipedia definition applies to systemd: it does
service a large and diverse “marketplace”. That marketplace is the entirety of
existing software which is started by an init system. Also, systemd can be used
on a wide range of hardware (embedded devices, tablets, phones, notebooks,
desktops, servers) which requires different features. As an example: on a
desktop system you typically don’t care strongly about a watchdog feature, but
on embedded or servers that feature is very handy. Similarly, on a tablet,
forward secure sealing of logfiles is not as important as on a server.
Therefore, I can understand if you feel that you don’t need many of the
features systemd provides. But please think of other users and maintainers who
are very happy with systemd’s benefits.
</p>

<p>
Also note that while systemd supports many things (in separate binaries!), you
don’t have to use them all. It still makes sense to ship them all in the same
package. Take coreutils as another example in that area. The binaries belong
together, even though you most likely haven’t used all of them (e.g. od, pr,
ptx, … :-)).
</p>

<h3>systemd is too complex</h3>

<p>
The remaining concern is that systemd is too complex. In my experience,
complexity is often inherent to a specific area and one cannot simply make it
go away. Instead, there are different models of how that complexity is
represented. Think of the monolithic Linux kernel versus the MINIX microkernel.
The latter has a very small amount of lines of source in the kernel, but puts
the complexity into userspace. The former uses a different approach with more
source in the kernel. The arguments between both camps show that neither is
clearly right or clearly wrong.
</p>

<p>
In a way, sysvinit represents the MINIX model: it has a small core (the init
binary itself), but a lot of complexity in shell scripts and external programs.
The fact that solutions are copied from one init script to another leads to
lots of subtle errors and makes code reuse really hard. systemd however has
more source code in the binaries, but requires only very simple, descriptive,
textual configuration instead of complex init scripts. To me, it seems
preferable to have the complexity in a single place instead of distributed
across lots of people and projects.
</p>

<h3>Conclusion</h3>

<p>
In a way, you are right. systemd centralizes complexity from tons of init
scripts into a single place. However, it therefore makes it very easy for
maintainers to write service files (equivalent of an init script) and provides
a consistent and reliable interface for service management. Furthermore, it is
different than sysvinit, and different solutions often seem complex at first.
While systemd consumes more resources than sysvinit, it uses them to make more
information available about services; its finer-grained service management
requires more state-keeping, but in turn offers you more control over your
services.
</p>
