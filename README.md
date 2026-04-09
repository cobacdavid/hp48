# HP-48 mode for GNU/emacs

 - works with `.hp48` suffix files
 - shortcuts:
   - `C-c C-x` launches `x48` (path is set to `/usr/bin/x48` with `hp48-x48-execpath` variable)
   - `C-c C-s` sends to a port (e.g. `/dev/ttyUSB0`, `dev/pts/2` ...) using `kermit` communication. The script used to establish the communication is set according to my HP-48 setup (ASCII etc.).
   - `C-c C-u` toggles from/to unicode from/to ASCII (e.g. `ΣLIST` switches with `\GSLIST`)
   - `C-c C-c` adds a comment colon on each non-comment line to keep trace of stack state (avoid write-only code effect)

# License MIT
Personal work + @XahLee on YT + Claude sonnet
