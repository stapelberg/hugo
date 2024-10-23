---
layout: post
title:  "Auto-opening portal pages with NetworkManager"
date:   2017-05-25 11:37:17 +02:00
categories: Artikel
Aliases:
  - /Artikel/network-manager-portal
---
<p>
Modern desktop environments like GNOME offer UI for this, but if you’re using a
more bare-bones window manager, you’re on your own. This article outlines how
to get a login page opened in your browser when you’re behind a portal.
</p>

<p>
If your distribution does not automatically enable it (Fedora does, Debian
doesn’t), you’ll first need to enable connectivity checking in NetworkManager:
</p>

<pre>
# sudo apt install network-manager-config-connectivity-debian
</pre>

<p>
Then, add a dispatcher hook which will open a browser when NetworkManager
detects you’re behind a portal. Note that the username must be hard-coded
because the hook runs as root, so this hook will not work as-is on multi-user
systems. The URL I’m using is an always-http URL, also used by Android (I
expect it to be somewhat stable). Portals will redirect you to their login page
when you open this URL.
</p>

<pre>
# cat &gt; /etc/NetworkManager/dispatcher.d/99portal &lt;&lt;EOT
#!/bin/bash

[ "$CONNECTIVITY_STATE" = "PORTAL" ] || exit 0

USER=michael
USERHOME=$(eval echo "~$USER")
export XAUTHORITY="$USERHOME/.Xauthority"
export DISPLAY=":0"
su $USER -c "x-www-browser http://www.gstatic.com/generate_204"
EOT
</pre>
