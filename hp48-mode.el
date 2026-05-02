;;; hp48-mode.el --- une tentative de mode pour éditer des programmes userRPL de HP48
;;; Author: David Cobac
;;; Date: 2025-2026

;; Xah Lee "Emacs Lisp Write Python Mode" 
;; https://www.youtube.com/watch?v=ANQNLuKodHA&t=71s

;; hp48 words
(defvar hp48-words
  '("ADD" "AND" "APPLY" "ARC"
    "BAR" "BEEP" "BLANK" "BOX"
    "CASE" "CF" "CHOOSE" "CHR" "CLLCD" "CYLIN"
    "DATE" "DISP" "DO" "DOERR" "DOLIST" "DOSUBS" "DTAG"
    "ELSE" "END" "ENDSUB" "ERASE" "EVAL"
    "FC\\?" "FC\\?C" "FOR" "FS\\?" "FS\\?C"
    "GET" "GETI" "GOR" "GROB"
    "IF" "IFT" "IFTE"
    "KILL"
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

;; Commandes de conversion contenant \->
;; Dans le buffer (mode ASCII/trigraphes), le backslash est un caractère
;; littéral. Pour le matcher en regex il faut \\ dans la regex, soit
;; \\\\ dans un string Elisp.  On n'utilise PAS 'words car \b en fin
;; de pattern ne matche pas après > (caractère non-word).
(defvar hp48-convwords
  '("ARRY\\->" "\\->ARRY"
    "B\\->R"
    "C\\->PX" "C\\->R"
    "COL\\->" "\\->COL"
    "D\\->R"
    "\\->DATE"
    "\\->LIST"
    "NUM\\->" "\\->NUM"
    "OBJ\\->" "\\->OBJ"
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
    "GRAD" "\\\\GSLIST"
    "IP" "IM"
    "LN" "LOG"
    "MAX" "MIN" "MOD"
    "NEG"
    "\\\\PILIST"
    "RAD" "RAND" "RE"
    "SIGN" "SIN" "SQ"
    "\\\\v/"
    ))

(defvar hp48-stackwords
  '("DEPTH" "DROP2" "DROP" "DROPN" "DUP" "DUP2" "DUPN"
    "OVER"
    "PICK"
    "ROLL" "ROLLD" "ROT"
    "SIZE" "SWAP"))

(defvar hp48-re-w (regexp-opt hp48-words 'words))
;; \b seulement au début : les patterns finissant par > n'ont pas de
;; frontière de mot après eux, mais > n'est jamais suivi d'un autre
;; identifiant HP48 sans espace, donc pas de faux positif.
(defvar hp48-re-cv (concat "\\b" (regexp-opt hp48-convwords)))
(defvar hp48-re-mw (regexp-opt hp48-mathwords 'words))
(defvar hp48-re-sw (regexp-opt hp48-stackwords 'words))

;; Calcule la colonne ASCII correspondant à la colonne unicode TARGET dans LINE.
;; En mode ASCII, les trigraphes (ex. \<< = 3 chars) comptent pour 1 char imprimé.
(defun hp48--ascii-col-for-unicode-col (line target)
  (let ((apos 0)
        (ucol 0)
        (len  (length line))
        ;; On ignore la première entrée (\\ → \\, identité) du tableau
        (trigraphs (mapcar #'cdr (cdr hp48-unicode-to-tio))))
    (while (and (< apos len) (< ucol target))
      (let ((matched nil))
        (dolist (tri trigraphs)
          (unless matched
            (let ((tlen (length tri)))
              (when (and (<= (+ apos tlen) len)
                         (string= (substring line apos (+ apos tlen)) tri))
                (setq apos (+ apos tlen) ucol (1+ ucol) matched t)))))
        (unless matched
          (setq apos (1+ apos) ucol (1+ ucol)))))
    apos))

;; Matcher font-lock dynamique : repère le surplus au-delà de la colonne 23
;; unicode sur chaque ligne, quelle que soit le mode (ASCII ou unicode).
;; 23 est +/- le nombre de caractères utilisés sur l'imprimante thermique
;; originale de HP et reprise ici
(defun hp48--overflow-matcher (limit)
  (let (found)
    (while (and (not found) (< (point) limit))
      (let* ((bol (line-beginning-position))
             (eol (line-end-position))
             (overflow
              (if hp48--unicode-mode
                  (+ bol 23)
                (+ bol (hp48--ascii-col-for-unicode-col
                        (buffer-substring-no-properties bol eol) 23)))))
        (if (< overflow eol)
            (progn
              (set-match-data (list overflow eol))
              (goto-char (1+ eol))
              (setq found t))
          (forward-line 1))))
    found))

(defvar hp48-keywords
  (list
   ;; Avertissement : caractères au-delà de la colonne 23 (en largeur unicode).
   ;; Le matcher dynamique tient compte des trigraphes en mode ASCII.
   '(hp48--overflow-matcher (0 font-lock-warning-face t))
   (cons hp48-re-w  'font-lock-keyword-face)
   (cons hp48-re-cv 'font-lock-type-face)
   ;; Équivalents unicode des convwords (→ à la place de \->)
   ;; section à revoir avec le tableau d'association fait après pour les conversions
   ;; qui avaient déjà été faites...
   (cons (regexp-opt
          '("ARRY→" "→ARRY"
            "B→R"
            "C→PX" "C→R"
            "COL→" "→COL"
            "D→R"
            "→DATE"
            "→LIST"
            "NUM→" "→NUM"
            "OBJ→" "→OBJ"
            "R→B" "R→C"
            "STR→" "→STR"
            "TAG→" "→TAG"))
         'font-lock-type-face)
   (cons hp48-re-mw 'font-lock-function-name-face)
   ;; Équivalents unicode des mathwords (√, ΣLIST, ΠLIST)
   (cons "√\\|ΣLIST\\|ΠLIST" 'font-lock-function-name-face)
   (cons hp48-re-sw 'font-lock-builtin-face)
   ;; \<< \>> et leurs équivalents unicode « »
   (cons "\\\\<<\\|\\\\>>\\|«\\|»" 'font-lock-keyword-face)
   (cons "{.*?}"    'font-lock-constant-face)
   (cons "\\[.*?\\]" 'font-lock-constant-face)
   (cons "'.*?'"    'font-lock-constant-face)
   (cons "@.*"      'font-lock-comment-face)
   ;; \-> seul et son équivalent unicode → (standalone)
   (cons "\\\\->\\|→" 'font-lock-type-face)
   ))

(defun hp48-completion-at-point ()
  (let ((bounds (bounds-of-thing-at-point 'word)))
    (when bounds
      (list (car bounds)
            (cdr bounds)
            (append hp48-words
                    hp48-mathwords
                    hp48-stackwords
                    hp48-convwords)))))


;; indentation par pile
(defun hp48-indent-line ()
  (interactive)
  (let ((step 2)
        (cur-line-start (save-excursion (beginning-of-line) (point)))
        ;; prog-stack : indentation de la ligne contenant chaque \<< non fermé
        (prog-stack nil)
        ;; loop-stack : indentation de la ligne contenant chaque
        ;; ouvrant non fermé
        (loop-stack nil))
    ;; Phase 1 : parcourir depuis le début du buffer jusqu'au début de la
    ;;           ligne courante afin de reconstruire l'état des piles.
    (save-excursion
      (goto-char (point-min))
      (while (< (point) cur-line-start)
        (cond
         ;; --- programmes : \<< ouvre, \>> ferme ---
         ((looking-at "\\\\<<")
          (push (current-indentation) prog-stack)
          (forward-char 3))
         ((looking-at "\\\\>>")
          (when prog-stack (pop prog-stack))
          (forward-char 3))
         ;; --- ouvrants de structure ---
         ((looking-at (regexp-opt '("IF" "FOR" "START" "WHILE" "DO") 'words))
          (push (current-indentation) loop-stack)
          (forward-word))
         ;; --- fermants : dépile ---
         ((looking-at (regexp-opt '("NEXT" "END" "STEP") 'words))
          (when loop-stack (pop loop-stack))
          (forward-word))
         ;; --- mid-blocks : dépile puis repousse l'indentation courante ---
         ((looking-at (regexp-opt '("THEN" "REPEAT" "ELSE" "UNTIL") 'words))
          (when loop-stack (pop loop-stack))
          (push (current-indentation) loop-stack)
          (forward-word))
         (t (forward-char 1)))))
    ;; Phase 2 : calculer l'indentation à appliquer à la ligne courante.
    (let ((cur-indent
           (save-excursion
             (beginning-of-line)
             (skip-chars-forward " \t")
             (cond
              ;; \>> fermant : s'aligne sur le début de la ligne du \<< correspondant
              ((looking-at "\\\\>>")
               (or (car prog-stack) 0))
              ;; fermant s'aligne sur la ligne d'ouverture
              ((looking-at (regexp-opt '("NEXT" "END" "STEP") 'words))
               (or (car loop-stack) 0))
              ;; mid-block : s'aligne eux aussi sur leur ouvrant
              ((looking-at (regexp-opt '("UNTIL" "THEN" "REPEAT" "ELSE") 'words))
               (or (car loop-stack) 0))
              ;; contenu ordinaire : ouvrant le plus profond (toutes piles
              ;; confondues) + step ; toplevel si aucun bloc ouvert
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
;; https://www.azimonti.com/hp48gx/
(defvar hp48-unicode-to-tio
  '(("\\\\" . "\\\\")       ; backslash en premier
    
    ;; --- Symboles mathématiques et lettres grecques (alias nommés) ---
    ("∠"  . "\\<)")         ; Right angle      0x80
    ("x̄"  . "\\x-")         ; x overbar        0x81
    ("∇"  . "\\.V")         ; Nabla            0x82
    ("√"  . "\\v/")         ; Racine carrée    0x83
    ("∫"  . "\\.S")         ; Intégrale        0x84
    ("Σ"  . "\\GS")         ; Somme            0x85
    ("▶"  . "\\|>")         ; Triangle droit   0x86
    ("π"  . "\\pi")         ; pi               0x87
    ("∂"  . "\\.d")         ; Dérivée partielle 0x88
    ("≤"  . "\\<=")         ; ≤                0x89
    ("≥"  . "\\>=")         ; ≥                0x8A
    ("≠"  . "\\=/")         ; ≠                0x8B
    ("α"  . "\\Ga")         ; alpha            0x8C
    ("→"  . "\\->")         ; →                0x8D
    ("←"  . "\\<-")         ; ←                0x8E
    ("↓"  . "\\|v")         ; ↓                0x8F
    ("↑"  . "\\|^")         ; ↑                0x90
    ("γ"  . "\\Gg")         ; gamma            0x91
    ("δ"  . "\\Gd")         ; delta            0x92
    ("ε"  . "\\Ge")         ; epsilon          0x93
    ("η"  . "\\Gn")         ; eta              0x94
    ("θ"  . "\\Gh")         ; theta            0x95
    ("λ"  . "\\Gl")         ; lambda           0x96
    ("ρ"  . "\\Gr")         ; rho              0x97
    ("σ"  . "\\Gs")         ; sigma            0x98
    ("τ"  . "\\Gt")         ; tau              0x99
    ("ω"  . "\\Gw")         ; omega            0x9A
    ("Δ"  . "\\GD")         ; Delta maj.       0x9B
    ("Π"  . "\\PI")         ; Pi maj.          0x9C
    ("Ω"  . "\\GW")         ; Omega maj.       0x9D
    ("■"  . "\\[]")         ; Carré plein      0x9E
    ("∞"  . "\\oo")         ; Infini           0x9F

    ;; --- Symboles typographiques (alias nommés) ---
    ("«"  . "\\<<")         ; «                0xAB
    ("°"  . "\\^o")         ; Degré            0xB0
    ("µ"  . "\\Gm")         ; Micro/mu         0xB5
    ("»"  . "\\>>")         ; »                0xBB

    ;; --- Opérateurs mathématiques (alias nommés) ---
    ("×"  . "\\.x")         ; ×                0xD7
    ("ß"  . "\\Gb")         ; sharp s          0xDF
    ("÷"  . "\\:-")         ; ÷                0xF7

    ;; --- Phi (conservé, absent du site) ---
    ("Φ"  . "\\O/")

    ;; --- Caractères à code numérique (0xA0–0xBF) ---
    ;; (" "  . "\\160")        ; Espace insécable
    ("¡"  . "\\161")        ; ! inversé
    ("¢"  . "\\162")        ; Cent
    ("£"  . "\\163")        ; Livre sterling
    ("¤"  . "\\164")        ; Monnaie générique
    ("¥"  . "\\165")        ; Yen
    ("¦"  . "\\166")        ; Barre brisée
    ("§"  . "\\167")        ; Paragraphe
    ("¨"  . "\\168")        ; Tréma
    ("©"  . "\\169")        ; Copyright
    ("ª"  . "\\170")        ; Indicateur ordinal féminin
    ("¬"  . "\\172")        ; Négation logique
    ("®"  . "\\174")        ; Registered
    ("¯"  . "\\175")        ; Macron
    ("±"  . "\\177")        ; Plus ou moins
    ("²"  . "\\178")        ; Exposant 2
    ("³"  . "\\179")        ; Exposant 3
    ("´"  . "\\180")        ; Accent aigu
    ("¶"  . "\\182")        ; Pied-de-mouche
    ("·"  . "\\183")        ; Point médian
    ("¸"  . "\\184")        ; Cédille
    ("¹"  . "\\185")        ; Exposant 1
    ("º"  . "\\186")        ; Indicateur ordinal masculin
    ("¼"  . "\\188")        ; 1/4
    ("½"  . "\\189")        ; 1/2
    ("¾"  . "\\190")        ; 3/4
    ("¿"  . "\\191")        ; ? inversé

    ;; --- Capitales latines étendues (0xC0–0xD6) ---
    ("À"  . "\\192")
    ("Á"  . "\\193")
    ("Â"  . "\\194")
    ("Ã"  . "\\195")
    ("Ä"  . "\\196")
    ("Å"  . "\\197")
    ("Æ"  . "\\198")
    ("Ç"  . "\\199")
    ("È"  . "\\200")
    ("É"  . "\\201")
    ("Ê"  . "\\202")
    ("Ë"  . "\\203")
    ("Ì"  . "\\204")
    ("Í"  . "\\205")
    ("Î"  . "\\206")
    ("Ï"  . "\\207")
    ("Ð"  . "\\208")
    ("Ñ"  . "\\209")
    ("Ò"  . "\\210")
    ("Ó"  . "\\211")
    ("Ô"  . "\\212")
    ("Õ"  . "\\213")
    ("Ö"  . "\\214")
    ("×"  . "\\215") ;; × déjà présent avec \\.x
    ("Ø"  . "\\216")
    ("Ù"  . "\\217")
    ("Ú"  . "\\218")
    ("Û"  . "\\219")
    ("Ü"  . "\\220")
    ("Ý"  . "\\221")
    ("Þ"  . "\\222")
    ;; ß déjà présent avec \\Gb

    ;; --- Minuscules latines étendues (0xE0–0xFF) ---
    ("à"  . "\\224")
    ("á"  . "\\225")
    ("â"  . "\\226")
    ("ã"  . "\\227")
    ("ä"  . "\\228")
    ("å"  . "\\229")
    ("æ"  . "\\230")
    ("ç"  . "\\231")
    ("è"  . "\\232")
    ("é"  . "\\233")
    ("ê"  . "\\234")
    ("ë"  . "\\235")
    ("ì"  . "\\236")
    ("í"  . "\\237")
    ("î"  . "\\238")
    ("ï"  . "\\239")
    ("ð"  . "\\240")
    ("ñ"  . "\\241")
    ("ò"  . "\\242")
    ("ó"  . "\\243")
    ("ô"  . "\\244")
    ("õ"  . "\\245")
    ("ö"  . "\\246")
    ;; ÷ déjà présent avec \\:-
    ("ø"  . "\\248")
    ("ù"  . "\\249")
    ("ú"  . "\\250")
    ("û"  . "\\251")
    ("ü"  . "\\252")
    ("ý"  . "\\253")
    ("þ"  . "\\254")
    ("ÿ"  . "\\255")
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
        (display-fill-column-indicator-mode -1)
        (font-lock-flush)
        (message "Mode ASCII (trigraphes)"))
    (progn
      (hp48-ascii-to-unicode)
      (setq hp48--unicode-mode t)
      (display-fill-column-indicator-mode 1)
      (font-lock-flush)
      (message "Mode Unicode"))))

;; gestion x48
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
  ;; IOPAR: { 9600 0 0 0 1 3 }
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
                          '("/dev/ttyUSB0" "/dev/pts/1")
                          nil nil nil nil
                          hp48--last-port)))
  (message "Choix de %s" port)
  (setq hp48--last-port port)
  (save-buffer)
  (let* ((bfn buffer-file-name)
	 (nfn (file-name-base bfn))
	 (nf (concat "/tmp/" nfn)))
    (hp48-kermit-conf port)
    (copy-file bfn nf t)
    (unwind-protect
	(shell-command
	 (format hp48--send-command hp48-kermit-configfile nf)
	 ;; messages kermit dans un buffer dédié
	 "*hp48-kermit*")
      (delete-file hp48-kermit-configfile)
      (delete-file nf))))

;;
;; impression
(defcustom hp48-printer-name "QL-700"
  "Nom de l'imprimante d'étiquettes pour l'impression HP48."
  :type 'string
  :group 'hp48)

(defcustom hp48-label-width-mm 62
  "Largeur de l'étiquette en millimètres."
  :type 'integer
  :group 'hp48)

(defcustom hp48-label-line-height-mm 4
  "Hauteur d'une ligne en millimètres pour le calcul de la hauteur d'étiquette."
  :type 'integer
  :group 'hp48)

(defun hp48-print-label ()
  "Imprime le buffer HP48 sur l'imprimante d'étiquettes QL-700.
La version imprimée est dans un buffer temporaire avec :
  - conversion ASCII (trigraphes) → Unicode
  - suppression des commentaires inline (@ non en début de ligne)"
  (interactive)
  (let ((source-buffer (current-buffer)))
    (with-temp-buffer
      ;; Copie du buffer source
      (insert-buffer-substring source-buffer)
      ;; Conversion ASCII → Unicode
      (let ((case-fold-search nil))
        (dolist (pair (reverse hp48-unicode-to-tio))
          (goto-char (point-min))
          (while (search-forward (cdr pair) nil t)
            (replace-match (car pair) t t))))
      ;; Suppression des commentaires non en début de ligne
      (goto-char (point-min))
      (while (not (eobp))
        (unless (looking-at "\\s-*@") ; "Vraie" ligne de commentaire 
          (when (re-search-forward "\\s-*@.*" (line-end-position) t)
            (replace-match "" t t)))
        (forward-line 1))
      ;; Impression
      (let* ((lines (count-lines (point-min) (point-max)))
             (line-height-mm hp48-label-line-height-mm)
             (margin-mm 10)
             (height-mm (round (+ (* lines line-height-mm) margin-mm)))
             (page-size (format "Custom.%dx%dmm" hp48-label-width-mm height-mm)))
        (let ((lpr-switches (list "-P" hp48-printer-name
				 "-o" "print-quality=5"
				 "-o" (concat "PageSize=" page-size))))
          (lpr-buffer))
	(message "Impression sur %s de %d lignes. En cas de souci, changez la valeur de hp48-label-line-height-mm"
		 hp48-printer-name lines)))))

;; les raccourcis clavier
(defvar-keymap hp48-mode-map
  "C-c C-c" #'hp48-add-stack-comments
  "C-c C-u" #'hp48-toggle-unicode
  "C-c C-s" #'hp48-send
  "C-c C-p" #'hp48-print-label
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
  ;; Indicateur visuel à 23 colonnes
  (setq-local fill-column 23)
  ;; L'indicateur de colonne n'est actif qu'en mode unicode (ligne droite pertinente).
  ;; En mode ASCII, le matcher font-lock hp48--overflow-matcher gère
  ;; la limite par ligne en tenant compte des trigraphes.
  (add-hook 'completion-at-point-functions #'hp48-completion-at-point nil t)
  (add-hook 'hp48-mode-hook #'indent-bars-mode)
  (add-hook 'hp48-mode-hook
          (lambda ()
	    (setq-local indent-tabs-mode nil)
            (setq-local indent-bars-spacing-override 2)))
  )

(add-to-list 'auto-mode-alist '("\\.hp48$" . hp48-mode))
(provide 'hp48-mode)
