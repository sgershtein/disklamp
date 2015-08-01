PAGE   255,255

;  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  ³                                                                    ³
;  ³            DiskLamp Ver 3.17   Copyright (c) 3/8/93 by             ³
;  ³                                                                    ³
;  ³                          S. Gershtein                              ³
;  ³                                                                    ³
;  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        .8086


.model  nearstack tiny
.code

        ORG     100H
DEBUG   EQU     0

NEWDRV  EQU     32H
AAX     EQU     16H
BBX     EQU     AAX+6
s44ah   equ     08h
NEWAD   EQU     AD - DRV + NEWDRV
NEWAD2  EQU     NEWAD+2
NEWJMP  EQU     JMPER - DRV + NEWDRV
DOSDR   EQU     0
STATDR  EQU     07h
;;CSEG13  EQU     5
;;CPTR13  EQU     CSEG13+2
NEWINF  EQU     INF13H - DRV + NEWDRV
delta   =     (offset DRV) - NEWDRV

START:  JMP     LOADER

ZASTAV: DB      13,10,'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ·'
        DB      13,10,'³   DiskLamp Ver 3.17,  (c) 1991,92,93 Sergey Gershtein  º'
        DB      13,10,'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼'
        DB      13,10,'$',26
ENVSTR: DB      0,0
        DW      1
MYNAME: DB      'DiskLamp'
NAMELEN EQU     $-MYNAME
        DB      0,0
ENVLEN  EQU     $-ENVSTR
PSPSEG  DW      0
CRC     EQU     03eceH
CRCA    EQU     0bb64h

DRV:                                            ; Int 13h handler
        pop     word ptr cs:aax
        pop     word ptr cs:bbx
        POPF
        push    WORD PTR CS:BBX
        push    WORD PTR CS:AAX
        push    ds
        push    cs
        pop     ds
        pushf
        PUSH    AX
        PUSH    BX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    ES
        PUSH    AX
        PUSH    CS
        POP     ES
        CLD
        TEST    DL,80H
        JZ      FLOPPY
        MOV     Ah,BYTE PTR dS:[FLOPAB-DELTA]
        MOV     BYTE PTR dS:STATDR,Ah
        CMP     CX,1
        JNZ     NMBR
        OR      DH,DH
        JNZ     NMBR
        MOV     BYTE PTR dS:DOSDR,254
        JMP     SHORT NFL
NMBR:   PUSH    DX
        PUSH    CX
        MOV     Al,'?'                  ; Drive '?'
        MOV     DI,OFFSET DRIVES-delta
        SHL     DL,1
        SHL     DL,1
        MOV     BYTE PTR DS:[FLAG13H+3-delta],CL
        MOV     BYTE PTR DS:[FLAG13H+2-delta],DH
        MOV     BYTE PTR DS:[FLAG13H+1-delta],CH
        AND     CL,11000000B
        mov     ch,6
        xchg    ch,cl
        shr     ch,cl
        OR      DL,Ch
        MOV     BYTE PTR DS:[FLAG13H-delta],DL
LOOP4:  MOV     SI,OFFSET FLAG13H-delta
        MOV     CX,4
REPE    CMPSB
        JC      DONE1
        JZ      DONE1A
        ADD     DI,CX
        MOV     AX,WORD PTR DS:[DI]
        INC     DI
        INC     DI
        JMP     SHORT LOOP4
DONE1A:
        MOV     AX,WORD PTR DS:[DI]
DONE1:  MOV     byte PTR DS:DOSDR,Al
        mov     byte ptr ds:statdr,ah
done1b: POP     CX
        POP     DX
        JMP     SHORT NFL
FLOPPY:
        MOV     AH,BYTE PTR dS:[FLOPAB-DELTA+1]
        CMP     DL,00H
        JZ      N_AB
        MOV     AH,BYTE PTR dS:[FLOPAB-DELTA+2]
N_AB:   ADD     DL,'A'
        MOV     AL,DL
        MOV     byte PTR dS:DOSDR,Al
        mov     byte ptr ds:statdr,ah
NFL:    XOR     AX,AX
        MOV     DS,AX
nMONO:  MOV     AX,0B800H
        MOV     BX,WORD PTR DS:044EH
        push    word ptr ds:044ah
        MOV     DS,AX
        mov     DI,offset AAX
        MOV     SI,BX
        MOVSW
        MOVSW
        MOVSW
        POP     Si
        MOV     DI,1
        ADD     SI,SI
        mov     word ptr cs:s44ah,si
        MOVSW
        MOVSW
        MOVSW
        MOV     ES,AX
        MOV     DI,BX
        POP     AX
        push    cs
        pop     ds
        test    BYTE PTR dS:STATDR,2
        JZ      ACCIS
        STC
; From here - error generation
ERRGEN: POP     ES
        POP     DI
        POP     SI
        POP     DX
        POP     BX
        POP     AX
        MOV     AH,80H
        JC      GRET                    ; not C flag means Write Protection
        MOV     AH,03H
gret:
        popf
        pop     ds
        STC
        RETF
; Till here - error generation
ACCIS:
        CMP     AH,4
        JNZ     SHORT NCYAN
        MOV     AH,3FH
        mov     al,'v'
        JMP     SHORT CLDONE
NCYAN:  CMP     AH,2
        JZ      SHORT GREEN
        CMP     AH,0AH
        JZ      SHORT GREEN
        CMP     AH,0EH
        JZ      SHORT GREEN
        JMP     SHORT NGREEN
GREEN:
        mov     ax,02f52h               ; 'R'
        JMP     SHORT CLDONE
NGREEN: CMP     AH,3
        JZ      SHORT RED
        CMP     AH,0BH
        JZ      SHORT RED
        CMP     AH,0FH
        JZ      SHORT RED
        JMP     SHORT NRED
RED:
        mov     ax,04f57h               ; (04fh shl 4 + 'W')
        TEST    byte ptr ds:statdr,8
        JZ      CLDONE
        CLC
        JMP     SHORT ERRGEN
NRED:   CMP     AH,5
        JNZ     SHORT NBLUE
        mov     ax,01f46h               ; (01fh shl 4 + 'F')
        TEST    byte ptr ds:statdr,4
        JZ      CLDONE
        CLC
        JMP     SHORT ERRGEN
NBLUE:  CMP     AH,0CH
        JZ      NZERO
        MOV     DH,BYTE PTR dS:DOSDR
        sub     dh,'A'
        cmp     dh,2
        jb      nzero
        MOV     BYTE PTR dS:DOSDR,0
NZERO:
        mov     ax,0f2ah                ;  (0fh shl 4 + '*')
CLDONE: and     ah,byte ptr ds:[color-delta]
        xchg    al,byte ptr ds:statdr
        MOV     DH,BYTE PTR dS:DOSDR
N_DOS:  MOV     WORD PTR dS:BBX,BX
        TEST    AL,1
        JZ      INOK
        XOR     AL,AL
        JMP     NBORD
INOK:   MOV     AL,DH
        OR      DH,DH
        JNZ     N_H_N
        MOV     AL,'H'
N_H_N:
        PUSH    DS
DOSFSEG =       $ + 1
        MOV     BX,1234H
   MOV   DS,BX
DOSFOFS =       $ + 1
        MOV     BX,1234H
        CMP     BYTE PTR DS:[BX],0
        JNE     DOSCALL
NOND:   OR      AL,20H                  ; Lower case
DOSCALL:
        POP     DS
        STOSW
        OR      DH,DH
        JNZ     C_DOS
        CMP     AL,'H'
        JZ      HARD
        CMP     AL,'h'
        JZ      HARD1
C_DOS:  MOV     AL,':'
        JMP     SHORT END_L
HARD:   MOV     AL,'D'
        JMP     SHORT END_L
HARD1:  MOV     AL,'d'
END_L:  STOSW
        mov     al,byte ptr ds:statdr
;        push    ax
;        AND     AH,0FH
;        stosw
;        pop     ax
        SHR     AH,1
        SHR     AH,1
        SHR     AH,1
        SHR     AH,1
        AND     AH,0FH
        or      ah,ah
	jnz	okah
	mov	ah,0fh
okah:
;        push    ax                      ; ?
        or      ah,8                    ; ? set bright
        stosw                           ; ?
;        pop     ax                      ; ?
JMPER:  JMP     SHORT NBORD
        MOV     DI,WORD PTR DS:s44ah
        MOV     AL,0C4H
        STOSW
        STOSW
        MOV     AL,'Ù'
        STOSW
NBORD:
        POP     ES
        POP     DI
        POP     SI
        POP     DX
        POP     BX
        POP     AX
        DB      9Ah
AD:     DD      ?
        PUSH    SI
        PUSH    DI
        PUSHF
        PUSH    ES
        MOV     di,WORD PTR dS:BBX
nmono1: MOV     si,0B800H
        MOV     ES,si
        CLD
        mov     si,offset aax
        MOVSW
        MOVSW
        MOVSW
        MOV     DI,WORD PTR DS:s44AH
        MOV     SI,1
        MOVSW
        MOVSW
        MOVSW
        POP     ES
        POPF
        POP     DI
        POP     SI
        pop     ds
        RETF                            ; RETF from Int 13H Handler

color:  db      0ffh                    ; here color: 0ffh - color, 1fh - bw
FLAG13H:DB      4 DUP(0)

CDR:    DB      0
FLOPAB: DB      255,255,255
DRIVES: DB      23 DUP(255,255,255,255,255,0)
INF13H: PUSHF
        CMP     AH,2
        JZ      READ
        CMP     AH,0AH
        JZ      READ
        CMP     AH,0EH
        JNZ     NREAD
READ:   PUSH    DX
        PUSH    CX
        SHL     DL,1
        SHL     DL,1
        MOV     BYTE PTR CS:FLAG13H+3,CL
        MOV     BYTE PTR CS:FLAG13H+2,DH
        MOV     BYTE PTR CS:FLAG13H+1,CH
        AND     CL,11000000B
        SHR     CL,1
        SHR     CL,1
        SHR     CL,1
        SHR     CL,1
        SHR     CL,1
        SHR     CL,1
        OR      DL,CL
        MOV     BYTE PTR CS:FLAG13H,DL
        POP     CX
        POP     DX
NREAD:  POPF
        DB      11101010B               ; Far JMP
ADN:    DD      ?

LOADER: MOV     AH,0DH
        INT     21H                     ; Flush Disk buffers
        MOV     BX,OFFSET ZASTAV        ; CRC veryfing
        MOV     DX,BX
        MOV     CX,OFFSET ENVSTR - OFFSET ZASTAV
        XOR     AX,AX
LOOP1:  ADD     AX,WORD PTR DS:[BX]
        INC     BX
        NEG     AX
        LOOP    LOOP1
        CMP     AX,CRC
        JZ      CRC_OK
BCRC:
        if      debug                    ; Output CRC
        mov     bx,ax
        and     ah,0f0h
        shr     ah,1
        shr     ah,1
        shr     ah,1
        shr     ah,1
        add     ah,'0'
        mov     byte ptr crc_ok,ah
        mov     ah,bh
        and     ah,0fh
        add     ah,'0'
        mov     byte ptr crc_ok+1,ah
        mov     ah,bl
        and     ah,0f0h
        shr     ah,1
        shr     ah,1
        shr     ah,1
        shr     ah,1
        add     ah,'0'
        mov     byte ptr crc_ok+2,ah
        mov     ah,bl
        and     ah,0fh
        add     ah,'0'
        mov     byte ptr crc_ok+3,ah
        mov     byte ptr crc_ok+4,'$'
        mov     dx,offset crc_ok
        call    outstr
        endif
        MOV     DX,OFFSET BADCRC         ; Bad CRC
        CALL    OUTSTR
        INT     20H

CRC_OK: MOV     BX,OFFSET CRCV
        MOV     CX,OFFSET endcrc - OFFSET CRCV -2
LOOP1A: ADD     AX,WORD PTR DS:[BX]
        INC     BX
        NEG     AX
        LOOP    LOOP1A
        CMP     AX,CRCA
;        IF      DEBUG
;        CMP     AX,AX
;        ENDIF
        JNZ     BCRC                    ; Bad CRC

        CALL    OUTSTR                  ; CRC Okay

        MOV     AH,30H
        INT     21H                     ; Get DOS version
        CMP     AL,3
        JGE     DOS_OK
        MOV     DX,OFFSET BADDOS
        CALL    OUTSTR
        INT     20H

DOS_OK:
        PUSH    CS
        POP     DS
        MOV     AX,2523H                ; Ctrl-Break
        MOV     DX,OFFSET IR
        INT     21H                     ; Set interrupt vector

        IF      DEBUG                   ; Message 'Experiment'
        MOV     DX,OFFSET EXPER
        CALL    OUTSTR
        ENDIF

        MOV     AH,0FH
        int     10h
        CMP     AL,7
        JNZ     CGA                       ; monocolor
        mov     byte ptr cs:color,1fh
        mov     ax,01b0h
        mov     byte ptr cs:nmono+2,al
        mov     byte ptr cs:nmono1+2,al
        mov     byte ptr cs:nmono2+2,al
        mov     byte ptr cs:nmono3+2,al
        mov     byte ptr cs:nmono4+2,al
        mov     byte ptr cs:nochars,ah
CGA:    CLD
; Looking for the comspec enviroment variable
        MOV     AX,WORD PTR CS:2CH
        dec     ax
        MOV     ES,AX
        XOR     DI,DI
        mov     cx,word ptr es:3
        inc     ax
        mov     es,ax
        shl     cx,1
        shl     cx,1
        shl     cx,1
        shl     cx,1
uploop: cmp     byte ptr es:[di],'a'
        jl      nupnup
        cmp     byte ptr es:[di],'z'
        jg      nupnup
        and     byte ptr es:[di],not 20h
nupnup: inc     di
        loop    uploop
        xor     di,di
        MOV     Al,'C'
        XOR     CX,CX
        DEC     CX
        CLD
LOOPCS:
REPNZ   SCASb
        JNE     NCOMS
        cmp     byte ptr es:[di],'O'
        jne     loopcs
        inc     di
        CMP     WORD PTR ES:DI,'SM'     ; 'CO' 'MS' 'PE' 'C='
        JNE     LOOPCS
        INC     DI
        INC     DI
        CMP     WORD PTR ES:DI,'EP'
        JNE     LOOPCS
        INC     DI
        INC     DI
        CMP     WORD PTR ES:DI,'=C'
        JNE     LOOPCS
        INC     DI
        INC     DI
        MOV     AX,WORD PTR ES:DI
        CMP     AH,':'
        JNZ     NCOMS
;        AND     AL,NOT 20H
        MOV     BYTE PTR CS:DRACC,AL
        SUB     AL,'@'
        MOV     BYTE PTR CS:CSPEC,AL
NCOMS:
; Done looking for the comspec
; Finding drivers
        MOV     AH,52H
        INT     21H
        MOV     DI,BX
        PUSH    ES
        POP     DS
        MOV     AL,'N'
        MOV     CX,0FFFFH
OTHERN:
REPNE   SCASB
        JCXZ    NODRIV
        CMP     WORD PTR DS:DI,'LU'
        JNZ     OTHERN
        MOV     AL,' '
        MOV     CX,5
        MOV     DX,DI
        DEC     DX
        INC     DI
        INC     DI
REPE    SCASB
        JCXZ    GO13
        JMP     SHORT OTHERN
NODRIV: MOV     DX,OFFSET NODRV
        CALL    OUTSTR
        INT     20H
GO13:
        SUB     DX,0AH
        MOV     DI,OFFSET DRIVERS
LOOP7:
 ; Storing block device driver
        MOV     BX,DX
        TEST    BYTE PTR [DS:BX+5],80H
        JNZ     CHARDEV                 ; Character device
        MOV     WORD PTR CS:DI,BX
        MOV     AX,DS
        INC     DI
        INC     DI
        MOV     WORD PTR CS:DI,AX
        INC     DI
        INC     DI
CHARDEV:
 ; End of storing driver
        CMP     WORD PTR [DS:BX],0FFFFH
        JZ      GO14                    ; No more drivers
        MOV     AX,WORD PTR DS:BX+2     ; Finding next driver
        MOV     DX,WORD PTR [DS:BX]
        MOV     DS,AX
        JMP     SHORT LOOP7
; End of finding drivers
GO14:
        PUSH    ES
        PUSH    CS
        PUSH    CS
        POP     DS
        POP     ES
        MOV     WORD PTR STOREDI,DI
; Parameters Upcasing & Delspacing
        MOV     Bl,BYTE PTR DS:80H      ; Parm Str length
        XOR     BH,BH
        MOV     BYTE PTR DS:[BX+81H],0  ; Marking End of Parm with 0
        MOV     SI,81h
LOOP18: CMP     BYTE PTR DS:[SI],0
        JZ      DUDONE
        CMP     BYTE PTR DS:[SI],'a'
        JL      GO18
        CMP     BYTE PTR DS:[SI],'z'
        JG      GO18
        AND     BYTE PTR DS:[SI],NOT 20H  ; UpCasing
GO18:   CMP     BYTE PTR DS:[SI],' '
        JNZ     GO19
        PUSH    SI
        MOV     DI,SI
        INC     SI
        MOV     CX,100H
        SUB     CX,SI
        CLD
REP     MOVSB
        POP     SI
        JMP     SHORT LOOP18
GO19:   INC     SI
        JMP     SHORT LOOP18
DUDONE: POP     ES
; UpCs & DelSp Done
        MOV     SI,80H
SPF:    INC     SI
sppf:   cmp     byte ptr ds:[si],'-'
        jz      okk
        CMP     BYTE PTR DS:[SI],'/'
        JZ      okk
        cmp     byte ptr ds:[si],0
        jz      okgo4
        jmp     nsw
okgo4:  jmp     go4
okk:    dec     BYTE PTR CS:NOPARM
        INC     SI
        CMP     BYTE PTR DS:[SI],'?'
        JZ      HLP
        CMP     BYTE PTR DS:[SI],'H'
        JNZ     NHELP
HLP:    MOV     DX,OFFSET HELP
        JMP     SWHALT
NHELP:  CMP     BYTE PTR DS:[SI],'B'
        JnZ     nBCH
        jmp     bch
nbch:   CMP     BYTE PTR DS:[SI],'Q'
        JNZ     NSW300
        MOV     BYTE PTR cs:QUIT,1
        JMP     SHORT SPF
nsw300: cmp     byte ptr ds:[si],'F'
        jz      set_f10
        cmp     byte ptr ds:[si],'C'
        jz      set_c
        cmp     byte ptr ds:[si],'N'
        jz      set_n
        cmp     byte ptr ds:[si],'I'
        jnz     resset
        jmp     set_i
resset: cmp     byte ptr ds:[si],'W'
        jnz     nset_w
        jmp     set_w
nset_w: cmp     byte ptr ds:[si],'A'
        jz      set_a10
        cmp     byte ptr ds:[si],'S'
        jz      set_s
        cmp     byte ptr ds:[si],'M'
        jz      set_m
;       here another switches

        jmp     nsw
set_f10:jmp     short set_f
set_a10:jmp     set_a
set_c:  cmp     byte ptr c_set,0
        jz      okcs
        jmp     bsw
okcs:   inc     byte ptr noparm
        mov     byte ptr c_set,1
        inc     si
        cmp     byte ptr ds:[si],'+'
        jz      set_c_p
        cmp     byte ptr ds:[si],'-'
        jz      bsw_cn
        jmp     nsw
bsw_cn: mov     byte ptr cs:color,01fh  ; color off
        jmp     spf
set_c_p:cmp     word ptr cs:nmono+1,0b000h
        jnz     notmm
        mov     dx,offset cpmono
        call    outstr
;        int     20h
        jmp     spf
notmm:  mov     byte ptr cs:color,0ffh  ; color on
        jmp     spf
set_s:  mov     byte ptr noparm,128     ; no menu (silent mode)
        cmp     byte ptr forcem,1
        jnz     back3s
        jmp     bsw                     ; -m & -s
set_n:  mov     byte ptr ds:nochars,1
        inc     byte ptr noparm
back3s: inc     si
sppf1:  jmp     sppf
set_m:  mov     byte ptr forcem,1       ; forse menu
        cmp     byte ptr noparm,128
        ja      back3s
        cmp     byte ptr noparm,0
        je      back3s
        jmp     bsw
set_f:  inc     si
set_f1: mov     bh,4
        call    setres
        cmp     byte ptr [si],'/'
        jz      sppf1
        cmp     byte ptr [si],'-'
        jz      sppf1
        cmp     byte ptr [si],0
        jz      sppf1
        jmp     short set_f1
set_a:  inc     si
set_a1: mov     bh,2
        call    setres
        cmp     byte ptr [si],'/'
        jz      sppf1
        cmp     byte ptr [si],'-'
        jz      sppf1
        cmp     byte ptr [si],0
        jz      sppf1
        jmp     short set_a1
set_w:  inc     si
set_w1: mov     bh,8
        call    setres
        cmp     byte ptr ds:[si],'/'
        jz      sppf1
        cmp     byte ptr ds:[si],'-'
        jz      sppf1
        cmp     byte ptr ds:[si],0
        jz      sppf1
        jmp     short set_w1
set_i:  inc     si
set_i1: mov     bh,1
        call    setres
        cmp     byte ptr ds:[si],'/'
        jz      sppf1
        cmp     byte ptr ds:[si],'-'
        jz      sppf1
        cmp     byte ptr ds:[si],0
        jz      sppf1
        jmp     short set_i1
;set_w:
;        jmp     short spf
;set_a:
;        jmp     short spf
;set_i:
;        jmp     short spf
BCH:    INC     SI
        CMP     BYTE PTR DS:[SI],'+'
        JNZ     NPLUS
        CMP     BYTE PTR BORDER,0
        JNZ     BSW
        MOV     BYTE PTR BORDER,255
        MOV     WORD PTR JMPER,9090H
        JMP     SPF
NPLUS:  CMP     BYTE PTR DS:[SI],'-'
        JNZ     NSW
        CMP     BYTE PTR BORDER,0
        JNZ     BSW
        MOV     BYTE PTR BORDER,1
        JMP     SPF
NSW:
        MOV     DX,OFFSET BADSW
SWHALT: CALL    OUTSTR                  ; Help
        INT     20H                     ; Halt program
BSW:    MOV     DX,OFFSET BSWT
        CALL    OUTSTR
        MOV     DX,OFFSET HELP
        JMP     SHORT SWHALT

GO4:
;        mov     byte ptr cs:border,0    ; To protect influation
        mov     si,offset resdr
        mov     di,offset setdr
        mov     cx,27
loopsrd:lodsb
        not     al
        and     al,byte ptr ds:[di]
        jnz     bsw
        inc     di
        loop    loopsrd

        CALL    CONTROL                 ; Already loaded?

        CMP     BYTE PTR CS:QUIT,0
        JZ      NQI
        MOV     DX,OFFSET NLO           ; Not loaded
        CALL    OUTSTR
        INT     20H

NQI:    PUSH    CS                      ; Marking PSP:20h with name
        POP     ES
        PUSH    CS
        POP     DS
        MOV     DI,20H
        MOV     SI,OFFSET MYNAME
        MOV     CX,NAMELEN
        CLD
REP     MOVSB

        MOV     AX,WORD PTR CS:2CH      ; Setting Name into Enviroment
        MOV     ES,AX
        PUSH    ES                      ; Segment of Env
        MOV     AH,4AH                  ; DOS Fn SetBlock
        MOV     BX,1                    ; New Env size will be 1
        INT     21H                     ; DOS call
        JNC     GO1                     ; No error
        MOV     DX,OFFSET ERRS          ; Error message
        CALL    OUTSTR
        INT     20H                     ; Halt program

GO1:    MOV     CX,ENVLEN
        MOV     SI,OFFSET ENVSTR
        MOV     DI,00H
REP     MOVSB

        PUSH    CS                      ; DOS flag installation
        POP     ES
        MOV     AH,34H
        INT     21H
        MOV     WORD PTR DOSFOFS,BX
        MOV     AX,ES
        MOV     WORD PTR DOSFSEG,AX

        XOR     AX,AX                   ; Interrupt 13h instalation
        MOV     DS,AX
        PUSH    CS
        POP     ES
        MOV     SI,76
        MOV     DI,OFFSET AD
        MOVSW
        MOVSW
        MOV     SI,76                   ; Inf13h installation
        MOV     DI,OFFSET ADN
        MOVSW
        MOVSW

        MOV     AX,3513H                ; Saving the old 13h vec
        INT     21H
        PUSH    ES
        PUSH    BX

        PUSH    CS
        POP     DS
        MOV     AH,25H                  ; Setting New Interrupt Vector
        MOV     DX,OFFSET INF13H
        INT     21H                     ; Set interrupt vector

        MOV     AH,0DH
        INT     21H                     ; Flush Disk buffers

; Working with drivers
        MOV     AX,0401H
        MOV     CX,0001H
        MOV     DX,0080H
        INT     13H
        JC      GO28
        MOV     BYTE PTR CS:FLOPAB,0
GO28:   ;MOV     BYTE PTR CS:STATUS+1,255
        PUSH    CS
        POP     DS
        MOV     AX,DS
        MOV     WORD PTR ADDRSEG,AX     ; Segment of Buffer
        MOV     DI,WORD PTR STOREDI
        SUB     DI,4
        XOR     CX,CX
        INT     11H                     ; Number of Floppies
        TEST    AL,1
        JZ      wWDRV                   ; No floppies
        MOV     BYTE PTR FLOPAB+1,0
        AND     AL,192
        JZ      WWDRV
        MOV     BYTE PTR FLOPAB+2,0
WWDRV:  MOV     CH,2
        MOV     DL,'C'
WDRV:
        MOV     BYTE PTR UNIT,CH
        MOV     AX,WORD PTR [DS:DI+2]
        MOV     ES,AX
        MOV     BX,WORD PTR [DS:DI]
        MOV     WORD PTR ENTRY_S,AX
        MOV     AX,WORD PTR [ES:BX+6]
        MOV     WORD PTR ENTRY_O,AX
        PUSH    ES
        PUSH    BX
        PUSH    CS
        POP     ES
        MOV     BX,OFFSET QUS
        mov     word ptr ds:numsec,1
        mov     word ptr ds:status,0
        mov     word ptr ds:sector,0
        CALL    DWORD PTR ENTRY_O
        POP     BX
        POP     ES
        MOV     AX,WORD PTR [ES:BX+8]
        MOV     WORD PTR ENTRY_O,AX
        MOV     BYTE PTR [DS:FLAG13H+3],0
        CALL    DWORD PTR ENTRY_O
        INC     BYTE PTR CS:CDR
        INC     CH
        TEST    BYTE PTR [DS:STATUS+1],80H
        JZ      IFNXT
        cmp     byte ptr ds:status,0
        jz      ifnxt
ERRD:   MOV     DX,OFFSET ERR25
        CALL    OUTSTR

IFNXT:  MOV     BP,DX
        PUSH    DI
        CMP     BYTE PTR [FLAG13H+3],0
        JZ      NONEHD
        MOV     DI,6
        MOV     AL,CL
        XOR     AH,AH
        MUL     DI
        MOV     SI,OFFSET FLAG13H
        MOV     DI,OFFSET DRIVES
        ADD     DI,AX
        PUSH    ES
        PUSH    CS
        POP     ES
        PUSH    CX
        SUB     DI,6
LOOP17: PUSH    SI
        MOV     CX,4
REPE    CMPSB
        PUSHF
        ADD     DI,CX
        INC     DI
        INC     DI
        CMP     DI,OFFSET DRIVES
        JZ      GO17A
        POPF
        POP     SI
        JNC     GO17
        PUSH    SI
        MOV     SI,DI
        SUB     SI,6
        MOVSW
        MOVSW
        MOVSW
        SUB     DI,18
        POP     SI
        JMP     SHORT LOOP17
GO17A:  POPF
        POP     SI
GO17:
        POP     CX
        MOVSW
        MOVSW
        MOV     DX,BP
        MOV     BYTE PTR ES:[DI],DL
        INC     DI
        POP     ES
        INC     CL
NONEHD: POP     DI
        INC     DX
        CMP     BYTE PTR [ES:BX+0AH],CH
        JNG     NWDRV
        JMP     WDRV
NWDRV:  XOR     CH,CH
        CMP     DI,OFFSET DRIVERS
        JZ      GO15
        SUB     DI,4
        JMP     WDRV
GO15:
        MOV     BYTE PTR CS:ADDDX+1,CL
NFD:
; End of working with drivers
ERR25G:
        POP     DX                      ; Restoring the old 13h vec
        POP     DS
        MOV     AX,2513H
        INT     21H

        XOR     AH,AH
        PUSH    ES
        PUSH    BX
        PUSH    CS
        POP     ES
        MOV     BX,OFFSET CDR
        MOV     BYTE PTR CS:STAY,0
        CALL    MENU                    ; Working with menu
        POP     BX
        POP     ES
        CMP     AH,1                    ; 2 means `install'
        JNZ     GOOK                    ; OK
        MOV     DX,OFFSET DONOTL        ; was not loaded
        CALL    OUTSTR
        INT     20H                     ; `Uninstall'

GOOK:
        MOV     DX,OFFSET LOADING       ; Message 'loading'
        CALL    OUTSTR
        mov     ax,cs
        mov     word ptr myseg,ax       ; store self code seg
        call    statusp
;        MOV     DX,OFFSET BORSET        ; Message 'Status'
;        CALL    OUTSTR
;        MOV     AL,BYTE PTR JMPER
;        MOV     AH,02H
;        CMP     AL,90H
;        JZ      BON1
;        MOV     DL,'f'
;        INT     21H
;        INT     21H
;        JMP     SHORT EM1       1111111111111111111111
;BON1:   MOV     DL,'n'
;        INT     21H
;EM1:    MOV     DX,OFFSET EMSTR
;        CALL    OUTSTR

        PUSH    CS
        POP     DS
        POP     ES                      ; Segment of Env
        MOV     AX,ES
        ADD     AX,WORD PTR ES:13H
        INC     AX
        INC     AX
        INC     AX
        MOV     CX,DS
        CMP     AX,CX
        JNE     GO6                     ; Non-closed Env to PSP
        CLI                             ; Disable interrupts
        MOV     AX,WORD PTR ES:11H
        TEST    AX,AX
        JNZ     GO5                     ; Used block
        MOV     AX,CS
        DEC     AX
        MOV     DS,AX                   ; DS - MCB of PSP
        MOV     SI,5
        MOV     DI,15H
        MOV     CX,0BH
REP     MOVSB                           ; Copy reserved MCB bytes
        MOV     AH,BYTE PTR DS:0
        MOV     BYTE PTR ES:10h,AH      ; Copy 'M' or 'Z' char
        MOV     AX,ES
        INC     AX
        INC     AX
        MOV     WORD PTR ES:11H,AX      ; New PSP seg
        MOV     BX,AX
        MOV     AX,WORD PTR DS:3        ; Old length
        ADD     AX,WORD PTR ES:13h      ; Block length
        INC     AX                      ; Old MCB len = 16 bytes
        MOV     WORD PTR ES:13h,AX
        MOV     AX,ES
        DEC     AX
        MOV     ES,AX
        MOV     WORD PTR ES:1,BX        ; Owner of Env
        INC     AX
        INC     AX
        INC     AX
        MOV     ES,AX                   ; Now ES - seg of new PSP
        PUSH    CS
        POP     DS                      ; DS - old PSP seg
        XOR     SI,SI                   ; Zero SI
        MOV     DI,SI                   ; and DI
        STI
        JMP     MOVER                   ; Moving all the text
                                        ; to new PSP

GO5:    STI                             ; Enable interrupts
GO6:
        PUSH    CS                      ; Moving driver from DRV to PSP:2fh
        POP     DS
        PUSH    DS
        POP     ES
        MOV     SI,OFFSET DRV
        MOV     DI,NEWDRV
        MOV     CX,OFFSET LOADER - OFFSET DRV
        CLD
REP     MOVSB

        MOV     AX,WORD PTR CS:VER      ; Setting the version #
        SUB     AX,3030H
        MOV     WORD PTR DS:2AH,AX      ; ???
        MOV     AX,0909H                ; Version 3, ver 4 - 0809h, 5 - 0709h
                                        ; and so on
        MOV     WORD PTR DS:28H,AX

        MOV     AX,2513H                ; Setting New Interrupt Vector
        MOV     DX,NEWDRV
        INT     21H                     ; Set interrupt vector

ADDDX:  MOV     DX,0                    ; here 0 will be changed
        MOV     AX,6                    ; during program running
        inc     dx
        MUL     DX
        MOV     DX,AX
        ADD     DX,OFFSET DRIVES - OFFSET DRV + NEWDRV
        INT     27H                     ; Terminate, stay resident

setres  proc    near                    ; Set / reset switches
;        mov     ax,word ptr ds:[si]
        cld
        lodsw
        cmp     al,'?'
        jnz     tea
        xor     al,al
        jmp     short donal
tea:    cmp     al,'A'
        jl      nnnsw
        cmp     al,'Z'
        jle     nsw1
nnnsw:  pop     ax
        jmp     nsw
nsw1:   sub     al,'@'
donal:  cmp     ah,':'
        jnz     nnnsw
        mov     ah,byte ptr ds:[si]
        inc     si
        mov     di,offset setdr
        cmp     ah,'-'
        jz      ok_set
        mov     di,offset resdr
        cmp     ah,'+'
        jz      ok_res
        pop     ax
        jmp     bsw
ok_set: xor     ah,ah
        add     di,ax
        or      byte ptr ds:[di],bh
;        inc     si
;        inc     si
        ret
ok_res: xor     ah,ah
        add     di,ax
        not     bh
        and     byte ptr ds:[di],bh
;        inc     si
;        inc     si
        ret
setres  endp

OUTSTR  PROC    NEAR
        PUSH    CS                      ; Out string from
        POP     DS                      ; DS:DX till first '$'
        MOV     AH,9
        INT     21H
        RET
OUTSTR  ENDP

sint10h proc    near                    ; save ax,bx... & call int 10h,
        mov     word ptr cs:sax,ax      ; then restore ax,bx...
        mov     word ptr cs:sbx,bx
        mov     word ptr cs:sdx,dx
        mov     word ptr cs:sbp,bp
        mov     word ptr cs:ssp,sp
        mov     word ptr cs:scx,cx
        int     10h
        mov     ax,word ptr cs:sax
        mov     bx,word ptr cs:sbx
        mov     dx,word ptr cs:sdx
        mov     bp,word ptr cs:sbp
        mov     sp,word ptr cs:ssp
        mov     cx,word ptr cs:scx
        ret
sint10h endp
sax:    dw      ?
sbx:    dw      ?
scx:    dw      ?
sdx:    dw      ?
sbp:    dw      ?
ssp:    dw      ?

SAVESCR PROC    NEAR                    ; Save screen & video mode
;
;       Testing adapter type:
;       1 - EGA, 2 - VGA, 0 - Other
;
        cmp     byte ptr cs:nochars,0
        jnz     doneva                  ; switch -n entered
        MOV     AX,1A00H
        int     10h
;       call    sint10h
        CMP     AL,1AH
        JNZ     NONVGA
        CMP     BL,0FFH
        JZ      NONVGA
        CMP     BL,08H
        JNZ     NONVGA
        MOV     BYTE PTR CS:EVA,2
        JMP     SHORT DONEVA
NONVGA: MOV     Ah,12H
        mov     bl,10h
        int     10h
;        call    sint10h
        CMP     BL,10H
        JZ      DONEVA
        CMP     CL,6
        JC      DONEVA
        CMP     CL,0AH
        JNC     DONEVA
        MOV     BYTE PTR CS:EVA,1
DONEVA:
;       Adapter type have been tested

        MOV     AX,CS
        MOV     DX,SS
        SUB     DX,AX
        MOV     AX,SP
        SUB     AX,OFFSET SCRBUF
        SHR     AX,1
        SHR     AX,1
        SHR     AX,1
        SHR     AX,1
        ADD     AX,DX
        CMP     AX,400H
        JNC     OKBUF                   ; JNC is '<='
        MOV     DX,OFFSET NOMEM
        CALL    OUTSTR
        INT     20H
OKBUF:
;        MOV     CX,SP
        MOV     AX,500H
        call    sint10h
;        MOV     SP,CX
        XOR     AX,AX
        MOV     DS,AX
        MOV     AX,WORD PTR DS:[0450H]
        MOV     WORD PTR CS:SAVECP,AX
nmono3: MOV     AX,0B800H
        MOV     BX,WORD PTR DS:044EH
        MOV     DS,AX
        CLD
        PUSH    CS
        POP     ES
        MOV     DI,OFFSET SCRBUF
        MOV     SI,BX
        MOV     CX,2000H
REP     MOVSW
        MOV     AH,0FH
        MOV     CX,SP
        int     10h
        MOV     SP,CX
        MOV     BYTE PTR CS:VMODE,AL
        cmp     al,7
        jz      go21
        MOV     AX,3
        call    sint10h
;        MOV     SP,CX
GO21:   MOV     AH,2
        XOR     BH,BH
        MOV     DH,25
        XOR     DL,DL
        call    sint10h
;        MOV     SP,CX
        CMP     BYTE PTR CS:EVA,0
        JZ      OTH1
        PUSH    CS
        POP     ES
        MOV     BP,OFFSET TBL43
        MOV     CX,1
        MOV     DX,43
        XOR     BL,BL
        MOV     BH,14
        CMP     BYTE PTR CS:EVA,1
        JZ      EGA1
        INC     BH
        INC     BH
EGA1:   MOV     AX,1100H
        call    sint10h
        MOV     DX,45
        MOV     BP,OFFSET TBL45
        call    sint10h
        MOV     DX,196
        MOV     BP,OFFSET TBL196
        call    sint10h
        MOV     DX,179
        MOV     BP,OFFSET TBL179
        call    sint10h
        MOV     DX,217
        MOV     BP,OFFSET TBL217
        call    sint10h
        INC     DX
        MOV     BP,OFFSET TBL218
        call    sint10h
        MOV     DX,191
        MOV     BP,OFFSET TBL191
        call    sint10h
        INC     DX
        MOV     BP,OFFSET TBL192
        call    sint10h
        MOV     DX,240
        MOV     BP,OFFSET TBL001
        CMP     BYTE PTR CS:EVA,2
        JZ      EGA3
        INC     BP
        INC     BP
EGA3:
        call    sint10h
        INC     DX
        ADD     BP,16
        CMP     DX,248
        JNZ     EGA3
        MOV     AX,1103H
        call    sint10h
OTH1:   RET
SAVESCR ENDP

include chtables.asm                    ; Character tables

RESTSCR PROC    NEAR                    ; Restore saved screeen & video mode
        CMP     BYTE PTR CS:EVA,0
        JZ      OTH3
        MOV     AX,1101H
        CMP     BYTE PTR CS:EVA,1
        JZ      EGA2
        INC     AL
        INC     AL
        INC     AL
EGA2:   XOR     BL,BL
        call    sint10h                 ; loading letter's pictures from ROM
OTH3:   MOV     AL,BYTE PTR CS:VMODE
        XOR     AH,AH
        call    sint10h
GO22:   XOR     AX,AX
        MOV     DS,AX
nmono4: MOV     AX,0B800H
        MOV     BX,WORD PTR DS:044EH
        MOV     ES,AX
        CLD
        PUSH    CS
        POP     DS
        MOV     SI,OFFSET SCRBUF
        MOV     DI,BX
        MOV     CX,2000H
REP     MOVSW
        PUSH    DS
        XOR     AX,AX
        MOV     DS,AX
        MOV     AX,WORD PTR CS:SAVECP
        MOV     WORD PTR DS:[0450H],AX
        POP     DS
        RET
SAVECP: DW      ?
RESTSCR ENDP

CONTROL PROC    NEAR
        MOV     AH,52H
        INT     21H
        MOV     AX,WORD PTR ES:[BX-2]   ; Segment of the first MCB
        PUSH    CS
        POP     DS

LOOP3:  MOV     ES,AX                   ; Next MCB
        MOV     BX,WORD PTR ES:1        ; Owner
        DEC     BX
        CMP     BX,AX
        JNZ     N_FOUND                 ; JMP if non-PSP Segment

PSP_S:  MOV     DI,30H                  ; Here - PSP segment
        MOV     SI,OFFSET MYNAME
        MOV     CX,NAMELEN
        CLD
REPE    CMPSB
        JNZ     N_FOUND
        MOV     WORD PTR PSPSEG,AX      ; Self PSP found.

N_FOUND:CMP     BYTE PTR ES:0,'M'
        JNZ     Z_MCB
        ADD     AX,WORD PTR ES:3
        INC     AX
        JMP     SHORT LOOP3             ; Looking for the next MCB

Z_MCB:  MOV     BX,WORD PTR PSPSEG
        TEST    BX,BX
        JNZ     FOUND
        RET
FOUND:  MOV     DX,OFFSET ALREADY
        CALL    OUTSTR
        INC     BX                      ; PSP instead of MCB
        MOV     DS,BX
        mov     word ptr cs:myseg,bx    ; store code seg of resident
        cmp     byte ptr cs:border,0
        jz      nsetbo
        MOV     AX,WORD PTR CS:JMPER    ; set border properly
        MOV     WORD PTR DS:NEWJMP,AX
        mov     byte ptr cs:border,0
nsetbo: MOV     AX,WORD PTR DS:2AH      ; Testing version
        ADD     AX,3030H
        CMP     AX,WORD PTR CS:VER
        JZ      GO8
        MOV     WORD PTR CS:VER,AX
NONONO: MOV     AX,WORD PTR DS:28H      ; ???
        CMP     AX,0909H
        JZ      VER3
        CMP     AL,09H
        JZ      VERG3
        ADD     AX,3030H
        MOV     WORD PTR CS:VER,AX
        DEC     BYTE PTR CS:VER-2
        JMP     SHORT VER3
VERG3:  SUB     AH,9
        NEG     AH
        ADD     BYTE PTR CS:VER-2,AH
VER3:   MOV     DX,OFFSET BADVER
        CALL    OUTSTR
        INT     20H

GO8:
        cmp     byte ptr cs:c_set,0
        jz      c_n_s
        push    ax
        mov     ah,byte ptr cs:color
        mov     byte ptr ds:[color-delta],ah
        pop     ax
c_n_s:
        CMP     WORD PTR DS:28H,0909H
        JNZ     NONONO
        CMP     BYTE PTR CS:BORDER,0
        JZ      UNI
        MOV     AX,WORD PTR CS:JMPER
        MOV     WORD PTR DS:NEWJMP,AX
        call    statusp             ; Output current status
;        PUSH    AX
;        MOV     DX,OFFSET BORSET
;        CALL    OUTSTR
;        POP     AX
;        MOV     AH,02H      2222222222222222222222
;        CMP     AL,90H
;        JZ      BON
;        MOV     DL,'f'
;        INT     21H
;        INT     21H
;        JMP     SHORT EM
;BON:    MOV     DL,'n'
;        INT     21H
;EM:     MOV     DX,OFFSET EMSTR
;        CALL    OUTSTR
        INT     20H
UNI:    PUSH    ES
        PUSH    DS
        XOR     AH,AH
        CMP     WORD PTR DS:NEWJMP,9090H
        JZ      BISON                   ; b_is_on
        MOV     BYTE PTR CS:BORDER,1    ; B - OFF
        JMP     CMENU
BISON:  MOV     BYTE PTR CS:BORDER,255  ; B - ON
CMENU:
        PUSH    DS
        POP     ES
        PUSH    BX
        push    ax
        push    es
        MOV     AX,3513H
        INT     21H                     ; Get vector
        MOV     AX,ES
        MOV     CX,DS
        CMP     AX,CX
        JNZ     NEW_13H                 ; Vector was changed
        CMP     BX,NEWDRV
        JZ      go_m                    ; Offset of Int 13h is not changed
new_13h:mov     byte ptr cs:cantun,1    ; Cannot be uninstalled
go_m:   mov     ax,es
        mov     word ptr cs:saves,ax    ; save es
        pop     es
        pop     ax
        MOV     BX,CDR - DELTA
        cmp     byte ptr cs:quit,0
        jz      c_m_now                 ; no command to uninstall is given
        cmp     byte ptr cs:cantun,0
        jz      c_b_uni                 ; command given & it's OK
        mov     byte ptr cs:cantun,2    ; can't be uninstalled
        jmp     short c_m_now
c_b_uni:mov     byte ptr cs:stay,0
c_m_now:CALL    MENU
        POP     BX
        POP     DS
        POP     ES
        CMP     AH,1                    ; 1 = Uninstall
        JZ      GOUN
        OR      AH,AH
        JZ      GOUNg                    ; 0 = No changes
        JMP     GO8

goung:  cmp     byte ptr cs:quit,0
        jnz     goun
;        mov     dx,offset borset
;        call    outstr             ; 33333333333333333333333
        call    statusp
        int     20h

GOUN:   cmp     byte ptr cs:cantun,0
        jnz     new_13
        mov     ax,word ptr cs:saves    ; restore es
        mov     es,ax
        MOV     DX,WORD PTR ES:NEWAD
        MOV     AX,WORD PTR ES:NEWAD2
        MOV     DS,AX
        MOV     AX,2513H                ; Set Old 13h vector
        INT     21H
        MOV     DX,OFFSET FREE
        CALL    OUTSTR
        MOV     WORD PTR ES:20H,AX
        MOV     BX,WORD PTR ES:2CH
        MOV     AH,49H
        INT     21H                     ; Free PSP
        JNC     GO2
        MOV     DX,OFFSET ERRS
        CALL    OUTSTR
GO2:    MOV     ES,BX                   ; AX,WORD PTR CS:ENVSEG
        MOV     AH,49H
        INT     21H                     ; Free Env
        JNC     GO3
        MOV     DX,OFFSET ERRS
        CALL    OUTSTR
GO3:    INT     20H
NEW_13: MOV     DX,OFFSET CHVEC
        CALL    OUTSTR
        INT     20H                     ; End program
CONTROL ENDP

WINDOW  PROC    NEAR
        MOV     WORD PTR CS:SAVESP,SP
        MOV     AX,600H
        int     10h
        MOV     BH,DH
        INC     BH
        MOV     AH,BH
        MOV     AL,CL
        INC     AL
        INC     AL
        MOV     DI,AX
        MOV     AL,DL
        SUB     AL,CL
        XOR     AH,AH
        INC     AL
        MOV     SI,AX
        MOV     AL,DL
        MOV     AH,CH
        INC     AH
        INC     AL
        PUSH    CS
        POP     DS
        MOV     BYTE PTR ATTR,06H
LOOPI:  MOV     DX,OFFSET BK
        MOV     CX,AX
        CALL    WRITE
        MOV     AX,CX
        INC     AH
        CMP     AH,BH
        JNZ     LOOPI
        MOV     CX,SI
        MOV     DX,DI
        MOV     AH,02H
        XOR     BH,BH
        call    sint10h
        MOV     AX,907H
        MOV     BX,06H
        cmp     byte ptr cs:color1,0
        jnz     goon
        mov     bx,07h
goon:   call    sint10h
        MOV     SP,WORD PTR CS:SAVESP
        MOV     BYTE PTR ATTR,5EH
        RET
SAVESP: DW      ?
BK:     DB      7,7,0
WINDOW  ENDP

GETCHAR PROC    NEAR
        XOR     AH,AH
        INT     16H
        RET
GETCHAR ENDP

WRITE   PROC    NEAR                    ; Write string from DS:DX till
        PUSH    CX                      ; first 0, attribute - CS:ATTR
        PUSH    BX                      ; from cursor position (Al,Ah)
        PUSH    SI
        PUSH    DI
        PUSH    ES
        PUSH    AX
        MOV     CL,AL
        XOR     CH,CH
        ADD     CX,CX                   ; Doubling CX
        MOV     DI,CX
        MOV     SI,DX
        MOV     AL,AH
        MOV     AH,160                  ; Y coordinate
        MUL     AH
        ADD     DI,AX
nmono2: MOV     AX,0B800H
        MOV     ES,AX
        MOV     AH,BYTE PTR CS:ATTR

        cmp     byte ptr cs:color1,0
        jnz     okcolor
        test    ah,40h
        jnz     gg1
        mov     ah,07h
        jmp     short okcolor
gg1:    mov     ah,70h

;        test    ah,0fh
;        jz      txdone
;        test    ah,8
;        pushf
;        and     ah,0f0h
;        popf
;        jz      grcol
;        or      ah,7
;        jmp     short txdone
;grcol:  or      ah,8
;txdone: test    ah,40h
;        jnz     mkbl
;        and     ah,0fh
;        or      ah,70h
;        jmp     short okcolor
;mkbl:   and     ah,0fh
okcolor:
;mov     ah,07h          ; ttttt

LOOPWN: CMP     BYTE PTR [DS:SI],0
        JZ      ENDLWN
        MOVSB
        MOV     BYTE PTR ES:DI,AH
        INC     DI
        JMP     SHORT LOOPWN
ENDLWN:
        POP     AX
        POP     ES
        POP     DI
        POP     SI
        POP     BX
        POP     CX
        RET

LOOPW1: MOV    WORD PTR CS:CURPOS,AX
        PUSH    DX
        MOV     AH,02H
        XOR     BH,BH
        MOV     DX,WORD PTR CS:CURPOS
        call    sint10h
        POP     DX
        MOV     CX,1
        MOV     BL,BYTE PTR CS:ATTR
        XOR     BH,BH
        MOV     AH,09H
        MOV     SI,DX
        MOV     AL,BYTE PTR DS:SI
        OR      AL,AL
        JZ      DONEW
        INC     DX
        call    sint10h
        MOV     AX,WORD PTR CS:CURPOS
        INC     AL
        CMP     AL,80
        JNZ     LOOPW1
        XOR     AL,AL
        INC     AH
        JMP     SHORT LOOPW1
DONEW:
        POP     DI
        POP     SI
        POP     BX
        POP     CX
        RET
;SAVESP1:DW      ?
WRITE   ENDP

BACKGR  PROC    NEAR
        MOV     AH,02H
        XOR     BH,BH
        XOR     DX,DX
        call    sint10h
        MOV     AX,0907H
        MOV     BX,01EH
        cmp     byte ptr cs:color1,0
        jnz     normcol
        mov     bl,07h
normcol:MOV     CX,2000H
        call    sint10h
        RET
BACKGR  ENDP

BEEP    PROC    NEAR                    ; Beep procedure !!!!!!!!!
        PUSH    AX
        PUSH    DS
        PUSH    CX
        PUSH    BX
        PUSH    DI
        MOV     AH,BYTE PTR CS:NBEEP
        OR      AH,AH
        JZ      NOTB
        cmp     ah,-1
        jz      notb
        MOV     BX,1193180/3000
        MOV     DI,100
        MOV     CX,2
        CMP     AH,1                    ; beep types:
        JZ      SOU                     ; 1 - illegal key
        MOV     BX,1193180/5000         ; 2 - cannot toggle
        INC     CX                      ; 3 - warning
        INC     CX
        MOV     DI,50
        CMP     AH,2
        JZ      SOU
        MOV     DI,10
SOU:    MOV     AH,1
        INT     16H
        JNZ     NOTB
        XOR     AX,AX
        MOV     DS,AX
LOOPSS: MOV     AL,182
        OUT     67,AL
        MOV     AX,BX
        OUT     66,AL
        MOV     AL,AH
        OUT     66,AL
        IN      AL,97
        PUSH    AX
        OR      AL,3
        OUT     97,AL
        SUB     BX,DI
        MOV     AX,WORD PTR DS:046CH
        INC     AX
LOOPWT: CMP     AX,WORD PTR DS:046CH
        JNC     LOOPWT
        POP     AX
        OUT     97,AL
        LOOP    LOOPSS
NOTB:   POP     DI
        MOV     BYTE PTR CS:NBEEP,0
        POP     BX
        POP     CX
        POP     DS
        POP     AX
        RET
BEEP    ENDP

MENU    PROC    NEAR
        PUSH    BX
        PUSH    ES
        push    bx
        sub     bx,5
; color analysis
        mov     ah,byte ptr es:[bx]
        cmp     ah,1fh
        jnz     coasis
        xor     ah,ah
coasis: mov     byte ptr cs:color1,ah
; end color analysis
        pop     bx
        inc     bx
        push    bx
        push    cs
        pop     ds
        mov     si,offset setdr
        push    si
        mov     cx,3
loo1a:  lodsb
        or      byte ptr es:[bx],al
        inc     bx
        loop    loo1a
        pop     di
        add     bx,4
loo2a:  mov     si,di
        mov     dl,byte ptr es:[bx]
        cmp     dl,255
        jz      loo2af
        sub     dl,'@'
        xor     dh,dh
        add     si,dx
        lodsb
        inc     bx
        or      byte ptr es:[bx],al
        add     bx,5
        jmp     short loo2a
loo2af:
        pop     bx
        mov     si,offset resdr
        push    si
        mov     cx,3
loo1b:  lodsb
        cmp     byte ptr es:[bx],255    ; drive is not exist
        jz      lolo2
        and     byte ptr es:[bx],al
lolo2:  inc     bx
        loop    loo1b
        pop     di
        add     bx,4
loo2b:  mov     si,di
        mov     dl,byte ptr es:[bx]
        cmp     dl,255
        jz      loo2bf
        sub     dl,'@'
        xor     dh,dh
        add     si,dx
        lodsb
        inc     bx
        and      byte ptr es:[bx],al
        add     bx,5
        jmp     short loo2b
loo2bf:
        CMP     BYTE PTR CS:NOPARM,0
        JZ      OKMENU
        cmp     byte ptr cs:forcem,0
        jnz     okmenu
        pop     es
        pop     bx
        xor     ax,ax
        RET
OKMENU:
        CALL    SAVESCR
        CALL    BACKGR
        MOV     AX,117H
        PUSH    CS
        POP     DS
        MOV     DX,OFFSET CPR
        CALL    WRITE
        MOV     DX,OFFSET SIGNAT
        MOV     AL,7
        CMP     BYTE PTR CS:EVA,0
        JZ      OTH4
        CALL    WRITE
OTH4:   MOV     CX,0303H
        MOV     DX,164BH
        MOV     BH,50H
        cmp     byte ptr cs:color1,0
        jnz     tgoon
        mov     bh,70h
tgoon:  CALL    WINDOW
        MOV     AH,02H
        XOR     BH,BH
        MOV     DX,1900H
        call    sint10h
        MOV     DX,OFFSET DRTXT
        MOV     AX,0507H
        CALL    WRITE
        MOV     AX,0515H
        MOV     DX,OFFSET DRLET
        MOV     BX,DX
LOOPLT: CALL    WRITE
        INC     BYTE PTR [DS:BX]
        INC     AL
        INC     AL
        CMP     BYTE PTR [DS:BX],91
        JNZ     LOOPLT
        MOV     AX,0707H
        MOV     DX,OFFSET B1TXT
        CALL    WRITE
        INC     AH
        INC     AH
        MOV     DX,OFFSET B2TXT
        CALL    WRITE
        INC     AH
        INC     AH
        MOV     DX,OFFSET B3TXT
        CALL    WRITE
        INC     AH
        INC     AH
        MOV     DX,OFFSET B4TXT
        CALL    WRITE
        ADD     AX,0205H
        MOV     DX,OFFSET B5TXT
        CALL    WRITE
        MOV     DX,OFFSET B6TXT
        MOV     AL,47
        CALL    WRITE
        INC     AH
        INC     AH
        MOV     AL,14
        MOV     DX,OFFSET B7TXT
        CALL    WRITE
        INC     AH
        MOV     DX,OFFSET B9TXT
        CALL    WRITE
        INC     AH
        MOV     DX,OFFSET B11TXT
        CALL    WRITE
        cmp     byte ptr cs:color1,0
        jz      notcol                          ; No color stress
        PUSH    DS
        MOV     AX,0B800H
        MOV     DS,AX
        MOV     BYTE PTR DS:[160*18+37],5AH
        MOV     BYTE PTR DS:[160*19+37],50H
        MOV     BYTE PTR DS:[160*19+83],50H
        MOV     BYTE PTR DS:[160*18+83],5CH
        MOV     BYTE PTR DS:[160*18+79],5CH
        POP     DS
notcol: POP     ES
        POP     BX
        MOV     AH,BYTE PTR ES:BX
        INC     BX
        INC     AH
        INC     AH
        INC     AH
        MOV     BYTE PTR CS:COLDR,AH
        MOV     DI,BX
        MOV     WORD PTR CS:DIBX,BX
        XOR     BX,BX
;        MOV     BX,0413H
        XOR     SI,SI
LOOPKEY:MOV     CX,12
        MOV     AX,1507H
        mov     byte ptr likeno,0
LOOPK1: MOV     DX,OFFSET SPACE5
        CALL    WRITE
        ADD     AL,5
        LOOP    LOOPK1
        MOV     DI,WORD PTR CS:DIBX
        XOR     CH,CH
LOOPM:  MOV     AX,0713H
        ADD     AL,CH
        ADD     AL,CH
        CMP     CH,3
        JC      FL
        MOV     DI,WORD PTR CS:DIBX
        MOV     CL,'@'
        ADD     CL,CH
        INC     DI
FINDLT: ADD     DI,6
        CMP     BYTE PTR ES:[DI],255    ; Finding drive letter
        JNZ     NXXX
        JMP     XXX
NXXX:   CMP     BYTE PTR ES:[DI],CL
        JNZ     FINDLT
        INC     DI
FL:     CMP     BYTE PTR ES:[DI],255    ; Working with it
        JNZ     NXXX2
        JMP     XXX
NXXX2:  MOV     CL,BYTE PTR ES:[DI]     ; Phisical drive
        MOV     DX,OFFSET PLUSG
        MOV     BYTE PTR CS:ATTR,5AH
        OR      SI,SI
        JZ      TST1
        CMP     BL,CH
        JNZ     TST1
        OR      BH,BH
        JNZ     TST1
        XOR     CL,1
        XOR     SI,SI
TST1:
        TEST    CL,1                    ; Indication
        JZ      OK11a
        MOV     DX,OFFSET MINUSG
        MOV     BYTE PTR CS:ATTR,5CH
        jmp     short ok11
ok11a:  mov     byte ptr likeno,1
OK11:   CALL    WRITE
        INC     AH
        INC     AH
        MOV     DX,OFFSET PLUSG
        MOV     BYTE PTR CS:ATTR,5AH
        cmp     byte ptr nbeep,0
        jnz     bo0
        mov     byte ptr nbeep,-1
bo0:    OR      SI,SI
        JZ      TST2
        CMP     BL,CH
        JNZ     TST2
        CMP     BH,1
        JNZ     TST2
        XOR     CL,2
        XOR     SI,SI
        cmp     byte ptr nbeep,-1
        jnz     bo1
        mov     byte ptr nbeep,0
bo1:
TST2:
        TEST    CL,2                    ; Access
        JZ      OK12
        mov     byte ptr likeno,1
        CMP     BYTE PTR CSPEC,CH
        JNZ     NOWAR
        PUSH    AX
        MOV     AX,150BH
        MOV     BYTE PTR CS:ATTR,0DCH
        MOV     DX,OFFSET WARN1
        CALL    WRITE
        ADD     AL,8
        MOV     DX,OFFSET WARN1A
        MOV     BYTE PTR CS:ATTR,05CH
        CALL    WRITE
        CMP     BYTE PTR CS:NBEEP,0
        JNZ     NBB
        MOV     BYTE PTR CS:NBEEP,3
NBB:    POP     AX
NOWAR:  MOV     DX,OFFSET MINUSG        ; No access
        MOV     BYTE PTR CS:ATTR,5CH
        CALL    WRITE
        MOV     DX,OFFSET N_A           ; Therefore - no writing
        INC     AH
        INC     AH
        CALL    WRITE                   ; & formatting
        INC     AH
        INC     AH
        JMP     SHORT OK14
OK12:   CALL    WRITE
        INC     AH
        INC     AH
        MOV     DX,OFFSET PLUSG
        MOV     BYTE PTR CS:ATTR,5AH
        OR      SI,SI
        JZ      TST4
        CMP     BL,CH
        JNZ     TST4
        CMP     BH,2
        JNZ     TST4
        XOR     CL,4
        XOR     SI,SI
TST4:
        TEST    CL,4                    ; Formatting
        JZ      OK13
        mov     byte ptr likeno,1
        MOV     DX,OFFSET MINUSG
        MOV     BYTE PTR CS:ATTR,5CH
OK13:   CALL    WRITE
        INC     AH
        INC     AH
        MOV     DX,OFFSET PLUSG
        MOV     BYTE PTR CS:ATTR,5AH
        OR      SI,SI
        JZ      TST8
        CMP     BL,CH
        JNZ     TST8
        CMP     BH,3
        JNZ     TST8
        XOR     CL,8
        XOR     SI,SI
TST8:
        TEST    CL,8                    ; Writting
        JZ      OK14
        mov     byte ptr likeno,1
        MOV     DX,OFFSET MINUSG
        MOV     BYTE PTR CS:ATTR,5CH
OK14:   CALL    WRITE
        MOV     BYTE PTR CS:ATTR,5EH
        MOV     BYTE PTR ES:[DI],CL
        JMP     SHORT NLOO              ; See forward

XXX:    MOV     BYTE PTR CS:ATTR,50H    ; Not a phisical drive
        MOV     DX,OFFSET XSTR
        CMP     CH,BYTE PTR CS:COLDR
        JNC     OKCDR
        OR      CH,CH
        JZ      OKCDR
        MOV     DX,OFFSET XXSTR
OKCDR:  CALL    WRITE
        INC     AH
        INC     AH
        CALL    WRITE
        INC     AH
        INC     AH
        CALL    WRITE
        INC     AH
        INC     AH
        CALL    WRITE
        MOV     BYTE PTR CS:ATTR,5EH
NLOO:   INC     CH
        INC     DI
        CMP     CH,1BH
        JZ      NLOOPM
        JMP     LOOPM                   ; Loop by drives
NLOOPM: cmp     byte ptr likeno,0
        JNZ     LIKEIS
        cmp     byte ptr cantun,0
        jnz     likeis                  ; go if can't uninstall
        mov     ax,1509h
        mov     byte ptr attr,53h
        mov     dx,offset advise
        call    write
likeis: MOV     AX,0F20H
        MOV     DX,OFFSET NNB
        MOV     BYTE PTR CS:ATTR,5AH
        cmp     byte ptr cs:cantun,2    ; Beep when -q typed but
        jz      cacaun                  ; DiskLamp cannot be quited
        CMP     BH,4
        JNZ     NCH4
        OR      SI,SI
        JZ      NCH4
        CMP     BL,20
        JNZ     BCHW
        cmp     byte ptr cs:cantun,0
        jnz     cantun1
        NOT     BYTE PTR CS:STAY
        jmp     short zerosi
cacaun: mov     byte ptr cs:cantun,1    ; It was 2 there
cantun1:push    ax                      ; Cannot be uninstalled
        push    dx                      ; +++++++
        mov     ax,1507h
        mov     byte ptr attr,5dh
        mov     dx,offset cantxt
        call    write
        mov     byte ptr attr,5ah
        mov     byte ptr cs:nbeep,1     ; Illegal key beep
        pop     dx
        pop     ax
zerosi: XOR     SI,SI
        JMP     SHORT NCH4
BCHW:   XOR     SI,SI
        CMP     BYTE PTR CS:BORDER,255
        JNZ     MAKEFFB
        MOV     BYTE PTR CS:BORDER,1
        JMP     SHORT NOKB
MAKEFFB:MOV     BYTE PTR CS:BORDER,255
NCH4:   CMP     BYTE PTR CS:BORDER,255
        JZ      OKB
NOKB:   MOV     BYTE PTR CS:ATTR,5CH
        MOV     DX,OFFSET FFB
OKB:    CALL    WRITE
        OR      SI,SI
        JZ      OKSI
        XOR     SI,SI
        MOV     BYTE PTR CS:NBEEP,2
        CMP     BYTE PTR CS:STAY,254
        JNZ     OKSI1
        MOV     BYTE PTR CS:STAY,0
OKSI:   CMP     BYTE PTR CS:STAY,254
        JNZ     OKSI1
        INC     BYTE PTR CS:STAY
OKSI1:
        MOV     AX,0F3AH
        MOV     DX,OFFSET RST
        MOV     BYTE PTR CS:ATTR,5AH
        CMP     BYTE PTR CS:STAY,0
        JNZ     HLTING
        MOV     BYTE PTR CS:ATTR,5CH
        MOV     DX,OFFSET HLTM
HLTING: CALL    WRITE
        MOV     BYTE PTR CS:ATTR,5EH
; Or si,si were moved from here
        CMP     BH,4
        JC      LESS4
        PUSHF
        CMP     BL,0AH
        JC      BL1
        MOV     BL,20
        JMP     SHORT GO30
BL1:    MOV     BL,7
        MOV     AX,0F20H
GO30:   POPF
        JNZ     N4
        MOV     DX,OFFSET BIGUP
        CMP     BL,20
        JNZ     GO31
        MOV     DX,OFFSET BBUP
GO31:   SUB     AX,0101H
        MOV     BYTE PTR CS:ATTR,5FH
        CALL    WRITE
        INC     AH
        MOV     DX,OFFSET MIDBOX
        CALL    WRITE
        PUSH    AX
        ADD     AL,4
        CMP     BL,20
        JNZ     GO33
        ADD     AL,5
GO33:   CALL    WRITE
        POP     AX
        INC     AH
        MOV     DX,OFFSET BIGDOWN
        CMP     BL,20
        JNZ     GO32
        MOV     DX,OFFSET BBDOWN
GO32:   CALL    WRITE
        MOV     BYTE PTR CS:ATTR,5EH
        JMP     SHORT GCH
N4:                             ; ???

LESS4:  MOV     AX,0713H
        ADD     AX,BX
        ADD     AX,BX
        SUB     AX,0101H
        MOV     DX,OFFSET UPBOX
        MOV     BYTE PTR CS:ATTR,5FH
        CALL    WRITE
        INC     AH
        MOV     DX,OFFSET MIDBOX
        CALL    WRITE
        INC     AL
        INC     AL
        CALL    WRITE
        DEC     AL
        DEC     AL
        INC     AH
        MOV     DX,OFFSET DOWNBOX
        CALL    WRITE
        MOV     BYTE PTR CS:ATTR,5EH
GCH:    CALL    BEEP
        MOV     DX,AX
        CALL    GETCHAR
        PUSH    AX
        MOV     AX,DX
        MOV     DX,OFFSET SPACE3
        CMP     BH,4
        JC      OKSP3
        MOV     DX,OFFSET SPACE5
OKSP3:  CALL    WRITE
        DEC     AH
        CALL    WRITE
        DEC     AH
        CALL    WRITE
        POP     AX
        OR      AL,AL
        JNZ     N_EXT
        CMP     AH,72
        JNZ     NUP
        OR      BH,BH
        JZ      CANTUP
        DEC     BH
        JMP     LOOPKEY
CANTUP: MOV     BH,4
        JMP     LOOPKEY
NUP:    CMP     AH,80
        JNZ     NDOWN
        CMP     BH,4
        JZ      CNTDOWN
        INC     BH
        JMP     LOOPKEY
CNTDOWN:XOR     BH,BH
        JMP     LOOPKEY
NDOWN:  CMP     AH,75
        JNZ     NLEFT
        OR      BL,BL
        JZ      CNTLEFT
        DEC     BL
        CMP     BH,4
        JNZ     LK
TBL:    CMP     BL,0AH
        JC      MK20
        MOV     BL,7
        JMP     SHORT LK
MK20:   MOV     BL,20
LK:     JMP     LOOPKEY
CNTLEFT:MOV     BL,1AH
        JMP     LOOPKEY
NLEFT:  CMP     AH,77
        JNZ     NRIGHT
        CMP     BL,1AH
        JZ      CTRIGHT
        INC     BL
        CMP     BH,4
        JZ      TBL
        JMP     LOOPKEY
CTRIGHT:XOR     BL,BL
        JMP     LOOPKEY
NRIGHT: JMP     QUSKEY
N_EXT:  CMP     AL,13
        JZ      ET
        CMP     AL,32
        JNZ     NSPC
ET:     DEC     SI
        CMP     BH,4
        JNZ     OKKO
        CMP     BL,20
        JNZ     OKKO
        JMP     LOOPKEY
OKKO:
        cmp     byte ptr cs:cantun,0    ;
        jnz     lk                      ; Cannot be uninstalled
        CMP     BYTE PTR CS:STAY,255
        JZ      LK
        MOV     BYTE PTR CS:STAY,254
        JMP     SHORT LK
NSPC:   CMP     AL,27
        JZ      ALLDONE
QUSKEY: MOV     BYTE PTR CS:NBEEP,1
        JMP     LOOPKEY
ALLDONE:CALL    RESTSCR
        MOV     AH,2
        CMP     BYTE PTR CS:BORDER,255
        JNZ     NOB
        MOV     WORD PTR JMPER,9090H
NOB:    CMP     BYTE PTR CS:STAY,0
        JNZ     RES
        MOV     AH,1
RES:    RET
MENU    ENDP

statusp proc    near            ; output current conditions
        push    bx
        push    dx
        push    ax
        mov     dx,offset borset
        call    outstr
;        mov     dx,offset line
;        call    outstr

;        mov     dx,offset line
;        call    outstr
        mov     dx,offset curbor
        call    outstr
        mov     ax,word ptr myseg
        mov     ds,ax                     ; seg of resident
        mov     bx,cs
        cmp     ax,bx
        jz      nminde                    ; just went resident
        mov     byte ptr cs:mmd,1
nminde:

        mov     bx,offset jmper
        call    mmdchk                  ; check mmd
        MOV     AL,BYTE PTR ds:bx
        MOV     AH,02H                  ; dos fn outchar
        CMP     AL,90H
        JZ      BON1
        MOV     DL,'f'
        INT     21H
        INT     21H
        JMP     SHORT EM1
BON1:   MOV     DL,'n'
        INT     21H
EM1:    MOV     DX,OFFSET nl
        CALL    OUTSTR
        pop     ax
        pop     dx
        pop     bx
        ret
mmd:    db      0               ; 1 if delta must be subtracted from bx
statusp endp

mmdchk  proc near
        cmp     byte ptr cs:mmd,0
        jz      gretmd
        sub     bx,delta
gretmd: ret
mmdchk  endp

ATTR:   DB      1EH
color1: db      ?                       ; Color1
CURPOS: DW      0
DRIVERS:DB      30*4 DUP(0ffH)
STOREDI:DW      ?
QUS:    DB      1AH                     ; Reqest Driver (1a - length)
UNIT:   DB      0                       ; SubUnit number
        DB      4                       ; Command code - read
STATUS: DW      0                       ; Status word
        DB      8 DUP (?)               ; Reserved
        DB      0F8H                    ; Media type = HD
ADDROFS:DW      NLO                     ; Buffer addr offset
ADDRSEG:DW      ?                       ; Buffer addr segment
numsec: DB      1                       ; Number of sectors
SECTOR: DB      0                       ; Sector Number
ANSWER: DD      ?                       ; Answer of Driver
        dd      0

EVA:    DB      0                       ; 1 - EGA, 2 - VGA, 0 - OTHER !!!
cantun  db      0                       ; 1 - cannot be uninstalled
                                        ; 2 - display message about it
saves   dw      ?                       ; es is to be saved here
CSPEC:  DB      255                     ; ComSpec drive 1 - a, etc.
likeno: db      1                       ; 0 - like no disklamp
DIBX:   DW      ?
STAY:   DB      -1
NBEEP:  DB      0
COLDR:  DB      0
nochars:db      0                       ; 1 - do not use EGA/VGA abilities
c_set   db      0                       ; 0 - colour hasn't been changed
forcem: db      0                       ; 1 - force working in menu
myseg:  dw      ?                       ; address of resident code seg
CRCV:                                   ; From here - CRC verifying
SIGNAT: DB      ' ',240,241,242,243,244,245,246,247,0
DRTXT:  DB      'Drive:      ?',0
DRLET:  DB      'A',0
XSTR:   DB      'X',0
XXSTR:  DB      7,0
B1TXT:  DB      'Indication:',0
B2TXT:  DB      'Access:',0
B3TXT:  DB      'Formatting:',0
B4TXT:  DB      'Writing:',0
B5TXT:  DB      'Border indication:',0
B6TXT:  DB      'Escaping:',0
B7TXT:  DB      'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Legend: ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',0
B9TXT:  DB      '    +  Permit option     ',30,' -  Protect option',0
B11TXT: DB      '    X  No such a drive     ',7,'  Uncontrollable drive',0
;B12TXT: DB      'ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼',0
WARN1:  DB      'WARNING!',0
WARN1A: DB      ' Protecting access drive '
DRACC:  DB      'd: you may have to reboot',0
advise: db      'NOTE: You can uninstall DiskLamp'
        db      ' if you want it to do nothing.',0
cantxt: db      'SORRY, DiskLamp cannot be uninstalled because of '
        db      'another resident',0
N_A:    DB      30,0
PLUSG:  DB      '+',0
MINUSG: DB      '-',0
UPBOX:  DB      'ÚÄ¿',0
MIDBOX: DB      '³',0
DOWNBOX:DB      'ÀÄÙ',0
BIGUP:  DB      'ÚÄÄÄ¿',0
BIGDOWN:DB      'ÀÄÄÄÙ',0
SPACE5: DB      '       '
SPACE3: DB      '   ',0
FFB:    DB      'Off',0
NNB:    DB      'On ',0
HLTM:   DB      '  Quit',0
RST:    DB      'Resident',0
BBUP:   DB      'ÚÄÄÄÄÄÄÄÄ¿',0
BBDOWN: DB      'ÀÄÄÄÄÄÄÄÄÙ',0
CPR:    DB      ' DiskLamp Ver 3.17  (c) 1991,92,93 by Sergey Gershtein ',0
NOMEM:  DB      ' ---> ERROR: Not enought memory',7,13,10,'$'
;newset: db      ', new perameters were assumed.',13,10,'$'
ERRS:
        DB      ' ---> ERROR: Memory allocation error occurred'
        DB      7,13,10,'$'
ERR25:
        DB      ' ---> ERROR: Error reading hard disk!',13,10,'$'
LOADING:
        DB      ' DiskLamp is loaded into memory$'
;EMSTR:  DB      '.',13,10,'$'
BORSET: DB      '.$'
;;        Current conditions:',13,10,10
;;     db      ' Drive   Cylinders   Indication   Access   Writing   Formatting '
nl:     db      13,10,'$'
;;line:db      'ÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄÄÄ'
;;        db      13,10,'$'
curbor: db      ' Border is now o$'
BADVER: DB      ', but the version 3.'
VER:    DB      '17.',13,10
        DB      ' To work with it you should run the same'
        DB      ' version.',13,10,'$'
NOPARM: DB      0H                      ; If there IS NO parms then 0
QUIT:   DB      0                       ; 1 means QUIT
DONOTL: DB      ' DiskLamp was not loaded.',13,10,'$'
; From here - reading buffer --------------------->
NLO:    DB      ' DiskLamp was not loaded yet, so it cannot'
        DB      ' be uninstalled.',13,10,'$'
NODRV:  DB      ' ---> ERROR: Disk drivers not found',7,13,10,'$'
cpmono: db      ' SORRY, using monochrome adapter you cannot '
        db      'switch color on.',7,13,10,'$'
BORDER: DB      0
BADCRC: DB      'Exec failure',7,'$'

FREE:
        DB      ,' and has been unistalled.',13,10,'$'

CHVEC:
        DB      ' but cannot be uninstalled.',13,10,'$'

ALREADY:
        DB      ' DiskLamp found in memory$'

BADDOS:
        DB      ' SORRY, Incorrect DOS version, must be '
        DB      '3.0 or newer',13,10,7,'$'
BADSW:
        DB      ' ---> There was an error among the switches you'
        db      ' typed.',7,13,10
HELP:
include dlhelp.asm
BSWT:   DB      '  ---> ERROR: Illegal switches combination.'
        DB      10,7,13,'$'
endcrc:
        IF      DEBUG
EXPER:
        DB      ' WARNING! THIS VERSION OF DISKLAMP IS '
        DB      'EXPERIMENTAL,',13,10
        DB      ' FOR INTERNAL USE ONLY. PLEASE BACKUP '
        db      'YOUR HARD DISK IF YOU USE IT!',13,10,10,'$'
        ENDIF
MOVER:  MOV     CX,OFFSET MOVER         ; Till here - CRC verifying
        CLI
REP     MOVSB
        MOV     AH,50H
        MOV     BX,ES
        INT     21H
        MOV     WORD PTR ENTRY_S,ES
        MOV     WORD PTR ENTRY_O,OFFSET GO6
        JMP     DWORD PTR DS:ENTRY_O

IR:     IRET
ENTRY_O:DW      ?                       ; Offset entry for JMP FAR
ENTRY_S:DW      ?                       ; Segment entry for JMP FAR
VMODE:  DB      0                       ; Current video mode
SCRBUF: DB      ?                       ; Screen restore buffer
setdr:  db      27 dup(0)
resdr:  db      27 dup(255)
;;CODE    ENDS
        END     START
