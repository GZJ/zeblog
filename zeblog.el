;;; zeblog.el --- A minimalist blog based on org  -*- lexical-binding: t -*-

;;; Copyright (C) 2023 GZJ

;; Author: GZJ <gzj00@outlook.com>
;; Keywords: blog
;; Version: 1.0.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; zeblog is a minimalist blog based on org.

;;; Code:
;;;; ------------------ require ------------------------------
(require 'org)
(require 'org-id)
(require 'xmlgen)
(require 'ox-publish)

;;;; ------------------ customize ------------------------------
(defgroup zeblog nil
  "zeblog group"
  :group 'edit)
;;;;; ------------------ customize variable ------------------------------
(setq zeblog-index-file-path '(concat (file-name-as-directory zeblog-path) zeblog-index-file))
(setq zeblog-buffer-prefix "zeblog-")
(setq zeblog-posts-path '(concat (file-name-as-directory zeblog-path) zeblog-posts-dir))
(setq zeblog-post-file-suffix ".org")
(setq zeblog-post-file-files-suffix ".files")
(setq zeblog-post-file-property-name "property.org")
(setq zeblog-post-setupfile '(concat (file-name-as-directory zeblog-path) zeblog-post-file-property-name))
(setq zeblog-index-file-html-path '(concat (file-name-as-directory (eval zeblog-publish-path)) zeblog-index-file-html))
(setq zeblog-publish-file-suffix ".html")
(setq zeblog-publish-path '(concat (file-name-as-directory zeblog-path) zeblog-publish-dir))

;;;;; ------------------ init customize ------------------------------
(defcustom zeblog-path ""
  "the index of zeblog"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-author ""
  "the name of zeblog"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-email ""
  "the email of zeblog"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-publish-url ""
  "zeblog publish url"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-publish-rss-title ""
  "zeblog publish title"
  :type 'string
  :group 'zeblog)

;;;;; ------------------ post file name and content ------------------------------
(defcustom zeblog-index-file "index.org"
  "the index of zeblog"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-index-file-html "index.html"
  "the index of zeblog"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-index-file-html-templ "index.html.tmpl"
  "template file for index.html"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-post-file-property "#+TITLE: %s\n\n"
  "the posts insert index.html"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-index-html-post "<div class=\"article\"><a href=\"%s.html\"> %s </a></div>"
  "the post insert index.html"
  :type 'string
  :group 'zeblog)

;;;;; ------------------ post and export directory ------------------------------
(defcustom zeblog-posts-dir "posts"
  "posts dir"
  :type 'string
  :group 'zeblog)

(defcustom zeblog-publish-dir "public_html"
  "publish dir"
  :type 'string
  :group 'zeblog)

;;;; ------------------ face ------------------------------
(defface zeblog-face
  '((t (:foreground "green" :background "black")))
  "face for zeblog"
  :group 'zeblog)

;;;; ------------------ var ------------------------------
(setq zeblog-published-files '())
(setq zeblog-publish-include-files '())

;;;; ------------------ function ------------------------------
;;;;; mode keymap
(defvar zeblog-mode-map nil "Keymap for `zeblog-mode'")
(progn
  (setq zeblog-mode-map (make-sparse-keymap))
  (define-key zeblog-mode-map (kbd "i") (lambda () (interactive) (zeblog-post-create 'next)))
  (define-key zeblog-mode-map (kbd "I") (lambda () (interactive) (zeblog-post-create 'prev)))
  (define-key zeblog-mode-map (kbd "c") (lambda () (interactive) (zeblog-post-create-open 'next)))
  (define-key zeblog-mode-map (kbd "C") (lambda () (interactive) (zeblog-post-create-open 'prev)))
  (define-key zeblog-mode-map (kbd "d") 'zeblog-post-delete)
  (define-key zeblog-mode-map (kbd "r") 'zeblog-post-rename)
  (define-key zeblog-mode-map (kbd "<return>") 'zeblog-post-open-other-window)
  (define-key zeblog-mode-map (kbd "S-<return>") 'zeblog-post-open)
  ;;  (define-key zeblog-mode-map [down-mouse-1] 'zeblog-post-open-click)
  (define-key zeblog-mode-map (kbd "n") 'zeblog-index-next)
  (define-key zeblog-mode-map (kbd "p") 'zeblog-index-prev)
  (define-key zeblog-mode-map (kbd "j") 'zeblog-index-next)
  (define-key zeblog-mode-map (kbd "k") 'zeblog-index-prev)
  (define-key zeblog-mode-map (kbd "M-<up>") 'zeblog-index-post-up)
  (define-key zeblog-mode-map (kbd "M-<down>") 'zeblog-index-post-down)
  (define-key zeblog-mode-map (kbd "K") 'zeblog-index-post-up)
  (define-key zeblog-mode-map (kbd "J") 'zeblog-index-post-down)
  (define-key zeblog-mode-map (kbd "m") 'zeblog-index-mark)
  (define-key zeblog-mode-map (kbd "M") 'zeblog-index-unmark)
  (define-key zeblog-mode-map (kbd "P") 'zeblog-publish)
  (define-key zeblog-mode-map (kbd "B") 'zeblog-browse-index)
  (define-key zeblog-mode-map (kbd "b") 'zeblog-browse-post)
  )

;;;###autoload
(define-derived-mode zeblog-mode org-mode
  "zeblog"
  (use-local-map zeblog-mode-map)
  (setq org-html-postamble nil)
  )

(add-hook 'zeblog-mode-hook
	  (lambda ()
	    (setq-local org-emphasis-alist
			'(("*" (bold :background "yellow")))
			)

	    (setq-local org-ascii-headline-spacing '(0 . 0))
	    (setq-local org-ascii-bullets '((ascii 42) (latin1 167) (utf-8 8226)))
	    (setq org-html-head-extra  "
<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\"/>
<meta name='viewport' content='width=device-width, initial-scale=1' />
<style> a {text-decoration:none;} </style>
")
	    )
	  )

(defvar zeblog-post-mode-map nil "Keymap for `zeblog-post-mode'")
(progn
  (setq zeblog-post-mode-map org-mode-map)
  (define-key zeblog-post-mode-map (kbd "C-c y") 'zeblog-post-paste-image)
  )

;;;###autoload
(define-derived-mode zeblog-post-mode org-mode
  "zeblog-post"
  (use-local-map zeblog-post-mode-map)
  )

;;;###autoload
(defun zeblog-init(path)
  (interactive "sblog path:")
  (let ((p (expand-file-name path))
	(tmpl (expand-file-name zeblog-index-file-html-templ path))
	)
    (unless (file-exists-p p)
      ;; (error "Path does not exist: %s" p))
      (make-directory p)
      )

    (unless (file-exists-p tmpl)
      ;;      (copy-file (expand-file-name zeblog-index-file-html-templ (zeblog-source-code-path)) p)
      (copy-file (expand-file-name zeblog-index-file-html-templ (zeblog-source-code-path)) (expand-file-name zeblog-index-file-html-templ p))
      )

    (zeblog-init-customize)
    (customize-set-variable 'zeblog-path p)
    )
  (with-current-buffer
      (find-file (eval zeblog-index-file-path))
    (rename-buffer (concat zeblog-buffer-prefix (file-name-nondirectory (buffer-file-name (current-buffer)))))

    (setq org-hide-emphasis-markers t)
    (zeblog-mode)
    (read-only-mode 1)
    )
  )

(defun zeblog-init-customize()
  (interactive)
  (while (string= "" zeblog-author)
    (customize-set-variable 'zeblog-author(read-string "Enter author: "))
    )
  (while (string= "" zeblog-email)
    (customize-set-variable 'zeblog-email (read-string "Enter email: "))
    )
  (while (string= "" zeblog-publish-url)
    (customize-set-variable 'zeblog-publish-url (read-string "Enter publish url: "))
    )
  (while (string= "" zeblog-publish-rss-title)
    (customize-set-variable 'zeblog-publish-rss-title (read-string "Enter publish rss title: "))
    )
  )

(defun zeblog-delete()
  (interactive)
  (progn
    (setq delete-by-moving-to-trash t)
    (delete-directory zeblog-path t)
    (with-current-buffer
	(concat zeblog-buffer-prefix zeblog-index-file)
      (set-buffer-modified-p nil)
      (kill-buffer (current-buffer))
      )
    )
  )

(defun zeblog-source-code-path()
  (interactive)
  (file-name-directory (format "%s" (symbol-file 'zeblog-source-code-path)))
  )

;;;;; utils function
(defun file-to-string (file)
  "File to string function"
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defun move-current-line-up ()
  (interactive)
  (let ((col (current-column)))
    (transpose-lines 1)
    (previous-line 2)
    (move-to-column col)
    )
  )

(defun move-current-line-down ()
  (interactive)
  (let ((col (current-column)))
    (next-line)
    (transpose-lines 1)
    (previous-line 1)
    (move-to-column col)
    )
  )

(defun has-previous-line-content ()
  "Return t if the previous line contains non-whitespace characters, otherwise return nil."
  (interactive)
  (if (= (line-number-at-pos) 1)
      nil
    (save-excursion
      (forward-line -1)
      (looking-at-p "\\S-")
      )
    )
  )

(defun has-next-line-content ()
  "Return t if the next line contains non-whitespace characters, otherwise return nil."
  (interactive)
  (save-excursion
    (forward-line)
    (looking-at-p "\\S-")))

;;;;; index
;;;;;; index all
(defun zeblog-index-all-posts ()
  (interactive)
  (let ((lines '()))
    (with-current-buffer
	(concat zeblog-buffer-prefix zeblog-index-file)
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (setq lines (append lines (list (buffer-substring-no-properties (line-beginning-position)
                                                                          (line-end-position)))))
          (forward-line 1))))
    (vconcat lines)
    ;;remove mark symbol
    (mapcar
     (lambda (line)
       (if (string-prefix-p "*" line)
	   (setq line (substring line 1)))
       (if (string-suffix-p "*" line)
	   (setq line (substring line 0 -1)))
       line)
     lines)
    ))

;;;;;; index post name
(defun zeblog-index-post-name-insert(name pos)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((inhibit-read-only t))
      (pcase pos
	('prev (save-excursion (goto-char (line-beginning-position)) (insert name) (newline)))
	('next (save-excursion (goto-char (line-end-position)) (newline) (insert name)))
	)
      )
    )
  )

(defun zeblog-index-post-name-get()
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (if (and
	 (string-match-p "*" (string (char-after (line-beginning-position))) )
	 (string-match-p "*" (string (char-before (line-end-position))) )
	 )
	(buffer-substring-no-properties (+ (line-beginning-position) 1) (- (line-end-position) 1))
      (buffer-substring-no-properties (line-beginning-position) (line-end-position))
      )
    )
  )

(defun zeblog-index-post-name-delete()
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((inhibit-read-only t))
      (kill-whole-line)
      )
    )
  )

(defun zeblog-index-post-rename(name)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((inhibit-read-only t))
      (delete-region (line-beginning-position)(line-end-position))
      (insert name)
      )
    )
  )

;;;;;; index post up down
(defun zeblog-index-post-up()
  (interactive)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((inhibit-read-only t))
      (if (has-previous-line-content)
	  (move-current-line-up)
	)
      )
    )
  )
(defun zeblog-index-post-down()
  (interactive)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((inhibit-read-only t))
      (if (has-next-line-content)
	  (move-current-line-down)
	)
      )
    )
  )

;;;;;; index cursor move
(defun zeblog-index-next()
  (interactive)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (forward-line 1)
    )
  )
(defun zeblog-index-prev()
  (interactive)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (forward-line -1)
    )
  )

;;;;;; index mark
(defun zeblog-index-mark()
  (interactive)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((inhibit-read-only t))
      (unless (and
	       (string-match-p "*" (string (char-after (line-beginning-position))) )
	       (string-match-p "*" (string (char-before (line-end-position))) )
	       )
	(save-excursion
	  (goto-char (line-beginning-position))
	  (insert "*")
	  (goto-char (line-end-position))
	  (insert "*")
	  )
	)
      )
    )
  )

(defun zeblog-index-unmark()
  (interactive)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((inhibit-read-only t))
      (if (and
	   (string-match-p "*" (string (char-after (line-beginning-position))) )
	   (string-match-p "*" (string (char-before (line-end-position))) )
	   )
	  (progn
	    (goto-char  (line-beginning-position))
	    (delete-char 1)
	    (goto-char  (- (line-end-position) 1))
	    (delete-char 1)
	    )
	(message "It's not published")
	)
      )
    )
  )

(defun zeblog-index-marked-p ()
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((line-text (buffer-substring (line-beginning-position) (line-end-position))))
      (if (string-match "^\\*.*\\*$" line-text)
          t
	nil)))
  )

(defun zeblog-index-marked-text ()
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((line-text (buffer-substring (line-beginning-position) (line-end-position))))
      (if (string-match "^\\*\\(.*\\)\\*$" line-text)
          (substring-no-properties (match-string 1 line-text))
	nil)))
  )

(defun zeblog-index-marked-posts()
  (interactive)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((posts '()))
      (org-element-map (org-element-parse-buffer) 'bold
	(lambda (bold)
    	  (add-to-list 'posts  (substring-no-properties (car  (org-element-contents bold))) t)
	  )
	)
      posts)
    )
  )

(defun zeblog-index-marked-posts-file()
  (interactive)
  (with-current-buffer
      (concat zeblog-buffer-prefix zeblog-index-file)
    (let ((posts '()))
      (org-element-map (org-element-parse-buffer) 'bold
	(lambda (bold)
    	  (add-to-list 'posts  (concat (substring-no-properties (car  (org-element-contents bold))) ".org") t)
	  )
	)
      posts)
    )
  )

;;;;; posts
;;;;;; post get file path
(defun zeblog-post-file-path (name)
  (concat (file-name-as-directory (eval zeblog-posts-path)) name zeblog-post-file-suffix)
  )

(defun zeblog-post-files-file-path (name)
  (concat (file-name-as-directory (eval zeblog-posts-path)) name zeblog-post-file-files-suffix )
  )
;;post publish file and files path
(defun zeblog-post-publish-file-path (name)
  (concat (file-name-as-directory (eval zeblog-publish-path)) name zeblog-publish-file-suffix)
  )

(defun zeblog-post-files-publish-file-path (name)
  (concat (file-name-as-directory (eval zeblog-publish-path)) name zeblog-post-file-files-suffix)
  )

;;;;;; post create and open
(defun zeblog-post-create(pos)
  (interactive)
  (let ((post-title (read-string "Title name:")))
    (zeblog-index-post-name-insert post-title pos)
    (with-current-buffer
	(find-file-noselect (zeblog-post-file-path post-title))
      (rename-buffer (concat zeblog-buffer-prefix (file-name-nondirectory (buffer-file-name (current-buffer)))))
      (insert (format zeblog-post-file-property post-title))
      (save-buffer)
      )
    )
  )

(defun zeblog-post-create-open(pos)
  (interactive)
  (let ((post-title (read-string "Title name:")))
    (zeblog-index-post-name-insert post-title pos)
    (with-current-buffer
	(find-file (zeblog-post-file-path post-title))
      (rename-buffer (concat zeblog-buffer-prefix (file-name-nondirectory (buffer-file-name (current-buffer)))))
      (insert (format zeblog-post-file-property post-title))
      (save-buffer)
      )
    )
  )

(defun zeblog-post-open ()
  (interactive)
  (with-current-buffer
      (find-file (zeblog-post-file-path (zeblog-index-post-name-get)))
    (rename-buffer (concat zeblog-buffer-prefix (file-name-nondirectory (buffer-file-name (current-buffer)))))
    (zeblog-post-mode)
    )
  )

(defun zeblog-post-open-other-window ()
  (interactive)
  (with-current-buffer
      (find-file-other-window (zeblog-post-file-path (zeblog-index-post-name-get)))
    (rename-buffer (concat zeblog-buffer-prefix (file-name-nondirectory (buffer-file-name (current-buffer)))))
    (zeblog-post-mode)
    )
  )


(defun zeblog-post-open-click (event)
  (interactive "e")
  (let ((pos (posn-point (event-end event))))
    (goto-char pos)
    (let ((post-file (zeblog-post-file-path (zeblog-index-post-name-get))))
      (if (file-exists-p post-file)
	  (with-current-buffer
	      (find-file post-file)
	    (rename-buffer (concat zeblog-buffer-prefix (file-name-nondirectory (buffer-file-name (current-buffer)))))
	    (zeblog-post-mode)
	    )
	)
      )
    )
  )

;;;;;; post update
(defun zeblog-post-title-update (newName)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "#\\+TITLE:.*" nil t)
      (replace-match (format "#+TITLE: %s" newName))
      ))
  )

(defun zeblog-post-rename()
  (interactive)
  (let ((new (read-string "new name:"))
	(old (zeblog-index-post-name-get))
	(post-files (zeblog-post-files-file-path (zeblog-index-post-name-get)))
	(post-published (zeblog-post-publish-file-path (zeblog-index-post-name-get)))
	(post-files-published (zeblog-post-files-publish-file-path (zeblog-index-post-name-get)))
	)
    (zeblog-index-post-rename new)
    (rename-file (zeblog-post-file-path old ) (zeblog-post-file-path new))
    (if (file-exists-p post-files)
	(rename-file (zeblog-post-file-path old ) (zeblog-post-file-path new))
      )
    (if (file-exists-p post-published)
	(rename-file (zeblog-post-publish-file-path old ) (zeblog-post-publish-file-path new))
      )
    (if (file-exists-p post-files-published)
	(rename-file (zeblog-post-files-publish-file-path old ) (zeblog-post-files-publish-file-path new))
      )
    (with-current-buffer
	(find-file-noselect (zeblog-post-file-path new))
      (zeblog-post-title-update new)
      )
    (zeblog-generate-html-index)
    )
  )

;;;;;; post delete
(defun zeblog-post-delete()
  (interactive)
  (zeblog-post-delete-all-files (zeblog-index-post-name-get))
  (zeblog-generate-html-index)
  )

(defun zeblog-post-delete-all-files(name)
  (interactive)
  (let ((file (zeblog-post-file-path name))
	(post-files (zeblog-post-files-file-path name))
	(post-published (zeblog-post-publish-file-path name))
	(post-files-published (zeblog-post-files-publish-file-path name))
	)
    (if (file-exists-p file)
	(progn
	  (setq delete-by-moving-to-trash t)
	  (delete-file file t))
      (if (file-exists-p post-files)
	  (progn
	    (setq delete-by-moving-to-trash t)
	    (delete-directory post-files t))
	)
      (if (file-exists-p post-published)
	  (progn
	    (setq delete-by-moving-to-trash t)
	    (delete-file post-published t))
	)
      (if (file-exists-p post-files-published)
	  (progn
	    (setq delete-by-moving-to-trash t)
	    (delete-directory post-files-published t))
	)
      (zeblog-index-post-name-delete)
      )
    )
  )

(defun zeblog-posts-clean()
  (interactive)
  )

;;;;;; post content
(defun zeblog-post-paste-image ()
  "Take a screenshot into a time stamped unique-named file in the
  same directory as the org-buffer and insert a link to this file."
  (interactive)
  (unless (file-directory-p (concat (file-name-base buffer-file-name) ".files"))
    (make-directory (concat (file-name-sans-extension  buffer-file-name) ".files"))
    )
  (let* ((imagename
          (concat
           (make-temp-name
            (concat (file-name-nondirectory buffer-file-name)
                    "_"
                    (format-time-string "%Y%m%d_%H%M%S_")) ) ".png"))
	 (dirpath (concat (file-name-base buffer-file-name) ".files"))
	 (imagepath (concat (file-name-as-directory dirpath) imagename))
	 )

    (message (format "magick clipboard: \"%s\"  " imagename))
    (message imagepath)
    (shell-command (format "magick clipboard: \"%s\"  " imagename))
    (rename-file imagename imagepath)
    (insert (concat "[[file:" imagepath "]]"))
    (org-display-inline-images)))

;;;; ------------------ publish ------------------------------
;;;;; publish function
(defun zeblog-publish()
  (interactive)
  (make-directory (eval zeblog-publish-path) t)
  (zeblog-generate-html-index)
  (setq zeblog-publish-include-files (zeblog-index-marked-posts-file))
  (call-interactively 'zeblog-publish-clean)
  (setq org-publish-project-alist
	(list
	 (list "zeblog-posts"
	       :exclude "."
	       :include zeblog-publish-include-files
	       :base-directory (eval zeblog-posts-path)
	       :base-extension "org"
	       :publishing-directory (eval zeblog-publish-path)
	       :publishing-function 'zeblog-org-html-publish-to-html
	       :recursive t
	       :headline-levels 4
	       :auto-preamble t
	       :section-numbers nil
	       :author zeblog-author
	       :email zeblog-email
	       :setupfile (eval zeblog-post-setupfile)
	       )
	 )
	)
  (let ((org-publish-use-timestamps-flag nil)
	(org-publish-use-timestamps nil))
    (funcall-interactively 'org-publish "zeblog-posts")
    (zeblog-generate-rss)
    )
  (setq zeblog-published-files zeblog-publish-include-files)
  )

(defun zeblog-publish-clean()
  (interactive)
  (setq zeblog-publish-include-files (zeblog-index-marked-posts-file))
  (setq diff (cl-set-difference zeblog-published-files zeblog-publish-include-files :test #'string=))
  (if (eq diff nil)
      ()
    (dolist (file diff)
      (let ((f (zeblog-post-publish-file-path (file-name-sans-extension file))))
	(when (file-exists-p f)
	  (setq delete-by-moving-to-trash t)
	  (delete-file f t))
	)
      )
    )
  )

;;;;; generate posts html
(defun zeblog-org-html-publish-to-html (plist filename pub-dir)
  (if (file-exists-p (concat (file-name-sans-extension filename) zeblog-post-file-files-suffix))
      (copy-directory (concat (file-name-sans-extension filename) zeblog-post-file-files-suffix) pub-dir)
    )
  (org-html-publish-to-html plist filename pub-dir)
  )

;;;;; generate rss.xml
(defun zeblog-generate-rss()
  (interactive)
  (let (
	(default-directory (eval zeblog-publish-path))
	(posts (zeblog-index-marked-posts))
	xml
	tagRss
	tagChannel)
    
    (setq xml (concat "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		      (progn
			(setq tagRss '(rss :version "2.0"))
			(setq tagChannel '(channel))
			(mapcar (lambda (post)
				  (let  ((tagTitle post)
					 (tagLink (format "%s/%s"  zeblog-publish-url (concat post zeblog-publish-file-suffix)))
					 (tagDescription))
				    (setq post-content (zeblog-org-file-to-html-body (zeblog-post-file-path post)))
				    (setq tagDescription (encode-coding-string post-content 'utf-8))
				    (add-to-list 'tagChannel  `(item (title ,tagTitle)(link ,tagLink)(description ,tagDescription))  t)
				    )
				  )
				posts)
			(add-to-list 'tagRss tagChannel t)
			(xmlgen tagRss)
			)
		      )
	  )
    (with-temp-file "rss.xml"
      (insert xml)
      )
    )
  )

(defun zeblog-org-file-to-html-body (file-path)
  (unless (file-exists-p file-path)
    (error "File does not exist: %s" file-path))
  (require 'ox-html)
  (let ((org-export-with-toc nil)
        (org-export-with-section-numbers nil)
        (org-export-body-only t)
	)
    (with-temp-buffer
      (insert-file-contents file-path)
      (org-mode)
      (org-export-as 'html nil nil t))))

;;;;; generate index.html
(defun zeblog-generate-html-index()
  (interactive)
  (let ((templ (file-to-string zeblog-index-file-html-templ))
	(posts (zeblog-index-marked-posts))
	posts-div
	posts-html
	)
    (setq posts-div (mapcar (lambda (post)
			      (format  zeblog-index-html-post post post))
			    posts)
	  )
    (mapcar (lambda (div)
	      (setq posts-html (concat posts-html "\n" div))
	      )
	    posts-div)
    (with-temp-file (eval zeblog-index-file-html-path)
      (insert (replace-regexp-in-string  "{{posts}}"   posts-html templ))
      )
    )
  )

;;;; ------------------ browse ------------------------------
(defun zeblog-browse-index()
  (interactive)
  (browse-url (eval zeblog-index-file-html-path))
  )

(defun zeblog-browse-post()
  (interactive)
  (browse-url (concat (file-name-as-directory (eval zeblog-publish-path)) (zeblog-index-post-name-get) zeblog-publish-file-suffix))
  )

(defun zeblog-browse-rss()
  (interactive)
  (browse-url (concat (file-name-as-directory (eval zeblog-publish-path))  "rss.xml"))
  )

(provide 'zeblog)
;;; zeblog.el ends here
