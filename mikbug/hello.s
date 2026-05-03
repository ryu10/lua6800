* HELLO.S for MIKBUG on CHICK-BUG
*
* NOTE: VAR = $8800, START = $81D0
*       RTI PCH = $8848, PCL = $8849
*
pdata1  equ   $817E 
*
   org    $1000
   ldx    #htext
   jsr    pdata1
   swi
   end
*
htext   fcc "HELLO WORLD"
  fcb 4
*
