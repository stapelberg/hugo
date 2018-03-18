---
layout: post
title:  "Kurz-Howto: mod_perl und CGI::Application::Dispatch"
date:   2008-02-06 10:00:00
categories: Artikel
Aliases:
  - /Artikel/cgi_app_dispatch
---



<p>
<code>CGI::Application::Dispatch</code> (nachfolgend mit C:A:D abgekürzt) ist
nicht gerade einsteigerfreundlich aufzusetzen. Leider existiert keine komplette
Anleitung, sondern nur die perldoc-Dokumentation, die nicht auf alle Details
eingeht, sondern lieber verschiedene Varianten durcheinanderwürfelt
(„There’s more than one way to do it”). Daher möchte ich hier kurz
niederschreiben, wie man dieses Framework für Webanwendungen zum Laufen
bekommt.
</p>

<h2>CPAN</h2>
<p>
Natürlich muss C:A:D installiert sein, bevor wir loslegen können. Wie bei
Perl-Software üblich, bekommt ihr dieses Modul via CPAN. Zumindest unter Gentoo
kann man das via <code>sudo cpan</code> aufrufen und nach einem <code>install
CGI::Application::Dispatch</code> hat man das Modul installiert.
</p>

<h2>Apache-Konfiguration</h2>
<p>
Der wichtigste Teil zu Beginn ist wohl die Apache-Konfiguration. Hier müssen
wir (am besten) ein Unterverzeichnis via <code>Location</code> definieren, für
das C:A:D zuständig ist (das Verzeichnis muss nicht wirklich existieren).
</p>

<p>Dies geschieht folgendermaßen:</p>

<p class="filenameHeader">/etc/apache2/vhosts/DemoApp.conf</p>
<pre class="Delphi" style="height: 300px">
&lt;VirtualHost localhost&gt;
	ServerAdmin michael@localhost
	DocumentRoot /home/michael/Perl/DemoApp
	CustomLog /var/log/apache2/perl.access common
	ErrorLog /var/log/apache2/perl.error

	&lt;Directory /home/michael/Perl/DemoApp&gt;
		Options FollowSymlinks +ExecCGI
		Order allow,denoy
		Allow from all
	&lt;/Directory&gt;

	<strong>&lt;Location /app&gt;
		SetHandler perl-script
		PerlHandler CGI::Application::Dispatch
		PerlSetVar CGIAPP_DISPATCH_PREFIX Proj
		PerlSetVar CGIAPP_DISPATCH_DEFAULT /app_services
	&lt;/Location&gt;</strong>
&lt;/VirtualHost&gt;
</pre>

<p>
Hiermit sagen wir Apache, dass C:A:D unsere Perl-Scripts aufruft und dass diese
im Ordner „Proj” liegen (relativ zum DocumentRoot, die Package-Defintion muss
daher mit Proj:: beginnen). Außerdem ist die „Startseite” (diejenige, die
erscheint, wenn man http://localhost/app aufruft) auf app_services festgelegt.
Hierbei ist es wichtig, dass das Präfix mit einem Großbuchstaben anfängt! In
meinen Tests gelang es mir nicht, hierfür Kleinbuchstaben zu verwenden :-(.
</p>

<p>
Als nächstes muss man wissen, dass die Adresse app_services in App::Services
umgewandelt wird. Insgesamt (inklusive Präfix) ergibt sich nun also
Proj::App::Services, welches in
/home/michael/Perl/DemoApp/<strong>Proj</strong>/<strong>App</strong>/<strong>Services</strong>.pm
gesucht wird (siehe DocumentRoot oben). Auch hier könnte man das leicht
übersehen, aber aus app_services (Kleinbuchstaben) wird tatsächlich
App::Services (Großbuchstaben) gemacht.
</p>

<p>
Im Browser ruft man also http://localhost/app/app_services oder
http://localhost/app auf zum Test (der fehlschlagen wird, da wir die Datei ja
noch nicht erstellt haben).
</p>

<p>
Hinweis: Sollte das Verzeichnis, in dem das Modul abgelegt ist, nicht im
@INC-Pfad liegen, so kann man sich die startup.pl-Datei ansehen, welche von der
mod_perl-Konfiguration via PerlRequire eingebunden wird. Bei Gentoo ist der
Dateiname /etc/apache2/modules.d/apache2-mod_perl-startup.pl. Diese Datei
beginnt mit <code>use lib qw(/home/michael/Perl/DemoApp);</code> in meinem
Fall, dadurch wird @INC mit diesem Pfad erweitert.
</p>

<h2>Der Code</h2>

<p class="filenameHeader">/home/michael/Perl/DemoApp/Proj/App/Services.pm</p>
<pre class="Delphi" style="height: 420px">package Proj::App::Services;

use base 'CGI::Application';

sub setup {
	my $self = shift;

	$self-&gt;run_modes(
		'list' =&gt; 'list',
		'add' =&gt; 'add'
	);
	$self-&gt;mode_param('rm');
	$self-&gt;start_mode('list');
}

sub list {
	my $self = shift;

	return "Liste";
}

sub add {
	my $self = shift;

	return "Hinzufügen";
}

1;</pre>

<p>
Zu Beginn definieren wir also das Package (daher eine pm-Datei)
Proj::App::Services, welches von CGI::Application erbt (<code>use base</code>).
Von C:A:D wird dann die setup-Funktion aufgerufen, welche die sogenannten
Runmodes definiert (die verschiedenen „Teile”, aus denen eine Webanwendung
üblicherweise besteht, wie zum Beispiel die Auflistung der Datensätze,
Detailansicht, Editieren, etc…), den Parameter angibt, in dem der Runmode
übergeben wird und den Standard-Runmode definiert.
</p>

<p>
Jeder dieser Runmodes (Key des Hashes ist der via Parameter übergebene
Bezeichner, Value ist der Funktionsname im Modul) ist eine Funktion, wie man
weiter unten sehen kann. Eine solche Funktion darf nichts via print ausgeben,
sondern muss die Ausgabe via return zurückgeben. C:A:D kümmert sich um die
Ausgabe der HTTP-Header und der Website.
</p>

<p>
Zu guter letzt wird das Modul via <code>return 1;</code> (in Kurzform) beendet.
</p>

<h2>Angabe des Runmodes</h2>

<p>
In den eigenen HTML-Ausgaben kann man dann den Runmode einfach als normalen
CGI-Parameter anhängen, zum Beispiel so:
</p>
<pre>&lt;a href="http://localhost/app/app_services?rm=add"&gt;Neuen Datensatz hinzufügen&lt;/a&gt;</pre>
<p>Hierbei sind natürlich noch weitere Parameter möglich:</p>
<pre>&lt;a href="http://localhost/app/app_services?rm=edit&amp;amp;id=23"&gt;Datensatz 23 bearbeiten&lt;/a&gt;</pre>

<p>
Mit ein bisschen <a
href="http://httpd.apache.org/docs/2.0/mod/mod_rewrite.html" target="_blank"
title="httpd.apache.org: mod_rewrite"><code>mod_rewrite</code>
(Apache-Modul)</a> kann man da sicherlich auch schönere URLs erstellen.
</p>

<h2>&Uuml;bersicht der Dateien</h2>
<p>Wie sieht nun also unser DocumentRoot aus?</p>

<pre class="Delphi" style="height: 180px">$ ls -hlR /home/michael/Perl/DemoApp
/home/michael/Perl/DemoApp:
total 4.0K
drwxr-xr-x 3 michael staff 4.0K 2008-02-06 00:12 Proj

/home/michael/Perl/DemoApp/Proj:
total 4.0K
drwxr-xr-x 2 michael staff 4.0K 2008-02-06 00:12 App

/home/michael/Perl/DemoApp/Proj/App:
total 4.0K
-rw-r--r-- 1 michael staff 378 2008-02-06 00:29 Services.pm</pre>

<h2>Noch Fragen?</h2>

<p>
Ich hoffe damit ist der Einstieg etwas erleichtert, wer noch Fragen hat, möge
mein Gästebuch benutzen :-).
</p>
