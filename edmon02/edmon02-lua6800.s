* EDMON02 - adapted for lua6800
* 2026 RyuStudio
*
* LUA6800 SPEC:
*    - CPU: moon6800 (mod),
*    - ACIA: 8018/19,
*    -RAM: 0000-DFFF ; note the RAM on Eaglet02 (F000-F3FF) is not implemented in LUA6800)
*
* TTY COMMANDS: M, G, L, S, B, C, T, R, V
*
* --- ACIA ---
aciacs      equ     $8018
aciada      equ     $8019
var         equ     $f380               ; the last 128 bytes of RAM are reserved for variables and stack
rom         equ     $f800
*
*   EDMON nmi trigger addresses
ennmitmr    equ     $8000               ; Lua6800-only: NMI ENABLE TIMER (step/breakpoint)
disnmitmr   equ     $8001               ; Lua6800-only: NMI DISABLE TIMER
uimds       equ     $00                 ; monitor UI: serial
uimdc       equ     $01                 ; monitor UI: console
*
            org     var
IOV         rmb     2                   ; IRQ VECTOR (placeholder)
BEGA        rmb     2                   ; BEGIN ADDRESS
ENDA        rmb     2                   ; END ADDRESS
SP          rmb     2                   ; USER STACK POINTER SAVE (SWI)
UFLAG       rmb     1                   ; USER CONTEXT VALID FLAG
TEMP1       rmb     2                   ; TEMP SCRATCH
DISBUF      rmb     8                   ; 7SEG DISPLAY BUFFER
DIGIN4      rmb     1                   ; 4-DIGIT ENTERED FLAG
DIGIN8      rmb     1                   ; 8-DIGIT ENTERED FLAG
MFLAG       rmb     1                   ; MEMORY CHANGE MODE FLAG
RFLAG       rmb     1                   ; REGISTER DISPLAY MODE FLAG
NFLAG       rmb     1                   ; TRACE MODE FLAG
PRINTER     rmb     2                   ; PRINTER ROUTINE ADDRESS
SCREEN      rmb     2                   ; VIDEO DISPLAY ROUTINE ADDRESS
ECHOFL      rmb     1                   ; ECHO DISABLED FLAG
TEMP2       rmb     1                   ; CTR IN REG DISPLAY, AUDIO
XKEYBF      rmb     2                   ; NEXT LOC IN DISPLAY BUFFER
SCNCNT      rmb     1                   ; KEYBD/DISP SCAN COUNTER
UIMODE      rmb     1                   ; monitor UI mode selector
VFLAG       rmb     1                   ; COUNT ACTIVE BREAKPOINTS
BPADR       rmb     2                   ; TEMP ADDR BP & XREG TEMP
XDSBUF      rmb     2                   ; XREG TEMP LOCATION
TW          rmb     2                   ; TEMP LOCATION
TEMP        equ     *
CKSM        rmb     1                   ; CHECKSUM FOR TAPE R/W
BYTECT      rmb     1                   ; BYTE COUNT FOR TAPE R/W
TEMP3       equ     *
BITCT       rmb     1                   ; BIT COUNT FOR TAPE R/W
SPWORK      rmb     1                   ; SER/PARL WORK
TAPEWK      rmb     1                   ; TAPE WORK
INPSR       rmb     2                   ; INPUT ROUTINE ADDR
OUTSR       rmb     2                   ; OUTPUT ROUTINE ADDR
TYPFLG      rmb     1                   ; TYPUTER MODE FLAG
BAUD        rmb     1                   ; BAUD RATE DEF.REGISTER
BPTAB       rmb     15                  ; BREAKPOINT TABLE (XHI, XL, OPCODE)
XHI         rmb     1                   ; XREG HIGH
XLOW        rmb     1                   ; XREG LOW
XTEMP       rmb     2                   ; X-REG SAVE (used by inch)
            org     var+$60
STACK       rmb     1                   ; STACK TOP
*
            org     rom
* ENTRY POINT - ACIA INIT
start       lds     #STACK
            clr     UFLAG
            clr     VFLAG
            clr     NFLAG
            clr     UIMODE              ; startup stays on serial monitor UI
            ldx     #io
            stx     IOV                 ; Set IRQ vector
            ldaa    #$03                ; RESET ACIA
            staa    aciacs
            nop
            nop
            nop
            ldaa    #$15                ; 8N1, NO INTERRUPT
            staa    aciacs
*
* TTY COMMAND Control
control     equ     *
            ldx     #MCL
            jsr     pdata1
            jsr     inch
            tab
            jsr     outs                ; print space
            cmpb    #'M
            bne     ctlj
            jmp     change
ctlj        cmpb    #'J
            bne     ctlg
            jmp     jump
ctlg        cmpb    #'G
            bne     ctll
            jmp     go
ctll        cmpb    #'L
            bne     ctls
            jmp     load
ctls        cmpb    #'S'
            bne     ctlb
            jmp     save
ctlb        cmpb    #'B'
            bne     ctlc
            jmp     breakp
ctlc        cmpb    #'C'
            bne     ctlt
            jmp     breakc
ctlt        cmpb    #'T'
            bne     ctlr
            jmp     trace
ctlr        cmpb    #'R'
            bne     ctlv
            jmp     regs
ctlv        cmpb    #'Y'
            bne     control
            jmp     srec
*
change      jsr     baddr
change0     jsr     cr
ch0         ldx     #XHI
            jsr     out4hs              ; print address
            ldx     XHI
            jsr     out2hs              ; print data
ch0a        jsr     inch                ; get subcmd
            cmpa    #$20                ; space?
            bne     chn
            jsr     byte                ; now get a byte and write it
            ldx     XHI
            staa    0,X
            cmpa    0,X
            beq     ch0end
            ldaa    #'?
            jsr     outch
ch0end      inx
            stx     XHI
            bra     change0
chn         cmpa    #$7f                ; del?
            bne     change1
            ldx     XHI
            dex
            stx     XHI
            bra     change0
change1     cmpa    #'/                 ; next addr?
            bne     change2
            ldx     XHI
            inx
            stx     XHI
            bra     change0
change2     cmpa    #'.                 ; new addr?
            bne     change3
            bra     change
change3     cmpa    #$0d                ; cr?
            beq     chend
change4     bra     change0             ; no valid command, try again
chend       jmp     control
*
go          tst     UFLAG
            beq     cmdbad
            jsr     getxb
            beq     resume
            jmp     trace1
*
jump        jsr     baddr
            jsr     mkframe
            jsr     getxb
            beq     resume
            jmp     instbp
*
load        ldx     #loadm
            jsr     pdata1
            jmp     control
loadm       fcb     'L, 'C, $04
*
save        ldx     #savem
            jsr     pdata1
            jmp     control
savem       fcb     'S, 'C, $04
*
breakp      jsr     baddr
            stx     BPADR
            jsr     setbr
            bcs     cmdbad
            jmp     control
            bra     cmdbad
breakpm     fcb     'B, 'C, $04
*
breakc      clr     VFLAG
            jmp     control
breakcm     fcb     'C, 'C, $04
*
trace       tst     UFLAG
            beq     cmdbad
            clr     VFLAG
trace1      inc     NFLAG
            jmp     trresume
*
trresume    lds     SP
            ldaa    #$01
            staa    ennmitmr           ; start 12us single-shot trace timer
            rti
*
resume      lds     SP
            rti
*
cmdbad      ldaa    #'?
            jsr     outch
            jmp     control
tracem      fcb     'T, 'C, $04
*
regs        ldaa    UIMODE
            cmpa    #uimdc
            beq     regscon
regsser     ldx     SP
            inx                         ; saved SWI/NMI frame starts at SP+1
            stx     TEMP1
            ldaa    0,x
            staa    XHI
            ldx     #XHI
            jsr     out2hs              ; CONDITION CODES
            ldx     TEMP1
            ldaa    1,x
            staa    XHI
            ldx     #XHI
            jsr     out2hs              ; ACC-B
            ldx     TEMP1
            ldaa    2,x
            staa    XHI
            ldx     #XHI
            jsr     out2hs              ; ACC-A
            ldx     TEMP1
            ldaa    3,x
            staa    XHI
            ldaa    4,x
            staa    XLOW
            ldx     #XHI
            jsr     out4hs              ; X-REG
            ldx     TEMP1
            ldaa    5,x
            staa    XHI
            ldaa    6,x
            staa    XLOW
            ldx     #XHI
            jsr     out4hs              ; P-COUNTER
            ldx     #SP
            jsr     out4hs              ; STACK POINTER
            jmp     control
regscon     ldx     #regscmsg
            jsr     pdata1
            jmp     regsser
regscmsg    fcb     $0d, $0a, 'C, 'O, 'N, 'S, 'O, 'L, 'E, ' , 'S, 'T, 'U, 'B, $0d, $0a, $04
*
srec        ldaa    #$0d
            jsr     outch
            nop
            ldaa    #$0A
            jsr     outch
*
*    CHECK TYPE
LOAD3       jsr     inch
            cmpa    #'S
            bne     LOAD3               ; 1ST CHAR NOT (S)
            jsr     inch                ; READ CHAR
            cmpa    #'9
            beq     LOAD21              ; START ADDRESS
            cmpa    #'1
            bne     LOAD3               ; 2ND CHAR NOT (1)
            clr     CKSM                ; ZERO CHECKSUM
            jsr     byte                ; READ BYTE
            suba    #2
            staa    BYTECT              ; BYTE COUNT
*
*    BUILD ADDRESS
            jsr     baddr
*
*    STORE DATA
LOAD11      jsr     byte
            dec     BYTECT
            beq     LOAD15              ; ZERO BYTE COUNT
            staa    0,X                 ; STORE DATA
            inx
            bra     LOAD11
*
*    ZERO BYTE COUNT
LOAD15      inc     CKSM
            beq     LOAD3
LOAD19      ldaa    #'?                 ; PRINT QUESTION MARK
            jsr     outch
LOAD21      equ     *
C1          jmp     control
*
*    BUILD ADDRESS
baddr       bsr     byte                ; READ 2 FRAMES
            staa    XHI
            bsr     byte
            staa    XLOW
            ldx     XHI                 ; (X) ADDRESS WE BUILT
            rts
*
MCL         fcb     $0d, $0a, '$, $04 ; CMD PROMPT
*
*
*    INPUT HEX CHAR
inhex       jsr     inch
inhex1      suba    #$30
            bmi     ihe                 ; NOT HEX
            cmpa    #$09
            ble     IN1HG
            cmpa    #$11
            bmi     ihe                 ; NOT HEX
            cmpa    #$16
            bgt     ihe                 ; NOT HEX
            suba    #7
IN1HG       clc
            rts
ihe         sec
            rts
*
*    INPUT BYTE (TWO FRAMES)
byte        bsr     inhex               ; GET HEX CHAR
bytem       bcc     byten
            bsr     bs
            bra     byte
byten       asla
            asla
            asla
            asla
            tab
byte1       bsr     inhex
            bcc     byte2
            bsr     bs
            bra     byte1
byte2       aba
            tab
            addb    CKSM
            stab    CKSM
            rts
*
*     print newline
cr          ldaa    #$0d
            jsr     outch
            ldaa    #$0a
            jsr     outch
            rts
*
*    backspace
bs          ldaa    #$08
            jsr     outch
            rts
*
*    INPUT FIRST HEX BYTE WITH FIRST NIBBLE ALREADY IN A
byte0       bsr     inhex0
            bcc     byte00
            jmp     cmdbad
byte00      equ     *
            asla
            asla
            asla
            asla
            tab
byte01      bsr     inhex
            bcc     byte02
            bsr     bs
            bra     byte01
byte02      aba
            tab
            addb    CKSM
            stab    CKSM
            rts
*
inhex0      suba    #$30
            bmi     ihe0
            cmpa    #$09
            ble     in1h0
            cmpa    #$11
            bmi     ihe0
            cmpa    #$16
            bgt     ihe0
            suba    #7
in1h0       clc
            rts
ihe0        sec
            rts
*
*    READ NEXT NON-SPACE CHAR
skipsp      jsr     inch
            cmpa    #$20
            beq     skipsp
            rts
*
*    BUILD INITIAL USER RTI FRAME AT STACK TOP
mkframe     ldx     #STACK-7
            stx     SP
            ldaa    #$00
            staa    1,x                 ; CCR
            staa    2,x                 ; B
            staa    3,x                 ; A
            staa    4,x                 ; XHI
            staa    5,x                 ; XLOW
            ldaa    XHI
            staa    6,x                 ; PCH
            ldaa    XLOW
            staa    7,x                 ; PCL
            inc     UFLAG
            rts
*
*    GET BREAKPOINT TABLE BASE IN X, COUNT IN B
getxb       ldx     #BPTAB
            ldab    VFLAG
            rts
*
*    ADVANCE TO NEXT BREAKPOINT ENTRY
add3x       inx
            inx
            inx
            decb
            rts
*
*    INSERT BREAKPOINT ENTRY AT BPADR
setbr       ldaa    BPADR
            cmpa    #$e0                ; only user RAM is breakpointable in lua6800
            bhs     setbre
            bsr     getxb
            beq     setbr0
            cmpb    #$05
            bge     setbre
setbr1      bsr     add3x
            bne     setbr1
setbr0      inc     VFLAG
            ldaa    BPADR
            staa    0,x
            ldaa    BPADR+1
            staa    1,x
            clc
            rts
setbre      sec
            rts
*
*    INSTALL ALL ACTIVE BREAKPOINTS THEN RESUME USER
instbp      stx     BPADR
            ldx     0,x
            ldaa    0,x
            psha
            ldaa    #$3f                ; SWI breakpoint opcode
            staa    0,x
            ldx     BPADR
            pula
            staa    2,x                 ; save replaced opcode
            bsr     add3x
            bne     instbp
            jmp     resume
*
*    RESTORE ACTIVE BREAKPOINTS AFTER SWI STOP
rmvbp       bsr     getxb
            beq     regsret
rmvbp1      stx     BPADR
            ldaa    2,x
            cmpa    #$3f                ; skip duplicate breakpoint entries
            beq     rmvbp2
            ldx     0,x
            staa    0,x
            ldx     BPADR
rmvbp2      bsr     add3x
            bne     rmvbp1
regsret     jmp     regs
*
* --- I/O ROUTINES (ACIA-based) ---
*
*    SAVE X REGISTER
savx        stx     XTEMP
            rts
*
*    OUTPUT ONE CHAR (A-reg)
outch       psha
outch1      ldaa    aciacs
            asra
            asra
            bcc     outch1
            pula
            staa    aciada
            rts
*
*    INPUT ONE CHAR -> A-reg (echoed)
inch        bsr     savx
inch1       ldaa    aciacs
            asra
            bcc     inch1
            ldaa    aciada
            anda    #$7f
            cmpa    #$7f
            beq     inch1
            bsr     outch
            ldx     XTEMP
            rts
*
*    OUT HEX HIGH NIBBLE OF A
outhl       lsra
            lsra
            lsra
            lsra
*    OUT HEX LOW NIBBLE OF A
outhr       anda    #$0f
            adda    #$30
            cmpa    #$39
            bls     outch
            adda    #$07
            bra     outch
*
*    OUTPUT 2 HEX CHARS FOR BYTE AT X, ADVANCE X
out2h       ldaa    0,x
out2ha      bsr     outhl
            ldaa    0,x
            inx
            bra     outhr
*
*    OUTPUT 4 HEX CHARS + SPACE (2 BYTES AT X)
out4hs      bsr     out2h
*    OUTPUT 2 HEX CHARS + SPACE (1 BYTE AT X)
out2hs      bsr     out2h
*    OUTPUT SPACE
outs        ldaa    #$20
            bra     outch
*
*    PRINT STRING AT X (EOT=$04 terminated)
pdata1      ldaa    0,x
            cmpa    #$04
            beq     pdata_e
            bsr     outch
            inx
            bra     pdata1
pdata_e     rts
*
*    SWI HANDLER - save user context, return to monitor
sfe         sts     SP
            inc     UFLAG
            tsx                         ; decrement prog ctr
            tst     6,x
            bne     *+4
            dec     5,x
            dec     6,x
            jsr     getxb
            bne     sfebp
            jmp     regsret
sfebp       equ     *
            jmp     rmvbp
*
*   Default NMI handler
*       edmon step/bp handler
nonmsk      ldaa    #$01                ; frst, reset lua6800 nmi timer
            staa    disnmitmr           ; then jump to edmon nmi handler
            sts     SP
            inc     UFLAG
            tst     NFLAG               ; trace/proceed restart path?
            bne     nmschk
            jmp     regsret
nmschk      equ     *
            clr     NFLAG
            jsr     getxb
            bne     nmsbp
            jmp     regsret
nmsbp       equ     *
            jmp     instbp
*
*   Default IRQ handler (stab - impl. later)
io          rti
*
*   IRQ jumber
irqv        ldx     IOV
            jmp     0,x
*
*   SYSTEM VECTORS
            org     $fff8
            fdb     irqv                ; IRQ
            org     $fffa
            fdb     sfe                 ; SWI
            org     $fffc
            fdb     nonmsk              ; NMI
            org     $fffe
            fdb     start               ; RESET
*
* end
            end