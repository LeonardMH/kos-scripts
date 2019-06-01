;;; ksx -- Major mode for Kerboscript Extended.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; This is derived directly from ks.el in the jarpy/ks-mode repo:
;; https://github.com/jarpy/ks-mode


(if (featurep 'ksx) (unload-feature 'ksx))

(defvar ksx-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?\n "> b" st)
    st)
  "Syntax table for ksx-mode.")

(defvar ksx-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "RET") 'reindent-then-newline-and-indent)
    keymap)
  "Keymap for ksx-mode.")

(defvar ksx-keywords
  (list "add" "all" "and" "at" "batch" "break" "cd" "clearscreen" "compile"
        "copy" "copypath" "create" "createdir" "declare" "delete" "deletepath"
        "deploy" "do" "edit" "else" "eta" "exists" "file" "for" "from" "function"
        "global" "heading" "if" "in" "is" "list" "local" "lock" "log" "movepath"
        "not" "off" "or" "on" "open" "parameter" "preserve" "print" "readjson"
        "reboot" "remove" "rename" "return" "run" "set" "shutdown" "stage"
        "step" "switch" "then" "to" "toggle" "unlock" "unset" "until" "volume"
        "wait" "when" "writejson")
  "List of Kerboscript keywords for ksx-mode.")

(defvar ksx-types
  (list  "sas" "steering" "throttle")
  "List of special Kerboscript types for ksx-mode.")

(defvar ksx-functions
  (list "abs" "arccos" "arcsin" "arctan" "arctan2" "ceiling"
        "constant" "cos" "floor" "ln" "log10" "max" "min" "mod"
        "node" "random" "round" "sin" "sort" "tan")
  "List of Kerboscript built-in functions for ksx-mode.")

(defvar ksx-constants
  (list "false" "true")
  "List of Kerboscript constants for ksx-mode.")

(let
    ((orbit-suffixes
      (list "apoapsis" "argumentofperiapsis" "body" "eccentricity"
            "hasnextpatch" "inclination" "lan"
            "longitudeofascendingnode" "meananomalyatepoch" "name"
            "nextpatch" "periapsis" "period" "position"
            "semimajoraxis" "semiminoraxis" "transition" "trueanomaly"
            "velocity"))
     (orbitable-suffixes
      (list "altitude" "apoapsis" "body" "direction" "distance"
            "geoposition" "hasbody" "hasobt" "hasorbit" "latitude"
            "longitude" "name" "north" "obt" "patches" "periapsis"
            "position" "prograde" "retrograde" "ship" "srfprograde"
            "srfretrograde" "the" "up" "velocity"))
     (orbitable-velocity-suffixes
      (list "orbit" "surface")))
  (defvar ksx-variables
    (delete-dups (append orbit-suffixes orbitable-suffixes
                         orbitable-velocity-suffixes))
    "List of known Kerboscript variables and structure suffixes for ksx-mode."))

(defun ksx-regexp-opt (keywords)
  "Make an optimized regexp from the list of KEYWORDS."
  (regexp-opt keywords 'symbols))

(defvar ksx-font-locks
  `(( "function \\([^ ]*\\)"        . (1 font-lock-function-name-face))
    ( "@lazyglobal off"             . font-lock-warning-face)
    ( ,(ksx-regexp-opt ksx-functions) . font-lock-builtin-face)
    ( ,(ksx-regexp-opt ksx-keywords)  . font-lock-keyword-face)
    ( ,(ksx-regexp-opt ksx-variables) . font-lock-variable-name-face)
    ( ,(ksx-regexp-opt ksx-types)     . font-lock-type-face)
    ( ,(ksx-regexp-opt ksx-constants) . font-lock-constant-face)))

(defvar ksx-indent 2
  "Indentation size for ksx-mode.")

(defun ksx-blank-line-p ()
  (save-excursion
    (beginning-of-line)
    (looking-at "[[:space:]]*\\(//.*\\)?$")))

(defun ksx-previous-indentation ()
  "Get the indentation of the previous significant line of Kerboscript."
  (save-excursion
    (ksx-backward-significant-line)
    (current-indentation)))

(defun ksx-backward-significant-line ()
  "Move backwards to the last non-blank, non-comment line of Kerboscript."
  (interactive)
  (forward-line -1)
  (while (and (ksx-blank-line-p)
              (not (bobp)))
    (forward-line -1))
  (current-indentation))

(defun ksx-unterminated-line-p ()
  "Is the current line of Kerboscript unterminated?"
  (save-excursion
    (beginning-of-line)
    (if (ksx-blank-line-p)
        nil
      (not (ksx-looking-at ".*[.{}]")))))

(defun ksx-unterminated-previous-line-p ()
  "Is the previous line of Kerboscript unterminated?"
  (save-excursion
    (beginning-of-line)
    (if (bobp)
        nil
      (progn
        (ksx-backward-significant-line)
        (ksx-unterminated-line-p)))))

(defun ksx-indent-buffer ()
  "Indent the current buffer as Kerboscript."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (ksx-indent-line)
    (while (not (ksx-last-line-p))
      (forward-line)
      (ksx-indent-line))))

(defun ksx-last-line-p ()
  "Is this the last line?"
  (save-excursion
    (end-of-line)
    (= (point) (point-max))))

(defun ksx-looking-at (regexp)
  "Look for REGEXP on this line, ignoring strings and comments."
  (let ((line (thing-at-point 'line))
        (string "\"\[^\"\]*\"")
        (comment "[[:space:]]*//.*"))
    (setq line (replace-regexp-in-string string "" line))
    (setq line (replace-regexp-in-string comment "" line))
    (string-match regexp line)))

(defun ksx-indent-line ()
  "Indent a line of Kerboscript."
  (interactive)
  (let* ((target-line (thing-at-point 'line))
         (indentation (ksx-previous-indentation))
         (opening-brace ".*{")
         (closing-brace ".*}.*")
         (indent-more
          (lambda()(setq indentation (+ indentation ksx-indent))))
         (indent-less
          (lambda()(setq indentation (- indentation ksx-indent)))))
    (save-excursion
      (beginning-of-line)
      (if (bobp)
          (setq indentation 0)
        (progn (if (ksx-looking-at closing-brace)
                   (funcall indent-less))
               (ksx-backward-significant-line)
               (if (ksx-looking-at opening-brace)
                   (funcall indent-more))
               ; Hanging indent.
               (if (and (ksx-unterminated-line-p)
                        (not (ksx-unterminated-previous-line-p))
                        (not (string-match opening-brace target-line)))
                   (funcall indent-more))
               ; Recover from hanging indent.
               (if (and (not (ksx-unterminated-line-p))
                        (ksx-unterminated-previous-line-p)
                        (not (ksx-looking-at opening-brace)))
                   (funcall indent-less)))))
    (indent-line-to (max indentation 0))))

(define-derived-mode ksx-mode fundamental-mode "ksx"
  "A major mode for editing Kerboscript files."
  :syntax-table ksx-mode-syntax-table
  (setq-local font-lock-defaults '(ksx-font-locks nil t))
  (setq-local indent-line-function 'ksx-indent-line)
  (if (featurep 'rainbow-delimiters) (rainbow-delimiters-mode-enable)))

(add-to-list 'auto-mode-alist '("\\.ks\\'" . ksx-mode))
(add-to-list 'auto-mode-alist '("\\.ksx\\'" . ksx-mode))

(provide 'ksx)
;;; ksx.el ends here
