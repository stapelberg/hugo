---
layout: post
date: 2019-07-20
title: "Linux distributions: Can we do without hooks and triggers?"
categories: Artikel
tags:
- distri
- debian
tweet_url: "https://twitter.com/zekjur/status/1152611129602035713"
---

Hooks are an extension feature provided by all package managers that are used in
larger Linux distributions. For example, Debian uses apt, which has various
[maintainer
scripts](https://www.debian.org/doc/debian-policy/ap-flowcharts.html). Fedora
uses rpm, which has
[scriptlets](https://fedoraproject.org/wiki/Packaging:Scriptlets). Different
package managers use different names for the concept, but all of them offer
package maintainers the ability to run arbitrary code during package
installation and upgrades. Example hook use cases include adding daemon user
accounts to your system (e.g. `postgres`), or generating/updating cache files.

Triggers are a kind of hook which run when *other* packages are installed. For
example, on Debian, the [`man(1)`](https://manpages.debian.org/man.1) package
comes with a trigger which regenerates the search database index whenever any
package installs a manpage. When, for example, the
[`nginx(8)`](https://manpages.debian.org/nginx.8) package is installed, a
trigger provided by the [`man(1)`](https://manpages.debian.org/man.1) package
runs.

Over the past few decades, Open Source software has become more and more
uniform: instead of each piece of software defining its own rules, a small
number of build systems are now widely adopted.

Hence, I think it makes sense to revisit whether offering extension via hooks
and triggers is a net win or net loss.

### Hooks preclude concurrent package installation

Package managers commonly can make very little assumptions about what hooks do,
what preconditions they require, and which conflicts might be caused by running
multiple package’s hooks concurrently.

Hence, package managers cannot concurrently install packages. At least the
hook/trigger part of the installation needs to happen in sequence.

While it seems technically feasible to retrofit package manager hooks with
concurrency primitives such as locks for mutual exclusion between different hook
processes, the required overhaul of all hooks¹ seems like such a daunting task
that it might be better to just get rid of the hooks instead. Only deleting code
frees you from the burden of maintenance, automated testing and debugging.

① In Debian, there are 8620 non-generated maintainer scripts, as reported by
   `find shard*/src/*/debian -regex ".*\(pre\|post\)\(inst\|rm\)$"` on a Debian
   Code Search instance.

### Triggers slow down installing/updating other packages

Personally, I never use the
[`apropos(1)`](https://manpages.debian.org/apropos.1) command, so I don’t
appreciate the [`man(1)`](https://manpages.debian.org/man.1) package’s trigger
which updates the database used by
[`apropos(1)`](https://manpages.debian.org/apropos.1). The process takes a long
time and, because hooks and triggers must be executed serially (see previous
section), blocks my installation or update.

When I tell people this, they are often surprised to learn about the existance
of the [`apropos(1)`](https://manpages.debian.org/apropos.1) command. I suggest
adopting an opt-in model.

### Unnecessary work if programs are not used between updates

Hooks run when packages are installed. If a package’s contents are not used
between two updates, running the hook in the first update could have been
skipped. Running the hook lazily when the package contents are used reduces
unnecessary work.

As a welcome side-effect, lazy hook evaluation automatically makes the hook work
in operating system images, such as live USB thumb drives or SD card images for
the Raspberry Pi. Such images must not ship the same crypto keys (e.g. OpenSSH
host keys) to all machines, but instead generate a different key on each
machine.

Why do users keep packages installed they don’t use? It’s extra work to remember
and clean up those packages after use. Plus, users might not realize or value
that having fewer packages installed has benefits such as faster updates.

I can also imagine that there are people for whom the cost of re-installing
packages incentivizes them to just keep packages installed—you never know when
you might need the program again…

### Implemented in an interpreted language

While working on hermetic packages (more on that in another blog post), where
the contained programs are started with modified environment variables
(e.g. `PATH`) via a wrapper bash script, I noticed that the overhead of those
wrapper bash scripts quickly becomes significant. For example, when using the
excellent [magit](https://magit.vc/) interface for Git in Emacs, I encountered
second-long delays² when using hermetic packages compared to standard
packages. Re-implementing wrappers in a compiled language provided a significant
speed-up.

Similarly, getting rid of an extension point which mandates using shell scripts
allows us to build an efficient and fast implementation of a predefined set of
primitives, where you can reason about their effects and interactions.

② magit needs to run git a few times for displaying the full status, so small
   overhead quickly adds up.

### Incentivizing more upstream standardization

Hooks are an escape hatch for distribution maintainers to express anything which
their packaging system cannot express.

Distributions should only rely on well-established interfaces such as autoconf’s
classic `./configure && make && make install` (including commonly used flags) to
build a distribution package. Integrating upstream software into a distribution
should not require custom hooks. For example, instead of requiring a hook which
updates a cache of schema files, the library used to interact with those files
should transparently (re-)generate the cache or fall back to a slower code path.

Distribution maintainers are hard to come by, so we should value their time. In
particular, there is a 1:n relationship of packages to distribution package
maintainers (software is typically available in multiple Linux distributions),
so it makes sense to spend the work in the 1 and have the n benefit.

### Can we do without them?

If we want to get rid of hooks, we need another mechanism to achieve what we
currently achieve with hooks.

If the hook is not specific to the package, it can be moved to the package
manager. The desired system state should either be derived from the package
contents (e.g. required system users can be discovered from systemd service
files) or declaratively specified in the package build instructions—more on that
in another blog post. This turns hooks (arbitrary code) into configuration,
which allows the package manager to collapse and sequence the required state
changes. E.g., when 5 packages are installed which each need a new system user,
the package manager could update `/etc/passwd` just once.

If the hook is specific to the package, it should be moved into the package
contents. This typically means moving the functionality into the program start
(or the systemd service file if we are talking about a daemon). If (while?)
upstream is not convinced, you can either wrap the program or patch it. Note
that this case is relatively rare: I have worked with hundreds of packages and
the only package-specific functionality I came across was automatically
generating host keys before starting OpenSSH’s
[`sshd(8)`](https://manpages.debian.org/sshd.8)³.

There is one exception where moving the hook doesn’t work: packages which modify
state outside of the system, such as bootloaders or kernel images.

③ Even that can be moved out of a package-specific hook, [as Fedora
demonstrates](https://src.fedoraproject.org/rpms/openssh/blob/30922f629cc135e3233e263d5e3eb346f9251c4e/f/sshd-keygen%40.service).

### Conclusion

Global state modifications performed as part of package installation today use
hooks, an overly expressive extension mechanism.

Instead, all modifications should be driven by configuration. This is feasible
because there are only a few different kinds of desired state
modifications. This makes it possible for package managers to optimize package
installation.
