---
layout: post
title:  "Displaying your printer’s status"
date:   2012-10-28 19:09:09
categories: Artikel
Aliases:
  - /Artikel/printer_status
---


<p>
At our house, we have a single, high-quality laser color printer in the
basement (along with the other computer equipment) which everybody uses, as
opposed to a crappy cheap printer at everyone’s workplace. This is a great
setup in our situation, since nobody prints a lot individually, so the slight
discomfort of having to go to the basement is a welcome trade-off for not
having to maintain cheap printers.
</p>

<p>
The only problem with this is the lack of feedback from the printer. That is,
when you printed your document from, say, your web browser, you have no way of
knowing when printing finished. Sure, you could go to the CUPS print server and
repeatedly watch to know when CUPS finished spooling the job. But that’s rather
inconvenient and won’t tell you what’s wrong in case the printer does
<strong>not</strong> print as expected (it will just sit there, or be paused).
</p>

<p>
What happened in reality is that I send the print job, wait a certain amount of
time (roughly corresponding with the document size) and just walk into the
basement. That usually works, except when it doesn’t.
</p>

<p>
Therefore, I wrote a little script which will display the printer’s status
(effectively what it displays on the LCD) using a Freedesktop notification
whenever the status changes. It looks like this in action:
</p>

<img src="/Bilder/printer-status.png" alt="printer status screenshot" width="358" height="38">

<p>
…where "kyocera" is the hostname of the printer and "Es wird gedruckt" is the
german way of saying "printing". The program displaying the notification is <a
href="http://knopwob.github.com/dunst/">dunst, a dmenu-ish
notification-daemon</a> which I can recommend.
</p>

<p>
You can find <a
href="http://code.stapelberg.de/git/notify-printer-status/tree/notify-printer-status">the
script called notify-printer-status here</a> (how creative, eh?). Since the
source code is only 44 lines long (including comments and boilerplate), adding
configuration logic seems to be overkill. Instead, just modify your copy of it.
I’ve been using the script since over a month and it’s been working fine, so I
doubt there are any serious bugs in the code.
</p>

<p>
To use it, you first need an SNMP-capable printer (doh). Then, install the Perl
modules Net::SNMP and Desktop::Notify (<code>sudo apt-get install
libnet-snmp-perl libdesktop-notify-perl</code> on Debian). Now replace the
hostname and find out the SNMP OID for your printer. This is surprisingly hard,
but one way I’ve found to work well for me is to use snmpwalk, distributed as
an example with Net::SNMP, and grep for what the printer currently displays:
</p>

<pre>
$ zcat /usr/share/doc/libnet-snmp-perl/examples/snmpwalk.pl.gz > snmapwalk.pl
$ perl snmapwalk.pl kyocera.rag.lan | grep Ruhemodus
1.3.6.1.2.1.43.16.5.1.2.1.1 = OCTET STRING: Ruhemodus
</pre>

<p>
Afterwards, just start the script in your <code>~/.xsession</code> and forget
about it. Enjoy!
</p>
