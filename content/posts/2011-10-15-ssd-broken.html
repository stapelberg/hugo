---
layout: post
date: 2011-10-15 16:13:00 +02:00
title: "SSD kaputt"
---
<p>
Nachdem meine SSD nun schon mehrfach für manche Blöcke Input/Output-Errors
gegeben hat (nach einem power cycle war sie aber wieder benutzbar), ist sie
gestern so ausgefallen, dass ich mich nicht mehr an meinem System anmelden
konnte und das Symptom auch über einen Neustart bestehen blieb.
</p>

<p>
Da ich ja schon vorher Anzeichen hatte, hatte ich mir rechtzeitig Ersatz
bestellt und so beschränkte sich die Reparatur auf Austauschen der Platte und
Zurückspielen des Backups. Da ich zwischen dem Ausfallzeitpunkt und letztem
Sicherungszeitpunkt ein paar kleine Änderungen an zwei Dateien gemacht hatte,
habe ich ein grml gebootet und die SSD mit einem alternativen Superblock
gemountet – dadurch konnte ich dann auf die Dateien zugreifen.
</p>

<p>
Bei der neuen SSD (eine OCZ Vertex 2, die hat derzeit das beste
Preis-/Leistungsverhältnis) habe ich diesmal die Partitionen so angelegt, dass
sie auf eine 512 KiB großen Erase Block Size ausgelegt sind. Mehr als
Dokumentation für mich denn als Anleitung hier die nötigen Schritte:
</p>

<pre>
$ fdisk -S 32 -H 32 /dev/sda
$ fdisk -l /dev/sda
Device Boot      Start         End      Blocks   Id  System
/dev/sda1            1024      511999      255488   83  Linux
/dev/sda2          513024   117230591    58358784   83  Linux
# the unit of align-payload is 512 byte sectors
$ cryptsetup luksFormat --align-payload=1024 /dev/sda2

# /boot
$ mkfs.ext4 -b 1024 -E stride=512,stripe-width=512 -O ^has_journal /dev/sda1

$ cryptsetup luksOpen /dev/sda2 sda2_crypt
$ mkfs.ext4 -b 4096 -E stride=128,stripe-width=128 /dev/mapper/sda2_crypt
</pre>

<p>
Für die „told you so“-Leute (oder Datenpunkt-Sammler, welche SSDs wann
ausfallen): Die alte SSD war von SuperTalent und hielt gute 1,5 Jahre. Ich habe
nie TRIM benutzt, was die Symptome erklären könnte. Was man probieren könnte,
wäre, die Platte leer zu machen, TRIM zu nutzen und schauen ob sie die defekten
Sektoren dann ordentlich wegsortiert. Ich hab aber derzeit nicht die Motivation
/ Mittel dazu.
</p>

<p>
Die Moral von der Geschichte ist natürlich, wie toll tägliche Backups sind. ♥
</p>
