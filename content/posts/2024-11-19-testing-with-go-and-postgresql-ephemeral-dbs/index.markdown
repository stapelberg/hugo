---
layout: post
title:  "Testing with Go and PostgreSQL: ephemeral DBs"
date:   2024-11-19 17:04:00 +01:00
categories: Artikel
tags:
- golang
---

<a href="https://en.wikipedia.org/wiki/PostgreSQL" target="_blank"><img
src="postgresql-elephant-featured.png" align="right" width="125"
style="margin-left: 1.5em" alt="PostgreSQL elephant logo"></a>

Let’s say you created a Go program that stores data in PostgreSQL — you
installed PostgreSQL, wrote the Go code, and everything works; great!

But after writing a test for your code, you wonder: how do you best provide
PostgreSQL to your automated tests? Do you start a separate PostgreSQL in a
Docker container, for example, or do you maybe reuse your development PostgreSQL
instance?

I have come to like using **ephemeral PostgreSQL instances** for their many benefits:

* Easier development setup: no need to *configure* a database, installation is enough.
\
I recommend installing PostgreSQL from your package manager, e.g. `apt install
postgresql` (Debian) or `brew install postgresql` (macOS). No need for Docker :)
* No risk of “works on my machine” (but nowhere else) problems: every test run
  starts with an empty database instance, so your test *must* set up the database
  correctly.
* The same approach works locally and on CI systems like GitHub Actions.

In this article, I want to show how to integrate ephemeral PostgreSQL instances
into your test setup. The examples are all specific to Go, but I expect that
users of other programming languages and environments can benefit from some of
these techniques as well.

## Single-package tests

When you are in the very early stages of your project, you might start out with
just a single test file (say, `app_test.go`), containing one or more test
functions (say, `TestSignupForm`).

In this scenario, all tests will run in the same process. While it’s easy enough
to write a few lines of code to start and stop PostgreSQL, I recommend reaching
for an existing test helper package.

Throughout this article, I will be using the
[`github.com/stapelberg/postgrestest`](https://pkg.go.dev/github.com/stapelberg/postgrestest)
package, which is based on [Roxy Light’s `postgrestest`
package](https://pkg.go.dev/zombiezen.com/go/postgrestest) but was extended to
work well in the scenarios this article explains.

To start an ephemeral PostgreSQL instance before your test functions run, you
would [declare a custom `TestMain`
function](https://pkg.go.dev/testing#hdr-Main):

```go
var pgt *postgrestest.Server

func TestMain(m *testing.M) {
	var err error
	pgt, err = postgrestest.Start(context.Background())
	if err != nil {
		panic(err)
	}
	defer pgt.Cleanup()

	m.Run()
}
```

Starting a PostgreSQL instance takes about:
* 300ms on my [Intel Core i9 12900K CPU](/posts/2022-01-15-high-end-linux-pc/) (from 2022)
* 800ms on my [MacBook Air M1](/posts/2021-11-28-macbook-air-m1/) (from 2020)

Then, you can create a separate database for each test on this ephemeral
Postgres instance:

```go
func TestSignupForm(t *testing.T) {
	pgurl, err := pgt.CreateDatabase(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	// test goes here…
}
```

Each CreateDatabase call takes about:
* 5-10ms on my [Intel Core i9 12900K CPU](/posts/2022-01-15-high-end-linux-pc/) (from 2022)
* 20ms on my [MacBook Air M1](/posts/2021-11-28-macbook-air-m1/) (from 2020)


Usually, most projects quickly grow beyond just a single `_test.go` file.

In one project if mine, I eventually reached over 50 test functions in 25 Go
packages. I stuck to the above approach of adding a custom `TestMain` to each
package in which my tests needed PostgreSQL, and my test runtimes eventually
looked like this:

```
# Intel Core i9 12900K
CGO_ENABLED=0 GOGC=off go test -count=1 -fullpath ./...
14,24s user 4,11s system 709% cpu 2,586 total

# MacBook Air M1
CGO_ENABLED=0 GOGC=off go test -count=1 -fullpath ./...
20,23s user 8,67s system 350% cpu 8,257 total
```

That’s not *terrible*, but not great either.

If you happen to open a process monitor while running tests, you might have
noticed that there are quite a number of PostgreSQL instances running. This
seems like something to optimize! Shouldn’t one PostgreSQL instance be enough
for all tests of a test run?

Let’s review the process model of `go test` before we can talk about how to
integrate with it.

## go test process model

The usual command to run all tests of a Go project is `go test ./...` (see [`go
help packages`](https://pkg.go.dev/cmd/go/internal/help#HelpPackages) for
details on the `/...` pattern syntax), which matches the Go package in the
current directory and all Go packages in its subdirectories.

Each Go package (≈ directory), including `_test.go` files, is compiled into a
*separate test binary:*

```
% go help test
[…]
'Go test' recompiles each package along with any files with names matching
the file pattern "*_test.go".
[…]
Each listed package causes the execution of a separate test binary.
[…]
```

These test binaries are then run in parallel. In fact, there are two levels of
parallelism at play here:

1. All test functions (within a single test binary) that call `t.Parallel()` will be
   run in parallel (in batches of size `-parallel`).
1. `go test` will run different test binaries in parallel.

The documentation explains that the `-parallel` test flag defaults to
`GOMAXPROCS` and references the `go test` parallelism:

```
% go help testflag
[…]
-parallel n
    Allow parallel execution of test functions that call t.Parallel, and
    fuzz targets that call t.Parallel when running the seed corpus.
    The value of this flag is the maximum number of tests to run
    simultaneously.
[…]
    By default, -parallel is set to the value of GOMAXPROCS.
    Setting -parallel to values higher than GOMAXPROCS may cause degraded
    performance due to CPU contention, especially when fuzzing.
    Note that -parallel only applies within a single test binary.
    The 'go test' command may run tests for different packages
    in parallel as well, according to the setting of the -p flag
    (see 'go help build').
```

The `go test` parallelism is controlled by the `-p` flag, which also defaults to
`GOMAXPROCS`:

```
% go help build
[…]
-p n
	the number of programs, such as build commands or
	test binaries, that can be run in parallel.
	The default is GOMAXPROCS, normally the number of CPUs available.
[…]
```

To print `GOMAXPROCS` on a given machine, we can run a test program like this
`gomaxprocs.go`:

```go
package main

import "runtime"

func main() {
	print(runtime.GOMAXPROCS(0))
}
```

For me, `GOMAXPROCS` defaults to the [24 *threads* of my Intel Core i9 12900K
CPU](https://ark.intel.com/content/www/us/en/ark/products/134597/intel-core-i9-12900-processor-30m-cache-up-to-5-10-ghz.html),
which has 16 *cores* (8 Performance, 8 Efficiency; only the Performance cores
have Hyper Threading):

```
% go run gomaxprocs.go
24
% grep 'model name' /proc/cpuinfo | wc -l
24
```

So with a single `go test ./...` command, we can expect 24 parallel processes
each running 24 tests in parallel. With our current approach, we would start up
to 24 concurrent ephemeral PostgreSQL instances (if we have that many packages),
which seems wasteful to me.

Starting one ephemeral PostgreSQL instance per `go test` run seems better.

## Sharing one PostgreSQL among all tests

How can we go from starting 24 Postgres instances to starting just one?

First, we need to update our test setup code to work with a passed-in database
URL. For that, we switch from calling
[`CreateDatabase`](https://pkg.go.dev/github.com/stapelberg/postgrestest#Server.CreateDatabase)
to using a
[`DBCreator`](https://pkg.go.dev/github.com/stapelberg/postgrestest#DBCreator)
for a database identified by a URL. The old code still needs to remain so that
you can run a single test without bothering with `PGURL`:

{{< highlight go "hl_lines=4-8 17-21" >}}
var dbc *postgrestest.DBCreator

func TestMain(m *testing.M) {
	// It is best to specify the PGURL environment variable so that only
	// one PostgreSQL instance is used for all tests.
	pgurl := os.Getenv("PGURL")
	if pgurl == "" {
		// 'go test' was started directly, start one Postgres per process:
		pgt, err := postgrestest.Start(context.Background())
		if err != nil {
			panic(err)
		}
		defer pgt.Cleanup()
		pgurl = pgt.DefaultDatabase()
	}

	var err error
	dbc, err = postgrestest.NewDBCreator(pgurl)
	if err != nil {
		panic(err)
	}

	m.Run()
}
{{< /highlight >}}

Inside the test function(s), we only need to update the `CreateDatabase`
receiver name:

{{< highlight go "hl_lines=2" >}}
func TestSignupForm(t *testing.T) {
	pgurl, err := dbc.CreateDatabase(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	// test goes here…
}
{{< /highlight >}}


Then, we create a new wrapper program (e.g. `internal/cmd/initpg/initpg.go`)
which calls `postgrestest.Start` and passes the `PGURL` environment variable to
the process(es) it starts:

```go
// initpg is a small test helper command which starts a Postgres
// instance and makes it available to the wrapped 'go test' command.
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"

	"github.com/stapelberg/postgrestest"

	// Use the same database driver as in the rest of your project.
	_ "github.com/lib/pq"
)

func runWrappedCommand(pgurl string) error {
	// os.Args[0] is initpg
	// os.Args[1] is --
	// os.Args[2] is go
	// os.Args[3] is test
	// etc.
	wrapped := exec.Command(os.Args[2], os.Args[3:]...)
	wrapped.Stdin = os.Stdin
	wrapped.Stdout = os.Stdout
	wrapped.Stderr = os.Stderr
	wrapped.Env = append(os.Environ(), "PGURL="+pgurl)
	if err := wrapped.Run(); err != nil {
		return fmt.Errorf("%v: %v", wrapped.Args, err)
	}
	return nil
}

func initpg() error {
	pgt, err := postgrestest.Start(context.Background())
	// NOTE: keep reading the article, do not submit as-is
	if err != nil {
		return err
	}
	defer pgt.Cleanup()

	// Run the wrapped command ('go test', typically)
	return runWrappedCommand(pgt.DefaultDatabase())
}

func main() {
	if err := initpg(); err != nil {
		log.Fatal(err)
	}
}
```

### Running the initpg wrapper program

While we could use `go run ./internal/cmd/initpg` to compile and run this
wrapper program, it is a bit wasteful to recompile this program over and over
when it rarely changes.

One alternative is to use `go install` instead of `go run`. I have two minor
concerns with that:

1. `go install` installs into the bin directory, which is `~/go/bin` by default.

    * This means we need to rely on the `PATH` environment variable containing
      the bin directory to run the installed program. Unfortunately, influencing
      or determining the `go install` destination path is tricky.
    * It would be nice to not litter the user’s bin directory. I think the bin
      directory should contain programs which the user explicitly requested to
      install, not helper programs that are only necessary to run tests.

1. On my machine, `go install` takes about 100ms, even when nothing has changed.

I like to define a `Makefile` in each of my projects with a set of targets that
are consistently named, e.g. `make test`, `make push`, etc. Given that I already
use `make`, I like to set up my `Makefile` to build initpg in the `_bin`
directory:

```Makefile
.PHONY: test

_bin/initpg: internal/cmd/initpg/initpg.go
	mkdir -p _bin
	go build -o _bin/initpg ./internal/cmd/initpg

test: _bin/initpg
	./_bin/initpg -- go test ./...
```

Because `initpg.go` rarely changes, the program will typically not need to be
recompiled.

Note that this `Makefile` is only approximately correct: `initpg`’s dependency
on `postgrestest` is not modeled, so you need to delete `_bin/initpg` to pick up
changes to `postgrestest`.

## Performance

Let’s compare the before and after test runtimes on the Intel Core i9 12900K:

```
# Intel Core i9 12900K: one Postgres for each test
CGO_ENABLED=0 GOGC=off go test -count=1 -fullpath ./...
14,24s user 4,11s system 709% cpu 2,586 total

# Intel Core i9 12900K: one Postgres shared among all tests
CGO_ENABLED=0 GOGC=off ./_bin/initpg -- go test -count=1 -fullpath ./...
11,40s user 3,10s system 659% cpu 2,199 total
```

For comparison, the effect is more pronounced on the MacBook Air M1:

```
# MacBook Air M1: one Postgres for each test
CGO_ENABLED=0 GOGC=off go test -count=1 -fullpath ./...
20,23s user 8,67s system 350% cpu 8,257 total

# MacBook Air M1: one Postgres shared among all tests
CGO_ENABLED=0 GOGC=off ./_bin/initpg -- go test -count=1 -fullpath ./...
14,25s user 4,36s system 275% cpu 6,752 total
```

Sharing one PostgreSQL instance has reduced the total test runtime for a full
run by about 20%!

### Why is it sometimes slower?

We have measurably reduced the runtime of a full test run, but if you pay close
attention during development you will notice that now **every test run is a full
test run**, even when you only change a single package!

Why can Go no longer cache any of the test results? The problem is that the
`PGURL` environment variable has a different value on each run: the name of the
temporary directory that the `postgrestest` package uses for its ephemeral
database instance changes on each run.

The documentation on the `go test` caching behavior explains this in the last
paragraph:

{{< highlight text "hl_lines=20-21" >}}
% go help test
[…]
In package list mode only, go test caches successful package test
results to avoid unnecessary repeated running of tests. When the
result of a test can be recovered from the cache, go test will
redisplay the previous output instead of running the test binary
again. When this happens, go test prints '(cached)' in place of the
elapsed time in the summary line.

The rule for a match in the cache is that the run involves the same
test binary and the flags on the command line come entirely from a
restricted set of 'cacheable' test flags, defined as -benchtime, -cpu,
-list, -parallel, -run, -short, -timeout, -failfast, -fullpath and -v.
If a run of go test has any test or non-test flags outside this set,
the result is not cached. To disable test caching, use any test flag
or argument other than the cacheable flags. The idiomatic way to disable
test caching explicitly is to use -count=1.

Tests that open files within the package's source root (usually $GOPATH)
or that consult environment variables only match future runs in which
the files and environment variables are unchanged.
[…]
{{< /highlight >}}

(See also [Go issue #22593](https://github.com/golang/go/issues/22593) for more details.)

### Fixing Go test caching (env vars)

For the Go test caching to work, all environment variables our tests access
(including `PGURL`) need to contain the same value between runs. For us, this
means we cannot use a randomly generated name for the Postgres data directory,
but instead need to use a fixed name.

My `postgrestest` package offers convenient support for specifying the desired
directory:

{{< highlight go "hl_lines=2-7" >}}
func initpg() error {
	cacheDir, err := os.UserCacheDir()
	if err != nil {
		return err
	}
	pgt, err := postgrestest.Start(context.Background(),
		postgrestest.WithDir(filepath.Join(cacheDir, "initpg.gus")))
	if err != nil {
		return err
	}
	defer pgt.Cleanup()

	// Run the wrapped command ('go test', typically)
	return runWrappedCommand(pgt.DefaultDatabase())
}
{{< /highlight >}}

When running the tests now, starting with the second run (without any changes),
you should see a “ (cached)” suffix printed behind tests that were successfully
cached, and the test runtime should be much shorter — under a second in my
project:

```
% time ./_bin/initpg -- go test -fullpath ./...
ok  	example/internal/handlers/adminhandler	(cached)
[…]
./_bin/initpg -- go test -fullpath ./...
1,30s user 0,88s system 288% cpu 0,756 total
```

## Conclusion

In this article, I have shown how to integrate PostgreSQL into your test
environment in a way that is convenient for developers, light on system
resources and measurably reduces total test time.

Adopting `postgrestest` seems easy enough to me. If you want to see a complete
example, see [how I converted the `gokrazy/gus` repository to use
`postgrestest`](https://github.com/gokrazy/gus/commit/b97c652fd03754ba817bd3c13f18ea6e2e154ef4).

## Further optimization potential

Now that we have a detailed understanding of the `go test` process model and
PostgreSQL startup, we can consider further optimizations. I won’t actually
implement them in this article, which is already long enough, but maybe you want
to go further in your project…

### Hide Postgres startup

My journey into ephemeral PostgreSQL instances started with [Eric Radman’s
`pg_tmp` shell script](https://eradman.com/ephemeralpg/). Ultimately, I ended up
with the `postgrestest` Go solution that I much prefer: I don’t need to ship (or
require) the `pg_tmp` shell script with my projects. The fewer languages, the
better.

Also, `pg_tmp` is not a wrapper program, which resulted in problems regarding
cleanup: A wrapper program can reliably trigger cleanup when tests are done,
whereas `pg_tmp` has to poll for activity. Polling is prone to running too
quickly (cleaning up a database before tests were even started) or too slowly,
requiring constant tuning.

But, `pg_tmp` does have quite a clever concept of preparing PostgreSQL instances
in the background and thereby amortizing startup costs between test runs.

There might be an even simpler approach that could amount to the same startup
latency hiding behavior: Turning the sequential startup (`initpg` needs to wait
for PostgreSQL to start and only then can begin running `go test`) into parallel
startup using Socket Activation.

Note that PostgreSQL does not seem to support Socket Activation natively, so
probably one would need to implement a program-agnostic solution into `initpg`
as described in this [Unix Stack Exchange
question](https://unix.stackexchange.com/questions/352495/systemd-on-demand-start-of-services-like-postgresql-and-mysql-that-do-not-yet-s)
or [Andreas Rammhold’s blog
post](https://andreas.rammhold.de/posts/postgresql-tmpfs-with-sytemdsocket-activation-for-local-ephemeral-data-during-development/).

### De-duplicate schema creation cost

For isolation, we use a different PostgreSQL database for every test. This means
we need to initialize the database schema for each of these per-test databases.

We can eliminate this duplicative work by **sharing the same database** across
all tests, provided we have another way of isolating the tests from each other.

The [`txdb` package](https://github.com/DATA-DOG/go-txdb) provides a standard
`database/sql.Driver` which runs all queries of an entire test in a single
transaction. Using `txdb` means we can now safely share the same database
between tests without running into conflicts, failing tests, or needing extra
locking.

Be sure to initialize the database schema *before* using `txdb` to share the
database: long-running transactions needs to lock the PostgreSQL catalog as soon
as you change the database schema (i.e. create or modify tables), meaning only
one test can run at a time. (Using [`go tool
trace`](https://sourcegraph.com/blog/go/an-introduction-to-go-tool-trace-rhys-hiltner)
is a great way to understand such performance issues.)

I am aware that some people don’t like the transaction isolation approach. For
example, [Gajus Kuizinas’s blog post “Setting up PostgreSQL for running
integration
tests”](https://gajus.com/blog/setting-up-postgre-sql-for-running-integration-tests)
finds that transactions don’t work in their (JavaScript) setup. I don’t share
this experience at all: In Go, the [`txdb`
package](https://github.com/DATA-DOG/go-txdb) works well, even with nested
transactions. I have used `txdb` for months without problems.

In my tests, eliminating this duplicative schema initialization work saves
about:
* 0.5s on my Intel Core i9 12900K
* 1s on the MacBook Air M1
