---
layout: post
title:  "Root on DRBD"
date:   2012-11-28 13:10:00
categories: Artikel
---


<p>
I recently started using DRBD (Distributed Replicated Block Device) on Debian
Linux to have a setup in which there are two servers: One server which hosts
some virtual machines, and its hot-standby companion which holds exactly the
same data and can take over if the hardware of the master server dies.
</p>

<p>
Now, it is clear how to setup DRBD for the RAID array which holds all the
data — DRBD’s documentation is really good. What remained unclear to me,
though, is how I can also use DRBD for the root file system. Otherwise, I’d
need to put in some extra effort to remember to replicate all root filesystem
changes, which makes the whole setup much more complex to use.
</p>

<p>
I suspect people are deploying machines like this with root filesystems that
are centrally managed by puppet or similar.
</p>

<p>
Instead, I decided to also use DRBD for the root device. While that setup is
largely undocumented and not recommended on the DRBD mailing list, for
experienced Linux administrators, it is not <strong>THAT</strong> complex.
Essentially, you need to shrink the existing root filesystem, create the DRBD
metadata and then change the initramfs so that it will start DRBD before mounting
the root filesystem.
</p>

<h2>Shrinking the root filesystem</h2>

<p>
To calculate the size to which you have to shrink the existing filesystem, you
can use the following script which performs <a
href="http://www.drbd.org/users-guide/ch-internals.html#s-meta-data-size">the
calculation documented in the DRBD manual</a>:
</p>

<pre>
#!/bin/bash

which bc &gt;/dev/null 2&gt;&amp;1
if [ ! $? -eq 0 ]; then
    echo "Error: bc is not installed"
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "Error: Please supply block device path"
    echo "Eg. /dev/vg1/backups"
    exit 1
fi

DEVICE=$1

SECTOR_SIZE=$( blockdev --getss $DEVICE )
SECTORS=$( blockdev --getsz $DEVICE )
MD_SIZE=$( echo "((($SECTORS + (2^18)-1) / 262144 * 8) + 72)" | bc )
FS_SIZE=$( echo "$SECTORS - $MD_SIZE" | bc )

MD_SIZE_MB=$( echo "($MD_SIZE / 4 / $SECTOR_SIZE) + 1" | bc )
FS_SIZE_MB=$( echo "($FS_SIZE / 4 / $SECTOR_SIZE)" | bc )

echo "Filesystem: $FS_SIZE_MB MiB"
echo "Filesystem: $FS_SIZE Sectors"
echo "Meta Data:  $MD_SIZE_MB MiB"
echo "Meta Data:  $MD_SIZE Sectors"
echo "--"
echo "Resize commands: resize2fs -p "$DEVICE $FS_SIZE_MB"M"
</pre>

<p>
You might need to boot the system using a live system so that you can shrink
the filesystem. ext4 for example does not support online shrinking.
</p>

<h2>Configure the DRBD resource</h2>

<p>
After rebooting into the system with the shrinked root filesystem, you need to
configure the DRBD resource itself. Here is what I use:
</p>

<pre>
cat &gt; /etc/drbd.d/root.res &lt;&lt;'EOT'
resource root {
       handlers {
               pri-on-incon-degr "/usr/lib/drbd/notify-pri-on-incon-degr.sh";
               pri-lost-after-sb "/usr/lib/drbd/notify-pri-lost-after-sb.sh";
               local-io-error "/usr/lib/drbd/notify-io-error.sh";
       }
       startup {
               become-primary-on master;
               # Wait 10 seconds on boot until the peer connects.
               wfc-timeout 10;
       }
       net {
	       # While DRBD uses TCP, it might not detect all errors when
	       # checksum offloading is enabled. CRC32 is computationally
	       # cheap enough to just turn it on.
               data-integrity-alg crc32c;
       }
       syncer {
               rate 100M;
               verify-alg crc32c;
       }
       on master {
               device /dev/drbd0;
               disk /dev/vda2;
               address 192.168.1.10:7789;
               meta-disk internal;
       }
       on slave {
               device /dev/drbd0;
               disk /dev/vda2;
               address 192.168.1.20:7789;
               meta-disk internal;
       }
}
EOT
</pre>

<h2>Configuring the initramfs hook</h2>

<p>
The first script we create is the one which will be placed in the initramfs
itself. It needs to set the correct hostname, setup the ethernet interface,
possibly start mdadm, then create the DRBD devices and finally mount the root
filesystem:
</p>

<pre>
cat &gt; /usr/share/initramfs-tools/scripts/drbd &lt;&lt;'EOT'
# vim:ts=4:sw=4:noet
# DRBD mounting

retry_nr=0

do_drbdmount()
{

    configure_networking

    [ "$quiet" != "y" ] && log_begin_msg "Running /scripts/drbd-premount"
    run_scripts /scripts/drbd-premount
    [ "$quiet" != "y" ] && log_end_msg

    ifconfig eth0 up
    ifconfig eth0 192.168.1.10 netmask 255.255.255.0

    hostname master

    # In case you are using mdraid:
    #mdadm --assemble --scan

    /sbin/drbdadm up all
    /sbin/drbdadm sh-b-pri all

    for x in $(cat /proc/cmdline); do
        case $x in
        drbdroot=*)
            DRBDROOT="${x#drbdroot=}"
            ;;
        esac
    done

    mount -t ext4 ${DRBDROOT} ${rootmnt}
}

mountroot()
{
    [ "$quiet" != "y" ] && log_begin_msg "Running /scripts/drbd-top"
    run_scripts /scripts/drbd-top
    [ "$quiet" != "y" ] && log_end_msg

    modprobe drbd
    # For DHCP
    modprobe af_packet

    wait_for_udev 10

    # Default delay is around 180s
    delay=${ROOTDELAY:-180}

    # loop until nfsmount succeeds
    do_drbdmount
    while [ ${retry_nr} -lt ${delay} ] && [ ! -e ${rootmnt}${init} ]; do
        [ "$quiet" != "y" ] && log_begin_msg "Retrying drbd mount"
        /bin/sleep 1
        do_drbdmount
        retry_nr=$(( ${retry_nr} + 1 ))
        [ "$quiet" != "y" ] && log_end_msg
    done

    [ "$quiet" != "y" ] && log_begin_msg "Running /scripts/drbd-bottom"
    run_scripts /scripts/drbd-bottom
    [ "$quiet" != "y" ] && log_end_msg
}
EOT
</pre>

<p>
After reading the script, it should be clear to you why such a script is not
normally included in distributions nor recommended: The dependencies are hard
to set up in a generic way (e.g. configuring the network, starting RAID arrays,
etc.).
</p>

<p>
The second script will run every time we generate a new initramfs and include
the necessary tools and files.
</p>

<pre>
cat &gt; /usr/share/initramfs-tools/hooks/drbd &lt;&lt;'EOT'
#!/bin/sh

PREREQ=""

prereqs()
{
       echo "$PREREQ"
}

case $1 in
prereqs)
       prereqs
       exit 0
       ;;
esac

. /usr/share/initramfs-tools/hook-functions

copy_exec /sbin/drbdadm
copy_exec /sbin/drbdmeta
copy_exec /sbin/drbdsetup

cp -R /etc/drbd.* "${DESTDIR}/etc/"
mkdir -p "${DESTDIR}/var/lib/drbd"
cp -p /var/lib/drbd/node_id "${DESTDIR}/var/lib/drbd/node_id"

exit 0
EOt
</pre>

<p>
Afterwards, use <code>update-initramfs -u</code> to generate a new initramfs.
You can verify that the new files are included in the initramfs by using
<code>lsinitramfs /boot/initrd.img-$(uname -r)</code>.
</p>

<p>
Without any further changes, nothing will change when you reboot.
</p>

<h2>Creating the metadata (once)</h2>

<p>
An easy way to create the metadata is to stop booting in the initramfs and use the
provided shell. Reboot the machine, then, in grub, add the parameters
<code>break=premount boot=drbd drbdroot=/dev/drbd0</code>, then run the
following commands in the resulting shell:
</p>

<pre>
modprobe drbd
ifconfig eth0 up
ifconfig eth0 192.168.1.10 netmask 255.255.255.0
hostname master
drbdadm up root
drbdadm -- --overwrite-data-of-peer primary root
mount -t ext4 /dev/drbd0 /root
exit
</pre>

<p>
Afterwards, your system should boot normally.
</p>

<h2>Boot parameters</h2>

<p>
To make the changes persistent, modify <code>GRUB_CMDLINE_LINUX_DEFAULT</code>
in <code>/etc/default/grub</code> to include <code>boot=drbd
drbdroot=/dev/drbd0</code>. Afterwards, run <code>update-grub</code>.
</p>

<p>
That’s it. Enjoy your root on DRBD :-).
</p>
