---
layout: post
title:  "How I configured and then promptly returned a MikroTik CCR2004 router for Fiber7"
date:   2021-05-28 14:57:00 +02:00
categories: Artikel
tags:
- fiber
---

init7 recently announced that with their [FTTH fiber offering
Fiber7](https://www.init7.net/en/internet/fiber7/), they will now sell and
connect you with 25 Gbit/s (Fiber7-X2) or 10 Gbit/s (Fiber7-X) fiber optics, if
you want more than 1 Gbit/s.

This is possible thanks to the upgrade of their network infrastructure as part
of their “lifecycle management”, meaning the old networking gear was declared as
end-of-life. The new networking gear supports not only SFP+ modules (10 Gbit/s),
but also SFP28 modules (25 Gbit/s).

Availability depends on the [POP (Point Of Presence, German «Anschlusszentrale»)
you’re connected to](https://www.init7.net/en/infrastructure/fiber7-pops/). My
POP is planned to be upgraded in September.

Nevertheless, I wanted to already prepare my end of the connection, and ordered
the only router that [init7 currently lists as compatible with
Fiber7-X/X2](https://www.init7.net/en/internet/hardware/): the MikroTik
CCR2004-1G-12S+2XS.

{{< img src="mikrotik-ccr2004.jpg" alt="MikroTik CCR2004-1G-12S+2XS" >}}

The rest of this article walks through what I needed to configure (a lot,
compared to Ubiquiti or OpenWRT) in the hope that it helps other MikroTik users,
and then ends in [Why I returned it](#returned).

## Configuration

Connect an Ethernet cable to the management port on the MikroTik and:

1. log into the system using `ssh admin@192.168.88.1`
1. point a web browser to “Webfig” at http://192.168.88.1/ (no login required)

## Update firmware

Update the CCR2004 to the latest firmware version. At the time of writing, the
Long-term RouterOS track is [at version 6.47.9](https://mikrotik.com/download)
for the CCR2004 (ARM64):

1. Use `/system package print` to display the current version.
1. Upload `routeros-arm64-6.47.9.npk` using Webfig.
1. `/system reboot` and verify that `/system package print` shows `6.47.9` now.

## Set up auth

Set a password to prevent others from logging into the router:
```
/user set admin password=secret
```

Additionally, you can enable passwordless SSH key login, if you
want.

1. Create an RSA key, because [ed25519 keys are not
supported](https://forum.mikrotik.com/viewtopic.php?t=109143):

    ```
    % ssh-keygen -t rsa
    Generating public/private rsa key pair.
    Enter file in which to save the key: /home/michael/.ssh/id_mikrotik
    ```

1. Upload the `id_mikrotik.pub` file in Webfig

1. Import the SSH public key for the `admin` user:

    ```
    /user ssh-keys import user=admin public-key-file=id_mikrotik.pub
    ```

## Lock down the router

1. [Enable HTTPS in Webfig](https://help.mikrotik.com/docs/display/ROS/Webfig#Webfig-EnableHTTPS).

1. Disable all remote access except for SSH and HTTPS:

    ```
    /ip service disable telnet,ftp,www,api,api-ssl,winbox
    ```

1. Follow [MikroTik Securing Your
   Router](https://wiki.mikrotik.com/wiki/Manual:Securing_Your_Router#Neighbor_Discovery)
   recommendations:

    ```
    /tool mac-server set allowed-interface-list=none
    /tool mac-server mac-winbox set allowed-interface-list=none
    /tool mac-server ping set enabled=no
    /tool bandwidth-server set enabled=no
    /ip ssh set strong-crypto=yes
    /ip neighbor discovery-settings set discover-interface-list=none
    ```

## Enable DHCPv6 Client

For some reason, you need to explicitly enable IPv6 in 2021:
```
/system package enable ipv6
/system reboot
```

MikroTik says this is a precaution so that users don’t end up with default-open
firewall settings for IPv6. But then why don’t they just add some default
firewall rules?!

Anyway, to configure and immediately enable the DHCPv6 client, use:
```
/ipv6 dhcp-client add pool-name=fiber7 pool-prefix-length=64 interface=sfp28-1 add-default-route=yes use-peer-dns=no request=address,prefix
```

### Modify the IPv6 DUID

Unfortunately, MikroTik does not offer any user interface to set the IPv6 DUID,
which I need to configure to obtain my static IPv6 network prefix from my
provider’s DHCPv6 server.

Luckily, the DUID is included in backup files, so we can edit it and restore
from backup:

1. Run `/system backup save`
1. Download the backup file in Webfig by navigating to Files → Backup → Download.

1. Convert the backup file to hex in textual form, edit the DUID and convert it back to binary:

    ```
    % xxd MikroTik-19700102-0111.backup MikroTik-19700102-0111.backup.hex

    % emacs MikroTik-19700102-0111.backup.hex
    # Search for “dhcp/duid” in the file and edit accordingly:
    # got:  00030001085531dfa69e

    % xxd -r MikroTik-19700102-0111.backup.hex MikroTik-19700102-0111-patched.backup
    ```

1. Upload the file in Webfig, then restore the backup:

    `/system backup load name=MikroTik-19700102-0111-patched.backup`

## Enable IPv6 Router Advertisements

To make the router assign an IPv6 address from the obtained pool for itself, and
then send IPv6 Router Advertisements to the network, set:

```
/ipv6 address add address=::1 from-pool=fiber7 interface=bridge1
/ipv6 nd add interface=bridge1 managed-address-configuration=yes other-configuration=yes
```

## Enable DHCPv4 Client

To configure and immediately enable the [DHCPv4
client](https://wiki.mikrotik.com/wiki/Manual:IP/DHCP_Client) on the upstream
port, use:

```
/ip dhcp-client add interface=sfp28-1 disabled=no
```

I also changed the MAC address to match my old router’s address, just to take
maximum precaution to avoid any Port Security related issues with my provider’s
DHCP server:

```
/interface ethernet set sfp28-1 mac-address=00:0d:fa:4c:0c:31
```

## Enable DNS Server

By default, only the MikroTik itself can send DNS queries. Enable access for
network clients:

```
/ip dns set allow-remote-requests=yes
```

## Enable DHCPv4 Server

First, let’s bundle all SFP+ ports into a single bridge interface:

```
/interface bridge add name=bridge1
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus1 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus2 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus3 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus4 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus5 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus6 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus7 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus8 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus9 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus10 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus11 hw=yes
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus12 hw=yes
```

This means we’ll use the device like a big switch with routing between the
switch and the uplink port `sfp28-1`.

{{< note >}}

**Note**: I don’t know if this configuration reduces performance. I find
MikroTik’s documentation regarding hardware offloading and performance not the
clearest. Then again, the CCR2004 has no hardware offloading whatsoever (?) [as
per a forum post](https://forum.mikrotik.com/viewtopic.php?t=173065).

{{< /note >}}

To configure the DHCPv4 Server, configure an IP address, then start the setup
wizard:

```
/ip address add address=10.0.0.1/24 interface=bridge1
/ip dhcp-server setup
Select interface to run DHCP server on

dhcp server interface: bridge1
Select network for DHCP addresses

dhcp address space: 10.0.0.0/24
Select gateway for given network

gateway for dhcp network: 10.0.0.1
Select pool of ip addresses given out by DHCP server

addresses to give out: 10.0.0.2-10.0.0.240
Select DNS servers

dns servers: 10.0.0.1
Select lease time

lease time: 20m
```

## Enable IPv4 NAT

We need NAT to route all IPv4 traffic over our single public IP address:

```
/ip firewall nat add action=masquerade chain=srcnat out-interface=sfp28-1 to-addresses=0.0.0.0
```

Disable NAT services for security, e.g. to mitigate against NAT slipstreaming
attacks:

```
/ip firewall service-port disable ftp,tftp,irc,h323,sip,pptp,udplite,dccp,sctp
```

I can observe ≈10-20% CPU load when doing a Gigabit speed test over IPv4.

## TODO list

The following features I did not get around to configuring, but they were on my
list:

* [IPv4 port forwardings](https://help.mikrotik.com/docs/display/ROS/First+Time+Configuration)
* Cloudflare DynDNS update script
* [DNS resolution for DHCP hostnames](https://wiki.mikrotik.com/wiki/Setting_static_DNS_record_for_each_DHCP_lease)

## Why I returned it {#returned}

Initially, I thought the device’s fan spins up only at boot, and then the large
heatsink takes care of all cooling needs. Unfortunately, after an hour or so
into my experiment, I noticed that the MikroTik would spin up the fan for a
whole minute or so occasionally! Very annoying.

I also ran into weird DNS slow-downs, which I didn’t fully diagnose. In
Wireshark, it looked like my machine sent 2 DNS queries but received only 1 DNS
result, and then waited for a timeout.

I also noticed that I have a few more unexpected dependencies such as my home
automation using DHCP lease state by subscribing to an MQTT topic. Addressing
this issue and other similar little problems would have taken a bunch more time
and would have resulted in a less reliable system than I have today.

Since I last used MikroTik in 2014 the software seems to have barely changed. I
wish they finally implemented some table-stakes features like DNS resolution for
DHCP hostnames.

Given all the above, I no longer felt like getting enough value for the money
from the MikroTik, and found it easier to just switch back to [my own
router7](https://router7.org/) and return the MikroTik.

I will probably stick with the router7 software, but exchange the PC Engines APU
with the smallest PC that has enough PCI-E bandwidth for a multi-port SFP28
network card.

## Appendix A: Full configuration

```
# may/28/2021 11:40:15 by RouterOS 6.47.9
# software id = 6YZE-HKM8
#
# model = CCR2004-1G-12S+2XS
/interface bridge
add name=bridge1
/interface ethernet
set [ find default-name=sfp28-1 ] auto-negotiation=no mac-address=00:0d:fa:4c:0c:31
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=dhcp_pool0 ranges=10.0.0.2-10.0.0.240
/ip dhcp-server
add address-pool=dhcp_pool0 disabled=no interface=bridge1 lease-time=20m name=dhcp1
/interface bridge port
add bridge=bridge1 interface=sfp-sfpplus1
add bridge=bridge1 interface=sfp-sfpplus2
add bridge=bridge1 interface=sfp-sfpplus3
add bridge=bridge1 interface=sfp-sfpplus4
add bridge=bridge1 interface=sfp-sfpplus5
add bridge=bridge1 interface=sfp-sfpplus6
add bridge=bridge1 interface=sfp-sfpplus7
add bridge=bridge1 interface=sfp-sfpplus8
add bridge=bridge1 interface=sfp-sfpplus9
add bridge=bridge1 interface=sfp-sfpplus10
add bridge=bridge1 interface=sfp-sfpplus11
add bridge=bridge1 interface=sfp-sfpplus12
/ip neighbor discovery-settings
set discover-interface-list=none
/ip address
add address=192.168.88.1/24 comment=defconf interface=ether1 network=192.168.88.0
add address=10.0.0.1/24 interface=bridge1 network=10.0.0.0
/ip dhcp-client
add disabled=no interface=sfp28-1 use-peer-dns=no
/ip dhcp-server lease
add address=10.0.0.54 mac-address=DC:A6:32:02:AA:10
/ip dhcp-server network
add address=10.0.0.0/24 dns-server=10.0.0.1 domain=lan gateway=10.0.0.1
/ip dns
set allow-remote-requests=yes servers=8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844
/ip firewall nat
add action=masquerade chain=srcnat out-interface=sfp28-1 to-addresses=0.0.0.0
/ip firewall service-port
set ftp disabled=yes
set tftp disabled=yes
set irc disabled=yes
set h323 disabled=yes
set sip disabled=yes
set pptp disabled=yes
set udplite disabled=yes
set dccp disabled=yes
set sctp disabled=yes
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set www-ssl certificate=webfig disabled=no
set api disabled=yes
set winbox disabled=yes
set api-ssl disabled=yes
/ip ssh
set strong-crypto=yes
/ipv6 address
add address=::1 from-pool=fiber7 interface=bridge1
/ipv6 dhcp-client
add add-default-route=yes interface=sfp28-1 pool-name=fiber7 request=address,prefix use-peer-dns=no
/ipv6 nd
add interface=bridge1 managed-address-configuration=yes other-configuration=yes
/system clock
set time-zone-name=Europe/Zurich
/system logging
add topics=dhcp
/tool bandwidth-server
set enabled=no
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=none
/tool mac-server ping
set enabled=no
```
