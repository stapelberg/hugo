---
layout: post
title:  "Migrating my NAS from CoreOS/Flatcar Linux to NixOS"
date:   2025-07-13 08:17:00 +02:00
categories: Artikel
tags:
- pc
- nix
---

In this article, I want to show how to migrate an existing Linux server to NixOS
— in my case the CoreOS/Flatcar Linux installation on my Network Attached
Storage (NAS) PC.

I will show in detail how the previous CoreOS setup looked like (lots of systemd
units starting Docker containers), how I migrated it into an intermediate state
(using Docker on NixOS) just to get things going, and finally how I migrated all
units from Docker to native NixOS modules step-by-step.

If you haven’t heard of NixOS, I recommend you read the [first page of the NixOS
website](https://nixos.org) to understand what NixOS is and what sort of things
it makes possible.

The target audience of this blog post is people interested in trying out NixOS
for the use-case of a NAS, who like seeing examples to understand how to
configure a system.

You can apply these examples by first following [my blog post “How I like to
install NixOS
(declaratively)”](/posts/2025-06-01-nixos-installation-declarative/), then
making your way through the sections that interest you. If you prefer seeing the
full configuration, [skip to the conclusion](#conclusion).

{{< img src="IMG_5563.jpg" alt="PC NAS build from 2023" >}}

## Context/History {#history}

Over the last decade, I used a number of different operating systems for my
NAS needs. Here’s an overview of the 2 NAS systems storage2 and storage3:

| Year | storage2       | storage3         | Details (blog post)                                                                     |
|------|----------------|------------------|-----------------------------------------------------------------------------------------|
| 2013 | Debian on qnap | Debian on qnap   | [Wake-On-LAN with Debian on a qnap TS-119P2+](/posts/2014-01-28-qnap_ts119_wol/)        |
| 2016 | CoreOS on PC   | CoreOS on PC     | [Gigabit NAS (running CoreOS)](/posts/2016-11-21-gigabit-nas-coreos/)                   |
| 2023 | CoreOS on PC   | Ubuntu+ZFS on PC | [My all-flash ZFS NAS build](/posts/2023-10-25-my-all-flash-zfs-network-storage-build/) |
| 2025 | NixOS on PC    | Ubuntu+ZFS on PC | → you are here ←                                                                        |
| ?    | NixOS on PC    | NixOS+ZFS on PC  | Converting more PCs to NixOS seems inevitable ;)                                        |

## My NAS Software Requirements {#software-requirements}

* (This post is only about software! For my usage patterns and requirements
  regarding hardware selection, see [“Design Goals” in my My all-flash ZFS NAS
  build post
  (2023)](/posts/2023-10-25-my-all-flash-zfs-network-storage-build/#design-goals).)
* **Remote management:** I really like the model of having the configuration of
  my network storage builds version-controlled and managed on my main PC. It’s a
  nice property that I can regain access to my backup setup by re-installing my
  NAS from my PC within minutes.
* **Automated updates, with easy rollback:** Updating all my installations
  manually is not my idea of a good time. Hence, automated updates are a must —
  but when the update breaks, a quick and easy path to recovery is also a
  must.
    * CoreOS/Flatcar achieved that with an A/B updating scheme (update failed?
      boot the old partition), whereas NixOS achieves that with its concept of a
      “generation” (update failed? select the old generation), which is
      finer-grained.

## Why migrate from CoreOS/Flatcar to NixOS? {#why-migrate}

When I started using CoreOS, Docker was pretty new technology. I liked that
using Docker containers allowed you to treat services uniformly — ultimately,
they all expose a port of some sort (speaking HTTP, or Postgres, or…), so you
got the flexibility to run much more recent versions of software on a stable OS,
or older versions in case an update broke something.

Over a decade later, Docker is established tech. People nowadays take for
granted the various benefits of the container approach.

So, here’s my list of reasons why I wasn’t satisfied with Flatcar Linux anymore.

#### R1. cloud-init is deprecated {#cloud-init}

The [CoreOS cloud-init](https://github.com/coreos/coreos-cloudinit) project was
deprecated at some point in favor of
[Ignition](https://github.com/coreos/ignition), which is clearly more powerful,
but also more cumbersome to get started with as a hobbyist. As far as I can
tell, I must host my config at some URL that I then provide via a kernel
parameter. The old way of just copying a file seems to no longer be supported.

Ignition also seems less convenient in other ways: YAML is no longer supported,
only JSON, which I don’t enjoy writing by hand. Also, the format seems to
[change quite a bit](https://coreos.github.io/ignition/migrating-configs/).

As a result, I never made the jump from cloud-init to Ignition, and it’s not
good to be reliant on a long-deprecated way to use your OS of choice.

#### R2. Container Bitrot {#container-bitrot}

At some point, I did an audit of all my containers on the Docker Hub and noticed
that most of them were quite outdated. For a while, Docker Hub offered automated
builds based on a `Dockerfile` obtained from GitHub. However, automated builds
now require a subscription, and I will not accept a subscription just to use my
own computers.

#### R3. Dependency on a central service

If Docker at some point ceases operation of the Docker Hub, I am unable to
deploy software to my NAS. This isn’t a very hypothetical concern: In 2023,
Docker Hub [announced the end of organizations on the Free
tier](https://news.ycombinator.com/item?id=35154025) and then backpedaled after
community backlash.

Who knows how long they can still provide free services to hobbyists like myself.

#### R4. Could not try Immich on Flatcar {#no-immich}

The final nail in the coffin was when I noticed that I could not try Immich on
my NAS system! Modern web applications like Immich need multiple Docker
containers (for Postgres, Redis, etc.) and hence only offer [Docker
Compose](https://immich.app/docs/install/docker-compose) as a supported way of
installation.

Unfortunately, Flatcar [does not include Docker
Compose](https://github.com/flatcar/Flatcar/issues/894).

I was not in the mood to re-package Immich for non-Docker-Compose systems on an
ongoing basis, so I decided that a system on which I can neither run software
like Immich directly, nor even run Docker Compose, is not sufficient for my
needs anymore.

#### Reason Summary {#reason-summary}

With all of the above reasons, I would have had to set up automated container
builds, run my own central registry and would still be unable to run well-known
Open Source software like Immich.

Instead, I decided to try NixOS again (after a 10 year break) because it seems
like the most popular declarative solution nowadays, with a large community and
large selection of packages.

How does NixOS compare for my situation?

* Same: I also need to set up an automated job to update my NixOS systems.
  * I already have such a job for updating my [gokrazy](https://gokrazy.org) devices.
  * Docker push is asynchronous: After a successful push, I still need extra
    automation for pulling the updated containers on the target host and
    restarting the affected services, whereas NixOS includes all of that.
* Better: There is no central registry. With NixOS, I can push the build result
  directly to the target host via SSH.
* Better: The corpus of available software in NixOS is much larger (including
  Immich, for example) and the NixOS modules generally seem to be expressed at a
  higher level of abstraction than individual Docker containers, meaning you can
  configure more features with fewer lines of config.

## Prototyping in a VM {#vm-prototyping}

My NAS setup needs to work every day, so I wanted to prototype my desired
configuration in a VM before making changes to my system. This is not only
safer, it also allows me to discover any roadblocks, and what working with NixOS
feels like without making any commitments.

I copied my NixOS configuration from a previous test installation (see [“How I
like to install NixOS
(declaratively)”](/posts/2025-06-01-nixos-installation-declarative/)) and used
the following command to build a VM image and start it in QEMU:

```shell
nix build .#nixosConfigurations.storage2.config.system.build.vm

export QEMU_NET_OPTS=hostfwd=tcp::2222-:22
export QEMU_KERNEL_PARAMS=console=ttyS0
./result/bin/run-nixplay-vm
```

The configuration instructions below can be tried out in this VM, and once
you’re happy enough with what you have, you can repeat the steps on the actual
machine to migrate.

## Migrating {#migrating}

For the migration of my actual system, I defined the following milestones that
should be achievable within a typical session of about an hour (after
prototyping them in a VM):

* M1. Install NixOS
* M2. Set up remote disk unlock
* M3. Set up Samba for access
* M4. Set up SSH/rsync for backups
* Everything extra is nice-to-have and could be deferred to a future session on
  another day.

In practice, this worked out exactly as planned: the actual installation of
NixOS and setting up my config to milestone M4 took a little over one hour. All
the other nice-to-haves were done over the following days and weeks as time
permitted.

**Tip:** After losing data due to an installer bug in the 2000s, I have adopted
the habit of physically disconnecting all data disks (= pulling out the SATA
cable) when re-installing the system disk.

### M1. Install NixOS

After following [“How I like to install NixOS
(declaratively)”](/posts/2025-06-01-nixos-installation-declarative/), this is
my initial `configuration.nix`:

{{< highlight nix "hl_lines=11-79" >}}
{ modulesPath, lib, pkgs, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      ./hardware-configuration.nix
      ./disk-config.nix
    ];

  # Adding michael as trusted user means
  # we can upgrade the system via SSH (see Makefile).
  nix.settings.trusted-users = [ "michael" "root" ];
  # Clean the Nix store every week.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "storage2";
  time.timeZone = "Europe/Zurich";

  # Use systemd for networking
  services.resolved.enable = true;
  networking.useDHCP = false;
  systemd.network.enable = true;

  systemd.network.networks."10-e" = {
    matchConfig.Name = "e*";  # enp9s0 (10G) or enp8s0 (1G)
    networkConfig = {
      IPv6AcceptRA = true;
      DHCP = "yes";
    };
  };

  i18n.supportedLocales = [
    "en_DK.UTF-8/UTF-8"
    "de_DE.UTF-8/UTF-8"
    "de_CH.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];
  i18n.defaultLocale = "en_US.UTF-8";

  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;
  users.users.michael = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5secret"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5key"
    ];

    isNormalUser = true;
    description = "Michael Stapelberg";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "secret";  # XXX: change!
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
    git  # for checking out github.com/stapelberg/configfiles
    rsync
    zsh
    vim
    emacs
    wget
    curl
  ];

  programs.zsh.enable = true;

  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
{{< /highlight >}}

All following sections describe changes within this `configuration.nix`.

All devices in my home network obtain their IP address via DHCP. If I want to
make an IP address static, I configure it accordingly on my router.

My NAS PCs have one specialty with regards to IP addressing: They are reachable
via IPv4 and IPv6, and the IPv6 address can be derived from the IPv4 address.

Hence, I changed the systemd-networkd configuration from above such that it
configures a static IPv6 address in a dynamically configured IPv6 network:

{{< highlight nix "hl_lines=7-9" >}}
  systemd.network.networks."10-e" = {
    matchConfig.Name = "e*";  # enp9s0 (10G) or enp8s0 (1G)
    networkConfig = {
      IPv6AcceptRA = true;
      DHCP = "yes";
    };
    ipv6AcceptRAConfig = {
      Token = "::10:0:0:252";
    };
  };
{{< /highlight >}}

✅ This fulfills milestone M1.

### M2. Set up remote disk unlock

To unlock my encrypted disks on boot, I have a custom systemd service unit that
uses {{< man name="wget" section="1" >}} and {{< man name="cryptsetup"
section="8" >}} to split the key file between the NAS and a remote server (= an
attacker needs both pieces to unlock).

With CoreOS/Flatcar, my `cloud-init` configuration looked as follows:

```yaml
coreos:
  units:
    - name: unlock.service
      command: start
      content: |
        [Unit]
        Description=unlock hard drive
        Wants=network.target
        After=systemd-networkd-wait-online.service
        Before=samba.service

        [Service]
        Type=oneshot
        RemainAfterExit=yes
        # Wait until the host is actually reachable.
        ExecStart=/bin/sh -c "c=0; while [ $c -lt 5 ]; do /bin/ping6 -n -c 1 r.zekjur.net && break; c=$((c+1)); sleep 1; done"
        ExecStart=/bin/sh -c "[ -e \"/dev/mapper/S5SSNF0T205183F_crypt\" ] || (echo -n my_local_secret && wget --retry-connrefused --ca-directory=/dev/null --ca-certificate=/etc/ssl/certs/r.zekjur.net.crt -qO - https://r.zekjur.net:8443/nascrypto) | /sbin/cryptsetup --key-file=- luksOpen /dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNF0T205183F S5SSNF0T205183F_crypt"
        ExecStart=/bin/sh -c "[ -e \"/dev/mapper/S5SSNJ0T205991B_crypt\" ] || (echo -n my_local_secret && wget --retry-connrefused --ca-directory=/dev/null --ca-certificate=/etc/ssl/certs/r.zekjur.net.crt -qO - https://r.zekjur.net:8443/nascrypto) | /sbin/cryptsetup --key-file=- luksOpen /dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNJ0T205991B S5SSNJ0T205991B_crypt"
        ExecStart=/bin/sh -c "vgchange -ay"
        ExecStart=/bin/mount /dev/mapper/data-data /srv

write_files:
  - path: /etc/ssl/certs/r.zekjur.net.crt
    content: |
      -----BEGIN CERTIFICATE-----
      MIID8TCCAlmgAwIBAgIRAPWwvYWpoH+lGKv6rxZvC4MwDQYJKoZIhvcNAQELBQAw
      […]
      -----END CERTIFICATE-----
```

I converted it into the following NixOS configuration:

```nix
  systemd.services.unlock = {
    wantedBy = [ "multi-user.target" ];
    description = "unlock hard drive";
    wants = [ "network.target" ];
    after = [ "systemd-networkd-wait-online.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = [
        # Wait until the host is actually reachable.
        ''/bin/sh -c "c=0; while [ $c -lt 5 ]; do ${pkgs.iputils}/bin/ping -n -c 1 r.zekjur.net && break; c=$((c+1)); sleep 1; done"''

        ''/bin/sh -c "[ -e \"/dev/mapper/S5SSNF0T205183F_crypt\" ] || (echo -n my_local_secret && ${pkgs.wget}/bin/wget --retry-connrefused --ca-directory=/dev/null --ca-certificate=/etc/ssl/certs/r.zekjur.net.crt -qO - https://r.zekjur.net:8443/sdb2_crypt) | ${pkgs.cryptsetup}/bin/cryptsetup --key-file=- luksOpen /dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNF0T205183F S5SSNF0T205183F_crypt"''

        ''/bin/sh -c "[ -e \"/dev/mapper/S5SSNJ0T205991B_crypt\" ] || (echo -n my_local_secret && ${pkgs.wget}/bin/wget --retry-connrefused --ca-directory=/dev/null --ca-certificate=/etc/ssl/certs/r.zekjur.net.crt -qO - https://r.zekjur.net:8443/sdc2_crypt) | ${pkgs.cryptsetup}/bin/cryptsetup --key-file=- luksOpen /dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNJ0T205991B S5SSNJ0T205991B_crypt"''

        ''/bin/sh -c "${pkgs.lvm2}/bin/vgchange -ay"''
        ''/run/wrappers/bin/mount /dev/mapper/data-data /srv''
      ];
    };

  };
```

We’ll also need to store the custom TLS certificate file on disk. For that, we
can use the `environment.` configuration:

```nix
  environment.etc."ssl/certs/r.zekjur.net.crt".text = ''
-----BEGIN CERTIFICATE-----
MIID8TCCAlmgAwIBAgIRAPWwvYWpoH+lGKv6rxZvC4MwDQYJKoZIhvcNAQELBQAw
[…]
-----END CERTIFICATE-----
'';
```

The references like `${pkgs.wget}` will be replaced with a path to the Nix store
([→ nix.dev
documentation](https://nix.dev/tutorials/nix-language.html#paths)). On
CoreOS/Flatcar, I was limited to using just the (minimal set of) software
included in the base image, or I had to reach for Docker. On NixOS, we can use
all packages available in nixpkgs.

After [deploying](/posts/2025-06-01-nixos-installation-declarative/#making-changes)
and `reboot`ing, I can access my unlocked disk under `/srv`! 🎉

```
% df -h /srv
Filesystem             Size  Used Avail Use% Mounted on
/dev/mapper/data-data   15T   14T  342G  98% /srv
```

When listing my files, I noticed that the group id was different between my old
system and the new system. This can be fixed by explicitly specifying the
desired group id:

```nix
  users.groups.michael = {
    gid = 1000;  # for consistency with storage3
  };
```

✅ M2 is complete.

### M3. Set up Samba for access

Whereas I want to configure remote disk unlock at the systemd service level, for
Samba I want to use Docker: I wanted to first transfer my old (working)
Docker-based setups as they are, and only later convert them to Nix.

We enable the [Docker NixOS
module](https://search.nixos.org/options?query=virtualisation.docker.enable)
which sets up the daemons that Docker needs and whatever else is needed to make
it work:

```nix
  virtualisation.docker.enable = true;
```

This is already sufficient for other services to use Docker, but I also want to
be able to run the `docker` command interactively for debugging. Therefore, I
added `docker` to `systemPackages`:

{{< highlight nix "hl_lines=9" >}}
  environment.systemPackages = with pkgs; [
    git  # for checking out github.com/stapelberg/configfiles
    rsync
    zsh
    vim
    emacs
    wget
    curl
    docker
  ];
{{< /highlight >}}

After deploying this configuration, I can run `docker run -ti debian` to verify things work.

The `cloud-init` version of samba looked like this:

```yaml
coreos:
  units:
    - name: samba.service
      command: start
      content: |
        [Unit]
        Description=samba server
        After=docker.service unlock.mount
        Requires=docker.service unlock.mount

        [Service]
        Restart=always
        StartLimitInterval=0

        # Always pull the latest version (bleeding edge).
        ExecStartPre=-/usr/bin/docker pull stapelberg/docker-samba:latest

        # Set up samba users (cannot be done in the (public) Dockerfile because
        # users/passwords are sensitive information).
        ExecStartPre=-/usr/bin/docker kill smb
        ExecStartPre=-/usr/bin/docker rm smb
        ExecStartPre=-/usr/bin/docker rm smb-prep
        ExecStartPre=/usr/bin/docker run --name smb-prep stapelberg/docker-samba sh -c 'adduser --quiet --disabled-password --gecos "" --uid 29901 michael && sed -i "s,\\[global\\],[global]\\nserver multi channel support = yes\\naio read size = 1\\naio write size = 1,g" /etc/samba/smb.conf'
        ExecStartPre=/usr/bin/docker commit smb-prep smb-prepared
        ExecStartPre=/usr/bin/docker rm smb-prep
        ExecStartPre=/usr/bin/docker run --name smb-prep smb-prepared /bin/sh -c "echo \"secret\nsecret\n" | tee - | smbpasswd -a -s michael"
        ExecStartPre=/usr/bin/docker commit smb-prep smb-prepared

        ExecStart=/usr/bin/docker run \
          -p 137:137 \
          -p 138:138 \
          -p 139:139 \
          -p 445:445 \
          --tmpfs=/run \
          -v /srv/data:/srv/data \
          --name smb \
          -t \
          smb-prepared \
            /usr/sbin/smbd --foreground --debug-stdout --no-process-group
```

We can translate this 1:1 to NixOS:

```nix
  systemd.services.samba = {
    wantedBy = [ "multi-user.target" ];
    description = "samba server";
    after = [ "unlock.service" ];
    requires = [ "unlock.service" ];
    serviceConfig = {
      Restart = "always";
      StartLimitInterval = 0;
      ExecStartPre = [
        # Always pull the latest version.
        ''-${pkgs.docker}/bin/docker pull stapelberg/docker-samba:latest''

        # Set up samba users (cannot be done in the (public) Dockerfile because
        # users/passwords are sensitive information).
        ''-${pkgs.docker}/bin/docker kill smb''
        ''-${pkgs.docker}/bin/docker rm smb''
        ''-${pkgs.docker}/bin/docker rm smb-prep''
        ''-${pkgs.docker}/bin/docker run --name smb-prep stapelberg/docker-samba sh -c 'adduser --quiet --disabled-password --gecos "" --uid 29901 michael && sed -i "s,\\[global\\],[global]\\nserver multi channel support = yes\\naio read size = 1\\naio write size = 1,g" /etc/samba/smb.conf' ''
        ''-${pkgs.docker}/bin/docker commit smb-prep smb-prepared''
        ''-${pkgs.docker}/bin/docker rm smb-prep''
        ''-${pkgs.docker}/bin/docker run --name smb-prep smb-prepared /bin/sh -c "echo \"secret\nsecret\n" | tee - | smbpasswd -a -s michael"''
        ''-${pkgs.docker}/bin/docker commit smb-prep smb-prepared''
      ];

      ExecStart = ''-${pkgs.docker}/bin/docker run \
           -p 137:137 \
           -p 138:138 \
           -p 139:139 \
           -p 445:445 \
           --tmpfs=/run \
           -v /srv/data:/srv/data \
           --name smb \
           -t \
           smb-prepared \
             /usr/sbin/smbd --foreground --debug-stdout --no-process-group
             '';
    };
  };
}
```

✅ Now I can manage my files over the network, which completes M3!

See also: [Nice-to-haves: N5. samba from NixOS](#samba-nixos)

### M4. Set up SSH/rsync for backups

For backing up data, I use rsync over SSH. I restrict this SSH access to run
only rsync commands by using `rrsync` (in a Docker container). To configure the
SSH {{< man name="authorized_keys" section="5" >}}, we set:

```nix
  users.users.root.openssh.authorizedKeys.keys = [
    ''command="${pkgs.docker}/bin/docker run --log-driver none -i -e SSH_ORIGINAL_COMMAND -v /srv/backup/midna:/srv/backup/midna stapelberg/docker-rsync /srv/backup/midna" ssh-rsa AAAAB3Npublickey root@midna''
  };
```

✅ A successful test backup run completes milestone M4!

See also: [Nice-to-haves: N6. rrsync from NixOS](#rrsync-nixos)

## Nice-to-haves

### N1. Prometheus Node Exporter {#prometheus-node-exporter}

I like to monitor all my machines with [Prometheus](https://prometheus.io) (and
Grafana). For network connectivity and authentication, I use the Tailscale mesh
VPN.

To install Tailscale, I [enable its NixOS
module](https://search.nixos.org/options?query=services.tailscale.enable) and
make the `tailscale` command available:

```nix
  services.tailscale.enable = true;
  environment.systemPackages = with pkgs; [ tailscale ];
```

After deploying, I run `sudo tailscale up` and open the login link in my browser.

The Prometheus Node Exporter can also easily be enabled [through its NixOS
module](https://search.nixos.org/options?query=services.prometheus.exporters.node.enable):

```nix
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "storage2.example.ts.net";
  };
```

However, this isn’t reliable yet: When Tailscale’s startup takes a while during
system boot, the Node Exporter might burn through its entire restart budget when
it cannot listen on the Tailscale IP address yet. We can enable [indefinite
restarts](/posts/2024-01-17-systemd-indefinite-service-restarts/) for the
service to eventually come up:

```nix
  systemd.services."prometheus-node-exporter" = {
    startLimitIntervalSec = 0;
    serviceConfig = {
      Restart = "always";
      RestartSec = 1;
    };
  };
```

### N2. Reliable mounting {#reliable-mount}

While migrating my setup, I noticed that calling {{< man name="mount"
section="8" >}} from `unlock.service` directly is not reliable, and it’s better
to let systemd manage the mounting:

```nix
  fileSystems."/srv" = {
    device = "/dev/mapper/data-data";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.requires=unlock.service"
    ];
  };
```

Afterwards, I could just remove the {{< man name="mount" section="8" >}} call
from `unlock.service`:

```diff
@@ -247,7 +247,10 @@ fry/U6A=
         ''/bin/sh -c "${pkgs.lvm2.bin}/bin/vgchange -ay"''
-        ''/run/wrappers/bin/mount /dev/mapper/data-data /srv''
+        # Let systemd mount /srv based on the fileSystems./srv
+        # declaration to prevent race conditions: mount
+        # might not succeed while the fsck is still in progress,
+        # for example, which otherwise makes unlock.service fail.
       ];
     };

```

In systemd services, I can now depend on the `/srv` mount unit:

```nix
  systemd.services.jellyfin = {
    unitConfig.RequiresMountsFor = [ "/srv" ];
    wantedBy = [ "srv.mount" ];
  };
```

### N3. nginx-healthz {#nginx-healthz}

To save power, I turn off my NAS when they are not in use.

My backup orchestration uses Wake-on-LAN to start a wakeup and needs to wait
until the NAS is fully booted up and has mounted its `/srv` mount before it
can start backup jobs.

For this purpose, I have configured a web server (without any files) that
depends on the `/srv` mount. So, once the web server responds to HTTP requests,
we know `/srv` is mounted.

The `cloud-init` config looked as follows:

```yaml
coreos:
  units:
    - name: healthz.service
      command: start
      content: |
        [Unit]
        Description=nginx for /srv health check
        Wants=network.target
        After=srv.mount
        Requires=srv.mount
        StartLimitInterval=0

        [Service]
        Restart=always
        ExecStartPre=/bin/sh -c 'systemctl is-active docker.service'
        ExecStartPre=/usr/bin/docker pull nginx:1
        ExecStartPre=-/usr/bin/docker kill nginx-healthz
        ExecStartPre=-/usr/bin/docker rm -f nginx-healthz
        ExecStart=/usr/bin/docker run \
            --name nginx-healthz \
            --publish 10.0.0.252:8200:80 \
            --log-driver=journald \
            nginx:1
```

The Docker version (ported from Flatcar Linux) looks like this:

```nix
  systemd.services.healthz = {
    description = "nginx for /srv health check";
    wants = [ "network.target" ];
    unitConfig.RequiresMountsFor = [ "/srv" ];
    wantedBy = [ "srv.mount" ];
    startLimitIntervalSec = 0;
    serviceConfig = {
      Restart = "always";
      ExecStartPre = [
        ''/bin/sh -c 'systemctl is-active docker.service' ''
        ''-${pkgs.docker}/bin/docker pull nginx:1''
        ''-${pkgs.docker}/bin/docker kill nginx-healthz''
        ''-${pkgs.docker}/bin/docker rm -f nginx-healthz''
      ];

      ExecStart = [
        ''-${pkgs.docker}/bin/docker run \
            --name nginx-healthz \
            --publish 10.0.0.252:8200:80 \
            --log-driver=journald \
            nginx:1
        ''
      ];
    };
  };
```

This configuration gets a lot simpler when migrating it from Docker to NixOS:

```nix
  # Signal readiness on HTTP port 8200 once /srv is mounted:
  networking.firewall.allowedTCPPorts = [ 8200 ];
  services.caddy = {
    enable = true;
    virtualHosts."http://10.0.0.252:8200".extraConfig = ''
      respond "ok"
    '';
  };
  systemd.services.caddy = {
    unitConfig.RequiresMountsFor = [ "/srv" ];
    wantedBy = [ "srv.mount" ];
  };
```

### N4. NixOS Jellyfin {#jellyfin}

The Docker version (ported from Flatcar Linux) looks like this:

```nix
  networking.firewall.allowedTCPPorts = [ 4414 8096 ];
  systemd.services.jellyfin = {
    wantedBy = [ "multi-user.target" ];
    description = "jellyfin";
    after = [ "docker.service" "srv.mount" ];
    requires = [ "docker.service" "srv.mount" ];
    startLimitIntervalSec = 0;
    serviceConfig = {
      Restart = "always";
      ExecStartPre = [
        ''-${pkgs.docker}/bin/docker pull lscr.io/linuxserver/jellyfin:latest''
        ''-${pkgs.docker}/bin/docker rm jellyfin''
      ];
      ExecStart = [
        ''-${pkgs.docker}/bin/docker run \
          --rm \
          --net=host \
          --name=jellyfin \
          -e TZ=Europe/Zurich \
          -v /srv/jellyfin/config:/config \
          -v /srv/data/movies:/data/movies:ro \
          -v /srv/data/series:/data/series:ro \
          -v /srv/data/mp3:/data/mp3:ro \
          lscr.io/linuxserver/jellyfin:latest
        ''
      ];
    };
  };
```

As before, when using jellyfin from NixOS, the configuration gets simpler:

```nix
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.jellyfin = {
    unitConfig.RequiresMountsFor = [ "/srv" ];
    wantedBy = [ "srv.mount" ];
  };
```

For a while, I had also set up compatibility symlinks that map the old location
(`/data/movies`, inside the Docker container) to the new location
(`/srv/data/movies`), but I encountered strange issues in Jellyfin and ended up
just re-initializing my whole Jellyfin state. While the required configuration
had more lines, I found it neat to move it into its own file, so here is how to
do that:

Remove the lines above from `configuration.nix` and move them into
`jellyfin.nix`:

```nix
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/srv/jellyfin";
    cacheDir = "/srv/jellyfin/config/cache";
  };
  systemd.services.jellyfin = {
    unitConfig.RequiresMountsFor = [ "/srv" ];
    wantedBy = [ "srv.mount" ];
  };
}
```

Then, in `configuration.nix`, add `jellyfin.nix` to the `imports`:

```nix
   imports = [
     ./hardware-configuration.nix
     ./jellyfin.nix
   ];
```

### N5. NixOS samba {#samba-nixos}

To use Samba from NixOS, I replaced my `systemd.services.samba` config from M3
with this:

```nix
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      "global" = {
        "map to guest" = "bad user";
      };
      "data" = {
        "path" = "/srv/data";
        "comment" = "public data";
        "read only" = "no";
        "create mask" = "0775";
        "directory mask" = "0775";
        "guest ok" = "yes";
      };
    };
  };
  system.activationScripts.samba_user_create = ''
      smb_password="secret"
      echo -e "$smb_password\n$smb_password\n" | ${lib.getExe' pkgs.samba "smbpasswd"} -a -s michael
    '';
```

Note: Setting the samba password in the activation script works for small
setups, but if you want to keep your samba passwords out of the Nix store,
you’ll need to use a different approach. On a different machine, I use
[sops-nix](https://github.com/Mic92/sops-nix) to manage secrets and found that
refactoring the `smbpasswd` call like so works reliably:

```nix
let
  setPasswords = pkgs.writeShellScript "samba-set-passwords" ''
    set -euo pipefail
    for user in michael; do
        smb_password="$(cat /run/secrets/samba_passwords/$user)"
        echo -e "$smb_password\n$smb_password\n" | ${lib.getExe' pkgs.samba "smbpasswd"} -a -s $user
    done
  '';
in
 {
  # …
  services.samba = {
    # …as above…
  }

  systemd.services.samba-smbd.serviceConfig.ExecStartPre = [
    "${setPasswords}"
  ];

  sops.secrets."samba_passwords/michael" = {
    restartUnits = [ "samba-smbd.service" ];
  };
}
```

I also noticed that NixOS does not create a group for each user by default, but
I am used to managing my permissions like that. We can easily declare a group
like so:

```nix
  users.groups.michael = {
    gid = 1000; # for consistency with storage3
  };
  users.users.michael = {
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "docker"
      # By default, NixOS does not add users to their own group:
      # https://github.com/NixOS/nixpkgs/issues/198296
      "michael"
    ];
  };
```

### N6. NixOS rrsync {#rrsync-nixos}

The Docker version (ported from Flatcar Linux) looks like this:

```nix
  users.users.root.openssh.authorizedKeys.keys = [
    ''command="${pkgs.docker}/bin/docker run --log-driver none -i -e SSH_ORIGINAL_COMMAND -v /srv/backup/midna:/srv/backup/midna stapelberg/docker-rsync /srv/backup/midna" ssh-rsa AAAAB3Npublickey root@midna''
  ];
```

To use `rrsync` from NixOS, I changed the configuration like so:

```nix
  users.users.root.openssh.authorizedKeys.keys = [
    ''command="${pkgs.rrsync}/bin/rrsync /srv/backup/midna" ssh-rsa AAAAB3Npublickey root@midna''
  ];
```

### N7. sync.pl script {#syncpl-nixos}

The Docker version (ported from Flatcar Linux) looks like this:

```nix
  users.users.root.openssh.authorizedKeys.keys = [
    ''command="${pkgs.docker}/bin/docker run --log-driver none -i -e SSH_ORIGINAL_COMMAND -v /srv/data:/srv/data -v /root/.ssh:/root/.ssh:ro -v /etc/ssh:/etc/ssh:ro -v /etc/static/ssh:/etc/static/ssh:ro -v /nix/store:/nix/store:ro stapelberg/docker-sync",no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAAC3Npublickey sync@dr''
  ];
```

I wanted to stop managing the following `Dockerfile` to ship `sync.pl`:

```Dockerfile
FROM debian:stable

# Install full perl for Data::Dumper
RUN apt-get update \
    && apt-get install -y rsync ssh perl

ADD sync.pl /usr/bin/

ENTRYPOINT ["/usr/bin/sync.pl"]
```

To get rid of the Docker container, I translated the `sync.pl` file into a Nix
expression that writes the `sync.pl` Perl script to the Nix store:

```nix
{ pkgs }:

# For string literal escaping rules (''${), see:
# https://nix.dev/manual/nix/2.26/language/string-literals#string-literals

# For writers.writePerlBin, see https://wiki.nixos.org/wiki/Nix-writers

pkgs.writers.writePerlBin "syncpl" { libraries = []; } ''
# This script is run via ssh from dornröschen.
use strict;
use warnings;
use Data::Dumper;

if (my ($destination) = ($ENV{SSH_ORIGINAL_COMMAND} =~ /^([a-z0-9.]+)$/)) {
    print STDERR "rsync version: " . `${pkgs.rsync}/bin/rsync --version` . "\n\n";
    my @rsync = (
        "${pkgs.rsync}/bin/rsync",
        "-e",
        "ssh",
        "--max-delete=-1",
        "--verbose",
        "--stats",
        # Intentionally not setting -X for my data sync,
        # where there are no full system backups; mostly media files.
        "-ax",
        "--ignore-existing",
        "--omit-dir-times",
        "/srv/data/",
        "''${destination}:/",
    );
    print STDERR "running: " . Dumper(\@rsync) . "\n";
    exec @rsync;
} else {
    print STDERR "Could not parse SSH_ORIGINAL_COMMAND.\n";
}
''
```

I can then reference this file by importing it in my `configuration.nix` and
pointing it to the `pkgs` expression of my NixOS configuration:

{{< highlight nix "hl_lines=3-5 9 13" >}}
{ modulesPath, lib, pkgs, ... }:

let
  syncpl = import ./syncpl.nix { pkgs = pkgs; };
in {
  imports = [ ./hardware-configuration.nix ];

  users.users.root.openssh.authorizedKeys.keys = [
    ''command="${syncpl}/bin/syncpl",no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAAC3Npublickey sync@dr''
  ];

  # For interactive usage (when debugging):
  environment.systemPackages = [ syncpl ];

  # …
}
{{< /highlight >}}

This works, but is it the best approach? Here are some thoughts:

* By managing this script in a Nix expression, I can no longer use my editor’s
  Perl support.
  * I could probably also keep `sync.pl` as a separate file and use string
    interpolation in my Nix expression to inject an absolute path to the `rsync`
    binary into the script.
* Another alternative would be to add a wrapper script to my Nix expression
  which ensures that `$PATH` contains `rsync` and then the script wouldn’t need
  an absolute path anymore.
* For small glue scripts like this one, I consider it easier to manage the
  contents “inline” in the Nix expression, because it means one fewer file in my
  config directory.

### N8. Sharing configs {#flakes}

I want to configure all my NixOS systems such that my user settings are
identical everywhere.

To achieve that, I can extract parts of my `configuration.nix` into a
[`user-settings.nix`](https://github.com/stapelberg/nix/blob/main/user-settings.nix)
and then [declare an accompanying
`flake.nix`](https://github.com/stapelberg/nix/blob/30cdd7db9e0ab4b7cc3a38b7953e1b7e1e238d75/flake.nix#L7)
that provides this expression as an output.

After publishing these files in a git repository, I can reference said
repository in my `flake.nix`:

{{< highlight nix "hl_lines=4 11 26-30" >}}
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    stapelbergnix.url = "github:stapelberg/nix";
  };

  outputs =
    {
      self,
      nixpkgs,
	  stapelbergnix,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = false;
      };
    in
    {
      nixosConfigurations.storage2 = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit pkgs;
        modules = [
          ./configuration.nix
          stapelbergnix.lib.userSettings
          # Not on this machine; We have our own networking config:
          # stapelbergnix.lib.systemdNetwork
          # Use systemd-boot as bootloader
          stapelbergnix.lib.systemdBoot
        ];
      };
      formatter.${system} = pkgs.nixfmt-tree;
    };
}
{{< /highlight >}}

Everything [declared in the
`user-settings.nix`](https://github.com/stapelberg/nix/blob/main/user-settings.nix)
can now be removed from `configuration.nix`!

### N9. Trying immich! {#immich-nixos}

One of the motivating reasons for switching away from CoreOS/Flatcar was that I
couldn’t try Immich, so let’s give it a shot on NixOS:

```nix
  services.immich = {
    enable = true;
    host = "10.0.0.252";
    port = 2283;
    openFirewall = true;
    mediaLocation = "/srv/immich";
  };

  # Because /srv is a separate file system, we need to declare:
  systemd.services."immich-server" = {
    unitConfig.RequiresMountsFor = [ "/srv" ];
    wantedBy = [ "srv.mount" ];
  };
```

## Conclusion

You can find the [full configuration directory on
GitHub](https://github.com/stapelberg/zkj-nas-tools/tree/master/_2025-07-nixos-nas-configs).

I am pretty happy with this NixOS setup! Previously (with CoreOS/Flatcar), I
could declaratively manage my base system, but had to manage tons of Docker
containers in addition. With NixOS, I can declaratively manage *everything* (or
as much as makes sense).

Custom configuration like my SSH+rsync-based backup infrastructure can be
expressed cleanly, in one place, and structured at the desired level of
abstraction/reuse.

If you’re considering managing at least one other system with NixOS, I would
recommend it! One of my follow-up projects is to convert storage3 (my other NAS
build) from Ubuntu Server to NixOS as well to cut down on manual
management. Being able to just copy the entire config to set up another system,
or try out an idea in a throwaway VM, is just such a nice workflow 🥰

…but if you have just a single system to manage, probably all of this is too
complicated.
