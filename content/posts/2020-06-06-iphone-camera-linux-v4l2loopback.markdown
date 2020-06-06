---
layout: post
title:  "Using the iPhone camera as a Linux webcam with v4l2loopback"
date:   2020-06-06 11:18:00 +02:00
categories: Artikel
---

<a href="../../Bilder/2020-06-06-iphone-cam.jpg"><img
src="../../Bilder/2020-06-06-iphone-cam.thumb.jpg"
srcset="../../Bilder/2020-06-06-iphone-cam.thumb.2x.jpg 2x,../../Bilder/2020-06-06-iphone-cam.thumb.3x.jpg 3x"
alt="iPhone camera setup"
width="200" align="right" style="border: 1px solid #ccc; margin-left: 1em"></a>

For my [programming stream at
twitch.tv/stapelberg](https://www.twitch.tv/stapelberg), I wanted to add an
additional camera to show test devices, electronics projects, etc. I couldn’t
find my old webcam, and new ones are hard to come by currently, so I figured I
would try to include a phone camera somehow.

The setup that I ended up with is:

iPhone camera<br>
→ Instant Webcam<br>
→ WiFi<br>
→ gstreamer<br>
→ v4l2loopback<br>
→ OBS

Disclaimer: I was only interested in a video stream! I don’t think this setup
would be helpful for video conferencing, due to lacking audio/video
synchronization.

### iPhone Software: Instant Webcam app

I’m using the [PhobosLab Instant Webcam](https://instant-webcam.com/) (install
from the [Apple App
Store](https://apps.apple.com/us/app/instant-webcam/id683949930)) app on an old
iPhone 8 that I bought used.

There are three interesting related blog posts by app author Dominic Szablewski:

1. [MPEG1 Video Decoder in JavaScript](https://phoboslab.org/log/2013/05/mpeg1-video-decoder-in-javascript) (2013-May)
2. [HTML5 Live Video Streaming via WebSockets](https://phoboslab.org/log/2013/09/html5-live-video-streaming-via-websockets) (2013-Sep)
3. [Decode it like it’s 1999](https://phoboslab.org/log/2017/02/decode-it-like-its-1999) (2017-Feb)

As hinted at in the blog posts, the way the app works is by streaming MPEG1
video from the iPhone (presumably via ffmpeg?) to the [jsmpeg JavaScript
library](https://jsmpeg.com/) via WebSockets.

After some git archeology, I figured out that [jsmpeg was rewritten in commit
7bf420fd just after
v0.2](https://github.com/phoboslab/jsmpeg/commit/7bf420fd0c176d626a50494bfe32135dd911483d). You
can [browse the old version on
GitHub](https://github.com/phoboslab/jsmpeg/tree/186666dd9c2d1fd3430d41f15f695d4a78ed1e42).

Notably, the Instant Webcam app seems to **still use the older v0.2 version**,
which [starts WebSocket streams with a custom 8-byte
header](https://github.com/phoboslab/jsmpeg/blob/186666dd9c2d1fd3430d41f15f695d4a78ed1e42/stream-server.js)
that we need to strip.

### Linux Software

Install the [`v4l2loopback`](https://github.com/umlaeute/v4l2loopback) kernel
module, e.g.
[`community/v4l2loopback-dkms`](https://www.archlinux.org/packages/community/any/v4l2loopback-dkms/)
on Arch Linux or
[`v4l2loopback-dkms`](https://packages.debian.org/bullseye/v4l2loopback-dkms) on
Debian. I used version 0.12.5-1 at the time of writing.

Then, install [gstreamer](https://gstreamer.freedesktop.org/) and required
plugins. I used version 1.16.2 for all of these:

* [`gstreamer`](https://www.archlinux.org/packages/extra/x86_64/gstreamer/)
* [`gst-plugins-bad`](https://www.archlinux.org/packages/extra/x86_64/gst-plugins-bad/) for `mpegvideoparse`
* [`gst-libav`](https://www.archlinux.org/packages/extra/x86_64/gst-libav/) for `avdec_mpeg2video`

Lastly, install either [`websocat`](https://github.com/vi/websocat) or
[`wsta`](https://github.com/esphen/wsta) for accessing WebSockets. I
successfully tested with `websocat` 1.5.0 and `wsta` 0.5.0.

### Streaming

First, load the `v4l2loopback` kernel module:

```
% sudo modprobe v4l2loopback video_nr=10 card_label=v4l2-iphone
```

Then, we’re going to use gstreamer to decode the WebSocket MPEG1 stream (after
stripping the custom 8-byte header) and send it into the `/dev/video10` V4L2
device, to the `v4l2loopback` kernel module:

```
% websocat --binary ws://iPhone.lan/ws | \
  dd bs=8 skip=1 | \
  gst-launch-1.0 \
    fdsrc \
    ! queue \
    ! mpegvideoparse \
    ! avdec_mpeg2video \
    ! videoconvert \
    ! videorate \
    ! 'video/x-raw, format=YUY2, framerate=30/1' \
    ! v4l2sink device=/dev/video10 sync=false
```

Here are a couple of notes about individual parts of this pipeline:

* You must set `websocat` (or the alternative
  [`wsta`](https://github.com/esphen/wsta)) into binary mode, otherwise they
  will garble the output stream with newline characters, resulting in a
  seemingly kinda working stream that just displays garbage. Ask me how I know.

* The `queue` element uncouples decoding from reading from the network socket,
  which should help in case the network has intermittent troubles.

* Without enforcing `framerate=30/1`, you cannot cancel and restart the
  gstreamer pipeline: subsequent invocations will fail with `streaming stopped,
  reason not-negotiated (-4)`

* Setting format `YUY2` allows `ffmpeg`-based decoders to play the
  stream. Without this setting, e.g. `ffplay` will fail with `[ffmpeg/demuxer]
  video4linux2,v4l2: Dequeued v4l2 buffer contains 462848 bytes, but 460800 were
  expected. Flags: 0x00000001.`

* The `sync=false` property on `v4l2sink` plays frames as quickly as possible
  without trying to do any synchronization.

Now, consumers such as [OBS (Open Broadcaster
Software)](https://obsproject.com/), `ffplay` or `mpv` can capture from
`/dev/video10`:

```
% ffplay /dev/video10
% mpv av://v4l2:/dev/video10 --profile=low-latency
```

### Debugging

Hopefully the instructions above just work for you, but in case things go wrong,
maybe the following notes are helpful.

To debug issues, I used the `GST_DEBUG_DUMP_DOT_DIR` environment variable as
described on [Debugging tools: Getting pipeline
graphs](https://gstreamer.freedesktop.org/documentation/tutorials/basic/debugging-tools.html?gi-language=c#getting-pipeline-graphs). In
these graphs, you can quickly see which pipeline elements negotiate which caps.

I also used the [PL_MPEG](https://github.com/phoboslab/pl_mpeg) example program
to play the [supplied MPEG test
file](https://phoboslab.org/files/bjork-all-is-full-of-love.mpg). PL_MPEG is
written by Dominic Szablewski as well, and you can read more about it in
Dominic’s blog post [MPEG1 Single file C
library](https://phoboslab.org/log/2019/06/pl-mpeg-single-file-library). I
figured the codec and parameters might be similar between the different projects
of the same author and used this to gain more confidence into the stream
parameters.

I also used [Wireshark](https://www.wireshark.org/) to look at the stream
traffic to discover that `websocat` and `wsta` garble the stream output by
default unless the `--binary` flag is used.
