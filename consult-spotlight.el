;;; consult-spotlight.el --- Consult interface to macOS mdfind (Spotlight) -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: MDF <sguibor@gmail.com>
;; URL: https://github.com/guibor/consult-spotlight
;; Version: 0.2.0
;; Package-Requires: ((emacs "28.1") (consult "2.0"))
;; Keywords: matching, files, convenience

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; consult-spotlight provides a Consult-powered interface to macOS
;; Spotlight (mdfind).  Results are fetched asynchronously and can be
;; opened directly from the minibuffer.
;;
;; With Embark, press `M-o b' on a candidate to open it in the default
;; browser via `consult-spotlight-open-in-browser'.

;;; Code:

(require 'consult)
(require 'subr-x)

(defgroup consult-spotlight nil
  "Spotlight search using Consult."
  :group 'consult
  :prefix "consult-spotlight-")

(defcustom consult-spotlight-default-directory "~/"
  "Default base directory for Spotlight searches."
  :type 'directory)

(defcustom consult-spotlight-min-input 2
  "Minimum input length before starting the Spotlight process."
  :type 'integer)

(defcustom consult-spotlight-args
  "mdfind"
  "Command line arguments for mdfind, see `consult-spotlight'.
The dynamically computed arguments are appended.
Can be either a string, or a list of strings or expressions."
  :type '(choice string (repeat (choice string sexp))))

(defcustom consult-spotlight-silence-stderr t
  "Whether to discard stderr from the Spotlight process."
  :type 'boolean)

(defcustom consult-spotlight-register-embark-actions t
  "Register `consult-spotlight-open-in-browser' on `embark-file-map'."
  :type 'boolean)

(defvar consult-spotlight-history nil
  "Minibuffer history for `consult-spotlight'.")

(defun consult-spotlight--onlyin-args (dirs)
  "Return a list of -onlyin arguments for DIRS."
  (mapcan (lambda (dir)
            (list "-onlyin" (file-name-as-directory (expand-file-name dir))))
          dirs))

(defun consult-spotlight--prompt (dirs)
  "Return a minibuffer prompt for DIRS."
  (let ((disp (mapcar (lambda (dir)
                        (abbreviate-file-name (expand-file-name dir)))
                      dirs)))
    (format "Spotlight (%s): "
            (if (= (length disp) 1)
                (car disp)
              (format "%d dirs" (length disp))))))

(defun consult-spotlight--silence-stderr (command)
  "Return COMMAND with stderr discarded if configured."
  (if consult-spotlight-silence-stderr
      (append (list "/bin/sh" "-c" "exec \"$@\" 2>/dev/null" "consult-spotlight")
              command)
    command))

(defun consult-spotlight--builder (dirs)
  "Create a Spotlight command builder for DIRS."
  (let ((onlyin (consult-spotlight--onlyin-args dirs)))
    (lambda (input)
      (pcase-let ((`(,arg . ,opts) (consult--command-split input)))
        (unless (string-blank-p arg)
          (cons (consult-spotlight--silence-stderr
                 (append (consult--build-args consult-spotlight-args)
                         opts
                         onlyin
                         (list arg)))
                (cdr (consult--default-regexp-compiler arg 'basic t))))))))

(defun consult-spotlight--read (builder prompt &optional initial)
  "Read a Spotlight result from BUILDER using PROMPT and optional INITIAL."
  (consult--read
   builder
   :prompt prompt
   :sort nil
   :require-match t
   :initial initial
   :add-history (thing-at-point 'filename)
   :category 'file
   :state (consult--file-preview)
   :history '(:input consult-spotlight-history)))

;;;###autoload
(defun consult-spotlight-open-in-browser (file)
  "Open FILE or URL in the default browser."
  (interactive "fOpen in browser: ")
  (require 'browse-url)
  (let ((file (substring-no-properties file)))
    (browse-url
     (if (string-match-p "\\`[a-z]+://" file)
         file
       (browse-url-file-url (expand-file-name file))))))

(defun consult-spotlight--register-embark-actions ()
  "Register Embark actions for Spotlight file candidates."
  (define-key embark-file-map "b" #'consult-spotlight-open-in-browser))

;;;###autoload
(defun consult-spotlight (&optional dir initial)
  "Search with macOS Spotlight for files matching input.

If DIR is a string, search within that directory.  When called
interactively with a prefix argument, prompt for DIR.  DIR may
also be a list of directories.  INITIAL is initial minibuffer input.

While selecting a candidate, use Embark (`M-o' by default) and then
`b' to open the file in the default browser."
  (interactive
   (when current-prefix-arg
     (list (read-directory-name "Spotlight directory: "
                                consult-spotlight-default-directory
                                nil t))))
  (unless (executable-find "mdfind")
    (user-error "Consult Spotlight requires the mdfind command"))
  (let* ((dirs (if (and dir (listp dir))
                   dir
                 (list (or dir consult-spotlight-default-directory))))
         (prompt (consult-spotlight--prompt dirs))
         (default-directory (file-name-as-directory
                             (expand-file-name (car dirs))))
         (builder (consult-spotlight--builder dirs))
         (selection (consult-spotlight--read builder prompt initial)))
    (when selection
      (find-file selection))))

(with-eval-after-load 'embark
  (when consult-spotlight-register-embark-actions
    (consult-spotlight--register-embark-actions)))

(provide 'consult-spotlight)
;;; consult-spotlight.el ends here
