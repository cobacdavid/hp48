;;; hp48-mode.el --- une tentative de mode pour éditer des programmes userRPL de HP48
;;; Code:
 
;; https://www.youtube.com/watch?v=ANQNLuKodHA&t=71s

;; "\\->" est à part car si dans convwords, il ne se highlighte pas seul
;; hp48 words
(defvar hp48-words
  '("ADD" "AND" "APPLY" "ARC"
    "BAR" "BEEP" "BLANK" "BOX"
    "CASE" "CF" "CHOOSE" "CHR" "CLLCD" "CYLIN"
    "DATE" "DISP" "DO" "DOERR" "DOLIST" "DOSUBS"
    "ELSE" "END" "ENDSUB" "ERASE" "EVAL"
    "FC\?" "FC\?C" "FOR" "FS\?" "FS\?C"
    "GET" "GETI" "GOR" "GROB"
    "IF" "IFT" "IFTE"
    "LAST" "LASTARG" "LIST"
    "NEXT" "NOT"
    "OR"
    "PICT" "PIXON" "POS" "PUT" "PVIEW"
    "RCL" "RCWS" "RECT" "REPEAT" "REVLIST"
    "SEQ" "SF" "START" "STO" "STREAM" "STWS"
    "THEN" "TLINE"
    "UNTIL"
    "WHILE"
    "XOR" "XRNG"
    "YRNG"
    ))

(defvar hp48-convwords
  '("ARRY\\->" "\\->ARRY"
    "B\\->R"
    "C\\->PX" "C\\->R"
    "COL\\->" "\\->COL"
    "D\\->R"
    "\\->DATE" 
    "\\->LIST"
    "NUM\\->" "\\->NUM"
    "OBJ\\->"
    "R\\->B" "R\\->C"
    "STR\\->" "\\->STR"
    "TAG\\->" "\\->TAG"
    ))

(defvar hp48-mathwords
  '("ABS" "ALOG" "ARG" "ASIN" "ASR" "ATAN" 
    "CEIL" "COMB" "CONJ" "COS" "CROSS"
    "DEG" "DOT"
    "EXP"
    "FLOOR" "FP"
    "GRAD" "\\GSLIST"
    "IP" "IM"
    "LN" "LOG"
    "MAX" "MIN" "MOD"
    "\\PILIST"
    "RAD" "RAND" "RE"
    "SIGN" "SIN" "SQ"
    "\\v/"
    ))

(defvar hp48-stackwords
  '("DEPTH" "DROP2" "DROP" "DROPN" "DUP" "DUP2" "DUPN"
    "OVER"
    "PICK"
    "ROLL" "ROLLD" "ROT"
    "SIZE" "SWAP"))

(defvar hp48-re-w (regexp-opt hp48-words 'words))
(defvar hp48-re-cv (regexp-opt hp48-convwords 'words))
(defvar hp48-re-mw (regexp-opt hp48-mathwords 'words))
(defvar hp48-re-sw (regexp-opt hp48-stackwords 'words))
(defvar hp48-keywords (list
   (cons hp48-re-w 'font-lock-keyword-face)
   (cons hp48-re-cv 'font-lock-type-face)
   (cons hp48-re-mw 'font-lock-function-name-face)
   (cons hp48-re-sw 'font-lock-builtin-face)
   (cons "\\\\<<\\|\\\\>>" 'font-lock-keyword-face)
   (cons "{.*?}" 'font-lock-constant-face)
   (cons "\\[.*?\\]" 'font-lock-constant-face)
   (cons "'.*?'" 'font-lock-constant-face)
   (cons "@.*" 'font-lock-comment-face)
   (cons "\\\\->" 'font-lock-type-face)
   )
  )

(defun hp48-completion-at-point ()
  (let ((bounds (bounds-of-thing-at-point 'word)))
    (when bounds
      (list (car bounds)
            (cdr bounds)
            (append hp48-words
                    hp48-mathwords
                    hp48-stackwords
                    hp48-convwords)))))


;; indentation par pile : le \>> fermant s'aligne sur le début de la ligne
;; contenant le \<< correspondant.
(defun hp48-indent-line ()
  (interactive)
  (let* ((step 2)
         (cur-line-start (save-excursion (beginning-of-line) (point)))
         ;; prog-stack : indentations des lignes contenant chaque \<< non fermé
         (prog-stack nil)
         ;; loop-stack : indentations des lignes contenant FOR/START/WHILE/DO/DOLIST
         (loop-stack nil))
    ;; Phase 1 : parcourir depuis le début jusqu'à la ligne courante
    (save-excursion
      (goto-char (point-min))
      (while (< (point) cur-line-start)
        (cond
         ((looking-at "\\\\<<")
          (push (current-indentation) prog-stack)
          (forward-char 3))
         ((looking-at "\\\\>>")
          (when prog-stack (pop prog-stack))
          (forward-char 3))
         ((looking-at (regexp-opt '("FOR" "START" "WHILE" "DO" "DOLIST") 'words))
          (push (current-indentation) loop-stack)
          (forward-word))
         ((looking-at (regexp-opt '("NEXT" "END") 'words))
          (when loop-stack (pop loop-stack))
          (forward-word))
	 ((looking-at (regexp-opt '("UNTIL" "REPEAT" "ELSE") 'words))
	  ;; ferme un bloc
	  (when loop-stack (pop loop-stack))
	  ;; ouvre un nouveau bloc au même niveau
	  (push (current-indentation) loop-stack)
	  (forward-word))
         (t (forward-char 1)))))
    ;; Phase 2 : calculer l'indentation de la ligne courante
    (let ((cur-indent
           (save-excursion
             (beginning-of-line)
             (skip-chars-forward " \t")
             (cond
              ;; \>> fermant : s'aligne sur le début de la ligne du \<< correspondant
              ((looking-at "\\\\>>")
               (or (car prog-stack) 0))
              ;; fermetures de boucle : s'alignent sur la ligne d'ouverture
              ((looking-at (regexp-opt '("NEXT" "END") 'words))
               (or (car loop-stack) 0))
	      ((looking-at (regexp-opt '("UNTIL" "REPEAT" "ELSE") 'words))
	       (or (car loop-stack) 0))
              ;; contenu ordinaire : indentation de l'ouvrant le plus profond + step
              ;; si aucun bloc ouvert : toplevel → colonne 0
              (t
               (if (or prog-stack loop-stack)
                   (+ (max (or (car prog-stack) 0)
                           (or (car loop-stack) 0))
                      step)
                 0))))))
      (indent-line-to cur-indent))))


;; insertion de commentaires pour état de la pile à chaque ligne
;; on evite les lignes déjà commentées
;; on ne les prend d'ailleurs pas en compte pour le calcul de le position
(defun hp48-add-stack-comments ()
  (interactive)
  (let* ((max-col (save-excursion
                    (goto-char (point-min))
                    (let ((m 0))
                      (while (not (eobp))
                        (beginning-of-line)
                        (unless (looking-at "\\s-*@")
                          (end-of-line)
                          (setq m (max m (current-column))))
                        (forward-line 1))
                      m)))
         (target-col (+ max-col 2)))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (beginning-of-line)
        (unless (looking-at "\\s-*@")
          (end-of-line)
          (unless (looking-back "@[^@]*" (line-beginning-position))
            (let ((pad (- target-col (current-column))))
              (insert (make-string (max pad 1) ?\s))
              (insert "@ "))))
        (forward-line 1)))))

;; conversion unicode vers ascii
(defvar hp48-unicode-to-tio
  '(("\\\\" . "\\\\")       ; backslash en premier
    ("∠"  . "\\<)")
    ("x̄"  . "\\x-")
    ("∇"  . "\\.V")
    ("√"  . "\\v/")
    ("∫"  . "\\.S")
    ("Σ"  . "\\GS")
    ("▶"  . "\\|>")
    ("π"  . "\\pi")
    ("∂"  . "\\.d")
    ("≤"  . "\\<=")
    ("≥"  . "\\>=")
    ("≠"  . "\\=")
    ("α"  . "\\Ga")
    ("→"  . "\\->")
    ("←"  . "\\<-")
    ("↓"  . "\\|v")
    ("↑"  . "\\|^")
    ("γ"  . "\\Gg")
    ("δ"  . "\\Gd")
    ("ε"  . "\\Ge")
    ("η"  . "\\Gn")
    ("θ"  . "\\Gh")
    ("λ"  . "\\Gl")
    ("ρ"  . "\\Gr")
    ("σ"  . "\\Gs")
    ("τ"  . "\\Gt")
    ("ω"  . "\\Gw")
    ("Δ"  . "\\GD")
    ("Π"  . "\\PI")
    ("Ω"  . "\\GW")
    ("∞"  . "\\oo")
    ("«"  . "\\<<")
    ("°"  . "\\^o")
    ("µ"  . "\\Gm")
    ("»"  . "\\>>")
    ("×"  . "\\.x")
    ("Φ"  . "\\O/")
    ("÷"  . "\\:-")
    ))

(defun hp48-ascii-to-unicode ()
  (interactive)
  (let ((case-fold-search nil))
    (save-excursion
      (dolist (pair (reverse hp48-unicode-to-tio))
        (goto-char (point-min))
        (while (search-forward (cdr pair) nil t)
          (replace-match (car pair) t t))))))

(defun hp48-unicode-to-ascii ()
  (interactive)
  (let ((case-fold-search nil))
    (save-excursion
      (dolist (pair hp48-unicode-to-tio)
        (goto-char (point-min))
        (while (search-forward (car pair) nil t)
          (replace-match (cdr pair) t t))))))

(defvar-local hp48--unicode-mode nil)

(defun hp48-toggle-unicode ()
  (interactive)
  (if hp48--unicode-mode
      (progn
        (hp48-unicode-to-ascii)
        (setq hp48--unicode-mode nil)
        (message "Mode ASCII (trigraphes)"))
    (progn
        (hp48-ascii-to-unicode)
        (setq hp48--unicode-mode t)
        (message "Mode Unicode"))))

;;
;; chemin vers x48
(defcustom hp48-x48-execpath "/usr/bin/x48"
  "Path to the x48 executable."
  :type 'string
  :group 'hp48)

(defun hp48-x48 ()
  (interactive)
  (start-process "x48" "*x48*" hp48-x48-execpath) 
  )

;; communication kermit
(defcustom hp48-kermit-config
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
"
  "Template for the Kermit configuration script.
The %s placeholder will be replaced with the device path."
  :type 'text
  :group 'hp48)

(defvar hp48-kermit-configfile "/tmp/ConnexionHP48")

(defun hp48-kermit-conf (port)
  (with-temp-file hp48-kermit-configfile
    (insert (format hp48-kermit-config port)))
  )

(defvar hp48--send-command
  (let ((cmd "kermit"))
    (concat cmd " " "%s" " -s %s")))

;; port par défaut
;; dernier choix reproposé auto.
(defcustom hp48-default-port-node "/dev/ttyUSB0"
  "Port série par défaut pour la HP48."
  :type 'string
  :group 'hp48)

(defvar hp48--last-port hp48-default-port-node)

(defun hp48-send (port)
  (interactive
   (list (completing-read "Port: "
                          '("/dev/ttyUSB0" "/dev/pts/2")
                          nil nil nil nil
                          hp48--last-port)))
  (message "Choix de %s" port)
  (setq hp48--last-port port)
  (save-buffer)
  (let* ((bfn buffer-file-name)
	 (nfn (file-name-base bfn))
	 (nf (concat "/tmp/" nfn)))
    (hp48-kermit-conf port)
    (copy-file bfn nf)
    (unwind-protect
	(shell-command
	 (format hp48--send-command hp48-kermit-configfile nf)
	 ;; messages kermit dans un buffer dédié
	 "*hp48-kermit*")
      (delete-file hp48-kermit-configfile)
      (delete-file nf))))

;; les raccourcis clavier
(defvar-keymap hp48-mode-map
  "C-c C-c" #'hp48-add-stack-comments
  "C-c C-u" #'hp48-toggle-unicode
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
  (setq-local indent-line-function #'hp48-indent-line)
  (add-hook 'completion-at-point-functions #'hp48-completion-at-point nil t)
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
