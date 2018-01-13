---
layout: post
title:  "Off-site backups with an apu2c4"
date:   2018-01-13 17:30:00 +01:00
categories: Artikel
---

### Background

A short summary of my backup strategy is: I run daily backups to my
[NAS](/Artikel/gigabit-nas-coreos). In order to recover from risks like my
apartment burning down or my belongings being stolen, I like to keep one copy of
my data off-site, updated less frequently.

I used to store off-site backups with the “unlimited storage” offerings of
various cloud providers.

These offers follow a similar pattern: they are announced, people sign up and
use a large amount of storage, the provider realizes they cannot make enough
money off of this pricing model, and finally the offer is cancelled.

I went through this two times, and my friend Mark’s [similar experience and
home-grown solution](https://bryars.eu/2017/10/backup-pi/) inspired me to also
build my own off-site backup.

### Introduction

I figured the office would make a good place for an external hard disk: I’m
there every workday, it’s not too far away, and there is good internet
connectivity for updating the off-site backup.

Initially, I thought just leaving the external hard disk there and updating it
over night by bringing my laptop to the office every couple of weeks would be
sufficient.

Now I know that strategy doesn’t work for me: the time would never be good
(“maybe I’ll unexpectedly need my laptop tonight!”), I would forget, or I would
not be in the mood.

Lesson learnt: **backups must not require continuous human involvement**.

The rest of this article covers the hardware I decided to use and the software
setup.

### Hardware

The external hard disk enclosure is a [T3US41 Sharkoon Swift Case PRO USB
3.0](https://www.alternate.de/Sharkoon/Swift-Case-PRO-USB-3-0-Laufwerksgeh%C3%A4use/html/product/1148212)
for 25 €.

The enclosed disk is a HGST 8TB drive for which I paid 290 € in mid 2017.

For [providing internet at our yearly retro computing
event](/Artikel/rgb2r-network), I still had a [PC Engines
apu2c4](https://pcengines.ch/apu2c4.htm) lying around, which I repurposed for my
off-site backups. For this year’s retro computing event, I’ll either borrow it
(setting it up is quick) or buy another one.

The apu2c4 has two USB 3.0 ports, so I can connect my external hard disk to it
without USB being a bottle-neck.

### Setup: installation

On the apu2c4, I installed Debian “stretch” 9, the latest Debian stable version
at the time of writing. I prepared a USB thumb drive with the netinst image:

```
% wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.2.1-amd64-netinst.iso
% cp debian-9.2.1-amd64-netinst.iso /dev/sdb
```

Then, I…

* plugged the USB thumb drive into the apu2c4
* On the serial console, pressed F10 (boot menu), then 1 (boot from USB)
* In the Debian installer, selected Help, pressed F6 (special boot parameters), entered `install console=ttyS0,115200n8`
* installed Debian as usual.
* Manually ran `update-grub`, so that GRUB refers to the boot disk by UUID instead of `root=/dev/sda1`. Especially once the external hard disk is connected, device nodes are unstable.
* On the serial console, pressed F10 (boot menu), then 4 (setup), then c to move the mSATA SSD to number 1 in boot order
* Connected the external hard disk

### Setup: persistent reverse SSH tunnel

I’m connecting the apu2c4 to a guest network port in our office, to keep it
completely separate from our corporate infrastructure. Since we don’t have
permanently assigned publically reachable IP addresses on that guest network, I
needed to set up a reverse tunnel.

First, I created an SSH private/public keypair using [`ssh-keygen(1)`](https://manpages.debian.org/stretch/openssh-client/ssh-keygen.1).

Then, I created a user account for the apu2c4 on my NAS (using cloud-config),
where the tunnel will be terminated. This account’s SSH usage is restricted to
port forwardings only:

```
users:
  - name: apu2c4
    system: true
    ssh-authorized-keys:
      - "restrict,command=\"/bin/false\",port-forwarding ssh-rsa AAAA…== root@stapelberg-apu2c4"
```

On the apu2c4, I installed the `autossh` Debian package (see the
[`autossh(1)`](https://manpages.debian.org/stretch/autossh/autossh.1) manpage
for details) and created the systemd unit file
`/etc/systemd/system/autossh-nas.service` with the following content:

```
[Unit]
Description=autossh reverse tunnel
After=network.target
Wants=network-online.target

[Service]
Restart=always
StartLimitIntervalSec=0
Environment=AUTOSSH_GATETIME=0
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -o "ExitOnForwardFailure yes" apu2c4@nas.example.net -R 2200:localhost:22

[Install]
WantedBy=multi-user.target
```

After enabling and starting the unit using `systemctl enable --now autossh-nas`,
the apu2c4 connected to the NAS and set up a reverse port-forwarding.

On the NAS, I configure SSH like so in my `/root/.ssh/config`:

```
Host apu2c4
  Hostname localhost
  Port 2200
  User root
  IdentitiesOnly yes
```

Finally, I authorized the public key of my NAS to connect to the apu2c4.

Note that this concludes the setup of the apu2c4: the device’s only purpose is
to make the external hard disk drive available remotely to my NAS, clean and
simple.

### Setup: full-disk encryption

I decided to not store the encryption key for the external hard disk on the
apu2c4, to have piece of mind in case the hard disk gets misplaced or even
stolen. Of course I trust my co-workers, but this is a matter of principle.

Hence, I amended my NAS’s cloud-config setup like so (of course with a stronger
key):

```
write_files:
  - path: /root/apu2c4.lukskey
    permissions: 0600
    owner: root:root
    content: |
    ABCDEFGHIJKL0123456789
```

…and configured the second key slot of the external hard disk to use this key.

### Setup: Backup script

I’m using a script roughly like the following to do the actual backups:

```
#!/bin/bash
# vi:ts=4:sw=4:et
set -e

/bin/ssh apu2c4 cryptsetup luksOpen --key-file - /dev/disk/by-id/ata-HGST_HDN1234 offline_crypt < /root/apu2c4.lukskey

/bin/ssh apu2c4 mount /dev/mapper/offline_crypt /mnt/offsite

# step 1: update everything but /backups
echo "$(date +'%c') syncing NAS data"

(cd /srv && /usr/bin/rsync --filter 'exclude /backup' -e ssh -ax --relative --numeric-ids ./ apu2c4:/mnt/offsite)

# step 2: copy the latest backup
hosts=$(ls /srv/backup/)
for host in $hosts
do
  latestremote=$(ls /srv/backup/${host}/ | tail -1)
  latestlocal=$(/bin/ssh apu2c4 ls /mnt/offsite/backup/${host} | tail -1)
  if [ "$latestlocal" != "$latestremote" ]
  then
    echo "$(date +'%c') syncing $host (offline: ${latestlocal}, NAS: ${latestremote})"
    /bin/ssh apu2c4 mkdir -p /mnt/offsite/backup/${host}
    (cd /srv && /usr/bin/rsync -e ssh -ax --numeric-ids ./backup/${host}/${latestremote}/ apu2c4:/mnt/offsite/backup/${host}/${latestremote} --link-dest=../${latestlocal})

    # step 3: delete all previous backups
    echo "$(date +'%c') deleting everything but ${latestremote} for host ${host}"
    ssh apu2c4 "find /mnt/offsite/backup/${host} \! \( -path \"/mnt/offsite/backup/${host}/${latestremote}/*\" -or -path \"/mnt/offsite/backup/${host}/${latestremote}\" -or -path \"/mnt/offsite/backup/${host}\" \) -delete"
  fi
done

/bin/ssh apu2c4 umount /mnt/offsite
/bin/ssh apu2c4 cryptsetup luksClose offline_crypt
/bin/ssh apu2c4 hdparm -Y /dev/disk/by-id/ata-HGST_HDN1234
```

Note that this script is not idempotent, lacking in error handling and won’t be
updated. It merely serves as an illustration of how things could work, but
specifics depend on your backup.

To run this script weekly, I created the following cloud-config on my NAS:

```
coreos:
  units:
    - name: sync-offsite.timer
      command: start
      content: |
        [Unit]
        Description=sync backups to off-site storage

        [Timer]
        OnCalendar=Sat 03:00

    - name: sync-offsite.service
      content: |
        [Unit]
        Description=sync backups to off-site storage
        After=docker.service srv.mount
        Requires=docker.service srv.mount

        [Service]
        Type=oneshot

        ExecStart=/root/sync-offsite-backup.sh
```

### Improvement: bandwidth throttling

In case your office (or off-site place) doesn’t have a lot of bandwidth
available, consider throttling your backups. Thus far, I haven’t had the need.

### Improvement: RTC-based wake-up

I couldn’t figure out whether the apu2c4 supports waking up based on a real-time
clock (RTC), and if yes, whether that works across power outages.

If so, one could keep it shut down (or suspended) during the week, and only
power it up for the actual backup update. The downside of course is that
any access (such as for restoring remotely) require physical presence.

If you know the answer, please send me an email.

### Conclusion

The presented solution is easier to integrate than most cloud storage
solutions.

Of course my setup is less failure-tolerant than decent cloud storage providers,
but given the low probability of a catastrophic event (e.g. apartment burning
down), it’s fine to just order a new hard disk or apu2c4 when either of the two
fails — for this specific class of backups, that’s an okay trade-off to make.

The upside of my setup is that the running costs are very low: the apu2c4’s few
watts of electricity usage are lost in the noise, and syncing a few hundred MB
every week is cheap enough these days.
