---
layout: post
title:  "Emacs: overriding the project.el project directory"
date:   2021-04-02 14:08:23 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1377957310245466116"
---

I recently learnt about the Emacs package `project.el`, which is used to figure
out which files and directories belong to the same project. This is [used under
the covers by
`Eglot`](https://github.com/joaotavora/eglot/blob/2fbcab293e11e1502a0128ca5f59de0ea7888a75/eglot.el#L738),
for example.

In practice, a project is recognized by looking for Git repositories, which is a
decent first approximation that often just works.

But what if the detection fails? For example, maybe you want to anchor your
project-based commands in a parent directory that contains multiple Git
repositories.

Luckily, we can provide our own entry to the `project-find-functions` hook, and
look for a `.project.el` file in the parent directories:

```elisp
;; Returns the parent directory containing a .project.el file, if any,
;; to override the standard project.el detection logic when needed.
(defun zkj-project-override (dir)
  (let ((override (locate-dominating-file dir ".project.el")))
    (if override
      (cons 'vc override)
      nil)))

(use-package project
  ;; Cannot use :hook because 'project-find-functions does not end in -hook
  ;; Cannot use :init (must use :config) because otherwise
  ;; project-find-functions is not yet initialized.
  :config
  (add-hook 'project-find-functions #'zkj-project-override))
```

Now, we can use `touch .project.el` in any directory to make `project.el`
recognize the directory as project root!

By the way, in case you are unfamiliar, the configuration above uses
[`use-package`](https://github.com/jwiegley/use-package), which is a great way
to (lazily, i.e. quickly!) load and configure Emacs packages.

{{< note >}}

**Tip:** With [a few lines of
code](https://www.reddit.com/r/emacs/comments/jt8csn/fzf_from_project_root/),
you can anchor helpful project-wide tools such as `fzf` (fuzzy finder) or `ag`
(Ack Grep) in the `project.el` root, too!

{{< /note >}}
