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
stack-op.rkt> (find-stack-operations '(A B) '(A B A B A B))
dup2 dup2
stack-op.rkt> (find-stack-operations '(A B C) '(A C A B A C))
swap over 4-pick over
stack-op.rkt> (find-stack-operations '(A B C) '(A C A B A C A A))
#f
stack-op.rkt> (find-stack-operations '(A B C) '(A C A B A C A A) 10)
swap over 4-roll over 4-roll 4-dupn drop
stack-op.rkt> (find-stack-operations '(A B C) '(A C A))
swap drop swap over
stack-op.rkt> (find-stack-operations '(A B C) '(A C A) 3 #t)
unrot drop over
```

### From (A B C) to...

| Dest. | HP-48G | HP-50G |
| --- | --- | --- |
| (A A A) | swap rot drop2 dup dup | unrot drop2 dup dup |
| (A A B) | rot drop dup  | rot over nip |
| (A A C) | swap drop dup | nip dup |
| (A B A) | swap rot drop over | unrot nip over |
| (A B B) | rot drop over swap | rot drop over swap |
| **(A B C)** |   |   |
| (A C A) | swap drop swap over | unrot drop over |
| (A C B) | swap 3-rolld | swap unrot |
| (A C C) | swap drop over swap | nip over swap |
| (B A A) | rot drop dup rot | rot over nip rot |
| (B A B) | rot drop over | rot drop over |
| (B A C) | swap | swap |
| (B B A) | swap rot drop dup | unrot nip dup |
| (B B B) | rot drop2 dup dup | rot drop2 dup dup |
| (B B C) | drop dup | over nip |
| (B C A) | 3-rolld  | unrot |
| (B C B) | drop swap over | rot nip over |
| (B C C) | drop over swap | drop over swap |
| (C A A) | swap drop dup rot  | nip dup rot |
| (C A B) | rot | rot |
| (C A C) | swap drop over  | nip over |
| (C B A) | swap rot  | swap rot |
| (C B B) | drop dup rot  | over nip rot |
| (C B C) | drop over  | drop over |
| (C C A) | swap drop swap dup | unrot over nip |
| (C C B) | drop swap dup  | rot nip dup |
| (C C C) | drop2 dup dup  | drop2 dup dup |


### License CC-0
Personal work + Peter Salvi + Claude sonnet
