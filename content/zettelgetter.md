---
title: "Zettelgetter"
date: 2014-11-07T09:49:22+01:00
aliases:
  - /Zettelgetter
---

<div id="content"><p>
Zettelgetter ist ein Perl-Script (nach Idee von Andreas Klein), welches sich in
das eLearing-System moodle einloggt und von den angegebenen URLs alle PDF-,
PS-, TXT-, CPP-, ZIP-, TAR- und BZ2-Dateien herunterlädt. Hierbei können
natürlich auch URLs außerhalb von moodle angegeben werden, sodass man mit einem
einzigen Scriptaufruf alle aktuellen Übungszettel herunterladen kann.
</p>

<p>
Außerdem wird im selben Repository (da thematisch verwandt) ein Script gepflegt
(pdfjoin.pl), welches PDFs von Springerlink herunterlädt und sie in ein großes
PDF packt. Die Universität Heidelberg hat beispielsweise Zugriff auf einige
E-Books auf Springerlink, aber wenn man jedes Kapitel einzeln laden muss, dann
macht das keinen Spaß – daher dieses Script.
</p>

<h2>Benutzung</h2>

<h3>Zettelgetter</h3>

<ul>
  <li>
  config.pm.example nach config.pm kopieren und anpassen. Pro angegebener URL wird ein Unterordner angelegt.
  </li>
  <li>
  ./get.pl aufrufen, sich über die Zettel freuen:
  <pre>
      Logging into moodle...
      Downloading new PDF aufgaben10.pdf...
      Downloading new PDF bankrobber-2008-12-11.zip...
      Downloading new PDF zettel-10.pdf...
      Downloading new PDF 10InfoI08OOVererbungneuneu.pdf...
      Downloading new PDF 10Vererbung.zip...
      Finished.
  </pre>
  </li>
</ul>

<h3>pdfjoin</h3>

<pre>Syntax: ./pdfjoin.pl &lt;output-file&gt; &lt;URL&gt;</pre>
</div>
	<h3>Lizenz</h3>
	<p><span class="name">Zettelgetter</span> ist freie Open-Source-Software unter der <span class="license">BSD-Lizenz</span>.</p>
	<div id="development">
		<h3>Entwicklung</h3>
		<p>Der aktuelle Entwicklungsstand kann <a class="dev_url" href="http://code.stapelberg.de/git/zettelgetter">in gitweb</a> verfolgt werden.</p>
	</div>
	<h3>Feedback</h3>
	<p>Solltest du mir eine Nachricht zukommen lassen wollen, <a href="/Impressum">schreib mir doch bitte eine E-Mail</a>.</p>
</div>
