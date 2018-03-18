---
layout: post
title:  "OpenWrt WAN watchdog"
date:   2013-10-29 23:00:00
categories: Artikel
Aliases:
  - /Artikel/openwrt_wan_watchdog
---


<p>
Ideally, an internet connection would be perfectly stable, but since that is
not always the case, a watchdog is the next best thing. In case you ever use
your home machine(s) remotely, the use case should be clear: make sure the
internet connection at home still works so that you can log in when travelling.
</p>

<p>
With OpenWrt, it’s fairly easy to implement a simple watchdog that pings a
public IP address every minute and triggers <code>/etc/init.d/networking
restart</code> in case the ping fails a couple of times in a row. For a DSL
connection, this means it will try to re-dial. This setup recovered a broken
connection for me more than once :-).
</p>

<p>
I stored the following shell script at <code>/root/wan-watchdog.sh</code>:
</p>
<pre>
#!/bin/sh

tries=0
while [[ $tries -lt 5 ]]
do
	if /bin/ping -c 1 8.8.8.8 &gt;/dev/null
	then
		exit 0
	fi
	tries=$((tries+1))
done

/etc/init.d/network restart
</pre>

<p>
Don’t forget to make it executable using <code>chmod +x
/root/wan-watchdog.sh</code>.
</p>

<p>
Afterwards, add the following entry in System → Scheduled Tasks in LuCI:
</p>
<pre>
* * * * * /root/wan-watchdog.sh
</pre>
