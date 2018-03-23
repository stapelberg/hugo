---
layout: post
date: 2013-07-27 20:20:00 +02:00
title: "grep(1) with line continuations"
---
<p>
For some rather advanced isolation and automation work I am currently doing
with Debian Code Search I needed to modify the ExecStart= line of a systemd
service file programmatically.
</p>

<p>
The recommended interface for programmatically querying service file properties
is <code>systemctl show -p ExecStart foo.service</code>, but with the
ExecStart= property in particular, the output cannot be parsed well:
</p>

<pre>
$ systemctl show -p ExecStart dcs-batch0-source-backend.service --no-pager
ExecStart={ path=/usr/bin/source-backend ; argv[]=/usr/bin/source-backend -unpacked_path=/dcs/unpacked-new/ -listen_address=localhost:30000 ; ignore_errors=no ; start_time=[Sat 2013-07-27 19:58:23 CEST] ; stop_time=[n/a] ; pid=12428 ; code=(null) ; status=0/0 }
</pre>

<p>
Therefore, I decided to extract the ExecStart= line from the service file
directly instead of querying it from systemd. One might think that a simple
<code>grep(1)</code> call like <code>grep '^ExecStart=' foo.service</code>
would be enough, but systemd supports line continuations in the service file
syntax and I make use of that in my service files.
</p>

<p>
It is a well-known truth that whenever <code>grep(1)</code> fails,
<code>perl(1)</code> saves the day:
</p>

<pre>
perl -nlE 'say if /^ExecStart=.*[^\\]$/ || /^ExecStart=/ .. /[^\\]$/' < /lib/systemd/system/sudo.service
ExecStart=/usr/bin/find /var/lib/sudo -exec /usr/bin/touch -t 198501010000 '{}' \073
</pre>

<pre>
perl -nlE 'say if /^ExecStart=.*[^\\]$/ || /^ExecStart=/ .. /[^\\]$/' < /run/systemd/system/dcs-batch0-source-backend.service
ExecStart=/usr/bin/source-backend \
    -unpacked_path=/dcs/unpacked/ \
    -listen_address=localhost:30000
</pre>
