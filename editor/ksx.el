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

; These are the listed constants at: https://ksp-kos.github.io/KOS/language/syntax.html
; but there clearly seem to be some missing keywords here, so idk..
;
; >
; add all at batch break clearscreen compile copy declare delete
; deploy do do edit else file for from from function global if
; in list local lock log off on once parameter preserve print reboot
; remove rename run set shutdown stage step switch then to toggle
; unlock unset until volume wait when
; >
;
; These are the listed boolean operators:
;
; >
; not  and  or  true  false
; >
(defvar ksx-keywords
  (list "add" "all" "and" "at" "batch" "break" "cd" "clearscreen" "compile"
        "copy" "copypath" "create" "createdir" "declare" "delete" "deletepath"
        "deploy" "do" "edit" "else" "eta" "exists" "file" "for" "from" "function"
        "global" "if" "in" "is" "list" "local" "lock" "log" "movepath"
        "not" "off" "or" "on" "open" "parameter" "preserve" "print" "readjson"
        "reboot" "remove" "rename" "return" "run" "set" "shutdown" "stage"
        "step" "switch" "then" "to" "toggle" "unlock" "unset" "until" "volume"
        "wait" "when" "writejson")
  "List of Kerboscript keywords for ksx-mode.")

(defvar ksx-types
  (list  "sas" "steering" "throttle")
  "List of special Kerboscript types for ksx-mode.")

(defvar ksx-functions
  (list "abs" "arccos" "arcsin" "arctan" "arctan2" "ceiling" "constant" "cos"
        "floor" "heading" "ln" "log10" "max" "min" "mod" "node" "random" "round"
        "sin" "sort" "tan")
  "List of Kerboscript built-in functions for ksx-mode.")

(defvar ksx-constants
  (list "false" "true")
  "List of Kerboscript constants for ksx-mode.")

(let
    ((top-level-suffixable (list "addons"))
     (addons-suffixes (list "rt" "kac"))
     (addons-rt-suffixes
      (list "available" "delay" "kscdelay" "antennahasconnection"
            "hasconnection" "haskscconnection" "haslocalcontrol"
            "groundstations"))
     (addons-kac-suffixes (list "available" "alarms"))
     (addons-kac-alarms-suffixes
      (list "id" "name" "action" "type" "notes" "remaining" "repeat"
            "repeatperiod" "originbody" "targetbody"))
     (orbit-suffixes
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
      (list "orbit" "surface"))
     (vessel-suffixes
      (list
       "control" "bearing" "heading" "maxthrust" "maxthrustat" "availablethrust"
       "availablethrustat" "facing" "mass" "wetmass" "drymass" "dynamicpressure"
       "q" "verticalspeed" "groundspeed" "airspeed" "termvelocity" "shipname"
       "name" "status" "type" "starttracking" "angularmomentum" "angularvel"
       "sensors" "loaded" "unpacked" "loaddistance" "isdead" "patches"
       "rootpart" "controlpart" "parts" "dockingports" "elements" "resources"
       "partsnamed" "partsnamedpattern" "partstitled" "partstitledpattern"
       "partsstagged" "partsstaggedpattern" "partsdubbed" "partsdubbedpattern"
       "modulesnamed" "partsingroup" "modulesingroup" "allpartstagged"
       "crewcapacity" "crew" "connection" "messages"))
     (vessel-control-suffixes
      (list
       "pilotmainthrottle" "pilotyaw" "pilotpitch" "pilotroll" "pilotrotation"
       "pilotyawtrim" "pilotpitchtrim" "pilotrolltrim" "pilotfore"
       "pilotstarboard" "pilottop" "pilottranslation" "pilotwheelsteer"
       "pilotwheelthrottle" "pilotwheelsteertrim" "pilotwheelthrottletrim"
       "pilotneutral"))
     (vector-suffixes
      (list "x" "y" "z" "mag" "normalized" "sqrmagnitude" "direaction" "vec"))
     )
  (defvar ksx-variables
    (delete-dups (append
                  top-level-suffixable
                  addons-suffixes
                  addons-rt-suffixes
                  addons-kac-suffixes
                  addons-kac-alarms-suffixes
                  orbit-suffixes
                  orbitable-suffixes
                  orbitable-velocity-suffixes
                  vessel-suffixes
                  vessel-control-suffixes
                  vector-suffixes))
    "List of known Kerboscript variables and structure suffixes for ksx-mode."))

(defun ksx-regexp-opt (keywords)
  "Make an optimized regexp from the list of KEYWORDS."
  (regexp-opt keywords 'symbols))

(defvar ksx-font-locks
  `(( "\\(@lazyglobal\\|@import\\|@from\\|import\\)" . (1 font-lock-warning-face))
    ( "function \\([^ ]*\\)"          . (1 font-lock-function-name-face))
    ( "\\(\\(\\sw\\|\\s_\\)*\\)("     . (1 font-lock-function-name-face))
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

; START Fill handling!!!
; Shamelessly pulled from: https://github.com/rust-lang/rust-mode
(defun ksx-fill-prefix-for-comment-start (line-start)
  "Determine what to use for `fill-prefix' based on the text at LINE-START."
  (let ((result
         ;; Replace /* with same number of spaces
         (replace-regexp-in-string
          "\\(?:/\\*+?\\)[!*]?"
          (lambda (s)
            ;; We want the * to line up with the first * of the
            ;; comment start
            (let ((offset (if (eq t
                                  (compare-strings "/*" nil nil
                                                   s
                                                   (- (length s) 2)
                                                   (length s)))
                              1 2)))
              (concat (make-string (- (length s) offset)
                                   ?\x20) "*")))
          line-start)))
    ;; Make sure we've got at least one space at the end
    (if (not (= (aref result (- (length result) 1)) ?\x20))
        (setq result (concat result " ")))
    result))

(defun ksx-in-comment-paragraph (body)
  ;; We might move the point to fill the next comment, but we don't want it
  ;; seeming to jump around on the user
  (save-excursion
    ;; If we're outside of a comment, with only whitespace and then a comment
    ;; in front, jump to the comment and prepare to fill it.
    (when (not (nth 4 (syntax-ppss)))
      (beginning-of-line)
      (when (looking-at (concat "[[:space:]\n]*" comment-start-skip))
        (goto-char (match-end 0))))

    ;; We need this when we're moving the point around and then checking syntax
    ;; while doing paragraph fills, because the cache it uses isn't always
    ;; invalidated during this.
    (syntax-ppss-flush-cache 1)
    ;; If we're at the beginning of a comment paragraph with nothing but
    ;; whitespace til the next line, jump to the next line so that we use the
    ;; existing prefix to figure out what the new prefix should be, rather than
    ;; inferring it from the comment start.
    (let ((next-bol (line-beginning-position 2)))
      (while (save-excursion
               (end-of-line)
               (syntax-ppss-flush-cache 1)
               (and (nth 4 (syntax-ppss))
                    (save-excursion
                      (beginning-of-line)
                      (looking-at paragraph-start))
                    (looking-at "[[:space:]]*$")
                    (nth 4 (syntax-ppss next-bol))))
        (goto-char next-bol)))

    (syntax-ppss-flush-cache 1)
    ;; If we're on the last line of a multiline-style comment that started
    ;; above, back up one line so we don't mistake the * of the */ that ends
    ;; the comment for a prefix.
    (when (save-excursion
            (and (nth 4 (syntax-ppss (line-beginning-position 1)))
                 (looking-at "[[:space:]]*\\*/")))
      (goto-char (line-end-position 0)))
    (funcall body)))

(defun ksx-with-comment-fill-prefix (body)
  (let*
      ((line-string (buffer-substring-no-properties
                     (line-beginning-position) (line-end-position)))
       (line-comment-start
        (when (nth 4 (syntax-ppss))
          (cond
           ;; If we're inside the comment and see a * prefix, use it
           ((string-match "^\\([[:space:]]*\\*+[[:space:]]*\\)"
                          line-string)
            (match-string 1 line-string))
           ;; If we're at the start of a comment, figure out what prefix
           ;; to use for the subsequent lines after it
           ((string-match (concat "[[:space:]]*" comment-start-skip) line-string)
            (ksx-fill-prefix-for-comment-start
             (match-string 0 line-string))))))
       (fill-prefix
        (or line-comment-start
            fill-prefix)))
    (funcall body)))

(defun ksx-find-fill-prefix ()
  (ksx-in-comment-paragraph (lambda () (ksx-with-comment-fill-prefix (lambda () fill-prefix)))))

(defun ksx-fill-paragraph (&rest args)
  "Special wrapping for `fill-paragraph' to handle multi-line comments with a * prefix on each line."
  (ksx-in-comment-paragraph
   (lambda ()
     (ksx-with-comment-fill-prefix
      (lambda ()
        (let
            ((fill-paragraph-function
              (if (not (eq fill-paragraph-function 'ksx-fill-paragraph))
                  fill-paragraph-function))
             (fill-paragraph-handle-comment t))
          (apply 'fill-paragraph args)
          t))))))

(defun ksx-do-auto-fill (&rest args)
  "Special wrapping for `do-auto-fill' to handle multi-line comments with a * prefix on each line."
  (ksx-with-comment-fill-prefix
   (lambda ()
     (apply 'do-auto-fill args)
     t)))

(defun ksx-fill-forward-paragraph (arg)
  ;; This is to work around some funny behavior when a paragraph separator is
  ;; at the very top of the file and there is a fill prefix.
  (let ((fill-prefix nil)) (forward-paragraph arg)))
; END Fill handling!!!

(defun ksx-mode-reload ()
  (interactive)
  (unload-feature 'ksx)
  (require 'ksx)
  (ksx-mode))

;;;###autoload
(define-derived-mode ksx-mode prog-mode "KerboScript Extended"
  "A major mode for editing Kerboscript files."
  :group 'ksx-mode
  :syntax-table ksx-mode-syntax-table
  ; allow wrapping comments
  (setq-local comment-start "// ")
  (setq-local comment-end   "")
  (setq-local comment-start-skip "\\(?://*\\|/\\*?\\)[[:space:]]*")
  (setq-local paragraph-start
              (concat "[[:space:]]*\\(?:" comment-start-skip "\\|\\*/?[[:space:]]*\\|\\)$"))
  (setq-local normal-auto-fill-function 'ksx-do-auto-fill)
  (setq-local fill-paragraph-function 'ksx-fill-paragraph)
  (setq-local fill-forward-paragraph-function 'ksx-fill-forward-paragraph)
  (setq-local adaptive-fill-function 'ksx-find-fill-prefix)
  (setq-local adaptive-fill-first-line-regexp "")

  (setq-local font-lock-defaults '(ksx-font-locks nil t))
  (setq-local indent-line-function 'ksx-indent-line))

(add-to-list 'auto-mode-alist '("\\.ks\\'" . ksx-mode))
(add-to-list 'auto-mode-alist '("\\.ksx\\'" . ksx-mode))

(provide 'ksx)
;;; ksx.el ends here
