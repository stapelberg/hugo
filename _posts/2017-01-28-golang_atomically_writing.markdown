---
layout: post
title:  "Atomically writing files in Go"
date:   2017-01-28 21:29:00
categories: Artikel
---
<p>
Writing files is simple, but correctly writing files atomically in a performant
way might not be as trivial as one might think. Here’s an extensively commented
function to atomically write compressed files (taken from <a
href="https://github.com/Debian/debiman">debiman</a>, the software behind <a
href="https://manpages.debian.org/">manpages.debian.org</a>):
<p>

<pre>
package main

import (
    "bufio"
    "compress/gzip"
    "io"
    "io/ioutil"
    "log"
    "os"
    "path/filepath"
)

func tempDir(dest string) string {
    tempdir := os.Getenv("TMPDIR")
    if tempdir == "" {
        // Convenient for development: decreases the chance that we
        // cannot move files due to TMPDIR being on a different file
        // system than dest.
        tempdir = filepath.Dir(dest)
    }
    return tempdir
}

func writeAtomically(dest string, compress bool, write func(w io.Writer) error) (err error) {
    f, err := ioutil.TempFile(tempDir(dest), "atomic-")
    if err != nil {
        return err
    }
    defer func() {
        // Clean up (best effort) in case we are returning with an error:
        if err != nil {
            // Prevent file descriptor leaks.
            f.Close()
            // Remove the tempfile to avoid filling up the file system.
            os.Remove(f.Name())
        }
    }()

    // Use a buffered writer to minimize write(2) syscalls.
    bufw := bufio.NewWriter(f)

    w := io.Writer(bufw)
    var gzipw *gzip.Writer
    if compress {
        // NOTE: gzip’s decompression phase takes the same time,
        // regardless of compression level. Hence, we invest the
        // maximum CPU time once to achieve the best compression.
        gzipw, err = gzip.NewWriterLevel(bufw, gzip.BestCompression)
        if err != nil {
            return err
        }
        defer gzipw.Close()
        w = gzipw
    }

    if err := write(w); err != nil {
        return err
    }

    if compress {
        if err := gzipw.Close(); err != nil {
            return err
        }
    }

    if err := bufw.Flush(); err != nil {
        return err
    }

    // Chmod the file world-readable (ioutil.TempFile creates files with
    // mode 0600) before renaming.
    if err := f.Chmod(0644); err != nil {
        return err
    }

    // fsync(2) after fchmod(2) orders writes as per
    // https://lwn.net/Articles/270891/. Can be skipped for performance for
    // idempotent applications (which only ever atomically write new files and
    // tolerate file loss) on an ordered file systems. ext3, ext4, XFS, Btrfs,
    // ZFS are ordered by default.
    f.Sync()

    if err := f.Close(); err != nil {
        return err
    }

    return os.Rename(f.Name(), dest)
}

func main() {
    if err := writeAtomically("demo.txt.gz", true, func(w io.Writer) error {
        _, err := w.Write([]byte("demo"))
        return err
    }); err != nil {
        log.Fatal(err)
    }
}
</pre>

<p>
<a href="https://manpages.debian.org/rsync.1">rsync(1)</a> will fail when it
lacks permission to read files. Hence, if you are synchronizing a repository of
files while updating it, you’ll need to set <code>TMPDIR</code> to point to a
directory on the same file system (for <a
href="https://manpages.debian.org/rename.2">rename(2)</a> to work) which is not
covered by your <a href="https://manpages.debian.org/rsync.1">rsync(1)</a>
invocation.
</p>

<p>
When calling <code>writeAtomically</code> repeatedly to create lots of small
files, you’ll notice that creating <code>gzip.Writer</code>s is actually rather
expensive. Modifying the function to re-use the same <code>gzip.Writer</code>
<a
href="https://github.com/Debian/debiman/commit/2f891341daa6c2b24dc9b0bacd3b722b057d8e9b">yielded
a significant decrease in wall-clock time</a>.
</p>

<p>
Of course, if you’re looking for maximum write performance (as opposed to
minimum resulting file size), you should use a different gzip level than
<code>gzip.BestCompression</code>.
</p>
