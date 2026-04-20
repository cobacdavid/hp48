#lang racket

(require "stack-op.rkt")

(define (tuples n)
  (if (= n 0) '(())
      (apply append
             (map (lambda (x)
                    (map (lambda (rest)
                           (cons x rest))
                         (tuples (- n 1))))
                  *alphabet*))))
(define fso
  (lambda (lst)
    (let ([res (find-stack-operations *pile-depart* lst #:50g #t)])
      (cons lst res))))

;;;;;;
(define *alphabet* '(A B C))
(define *pile-depart* '(A B C))
(define *a-atteindre* (tuples 3))

(let loop ([cpl (map fso *a-atteindre*)])
  (when (not (null? cpl))
    (let* ([soluce (car cpl)]
           [to (car soluce)]
           [rpl (cdr soluce)])
      (displayln (string-append "| (" (string-join (map symbol->string to) " ") ") | "
                                (if rpl rpl "X")
                                " |"))
      (loop (cdr cpl)))))
;;;;;;
(find-stack-operations '(A B C O) '(C O B A C) #:50g #t)
;; "swap 4-roll 4-pick"
;;;;;;
(stack-after-op '(A B C D) '(nip drop))
;; '(C D)
;;;;;;
(optimize '(swap over swap))
;; dup rot est une meilleure solution que swap over swap
(optimize '(drop drop dup nip dup) #:50g #t)
;; drop2 dup est une meilleure solution que drop drop dup nip dup
