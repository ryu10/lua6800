* HELLO.S for MIKBUG-acia
*
* NOTE: VAR = $1F00, START = $E0D0
*       RTI PCH = $1F48, PCL = $1F49
*
pdata1  equ   $E07E 
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
