---
layout: post
date: 2012-08-16 17:42:00 +02:00
title: "Disabling auto-reload in Evince"
---
<p>
Because it is insanely hard to google this, here is how to disable auto-reload
of PDF files within Evince (&gt;= v3.4.0):
</p>

<pre>
gsettings set org.gnome.Evince auto-reload false
</pre>
