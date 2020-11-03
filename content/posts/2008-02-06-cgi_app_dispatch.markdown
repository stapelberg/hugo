---
layout: post
title:  "Kurz-Howto: mod_perl und CGI::Application::Dispatch"
date:   2008-02-06 10:00:00
categories: Artikel
Aliases:
  - /Artikel/cgi_app_dispatch
---

`CGI::Application::Dispatch` (nachfolgend mit C:A:D abgekürzt) ist
nicht gerade einsteigerfreundlich aufzusetzen. Leider existiert keine komplette
Anleitung, sondern nur die perldoc-Dokumentation, die nicht auf alle Details
eingeht, sondern lieber verschiedene Varianten durcheinanderwürfelt
(„There’s more than one way to do it”). Daher möchte ich hier kurz
niederschreiben, wie man dieses Framework für Webanwendungen zum Laufen
bekommt.

## CPAN

Natürlich muss C:A:D installiert sein, bevor wir loslegen können. Wie bei
Perl-Software üblich, bekommt ihr dieses Modul via CPAN. Zumindest unter Gentoo
kann man das via <code>sudo cpan</code> aufrufen und nach einem <code>install
CGI::Application::Dispatch</code> hat man das Modul installiert.

## Apache-Konfiguration

Der wichtigste Teil zu Beginn ist wohl die Apache-Konfiguration. Hier müssen
wir (am besten) ein Unterverzeichnis via `Location` definieren, für
das C:A:D zuständig ist (das Verzeichnis muss nicht wirklich existieren).

Dies geschieht folgendermaßen:

**/etc/apache2/vhosts/DemoApp.conf**:

```
<VirtualHost localhost>
	ServerAdmin michael@localhost
	DocumentRoot /home/michael/Perl/DemoApp
	CustomLog /var/log/apache2/perl.access common
	ErrorLog /var/log/apache2/perl.error

	<Directory /home/michael/Perl/DemoApp>
		Options FollowSymlinks +ExecCGI
		Order allow,denoy
		Allow from all
	</Directory>

	<Location /app>
		SetHandler perl-script
		PerlHandler CGI::Application::Dispatch
		PerlSetVar CGIAPP_DISPATCH_PREFIX Proj
		PerlSetVar CGIAPP_DISPATCH_DEFAULT /app_services
	</Location>
</VirtualHost>
```

Hiermit sagen wir Apache, dass C:A:D unsere Perl-Scripts aufruft und dass diese
im Ordner „Proj” liegen (relativ zum DocumentRoot, die Package-Defintion muss
daher mit Proj:: beginnen). Außerdem ist die „Startseite” (diejenige, die
erscheint, wenn man http://localhost/app aufruft) auf app_services festgelegt.
Hierbei ist es wichtig, dass das Präfix mit einem Großbuchstaben anfängt! In
meinen Tests gelang es mir nicht, hierfür Kleinbuchstaben zu verwenden :-(.

Als nächstes muss man wissen, dass die Adresse app_services in App::Services
umgewandelt wird. Insgesamt (inklusive Präfix) ergibt sich nun also
Proj::App::Services, welches in
/home/michael/Perl/DemoApp/<strong>Proj</strong>/<strong>App</strong>/<strong>Services</strong>.pm
gesucht wird (siehe DocumentRoot oben). Auch hier könnte man das leicht
übersehen, aber aus app_services (Kleinbuchstaben) wird tatsächlich
App::Services (Großbuchstaben) gemacht.

Im Browser ruft man also http://localhost/app/app_services oder
http://localhost/app auf zum Test (der fehlschlagen wird, da wir die Datei ja
noch nicht erstellt haben).

Hinweis: Sollte das Verzeichnis, in dem das Modul abgelegt ist, nicht im
@INC-Pfad liegen, so kann man sich die startup.pl-Datei ansehen, welche von der
mod_perl-Konfiguration via PerlRequire eingebunden wird. Bei Gentoo ist der
Dateiname /etc/apache2/modules.d/apache2-mod_perl-startup.pl. Diese Datei
beginnt mit <code>use lib qw(/home/michael/Perl/DemoApp);</code> in meinem
Fall, dadurch wird @INC mit diesem Pfad erweitert.

## Der Code

**/home/michael/Perl/DemoApp/Proj/App/Services.pm**:

```
package Proj::App::Services;

use base 'CGI::Application';

sub setup {
	my $self = shift;

	$self->run_modes(
		'list' => 'list',
		'add' => 'add'
	);
	$self->mode_param('rm');
	$self->start_mode('list');
}

sub list {
	my $self = shift;

	return "Liste";
}

sub add {
	my $self = shift;

	return "Hinzufügen";
}

1;
```

Zu Beginn definieren wir also das Package (daher eine pm-Datei)
Proj::App::Services, welches von CGI::Application erbt (<code>use base</code>).
Von C:A:D wird dann die setup-Funktion aufgerufen, welche die sogenannten
Runmodes definiert (die verschiedenen „Teile”, aus denen eine Webanwendung
üblicherweise besteht, wie zum Beispiel die Auflistung der Datensätze,
Detailansicht, Editieren, etc…), den Parameter angibt, in dem der Runmode
übergeben wird und den Standard-Runmode definiert.

Jeder dieser Runmodes (Key des Hashes ist der via Parameter übergebene
Bezeichner, Value ist der Funktionsname im Modul) ist eine Funktion, wie man
weiter unten sehen kann. Eine solche Funktion darf nichts via print ausgeben,
sondern muss die Ausgabe via return zurückgeben. C:A:D kümmert sich um die
Ausgabe der HTTP-Header und der Website.


Zu guter letzt wird das Modul via <code>return 1;</code> (in Kurzform) beendet.

## Angabe des Runmodes

In den eigenen HTML-Ausgaben kann man dann den Runmode einfach als normalen
CGI-Parameter anhängen, zum Beispiel so:

```
<a href="http://localhost/app/app_services?rm=add">Neuen Datensatz hinzufügen</a>
```


Hierbei sind natürlich noch weitere Parameter möglich:

```
<a href="http://localhost/app/app_services?rm=edit&amp;id=23">Datensatz 23 bearbeiten</a>
```
Mit ein bisschen <a
href="http://httpd.apache.org/docs/2.0/mod/mod_rewrite.html" target="_blank"
title="httpd.apache.org: mod_rewrite"><code>mod_rewrite</code>
(Apache-Modul)</a> kann man da sicherlich auch schönere URLs erstellen.

## Übersicht der Dateien

Wie sieht nun also unser DocumentRoot aus?

```
$ ls -hlR /home/michael/Perl/DemoApp
/home/michael/Perl/DemoApp:
total 4.0K
drwxr-xr-x 3 michael staff 4.0K 2008-02-06 00:12 Proj

/home/michael/Perl/DemoApp/Proj:
total 4.0K
drwxr-xr-x 2 michael staff 4.0K 2008-02-06 00:12 App

/home/michael/Perl/DemoApp/Proj/App:
total 4.0K
-rw-r--r-- 1 michael staff 378 2008-02-06 00:29 Services.pm
```

## Noch Fragen?

Ich hoffe damit ist der Einstieg etwas erleichtert, wer noch Fragen hat, möge
mein Gästebuch benutzen :-).
