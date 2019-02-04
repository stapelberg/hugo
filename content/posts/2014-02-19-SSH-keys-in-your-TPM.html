---
layout: post
date: 2014-02-19 08:40:00 +0100
title: "Using your TPM for SSH authentication"
categories: Artikel
tags:
- debian
---
<p>
Thomas Habets has <a
href="http://blog.habets.se/2013/11/TPM-chip-protecting-SSH-keys---properly">blogged
about using your TPM (Trusted Platform Module) for SSH authentication</a> a few
weeks ago. We worked together to get his package <a
href="https://packages.debian.org/sid/simple-tpm-pk11">simple-tpm-pk11</a> into
Debian, and it has just arrived in unstable :-).
</p>

<p>
Using simple-tpm-pk11, you can let your TPM generate a key, which you then can
use for SSH authentication. This key will never leave the TPM, so it is safer
than having your key on the filesystem (e.g. <code>~/.ssh/id_rsa</code>), since
file system access is not enough to steal your key anymore. Instead, you’ll
need remote code execution.
</p>

<p>
To use this software, first make sure your TPM is enabled in the BIOS. In my
ThinkPad X200 from 2008, the TPM is called “Security Chip”.
</p>

<p>
Afterwards, claim ownership of your TPM using <code>tpm_takeownership -z</code>
(from the <code>tpm-tools</code> package) and enter a password. You will
<strong>not</strong> need to enter this password for every SSH authentication
later (but you may choose to set a separate password for that).
</p>

<p>
Then, install <code>simple-tpm-pk11</code>, create a key, set it as your
PKCS11Provider and install the public key on the host(s) where you want to use
it:
</p>

<pre>
mkdir ~/.simple-tpm-pk11
stpm-keygen -o ~/.simple-tpm-pk11/my.key
echo key my.key &gt; ~/.simple-tpm-pk11/config
echo -e "\nHost *\n    PKCS11Provider libsimple-tpm-pk11.so" &gt;&gt; ~/.ssh/config
ssh-keygen -D libsimple-tpm-pk11.so | ssh shell.example.com tee -a .ssh/authorized_keys
</pre>

<p>
You’ll now be able to ssh into shell.example.com without having the key for
that on your file system :-).
</p>

<p>
In case you have any feedback about/troubles with the software, please feel
free to contact Thomas directly.
</p>
