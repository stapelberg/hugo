---
title: "25 Gbit/s speedtest server"
date: 2022-12-08T20:24:03+01:00
---

I’m running an Ookla Speedtest server that’s connected via 25 Gbit/s to the internet.

[→ Read more about the hardware](/posts/2021-07-10-linux-25gbit-internet-router-pc-build/)

[→ Read more about the internet connection](/posts/2022-04-23-fiber7-25gbit-upgrade/)

## Ookla CLI Speedtest using Docker (or podman)

Running a Docker container might be the easiest way to run the Ookla Speedtest CLI:

```
# docker run --net host --rm -it \
  docker.io/stapelberg/speedtest:latest \
    -s 50092
```

FYI, server id 43030 is the init7 speedtest server, which is also connected via
25 Gbit/s.

## Ookla CLI Speedtest, manually installed

Follow the instructions at https://www.speedtest.net/apps/cli to install the
Ookla Speedtest command line tool.

{{< note >}}

Do not install the `speedtest-cli` Debian or Arch Linux packages! These are not
the Ookla version, but an open-source re-implementation.

You need the original Ookla Speedtest CLI to be able to select an arbitrary
server (and for multi-connection speedtests, resulting in better performance).

{{< /note >}}

Then, run a speedtest:

```
# speedtest-cli -s 50092
```

## HTTP

If you cannot use the Ookla Speedtest for some reason, you can also download a
file via HTTP.

As I described in [my article on 25 Gbit/s HTTP
downloads](/posts/2022-05-14-http-and-https-download-25gbit/), you should be
able to easily saturate 25 Gbit/s without any further tuning:

```
% curl -v -o /dev/null http://repo7.distr1.org/tmp/50GB.zero
```

If your download is unexpectedly slow, try [enabling TCP
BBR](https://www.cyberciti.biz/cloud-computing/increase-your-linux-server-internet-speed-with-tcp-bbr-congestion-control/).
