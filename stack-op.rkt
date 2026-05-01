#lang racket
;; auteur : David Cobac
;; date : avril 2026
;;
;; adaptation de https://salvi.chaosnet.org/snippets/forth-stack.html
;; de Peter Salvi
;;
;; AIA
;;

(require (for-syntax racket/match))
(require racket/hash)

(provide find-stack-operations stack-after-op optimize)
;;
;;
(define *rpl-operations-48* (make-hash))
(define *rpl-operations-l48* (make-hash))
(define *rpl-operations-50* (make-hash))

(define-syntax (defrpl stx)
  (match (syntax->list stx)
    [(list _ name mod type expr)
     (let* ([keyname (syntax->datum name)]
            [fn-string-name (string-append "rpl-" (symbol->string keyname))]
            [fn-name (string->symbol (string-upcase fn-string-name))]
            [modele (syntax->datum mod)]
            [dico (string->symbol (string-append "*rpl-operations-"
                                                 (if (number? modele)
                                                     (number->string modele)
                                                     (symbol->string modele))
                                                 "*"))]
            [typearg (syntax->datum type)])
       (datum->syntax stx
                      (if (number? typearg)
                          `(begin
                             (define (,fn-name lst)
                               (if (>= (length lst) ,typearg)
                                   (begin ,expr)
                                   #f))
                             (hash-set! ,dico ',keyname ,fn-name))
                          `(begin
                             (define (,fn-name lst)
                               (begin ,expr))
                             (hash-set! ,dico ',keyname ,fn-name)))))]))

;;
;; Pile HP48
;;
;; SOMMET DE PILE À GAUCHE !
;;
;;
;; n au sommet de la pile
(defrpl dupn 48 n
  (let* ([n (first lst)]
         [pile (rest lst)])
    (append (take pile n) pile)))

(defrpl dropn 48 n
  (drop lst (+ (first lst) 1)))

(defrpl roll 48 n
  (let* ([n (first lst)]
         [n-1 (- n 1)]
         [pile (rest lst)]
         [premiers (take pile n-1)]
         [autres (drop pile n-1)])
    (append (list (first autres)) premiers (rest autres))))

(defrpl rolld 48 n
  (let* ([n (first lst)]
         [n-1 (- n 1)]
         [pile (rest lst)]
         [premiers (take (cdr pile) n-1)]
         [autres (drop pile n)])
    (append premiers (list (first pile)) autres)))

(defrpl pick 48 n
  (let ([n (first lst)]
        [pile (rest lst)])
    (list* (first (drop pile (- n 1))) pile)))

;; legacy 48 
(defrpl drop l48 1
  (drop lst 1))

(defrpl drop2 l48 2
  (drop lst 2))

(defrpl dup l48 1
  (list* (first lst) lst))

(defrpl dup2 l48 2
  (list* (first lst) (second lst) lst))

(defrpl over l48 2
  (list* (second lst) lst))

(defrpl rot l48 3
  (list* (third lst) (first lst) (second lst) (drop lst 3)))

(defrpl swap l48 2
  (list* (second lst) (first lst) (drop lst 2)))

(defrpl 1-dropn l48 1
  (drop lst 1))
(defrpl 2-dropn l48 2
  (drop lst 2))
(defrpl 3-dropn l48 3
  (drop lst 3))
(defrpl 4-dropn l48 4
  (drop lst 4))

(defrpl 1-dupn l48 1
  (list* (first lst) lst))
(defrpl 2-dupn l48 2
  (list* (first lst) (second lst) lst))
(defrpl 3-dupn l48 3
  (append (take lst 3) lst))
(defrpl 4-dupn l48 4
  (append (take lst 4) lst))


(defrpl 1-pick l48 1
  (list* (first lst) lst))
(defrpl 2-pick l48 2
  (list* (second lst) lst))
(defrpl 3-pick l48 3
  (list* (third lst) lst))
(defrpl 4-pick l48 4
  (list* (fourth lst) lst))

(defrpl 1-roll l48 1
  lst)
(defrpl 2-roll l48 2
  (list* (second lst) (first lst) (drop lst 2)))
(defrpl 3-roll l48 3
  (list* (third lst) (first lst) (second lst) (drop lst 3)))
(defrpl 4-roll l48 4
  (list* (fourth lst) (first lst) (second lst) (third lst) (drop lst 4)))

(defrpl 1-rolld l48 1
  lst)
(defrpl 2-rolld l48 2
  (list* (second lst) (first lst) (drop lst 2)))
(defrpl 3-rolld l48 3
  (list* (second lst) (third lst)  (first lst) (drop lst 3)))
(defrpl 4-rolld l48 3
  (list* (second lst) (third lst) (fourth lst) (first lst) (drop lst 4)))


;; 50G

(defrpl nip 50 2
  (list* (first lst) (drop lst 2)))

(defrpl unrot 50 3
  (list* (second lst) (third lst) (first lst) (drop lst 3)))

(defrpl dupdup 50 1
  (list* (first lst) (first lst) lst))

(defrpl unpick 50 n
  (let* ([n (first lst)]
         [pile (rest lst)]
         [debut (take pile n)]
         [fin (drop pile (+ n 1))])
    (append (rest debut) (list (first pile)) fin)))

;; difficilement utilisable sans tout casser...
;; (defrpl ndupn 50 n
;;   (let ([n (first lst)])
;;     (append (list n) (make-list n (second lst)) lst)))


(define (elements-still-in-to-list? current-stack to)
  (andmap (lambda (elem) (member elem current-stack)) to))
;;
;;
(define (find-stack-operations from-list to-list #:pmax [pmax 5] #:50g [50g #f])
  (let* ([from from-list]
         [to to-list]
         [maxk (max (length from) (length to))]
         [im48g (make-immutable-hash (hash->list *rpl-operations-48*))]
         [im50g (make-immutable-hash (hash->list *rpl-operations-50*))]
         [rpl-operations (if 50g (hash-union im48g im50g)
                             *rpl-operations-48*)]
         [set-to-list (remove-duplicates to-list)])
    ; 
    (let/ec return
      (define (rec lst n [acc '()])
        (cond [(and (equal? lst to) (>= n 0))
               (return (string-join (reverse acc) " "))]
              [(< n 0) (void)]
              [(not (elements-still-in-to-list? lst set-to-list)) (void)]
              [else
               (hash-for-each rpl-operations
                              (lambda (name fn)
                                (if (hash-has-key? *rpl-operations-48* name)
                                    (for ([k (in-range 1 (+ 1 maxk))])
                                      (when (>= (length lst) k)
                                        (let ([new-lst (fn (list* k lst))])
                                          (when new-lst
                                            (let* ([commande (string-append (number->string k) "-" (symbol->string name))]
                                                   [cmd (cond [(string=? commande "1-dupn") "dup"]
                                                              [(string=? commande "2-dupn") "dup2"]
                                                              [(string=? commande "1-dropn") "drop"]
                                                              [(string=? commande "2-dropn") "drop2"]
                                                              [(string=? commande "1-pick") "dup"]
                                                              [(string=? commande "2-pick") "over"]
                                                              [(string=? commande "2-roll") "swap"]
                                                              [(string=? commande "3-roll") "rot"]
                                                              [(string=? commande "2-rolld") "swap"]
                                                              [(and 50g (string=? commande "3-rolld")) "unrot"]
                                                              [else commande])])
                                              (if (member cmd '("drop" "drop2" "dup" "dup2" "over" "rot" "swap"))
                                                  (rec new-lst (- n 1) (cons cmd acc))
                                                  (rec new-lst (- n 2) (cons cmd acc)))
                                              )))))
                                    (if (member name '(unpick))
                                        (for ([k (in-range 1 (+ 1 maxk))])
                                          (when (>= (length lst) (+ k 1))
                                            (let ([new-lst (fn (list* k lst))])
                                              (when new-lst
                                                (let ([commande (string-append (number->string k) "-" (symbol->string name))])
                                                  (rec new-lst (- n 2) (append acc (list commande))))))))
                                        (let ([new-lst (fn lst)])
                                          (when new-lst
                                            (rec new-lst (- n 1) (append acc (list (symbol->string name))))))))))]))
      (for ([n (in-range 0 (+ pmax 1))])
        (rec from n))
      #f)))

(define (stack-after-op from-list op-list)
  (let* ([im48g  (make-immutable-hash (hash->list *rpl-operations-48*))]
         [iml48g (make-immutable-hash (hash->list *rpl-operations-l48*))]
         [im50g  (make-immutable-hash (hash->list *rpl-operations-50*))]
         [rpl-operations (hash-union im48g iml48g im50g)])
    (foldl (lambda (f acc) ((hash-ref rpl-operations f) acc)) from-list op-list)))

(define (optimize op-list #:depth [depth 5] #:50g [50g #f])
  (let* ([from-list (build-list depth (lambda (i)
                                        (string->symbol
                                         (string (integer->char (+ (char->integer #\A) i))))))]
         [nv-st (stack-after-op from-list op-list)]
         [soluce-string (find-stack-operations from-list nv-st #:50g 50g)]
         [from-string (string-join (map symbol->string from-list) " ")]
         [op-list-string (string-join (map symbol->string op-list) " ")])
    (cond [(string=? soluce-string op-list-string) (displayln (string-append op-list-string " est excellent."))]
          [(= (length (regexp-split #px"[ -]" soluce-string))
              (length (regexp-split #px"[ -]" op-list-string)))
            (displayln (string-append op-list-string " est déjà parfait. Autre possibilité : " soluce-string))]
          [else (displayln (string-append soluce-string " est une meilleure solution que " op-list-string))])))

