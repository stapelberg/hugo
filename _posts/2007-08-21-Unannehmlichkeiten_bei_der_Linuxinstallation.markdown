---
layout: post
title:  "Unannehmlichkeiten bei der Linuxinstallation"
date:   2007-08-21 10:00:00
categories: Artikel
---



<h3>Vorgeplänkel</h3>

<p>
Nach 5-jährigem Einsatz Windows XP hatte ich endgültig genug von dessen Macken
wenn man mehr Hardware verwendet als der Durchschnittuser (oder als vor 5
Jahren eben utopisch war): Mehr als 1 GB RAM und mehr als 1 Bildschirm und
schon fangen die Probleme an (nicht genügend Resourcen trotz 1,3 GB freiem RAM
sage ich nur; hab’ gar keine Lust darüber noch mehr Worte zu verlieren :-/).
</p>

<p>
Freitags war es dann soweit. Vorausschauend nahm ich mir die nächsten Tage
nichts vor, ich hatte also Freitag, Samstag, Sonntag und die beiden Wochentage
darauf (wir hatten wegen Abiturprüfungen frei) Zeit, um mich mit der
Linuxinstallation zu befassen. Die neu für Linux angeschaffte 250
GB-SATA-Festplatte war schnell eingebaut und betriebsbereit, das BIOS machte –
wie es sich für ein einigermaßen aktuelles BIOS gehört – keinerlei Probleme.
Zusätzlich hatte ich übrigens noch zwei 74 GB-SATA-Festplatten im RAID-1 und
eine 80 GB-IDE-Platte angeschlossen.
</p>

<h3>XUbuntu Live-CD</h3>

<p>
Da ich mit Ubuntu Linux bisher eigentlich nur gute Erfahrungen gemacht habe,
entschied ich mich, auch diesmal Ubuntu zu verwenden, allerdings mit dem
abgespeckten Xfce-Desktop, da dieser ohnehin nach der Installation
Enlightenment weichen muss.
</p>

<p>
Nachdem ich mir die „Desktop”-CD geladen hatte, bemerkte ich beim Einlegen,
dass das eine Live-CD ist – das hätten die auch gleich hinschreiben können. Von
dieser sollte man jedoch auch installieren können, also nicht so schlimm. Ich
vermute, dass der Textinstaller den gleichen Bug hat, da dieser für
grub-installer filed ist…
</p>

<h3>Nichtfunktionierender Standardtreiber</h3>

<p>
Nachdem der grafische Splashscreen durchgelaufen war, schlug das Starten des
X-Servers fehl. Einen Grund dafür konnte ich auf Anhieb nicht erkennen, ich
dachte mir jedoch, dass ich es einfach mal mit einem anderen Treiber für meine
ATI x700 probieren könnte und der (proprietäre) fglrx-Treiber lief dann auch
sofort. Leider wird dieser nicht standardmäßig mitgeliefert, sodass ich zuerst
das Netzwerk konfigurieren musste und danach via <code>apt-get install
xorg-driver-fglrx</code> den Treiber nachinstallieren musste. Einmalig ist das
ja nicht so schlimm – dieser eine Start sollte aber nicht der letzte bleiben
und mit der Zeit wurde das schon ziemlich nervig.
</p>

<p>
Einfach den X-Server nun zu starten ist jedoch falsch, man muss den
<code>gdm</code> via <code>killall gdm &amp;&amp; gdm</code> beenden und
neustarten, ansonsten wird zum Beispiel das Symbol um die Installation zu
starten am Desktop nicht angezeigt. Benutzername für die Anmeldung ist
„Ubuntu”, das Passwort ist leer. Warum hier kein Auto- oder zumindest
Timed-Login verwendet wird oder wie das ein Linuxeinsteiger wissen soll, ist
mir schleierhaft.
</p>

<h3>Funktionierende Bootloader? Bei SATA nicht</h3>

<p>
SATA gibt’s schon lange genug, damit es einfach funktionieren müsste, könnte
man meinen. Gut, bei Windows XP muss man die SATA-Treiber von Diskette (!)
laden, oder direkt eine gepatchte Installations-CD erstellen, aber das ist ja
nicht (mehr) unser Maßstab.
</p>

<p>
Leider meint der <code>grub-installer</code>, dass er die erste Festplatte
nehmen müsse, die er findet, um den MBR dort zu überschreiben. Da dies aber
meine IDE-Festplatte war, landete der Bootloader also dort. Da mein BIOS nicht
ausgibt, auf welcher Festplatte es nun nach Bootloadern sucht, bemerkte ich
dies anfangs gar nicht. Was ich allerdings bemerkte: Das System ließ sich nicht
booten. Auch nach erneutem Installieren von GRUB nicht.
</p>

<p>
Auf den Rat eines Freundes hin erstelle ich dann eine separate Partition für
<code>/boot</code>, weil das BIOS eventuell Probleme mit den 250 GB haben
könnte. Das brachte mich immerhin zu einer anderen Fehlermeldung, zum starten
ließ sich GRUB allerdings nicht überreden.
</p>

<p>
Nach einigem Durchprobieren der Verfügbaren BIOS-Optionen und dem Suchen nach
einem leider nicht auffindbaren Legacy Mode (SATA-Festplatten wie IDE
darstellen), zog ich einfach das Kabel der IDE-Festplatte um dem Installer nur
noch eine Möglichkeit geben, den Bootloader zu installieren. Schon beim
Bootversuch merkte ich nun, dass das BIOS gar keinen Bootloader fand – dieser
war also wirklich nicht auf der SATA-Festplatte gelandet.
</p>

<p>
Die erneute Installation ließ mir wenigstens einen Bootloader auf der Platte,
es lag also tatsächlich daran. Für dieses Problem existiert schon seit dem
21.02.2006 <a
href="https://launchpad.net/distros/ubuntu/+source/grub-installer/+bug/32357"
title="Bugreport">ein Bugreport</a>, in der aktuellen Ubuntu-Version ist er
jedoch noch immer nicht behoben.
</p>

<h3>Das Problem</h3>

<p>
Wo nun das Problem ist? Ein MBR macht ja eigentlich nichts, kann man ja
ersetzen. Blöderweise war die besagte 80 GB-Festplatte jedoch mit einem
TrueCrypt-Volume ausgestattet und TrueCrypt legt in den ersten 512 Bytes (dort,
wo auch der Bootloader hingeschrieben wird) seine Keys ab, die er – kombiniert
mit der eigenen Passphrase natürlich – zum Einbinden des Volumes benötigt. Wenn
diese überschrieben werden, ist das Volume nicht mehr zu retten. Fast 80 GB
Daten also verloren.
</p>

<h3>GRUB, Teil Zwei</h3>

<p>
Wie vorhin kurz erwähnt, landete also schlussendlich wenigstens ein GRUB auf
der Festplatte. Dieser zeigte jedoch kein Menü an, sondern nur das Prompt.
Mittels <code>root (hd0,0)</code>, <code>kernel /vmlinuz-2.6.15-23-386 ro
root=/dev/sdc3</code> (/dev/sdc3 ist die Datenpartition), <code>initrd
/initrd.img-2.6.15-23-386</code> und <code>boot</code> konnte ich problemlos
starten.
</p>

<p>
Der Debian- beziehungsweise Ubuntuinstaller legt die menu.lst in
/boot/grub/menu.lst ab. Meine Vermutung ist nun (war bisher noch nicht
unbeschäftigt genug, um neuzustarten), dass GRUB in /boot/boot/grub/menu.lst
sucht, da er ja in der Regel eine Partition vor sich hat, wo die Dateien in
/boot liegen. Ein solches Verzeichnis gab es auch – allerdings ohne menu.lst.
Ich habe nun einen Symlink angelegt und werde berichten, ob das funktioniert.
Übrigens: Mittels <code>configfile /grub/menu.lst</code> bekommt man das Menü
auch zu sehen.
</p>

<p>
Außerdem macht der Installer aber noch einen weiteren Fehler: Er definiert die
Festplatte als hd(2,0), obwohl die zum Boot notwendigen Dateien ja auf hd(0,0)
liegen. Ob das nun mit der ohnehin falschen Reihenfolge zu tun hat, oder ein
separater Bug ist, weiß ich nicht. Jedenfalls musste ich das von Hand ändern.
</p>

<h3>Fazit</h3>

<p>
Für den etwas Hardware-ambitionierten Otto-Normal-User ist Linux also immer
noch nicht geeignet – trotz Live-CDs und tollen grafischen Installern oder auch
dem althergebrachten Textinstaller (der ja die selben Programme intern
verwendet).
</p>

<p>
Von Linux abbringen lasse ich mich dadurch jedoch nicht, dafür bietet es
einfach zu viele Vorteile. Welche das sind, darf nun gerne selbst ausprobiert
werden :-).
</p>
