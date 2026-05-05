* HELLO.S for EDMON02
**
pdata1  equ   $fa13 
*
   org    $0000
   ldx    #htext
   jsr    pdata1
   swi
   end
*
htext   fcc "HELLO WORLD"
  fcb 4
*
