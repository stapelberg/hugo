---
layout: post
title:  "Anecdotes about getting a DSL connection"
date:   2013-06-25 23:00:00
categories: Artikel
Aliases:
  - /Artikel/dsl_connection_troubles
---


<p>
I recently moved to Zürich and therefore needed a new internet connection. I am
given to understand that fiber will be available at my place in a few months,
so I chose to go with a provider that will allow me to eventually switch to
fiber once it’s available.
</p>

<p>
That choice makes me an oddball; normally people go with cablecom, who offer
speeds of up to 150 MBit/s here. If I had gone with cablecom, too, I would not
have written this article :-).
</p>

<h2>Phone line mandatory</h2>

<p>
So, for a DSL connection, you need a phone connection. I ordered the cheapest
one and got a letter from Swisscom telling me that they will connect my phone
line at 2013-05-02. Normally, you provide them the name of the previous tenant
and they will just switch your existing line. Since my previous tenant didn’t
have a phone (remember, cable is popular here), this was more complicated: I
needed to call an electrician who would connect my apartment to the
Hausverteiler (demarcation point).
</p>

<p>
I found an electrician who would come to my place at 2013-05-02 and connect my
line for a fixed rate of 180 CHF (≈ 150 €). Quite a bit of money, given that
Swisscom said it should be something like 50 CHF. I called another electrician
who quoted similar rates, so I didn’t bother to cancel the existing appointment
and look for a cheaper one. Later on, I found out that 180 CHF for everything
was probably a pretty good deal.
</p>

<h2>Connecting^WFinding the line^Wdemarcation point</h2>

<p>
When the electrician arrived, he unmounted the phone plug socket, connected
some kind of tone generator and started measuring where the lines go. He wasn’t
able to trace the lines along the walls, so we went to the basement instead.
There, we were unable to find the demarcation point. We checked every room
multiple times, asked the other tenants (who did not know either) and even went
over the the neighbor’s house to look at their setup.
</p>

<p>
After a while, the electrician decided to call the building management and ask
for help. They couldn’t answer the question either, but promised they would
check the next day. He then called Swisscom and requested some plans, which he
got, but they didn’t help us either. At that point, he was at my place for
about an hour and decided to come back tomorrow, since he couldn’t do anything
else.
</p>

<div style="float: right; margin-right: 4em; margin-left: 1em; background-color: #eee; padding: 1em; border-radius: 5px">
<a href="/Bilder/hauptverteiler.jpg"><img src="/Bilder/hauptverteiler.thumb.jpg" width="200" height="267" alt="Hauptverteiler" border="0" style="box-shadow: 3px 3px 5px 1px #000"></a><br>
<small>Hauptverteiler (800x1067 px)</small>
</div>

<p>
The next day, the building manager revealed that the demarcation point is in
the heater room in the basement, which every electrician should be able to
unlock with a standard key. Well, my electrician wasn’t, so the building
manager left the door open for us.
</p>

<p>
After this problem was fixed, it should have been straight-forward. But it
turns out the demarcation point is a mess (are all of them like this?). We
tried to measure which line goes to my apartment with the tone generator again,
but no luck. We then went back to the level in which my apartment is in and
uncovered the hole for cables in the wall, where we figured out that there
actually is no connection going from my apartment to the basement — the wires
were cut.
</p>

<div style="float: right; margin-right: 4em; margin-left: 1em; background-color: #eee; padding: 1em; border-radius: 5px">
<a href="/Bilder/hauptverteiler_innen.jpg"><img src="/Bilder/hauptverteiler_innen.thumb.jpg" width="200" height="267" alt="Hauptverteiler (contents)" border="0" style="box-shadow: 3px 3px 5px 1px #000"></a><br>
<small>…contents (800x1067 px)</small>
</div>

<p>
Luckily, the electrician was able to find another pair of cables going to the
basement and connected them. I can just hope that this wasn’t the phone line of
another apartment, but I received no complaints for two months now. At this
point, we could detect a signal in the basement and the electrician connected
the line to the corresponding connector. Everything should work now, and he
verified that by measuring that some voltage arrived in my apartment, given
that I did not have an actual phone to connect to this line.
</p>

<h2>No signal</h2>

<p>
So I then connected my DSL modem and tried to connect, which didn’t work, even
after resetting the whole thing and waiting for many minutes. The electrician
guessed that Swisscom might not have connected the line yet and suggested I
should call them. Then he left, after spending about 2-3 hours in total at my
place for a task that should’ve been done in 30 minutes tops.
</p>

<p>
On the phone, my provider told me that there was some problem with connecting
the line on Swisscom’s side and they are hoping to get it fixed within the
next 10 (!) days. Great.
</p>

<h2>No signal at my neighbor’s place, too</h2>

<p>
The next day, my neighbor rang the doorbell and asked whether I had issues with
my phone, too. Hah. It turned out that the guy is actually the son of an old
lady living in the house and wasn’t able to reach her via phone for an entire
day. That’s a problem because the old lady is pretty sick and relies on a
phone. So I told him that recently there was an electrician at this place who
connected my internet line and he might have broken something in the process.
It was a public holiday, so we could not reach the electrician.
</p>

<p>
We then brought one of the old lady’s spare phones upstairs to see whether my
phone line was actually working. Turns out, it’s working, which is good.
However, when dialling out, I had the number that belonged to the old lady. Not
good.
</p>

<p>
Given that the heater room in the basement was still unlocked, I figured I
could have a look myself and see whether the mistake is obvious or not. Given
that I didn’t had my goods shipped to Zürich at that time, I had no electronic
spare parts available and had to improvise :-).
</p>

<h2>MacGyver would be proud</h2>

<div style="float: right; margin-right: 4em; margin-left: 1em; background-color: #eee; padding: 1em; border-radius: 5px">
<a href="/Bilder/linelist.jpg"><img src="/Bilder/linelist.thumb.jpg" width="200" height="240" alt="debug “log”" border="0" style="box-shadow: 3px 3px 5px 1px #000"></a><br>
<small>debug “log” (800x958 px)</small>
</div>

<p>
The phone I had borrowed has a <a
href="http://de.wikipedia.org/wiki/Reichle-Stecker">TT89 Reichle-Stecker</a>
(it’s a swiss thing), which obviously is not very useful when you want to test
the lines in a demarcation point. Luckily, the DSL modem shipped with a
splitter that had a two-wire input and an RJ11 output. They also shipped an
RJ11 to TT83 adapter. So I connected the phone to the adapter to the splitter
and then unisolated one of my ethernet cables with a scissor to get two wires.
</p>
<p>
Equipped with that adventurous testing device, I connected the phone to each
line, dialed my mobile phone and noted the number the call came from.
</p>

<p>
After trying all the lines, I figured out there was an off-by-one error:
Swisscom said my line was supposed to be the 9th connection, but it needed to
go into the 10th. I then swapped the wires and voilà — I have my number in my
apartment and the old lady has a working phone again.
</p>

<p>
So, if the old lady hadn’t complained, that would have been a subtle error that
would have caused more headaches later on.
</p>

<div style="float: right; margin-right: 4em; margin-left: 1em; background-color: #eee; padding: 1em; border-radius: 5px">
<a href="/Bilder/splitter.jpg"><img src="/Bilder/splitter.thumb.jpg" width="200" height="168" alt="Splitter" border="0" style="box-shadow: 3px 3px 5px 1px #000"></a><br>
<small>splitter (600x503 px)</small>
</div>


<p>
A few days later, my internet provider called and told me that swisscom would
connect the line the next day. And this time, it actually worked: the modem
synced and I had an internet connection. Of course, it only reaches about 15
MBit/s instead of the “available” 50 MBit/s, but everybody is used to that,
right? Since I had all the equipment still lying around, I even tested it
directly at the demarcation point, to make sure it’s not the crappy lines going
into my apartment. But no speed increase there, either. In the end, my provider
agreed to downgrade me to the 20 MBit/s option, so at least it’s significantly
cheaper.
</p>

<h2>Conclusion</h2>

<p>
What’s the moral of the story? Physical connections to the internet are still
surprisingly hard. It’s been 14 years since I first connected to the internet
via DSL, and nothing has changed (for me!). Hopefully, we all have fiber soon,
and stories like this one will be a thing of the past.
</p>
