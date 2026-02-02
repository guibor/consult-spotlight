;;; consult-spotlight.el --- Consult interface to macOS mdfind (Spotlight) -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: MDF <sguibor@gmail.com>
;; URL: https://github.com/guibor/consult-spotlight
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (consult "1.5"))
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

;;; Code:

(require 'consult)
(require 'subr-x)

(defgroup consult-spotlight nil
  "Spotlight search using Consult."
  :group 'consult
  :prefix "consult-spotlight-")

(defcustom consult-spotlight-default-directory "~"
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

(defcustom consult-spotlight-stderr
  (if (eq system-type 'windows-nt) "NUL" "/dev/null")
  "File to capture stderr from the Spotlight process.
Set to nil to inherit stderr."
  :type '(choice (const :tag "Inherit" nil) file))

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

(defun consult-spotlight--builder (dirs)
  "Create a Spotlight command builder for DIRS."
  (let ((onlyin (consult-spotlight--onlyin-args dirs)))
    (lambda (input)
      (pcase-let ((`(,arg . ,opts) (consult--command-split input)))
        (unless (string-blank-p arg)
          (cons (append (consult--build-args consult-spotlight-args)
                        opts
                        onlyin
                        (list arg))
                (cdr (consult--default-regexp-compiler arg 'basic t))))))))

;;;###autoload
(defun consult-spotlight (&optional dir initial)
  "Search with macOS Spotlight for files matching input.

If DIR is a string, search within that directory.  When called
interactively with a prefix argument, prompt for DIR.  DIR may
also be a list of directories.  INITIAL is initial minibuffer input."
  (interactive "P")
  (unless (executable-find "mdfind")
    (user-error "Consult-spotlight requires the mdfind command"))
  (let* ((dir (cond
               ((stringp dir) dir)
               ((and dir (listp dir)) dir)
               (dir (read-directory-name "Spotlight directory: "
                                         consult-spotlight-default-directory
                                         nil t))
               (t consult-spotlight-default-directory)))
         (dirs (if (listp dir) dir (list dir)))
         (prompt (consult-spotlight--prompt dirs))
         (default-directory (file-name-as-directory
                             (expand-file-name (car dirs))))
         (builder (consult-spotlight--builder dirs))
         (selection
          (consult--read
           (consult--process-collection builder
             :min-input consult-spotlight-min-input
             :stderr consult-spotlight-stderr
             :highlight t)
           :prompt prompt
           :sort nil
           :require-match t
           :initial initial
           :add-history (thing-at-point 'filename)
           :category 'file
           :history '(:input consult-spotlight-history))))
    (when selection
      (find-file selection))))

(provide 'consult-spotlight)
;;; consult-spotlight.el ends here
