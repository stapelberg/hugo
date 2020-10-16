---
layout: post
title:  "Bug Report: Regression: Nuki Opener + BTicino 344212"
date:   2020-10-16 07:30:00 +02:00
categories: Artikel
---

Ich habe kürzlich einen Nuki Opener gekauft und leider nicht in Betrieb nehmen
können.

Den Nuki Opener konnte ich zwar anlernen, aber wenn er versucht, die Tür zu
öffnen, passiert im Haus einfach nichts — die Klingelanlage reagiert nicht.

Nachdem ich mit dem Nuki Support nicht weiterkam, habe ich mir zum Vergleich
einen zweiten Nuki Opener gekauft.

Mit dem **zweiten Nuki Opener funktioniert** die gleiche Modellwahl (Hersteller
BTicino, Modell 344212) und [gleiche
Verkabelung](/posts/2020-09-28-nuki-scs-bticino-decoding/): die Klingelanlage
entsperrt die Tür.

Ein Unterschied zwischen den beiden Geräten: der zweite Opener läuft noch mit
der alten Software-Version:

| Gerät          | Software-Version | Funktioniert? |
|----------------|------------------|---------------|
| Nuki Opener #1 | 1.5.3 (aktuell)  | kaputt :-(    |
| Nuki Opener #2 | 1.3.1            | funktioniert! |

Für mich sieht alles danach aus, als ob sich in neuere Software-Versionen ein
Fehler eingeschlichen hat.

Meine Oszilloskop-Aufzeichnungen beider Software-Versionen belegen, dass das
Signal, welches die aktuelle Software-Version 1.5.3 auf den [BTicino SCS
Bus](https://en.wikipedia.org/wiki/Bus_SCS) schickt, kaputt ist!

Ich stelle die rohen Messwerte jeweils in mehreren Formaten zur Verfügung, mit
denen die Engineers bei Nuki das Problem einfach nachstellen und beheben können:

* Die original Rigol Waveform-Dateien kann man mit [Rigol
  Ultrascope](https://www.rigolna.com/download/) öffnen.

* Bequemer ist wohl, die CSV-Variante in andere Waveform Viewer zu importieren.

* [SCS Signale dekodiert man am
  einfachsten](/posts/2020-09-28-nuki-scs-bticino-decoding/) mit dem [freien
  Logic Analyzer sigrok](https://sigrok.org/).

## Nuki Opener Software-Version 1.3.1 (funktioniert)

Mit Software-Version 1.3.1 erscheint nach dem Anlernen im Debug Protokoll:
```
bv/ct:276/260dV,ba:22%
R:n75,m35@0,d7
O:n67,m32@0,d7
```

Die `n` und `m` Werte entsprechen etwa den relevanten Zeiten auf dem SCS Bus, wo
einzelne Bits 104μs lang sind, aufgeteilt in 34μs für High/Low und 70μs Stille.

Die Base Voltage (`bv`) von 27.6V, und der Comparator Trigger (`ct`) von 26.0V
stimmen mit den erwarteten Pegeln des SCS Bus überein.

| Oszilloskop-Aufzeichnung SCS Bus | Rigol Waveform                                         | CSV                                                  | Sigrok                                               |
|----------------------------------|--------------------------------------------------------|------------------------------------------------------|------------------------------------------------------|
| 2020-10-15-nuki131-door-open.sr  | [wfm (1,1 MB)](/nuki/2020-10-15-nuki131-door-open.wfm) | [csv (2 MB)](/nuki/2020-10-15-nuki131-door-open.zip) | [sr (160 KB)](/nuki/2020-10-15-nuki131-door-open.sr) |
| 2020-10-15-nuki131-ring.sr       | [wfm (1,1 MB)](/nuki/2020-10-15-nuki131-ring.wfm)      | [csv (2 MB)](/nuki/2020-10-15-nuki131-ring.zip)      | [sr (160 KB)](/nuki/2020-10-15-nuki131-ring.sr)      |
| 2020-10-15-nuki131-nuki-open.sr  | [wfm (1,1 MB)](/nuki/2020-10-15-nuki131-nuki-open.wfm) | [csv (2 MB)](/nuki/2020-10-15-nuki131-nuki-open.zip) | [sr (160 KB)](/nuki/2020-10-15-nuki131-nuki-open.sr) |

Hier ist das Öffnen-Signal des Nuki Openers (`2020-10-15-nuki131-nuki-open`):

<a href="../../nuki/2020-10-15-nuki131-nuki-open.jpg"><img src="../../nuki/2020-10-15-nuki131-nuki-open.thumb.1x.jpg" srcset="../../nuki/2020-10-15-nuki131-nuki-open.thumb.2x.jpg 2x,../../nuki/2020-10-15-nuki131-nuki-open.thumb.3x.jpg 3x" width="600" alt="2020-10-15-nuki131-nuki-open" style="border: 1px solid #000" loading="lazy"></a>

## Nuki Opener Software-Version 1.5.3 (kaputt)

Mit Software-Version 1.5.3 erscheint nach dem Anlernen im Debug Protokoll:
```
bv/ct:277/261dV,ba:35%
R:n83,m31@0,d7
O:n7,m30@2,d0
```

Während sich Ring (`R`) noch in der Toleranz bewegt, sieht Open (`O`) sehr
anders aus.

Statt `0,d7` (7 Daten-Bytes, wie auf dem SCS Bus?) findet sich hier `2,d0`.

Die Länge des Signals wurde mit `n7` falsch erkannt.

| Oszilloskop-Aufzeichnung SCS Bus | Rigol Waveform                                 | CSV                                          | Sigrok                                       |
|----------------------------------|------------------------------------------------|----------------------------------------------|----------------------------------------------|
| 2020-10-09-nuki-open.sr          | [wfm (1,1 MB)](/nuki/2020-10-09-nuki-open.wfm) | [csv (2 MB)](/nuki/2020-10-09-nuki-open.zip) | [sr (160 KB)](/nuki/2020-10-09-nuki-open.sr) |

Hier ist das kaputte Öffnen-Signal des Nuki Openers (`2020-10-09-nuki-open`):

<a href="../../nuki/2020-10-09-nuki-open.jpg"><img src="../../nuki/2020-10-09-nuki-open.thumb.1x.jpg" srcset="../../nuki/2020-10-09-nuki-open.thumb.2x.jpg 2x,../../nuki/2020-10-09-nuki-open.thumb.3x.jpg 3x" width="600" alt="2020-10-09-nuki-open" style="border: 1px solid #000" loading="lazy"></a>

## Appendix A: Installation Nuki Opener

Wie ich mein Nuki Opener installiert habe, ist in [meinem Post «Nuki Opener with
an SCS bus intercom (bTicino 344212)» vom
2020-09-28](/posts/2020-09-28-nuki-scs-bticino-decoding/) ausführlich
beschrieben, inkl. Bilder.

## Appendix B: Messumgebung

Die Messungen wurden mit einem Rigol DS1102E Oszilloskop angefertigt.

Kanal 1 war auf 10X eingestellt und an den SCS Bus angeschlossen.

Die Sample Rate war auf 10 MHz eingestellt, denn:

1. `Acquire` → `Memdepth` war auf `Long mem` eingestellt.
1. Die Time Base war auf 2ms eingestellt (→ [Sample Rate
   Tabelle](https://www.eevblog.com/forum/blog/rigol-ds1052e-sample-rate-vs-timebase-setting/msg115617/#msg115617))

