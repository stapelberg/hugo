---
layout: post
title:  "Video-Chat with Pidgin (XMPP)"
date:   2011-07-10 12:40:00
categories: Artikel
Aliases:
  - /Artikel/video_chat_with_pidgin
---



<p style="background-color: #c0c0c0">
This post is in english / Dieser Artikel ist auf Englisch, weil er nicht nur
für die deutschen Pidgin-Nutzer hilfreich sein soll.
</p>

<p>
Recently, Google+ and Facebook introduced video chatting. While video chatting
is not a new technology at all, I noticed that I never really tried it except
for a few experiments. Therefore, I wanted to set up video chatting between two
Linux computers, using only free and open source software.
</p>

<p>
I decided to use XMPP (Jabber) instead of SIP for this, due to my bad
experiences with SIP and NAT / packet filters. Also, both users already use
XMPP to communicate.
</p>

<p>
As you can see on the <a
href="http://en.wikipedia.org/wiki/Jingle_(protocol)">Wikipedia page about
Jingle</a>, the video chat protocol extension for XMPP, quite a few clients say
they support Jingle. I decided to try it with <a
href="http://pidgin.im/">Pidgin</a> in version 2.9.0 (it has support for Jingle
since 2.6.0).
</p>

<h2>Camera</h2>

<p>
Linux provides plug &amp; play support for UVC cameras (enable the
<code>USB_VIDEO_CLASS</code> kernel option, module is called
<code>uvcvideo</code>). One camera which got good reviews on Amazon and
reportedly works on Linux is the <a
href="http://www.amazon.de/Logitech-C270-USB-HD-Webcam/dp/B003PAOAWG/">Logitech
C270 USB HD Webcam</a>. I bought it for about 22 € and it works just fine on my
machines with Linux 2.6.39.3.
</p>

<p>
<strong>Update:</strong> The Logitech C270 USB HD Webcam does
<strong>not</strong> work fine on my computer: The usb audio driver has a bug
which causes the audio of the C270’s microphone to stutter occasionally. This
affects both models I bought, which is why I returned the camera.
</p>

<p>
After plugging it in, you can use MPlayer to check if your camera is working:
</p>

<pre>
$ mplayer -v tv:// -tv device=/dev/video0:driver=v4l2
</pre>

<p>
To tune some parameters (contrast, light, …), use the <code>uvcdynctrl</code>
tool. The most important setting for most cameras is the Auto Exposure setting:
When activated, the camera will take a long time for exposure, which results in
a frame rate of 5 fps instead of 30 fps (the picture quality is much better,
though). So be sure to change the Auto Exposure setting.
</p>

<h2>Installing packages</h2>

<p>
Pidgin’s implementation of Jingle uses Farsight and GStreamer. I installed the
following packages on both systems:
</p>

<ul>
<li>gstreamer-tools (0.10.35-1)</li>
<li>gstreamer0.10-alsa (0.10.35-1)</li>
<li>gstreamer0.10-ffmpeg (1:0.10.11-4.1)</li>
<li>gstreamer0.10-nice (0.1.0-2)</li>
<li>gstreamer0.10-plugins-bad (0.10.22-2)</li>
<li>gstreamer0.10-plugins-base (0.10.35-1)</li>
<li>gstreamer0.10-plugins-good (0.10.30-1)</li>
<li>gstreamer0.10-plugins-ugly (0.10.18-1)</li>
<li>gstreamer0.10-pulseaudio (0.10.30-1)</li>
<li>gstreamer0.10-tools (0.10.35-1)</li>
<li>gstreamer0.10-x (0.10.35-1)</li>
<li>gstreamer0.10-x264 (0.10.18-0.0)</li>
<li>libgstreamer-plugins-base0.10-0 (0.10.35-1)</li>
<li>libgstreamer-plugins-base0.10-dev (0.10.35-1)</li>
<li>libgstreamer0.10-0 (0.10.35-1)</li>
<li>libgstreamer0.10-dev (0.10.35-1)</li>
</ul>

<p>
To verify that your camera is also working in GStreamer, use the following command:
</p>

<pre>
$ gst-launch v4l2src ! xvimagesink
</pre>

<p>
Be sure to test this multiple times. While testing, my buddy ran into <a
href="https://bugzilla.gnome.org/show_bug.cgi?id=638300">a bug, where only the
first invocation works</a> on the ThinkPad integrated camera. The patch in that
bugreport fixed the problem for him (apply it to the <a
href="http://packages.qa.debian.org/g/gst-plugins-good0.10.html">gst-plugins-good0.10</a>
source package).
</p>

<h2>Pidgin</h2>

<p>
In Pidgin, first configure your network settings properly. If you (or your
buddy) are behind an IPv4 NAT, go to Tools → Preferences → Network and enter
<code>stunserver.org</code> as STUN server. Afterwards, configure a port range
and enable these ports in your packet filter, if you use a packet filter.
</p>

<p>
For IPv6 (which Pidgin uses, if available), no further setup is required.
</p>

<p>
Afterwards, you need to configure your Voice/Video settings (it did not work
with various symptoms unless both buddys make specific settings here). Enable
the Voice/Video settings plugin in the Tools → Plugins dialog. Then press
Configure Plugin and make the following settings:
</p>

<ul>
<li>Audio → Input → PulseAudio → Webcam C270 Analog Mono</li>
<li>Video → Output → Plugin → X Window System (XV) → Intel Textured Video</li>
<li>Video → Input → Plugin → Video4Linux2 → UVC Camera</li>
</ul>

<p>
Please note that <strong>all of these settings are important</strong> and video
chat did not work for us unless we configured all of them.
</p>

<p>
Now (or after a restart of Pidgin) you should be able to chose Conversation →
Media → Audio/Video call in any conversation window with your buddys. This
option is disabled if the buddy’s computer / XMPP client does not support video
chat.
</p>

<h2>Codecs</h2>

<p>
By default, Farsight uses the Theora video codec and Speex audio codec with a
relatively high bitrate. I decided I want to use less bandwidth to still have
some bandwidth left for other things and to avoid lags.
</p>

<p>
To configure which codecs are used, create <code>~/.purple/fs-codec.conf</code>
and copy your settings from
<code>/usr/share/farsight2/0.0/fsrtpconference/default-codec-preferences</code>,
then modify them. For example, to disable Speex, add <code>id=-1</code> in the
SPEEX sections.
</p>

<p>
To change the bitrate of Theora, create <code>~/.purple/fs-element.conf</code> and
add the following contents:
</p>

<pre>
[theoraenc]
bitrate=210
</pre>

<p>
This resulted in a total bandwidth of about 300 kbit/s (for video and audio).
</p>

<h2>Voice/Video with different clients</h2>

<p>
We also tested Gajim and Psi. With Pidgin/Psi, we were able to do voice calls,
but no video. With Pidgin/Gajim, we were unable to establish neither voice
calls nor video calls.
</p>

<h2>Conclusion</h2>

<p>
Video chatting with free and open source software (FOSS) does work. Setting it
up, however, is a rather unpleasant experience, which is why I wrote this
article.  The error reporting by the Pidgin, Farsight and GStreamer combination
is horrible. While finding out how to get this to work, we always ended up with
open video chat windows where the video just stayed black and the audio was
silent. Pidgin did not display any error messages or hints on what was wrong.
Even the debug window of Pidgin did not provide any clues.
</p>

<p>
It is therefore totally understandable why people could be excited about
Google+ or Facebook video chatting which reportedly just work. Hopefully, we
can improve the video chat situation in FOSS to just work out of the box :).
</p>
