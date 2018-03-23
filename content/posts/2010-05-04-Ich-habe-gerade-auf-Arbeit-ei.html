---
permalink: /post/11
layout: post
date: 2010-05-04 13:23:18 +02:00
title: "
Ich habe gerade auf Arbeit ei…"
---
<p>
Ich habe gerade auf Arbeit einen 9 Jahre alten Fehler in einem Treiber für
eine unserer Karten behoben. Das Symptom war, dass manchmal das Auslesen
des Buffers auf der Karte einfach hing. Als ich mir das Problem auf meiner
Testmaschine anschaute, hing der Transfer nicht nur, sondern gelegentlich
startete auch die Maschine neu (manchmal mit Kernel Panic).
</p>

<p>
Für Leute mit ein bisschen Kenntnis von Kerneltreibern ist nun eigentlich
die erste Vermutung, dass mit dem DMA-Transfer etwas nicht stimmt. Kurz
gesagt funktioniert DMA (Direct Memory Access) so, dass der Computer der
Karte sagt, an welcher Speicheradresse ein Buffer steht, in welchen die
Karte dann direkt schreibt. Wenn jetzt also der Transfer hängt, bedeutet
dass, dass die Karte nie signalisiert, dass sie fertig ist, was im besten
Fall bedeutet, dass sie garnicht erst angefangen hat, im schlimmsten Fall
hat sie nie aufgehört und schreibt dann natürlich einfach den gesamten Speicher
mit irgendwelchen Werten voll :-).
</p>

<p>
Leider ist auf dieser Karte der DMA-Teil nicht innerhalb des FPGAs, ansonsten
hätte man die Möglichkeit gehabt, sich genau anzuschauen, was vom Rechner
kommt und wo dabei das Problem ist. Stattdessen erledigt ein externer
Chip den DMA-Transfer, der sich allerdings über die Jahre bewährt hat.
</p>

<p>
Das eigentliche Problem war nun, dass tatsächlich einfach das Stop-Bit im
letzten DMA-descriptor fehlte. Daher trat das Problem nur bei DMA-Transfers
mit mehr als einer Page (eine Page fasst 4096 Bytes) auf (ansonsten wird als
Spezialfall nur ein Descriptor genutzt, der dann auch ein korrektes Stop-Bit
gesetzt bekommt). Weiterhin musste die Transfergröße ein Vielfaches der
Pagesize sein und der Speicher musste aligned sein (was von der Anwendung nicht
gefordert wurde, da es nicht notwendig ist in diesem Fall). Der Bugfix sieht
dann so aus:
</p>

<pre> 
-    if (restOfTransferSize < pagesize) {
+    if (restOfTransferSize <= pagesize) {
</pre>

<p>
…und ja, natürlich hab ich mir den Spaß nicht nehmen lassen, ein paar mal
den Speicher mit Müll vollzuschreiben und zu schauen, wo es kracht :-). Und
im Gegensatz zu der letzten DMA debugging session hat es mir dabei nicht das
Dateisystem zerschossen, sondern nur (wiederholt) .zsh_history und .viminfo.
</p>

