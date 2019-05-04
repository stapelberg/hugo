---
layout: post
date: 2019-05-23
title: "Optional dependencies don’t work"
categories: Artikel
tags:
- debian

---

In the i3 projects, we have always tried hard to avoid optional
dependencies. There are a number of reasons behind it, and as I have recently
encountered some of the downsides of optional dependencies firsthand, I
summarized my thoughts in this article.

### What is a (compile-time) optional dependency?

When building software from source, most programming languages and build systems
support conditional compilation: different parts of the source code are compiled
based on certain conditions.

An optional dependency is conditional compilation hooked up directly to a knob
(e.g. command line flag, configuration file, …), with the effect that the
software can now be built without an otherwise required dependency.

Let’s walk through a few issues with optional dependencies.

### Inconsistent experience in different environments

Software is usually not built by end users, but by packagers, at least when we
are talking about Open Source.

Hence, end users don’t see the knob for the optional dependency, they are just
presented with the fait accompli: their version of the software behaves
differently than other versions of the same software.

Depending on the kind of software, this situation can be made obvious to the
user: for example, if the optional dependency is needed to print documents, the
program can produce an appropriate error message when the user tries to print a
document.

Sometimes, this isn’t possible: when i3 introduced an optional dependency on
cairo and pangocairo, the behavior itself (rendering window titles) worked in
all configurations, but non-ASCII characters might break depending on whether i3
was compiled with cairo.

For users, it is frustrating to only discover in conversation that a program has
a feature that the user is interested in, but it’s not available on their
computer. For support, this situation can be hard to detect, and even harder to
resolve to the user’s satisfaction.

### Packaging is more complicated

Unfortunately, many build systems don’t stop the build when optional
dependencies are not present. Instead, you sometimes end up with a broken build,
or, even worse: with a successful build that does not work correctly at runtime.

This means that packagers need to closely examine the build output to know which
dependencies to make available. In the best case, there is a summary of
available and enabled options, clearly outlining what this build will
contain. In the worst case, you need to infer the features from the checks that
are done, or work your way through the `--help` output.

The better alternative is to configure your build system such that it stops when
*any* dependency was not found, and thereby have packagers acknowledge each
optional dependency by explicitly disabling the option.

### Untested code paths bit rot

Code paths which are not used will inevitably bit rot. If you have optional
dependencies, you need to test both the code path without the dependency and the
code path with the dependency. It doesn’t matter whether the tests are automated
or manual, the test matrix must cover both paths.

Interestingly enough, this principle seems to apply to all kinds of software
projects (but it slows down as change slows down): one might think that
important Open Source building blocks should have enough users to cover all
sorts of configurations.

However, consider this example: building cairo without libxrender results in all
GTK application windows, menus, etc. being displayed as empty grey
surfaces. Cairo does not fail to build without libxrender, but the code path
clearly is broken without libxrender.

### Can we do without them?

I’m not saying optional dependencies should *never* be used. In fact, for
bootstrapping, disabling dependencies can save a lot of work and can sometimes
allow breaking circular dependencies. For example, in an early bootstrapping
stage, binutils can be compiled with `--disable-nls` to disable
internationalization.

However, optional dependencies are broken so often that I conclude they are
overused. Read on and see for yourself whether you would rather commit to best
practices or not introduce an optional dependency.

### Best practices

If you do decide to make dependencies optional, please:

1. Set up automated testing for **all** code path combinations.
2. Fail the build until packagers explicitly pass a `--disable` flag.
3. Tell users their version is missing a dependency at runtime, e.g. in `--version`.
