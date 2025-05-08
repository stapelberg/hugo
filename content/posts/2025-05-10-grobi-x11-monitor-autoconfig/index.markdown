---
layout: post
title:  "In praise of grobi for auto-configuring X11 monitors"
date:   2025-05-10 08:24:00 +02:00
categories: Artikel
tags:
- pc
- golang
---

I have recently started using the [`grobi` program by Alexander
Neumann](https://github.com/fd0/grobi/) again and was delighted to discover that
it makes using my fiddly (but wonderful) [Dell 32-inch 8K monitor
(UP3218K)](/posts/2017-12-11-dell-up3218k/) monitor much more convenient — I get
a signal more quickly than with my previous, sleep-based approach.

Previously, when my PC woke up from suspend-to-RAM, there were two scenarios:

1. The monitor was connected. My [sleep program](#zleep) would power on the
   monitor (if needed), sleep a little while and then run {{< man name="xrandr"
   section="1" >}} to (hopefully) configure the monitor correctly.
1. The monitor was not connected, for example because it was still connected to
   my work PC.

In scenario ②, or if the one-shot configuration attempt in scenario ① fails, I
would need to SSH in from a different computer and run `xrandr` manually so that
the monitor would show a signal:

```
% DISPLAY=:0 xrandr \
  --output DP-4 --mode 3840x4320 --panning 0x0+0+0 \
  --output DP-2 --right-of DP-4 --mode 3840x4320 --panning 0x0+3840+0
```

## Automatic monitor configuration with grobi

I have now completely solved this problem by creating the following
`~/.config/grobi.conf` file:

```yaml
rules:
  - name: UP3218K

    outputs_connected: [DP-2, DP-4]

	# DP-4 is left, DP-2 is right
    configure_row:
        - DP-4@3840x4320
        - DP-2@3840x4320

    # atomic instructs grobi to only call xrandr once and configure all the
    # outputs. This does not always work with all graphic cards, but is
	# needed to successfully configure the UP3218K monitor.
    atomic: true
```

…and installing / enabling `grobi` (on Arch Linux) using:

```
% sudo pacman -S grobi
% systemctl --user enable --now grobi
```

Whenever `grobi` detects that my monitor is connected (it listens for [X11
RandR](https://cgit.freedesktop.org/xorg/proto/randrproto/tree/randrproto.txt)
output change events), it will run {{< man name="xrandr" section="1" >}} to
configure the monitor resolution and positioning.

To check what `grobi` is seeing/doing, you can use:

```
% systemctl --user status grobi
% journalctl --user -u grob
```

For example, on my system, I see:

```
grobi: 18:31:48.823765 outputs: [HDMI-0 (primary) DP-0 DP-1 DP-2 (connected) 3840x2160+ [DEL-16711-808727372-DELL UP3218K-D2HP805I043L] DP-3 DP-4 (connected) 3840x21>
grobi: 18:31:48.823783 new rule found: UP3218K
grobi: 18:31:48.823785 enable outputs: [DP-4@3840x4320 DP-2@3840x4320]
grobi: 18:31:48.823789 using one atomic call to xrandr
grobi: 18:31:48.823806 running command /usr/bin/xrandr xrandr --output DP-4 --mode 3840x4320 --output DP-2 --mode 3840x4320 --right-of DP-4
grobi: 18:31:49.285944 new RANDR change event received
```

Notably, the instructions for getting out of a bad state (no signal) are now to
power off the monitor and power it back on again. This will result in RandR
output change events, which will trigger `grobi`, which will run `xrandr`, which
configures the monitor. Nice!

## Why not autorandr?

No particular reason. I knew `grobi`.

If nothing else, `grobi` is written in Go, so it’s likely to keep working
smoothly over the years.

## Does grobi work on Wayland?

Probably not. There is no mention of Wayland over on the [grobi
repository](https://github.com/fd0/grobi/).

## Bonus: my Suspend-to-RAM setup {#zleep}

As a bonus, this section describes the other half of my monitor-related
automation.

When I suspend my PC to RAM, I either want to wake it up manually later, for
example by pressing a key on the keyboard or by sending a Wake-on-LAN packet, or
I want it to wake up automatically each morning at 6:50 — that way, daily cron
jobs have some time to run before I start using the computer.

To accomplish this, I use `zleep`, a wrapper program around {{< man
name="rtcwake" section="8" >}} and `systemctl suspend` that integrates with the
myStrom switch smart plug to turn off power to the monitor entirely. This is
worthwhile because the monitor draws 30W even in standby!

```go
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"time"
)

var (
	resume = flag.Bool("resume",
		false,
		"run resume behavior only (turn on monitor via smart plug)")

	noMonitor = flag.Bool("no_monitor",
		false,
		"disable turning off/on monitor")
)

func monitorPower(ctx context.Context, method, cmnd string) error {
	if *noMonitor {
		log.Printf("[monitor power] skipping because -no_monitor flag is set")
		return nil
	}
	log.Printf("[monitor power] command: %v", cmnd)
	u, err := url.Parse("http://myStrom-Switch-A46FD0/" + cmnd)
	if err != nil {
		return err
	}
	for {
		if err := ctx.Err(); err != nil {
			return err
		}
		req, err := http.NewRequest(method, u.String(), nil)
		if err != nil {
			return err
		}
		ctx, canc := context.WithTimeout(ctx, 5*time.Second)
		defer canc()
		req = req.WithContext(ctx)
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			log.Print(err)
			time.Sleep(1 * time.Second)
			continue
		}
		if resp.StatusCode != http.StatusOK {
			log.Printf("unexpected HTTP status code: got %v, want %v", resp.Status, http.StatusOK)
			time.Sleep(1 * time.Second)
			continue
		}
		log.Printf("[monitor power] request succeeded")
		return nil
	}
}

func nextWakeup(now time.Time) time.Time {
	midnight := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.Local)
	if now.Hour() < 6 {
		// wake up today
		return midnight.Add(6*time.Hour + 50*time.Minute)
	}

	// wake up tomorrow
	return midnight.Add(24 * time.Hour).Add(6*time.Hour + 50*time.Minute)
}

func runResume() error {
	// Retry for up to one minute to give the network some time to come up
	ctx, canc := context.WithTimeout(context.Background(), 1*time.Minute)
	defer canc()
	if err := monitorPower(ctx, "GET", "relay?state=1"); err != nil {
		log.Print(err)
	}
	return nil
}

func zleep() error {
	ctx := context.Background()

	now := time.Now().Truncate(1 * time.Second)
	wakeup := nextWakeup(now)
	log.Printf("now   : %v", now)
	log.Printf("wakeup: %v", wakeup)
	log.Printf("wakeup: %v (timestamp)", wakeup.Unix())

	// assumes hwclock is running in UTC (see timedatectl | grep local)

	// Power the monitor off in 15 seconds.
	// mode=on is intentional: https://api.mystrom.ch/#e532f952-36ea-40fb-a180-a57b835f550e
	// - the switch will be turned on (already on, so this is a no-op)
	// - the switch will wait for 15 seconds
	// - the switch will be turned off
	if err := monitorPower(ctx, "POST", "timer?mode=on&time=15"); err != nil {
		log.Print(err)
	}

	sleep := exec.Command("sh", "-c", fmt.Sprintf("sudo rtcwake -m no --verbose --utc -t %v && sudo systemctl suspend", wakeup.Unix()))
	sleep.Stdout = os.Stdout
	sleep.Stderr = os.Stderr
	fmt.Printf("running %v\n", sleep.Args)
	if err := sleep.Run(); err != nil {
		return fmt.Errorf("%v: %v", sleep.Args, err)
	}

	return nil
}

func main() {
	flag.Parse()
	if *resume {
		if err := runResume(); err != nil {
			log.Fatal(err)
		}
	} else {
		if err := zsleep(); err != nil {
			log.Fatal(err)
		}
	}
}
```

To turn power to the monitor on after resuming, I placed the following shell
script in `/lib/systemd/system-sleep/zleep.sh`:

```bash
#!/bin/sh

case "$1" in
	pre)	exit 0
		;;
	post)	/usr/local/bin/zleep -resume
		exit 0
		;;
 	*)	exit 1
		;;
esac
```

Once power is on, grobi will detect and configure the monitor.

Here is the program in action:

```
2025/05/06 21:58:32 now   : 2025-05-06 21:58:32 +0200 CEST
2025/05/06 21:58:32 wakeup: 2025-05-07 06:50:00 +0200 CEST
2025/05/06 21:58:32 wakeup: 1746593400 (timestamp)
2025/05/06 21:58:32 [monitor power] command: timer?mode=on&time=15
2025/05/06 21:58:32 [monitor power] request succeeded
running [sh -c sudo rtcwake -m no --verbose --utc -t 1746593400 && sudo systemctl suspend]
Using UTC time.
	delta   = 0
	tzone   = 0
	tzname  = UTC
	systime = 1746561512, (UTC) Tue May  6 19:58:32 2025
	rtctime = 1746561512, (UTC) Tue May  6 19:58:32 2025
alarm 1746593400, sys_time 1746561512, rtc_time 1746561512, seconds 0
rtcwake: wakeup using /dev/rtc0 at Wed May  7 04:50:00 2025
suspend mode: no; leaving
```
