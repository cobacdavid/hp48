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

`find-stack-operations` admits two optional arguments, fisrt is `pmax` depth, second is `50g` a boolean to include HP-50G stack ops (currently only `dupdup`, `nip`, `unpick` et `unrot`).

```lisp
stack-op.rkt> (find-stack-operations '(A B) '(A B A B A B))
dup2 dup2
stack-op.rkt> (find-stack-operations '(A B C) '(A C A B A C))
swap over 4-pick over
stack-op.rkt> (find-stack-operations '(A B C) '(A C A B A C A A))
#f
stack-op.rkt> (find-stack-operations '(A B C) '(A C A B A C A A) #:pmax 10)
swap over 4-roll over 4-roll 4-dupn drop
stack-op.rkt> (find-stack-operations '(A B C) '(A C A))
swap drop swap over
stack-op.rkt> (find-stack-operations '(A B C) '(A C A) #:50g #t)
unrot drop over
```

### From (A B C) to...

| Dest. | HP-48G | HP-50G | Gain |
| --- | --- | --- | --- |
| (A A A) | swap rot drop2 dup dup | unrot drop2 dupdup | 40.0% |
| (A A B) | rot drop dup | rot over nip | 0.0% |
| (A A C) | swap drop dup | nip dup | 33.3% |
| (A B A) | swap rot drop over | dup 3-unpick | 25.0% |
| (A B B) | rot drop over swap | over 3-unpick | 25.0% |
| (A B C) |  |  |  |
| (A C A) | swap drop swap over | unrot drop over | 25.0% |
| (A C B) | swap 3-rolld | swap unrot | 33.3% |
| (A C C) | swap drop over swap | nip over swap | 25.0% |
| (B A A) | rot drop dup rot | swap over 3-unpick | 0.0% |
| (B A B) | rot drop over | rot drop over | 0.0% |
| (B A C) | swap | swap | 0.0% |
| (B B A) | swap rot drop dup | 2-unpick dup | 25.0% |
| (B B B) | rot drop2 dup dup | rot drop2 dupdup | 25.0% |
| (B B C) | drop dup | over nip | 0.0% |
| (B C A) | 3-rolld | unrot | 50.0% |
| (B C B) | drop swap over | rot nip over | 0.0% |
| (B C C) | drop over swap | drop over swap | 0.0% |
| (C A A) | swap drop dup rot | nip dup rot | 25.0% |
| (C A B) | rot | rot | 0.0% |
| (C A C) | swap drop over | nip over | 33.3% |
| (C B A) | swap rot | swap rot | 0.0% |
| (C B B) | drop dup rot | over nip rot | 0.0% |
| (C B C) | drop over | drop over | 0.0% |
| (C C A) | swap drop swap dup | unrot over nip | 25.0% |
| (C C B) | drop swap dup | rot nip dup | 0.0% |
| (C C C) | drop2 dup dup | drop2 dupdup | 33.3% |
| **Moyenne** | 3.1 | 2.5 | **16.3%** |


### License CC-0
Personal work + Peter Salvi + Claude sonnet
