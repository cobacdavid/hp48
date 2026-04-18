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
;;
;;
(define *rpl-operations-48* (make-hash))
(define *rpl-operations-50* (make-hash))

(define-syntax (defrpl stx)
  (match (syntax->list stx)
      [(list _ name mod type expr)
         (let* ([keyname (syntax->datum name)]
                [fn-string-name (string-append "rpl-" (symbol->string keyname))]
                [fn-name (string->symbol (string-upcase fn-string-name))]
                [modele (syntax->datum mod)]
                [dico (string->symbol (string-append "*rpl-operations-" (number->string modele) "*"))]
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

(defrpl nip 50 2
  (list* (first lst) (drop lst 2)))

(defrpl unrot 50 3
  (list* (second lst) (third lst) (first lst) (drop lst 3)))

;;
;;
(displayln *rpl-operations-50*)
;;
(define (call-rpl fn lst)
  ((hash-ref *rpl-operations-48* fn) lst))

(define (find-stack-operations from-list to-list [pmax 5] [50g #f])
  (let* ([from from-list]
         [to to-list]
         [im48g (make-immutable-hash (hash->list *rpl-operations-48*))]
         [im50g (make-immutable-hash (hash->list *rpl-operations-50*))]
         [rpl-operations (if 50g (hash-union im48g im50g)
                             *rpl-operations-48*)])
    (let/ec return
      (define (rec lst n [acc '()])
        (cond [(equal? lst to)
               (displayln (string-join acc " "))
               (return #t)]
              [(zero? n) (void)]
              [else
               (hash-for-each rpl-operations
                              (lambda (name fn)
                                (if (hash-has-key? *rpl-operations-48* name)
                                    (for ([k (in-range 1 5)])
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
                                              (rec new-lst (- n 1) (append acc (list cmd))))))))
                                    (let ([new-lst (fn lst)])
                                          (when new-lst
                                            (rec new-lst (- n 1) (append acc (list (symbol->string name)))))))))]))
      (for ([n (in-range 0 (+ pmax 1))])
        (rec from n))
      (displayln "Prof. max. atteinte sans résultat"))))
