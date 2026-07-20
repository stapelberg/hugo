---
permalink: /post/36
layout: post
date: 2010-12-06 21:57:46 +01:00
title: "
Erkenntnis des Tages: POSIX-S…"
---
<p>
Erkenntnis des Tages: POSIX-Semaphor-Funktionen wie <code>sem_init</code>,
<code>sem_wait</code>, … funktionieren nicht, wenn der <code>sem_t</code> nicht
aligned ist (also sich beispielsweise in einer struct mit
<code>__attribute__((packed))</code> befindet).
</p>

