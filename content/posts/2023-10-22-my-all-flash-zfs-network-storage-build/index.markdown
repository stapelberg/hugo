---
layout: post
title:  "My 2023 all-flash ZFS NAS (Network Storage) build"
date:   2023-10-22 08:00:00 +01:00
categories: Artikel
tags:
- pc
---

For over 10 years now, I run two self-built NAS (Network Storage) devices which serve media (currently via Jellyfin) and run daily backups of all my PCs and servers.

In this article, I describe my goals, which hardware I picked for my new build (and why) and how I set it up.

## Design Goals

I use my network storage devices primarily for archival (daily backups), and secondarily as a media server. 

There are days when I don’t consume any media (TV series and movies) from my NAS, because I have my music collection mirrored to another server that’s running 24/7 anyway. In total, my NAS runs for a few hours in some evenings, and for about an hour (daily backups) in the mornings.

This usage pattern is distinctly different than, for example, running a NAS as a file server for collaborative video editing that needs to be available 24/7.

The goals of my NAS setup are:

1. Save power: each NAS build only runs when needed.
   * They must support Wake-on-LAN or [similar (ESP32 remote power button)](/posts/2022-10-09-remote-power-button/).
   * Scheduling of backups is done separately, on a Raspberry Pi with [gokrazy](https://gokrazy.org/).
   * Convenient [power off (tied to our all-lights-out button)](https://github.com/stapelberg/regelwerk/commit/8b81d7a808b1d76a0e96bdb4ab43964623d133c4) and power on (with [webwake](https://github.com/stapelberg/zkj-nas-tools/blob/master/webwake/webwake.go)).
2. Use Off-the-shelf hardware and software.
   * When hardware breaks, I can get replacements from the local PC store the same day.
   * Even when only the data disk(s) survive, I should be able to access my data when booting a standard live Linux system.
   * Minimal application software risk: I want to minimize risk for manual screw-ups or software bugs, meaning I use the venerable rsync for my backup needs (not Borg, restic, or similar). 
   * Minimal system software risk: I use reliable file systems with the minimal feature set — no LVM or btrfs snapshots, no ZFS replication, etc. To achieve redundancy, I don’t use a cluster file system with replication, instead I synchronize my two NAS builds using rsync, without the `--delete` flag.
3. Minimal failure domains: when one NAS fails, the other one keeps working.
   * Having N+1 redundancy here takes the stress out of repairing your NAS.
   * I run each NAS in a separate room, so that accidents like fires or spilled drinks only affect one machine.

#### File System: ZFS

In this specific build, I am trying out [ZFS](https://en.wikipedia.org/wiki/ZFS). Because I have two NAS builds
running, it is easy to change one variable of the system (which file system to
use) in one build, without affecting the other build.

My main motivation for using ZFS instead of [`ext4`](https://en.wikipedia.org/wiki/Ext4) is that ZFS does data checksumming, whereas ext4 only checksums metadata and the journal, but not data at rest. With large enough datasets, the chance of bit flips increases significantly, and I would prefer to know about them so that I can restore the affected files from another copy.

## Hardware

Each of the two storage builds has (almost) the same components. This makes it easy to diagnose one with the help of the other. When needed, I can swap out components of the second build to temporarily repair the first one, or vice versa.

{{< img src="IMG_1974.jpg" alt="photo of the Network Storage PC from the side, showing the Noctua case fan and CPU cooler, data disks, PSU and cables" >}}

### Base Components

| Price   | Type         | Article                                                                                                                                    | Remark                                                                                 |
|---------|--------------|--------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| 114 CHF | mainboard    | [AsRock B450 Gaming ITX/ac](https://www.digitec.ch/en/s1/product/asrock-b450-gaming-itxac-am4-amd-b450-mini-itx-motherboards-9385702)      | Mini ITX                                                                               |
| 80 CHF  | cpu          | [AMD Athlon 3000G](https://www.heise.de/preisvergleich/amd-athlon-3000g-yd3000c6m2ofh-yd3000c6fhmpk-a2174924.html?hloc=at&hloc=de)         | 35W TDP, GPU                                                                           |
| 65 CHF  | cpu cooler   | [Noctua NH-L12S](https://www.digitec.ch/de/s1/product/noctua-nh-l12s-70-mm-cpu-kuehler-6817433)                                            | silent!                                                                                |
| 58 CHF  | power supply | [Silverstone ST30SF 300W SFX](https://www.digitec.ch/en/s1/product/silverstone-power-supply-st30sf-300w-sfx-300-w-power-supply-pc-5988297) | SFX form factor                                                                                   |
| 51 CHF  | case         | [Silverstone SST-SG05BB-Lite](https://www.digitec.ch/en/s1/product/silverstone-sst-sg05bb-lite-mini-itx-mini-dtx-pc-case-3525365)          | Mini ITX                                                                               |
| 48 CHF  | system disk  | [WD Red SN700 250GB](https://www.digitec.ch/en/s1/product/wd-red-sn700-250-gb-m2-2280-ssd-17688689)                                        | M.2 NVMe                                                                               |
| 32 CHF  | case fan     | [Noctua NF-S12A ULN](https://www.digitec.ch/en/s1/product/noctua-nf-s12a-uln-120mm-1x-pc-fans-2451401)                                     | silent 120mm                                                                           |
| 28 CHF  | ram          | [8 GB DDR4 Value RAM (F4-2400C15-8GNT)](https://www.digitec.ch/en/s1/product/gskill-value-1-x-8gb-2400-mhz-ddr4-ram-dimm-ram-11056524)     |                                                                                        |

The total price of 476 CHF makes this not a cheap build.

But, I think each component is well worth its price. Here’s my thinking regarding the components:

* Why not a cheaper **system disk**? I wanted to use an M.2 NVMe disk so that I could mount it on the bottom of the mainboard instead of having to mount another SATA disk in the already-crowded case. Instead of chosing the cheapest M.2 disk I could find, I went with WD Red as a brand I recognize. While it’s not a lot of effort to re-install the system disk, it’s still annoying and something I want to avoid if possible. If spending 20 bucks saves me one disk swap + re-install, that’s well worth it for me!
* Why not skip the **system disk** entirely and install on the data disks? That makes the system harder to (re-)install, and easier to make manual errors when recovering the system. I like to physically disconnect the data disks while re-installing a NAS, for example. (I’m a fan of simple precautions that prevent drastic mistakes!)
* Why not a cheaper **CPU cooler**? In [one of my earlier NAS builds](/posts/2019-10-23-nas/), I used a (cheaper) passive CPU fan, which was directly in the air stream of the Noctua 120mm case fan. This setup was spec'ed for the CPU I used, and yet said CPU died as the only CPU to die on me in many many years. I want a reliable CPU fan, but also an absolutely silent build, so I went with the Noctua CPU cooler.
* Why not skip the **case fan**, or go with the Silverstone-supplied one? You might argue that the airflow of the CPU cooler is sufficient for this entire build. Maybe that’s true, but I don’t want to risk it. Also, there are 3 disks (two data disks and one system disk) that can benefit from additional airflow.
* Regarding the **CPU**, I chose the cheapest AMD CPU for Socket AM4, with a 35W TDP and built-in graphics. The built-in graphics means I can connect an HDMI monitor for setup and troubleshooting, without having to use the mainboard’s valuable one and only PCIe slot.
\
\
Unfortunately, AMD CPUs with 35W TDP are not readily available right now. My tip is to look around for a bit, and maybe buy a used one. Chose either the predecessor Athlon 200GE, or the newer generation Ryzen APU series, whichever you can get your hands on.
* Regarding the **mainboard**, I went with the AsRock Mini ITX series, which have served me well over the years. I started with an [AsRock AM1H-ITX](https://www.asrock.com/mb/AMD/AM1H-itx/) in 2016, then bought two [AsRock AB350 Gaming ITX/ac](https://www.digitec.ch/en/s1/product/asrock-ab350-gaming-itxac-am4-amd-b350-mini-itx-motherboards-7022839) in 2019, and recently an [AsRock B450 Gaming ITX/ac](https://www.digitec.ch/en/s1/product/asrock-b450-gaming-itxac-am4-amd-b450-mini-itx-motherboards-9385702).

As a disclaimer: the two builds I use are *very similar* to the component list above, with the following differences:

1. On storage2, I use an old AMD Ryzen 5 5600X CPU instead of the listed Athlon 3000G. The extra performance isn’t needed, and the lack of integrated graphics is annoying. But, I had the CPU lying around and didn’t want it to go to waste.
2. On storage3, I use an old AMD Athlon 200GE CPU on an [AsRock AB350](https://www.digitec.ch/en/s1/product/asrock-ab350-gaming-itxac-am4-amd-b350-mini-itx-motherboards-7022839) mainboard. 

I didn’t describe the *exact* builds I use because a component list is more useful if the components on it are actually available :-). 

### 16 TB SSD Data Disks

It used to be that Solid State Drives (SSDs) were just way too expensive compared to spinning hard disks when talking about terabyte sizes, so I used to put the largest single disk drive I could find into each NAS build: I started with 8 TB disks, then upgraded to 16 TB disks later.

Luckily, the price of flash storage has come down quite a bit: the [Samsung SSD 870 QVO (8 TB)](https://www.digitec.ch/en/s1/product/samsung-870-qvo-8000-gb-25-ssd-13388185) costs “only” 42 CHF per TB. For a total of 658 CHF, I can get 16 TB of flash storage in 2 drives:

{{< img src="2023-10-22-samsung-870qvo-featured.jpg" alt="two samsung 870 QVO disks" >}}

Of course, spinning hard disks are at 16 CHF per TB, so going all-flash is over 3x as expensive.

I decided to pay the premium to get a number of benefits:

* My NAS devices are quieter because there are no more spinning disks in them. This gives me more flexibility in where to physically locate each storage machine.
* My daily backups run quicker, meaning each NAS needs to be powered on for less time. The effect was actually quite pronounced, because figuring out which files need backing up requires a lot of random disk access. My backups used to take about 1 hour, and now finish in less than 20 minutes.
* The quick access times of SSDs solve the last remaining wrinkle in my backup scheme: deleting backups and measuring used disk space is finally fast!

### Power Usage

The choice of CPU, Mainboard and Network Card all influence the total power usage of the system. Here are a couple of measurements to give you a rough idea of the power usage:

| build    | CPU   | main board                                                                                                          | network card                                                     | idle | load |
|----------|-------|--------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|------|------|
| s2 | 5600X | [B450](https://www.digitec.ch/en/s1/product/asrock-b450-gaming-itxac-am4-amd-b450-mini-itx-motherboards-9385702)   | 10G: Mellanox ConnectX-3                                         | 26W  | 60W  |
| s3 | 200GE | [AB350](https://www.digitec.ch/en/s1/product/asrock-ab350-gaming-itxac-am4-amd-b350-mini-itx-motherboards-7022839) | 10G: [FS Intel 82599](https://www.fs.com/products/135978.html) | 28W  | 50W  |
| s3 | 200GE | [AB350](https://www.digitec.ch/en/s1/product/asrock-ab350-gaming-itxac-am4-amd-b350-mini-itx-motherboards-7022839) | 1G onboard                                                       | 23W  | 40W  |

These values were measured using a [myStrom WiFi Switch](https://mystrom.ch/de/wifi-switch/).

## Operating System

### Previously: CoreOS

Before this build, I ran my NAS using Docker containers on [CoreOS (later renamed to Container Linux)](https://en.wikipedia.org/wiki/Container_Linux), which was a light-weight Linux distribution focused on containers. There are two parts about CoreOS that I liked most.

The most important part was that CoreOS updated automatically, using an A/B updating scheme, just like I do in [gokrazy](https://gokrazy.org/). I want to run as many of my devices as possible with A/B updates.

The other bit I like is that the configuration is very clearly separated from the OS. I managed the configuration (a [cloud-init YAML file](https://cloud-init.io/)) on my main PC, so when swapping out the NAS system disk with a blank disk, I could just plug my config file into the CoreOS installer, and be done.

When CoreOS was bought by Red Hat and merged into Project Atomic, there wasn’t a good migration path and cloud-init wasn’t supported anymore. As a short-term solution, I switched from CoreOS to Flatcar Linux, a spiritual successor.

### Now: Ubuntu Server

For this build, I wanted to try out ZFS. I always got the impression that ZFS was a pain to run because its kernel modules are not included in the upstream Linux kernel source.

Then, in 2016, Ubuntu decided to include ZFS by default. There are a couple of other Linux distributions on which ZFS seems easy enough to run, like Gentoo, Arch Linux or NixOS.

I wanted to spend my “innovation tokens” on ZFS, and keep the rest boring and similar to what I already know and work with, so I chose Ubuntu Server over NixOS. It’s similar enough to Debian that I don’t need to re-learn.

Luckily, the migration path from Flatcar’s cloud-init config to Ubuntu Server is really easy: just copy over parts of the cloud-config until you’re through the entire thing. It’s like a checklist!

### Maybe later? gokrazy

In the future, it might be interesting to build a NAS setup using [gokrazy](https://gokrazy.org). In particular since we now can [run Docker containers on gokrazy](https://gokrazy.org/packages/docker-containers/), which makes running Samba or Jellyfin quite easy!

Using gokrazy instead of Ubuntu Server would get rid of a lot of moving parts. The current blocker is that ZFS is not available on gokrazy. Unfortunately that’s not easy to change, in particular also from a licensing perspective. 

## Setup

### UEFI

I changed the following UEFI settings:

* Advanced → ACPI Configuration → PCIE Devices Power On: Enabled
  * This setting is needed (but not sufficient) for Wake On LAN (WOL). You also need to enable WOL in your operating system.

* Advanced → Onboard Devices Configuration → Restore on AC/Power Loss: Power On
  * This setting ensures the machine turns back on after a power loss. Without it, WOL might not work after a power loss.

### Operating System

#### Network preparation

I like to configure static IP addresses for devices that are a permanent part of my network.

I have come to prefer configuring static addresses as static DHCP leases in my router, because then the address remains the same no matter which operating system I boot — whether it’s the installed one, or a live USB stick for debugging.

#### Ubuntu Server

1. Download Ubuntu Server from https://ubuntu.com/download/server

   * I initially let the setup program install Docker, but that’s a mistake. The setup program will get you Docker from snap (not apt), which [can’t work with the whole file system](https://stackoverflow.com/questions/52526219/docker-mkdir-read-only-file-system).

2. Disable swap:

   * `swapoff -a`
   * `$EDITOR /etc/fstab` # delete the swap line

3. Automatically load the corresponding sensors kernel module for the mainboard so that the Prometheus node exporter picks up temperature values and fan speed values:

   * `echo nct6775 | sudo tee /etc/modules`

4. Enable [unattended upgrades](https://help.ubuntu.com/community/AutomaticSecurityUpdates):

   * `dpkg-reconfigure -plow unattended-upgrades`
   * Edit `/etc/apt/apt.conf.d/50unattended-upgrades` — I like to make the following changes:

      ```
      Unattended-Upgrade::MinimalSteps "true";
      Unattended-Upgrade::Mail "michael@example.net";
      Unattended-Upgrade::MailReport "only-on-error";
      Unattended-Upgrade::Automatic-Reboot "true";
      Unattended-Upgrade::Automatic-Reboot-Time "08:00";
      Unattended-Upgrade::SyslogEnable "true";
      ```


### Network

#### Tailscale Mesh VPN

I have come to like Tailscale. It’s a mesh VPN (data flows directly between the machines) that allows me access to and from my PCs, servers and storage machines from anywhere. 

Specifically, I followed the [install Tailscale on Ubuntu 22.04 guide](https://tailscale.com/download/linux/ubuntu-2204).

#### Prometheus Node Exporter

For monitoring, I have an existing Prometheus setup. To add a new machine to my setup, I need to configure it as a new target on my Prometheus server. In addition, I need to set up Prometheus on the new machine.

First, I installed the Prometheus node exporter using `apt install prometheus-node-exporter`.

Then, I modified `/etc/default/prometheus-node-exporter` to only listen on the Tailscale IP address:

```shell
ARGS="--web.listen-address=100.85.3.16:9100"
```

Lastly, I added a systemd override to ensure the node exporter keeps trying to start until tailscale is up: the command `systemctl edit prometheus-node-exporter` opens an editor, and I configured the override like so:
   
```
# /etc/systemd/system/prometheus-node-exporter.service.d/override.conf
[Unit]
# Allow infinite restarts, even within a short time.
StartLimitIntervalSec=0

[Service]
RestartSec=1
```

#### Static IPv6 address

Similar to the static IPv4 address, I like to give my NAS a static IPv6 address as well. This way, I don’t need to reconfigure remote systems when I (sometimes temporarily) switch my NAS to a different network card with a different MAC address. Of course, this point becomes moot if I ever switch all my backups to Tailscale.

Ubuntu Server comes with Netplan by default, but I don’t know Netplan and don’t want to use it.

To switch to `systemd-networkd`, I ran:

```
apt remove --purge netplan.io
```

Then, I created a `systemd-networkd` config file with a static IPv6 token, resulting in a predictable IPv6 address:

```
$EDITOR /etc/systemd/network/enp.network
```

My config file looks like this:

```
[Match]
Name=enp*

[Network]
DHCP=yes
IPv6Token=0:0:0:0:10::253
IPv6AcceptRouterAdvertisements=yes
```

#### IPv6 firewall setup

An easy way to configure Linux’s `netfilter` firewall is to `apt install iptables-persistent`. That package takes care of saving firewall rules on shutdown and restoring them on the next system boot.

My rule setup is very simple: allow ICMP (IPv6 needs it), then set up `ACCEPT` rules for the traffic I expect, and `DROP` the rest.

Here’s my resulting `/etc/iptables/rules.v6` from such a setup:

<details>
<summary>
<code>/etc/iptables/rules.v6</code>
</summary>

```
# Generated by ip6tables-save v1.4.14 on Fri Aug 26 19:57:51 2016
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p ipv6-icmp -m comment --comment "IPv6 needs ICMPv6 to work" -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -m comment --comment "Allow packets for outgoing connections" -j ACCEPT
-A INPUT -s fe80::/10 -d fe80::/10 -m comment --comment "Allow link-local traffic" -j ACCEPT
-A INPUT -s 2001:db8::/64 -m comment --comment "local traffic" -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -m comment --comment "SSH" -j ACCEPT
COMMIT
# Completed on Fri Aug 26 19:57:51 2016
```

</details>

### Encrypted ZFS

Before you can use ZFS, you need to install the ZFS tools using `apt install zfsutils-linux`.

Then, we create a zpool that spans both SSDs:

```shell
zpool create \
  -o ashift=12 \
  srv \
  /dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNF0TC06121Z \
  /dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNF0TC06787P
```

The `-o ashift=12` ensures [proper alignment](https://wiki.archlinux.org/title/ZFS#Advanced_Format_disks) on disks with a sector size of either 512B or 4KB.

On that zpool, we now create our datasets:

```shell
(echo -n on-device-secret && \
 wget -qO - https://autounlock.zekjur.net:8443/nascrypto) | zfs create \
  -o encryption=on \
  -o compression=off \
  -o atime=off \
  -o keyformat=passphrase \
  -o keylocation=file:///dev/stdin \
  srv/data
```

The key I’m piping into `zfs create` is constructed from two halves: the on-device secret and the remote secret, which is a setup I’m using to implement an automated crypto unlock that is remotely revokable. See the next section for the corresponding `unlock.service`.

I repeated this same command (adjusting the dataset name) for each dataset: I currently have one for `data` and one for `backup`, just so that the used disk space of each major use case is separately visible:

```shell
df -h /srv /srv/backup /srv/data   
Filesystem      Size  Used Avail Use% Mounted on
srv             4,2T  128K  4,2T   1% /srv
srv/backup      8,1T  3,9T  4,2T  49% /srv/backup
srv/data         11T  6,4T  4,2T  61% /srv/data
```

#### ZFS maintenance

To detect errors on your disks, ZFS has a feature called “scrubbing”. I don’t think I need to scrub more often than monthly, but [maybe your scrubbing requirements are different](https://wiki.archlinux.org/title/ZFS#Scrubbing).

I enabled monthly scrubbing on my zpool `srv`:

```shell
systemctl enable --now zfs-scrub-monthly@srv.timer
```

On this machine, a scrub takes a little over 4 hours and keeps the disks busy:

```
  scan: scrub in progress since Wed Oct 11 16:32:05 2023
	808G scanned at 909M/s, 735G issued at 827M/s, 10.2T total
	0B repaired, 7.01% done, 03:21:02 to go
```

We can confirm by looking at the Prometheus Node Exporter metrics:

{{< img src="2023-10-11-grafana-scrub.png" alt="screenshot of a Grafana dashboard showing Prometheus Node Exporter metrics" >}}

The other maintenance-related setting I changed is to enable automated TRIM:

```shell
zpool set autotrim=on srv
```


#### Auto Crypto Unlock

To automatically unlock the encrypted datasets at boot, I’m using a custom `unlock.service` systemd service file.

My `unlock.service` constructs the crypto key from two halves: the on-device secret and the remote secret that’s downloaded over HTTPS.

This way, my NAS can boot up automatically, but in an emergency I can remotely stop this mechanism.

<details>
<summary>
My unlock.service
</summary>

```systemd
[Unit]
Description=unlock hard drive
Wants=network.target
After=systemd-networkd-wait-online.service
Before=samba.service

[Service]
Type=oneshot
RemainAfterExit=yes
# Wait until the host is actually reachable.
ExecStart=/bin/sh -c "c=0; while [ $c -lt 5 ]; do /bin/ping6 -n -c 1 autounlock.zekjur.net && break; c=$((c+1)); sleep 1; done"
ExecStart=/bin/sh -c "(echo -n secret && wget --retry-connrefused -qO - https://autounlock.zekjur.net:8443/nascrypto) | zfs load-key srv/data"
ExecStart=/bin/sh -c "(echo -n secret && wget --retry-connrefused -qO - https://autounlock.zekjur.net:8443/nascrypto) | zfs load-key srv/backup"
ExecStart=/bin/sh -c "zfs mount srv/data"
ExecStart=/bin/sh -c "zfs mount srv/backup"

[Install]
WantedBy=multi-user.target
```
</details>

### Backup

For the last 10 years, I have been doing my backups using `rsync`. 

Each machine pushes an incremental backup of its entire root file system (and any mounted file systems that should be backed up, too) to the backup destination (storage2/3).

All the machines I’m backing up run Linux and the `ext4` file system. I verified that my backup destination file systems support all the features of the backup source file system that I care about, i.e. extended attributes and POSIX ACLs.

The scheduling of backups is done by “[dornröschen](https://github.com/stapelberg/zkj-nas-tools/tree/master/dornroeschen
)”, a Go program that wakes up the backup sources and destination machines and starts the backup by triggering a command via SSH.

#### SSH configuration

The backup scheduler establishes an SSH connection to the backup source.

On the backup source, I authorized the scheduler like so, meaning it will run [`/root/backup.pl`](https://github.com/stapelberg/zkj-nas-tools/blob/master/dornroeschen/backup-remote.pl) when connecting:

```
command="/root/backup.pl",no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAAC3Nzainvalidkey backup-scheduler
```

backup.pl runs `rsync`, which establishes another SSH connection, this time from the backup source to the backup destination.

On the backup destination (storage2/3), I authorize the backup source’s SSH public key to run {{< man name="rrsync" section="1" >}}, a script that only permits running `rsync` in the specified directory: 

```
command="/usr/bin/rrsync /srv/backup/server.zekjur.net",no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAAC3Nzainvalidkey server.zekjur.net
```

#### Signaling Readiness after Wake-Up

I found it easiest to signal readiness by starting an empty HTTP server gated on `After=unlock.service` in systemd:

<details>
<summary><code>/etc/systemd/system/healthz.service</code></summary>

```systemd
[Unit]
Description=nginx for /srv health check
Wants=network.target
After=unlock.service
Requires=unlock.service
StartLimitInterval=0

[Service]
Restart=always
# https://itectec.com/unixlinux/restarting-systemd-service-on-dependency-failure/
ExecStartPre=/bin/sh -c 'systemctl is-active docker.service'
# Stay on the same major version in the hope that nginx never decides to break
# the config file syntax (or features) without doing a major version bump.
ExecStartPre=/usr/bin/docker pull nginx:1
ExecStartPre=-/usr/bin/docker kill nginx-healthz
ExecStartPre=-/usr/bin/docker rm -f nginx-healthz
ExecStart=/usr/bin/docker run \
  --name nginx-healthz \
  --publish 10.0.0.253:8200:80 \
  --log-driver=journald \
nginx:1

[Install]
WantedBy=multi-user.target
```

</details>

My [`wake`](https://github.com/stapelberg/zkj-nas-tools/blob/master/wake/wake.go) program then polls that port and returns once the server is up, i.e. the file system has been unlocked and mounted.

#### Auto Shutdown

Instead of explicitly triggering a shutdown from the scheduler program, I run “dramaqueen”, which shuts down the machine after 10 minutes, but will be inhibited while a backup is running. Optionally, shutting down can be inhibited while there are active samba sessions.

<details>
<summary><code>/etc/systemd/system/dramaqueen.service</code></summary>

```systemd
[Unit]
Description=dramaqueen
After=docker.service
Requires=docker.service

[Service]
Restart=always
StartLimitInterval=0

# Always pull the latest version (bleeding edge).
ExecStartPre=-/usr/bin/docker pull stapelberg/dramaqueen
ExecStartPre=-/usr/bin/docker rm -f dramaqueen
ExecStartPre=/usr/bin/docker create --name dramaqueen stapelberg/dramaqueen
ExecStartPre=/usr/bin/docker cp dramaqueen:/usr/bin/dramaqueen /tmp/
ExecStartPre=/usr/bin/docker rm -f dramaqueen
ExecStart=/tmp/dramaqueen -net_command=

[Install]
WantedBy=multi-user.target
```
</details>

#### Enabling Wake-on-LAN

Luckily, the network driver of the onboard network card supports WOL by
default. If that’s not the case for your network card, see [the Arch wiki 
Wake-on-LAN article](https://wiki.archlinux.org/title/Wake-on-LAN).
  
## Conclusion

I have been running a PC-based few-large-disk Network Storage setup for years at this point, and I am very happy with all the properties of the system. I expect to run a very similar setup for years to come.

The low-tech approach to backups of using rsync has worked well — without changes — for years, and I don’t see rsync going away anytime soon.

The upgrade to all-flash is really nice in terms of random access time (for incremental backups) and to eliminate one of the largest sources of noise from my builds.

ZFS seems to work fine so far and is well-integrated into Ubuntu Server.

#### Related Options

There are solutions for almost everyone’s NAS needs. This build obviously hits my personal sweet spot, but your needs and preferences might be different!

Here are a couple of related solutions:

* If you would like a more integrated solution, you could take a look at [the Odroid H3 (Celeron)](https://www.heise.de/ratgeber/Einplatinencomputer-Odroid-H3-als-NAS-und-Heimserver-einrichten-7496088.html).
* If you’re okay with less compute power, but want more power efficiency, you could use an ARM64-based Single Board Computer.
* If you want to buy a commercial solution, buy a device from qnap and fill it with SSD disks.
  * There are even commercial M.2 flash storage devices like the [ASUSTOR Flashstor](https://www.jeffgeerling.com/blog/2023/first-look-asustors-new-12-bay-all-m2-nvme-ssd-nas) becoming available! If not for the “off the shelf hardware” goal of my build, this would probably be the most interesting commercial alternative to me.
* If you want more compute power, consider a Thin Client (perhaps used) instead of a Single Board Computer.
  * [ServeTheHome](https://www.servethehome.com/) has a nice series called Project TinyMiniMicro ([introduction](https://www.servethehome.com/introducing-project-tinyminimicro-home-lab-revolution/), [blog posts](https://www.servethehome.com/tag/tinyminimicro/))
  * If you’re a heise+ subscriber, [they have a (German) article about building a NAS from a thin client](https://www.heise.de/ratgeber/Schlank-guenstig-stromsparend-NAS-mit-Thin-Client-im-Eigenbau-7546763.html).
* Very similar to thin clients is the Intel NUC (“Next Unit of Computing”): [(German) article comparing different NUC 12 devices](https://www.golem.de/news/nuc-12-pro-test-mini-kraftpakete-fuers-buero-und-mediacenter-2303-172992.html)
