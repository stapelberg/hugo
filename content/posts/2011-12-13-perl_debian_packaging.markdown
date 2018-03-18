---
layout: post
title:  "Packaging your Perl script for Debian"
date:   2011-12-13 19:13:00
categories: Artikel
Aliases:
  - /Artikel/perl_debian_packaging
---



<p>
I wrote a few Perl scripts for various things during the last few years. Many
of them run on machines which I don't maintain on my own (other people have
root access, too) and some even run on machines which I don't have access to at
all. All of the former machines run Debian, so this article only cares about
Debian.
</p>

<h3>Reasons for packaging</h3>

<p>
The naive approach to distributing any kind of scripts is to just upload the
script somewhere. Or directly put it on some machine. Or email it to someone.
And for testing if your program works, that’s great. But after a short amount
of time, especially if other people are involved, you should consider packaging
your script properly:
</p>

<ul>
<li>
If your script is running permanently, and you are not around when the
machine it is running on crashes or needs to be restarted, others have a hard
time figuring out how to restore whichever service it was providing (if they
care at all). This reduces the dependencies on you and it reduces your
cognitive load.<br>

Strictly speaking, the benefit here is due to having an initscript (or
similar), but I consider that part of a proper package, which is why I’m
listing this.
</li>

<li>
All dependencies for your script are properly specified, so that the initial
deployment is easy (you don’t have to use CPAN at all, assuming all
dependencies are available as Debian packages). More importantly, future
upgrades become easier. Debian will automatically take care of upgrading your
dependencies and making sure they are around. Without having a package, nobody
will know that you need these dependencies. Also, nobody knows your code is on
the system in case anything breaks on the next upgrade.
</li>

<li>
Having a proper package leads to just having to use <code>dpkg -l
packagename</code> to figure out which version you are running on this machine.
Also, to find all files which are relevant to your script (think modules it
installs, configuration files, …), you can use <code>dpkg -L
packagename</code>.
</li>

<li>
Following the best practise of building the package out of a fresh checkout of
your SCM repository and only ever installing packages on the target machine
will force you to have all files under version control and no files lying
around on your particular computer which are necessary to run the script.
</li>

</ul>

<p>
Most of these reasons might not be an immediate benefit for you. But they will
make your life so much easier in the future :).
</p>

<h3>File layout for your script</h3>

<p>
Often, Perl scripts start as "foo.pl" or similar. To make creating a
Makefile.PL and the Debian package easier, you should consider the directory
following layout:
</p>

<pre>
/
/lib
/lib/Myprogram
/lib/Myprogram/functionality.pm (module which implements your stuff)
/script
/script/myprogram (executable script)
/Makefile.PL
</pre>

<p>
As you can see, it’s not complex, but you should place your core functionality
in a module within lib/ and have a little wrapper script (/script/myprogram)
which just uses that module. This is good style because dh-make-perl, a tool to
help us with the Debian packaging, will then find the dependencies which your
code has and automatically add them to the debian/control file.
</p>

<p>
In the wrapper script, you can handle things such as providing a useful
description and synopsis when called without arguments and generally handling
commandline-arguments. It is good style to not use the .pl extension because
users generally don’t care in which language a tool is written in. Should you
ever change the language, you would need to change the name.
</p>

<h3>Makefile.PL</h3>

<p>
In the Perl world, Makefile.PL is equivalent to the various kinds of Makefiles
that other languages use. We have the advantage of being able to depend on
Perl, though, which leads to much simpler, cleaner and nicer files :).
</p>

<p>
In general, you use some Perl module to help you write a Makefile (without .PL)
when the user calls <code>perl Makefile.PL</code>. A good module for that is
Module::Install.
</p>

<p>
A typical Makefile.PL looks like this:
</p>

<pre>
#!/usr/bin/env perl
use strict;
use warnings;
use inc::Module::Install;

name     'RaumZeitPinSync';
all_from 'lib/RaumZeitLabor/BenutzerDB/Pinsync.pm';

requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'JSON::XS';

install_script 'pin-sync';

WriteAll;
</pre>

<p>
One gotcha here is the name of your distribution. You should not use dashes (-)
in it, since they have a special meaning (they replace ::, so the AnyEvent::I3
module is in the AnyEvent-I3 distribution).
</p>

<p>
Using <code>make install</code> after generating the Makefile will install
script/pin-sync to /usr/bin and lib/RaumZeitLabor/BenutzerDB/Pinsync.pm to
/usr/share/perl5.
</p>

<h3>POD</h3>

<p>
To automatically make the Makefile and dh-make-perl pick up your author
information, version number and description, add a block like the following to
your module (the one you specify using the all_from keyword, in our case
lib/RaumZeitLabor/BenutzerDB/Pinsync.pm):
</p>

<pre>
=head1 NAME

RaumZeitPinSync - Syncs PINs to the Pinpad controller EEPROM

=head1 DESCRIPTION

This module synchronizes our user-specific PINs to the Pinpad controller
EEPROM.

=head1 VERSION

Version 1.0

=head1 AUTHOR

Michael Stapelberg, C&lt;&lt; &lt;michael at stapelberg.de&gt; &gt;&gt;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Stapelberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the BSD license.

=cut
</pre>

<h3>Debian packaging</h3>

<p>
We’re far enough to actually generate Debian packaging now. We are going to use
dh-make-perl to generate a template for that (often, the template is good
enough to require no further changes). It is normally used to generate Debian
packages from CPAN modules, so we have to override the default package name.
Furthermore, we use source format 1 which does not require an orig-tarball
being around in the parent directory:
</p>

<pre>
perl Makefile.PL
dh-make-perl -p raumzeitpinsync --source-format 1
</pre>

<p>
Now you have a few files in the debian/ directory. Ignore these for now and see
what building a package gets us:
</p>

<pre>
dpkg-buildpackage
dpkg -c ../raumzeitpinsync*.deb
dpkg -I ../raumzeitpinsync*.deb
</pre>

<p>
You should get an output like this:
</p>

<pre>
...
drwxr-xr-x root/root ./usr/share/perl5/
drwxr-xr-x root/root ./usr/share/perl5/RaumZeitLabor/
drwxr-xr-x root/root ./usr/share/perl5/RaumZeitLabor/BenutzerDB/
-rw-r--r-- root/root ./usr/share/perl5/RaumZeitLabor/BenutzerDB/Pinsync.pm
drwxr-xr-x root/root ./usr/share/man/
drwxr-xr-x root/root ./usr/share/man/man3/
-rw-r--r-- root/root ./usr/share/man/man3/RaumZeitLabor::BenutzerDB::Pinsync.3pm.gz
drwxr-xr-x root/root ./usr/bin/
-rwxr-xr-x root/root ./usr/bin/pin-sync
...

 Package: raumzeitpinsync
 Version: 1.0-1
 Architecture: all
 Maintainer: Michael Stapelberg &lt;michael stapelberg.de&gt;
 Installed-Size: 15
 Depends: perl, libanyevent-http-perl, libanyevent-perl, libjson-xs-perl
 Section: perl
 Priority: optional
 Homepage: http://search.cpan.org/dist/RaumZeitPinSync/
 Description: Syncs PINs to the Pinpad controller EEPROM
  (no description was found)
  .
  This description was automagically extracted from the module by dh-make-perl.
</pre>

<h3>Additional files (initscript, logrotate config, …)</h3>

<p>
Often, a script needs additional files to run. For example an initscript to
start on system boot. Or a webserver configuration, a config file, a logrotate
configuration, etc…
</p>

<p>
To easily install additional files, we can just modify our Makefile.PL to look
like this:
</p>

<pre>
#!/usr/bin/env perl
use strict;
use warnings;
use inc::Module::Install;

name     'RaumZeitPinSync';
all_from 'lib/RaumZeitLabor/BenutzerDB/Pinsync.pm';

requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'JSON::XS';

install_script 'pin-sync';

postamble <<'END_OF_MAKEFILE';
install:: extra_install
pure_install:: extra_install
install_vendor:: extra_install

extra_install:
	install -d $(DESTDIR)/etc/
	install -m 640 pin-sync.yml.ex $(DESTDIR)/etc/pin-sync.yml
END_OF_MAKEFILE

WriteAll;
</pre>

<p>
For an initscript, you can copy /usr/share/debhelper/dh_make/debian/init.d.ex
to debian/raumzeitpinsync.init (the filename is relevant) and modify it
accordingly.
</p>

<p>
Afterwards, re-run perl Makefile.PL and dpkg-buildpackage. Enjoy your package!
</p>
