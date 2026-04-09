;;; hp48-mode.el --- une tentative de mode pour éditer des programmes userRPL de HP48
;;; Code:
 
;; https://www.youtube.com/watch?v=ANQNLuKodHA&t=71s

;; hp48 words
(defvar hp48-words
  '("AND" "ARC"
    "BEEP"
    "CASE" "CF" "CYLIN"
    "DO" "DOLIST"
    "ELSE" "END" "ERASE"
    "FC\?C" "FOR" "FS"
    "GET"
    "IF" "IFT" "IFTE"
    "LIST"
    "NEXT" "NOT"
    "OBJ\\->" "OR"
    "PICT" "POS" "PUT" "PVIEW"
    "RCL" "RECT" "REPEAT"
    "SEQ" "SF" "START" "STO"
    "THEN" "TLINE"
    "UNTIL"
    "WHILE"
    "XOR" "XRNG"
    "YRNG"
    ))


(defvar hp48-mathwords
  '("ABS" "ALOG" "ASIN"
    "B\\->R"
    "COS"
    "FP"
    "\\GSLIST"
    "IP"
    "LOG"
    "MAX" "MIN" "MOD"
    "\\PILIST"
    "SIN" "SQ"
    "\\v/"
    "\\->"))

(defvar hp48-stackwords
  '("DEPTH" "DROP2" "DROP" "DROPN" "DUP" "DUP2" "DUPN"
    "OVER"
    "PICK"
    "ROLL" "ROLLD" "ROT"
    "SIZE" "SWAP"))

(defvar hp48-re-w (regexp-opt hp48-words 'words))
(defvar hp48-re-mw (regexp-opt hp48-mathwords 'words))
(defvar hp48-re-sw (regexp-opt hp48-stackwords 'words))
(defvar hp48-keywords (list
   (cons hp48-re-w 'font-lock-keyword-face)
   (cons hp48-re-mw 'font-lock-function-name-face)
   (cons hp48-re-sw 'font-lock-builtin-face)
   (cons "\\\\<<\\|\\\\>>" 'font-lock-keyword-face)
   (cons "{.*?}" 'font-lock-constant-face)
   (cons "\\[.*?\\]" 'font-lock-constant-face)
   (cons "'.*?'" 'font-lock-constant-face)
   (cons "@.*" 'font-lock-comment-face)
   )
  )

;; lien vers x48
(defvar hp48-x48-execpath  "/usr/bin/x48")

(defun hp48-x48 ()
  (interactive)
  (start-process "x48" "*x48*" hp48-x48-execpath) 
  )

;; communication kermit
(defvar hp48-kermit-config
  "#!/usr/bin/kermit +
set line %s
set speed 9600
set carrier-watch off
set modem type direct
set flow none 
set parity none
set block 1
set control prefix all
robust
")

(defvar hp48-kermit-configfile "/tmp/ConnexionHP48")

(defun hp48-kermit-conf (port)
  (with-temp-file hp48-kermit-configfile
    (insert (format hp48-kermit-config port)))
  )

(defvar hp48--send-command
  (let ((cmd "kermit"))
    (concat cmd " " "%s" " -s %s")))

(defvar hp48-default-port-node "/dev/ttyUSB0")

(defun hp48-send (port)
  (interactive
   ;; (list (read-directory-name "Port :" hp48-default-port-node)))
   "sPort: ")
  (message "Choix de %s" port)
  (save-buffer)
  (let* ((bfn buffer-file-name)
	 (nfn (file-name-base bfn))
	 (nf (concat "/tmp/" nfn)))
    (hp48-kermit-conf port)
    (copy-file bfn nf)
    (shell-command
     (format hp48--send-command hp48-kermit-configfile nf))
    (delete-file hp48-kermit-configfile)
    (delete-file nf)
    )
  )

;;
(defvar-keymap hp48-mode-map
  "C-c C-s" #'hp48-send
  "C-c C-x" #'hp48-x48)

;; hp48 mode
(define-derived-mode hp48-mode nil "HP48"
  "major mode pour le USERRPL"
  :syntax-table (let ((st (make-syntax-table)))
		    (modify-syntax-entry ?@ "<" st)
		    (modify-syntax-entry ?\n ">" st)
		    (modify-syntax-entry ?\\ "w" st)
		    st
		    )
  (setq-local comment-start "@")
  (setq-local comment-start-skip "@+\\s-*")
  (setq-local tab-width 2)
  (setq-local font-lock-defaults '(hp48-keywords))
  )
;;(define-key hp48-mode-map "\C-c\C-s" 'hp48-send)
;;(define-key hp48-mode-map "\C-c\C-x" 'hp48-x48)
;; (add-hook 'hp48-mode-hook (lambda ()  (modify-syntax-entry ?\\ "w")))
(add-to-list 'auto-mode-alist '("\\.hp48$" . hp48-mode))
(provide 'hp48-mode)


;; ;; snippets
;; (defun hp48-insert-while ()
;;   "YASnippet aussi disponible"
;;   (interactive)
;;   (let ((positionc (current-column)))
;;     (save-excursion
;;       (insert "WHILE REPEAT\n")
;;       (insert-char ?\s positionc)
;;       (insert "\n")
;;       (insert-char ?\s positionc)
;;       (insert "END")
;;       )
;;     )
;;   (forward-word))

;; (defun hp48-insert-for (start end)
;;   "YASnippet aussi disponible"
;;   (interactive "Nstart: \nNend: ")
;;   (let ((positionc (current-column)))
;;     (insert (number-to-string start) " " (number-to-string end) " ")
;;     (insert "FOR I\n")
;;     (insert-char ?\s positionc)
;;     (insert "\n")
;;     (insert-char ?\s positionc)
;;     (insert "NEXT")
;;     (forward-line -1)
;;     (insert-char ?\s positionc)
;;     ))
