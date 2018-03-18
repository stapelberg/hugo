---
layout: post
title:  "Xen-Server sichern mit LVM-Snapshots"
date:   2009-10-08 13:38:38
categories: Artikel
Aliases:
  - /Artikel/xen_lvm_snapshot
---



<p>
  Wenn man einen Server mit Xen virtualisiert, steht man beim Einrichten des
  Backups vor der Frage, wie man das Backup organisiert. Hier gibt es
  (mindestens) die folgenden Ansätze:
</p>

<ol>
  <li style="margin-bottom: 25px">
    Man betrachtet jede virtuelle Instanz als eigenständig und installiert
    dort jeweils die Backupsoftware.<br>
    <br>
    Vorteil: Keine zusätzliche/neue Konfiguration nötig für den
    Host-Rechner.<br>
    Nachteil: Pro Instanz ein Backup-Job nötig, je nach Anzahl der Instanzen
    wird es schnell unübersichtlich.
  </li>

  <li style="margin-bottom: 25px">
    Man fertigt vor dem Backup einen kompletten Snapshot der Instanzen an und
    sichert diesen dann auf dem Hostrechner.<br>
    <br>
    Vorteil: Weniger Konfigurationsaufwand<br>
    Nachteil: Zeitaufwändig, Speicherplatzaufwändig, Wiederherstellung einzelner
    Dateien kompliziert/zeitaufwändig.
  </li>

  <li>
    Man benutzt LVM und fertigt einen Snapshot vor der Sicherung an, den man
    dann ins Dateisystem einhängt und einfach den kompletten Hostrechner
    sichert.<br>
    <br>
    Vorteil: Spart Zeit, Speicherplatz, ermöglicht Wiederherstellung einzelner
    Dateien<br>
    Nachteil: Je nach Konfiguration ist es etwas umständlich, die Partitionen
    aus den einzelnen Logical Volumes zu mounten.
  </li>
</ol>

<p>
  Ich möchte in diesem Artikel näher auf die dritte Methode eingehen, da bei
  allen anderen die Nachteile überwiegen. Weiterhin bietet sich die Methode
  mit den LVM-Snapshots ohnehin an wenn man seine Instanzen in jeweils einem
  Logical Volume aufgesetzt hat (damit man später bei Bedarf die Größe ändern
  kann – das ist bei einer herkömmlichen Installation <a
  href="/Artikel/Xen_resize">deutlich komplizierter</a>).
</p>

<h2>Installation von einer domU auf einem LV</h2>

<p>
  Für die Installation einer domU auf einem LV geht man ganz normal vor (wie
  beispielsweise <a href="http://wiki.debian.org/Xen">im Debian Wiki</a>
  beschrieben), nur dass man bei der Konfiguration der Festplatte den LVM-Pfad
  zu seinem LV angibt. Wenn also die Volume Group <code>in.zekjur.net</code>
  heißt und das LV <code>domu-infra</code>, sieht der passende Eintrag
  folgendermaßen aus:
</p>

<pre>disk = ['phy:in.zekjur.net/domu-infra,xvda,w']</pre>

<p>
  Der Name des LVs ist übrigens später noch wichtig. Über den Prefix
  <code>domu-</code> identifizieren wir die LVs, von denen wir einen Snapshot
  anfertigen werden.
</p>

<h2>Das Prinzip von LVM-Snapshots</h2>

<p>
  Snapshots werden angefertigt, indem man ein neues LV erstellt und beim
  Erstellen angibt, von welchem LV dieses ein Snapshot werden soll. Bei der
  Erstellung kann man, wie üblich, Name und Größe angeben. Anschließend hat
  man ein neues LV, welches bei Zugriff dieselben Daten enthält wie das
  Original zum Zeitpunkt der Anfertigung des Snapshots. Das sieht in etwa so
  aus:
</p>

<pre># lvcreate -n snap_infra -L 1G -s in.zekjur.net/domu-infra
Logical volume "snap_infra" created
# lvs
LV         VG            Attr   LSize  Origin     Snap%  Move Log Copy% Convert
domu-infra in.zekjur.net owi-ao 10,00G                                          
root       in.zekjur.net -wi-ao 10,00G                                          
snap_infra in.zekjur.net swi-a-  1,00G domu-infra   0,00                        
swap_1     in.zekjur.net -wi-ao  9,47G                                          
</pre>

<p>
  Die vorhin angegebene Größe dient nun dazu, die Änderungen an einer der
  beiden Versionen (Original oder Snapshot) zu speichern. Das ist zum Beispiel
  dann nötig, wenn sich die Originaldaten verändern (Logfiles etc.), aber
  auch, wenn sich Daten im Snapshot verändern (wir werden das Journal später
  im Snapshot „reparieren” müssen). Ich benutze als Größe 1 GB, was locker
  ausreichen sollte für meine Daten. Wenn sich mehr Daten ändern, muss man
  diesen Wert natürlich entsprechend erhöhen.
</p>

<h2>Die Problematik: Partitionen im LV</h2>

<p>
  Sofern man nicht absichtlich die domU auf die komplette Platte (/dev/xvda)
  installiert hat, steht man nun vor einem kleinen Problem: Innerhalb des LVs
  befindet sich nun eine Partitionstabelle. Auf die einzelnen Partitionen kann
  man nun leider nicht bequem zugreifen. Stattdessen muss man das Offset der
  gewünschten Datenpartition herausfinden und diese dann loop-mounten. Damit
  es einfach bleibt, gehe ich davon aus, dass die gewünschte Datenpartition
  die erste ext3-Partition ist, alle anderen Partitionen werden ignoriert.
</p>

<p>
  Um besagtes Offset zu finden, kann man sich <code>parted</code> zu nutze
  machen, welchem man folgendermaßen die Partitionstabelle in der passenden
  Einheit entlocken kann:
</p>

<pre># parted /dev/mapper/in.zekjur.net-snap_infra
GNU Parted 1.8.8
Using /dev/mapper/in.zekjur.net-snap_infra
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) unit                                                             
Unit?  [compact]? B                                                       
(parted) print                                                            
Model: Linux device-mapper (snapshot) (dm)
Disk /dev/mapper/in.zekjur.net-snap_infra: 10737418240B
Sector size (logical/physical): 512B/512B
Partition Table: msdos

Number  Start         End           Size          Type      File system  Flags
 1      32256B        10232248319B  10232216064B  primary   ext3         boot 
 2      10232248320B  10733990399B  501742080B    extended                    
 5      10232280576B  10733990399B  501709824B    logical   linux-swap        

(parted)                                                                  
</pre>

<p>
  In diesem Fall müssen wir also das LV ab Stelle 32256 benutzen, was
  folgendermaßen machbar ist:
</p>

<pre># losetup -o 32256 -f /dev/mapper/in.zekjur.net-snap_infra 
# losetup -a
/dev/loop0: [000c]:2119316 (/dev/mapper/in.zekjur.net-snap_infra), offset 32256
</pre>

<p>
  Wenn man nun allerdings versucht, <code>/dev/loop0</code> direkt zu mounten,
  wird dies nicht gelingen (ich gehe von <code>ext3</code> als Dateisystem
  aus). Das liegt daran, dass das Journal nicht auf die „Platte” geschrieben
  wurde, schließlich haben wir das Dateisystem nicht korrekt unmounted
  innerhalb unserer domU.
</p>

<p>
  Glücklicherweise kann man in LVM2 auch schreibend auf Snapshots zugreifen,
  sodass wir mit einem Aufruf von <code>fsck</code> das Journal „reparieren”
  können:
</p>

<pre># fsck.ext3 -y /dev/loop0
e2fsck 1.41.3 (12-Oct-2008)
/dev/loop0: recovering journal
/dev/loop0: clean, 53600/624624 files, 366091/2498099 blocks
</pre>

<p>
  Anschließend kann man das Dateisystem ganz normal mounten und sichern.
</p>

<h2>Automatisieren</h2>

<p>
  Da ich diesen Vorgang gerne automatisiert in meine Backup-Software einbinden
  würde, habe ich dazu ein Script geschrieben, welches alle oben genannten
  Schritte durchführt. Aufgeteilt sind die Scripts in mount und unmount,
  weiterhin gibt es ein <code>foreach-domu</code>-Script, welches für alle
  LVs, deren Name mit <code>domu-</code> beginnt (muss er ohnehin für die
  anderen Scripts) die passende Aktion ausführt.
</p>

<p>
  Herunterladen kannst du dir die Scripts via git:
</p>

<pre># git clone git://code.stapelberg.de/xen-lvm-snapshot</pre>

<p>
  Anschauen kannst du dir sie <a
  href="http://code.stapelberg.de/git/xen-lvm-snapshot">im Webinterface</a>.
</p>

<h2>Einbinden in bacula</h2>

<p>
  Durch die „Client Run Before Job”- und „Client Run After Job”-Optionen von
  bacula ist das Einbinden ziemlich einfach:
</p>

<pre>
Job {  
        Name = "in.zekjur.net"
        Type = Backup
        Client = in.zekjur.net-fd
        FileSet = "in.zekjur.net-set"
        Schedule = "in.zekjur.net-sched"
        Storage = in.zekjur.net-storage
        Messages = Standard
        Priority = 10
        Write Bootstrap = "/raid/bacula/in.zekjur.net/bootstrap"
        Pool = in.zekjur.net
        Maximum Concurrent Jobs = 1
        Spool Attributes = no
        <strong>Client Run Before Job = "/root/bin/xen-lvm-snapshot/foreach-domu.sh mount"</strong>
        <strong>Client Run After Job = "/root/bin/xen-lvm-snapshot/foreach-domu.sh unmount"</strong>
}
</pre>

<p>
  Anschließend sollte man sicherstellen, dass <code>/mnt</code> im FileSet
  nicht von der Sicherung ausgenommen wird.
</p>
