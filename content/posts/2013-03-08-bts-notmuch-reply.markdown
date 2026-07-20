---
layout: post
date: 2013-03-08 16:20:00 +0100
title: "Replying to Debian BTS messages in notmuch"
categories: Artikel
tags:
- debian
---
<p>
Previously, my workflow regarding replying to bugreports outside my own
packages was very uncomfortable: I first downloaded the mbox archive from the
BTS, then imported that in claws-mail, hit reply all, remove submit@, add
bugnumber@, then send the email.
</p>

<p>
Therefore, I decided to hack up a little elisp function to automate this
process for notmuch. It first downloads the message from the BTS, adds it to
the notmuch database, then calls notmuch-mua-reply on the message and fixes the
To: header:
</p>

<pre>
;; Removes submit@bugs.debian.org from the recipients of a reply-all message.
(defun debian-remove-submit (recipients)
  (delq nil
	(mapcar (lambda (recipient)
		  (and (not (string-equal (nth 1 recipient) "submit@bugs.debian.org"))
		       recipient))
		recipients)))

(defun debian-add-bugrecipient (recipients bugnumber)
  (let* ((bugaddress (concat bugnumber "@bugs.debian.org"))
	 (addresses (mapcar (lambda (x) (nth 1 x)) recipients))
	 (exists (member bugaddress addresses)))
    (if exists
	recipients
      (append (list (list (concat "Bug " bugnumber) bugaddress)) recipients))))

;; TODO: msg should be made optional and it should default to the latest message in the bugreport.
;; NB: bugnumber and msg are both strings.
(defun debian-bts-reply (bugnumber msg)
  ;; Download the message to ~/mail-copy-fs/imported.
  (let ((msgpath (format "~/mail-copy-fs/imported/bts_%s_msg_%s.msg" bugnumber msg)))
    (let* ((url (format "http://bugs.debian.org/cgi-bin/bugreport.cgi?msg=%s;mbox=yes;bug=%s" msg bugnumber))
	   (download-buffer (url-retrieve-synchronously url)))
      (save-excursion
	(set-buffer download-buffer)
	(goto-char (point-min)) ; just to be safe
	(if (not (string-equal
		  (buffer-substring (point) (line-end-position))
		  "HTTP/1.1 200 OK"))
	    (error "Could not download the message from the Debian BTS"))
	;; Delete the HTTP headers and the first "From" line (in order to
	;; make this a message, not an mbox).
	(re-search-forward "^$" nil 'move)
	(forward-char)
	(forward-line 1)
	(delete-region (point-min) (point))
	;; Store the message on disk.
	(write-file msgpath)
	(kill-buffer)))
    ;; Import the mail into the notmuch database.
    (let ((msgid (with-temp-buffer
		   (call-process "~/.local/bin/notmuch-import.py" nil t nil (expand-file-name msgpath))
		   (buffer-string))))
      (notmuch-mua-reply (concat "id:" msgid) "Michael Stapelberg &lt;stapelberg@debian.org&gt;" t)
      ;; Remove submit@bugs.debian.org, add &lt;bugnumber&gt;@bugs.debian.org.
      (let* ((to (message-fetch-field "To"))
	     (recipients (mail-extract-address-components to t))
	     (recipients (debian-remove-submit recipients))
	     (recipients (debian-add-bugrecipient recipients bugnumber))
	     (recipients-str (mapconcat (lambda (x) (concat (nth 0 x) " &lt;" (nth 1 x) "&gt;")) recipients ", ")))
	(save-excursion
	  (message-goto-to)
	  (message-delete-line)
	  (insert "To: " recipients-str "\n")))
      ;; Our modifications don’t count as modifications.
      (set-buffer-modified-p nil))))
</pre>

<p>
In case you want to get updates, you can find the latest version of this code in <a href="http://code.stapelberg.de/git/configfiles/tree/emacs-zkj-notmuch.el">my configfiles git repository</a>.
</p>

<p>
To add a single message to the notmuch database and get its message ID, I have
written this simple python script (using python-notmuch), located in
<code>~/.local/bin/python-import.py</code>:
</p>

<pre>
#!/usr/bin/env python
# vim:ts=4:sw=4:et

import notmuch
import sys

if len(sys.argv) &lt; 2:
    print "Syntax: notmuch-import.py &lt;filename&gt;"
    sys.exit(0)

db = notmuch.Database(mode=notmuch.Database.MODE.READ_WRITE)
(msg, status) = db.add_message(sys.argv[1])
print msg.get_message_id()
</pre>

<p>
If you have any improvements, I’d love to hear about it. If it’s useful for
you, enjoy.
</p>
