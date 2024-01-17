---
layout: post
title:  "systemd: enable indefinite service restarts"
date:   2024-01-17 20:58:14 +01:00
categories: Artikel
---

When a service fails to start up enough times in a row, systemd gives up on it.

On servers, this isn’t what I want — in general it’s helpful for automated
recovery if daemons are restarted indefinitely. As long as you don’t have
circular dependencies between services, all your services will eventually come
up after transient failures, without having to specify dependencies.

This is particularly useful because specifying dependencies on the systemd level
introduces footguns: when interactively stopping individual services, systemd
also stops the dependents. And then you need to remember to restart the
dependent services later, which is easy to forget.

## Enabling indefinite restarts for a service

To make systemd restart a service indefinitely, I first like to create a drop-in
config file like so:

```
cat > /etc/systemd/system/restart-drop-in.conf <<'EOT'
[Unit]
StartLimitIntervalSec=0

[Service]
Restart=always
RestartSec=1s
EOT
```

Then, I can enable the restart behavior for individual services like
`prometheus-node-exporter`, without having to modify their `.service` files
(which needs manual effort when updating):

```
cd /etc/systemd/system
mkdir prometheus-node-exporter.service.d
cd prometheus-node-exporter.service.d
ln -s ../restart-drop-in.conf
systemctl daemon-reload
```

## Changing the defaults for all services

If most of your services set `Restart=always` or `Restart=on-failure`, you can
change the system-wide defaults for `RestartSec` and `StartLimitIntervalSec`
like so:

```
mkdir /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/restartdefaults.conf <<'EOT'
[Manager]
DefaultRestartSec=1s
DefaultStartLimitIntervalSec=0
EOT
systemctl daemon-reload
```

## What do the default settings do?

So why do we need to change these settings to begin with?

The default systemd settings (as of systemd 255) are:

```
DefaultRestartSec=100ms
DefaultStartLimitIntervalSec=10s
DefaultStartLimitBurst=5
```

This means that services which specify `Restart=always` are restarted 100ms
after they crash, and if the service crashes more than 5 times in 10 seconds,
systemd does not attempt to restart the service anymore.

It’s easy to see that for a service which takes, say, 100ms to crash, for
example because it can’t bind on its listening IP address, this means:

| time    | event                  |
|---------|------------------------|
| T+0     | first start            |
| T+100ms | first crash            |
| T+200ms | second start           |
| T+300ms | second crash           |
| T+400ms | third start            |
| T+500ms | third crash            |
| T+600ms | fourth start           |
| T+700ms | fourth crash           |
| T+800ms | fifth start            |
| T+900ms | fifth crash within 10s |
| T+1s    | systemd gives up       |

## Why does systemd give up by default?

I’m not sure. If I had to speculate, I would guess the developers wanted to
prevent laptops running out of battery too quickly because one CPU core is
permanently busy just restarting some service that’s crashing in a tight loop.

That same goal could be achieved with a more relaxed `DefaultRestartSec=` value,
though: With `DefaultRestartSec=5s`, for example, we would sufficiently space
out these crashes over time.

There is [some recent discussion
upstream](https://github.com/systemd/systemd/issues/30804) regarding changing
the default. Let’s see where the discussion goes.
