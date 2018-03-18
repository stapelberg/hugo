---
layout: post
title:  "Remote kernel logs with netconsole and rsyslog"
date:   2013-09-16 00:25:00
categories: Artikel
Aliases:
  - /Artikel/remote_syslog
---


<p>
A couple of times now, I’ve had problems with my server. The earliest one was
when a hard disk drive died. Then memory went bad and had to be replaced.
Another example was when a power supply of another machine died and took out
the whole rack. What all of these incidents have in common: after finding my
machine unreachable, I would have loved to be able to look at a logfile that
would give me a clue about what just happened. Most of the times, the relevant
kernel oopses/panics were not persisted to the syslog.
</p>

<p>
Therefore, it seems like a good idea to set up netconsole and remote syslog, so
that the server logs to another server. Of course, the other server should not
be located right next to it, but maybe even in a different data center. It
seems like a good idea to have an “I log your stuff, you log my stuff“ deal
with a friend who also owns a server.
</p>

<p>
This article walks you through setting up <code>rsyslog</code> on the receiver
(my friend’s server) and netconsole on the sender (my server).
</p>

<h2>Configuring rsyslog on the receiver</h2>

<p>
First, install <code>rsyslog</code> in case you haven’t installed it yet. This
article was tested with rsyslog 7.4.2-1. Given that rsyslog is migrating to a
newer configuration file format, the rsyslog configuration might need a few
simple changes in the future. We also need the <code>acl</code> package that
contains the <code>setfacl</code> command:
</p>

<pre>
apt-get install acl rsyslog
</pre>

<p>
We will use file system ACLs (Access Control Lists) to make sure that the
unprivileged user has read access to the logfiles. This is necessary because
rsyslog will create new files (when rotating) and cannot be told to use a
specific owner/group on a per-file basis. If you have not mounted your
filesystem with the “acl” option already, edit <code>/etc/fstab</code> and
remount the filesystem on which /var/log is stored:
</p>

<pre>
# add the “acl” mount option to /etc/fstab
vi /etc/fstab
mount -o remount,acl /
</pre>

<p>
Let’s set up a couple of variables first to make the following commands easier
to understand:
</p>

<pre>
UNPRIVUSER=michael
LOGNAME=vmhost
LOGIP=203.0.113.2
</pre>

<p>
Now let’s create a directory for each log target (so that you can have
different ACLs), give it the permissions that rsyslog will use later and set up
the ACL. With the <code>setfacl</code> command, the user $UNPRIVUSER will have
access to the directory and all files created in that directory:
</p>

<pre>
mkdir -p /var/log/remote/$LOGNAME
chown -R root.adm /var/log/remote
setfacl -m d:user:${UNPRIVUSER}:r /var/log/remote/$LOGNAME
</pre>

<p>
Since rsyslog does not listen for syslog on a remotely reachable UDP port by
default, let’s create a config file that enables remote listening and also only
stores logfiles from IP addresses that we care about persistently in the
corresponding file:
</p>

<pre>
cat &gt;/etc/rsyslog.d/zkj-remote.conf &lt;&lt;EOT
\$ModLoad imudp
\$RuleSet remote

# For each IP address that you want to store logs from,
# add and modify the following two (!) lines:
if \$fromhost-ip=='$LOGIP' then /var/log/remote/$LOGNAME/console.log
& stop

\$InputUDPServerBindRuleset remote
\$UDPServerRun 6666

\$RuleSet RSYSLOG_DefaultRuleset
EOT
</pre>

<p>
To prevent this logfile from filling up the server’s hard disk, we configure
logrotate accordingly:
</p>

<pre>
cat &gt;/etc/logrotate.d/zkj-remote &lt;&lt;'EOT'
/var/log/remote/*/*.log
{
        copytruncate
        rotate 30
        daily
        missingok
        dateext
        notifempty
        delaycompress
        compress
        maxage 31
        postrotate
                invoke-rc.d rsyslog reload > /dev/null
        endscript
}
EOT
</pre>

<p>
Now restart <code>rsyslog</code> and make sure port 6666/udp is not blocked in
your packet filter, if any.
</p>

<h2>Configuring netconsole on the sender</h2>

<p>
Given that the machine you are sending data from is most likely currently
running, let’s focus on getting netconsole working on a running Linux box first
and make it persistent later.
</p>

<p>
Let’s start with loading the necessary kernel modules, mounting the
pseudo-filesystem configfs and creating a directory for this netconsole target:
</p>

<pre>
modprobe configfs
modprobe netconsole
mount none -t configfs /sys/kernel/config
mkdir /sys/kernel/config/netconsole/target1
cd /sys/kernel/config/netconsole/target1
</pre>

<p>
Since netconsole needs to work in as many situations as possible (think of
kernel bugs), it does not do DNS or even ARP resolution, so we need to hardcode
the IP and MAC addresses we want to use. Note that if you are logging to a
server which is not in the same subnet as yours, you’ll need to specify the MAC
address of the gateway. You can get the MAC address of your gateway using these
commands:
</p>

<pre>
GATEWAY=$(ip -4 -o route get 203.0.113.2 | cut -f 3 -d ' ')
MAC=$(ip -4 neigh show $GATEWAY | cut -f 5 -d ' ')
</pre>

<p>
So, let’s save the parameters and enable logging:
</p>

<pre>
echo 203.0.113.2 > remote_ip
echo 198.51.100.1 > local_ip
echo $MAC > remote_mac
echo 1 > enabled
</pre>

<p>
The kernel will print the configuration, so you can verify that everything was
configured okay using <code>dmesg | tail -20</code>.
</p>

<p>
Before we test whether the setup works, we need to increase the kernel log
level, which is too low by default. By setting it to 7 (debug), we log
everything:
</p>

<pre>
echo 7 > /proc/sys/kernel/printk
</pre>

<p>
That’s it! To trigger a kernel log message you can use either of these (or
both):
</p>

<pre>
echo 'Hello from the sender' > /dev/kmsg
# Dump memory stats (no side effects)
echo m > /proc/sysrq-trigger
</pre>

<p>
You should now see messages in the log file on the receiver.
</p>

<h2>Making the netconsole settings persistent</h2>

<p>
Ideally, we want to have early boot in the logfile, so the best way of
persisting these settings is to add them to the kernel command line in
<code>/etc/default/grub</code>:
</p>

<pre>
GRUB_CMDLINE_LINUX_DEFAULT="init=/bin/systemd panic=10 loglevel=7 \
netconsole=6665@198.51.100.1/eth0,6666@203.0.113.2/00:1d:d4:e2:43:01"
</pre>

<p>
Don’t forget to run <code>update-grub</code> to write these changes to
<code>/boot</code>.
</p>
