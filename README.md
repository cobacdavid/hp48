# 
## HP-48 mode for GNU/emacs

 - works with `.hp48` suffix files
 - shortcuts:
   - `C-c C-x` launches `x48` (path is set to `/usr/bin/x48` with `hp48-x48-execpath` variable)
   - `C-c C-s` sends to a port (e.g. `/dev/ttyUSB0`, `dev/pts/2` ...) using `kermit` communication. The script used to establish the communication is set according to my HP-48 setup (ASCII etc.).
   - `C-c C-u` toggles from/to unicode from/to ASCII (e.g. `ΣLIST` switches with `\GSLIST`)
   - `C-c C-c` adds a comment colon on each non-comment line to keep trace of stack state (avoid write-only code effect)

### License MIT
Personal work + @XahLee on YT + Claude sonnet

## Find Stack Operations 
This script is a Racket adaptation for HP-48 of [P. Salvi's common-lisp work](https://salvi.chaosnet.org/snippets/forth-stack.html) for Forth language.

This racket script finds shortest sequence of stack operations from a stack state to another given a maximum search-depth (default is 5).
TOS (Top Of Stack ) is on the left.

`find-stack-operations` admits two optional arguments, fisrt is max depth, second is a boolean to include HP-50G stack ops (currently only `nip` and `unrot`).

```lisp
stack-op-48.rkt> (find-stack-operations '(A B) '(A B A B A B))
dup2 dup2
#t
stack-op-48.rkt> (find-stack-operations '(A B C) '(A C A B A C))
swap over 4-pick over
#t
stack-op-48.rkt>  (find-stack-operations '(A B C) '(A C A B A C A A))
Prof. max. atteinte sans résultat
stack-op-48.rkt> (find-stack-operations '(A B C) '(A C A B A C A A) 8)
swap over 4-roll over 4-roll 4-dupn drop
#t
stack-op.rkt> (find-stack-operations '(A B C) '(A C A))
3-rolld drop over
#t
stack-op.rkt> (find-stack-operations '(A B C) '(A C A) 3 #t)
unrot 3-pick nip
#t
```
### License CC-0
Personal work + Peter Salvi + Claude sonnet
