---
layout: post
title:  "Codegolf erklärt"
date:   2008-08-03 10:00:00
categories: Artikel
---



<h2>Die Aufgabe</h2>

<p>
Als <a href="https://www.noname-ev.de/w/Codegolf/3" title="Codegolf im NoName
e.V. Wiki">Aufgabe (im NoName e.V.-Wiki)</a> war gestellt, dass man ein
Programm schreiben soll, welches den Wochentag (Montag, Dienstag, Mittwoch,
Donnerstag, Freitag, Samstag, Sonntag) inklusive Zeilenumbruch auf stdout
ausgibt. Die Eingabe ist im Format:
</p>
<pre>\d{1,2}\. (Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember) \d{4}</pre>
<p>Also zum Beispiel „1. Januar 2008”.</p>
<p>
Das Datum soll nur für den gregorianischen Kalender berechnet werden, der in
Deutschland ab 1776 definiert ist.
</p>
<p>
Beim sogenannten Codegolf geht es nun darum, dass das Programm möglichst kurz
wird. Als Sonderdisziplin betrachte ich es, das Programm möglichst kryptisch zu
gestalten :-).
</p>
<p>
Ich werde auf dieser Seite folgende Lösungen präsentieren und erklären:
</p>

<ul>
	<li>zsh, erste Lösung (148 Zeichen)</li>
	<li>zsh, zweite Lösung (132 Zeichen)</li>
	<li>C, Lösung (249 Zeichen)</li>
	<li>C, Obfuscated (216 Zeichen)</li>
	<li>C, Nicht den Regeln entsprechend (155 Zeichen)</li>
	<li>C, Nicht den Regeln entsprechend, obfuscated (128 Zeichen)</li>
	<li>bash, von Jiska (225 Zeichen)</li>
</ul>

<h2>Zählweise</h2>

<p>
Bei Scripts werden die Shebangs an sich nicht mitgezählt („#!/bin/sh” zum
Beispiel), die Parameter allerdings schon, beispielsweise fallen bei folgender
Shebang drei Byte an:
</p>
<pre>#!/usr/bin/perl -w</pre>
<p>
Analog dazu wird bei kompilierten Sprachen der Compileraufruf nicht mitgezählt
(„make dateiname” für C-Programme zum Beispiel), zusätzliche Optionen
allerdings schon.
</p>

<h2>zsh, erste Lösung (148 Zeichen)</h2>

<pre>#!/bin/zsh
l=(locale LC_TIME)
a=$($l|awk "/$2/&amp;&amp;NR&gt;23&amp;&amp;\$0=(NR-2)%12+1" RS=\;)
Y=$[$3-(a&gt;10)]
$l|awk -F\; "NR==2&amp;&amp;\$0=\$$[($1+Y+Y/4-Y/100+Y/400+31*a/12)%7+1]"</pre>

<p>
Das Programm funktioniert so, dass die Monatsnamen aus den <a
href="http://en.wikipedia.org/wiki/Locales">locales</a> ausgelesen werden.
Dadurch funktioniert das Programm mit beliebigen Character Sets und
Monats/Tages-Namen. Das war zwar nicht gefordert, ist aber ein netter
Nebeneffekt. Eingabe- und Ausgabeformat richten sich also nach gesetzter
LC_TIME- beziehungsweise LC_ALL-Variable.
</p>

<h3>Zeile 2: l=(locale LC_TIME)</h3>
<p>
l wird auf den Aufruf von locale gesetzt, den wir zweimal benutzen (Zeile 3 und
Zeile 5). Zu beachten ist, dass es nicht funktionieren würde, wenn man einen
String verwendet (er würde nach dem Programm „locale LC_TIME” suchen, statt
nach locale), sondern dass es ein Array (durch die runden Klammern definiert)
sein muss. Auch das Angeben der Strings in Anführungszeichen ist nicht nötig.
</p>

<h3>Zeile 3: a=$($l|awk "/$2/&amp;&amp;NR>23&amp;&amp;\$0=(NR-2)%12+1" RS=\;)</h3>
<p>
Die ersten vier Zeilen der Ausgabe von <code>locale LC_TIME</code> sehen
folgendermaßen aus:
</p>
<pre>Sun;Mon;Tue;Wed;Thu;Fri;Sat
Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday
Jan;Feb;Mar;Apr;May;Jun;Jul;Aug;Sep;Oct;Nov;Dec
January;February;March;April;May;June;July;August;September;October;November;December</pre>

<p>
Diese werden nun an <code>awk</code>, eine uralte UNIX-Scriptsprache übergeben.
<code>awk</code> besitzt eine Variable, den sogenannten Record Seperator (RS),
welcher, sofern er auf ein Semikolon gesetzt wird (am Ende des Aufrufs),
bewirkt, dass awk nicht nur neue Zeilen sondern auch ein Semikolon als
Trennzeichen interpretiert. Man kann sich die Ausgabe dann folgendermaßen
vorstellen (verkürzt):
</p>
<pre>Sun
Mon
Tue
...</pre>

<p>
<code>awk</code> kann man nun mit einem Pattern aufrufen. Wenn dieses in der
Eingabe gefunden wird, wird die betreffende Zeile ausgegeben. Die kürzeste
Form, ein Pattern zu formulieren, das nach einem bestimmten Wort (dem
Monatsnamen in unserem Fall) sucht, ist, eine Regular Expression zu verwenden:
<code>/Januar/</code>
</p>

<p>
Weiterhin gibt es die interne Variable NR, die Anzahl an eingelesenen Records,
die automatisch gesetzt wird. Die ersten 24 Records sind für uns nicht
interessant, danach folgen jedoch die nicht abgekürzten Monatsnamen (gäbe es
nicht den Mai, der abgekürzt ebenso lang ist, hätten wir uns die Abfrage auf NR
sparen können).
</p>

<p>
Die vorhin erwähnte Ausgabe der betreffenden Zeile bei zutreffendem Pattern
funktioniert so, dass die Zeile in <code>$0</code> gespeichert wird und
<code>awk</code> prinzipiell <code>print $0</code> ausführt. Um uns die Ausgabe
zu ersparen, definieren wir also einfach <code>$0</code> um und lassen
<code>awk</code> den Rest erledigen.
</p>

<p>
Diese drei Bedingungen verknüpfen wir nun mit dem boolschen Und-Operator.
</p>

<p>
In der Zuweisung von <code>$0</code> wird durch <code>(NR-2)</code> auch gleich
ein Teil der Zellerschen Kongruenz erledigt, nämlich die Verschiebung in Januar
und Februar, sodass effektiv folgende Indizes zugeordnet werden:
</p>
<ul>
	<li>Januar: 11</li>
	<li>Februar: 12</li>
	<li>März: 1</li>
	<li>April: 2</li>
	<li>Mai: 3</li>
	<li>Juni: 4</li>
	<li>Juli: 5</li>
	<li>August: 6</li>
	<li>September: 7</li>
	<li>Oktober: 8</li>
	<li>November: 9</li>
	<li>Dezember: 10</li>
</ul>
<p>
Die Modulo-Operation brauchen wir, damit nur 1-12 herauskommt, obwohl wir
eigentlich 24-36 als NR haben.
</p>

<h3>Zeile 4: Y=$[$3-(a&gt;10)]</h3>

<p>
Hier wird die Variable Y (Year) auf den dritten Parameter zugewiesen sowie eine
Korrektur für Januar und Februar vorgenommen. Das geht am schnellsten, indem
man im arithmetischen Kontext <code>(a&gt;10)</code> prüft, was ansonsten
leider nicht klappt. In den arithmetischen Kontext gelangen wir am schnellsten
durch das eigentlich veraltete <code>$[]</code> anstelle von
<code>$(())</code>.
</p>

<h3>Zeile 5: $l|awk -F\; "NR==2&&\$0=\$$[($1+Y+Y/4-Y/100+Y/400+31*a/12)%7+1]"</h3>

<p>
Auch hier greifen wir auf <code>awk</code> und die locales zurück, diesmal
allerdings „andersherum”. Damit wir einfach auf die verschiedenen Zugreifen
können, benutzen wir statt des Record Seperators diesmal den Field Seperator
(FS), den man auch mit der Option <code>-F</code> angegeben kann, was in diesem
Fall kürzer ist (da man das Semikolon escapen muss). Der Field Seperator
bewirkt, dass <code>$1</code> mit dem ersten Feld gefüllt ist, <code>$2</code>
mit dem zweiten und so weiter...
</p>

<p>
Der <code>awk</code>-Teil ist nun nahezu beendet. Via altbekannter Variable NR
suchen wir uns die zweite Zeile der Ausgabe und setzen <code>$0</code> (zur
Ausgabe) auf die entsprechende Variable, also <code>$1</code> oder
<code>$2</code> und so weiter.
</p>

<p>
Im arithmetischen Kontext berechnen wir nun das eigentliche Datum via Zellers
Kongruenz. Interessant hierbei ist, dass man keine Dollarzeichen für Variablen
im arithmetischen Kontext braucht, was 5 Byte spart.
</p>

<h2>zsh, zweite Lösung (132 Zeichen)</h2>

<pre>#!/bin/zsh
p=riMnlASbvzJu;a=$p[(i)${2[$[19%$#2]]}];Y=$[$3-(a&gt;10)]
locale LC_TIME|awk -F\; "NR==2&amp;&amp;\$0=\$$[($1+Y+Y/4-Y/100+Y/400+31*a/12)%7+1]"</pre>

<p>
Bei dieser Lösung ist die zweite Zeile identisch mit der letzten der ersten
Lösung, lediglich das Umwandeln von Monatsname in den entsprechenden Index
wurde verkürzt.
</p>

<h3>Zeile 1: p=riMnlASbvzJu;a=$p[(i)${2[$[19%$#2]]}];Y=$[$3-(a&gt;10)]</h3>

<p>
Zuerst wird die Variable p zugewiesen, hierbei brauchen wir keine
Anführungszeichen, das spart zwei Byte. Zu beachten ist, dass der String im
Gegensatz zu der C-Lösung oder zu manchen Perl-Lösungen keine Sonderzeichen
enthält.
</p>

<p>
Beim Umsetzen des Monatsnamen machen wir uns nun mehrere Effekte zu nutze. Das
<code>(i)</code> ist ein Subscript Flag, welches das Offset des Ergebnisses der
(Regexp)Suche nach dem nachfolgenen Pattern zurückgibt. Bei
<code>p=abc;a=$p[(i)b]</code> wäre also a = 2. Der andere Effekt ist die Suche
nach einem eindeutigen Buchstaben im Monatsname, dessen Position man möglichst
einfach bestimmen kann. Wenn man den 19. Buchstaben nimmt, also <code>19 %
$#2</code> (<code>$#2</code> ist die Länge des zweiten Parameters, also des
Monatsnamens) bekommt man folgende Werte/Buchstaben:
</p>
<ul>
	<li>Januar: 1 (J)</li>
	<li>Februar: 5 (u)</li>
	<li>März: 3 (r)</li>
	<li>April: 4 (i)</li>
	<li>Mai: 1 (M)</li>
	<li>Juni: 3 (n)</li>
	<li>Juli: 3 (l)</li>
	<li>August: 1 (A)</li>
	<li>September: 1 (S)</li>
	<li>Oktober: 5 (b)</li>
	<li>November: 3 (v)</li>
	<li>Dezember: 3 (z)</li>
</ul>

<p><code>Y=...</code> entspricht dann Zeile 4 der ersten Lösung.</p>

<h2>C, Lösung (249 Zeichen)</h2>

<pre>main(int a,char**b){char*H[]={"Sonntag","Montag","Dienstag","Mittwoch","Donnerstag","Freitag","Samstag"},
*d=b[2],*s=" $c-VX\\`]fdZ_";
printf("%s\n",H[(31*(a=strchr(s,(*d^d[3]^d[2]&amp;127)+9)-s)/12+atoi(b[1])+(a=atoi(b[3])-(a&gt;10))+a/4-a/100+a/400)%7]);}</pre>

<p>Kompilieren und testen (die Datei muss als wochentag.c gespeichert werden):</p>
<pre>$ make wochentag
$ ./wochentag 1. Januar 2008</pre>

<p>
(Die Lösung wurde natürlich ohne die Zeilenumbrüche abgegeben, diese dienen nur
zur Lesbarkeit.)
</p>

<p>
C ist natürlich eine Sprache, in der man nicht sonderlich gute Chancen hat,
beim Golfen zu gewinnen. Nichtsdestotrotz ist es interessant, wie nahe man an
andere Lösungen kommt, weil man doch einige Möglichkeiten ausnutzen kann.
</p>

<p>
Worum man leider nicht kommt, ist eine Definition der main-Funktion inklusive
Parameter (auf die wir ja zugreifen wollen). Ich hätte erwartet, dass man die
Funktion nicht unbedingt main nennen muss (was aber leider nicht so ist), da
der Compiler ja weiß, dass wir ein Executable bauen und keine Library und es
ansonsten keine Funktionen gibt.
</p>

<p>
Anschließend folgt die Definition eines Arrays mit Strings für jeden Wochentag,
die später ausgegeben werden. Weglassen kann man hierbei die Anzahl der
Einträge, der Compiler kann sie zur Compilezeit ermitteln, das spart ein Byte.
Außerdem definieren wir <code>*d</code> als Abkürzung für den Zugriff auf
<code>b[2]</code> (den zweiten Parameter, also den Monatsnamen). Da wir
<code>b[2]</code> später drei mal benutzen, lohnt sich das.
</p>

<p>
Nun folgt ein Teil der Magie, nämlich der String <code>s</code>, der als Lookup
Table verwendet wird. Etwas unschön ist, dass er einen Backslash enthält, der
natürlich escaped werden muss. Das hätte man durch eine noch weitere
Verschiebung bei <code>strchr</code> zwar ändern können, aber dann hätte man ja
an anderer Stelle wiederum ein Byte mehr. Der besseren Lesbarkeit zuliebe ist
hier die Definition von <code>a</code> (eigentlich speichert argc die Anzahl
der Argumente, aber diese brauchen wir nicht und können somit die Definition
eines integers sparen):
</p>
<pre>a = strchr(s,(*d ^ d[3] ^ d[2]&amp;127)+9)-s</pre>

<p>
Was hier geschieht ist das Erzeugen eines eindeutigen Kennzeichners des
Monatsnamen, indem der erste, dritte und ein Teil des vierten Buchstabens via
XOR vermischt werden und dieses Ergebnis anschließend um 9 Zeichen verschoben
wird (damit <code>s</code> möglichst schön aussieht). Wir suchen nun mit
<code>strchr</code> die Position des erzeugten Zeichens und ziehen davon die
Speicheradresse von s ab. Das ist nötig, da es in C leider keine Funktion gibt,
die das Offset eines Zeichens in einem String zurückgibt, sondern nur einen
Zeiger auf die Position.
</p>

<p>
Anschließend folgt die Ausgabe mit derselben Berechnung wie bei den
zsh-Lösungen. Was die C-Lösung so lang macht, sind die expliziten
Funktionsaufrufe wie atoi, strchr, printf und die Deklarationen wie char und
main.
</p>

<h2>C, Obfuscated (216 Zeichen)</h2>
<pre>N(I a,C**b){C*H[]={"Sonntag","Montag","Dienstag","Mittwoch","Donnerstag","Freitag","Samstag"},*s=" $c-VX\\`]fdZ_",
*d=b[2];X(F,H[(31*(a=Y(s,(*d^d[3]^d[2]&amp;127)+9)-s)/12+E(b[1])+(a=E(b[3])-(a&gt;10))+a/4-a/100+a/400)%7]);}</pre>

<p>
Dem eben genannten Problem, was den C-Code so lange macht, habe ich mich dann
in der Form angenommen, dass ich main, int, char, strchr, atoi und printf in
den Compileraufruf via <code>define</code> ausgelagert habe. Dass diese Lösung
dadurch nicht weniger Zeichen hat insgesamt ist mir natürlich klar (da die
Compileroptionen ja gezählt werden), aber es ist dennoch „schön” zu sehen, wie
der Code dann aussieht ;-).
</p>

<h2>C, Nicht den Regeln entsprechend (155 Zeichen)</h2>
<pre>main(int a,char**b){char*s=" $c-VX\\`]fdZ_",*d=b[2];
return(31*(a=strchr(s,(*d^d[3]^d[2]&amp;127)+9)-s)/12+atoi(b[1])+(a=atoi(b[3])-(a&gt;10))+a/4-a/100+a/400)%7;}</pre>

<p>
Bei dieser Lösung war das Ziel, eine Programm zu schreiben, welches zwar nicht
den Regeln des Wettbewerbs entspricht, aber dennoch funktionsfähig ist. Dieses
Programm gibt den errechneten Tag nicht aus, sondern übergibt ihn via
Returncode. Das spart die Definition der Tagesnahmen.
</p>

<h2>C, Nicht den Regeln entsprechend, obfuscated (128 Zeichen)</h2>
<pre>N(I a,C**b){C*s=" $c-VX\\`]fdZ_",*d=b[2];R(31*(a=Y(s,(*d^d[3]^d[2]&amp;127)+9)-s)/12+E(b[1])+(a=E(b[3])-(a&gt;10))+a/4-a/100+a/400)%7;}</pre>

<p>
Wenn man jetzt die eben genannte Variante nochmal obfuscated, sieht das ganze
so aus. Vom Quellcode her ist das die kürzeste Variante und sicherlich die
unverständlichste, wenn man damit angefangen hätte ;-).
</p>

<h2>bash, von Jiska (225 Zeichen)</h2>
<pre>
#!/bin/bash
t=(J F z A Ma ni li g S O N D)
w=(SonnX MonX DiensX Mittwoch DonnersX FreiX SamsX)
for((i=0;i&lt;12;i++));do echo $2|grep -q ${t[i]}&amp;&amp;m=$[i+2];done
y=$3
echo ${w[$[m&lt;4&amp;&amp;(m+=12,y--),(${1/.}+13*m/5+y+y/4-y/100+y/400+6)%7]]/X/tag}
</pre>

<p>
Was mir an dieser Lösung gut gefällt, ist die Art und Weise, wie die Monate
erkannt werden. Jiska benutzt hierbei Regular Expressions, die jeden
Monatsnamen eindeutig identifizeren und ziemlich kurz sind. Der Trick dabei
ist, dass Regular Expressions natürlich an jeder Stelle zutreffen. Dadurch
fällt jegliche Logik weg um einen eindeutigen Teil zu erzeugen, leider ist der
Code aufgrund der vergleichsweise beschränkten Möglichkeiten der
<code>bash</code> trotzdem länger.
</p>

<p>
Ansonsten interpretiert die <code>bash</code> im Gegensatz zur <code>zsh</code>
den ersten Parameter mit abschließendem Punkt nicht als integer, sodass man den
Punkt vorher via <code>${1/.}</code> entfernt. Ebenso wird die Ausgabe der Tage
verkürzt, indem „tag” durch X abgekürzt wird und später wieder ersetzt wird.
</p>

<p>
Leider gelang es uns nicht, die Regular Expressions auf einen Buchstaben
abzukürzen (ohne auf den selben Ansatz wie oben zurückzugreifen), problematisch
ist zum Beispiel der Januar, der schwer vom Juni zu unterscheiden ist (weil das
i als einzig unterschiedlicher Buchstabe schon im Mai vergeben ist). Auch durch
Tricks wie das Entfernen von „uar” und „ber” kam ich nicht weiter. Wer hier
eine schöne Lösung findet, möge sie mir bitte zusenden :-).
</p>
