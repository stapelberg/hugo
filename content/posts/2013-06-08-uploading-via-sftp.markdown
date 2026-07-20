---
layout: post
date: 2013-06-08 12:30:00 +0200
title: "Uploading packages via SFTP"
categories: Artikel
tags:
- debian
---
<p>
Yesterday I uploaded a big package and got multiple timeouts. I then figured
out that DDs can also upload using SFTP (i.e. SSH’s file transfer thingie)
instead of traditional FTP, which seems like a more modern alternative. So
let’s give that a try. With <a
href="http://people.debian.org/~paultag/dput-ng/">dput-ng</a>, the following
configuration leads to using sftp by default:
</p>

<pre>
mkdir -p ~/.dput.d/profiles/
cat &gt; ~/.dput.d/profiles/ftp-master.json &lt;&lt;EOT
{
    "fqdn": "ssh.upload.debian.org",
    "incoming": "/srv/upload.debian.org/UploadQueue/",
    "method": "sftp"
}
EOT
</pre>

<p>
Note that uploading via SFTP will lead to <a
href="http://ftp-master.debian.org/git/dak.git/">debianqueued</a> uploading the
files via FTP for you. But maybe that is more reliable than doing it yourself.
We’ll see :-).
</p>
