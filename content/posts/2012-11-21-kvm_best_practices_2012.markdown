---
layout: post
title:  "My KVM best practices (2012)"
date:   2012-11-21 13:10:00
categories: Artikel
Aliases:
  - /Artikel/kvm_best_practices_2012
---


<p>
KVM stands for Kernel-based Virtual Machine and is my preferred way of
virtualizing a Linux system, in combination with libvirt. This article
documents a few hints on what my current best practice setup is.
</p>

<p>
For the host and most VMs, I use Debian wheezy (which is not yet released as of
writing this article). I want a recent kernel and, most importantly, systemd.
</p>

<h2>Networking</h2>

<p>
An easy setup is to just use a bridge which contains the real ethernet device (eth0). However, I have noticed a few problems with IPv6 routes on bridge devices which turned out to be kernel bugs (<a href="http://git.kernel.org/?p=linux/kernel/git/davem/net-next.git;a=commit;h=23ea5a963768ff162a9ff8654589d7f7e1dfb780">1</a>, <a href="http://git.kernel.org/?p=linux/kernel/git/davem/net-next.git;a=commitdiff;h=d4596bad2a713fcd0def492b1960e6d899d5baa8">2</a>, possibly I forgot some). The symptom is similar to <a href="https://lkml.org/lkml/2012/3/25/13">this post by Marc</a>, essentially leading to VMs which don’t come up properly after rebooting the host or even rebooting just the VM.
</p>

<p>
Therefore, I use <code>tap</code> devices instead. They are a bit complicated
to setup. See <a href="http://libvirt.org/formatdomain.html#elementsNICSEthernet">the libvirt documentation on generic ethernet connections</a> and <a href="http://wiki.libvirt.org/page/Guest_won't_start_-_warning:_could_not_open_/dev/net/tun_('generic_ethernet'_interface)">this libvirt wiki page, which explains how you can lower the host protection to be able to use these interfaces</a>. Here is the XML part of the VM definition which I use:
</p>

<pre>
&lt;interface type='ethernet'&gt;
  &lt;mac address='52:54:00:fa:f1:f1'/&gt;
  &lt;script path='/etc/libvirt/qemu/networks/ifup-infra.sh'/&gt;
  &lt;target dev='tap.infra'/&gt;
  &lt;address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/&gt;
&lt;/interface&gt;
</pre>

<p>
The script <code>/etc/libvirt/qemu/networks/ifup-infra.sh</code> contains:
</p>

<pre>
#!/bin/sh
#
# Network configuration for kvm domain "infra"
#
# Generate a random (but fix) MAC address:
#     echo -n 'f6:'; openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//'
# F6 is a prefix which is considered Locally Administered because the second
# lowest bit of the first byte is set to 1.

set -e

/sbin/ip link set $1 address f6:63:cb:bb:59:e1
/sbin/ip link set $1 up
/sbin/ip -4 route add 79.140.39.194/32 dev $1
/sbin/ip -4 route add 79.140.39.198/32 via 79.140.39.194 dev $1
/sbin/ip -6 route add 2001:4d88:100e:1::/64 dev $1
# RZL VPN
/sbin/ip -6 route add 2001:4d88:100e:ccc0::/64 via 2001:4d88:100e:1::2 dev $1
/sbin/ip -6 route add 2001:4d88:100e:ccc::/64 via 2001:4d88:100e:1::2 dev $1
</pre>

<p>
The script sets a static, locally administered MAC address on the tap interface
on the host. This is necessary so that the VM can use the same link-local
address as default route.
</p>

<h2>IP Addresses</h2>

<p>
On the host, I have a /27 IPv4 network and a /48 IPv6 network. Previously, I
used an IP address configuration such as 79.140.39.194/27 inside the VM.
However, that only works when you have no special routes such as an IP address
you route into a VPN (or you add routes within each VM which is error-prone and
tiresome).
</p>

<p>
Therefore, I configure IPs in the VM with a /32 netmask, e.g. 79.140.39.194/32.
The default IPv4 route within each VM is 192.168.23.23, so that I don’t lose
one of my precious public IPs for that purpose:
</p>

<pre>
host # ip -4 address add 192.168.23.23/32 dev lo
vm # ip -4 route add 192.168.23.23 dev eth0
vm # ip -4 route add default via 192.168.23.23
</pre>

<p>
For IPv6, we use a link-local address, which depends on the MAC address we set earlier in <code>ifup-infra.sh</code>:
</p>

<pre>
vm # ip -6 route add default via fe80::f463:cbff:febb:59e1 dev eth0
</pre>

<p>
For the reference, here is the entire <code>/etc/network/interfaces</code> of a VM:
</p>

<pre>
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
    address 79.140.39.194
    netmask 255.255.255.255
    # dns-* options are implemented by the resolvconf package, if installed
    dns-nameservers 80.244.244.244
    dns-search in.zekjur.net
    post-up ip -4 route add 192.168.23.23 dev eth0
    post-up ip -4 route add default via 192.168.23.23
    post-up ip -4 address add 79.140.39.197/32 dev eth0
    post-up ip -6 address add 2001:4d88:100e:1::2/64 dev eth0
    post-up ip -6 address add 2001:4d88:100e:1::3/64 dev eth0
    post-up ip -6 route add default via fe80::f463:cbff:febb:59e1 dev eth0
    # iptables
    post-up iptables-restore < /etc/network/iptables
    post-up ip6tables-restore < /etc/network/ip6tables
</pre>

<h2>Serial console</h2>

<p>
It is benefical to be able to use the <code>virsh</code> console so that you
don’t have to use VNC to access your virtual machine’s text consoles. For VNC,
you probably need to create an SSH-tunnel first and then you might have issues
with your keyboard layout. Also, the virsh console is much faster since it’s
text-only. Either way (virsh console or VNC) can be used to recover your VM in
situations where you e.g. messed up <code>/etc/network/interfaces</code> and
the VM is not reachable over the network anymore.
</p>

<p>
Luckily, with systemd inside the VM, the only thing you have to do is modify
<code>/etc/default/grub</code> like this:
</p>

<pre>
GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0 init=/bin/systemd"
</pre>

<p>
The order is important here! See also <a
href="http://0pointer.de/blog/projects/serial-console.html">Lennart’s blog post
about serial consoles with systemd</a>.
</p>

<p>
In case you are not yet using systemd, you have to uncomment the getty entry
for ttyS0 in <code>/etc/inittab</code> to get a login prompt.
</p>

<p>
After configuring your VM accordingly, you can use <code>virsh console
infra</code> to access the VM called "infra" on serial console level.
</p>

<h2>Caching / Performance</h2>

<p>
Depending on your use-case, you might want to <a
href="http://lists.fedoraproject.org/pipermail/virt/2011-October/002956.html">change
the cache settings</a> which can bring dramatic disk bandwidth improvements in
the virtual machine at the expense of data security.
</p>

<p>
Also see the section "Performance Tuning" of <a
href="http://www.technichristian.net/2012/05/04/kvm-on-debian-squeeze-my-notes.techni">Michael
David’s post about his KVM setup</a> for further tips on performance.
</p>

<h2>Snapshots (backup)</h2>

<p>
I previously wrote <a
href="http://michael.stapelberg.de/Artikel/xen_lvm_snapshot">about snapshots to
backup virtual machines</a> and still use that approach. Unfortunately, there
is <a href="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=549691">a bug
which prevents lvremove from working properly</a>.
</p>

<p>
I updated my script to include a workaround which works in the vast majority of
cases (I only once had to clean up block devices manually in a high-load
scenario since deploying the workaround).
</p>

<p>
Find it at <a href="http://code.stapelberg.de/git/xen-lvm-snapshot/">the xen-lvm-snapshot git repository</a>.
</p>
