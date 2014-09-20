---
layout: post
title:  "Kurz-Howto: Videos aufnehmen mit einer USB-Webcam und GStreamer"
date:   2011-09-25 11:38:00
categories: Artikel
---



<p>
Gelegentlich möchte man ein Video aufnehmen. Doch welches Programm verwendet
man dafür? Wie erreicht man die beste Qualität bei kleinster Dateigröße? Diese
kurze Anleitung erklärt, wie man mit GStreamer und FFmpeg eine Video-Aufnahme
von einer USB-Webcam (die VF0610 Live! Cam Socialize HD in meinem Fall)
aufzeichnet und enkodiert.
</p>

<h2>Auflösung/Bildrate herausfinden</h2>

<p>
Mit uvcdynctrl -f sieht man, welche Auflösungen und zugehörigen Bildraten die
Kamera unterstützt. In meinem Fall sieht das so aus:
</p>

<pre>
Listing available frame formats for device video0:
Pixel format: YUYV (YUV 4:2:2 (YUYV); MIME type: video/x-raw-yuv)
  Frame size: 640x360
    Frame rates: 30, 25, 20, 15, 10, 5
  Frame size: 1280x720
    Frame rates: 10, 5
  Frame size: 800x448
    Frame rates: 30, 20, 15, 10, 5
  Frame size: 640x480
    Frame rates: 30, 25, 20, 15, 10, 5
  Frame size: 960x544
    Frame rates: 15, 10, 5
  Frame size: 432x240
    Frame rates: 30, 25, 20, 15, 10, 5
  Frame size: 320x240
    Frame rates: 30, 25, 20, 15, 10, 5
</pre>

<p>
In <code>guvcview</code> habe ich ausprobiert, welche Auflösung am besten aussieht
(also wie groß der gefühlte Unterschied ist). Hierbei wirkte 800x448 am besten
auf mich. Meine Kamera unterstützt bei dieser Auflösung eine Bildrate von 30
fps oder 20 fps. Die niedrigeren Bildraten würde ich nicht nutzen, es sei denn,
die Aufnahme enthält kaum Bewegungen. Wenn man 30 fps statt 20 fps nutzt,
kostet einen das 5,2 MB mehr Speicherplatz pro Sekunde (in der Roh-Aufnahme).
</p>

<p>
Weiterhin kann man in guvcview die einzelnen Parameter der Kamera so
einstellen, dass sie für die jeweilige Kamera und Umgebung ein gutes Bild
liefern. In meinem Fall funktionierten folgende Einstellungen am besten:
</p>

<pre>
Brightness: 35
Contrast: 133
Saturation: 110
Hue: 0
White Balance Temperature, Auto: disabled
Gamma: 183
Gain: 0
Power Line Frequency: disabled
White Balance Temperature: 5692
Sharpness: 0
Backlight Compensation: 4
Exposure (Absolute): 625
</pre>

<h2>Aufnehmen (roh)</h2>

<p>
Mit folgendem Befehl erzeugen wir die Aufnahme, bei der die Bilddaten direkt
als AVI-Datei (ohne Enkodierung) gespeichert werden. Zusätzlich wird ein
Zeitstempel über das Bild gelegt, damit man weiß, wie lange man schon aufnimmt.
Weiterhin wird das Bild nicht nur gespeichert, sondern auch am Bildschirm
angezeigt:
</p>

<pre>
gst-launch v4l2src ! 'video/x-raw-yuv,width=800,height=448,framerate=20/1' ! \
    timeoverlay halign=right valign=top shaded-background=true ! \
    tee name=t_vid ! queue ! \
    xvimagesink sync=false t_vid. ! queue ! \
    videorate ! 'video/x-raw-yuv,framerate=20/1' ! queue ! mux. \
    alsasrc device=hw:1 ! queue ! \
    audioconvert ! queue ! mux. avimux name=mux ! \
    filesink location=rohvideo.avi
</pre>

<p>
Nachdem man das Fenster schließt, kann man verifizieren, dass man eine Datei
namens rohvideo.avi hat.
</p>

<h2>Enkodieren</h2>

<p>
Die rohen Bilddaten nehmen ca. 10 MB pro Sekunde ein. Sofern man das Video
anschließend über das Internet teilen möchte, ist das natürlich enorm viel.
Deshalb enkodieren wir mit <code>ffmpeg</code> die rohen Videodaten zu einem
H264-Video in einem MP4-Container:
</p>

<pre>
ffmpeg -i rohvideo.avi -y -f mp4 -vcodec libx264 -crf 28 -threads 0 \
    -flags +loop -cmp +chroma -deblockalpha -1 -deblockbeta -1 -refs 3 \
    -bf 3 -coder 1 -me_method hex -me_range 18 -subq 7 -partitions \
    +parti4x4+parti8x8+partp8x8+partb8x8 -g 320 -keyint_min 25 -level 41 \
    -qmin 10 -qmax 51 -qcomp 0.7 -trellis 1 -sc_threshold 40 -i_qfactor \
    0.71 -flags2 +mixed_refs+dct8x8+wpred+bpyramid -acodec libfaac -ab \
    80k -ar 48000 -ac 2 video.mp4
</pre>

<p>
Kurze Zeit später (das Enkodieren dauert auf meinem Core 2 Duo-Laptop ca. 10s
für ein Video mit 16s Länge) erhält man die Datei video.mp4, welche in meinem
Fall nurnoch 0,05 MB pro Sekunde benötigt.
</p>
