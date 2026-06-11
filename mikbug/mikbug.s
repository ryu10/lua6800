            nam     MIKBUG
*	REV 009
*	COPYRIGHT 1974 BY MOTOROLA INC
*
*	MIKBUG (TM)
*
*	L  LOAD
*	G  GO TO TARGET PROGRAM
*	M  MEMORY CHANGE
*	P  PRINT/PUNCH DUMP
*	R  DISPLAY CONTENTS OF TARGET STACK
*		CC   B   A   X   P   S
*
*	ADDRESS
ACIACS      equ     $8018
ACIADA      equ     $8019
VAR         equ     $F380
disnmitmr   equ     $8001               ; Lua6800-only: NMI DISABLE TIMER

*
*	OPT	MEMORY
            org     $F800
*
*	I/O INTERRUPT SEQUENCE
IO          ldx     IOV
            jmp     0,X
*
*	NMI SEQUENCE
POWDWN      ldx     NIO                 GET NMI VECTOR
            jmp     0,X
*
*	L COMMAND
LOAD        equ     *
            ldaa    #$0D
            bsr     OUTCH
            nop
            ldaa    #$0A
            bsr     OUTCH
*
*	CHECK TYPE
LOAD3       bsr     INCH
            cmpa    #'S
            bne     LOAD3               1ST CHAR NOT (S)
            bsr     INCH                READ CHAR
            cmpa    #'9
            beq     LOAD21              START ADDRESS
            cmpa    #'1
            bne     LOAD3               2ND CHAR NOT (1)
            clr     CKSM                ZERO CHECKSUM
            bsr     BYTE                READ BYTE
            suba    #2
            staa    BYTECT              BYTE COUNT
*
*	BUILD ADDRESS
            bsr     BADDR
*
*	STORE DATA
LOAD11      bsr     BYTE
            dec     BYTECT
            beq     LOAD15              ZERO BYTE COUNT
            staa    0,X                 STORE DATA
            inx
            bra     LOAD11
*
*	ZERO BYTE COUNT
LOAD15      inc     CKSM
            beq     LOAD3
LOAD19      ldaa    #'?                 PRINT QUESTION MARK
            bsr     OUTCH
LOAD21      equ     *
C1          jmp     CONTRL
*
*	BUILD ADDRESS
BADDR       bsr     BYTE                READ 2 FRAMES
            staa    XHI
            bsr     BYTE
            staa    XLOW
            ldx     XHI                 (X) ADDRESS WE BUILT
            rts
*
*	INPUT BYTE (TWO FRAMES)
BYTE        bsr     INHEX               GET HEX CHAR
            asla
            asla
            asla
            asla
            tab
            bsr     INHEX
            aba
            tab
            addb    CKSM
            stab    CKSM
            rts
*
*	OUT HEX BCD DIGIT
OUTHL       lsra                        OUT HEX LEFT BCD DIGIT
            lsra
            lsra
            lsra
OUTHR       anda    #$F                 OUT HEX RIGHT BCD DIGIT
            adda    #$30
            cmpa    #$39
            bls     OUTCH
            adda    #$7
*
*	OUTPUT ONE CHAR
OUTCH       jmp     OUTEEE
INCH        jmp     INEEE
*
*	PRINT DATA POINTED AT BY X-REG
PDATA2      bsr     OUTCH
            inx
PDATA1      ldaa    0,X
            cmpa    #4
            bne     PDATA2
            rts                         STOP ON EOT
*
*	CHANGE MENORY (M AAAA DD NN)
CHANGE      bsr     BADDR               BUILD ADDRESS
CHA51       ldx     #MCL
            bsr     PDATA1              C/R L/F
            ldx     #XHI
            bsr     OUT4HS              PRINT ADDRESS
            ldx     XHI
            bsr     OUT2HS              PRINT DATA (OLD)
            stx     XHI                 SAVE DATA ADDRESS
            bsr     INCH                INPUT ONE CHAR
            cmpa    #$20
            bne     CHA51               NOT SPACE
            bsr     BYTE                INPUT NEW DATA
            dex
            staa    0,X                 CHANGE MEMORY
            cmpa    0,X
            beq     CHA51               DID CHANGE
            bra     LOAD19              NOT CHANGED
*
*	INPUT HEX CHAR
INHEX       bsr     INCH
            suba    #$30
            bmi     C1                  NOT HEX
            cmpa    #$09
            ble     IN1HG
            cmpa    #$11
            bmi     C1                  NOT HEX
            cmpa    #$16
            bgt     C1                  NOT HEX
            suba    #7
IN1HG       rts
*
*	OUTPUT 2 HEX CHAR
OUT2H       ldaa    0,X                 OUTPUT 2 HEX CHAR
OUT2HA      bsr     OUTHL               OUT LEFT HEX CHAR
            ldaa    0,X
            inx
            bra     OUTHR               OUTPUT RIGHT HEX CHAR AND R
*
*	OUTPUT 2-4 HEX CHAR + SPACE
OUT4HS      bsr     OUT2H               OUTPUT 4 HEX CHAR + SPACE
OUT2HS      bsr     OUT2H               OUTPUT 2 HEX CHAR + SPACE
*
*	OUTPUT SPACE
OUTS        ldaa    #$20                SPACE
            bra     OUTCH               (BSR & RTS)
*
*	ENTER POWER  ON SEQUENCE
START       equ     *
            ldaa   #1
            staa   disnmitmr           DISABLE NMI
            lds     #STACK
            sts     SP                  INZ TARGET'S STACK PNTR
*
*	ACIA INITIALIZE
            ldaa    #$03                RESET CODE
            staa    ACIACS
            nop
            nop
            nop
            ldaa    #$15                8N1 NON-INTERRUPT
            staa    ACIACS
*
*	COMMAND CONTROL
CONTRL      lds     #STACK              SET CONTRL STACK POINTER
            ldx     #MCL
            bsr     PDATA1              PRINT DATA STRING
            bsr     INCH                READ CHARACTER
            tab
            bsr     OUTS                PRINT SPACE
            cmpb    #'L
            bne     *+5
            jmp     LOAD
            cmpb    #'M
            beq     CHANGE
            cmpb    #'R
            beq     PRINT               STACK
            cmpb    #'P
            beq     PUNCH               PRINT/PUNCH
            cmpb    #'G
            bne     CONTRL
            lds     SP                  RESTORE PGM'S STACK PTR
            rti                         GO
            fcb     1,1,1,1,1,1,1,1	GRUE
*
*	ENTER FROM SOFTWARE INTERRUPT
SFE         equ     *
            sts     SP                  SAVE TARGET'S STACK POINTER
*
*	DECREMENT P-COUNTER
            tsx
            tst     6,X
            bne     *+4
            dec     5,X
            dec     6,X
*
*	PRINT CONTENTS OF STACK
PRINT       ldx     SP
            inx
            bsr     OUT2HS              CONDITION CODES
            bsr     OUT2HS              ACC-B
            bsr     OUT2HS              ACC-A
            bsr     OUT4HS              X-REG
            bsr     OUT4HS              P-COUNTER
            ldx     #SP
            bsr     OUT4HS              STACK POINTER
C2          bra     CONTRL
*
*	PUNCH DUMP
*	PUNCH FROM BEGINING ADDRESS (BEGA) THRU ENDI
*	ADDRESS (ENDA)
MTAPE1      fcb     $D,$A,'S,'1,$4	PUNCH FORMAT
            fcb     1,1,1,1	GRUE
PUNCH       equ     *
            ldx     BEGA
            stx     TW                  TEMP BEGINING ADDRESS
PUN11       ldaa    ENDA+1
            suba    TW+1
            ldab    ENDA
            sbcb    TW
            bne     PUN22
            cmpa    #16
            bcs     PUN23
PUN22       ldaa    #15
PUN23       adda    #4
            staa    MCONT               FRAME COUNT THIS RECORD
            suba    #3
            staa    TEMP                BYTE COUNT THIS RECORD
*
*	PUNCH C/R,L/F,NULL,S,1
            ldx     #MTAPE1
            jsr     PDATA1
            clrb                        ZERO CHECKSUM
*
*	PUNCH FRAME COUNT
            ldx     #MCONT
            bsr     PUNT2               PUNCH 2 HEX CHAR
*
*	PUNCH ADDRESS
            ldx     #TW
            bsr     PUNT2
            bsr     PUNT2
*
*	PUNCH DATA
            ldx     TW
PUN32       bsr     PUNT2               PUNCH ONE BYTE (2 FRAMES)
            dec     TEMP                DEC BYTE COUNT
            bne     PUN32
            stx     TW
            comb
            pshb
            tsx
            bsr     PUNT2               PUNCH CHECKSUM
            pulb                        RESTORE STACK
            ldx     TW
            dex
            cpx     ENDA
            bne     PUN11
            bra     C2                  JMP TO CONTRL
*
*	PUNCH 2 HEX CHAR UPDATE CHECKSUM
PUNT2       addb    0,X                 UPDATE CHECKSUM
            jmp     OUT2H               OUTPUT TWO HEX CHAR AND RTS
*
            fcb     1,1,1,1,1,1	GRUE
MCL         fcb     $D,$A,'*,$4
            fcb     1,1,1,1	GRUE
*
*	SAVE X REGISTER
SAV         stx     XTEMP
            rts
            fcb     1,1,1	GRUE
*
*	INPUT ONE CHAR INTO A-REGISTER
INEEE
            bsr     SAV
IN1         ldaa    ACIACS
            asra
            bcc     IN1                 RECEIVE NOT READY
            ldaa    ACIADA              INPUT CHARACTER
            anda    #$7F                RESET PARITY BIT
            cmpa    #$7F
            beq     IN1                 IF RUBOUT, GET NEXT CHAR
            bsr     OUTEEE
            rts
            fcb     1,1,1,1,1,1,1,1	GRUE
            fcb     1,1,1,1,1,1,1,1	GRUE
            fcb     1	GRUE
*
*	OUTPUT ONE CHAR
OUTEEE      psha
OUTEEE1     ldaa    ACIACS
            asra
            asra
            bcc     OUTEEE1
            pula
            staa    ACIADA
            rts
*
*	VECTOR
            org     $FFF8
            fdb     IO
            fdb     SFE
            fdb     POWDWN
            fdb     START

            org     VAR
IOV         rmb     2                   IO INTERRUPT POINTER
BEGA        rmb     2                   BEGINING ADDR PRINT/PUNCH
ENDA        rmb     2                   ENDING ADDR PRINT/PUNCH
NIO         rmb     2                   NMI INTERRUPT POINTER
SP          rmb     1                   S-HIGH
            rmb     1                   S-LOW
CKSM        rmb     1                   CHECKSUM

BYTECT      rmb     1                   BYTE COUNT
XHI         rmb     1                   XREG HIGH
XLOW        rmb     1                   XREG LOW
TEMP        rmb     1                   CHAR COUNT (INADD)
TW          rmb     2                   TEMP
MCONT       rmb     1                   TEMP
XTEMP       rmb     2                   X-REG TEMP STORAGE
            rmb     46
STACK       rmb     1                   STACK POINTER

            end