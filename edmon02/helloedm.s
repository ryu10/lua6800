* HELLO.S for EDMON02
**
pdata1  equ   $fb68
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
