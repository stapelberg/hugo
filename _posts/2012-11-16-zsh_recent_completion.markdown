---
layout: post
title:  "zsh: tab-completing recent files"
date:   2012-11-16 13:18:00
categories: Artikel
---


<p>
This short article describes the most important productivity enhancement for
working in a shell (zsh) in the last few months for me: A shortcut for
completing the most recent files.
</p>

<p>
In my daily work, it often happens that I save an email attachment (or download
a file from the internet) and then do something with it in a shell, like
unpacking it, applying a patch to source code, and so on.
</p>

<p>
While I do have an alias to execute <code>ls -hltr</code> which shows me the
most recently modified files, it is much more convenient to just tab-complete
the most recent file.
</p>

<p>
Based on Feh’s zsh configuration, I added the following statements to my zshrc:
</p>

<pre>
# 'ctrl-x r' will complete the 12 last modified (mtime) files/directories
zle -C newest-files complete-word _generic
bindkey '^Xr' newest-files
zstyle ':completion:newest-files:*' completer _files
zstyle ':completion:newest-files:*' file-patterns '*~.*(omN[1,12])'
zstyle ':completion:newest-files:*' menu select yes
zstyle ':completion:newest-files:*' sort false
zstyle ':completion:newest-files:*' matcher-list 'b:=*' # important
</pre>

<p>
Now, being in <code>/tmp</code> and launching <code>vi</code>, when I press
Control+x followed by r, this is what I get:
</p>

<img src="/Bilder/zsh-tab-complete-recent.png" alt="zsh: tab-completing recent files">
