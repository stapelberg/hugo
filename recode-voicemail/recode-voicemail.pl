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
