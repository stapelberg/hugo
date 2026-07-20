---
permalink: /post/42
layout: post
date: 2011-03-06 20:29:32 +01:00
title: "
Um in 'git diff' immer einen …"
---
<p>
Um in 'git diff' immer einen Pager zu kriegen (also nicht einfach die Ausgabe
ins Terminal geklatscht, was mir zu unübersichtlich ist), kann man folgende
Einstellung setzen:
</p>

<pre>
$ git config --global pager.diff 'LESS=RS less -c'
</pre>

<p>
Getestet mit git 1.7.4.1 aus Debian unstable (<code>apt-get install
git/unstable</code>), mit älteren Versionen geht es anscheinend nicht.
</p>

