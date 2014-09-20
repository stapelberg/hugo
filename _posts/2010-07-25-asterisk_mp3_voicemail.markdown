---
layout: post
title:  "Kurz-Howto: Anrufbeantworter-Nachrichten in Asterisk als MP3 versenden"
date:   2010-07-25 23:43:30
categories: Artikel
---


<p>
Auf meiner Asterisk-Telefonanlage läuft natürlich auch ein Anrufbeantworter.
Damit ich diesen nicht immer nur abfragen kann, wenn ich gerade einen
E-Mail-Client vor mir habe (<a href="http://sup.rubyforge.org/">sup</a>
unterstützt leider noch keine verteilten Setups), sondern auch, wenn ich gerade
nur mein Telefon greifbar habe, habe ich meine Konfiguration etwas geändert.
</p>

<p>
Zunächst möchte ich natürlich die Nachricht sowohl in meinem eigentlichen
E-Mail-Client archiviert haben als auch auf mein Telefon (für das ich ein
separates Konto auf meinem Mailserver habe) bekommen.  Normalerweise benutze
ich als <code>mailcmd</code> in der <code>/etc/asterisk/voicemail.conf</code>
direkt <code>/usr/lib/dovecot/deliver -d michael -m daemons</code>. Damit die
E-Mails an beide Nutzer ausgeliefert werden richtet man sich ein kleines
Script ein, welches man im Asterisk als <code>mailcmd</code> konfiguriert:
</p>

<pre>
#!/bin/sh

TMPFILE=$(mktemp)
cat > $TMPFILE
cat $TMPFILE | /usr/lib/dovecot/deliver -d michael -m daemons
cat $TMPFILE | /usr/lib/dovecot/deliver -d pbx -m INBOX
rm $TMPFILE
</pre>

<p>
Die E-Mails werden nun auf meinem Telefon (<a
href="http://en.wikipedia.org/wiki/Nokia_N900">Nokia N900</a>) passend
angezeigt und auch die automatische Benachrichtigung bei neuen Mails
funktioniert. Einzig mit dem Attachment (das eigentlich wichtige neben der
Rufnummer des Anrufers und der Uhrzeit) kann der mitgelieferte Mediaplayer
nichts anfangen – kein Wunder, denn Asterisk kodiert standardmäßig mit dem
gsm-codec (abspielen kann man diese Dateien zum Beispiel mit <a
href="http://www.mplayerhq.hu/">MPlayer</a>). Wenn man sich die passende
Dokumentation zur <code>format</code>-Einstellung von asterisk ansieht, stellt
man fest, dass das Alternativformat unkomprimiertes WAV ist, was bei einigen
Nachrichten schnell in den Megabyte-Bereich wächst. Sofern man nur über UMTS
online ist, will man große Datenmengen natürlich vermeiden, weswegen eine
Umkodierung nach MP3 naheliegt. Das erledige ich mit folgendem Script:
</p>

<pre>
#!/usr/bin/env perl
# vim:ts=4:sw=4:expandtab
# © 2010 Michael Stapelberg, public domain

use strict;
use warnings;
use MIME::Parser;
use IPC::Run qw(run);
use File::Temp qw(tempdir);

# Replaces wav with mp3 and fixes MIME type in headers
sub replace_header {
    my ($head, $field) = @_;

    $_ = $head->get($field);
    s/x-wav/mpeg/ig;
    s/wav/mp3/ig;
    $head->replace($field => $_);
}

# Parse the input file
my $parser = MIME::Parser->new();
$parser->output_under(tempdir(CLEANUP => 1));
my $entity = $parser->parse(\*STDIN) or die "failed";

# Re-encode the audio part
for my $part ($entity->parts) {
    my $body = $part->bodyhandle;
    my $head = $part->head;
    next unless $head->get('Content-Type') =~ /wav/;

    # Feed the attachment's body to ffmpeg(1) and save the MP3 output
    my $mp3;
    my @cmd = qw(ffmpeg -i - -ar 16000 -ab 128000 -f mp3 -);
    run \@cmd, '<', \$body->as_string, '>', \$mp3, '2>', '/dev/null';
    $part->bodyhandle(MIME::Body::Scalar->new($mp3));

    replace_header($head, 'Content-Type');
    replace_header($head, 'Content-Disposition');
}
$entity->print(\*STDOUT);
</pre>
<p>
(Direkter Download: <a href="/recode-voicemail/recode-voicemail.pl">recode-voicemail.pl</a>)
</p>

<p>
Damit das Script funktioniert muss man unter Debian-Systemen die Pakete
libmime-tools-perl, libipc-run-perl und ffmpeg installieren. ffmpeg sollte man
sich hierbei entweder aus <a
href="http://www.debian-multimedia.org/">debian-multimedia</a> installieren
oder selbst kompilieren, denn die Version in debian hat keine Unterstützung für
den MP3-Codec. Einen Testlauf kann man z.B. folgendermaßen durchführen:
<code>ffmpeg -i /var/spool/asterisk/voicemail/default/1/INBOX/msg0001.wav -ar
16000 -ab 128000 -f mp3 /tmp/out.mp3</code>. Anschließend sollte man eine
abspielbare MP3-Datei in <code>/tmp/out.mp3</code> haben, sonst stimmt etwas
mit der ffmpeg-Installation nicht.
</p>

<p>
Das Script zum Re-encodieren kann man nun in das obige Script zum Zustellen der
Mail an beide Accounts einbinden:
</p>

<pre>
#!/bin/sh

TMPFILE=$(mktemp)
/etc/asterisk/recode-voicemail.pl > $TMPFILE
cat $TMPFILE | /usr/lib/dovecot/deliver -d michael -m daemons
cat $TMPFILE | /usr/lib/dovecot/deliver -d pbx -m INBOX
rm $TMPFILE
</pre>
