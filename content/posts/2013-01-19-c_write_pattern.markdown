---
layout: post
title:  "The C write() pattern"
date:   2013-01-19 12:00:00
categories: Artikel
Aliases:
  - /Artikel/c_write_pattern
---


<p>
When writing data to a file descriptor (file, socket, …) in C, it is
recommended to use a loop to write the entire buffer and keep track of how many
bytes <code>write()</code> could actually write to the file descriptor. This is
how to write data to a file in C in a naive way:
</p>

<pre>
#include &lt;stdlib.h&gt;
#include &lt;string.h&gt;
#include &lt;unistd.h&gt;
#include &lt;sys/types.h&gt;
#include &lt;sys/stat.h&gt;
#include &lt;fcntl.h&gt;
#include &lt;err.h&gt;
#include &lt;errno.h&gt;

int main() {
    int fd = open("/tmp/pattern.example",
                  O_CREAT | O_TRUNC | O_RDWR,
		  S_IRUSR | S_IWUSR);
    if (fd == -1)
        err(EXIT_FAILURE, "Could not open() file");

    const char *data = "This data illustrates my point.";
    /* This is WRONG, don’t do that: */
    write(fd, data, strlen(data));

    close(fd);
    return 0;
}
</pre>

<p>
…and here is how to write data with the aforementioned pattern:
</p>

<pre>
const char *data = "This data illustrates my point.";
int written = 0;
int n;
while (written < strlen(data)) {
    if ((n = write(fd, data + written, strlen(data) - written)) < 0) {
        err(EXIT_FAILURE, "Could not write() data");
    }

    written += n;
}
</pre>

<p>
In case it is not entirely obvious what happens here:
<code>write()</code> returns the amount of bytes it wrote, and that
might be less than you specified. Therefore, we keep track of how many
bytes were written and try to write the rest, until finally all data
was written successfully. Be careful, though: a return value of -1
signals an error, so you need to handle these carefully.
</p>

<p>
The reason I am writing about this pattern is to illustrate it with
real-world examples. We recently received a bug report for i3 (ticket
#896, direct link omitted due to spam bots) which stated that i3bar
would crash in a certain setup when switching workspaces. This report
was only reproducible on OpenBSD, which tends to use conservative
buffer sizes for many things.
</p>

<p>
It turned out that the cause for the crash was <a
href="http://code.stapelberg.de/git/i3/commit/?h=next&id=f5b7bfb12ef74ddbf250e5076bbfaafd0027474c">an
error in our write code</a>, which would fail to properly call
<code>write()</code> multiple times. This never came to our attention
previously because the data we send upon workspace switches got larger only
recently and the buffer sizes on Linux still fit all of the data in a single
<code>write()</code> call.
</p>

<p>
Another interesting behavior of some system calls is that they might return an
error which means that you should just repeat that call. Two such error codes
come to mind: <code>EAGAIN</code> and <code>EINTR</code>. The former is only
relevant for non-blocking file descriptors, and means that performing that
<code>write()</code> would block the process. <code>EINTR</code> means the
system call was interrupted by a signal.
</p>

<p>
The same piece of code which contained the bug I talked about earlier was also
not prepared to handle <code>EAGAIN</code>: when you switched workspaces often
enough, the scheduler might give i3 so much CPU time — and none to i3bar — that
i3 filled up the socket buffer and <code>write()</code> returned -1 with errno
set to <code>EAGAIN</code>.
</p>

<p>
In conclusion, the correct write pattern looks like this:
</p>

<pre>
const char *data = "This data illustrates my point.";
int written = 0;
int n;
while (written < strlen(data)) {
    if ((n = write(0, data + written, strlen(data) - written)) < 0) {
        if (errno == EINTR || errno == EAGAIN)
            continue;
        err(EXIT_FAILURE, "Could not write() data");
    }

    written += n;
}
</pre>
