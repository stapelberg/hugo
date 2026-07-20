---
layout: post
date: 2017-10-22 13:20:00 +0200
title: "Which VCS do Debian’s Go package upstreams use?"
categories: Artikel
tags:
- debian
- golang
---
<p>
  In the pkg-go team, we are currently discussing which workflows we should
  standardize on.
</p>

<p>
  One of the considerations is what goes into the “upstream” Git branch of our
  repositories: should it track the upstream Git repository, or should it
  contain orig tarball imports?
</p>

<p>
  Now, tracking the upstream Git repository only works if upstream actually uses
  Git. The go tool, which is widely used within the Go community for managing Go
  packages, supports Git, Mercurial, Bazaar and Subversion. But which of these
  are actually used in practice?
</p>

<p>
  Let’s find out!
</p>

<h3>Option 1: If you have the sources lists of all suites locally anyway</h3>

<pre>
/usr/lib/apt/apt-helper cat-file \
  $(apt-get indextargets --format '$(FILENAME)' 'ShortDesc: Sources' 'Origin: Debian') \
  | sed -n 's,Go-Import-Path: ,,gp' \
  | sort -u
</pre>

<h3>Option 2: If you prefer to use a relational database over textfiles</h3>

<p>
  This is the harder option, but also the more complete one.
</p>

<p>
  First, we’ll need the Go package import paths of all Go packages which are in
  Debian. We can get them from
  the <a href="https://wiki.debian.org/ProjectB">ProjectB</a> database, Debian’s
  main PostgreSQL database containing all of the state about the Debian archive.
</p>

<p>
  Unfortunately, only Debian Developers have SSH access to a mirror of ProjectB
  at the moment. I contacted DSA to ask about providing public ProjectB access.
</p>

<pre>
  ssh mirror.ftp-master.debian.org "echo \"SELECT value FROM source_metadata \
  LEFT JOIN metadata_keys ON (source_metadata.key_id = metadata_keys.key_id) \
  WHERE metadata_keys.key = 'Go-Import-Path' GROUP BY value\" | \
    psql -A -t service=projectb" > go_import_path.txt
</pre>

<p>
  I
  uploaded <a href="https://people.debian.org/~stapelberg/2017-10-22-go_import_path.txt">a
  copy of resulting <code>go_import_path.txt</code></a>, if you’re curious.
</p>

<p>
  Now, let’s come up with a little bit of Go to print the VCS responsible for
  each specified Go import path:
</p>

<pre>
go get -u golang.org/x/tools/go/vcs
cat >vcs4.go <<'EOT'
package main

import (
	"fmt"
	"log"
	"os"
	"sync"

	"golang.org/x/tools/go/vcs"
)

func main() {
	var wg sync.WaitGroup
	for _, arg := range os.Args[1:] {
		wg.Add(1)
		go func(arg string) {
			defer wg.Done()
			rr, err := vcs.RepoRootForImportPath(arg, false)
			if err != nil {
				log.Println(err)
				return
			}
			fmt.Println(rr.VCS.Name)
		}(arg)
	}
	wg.Wait()
}
EOT
</pre>

<p>
  Lastly, run it in combination
  with <a href="https://manpages.debian.org/stretch/coreutils/uniq.1"><code>uniq(1)</code></a>
  to discover…
</p>

<pre>
go run vcs4.go $(tr '\n' ' ' < go_import_path.txt) | sort | uniq -c
    760 Git
      1 Mercurial
</pre>
