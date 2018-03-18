#!/usr/bin/env perl
# vim:ts=4:sw=4:expandtab
#
# © 2011 Michael Stapelberg <michael at stapelberg dot de>
# licensed under 3-clause BSD license
#
# This script is an umount(8) wrapper which also calls luksClose for the device
# if its path starts with /dev/mapper. Also, it displays the amount of dirty
# pages waiting to be written to disk and displays an estimate.

use strict;
use warnings;
use v5.10;

# call the real umount in the following exec
unshift @ARGV, '/bin/umount';

my $path = $ARGV[-1];

# strip trailing slash, if existant
$path =~ s,/$,,g;

# get the current mounts as { source => dest } hash from /etc/mtab
open(my $mtab, '<', '/etc/mtab');
my %tab = map { /([^ ]+) ([^ ]+)/ and ($2, $1) } <$mtab>;
close($mtab);

# check if the source starts with /dev/mapper
my $source = $tab{$path};

# no /dev/mapper at the beginning, just pass this to umount
exec @ARGV unless ($source =~ m,^/dev/mapper/,);

say "umounting $path… (source: $source)";

my $pid = fork;
die "Could not fork: $!" unless defined($pid);

if ($pid == 0) {
    # Child: umount
    exec @ARGV;
    exit 1;
}

# Parent: display number of dirty pages, call luksClose afterwards
my $umount_running = 1;
$SIG{CHLD} = sub {
    my $waitedpid = wait;
    my $exitcode = ($? >> 8);
    if ($exitcode != 0) {
        say "ERROR: umount exited with exitcode $exitcode, aborting";
        exit(1);
    }
    $umount_running = 0;
};

# watch nr_dirty, the number of dirty (= to be written to disk) pages
open(my $vmstat, '<', '/proc/vmstat');
while ($umount_running) {
    my ($dirty) = map { /([0-9]+)$/ and $1 } grep { /^nr_dirty / } <$vmstat>;

    # one page is 4096 bytes, so translate $dirty to bytes
    $dirty *= 4096;

    # rewind the file handle to get the new value in the next iteration
    seek $vmstat, 0, 0;
    say "dirty = $dirty";
# TODO: provide a time estimate
    sleep(1);
}
close($vmstat);

# prefix sudo if we’re not root, run cryptsetup to close the crypto device
exec (($< != 0 ? 'sudo' : ()), 'cryptsetup', 'luksClose', $source);
