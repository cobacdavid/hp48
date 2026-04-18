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
;;
;;
(define *rpl-operations* (make-hash))

(define-syntax (defrpl stx)
  (match (syntax->list stx)
      [(list _ name expr)
         (let* ([keyname (syntax->datum name)]
                [fn-string-name (string-append "rpl-" (symbol->string keyname))]
                [fn-name (string->symbol (string-upcase fn-string-name))])
           (datum->syntax stx
                          `(begin
                             (define (,fn-name lst)
                               (begin ,expr))
                             (hash-set! *rpl-operations* ',keyname ,fn-name))))]))

;;
;; Pile HP48
;;
;; SOMMET DE PILE À GAUCHE !
;;
;;
;; n au sommet de la pile
(defrpl dupn 
  (let* ([n (first lst)]
         [pile (rest lst)])
    (when (>= (length pile) n)
      (append (take pile n) pile))))

(defrpl dropn
  ;; n au sommet de la pile
  (drop lst (+ (first lst) 1)))

(defrpl roll
  ;; n au sommet de la pile
  (let* ([n (first lst)]
         [n-1 (- n 1)]
         [pile (rest lst)]
         [premiers (take pile n-1)]
         [autres (drop pile n-1)])
    (append (list (first autres)) premiers (rest autres))))

(defrpl rolld
  ;; n au sommet de la pile
  (let* ([n (first lst)]
         [n-1 (- n 1)]
         [pile (rest lst)]
         [premiers (take (cdr pile) n-1)]
         [autres (drop pile n)])
    (append premiers (list (first pile)) autres)))

(defrpl pick
  ;; n au sommet de la pile
  (let ([n (first lst)]
        [pile (rest lst)])
    (list* (first (drop pile (- n 1))) pile))) 
;;
;;
;;
(define (call-rpl fn lst)
  ((hash-ref *rpl-operations* fn) lst))

(define (find-stack-operations from-list to-list [lemax 5])
  (let ([from from-list]
        [to   to-list])
    (let/ec return
      (define (rec lst n [acc '()])
        (cond
          [(equal? lst to)
           (displayln (string-join acc " "))
           (return #t)]
          [(zero? n) (void)]
          [else
           (hash-for-each *rpl-operations*
                          (lambda (name fn)
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
                                                      [else commande])])
                                      (rec new-lst (- n 1) (append acc (list cmd))))))))))]))
      (for ([n (in-range 0 (+ lemax 1))])
        (rec from n))
      (displayln "Prof. max. atteinte sans résultat"))))
