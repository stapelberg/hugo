---
layout: post
title:  "Hacking your own Kinesis keyboard controller"
date:   2013-03-21 11:49:42
categories: Artikel
Aliases:
  - /Artikel/kinesis_custom_controller
---

{{< note >}}

**Update:** The [kinT kinesis keyboard
controller](/posts/2020-07-09-kint-kinesis-keyboard-controller/) from 2020 is an
updated version, with [several
improvements](https://github.com/kinx-project/kint/#why-use-the-kint-instead-of-the-older-replacement-board)
over the older 2013 design!

{{< /note >}}

<p>
The <a href="http://kinesis-ergo.com/advantage.htm">Kinesis Advantage
Contoured</a> is an ergonomic keyboard which I have been using for four years.
It has many features that make it a great keyboard, and it’s certainly the best
I have ever used.
</p>

<p>
However, as you can also read on many places on the internet, many users have a
tiny problem with the keyboard: the modifier keys sometimes get stuck. For
example, you press Shift, followed by A, release Shift, press n. What appears
on your screen is AN instead of An. You can only get out of this state when
pressing Shift once again. It seems like the firmware doesn’t register the key
release.
</p>

<p>
Last year, I decided to write Kinesis about it and they offered me a firmware
upgrade. I was surprised to learn that a firmware upgrade actually means
getting shipped a new microcontroller with a new firmware on it :-). After
swapping the microcontroller, I noticed that the problem did not appear as
often as it used to, but it still appeared. Of course, that is not satisfactory
for perfectionists and heavy keyboard users :-).
</p>

<h2>The Humble Hacker Keyboard</h2>

<p>
The <a href="http://www.humblehacker.com/keyboard/">Humble Hacker Keyboard</a>
is a project by David Whetstone, who started out his project by modifying
existing keyboards, amongst them the Kinesis Contoured. Thankfully, he <a
href="http://humblehacker.com/blog/">documented his modifications in his
blog</a>.
</p>

<p>
After reading what he did, I decided to replicate his approach and swap the
electronics of my Kinesis. It seemed reasonably straight-forward: Use a
<a href="http://pjrc.com/teensy/">Teensy++ 2.0 USB development board</a>,
connect the different parts of your Kinesis to it and use David’s Open Source
firmware. So I ordered the Teensy++ and had a look at how to modify my Kinesis
so that I could test whether everything works before destructively modifying
the keyboard.
</p>

<h2>The flex connectors</h2>

<a href="/Bilder/kinesis-orig-board.jpg"><img
 src="/Bilder/kinesis-orig-board.thumb.jpg" width="400" height="300"
 alt="The original Kinesis Keyboard controller" border="0"></a>

<p>
In comparison to David’s version of the Kinesis Contoured, my version was newer
and used flex connectors for connecting the left/right keyboards to the
controller board, as you can see on the picture above. Thankfully, Kinesis is
very friendly to the enthusiast community around its products. Rick revealed
that they are using the Cvilux CF01131V000 flex connectors. Unfortunately, it
seems impossible to order just a few Cvilux parts to Europe.
</p>

<a href="/Bilder/flex-to-jumper-wire.jpg"><img
 src="/Bilder/flex-to-jumper-wire.thumb.jpg" align="left" width="200"
 height="288" alt="flex connector to jumper wire adapter"
 style="margin-right: 1em" border="0"></a>

<p>
From an earlier modification I still had a few spare Kinesis parts lying
around, so I decided to unsolder the flex connectors from those for a quick
test. Unfortunately, the grid of the flex connectors is different from the
usual 2.54mm grid, so you cannot simply use such a connector on a breadboard.
Volker came up with the idea of soldering a pin header directly to it, and that
worked (see the picture). I then used a bunch of jumper wires to connect the
flex connector to the Teensy++ and then the Kinesis keyboard parts to the flex
connector. After flashing the firmware, I could press keys on the Kinesis and
have them appear on my screen. Yay! :-)
</p>

<p>
Given that I could not order the Cvilux flex connectors directly, I spent quite
a bit of research into finding a compatible part. In the end, I found and used
the <a href="http://uk.rs-online.com/web/p/fpc-connectors/6704310/">Molex
39-53-2135</a> which you can order from RS components. They even have free
shipping for students :-).
</p>

<h2>The prototype board</h2>

<p>
Now that the proof of concept was done, it was time to design a prototype board
on which I can mount the Teensy++ and connect all the Kinesis keyboard parts —
essentially, one could call it a break-out board for the Teensy++. It really
doesn’t contain any electronics.
</p>

<p>
I created the layout and board files with the free version of <a
href="http://www.cadsoftusa.com/">CadSoft EAGLE</a>, based on David’s
descriptions in his blog posts. I am not very experienced in EAGLE, so
thankfully my friend Moritz helped out with creating an EAGLE library for the
Molex flex connector and cleaning up my board.
</p>

<p>
We then milled the prototype board at Volker’s lab and soldered the flex
connectors and pin headers on the prototype board. Here are two pictures of the
board, one before soldering and the other one after putting it into the
Kinesis:
</p>

<a href="/Bilder/kinesis-prototype-board.jpg"><img
 src="/Bilder/kinesis-prototype-board.thumb.jpg" width="200" height="157"
 alt="The prototype board" border="0"></a>
<a href="/Bilder/prototype-in-kinesis.jpg"><img
 src="/Bilder/prototype-in-kinesis.thumb.jpg" height="157" width="241"
 alt="The prototype board inside my Kinesis" border="0"></a>

<p>
Note that the thumb keyboards don’t use a flex connector — they are soldered
directly onto the controller board :-(. We decided to solder them to a pin
header so that we can connect and disconnect them at will.
</p>

<p>
After connecting the prototype board, most of the keyboard worked properly.
There unfortunately was one little mistake in the layout (and subsequently in
the board), which we were able to correct with a bit of wire. I then decided to
leave the prototype board in to test it for a bit of time until the PCBs were
manufactured and delivered.
</p>

<p>
Unfortunately, we only noticed that there have to be two holes in the center of
the board in order to be able to actually close the keyboard case. Furthermore,
the microcontroller doesn’t have a lot of space, so you need to be careful when
designing a board. I decided to eat my own dogfood and leave the Kinesis
half-open for a while.
</p>

<h2>The PCB</h2>

<p>
Now that it was clear that the idea basically works, Volker and I decided to
take measurements of the original board and design a proper board — with holes
in it and LEDs on it. It took Volker about two hours to route the board, and the
result looks pretty good.
</p>

<a href="/Bilder/kinesis-repl-board.png"><img
 src="/Bilder/kinesis-repl-board.thumb.png" width="400" height="282"
 alt="board" border="0"></a>

<p>
Afterwards, we submitted the board file to <a
href="http://www.bilex-lp.com/">BILEX-LP</a>, a cheap PCB manufacturer in
Bulgaria. It took them a few working days to manufacture the board and a few
more for shipping it, but it finally arrived about two weeks after we placed
the order. You can see the PCB on the picture below:
</p>

<a href="/Bilder/kinesis-controller-pcb.jpg"><img
 src="/Bilder/kinesis-controller-pcb.thumb.jpg" width="400" height="280"
 alt="Teensy++ Kinesis controller manufactured PCB" border="0"></a>

<p>
Of course, not everything was perfect, both with our board file and with the
manufacturing:
</p>

<ol>
<li style="margin-bottom: 0.25em">
One connection was disconnected because of a cut on the board. Not detecting
this in the quality control was the manufacturers fault. But you have to expect
this when ordering at a cheap PCB manufacturer — the other 5 boards look fine.
We were able to fix this with a bit of wire.
</li>

<li style="margin-bottom: 0.25em">
The bottom hole is too small for actually fitting the screw through it. That’s
not a big deal though, since the upper hole is good and the PCB is held in
place by the connection through the upper hole and the connected keyboards.
</li>

<li style="margin-bottom: 0.25em">
The drilling holes for the Teensy++ (in the middle of the board) are 0.8mil
instead of 0.9mil. Since the Teensy++ EAGLE library was downloaded from their
website, we thought it’d be fine, but we should have double-checked. Luckily,
you can still mount a pin header on the board, you just need to push a bit
harder :-).
</li>
</ol>

<p>
So all in all, the PCB is usable, even though it’s not perfect. I then soldered
the ports onto it and we placed it in my Kinesis. Note: the Teensy++ faces the
board, so the USB connector is also facing the board. Therefore, we plugged in
the USB cable and positioned it so that the connected cable fits, then soldered
it onto the pin header.
</p>

<a href="/Bilder/kinesis-pcb-mounted.jpg"><img
 src="/Bilder/kinesis-pcb-mounted.thumb.jpg" width="400" height="300"
 alt="The mounted PCB inside my Kinesis keyboard" border="0"></a>

<p>
For the USB connection, Volker suggested to just rip out the board on the other
side of the Kinesis case, then cut the cable and directly solder a USB cable to
it. That way, we re-use the original Kinesis strain-relief and their cable,
which is a pretty good idea. You can see the result here:
</p>

<a href="/Bilder/kinesis-case.jpg"><img
 src="/Bilder/kinesis-case.thumb.jpg" width="400" height="300"
 alt="The entire case of the Kinesis" border="0"></a>

<h2>The firmware</h2>

<p>
As expected, <a href="https://github.com/humblehacker/firmware">David’s Humble
Hacker Keyboard firmware</a> does not suffer from the stuck-modifier bug that
motivated me to start this whole modification in the first place. However, I
noticed that some key presses were registered twice, so I implemented
debouncing and sent <a
href="https://github.com/humblehacker/firmware/pull/3">a pull request</a>. The
whole implementation was finished surprisingly quickly, the code really is
pretty clean and easy to understand.
</p>

<p>
You can find my version of the firmware at <a
href="https://github.com/stapelberg/kinesis-firmware">https://github.com/stapelberg/kinesis-firmware</a>.
You can also <a href="/kinesis-firmware-2013-03-12.hex">download the .hex
firmware image</a> that you can flash on your Teensy++ — but beware: I use <a
href="http://www.neo-layout.org/">neo-layout.org</a>, so I remapped all the
keys in the firmware :-).
</p>

<p>
<strong>Update:</strong> I switched to a <a
href="/kinesis-firmware-2016-09-16.hex">a .hex firmware image</a> which uses
the US layout (with Escape/Delete swapped and <code>Super_L</code> on Home) and
now do my remapping in the operating system.
</p>

<h2>The layout and board files</h2>

<p>
In case you also want to replace the controller board of your Kinesis, or as a
foundation for similar projects, here are the EAGLE files:
</p>

<ul>
<li>
PCB with proper holes (2013-03-18):
<a href="https://github.com/stapelberg/kinesis-repl/blob/e35752f772712e0ace5ac1862a57efdda0599e90/untitled-bruecke.brd">brd</a>, 
<a href="https://github.com/stapelberg/kinesis-repl/blob/e35752f772712e0ace5ac1862a57efdda0599e90/untitled.sch">sch</a>,
<a href="/Bilder/kinesis-repl-board.png">brd (PNG)</a>,
<a href="/Bilder/kinesis-repl-sch.png">sch (PNG)</a>,
</li>

<li>
PCB as manufactured (2013-02-28):
<a href="https://github.com/stapelberg/kinesis-repl/blob/55b4677238732dcc1927b864cdfde1d82dbbbdb0/untitled-bruecke.brd">brd</a>, 
<a href="https://github.com/stapelberg/kinesis-repl/blob/55b4677238732dcc1927b864cdfde1d82dbbbdb0/untitled.sch">sch</a>
</li>

<li>
<a href="https://github.com/stapelberg/kinesis-repl">git repository</a>
</li>
</ul>

<p>
I have sold all the spare PCBs that I had. In case you want to order a batch
(about 80 USD for 3 boards, that’s the minimum), you can order
<a href="http://oshpark.com/shared_projects/BwWRYP5c">the kinesis PCB at
oshpark.com</a>. Please let me know how the quality is if you decide to do
that, but I’ve heard only good things so far :-).
</p>

<h2>Conclusion</h2>

<p>
Of course it was not strictly necessary to build my own keyboard controller. I
could have just lived with the bug. But it was fun and it’s a great feeling to
have a (mostly) selfmade keyboard with an Open Source firmware to type on :-).
</p>

<p>
The total amount of time spent on this project was about a full work week.
</p>

<p>
I also want to say a big thank you to David Whetstone for publishing his
experiments and firmware, to Moritz Augsburger for the help with the early
EAGLE files and last but not least to Volker Wunsch who spent a lot of time
with me and helped me a lot in order to get this project done.
</p>
