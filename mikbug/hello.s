* HELLO.S for MIKBUG
**
pdata1  equ   $f87e
*
   org    $1000
   ldx    #htext
   jsr    pdata1
   swi
   end
*
htext   fcc "HELLO WORLD"
  fcb $0d, $0a, $04
*
