; apple2.inc - AppleII
; 


; ゼロページ
; 
LOC0                        :=  $00             ; Preset to JMP OpCode ($4c) (3 bytes) ; AKA: GOWARM
LOC1                        :=  $01             ; Preset to BASIC Soft/Warm/Ctrl-C Entry (2 bytes)
LOC2                        :=  $02             ; Used in Shifting Right (ROR) LOC1-4,X (1 byte)
LOC3                        :=  $03             ; = GOSTROUT ; Preset to JMP OpCode ($4c)
LOC4                        :=  $04             ; = GOSTROUT + 1
BAS_USRVEC                  :=  $0a             ; Applesoft USR() Command Vector (JMP) (3 bytes)
BAS_USRPTR                  :=  $0b             ; Applesoft USR() Command Pointer (2 bytes)
CHARAC                      :=  $0d             ; Applesoft String Terminator, Alternate
ENDCHR                      :=  $0e             ; Applesoft String Terminator, Primary
NUMDIM                      :=  $0f             ; Number of Applesoft Array Dimensions
TKNCNTR                     :=  $0f             ; Holds Current Token - $80
DIMFLG                      :=  $10             ; Array Dimension Flag (DIM Call <> 0)
VALTYP                      :=  $11             ; Applesoft Variable Type ($00 = Num, $\lFF = Str)
INTFLG                      :=  $12             ; Negative for Integer Variable (%)
DATAFLG                     :=  $13             ; Applesoft DATA Statement Flag
GARFLG                      :=  $13             ; Applesoft Garbage Collection Flag
SUBFLG                      :=  $14             ; Subscript Flag ($00 = Allowed, $80 = NOT)
INPUTFLG                    :=  $15             ; Input Flag ($00 = INPUT, $40 = GET, $98 = READ)
CPRMASK                     :=  $16             ; Applesoft Compare Mask ((CPRTYP) <- FRMEVL)
SIGNFLG                     :=  $16             ; Applesoft Trig Functions Sign Flag (1 byte)
HSHAPE                      :=  $1a             ; Applesoft Hi-Res Screen Byte Pointer
HCOLOR1                     :=  $1c             ; Applesoft Hi-Res Color Mask
HCOUNT                      :=  $1d             ; Applesoft Hi-Res Line Step (2 bytes)
WNDLFT                      :=  $20             ; Left Column of Scroll Window
WNDWDTH                     :=  $21             ; Width of Scroll Window
WNDTOP                      :=  $22             ; Top of Scroll Window
WNDBTM                      :=  $23             ; Bottom of Scroll Window
CH                          :=  $24             ; Cursor Horizontal Displacement
CV                          :=  $25             ; Cursor Vertical Displacement
GBASL                       :=  $26             ; Graphics Base Address, Low
IWMDATAPTR                  :=  $26             ; IWM: Pointer to Boot1 Data Buffer
GBASH                       :=  $27             ; Graphics Base Address, High
BASL                        :=  $28             ; Text Base Address, Low
BASH                        :=  $29             ; Text Base Address, High
BAS2L                       :=  $2a             ; Scrolling Destination Line Pointer, Low
BAS2H                       :=  $2b             ; Scrolling Destination Line Pointer, High
IWMSLTNDX                   :=  $2b             ; IWM: Slot Number << 4
H2                          :=  $2c             ; Right End of Horizontal Line (HLINE)
LMNEM                       :=  $2c             ; Instruction Display Mnemonic Left Byte
RMNEM                       :=  $2d             ; Instruction Display Mnemonic Right Byte
V2                          :=  $2d             ; Bottom End of Vertical Line (VLINE)
CHKSUM                      :=  $2e             ; Cassette Tape Input Accumulated Checksum
FORMAT                      :=  $2e             ; Disassembler Instruction Display Format
MASK                        :=  $2e             ; Lo-Res Graphics Color Mask (Apple IIc)
LASTIN                      :=  $2f             ; Cassette Input Voltage Change Detector
LENGTH                      :=  $2f             ; Disassembler Instruction Display Length
HMASK                       :=  $30             ; Graphics On-the-Fly Color Bit Mask Safe
MODE                        :=  $31             ; Monitor Mode Flag
INVFLG                      :=  $32             ; Text Mask (Normal = $\lFF, Flash = $7f, Inv = $3f)
PROMPT                      :=  $33             ; Command Prompt Character
YSAV                        :=  $34             ; Y-Reg Safe For Monitor Command Processing
YSAV1                       :=  $35             ; Y-Reg Safe;  Save across JSR VIDOUT/VIDWAIT
CSWL                        :=  $36             ; Character Output Hook, Low
KSWL                        :=  $38             ; Character Input Hook, Low
PCL                         :=  $3a             ; Program Counter Safe, Low
PCH                         :=  $3b             ; Program Counter Safe, High
A1L                         :=  $3c             ; Monitor General Purpose A1-Reg, Low
IWMBITS                     :=  $3c             ; IWM: Temp Storage for Bit Manipulation
A1H                         :=  $3d             ; Monitor General Purpose A1-Reg, High
IWMSECTOR                   :=  $3d             ; IWM: Sector to Read
A2L                         :=  $3e             ; Monitor General Purpose A2-Reg, Low
A2H                         :=  $3f             ; Monitor General Purpose A2-Reg, High
A3L                         :=  $40             ; Monitor General Purpose A3-Reg, Low
IWMTRKFND                   :=  $40             ; IWM: Track Found
A3H                         :=  $41             ; Monitor General Purpose A3-Reg, High
IWMTRACK                    :=  $41             ; IWM: Track to Read
A4L                         :=  $42             ; Monitor General Purpose A4-Reg, Low
A4H                         :=  $43             ; Monitor General Purpose A4-Reg, High
A5L                         :=  $44             ; Monitor General Purpose A5-Reg, Low
ACC                         :=  $45             ; A-Reg Safe (Accumulator) (Destroys A5H!)
XREG                        :=  $46             ; X-Reg Safe (Index Register X)
YREG                        :=  $47             ; Y-Reg Safe (Index Register Y)
STATUS                      :=  $48             ; P-Reg Safe (Status Register)
SPNT                        :=  $49             ; S-Reg Safe (Stack Pointer)
SAVE6502                    :=  $4a             ; 6502 Registers Safe (Save Locations) + 5
RNDL                        :=  $4e             ; Keyin Random Counter Value, Low
RNDH                        :=  $4f             ; Keyin Random Counter Value, High
LINNUM                      :=  $50             ; Applesoft Line Number (2 bytes)
TEMPPT                      :=  $52             ; SD Stack: Next Temp Descriptor Ptr (1 byte)
LASTPT                      :=  $53             ; SD Stack: Last Temp Descriptor Ptr (1 byte)
TEMPST                      :=  $55             ; ~$5d: Holds up to 3 Descriptors (9 bytes)
INDEX                       :=  $5e             ; Move Strings Index Pointer (2 bytes)
LINPTR                      :=  $5e             ; Move Strings Line Pointer (2 bytes)
SRCPTR                      :=  $5e             ; Move Strings Source Pointer (2 bytes)
STKPTR                      :=  $5e             ; Move Strings Stack Pointer (2 bytes)
DSTPTR                      :=  $60             ; Move Strings Destination Pointer (2 bytes)
RESULT                      :=  $62             ; ~$66: FP Result of Last Mult* or Div/ (5 bytes)
TXTTAB                      :=  $67             ; Applesoft Start of Program Pointer (2 bytes)
VARTAB                      :=  $69             ; Applesoft Start of Variables Pointer (2 bytes)
ARYTAB                      :=  $6b             ; Applesoft Start of Arrays Pointer (2 bytes)
STREND                      :=  $6d             ; End of Variables & Pointers Storage (2 bytes)
FRETOP                      :=  $6f             ; FreSpcEnd & StringStorageStart Ptr (2 bytes)
FRESPC                      :=  $71             ; Applesoft String Routines' Temp Ptr (2 bytes)
MEMSIZ                      :=  $73             ; Applesoft End of String Space (HIMEM) (2 bytes)
CURLIN                      :=  $75             ; Current Applesoft Line Number (2 bytes)
OLDLIN                      :=  $77             ; Last Applesoft Line Executed, Address (2 bytes)
OLDTEXT                     :=  $79             ; Applesoft Old Text Pointer (2 bytes)
DATLIN                      :=  $7b             ; Line Number of Current DATA Statement (2 bytes)
DATPTR                      :=  $7d             ; Address of Current DATA Statement (2 bytes)
INPTR                       :=  $7f             ; Applesoft Input Pointer (2 bytes)
VARNAM                      :=  $81             ; Last-Used Variable Name Pointer (2 bytes)
VARPTR                      :=  $83             ; Last-Used Variable Value Pointer (2 bytes)
FORPTR                      :=  $85             ; Applesoft General Purpose Pointer (2 bytes)
LASTOP                      :=  $87             ; Applesoft FRMEVL Scratch Flag (1 byte)
TXPSV                       :=  $87             ; TXTPTR Safe: Used in INPUT routine (2 bytes)
CPRTYP                      :=  $89             ; Applesoft FRMEVL Compare Flag (>, = ,<) (1 byte)
FNCNAM                      :=  $8a             ; Applesoft Function Name Pointer (2 bytes)
TEMP3                       :=  $8a             ; ~$8e: Applesoft Temporary FAC #3 (5 bytes)
DSCPTR                      :=  $8c             ; Applesoft String Descriptor Pointer (2 bytes)
DSCLEN                      :=  $8f             ; Applesoft String Descriptor Length (1 byte)
JMPADRS                     :=  $90             ; Applesoft Jump (from ZP) to <Address> (3 bytes)
GARLEN                      :=  $91             ; Applesoft Garbage Collection Length (1 byte)
ARGEXT                      :=  $92             ; ARG Extra Precision Byte for FP Op's (1 byte)
TEMP1                       :=  $93             ; Applesoft FP Math Register (1 byte)
ARYPTR                      :=  $94             ; Applesoft Array Pointer (2 bytes)
HIGHDS                      :=  $94             ; Copy Ptr: Highest Destination Adrs +1 (2 bytes)
HIGHTR                      :=  $96             ; Copy Ptr: Highest Source Address +1 (2 bytes)
TEMP2                       :=  $98             ; Applesoft FP Math Register (2 bytes)
INDX                        :=  $99             ; Used by Applesoft Array Returns (1 byte)
TMPEXP                      :=  $99             ; Used in Applesoft FIN (Eval) Routine (1 byte)
EXPON                       :=  $9a             ; Applesoft Exponent Safe (1 byte)
DPFLG                       :=  $9b             ; Applesoft Decimal Point Flag (1 byte)
LOWTR                       :=  $9b             ; Copy Ptr: Lowest Source Address (2 bytes)
EXPSGN                      :=  $9c             ; Applesoft Exponent Sign Safe (1 byte)
DSCTMP                      :=  $9d             ; Temp Descriptor, String Length (1 byte)
FAC                         :=  $9d             ; Primary Floating Point Accumulator (6 bytes)
DSCTMPL                     :=  $9e             ; Temp Descriptor, String Addr, Low (1 byte)
DSCTMPH                     :=  $9f             ; Temp Descriptor, String Addr, High (1 byte)
TMPVPTR                     :=  $a0             ; Temporary Variable Pointer (FAC+3,4) (2 bytes)
FACSIGN                     :=  $a2             ; Primary FAC Unpacked Sign (msb) (1 byte)
SERLEN                      :=  $a3             ; Holds Length of Series-1 (1 byte)
SHFTSGNX                    :=  $a4             ; FAC Right Shift Sign Extension (1 byte)
ARG                         :=  $a5             ; Secondary Floating Point Accumulator (6 bytes)
ARGVPTR                     :=  $a8             ; Applesoft Temporary Variable Pointer (2 bytes)
ARGSIGN                     :=  $aA             ; Secondary FAC Unpacked Sign (msb) (1 byte)
SGNCPR                      :=  $aB             ; Applesoft Sign Flag for Comparing (1 byte)
STRNG1                      :=  $aB             ; Applesoft String Pointer #1 (2 bytes)
FACEXT                      :=  $aC             ; FAC Extra Precision Byte for FP Op's (1 byte)
SERPTR                      :=  $aD             ; Pointer to Series Data in FP Op's (2 bytes)
STRNG2                      :=  $aD             ; Applesoft String Pointer #2 (2 bytes)
PRGEND                      :=  $aF             ; Applesoft End of Program Pointer (2 bytes)
CHRGET                      :=  $b1             ; ~$c8: Get Next Char/Token ZP-Routine (24 bytes)
CHRGOT                      :=  $b7             ; ~$c8: CHRGET w/o advancing TXTPTR (18 bytes)
TXTPTR                      :=  $b8             ; CHRGET's Next Char/Token Pointer (2 bytes)
RNDSEED                     :=  $c9             ; ~$cD: Applesoft FP Random Number Seed (5 bytes)
HGRDX                       :=  $d0             ; Hi-Res Drawing Horizontal X-Position (2 bytes)
HGRDY                       :=  $d2             ; Hi-Res Drawing  Vertical  Y-Position (1 byte)
HGRQUAD                     :=  $d3             ; Hi-Res Graphics Drawing Quadrant (1 byte)
HGRE                        :=  $d4             ; Used in Hi-Res Graphics Drawing (2 bytes)
AUTORUN                     :=  $d6             ; AutoRun/Lock: No User Access If > = $80 (1 byte)
ERRFLG                      :=  $d8             ; ONERR GOTO is Active If = #$80 (1 byte)
ERRLIN                      :=  $dA             ; Applesoft Line# Where ERROR Occurred (2 bytes)
ERRPOS                      :=  $dC             ; Applesoft Error Handler TXTPTR Safe (2 bytes)
ERRNUM                      :=  $dE             ; Current Applesoft Error Number Safe (1 byte)
ERRSTK                      :=  $dF             ; Applesoft Stack Ptr before Error Safe (1 byte)
HGRX                        :=  $e0             ; Hi-Res Graphics X-Coordinate (H-POSN) (2 bytes)
HGRY                        :=  $e2             ; Hi-Res Graphics Y-Coordinate (V-POSN) (2 bytes)
HGRCOLOR                    :=  $e4             ; Hi-Res Graphics Color Flag/Safe (1 byte)
HGRHORIZ                    :=  $e5             ; Hi-Res Byte Horiz. Index from GBASL,H (1 byte)
HGRPAGE                     :=  $e6             ; Hi-Res Base Page (HPg1 = $20, HPg2 = $40) (1 byte)
HGRSCALE                    :=  $e7             ; Hi-Res Graphics Drawing Scale Factor (1 byte)
HGRSHPTR                    :=  $e8             ; Hi-Res Graphics Shape Pointer (2 bytes)
HGRCLSN                     :=  $eA             ; Hi-Res Graphics Collision Counter (2 bytes)
FIRST                       :=  $f0             ; Lo-Res Plot Coordinates (1 byte)
SPDBYT                      :=  $f1             ; Text Output Speed Limiter (1 byte)
TRCFLG                      :=  $f2             ; Trace OFF/ON Flag (<128/>127)~(bit-7) (1 byte)
FLASHBIT                    :=  $f3             ; Flash Text? (Flash = $40, Else = $00) (1 byte)
TXTPSV                      :=  $f4             ; Applesoft Char/Token Pointer Safe (2 bytes)
CURLSV                      :=  $f6             ; Applesoft Current Line Safe (2 bytes)
REMSTK                      :=  $f8             ; Stack Ptr Before Each Statement Safe (1 byte)
HGRROT                      :=  $f9             ; Hi-Res Graphics Rotation Value (1 byte)
FOUTBUFF                    :=  $fF             ; Start String at STACK-1 ($fF) (1 byte)

; 入力バッファ
;
INBUFF                      :=  $0200           ; Input Buffer [Range:(512~767)=($200~$2FF)]

; ベクタ
;
GOBRKV                      :=  $03ef           ; Set by DOS to JMP for User BRK Vector
DOSWARM                     :=  $03d0           ; DOS warmstart vector
DOSCOLD                     :=  $03d3           ; DOS coldstart vector
DOSCALL                     :=  $03d6           ; DOS file manager subroutine vector
BRKV                        :=  $03f0           ; Break vector
SOFTEV                      :=  $03f2           ; Vector for warm start
PWREDUP                     :=  $03f4           ; This must be = EOR #$a5 of SOFTEV + 1
AMPERV                      :=  $03f5           ; Ampersand (&) Command Vector (JMP)
USRADDR                     :=  $03f8           ; Monitor User Command (Ctrl-Y) Vector
NMI                         :=  $03fb           ; Non-Maskable Interrupt (NMI) Vector
IRQADDR                     :=  $03fe           ; Address of IRQ Handler

; テキスト
;
LINE1                       :=  $0400           ; Text Screen Start Address
LINE2                       :=  $0800           ; Text Screen Start Address

; ハイレゾグラフィッック
;
HGR1SCRN                    :=  $2000           ; Hi-Res Screen Pg.1 (Base-Address)
HGR2SCRN                    :=  $4000           ; Hi-Res Screen Pg.2 (Base-Address)

; キーボード入力
;
KBD                         :=  $c000           ; Read keyboard
KBDSTRB                     :=  $c010           ; Clear keyboard strobe

; 80 桁モード
;
CLR80COL                    :=  $c000           ; Disable 80 column store
SET80COL                    :=  $c001           ; Enable 80 column store
RD80COL                     :=  $c018           ; >127 if 80 column store enabled
RD80VID                     :=  $c01f           ; >127 if 80 column video enabled

; キャラクタセット
;
CLRALTCHAR                  :=  $c00e           ; Normal Apple II char set
SETALTCHAR                  :=  $c00f           ; Norm/inv LC, no flash
ALTCHARSET                  :=  $c01e           ; >127 if alt charset switched in

; ランゲージカード
;
RDLCBNK2                    :=  $c011           ; >127 if LC bank 2 in use
RDLCRAM                     :=  $c012           ; >127 if LC is read enabled
ROMIN                       :=  $c081           ; Swap in D000-FFFF ROM
LCBANK2                     :=  $c083           ; Swap in LC bank 2
LCBANK1                     :=  $c08b           ; Swap in LC bank 1

; V ブランク
;
RDVBLBAR                    :=  $c019           ; >127 if not vertical blanking
RDVBLMSK                    :=  $c041           ; >127 if VBL interrupts enabled
DISVBL                      :=  $c05a           ; Disable VBL interrupts
ENVBL                       :=  $c05b           ; Enable VBL interrupts

; ビデオモード
;
TXTCLR                      :=  $c050           ; Display graphics
TXTSET                      :=  $c051           ; Display text
MIXCLR                      :=  $c052           ; Disable 4 lines of text
MIXSET                      :=  $c053           ; Enable 4 lines of text
LOWSCR                      :=  $c054           ; Page 1
HISCR                       :=  $c055           ; Page 2
LORES                       :=  $c056           ; Lores graphics
HIRES                       :=  $c057           ; Hires graphics
DHIRESON                    :=  $c05e           ; Enable double-width graphics
DHIRESOFF                   :=  $c05f           ; Disable double-width graphics

; サウンド
;
SPEAKER                     :=  $c030           ; Toggle speaker 

; ゲームコントローラ
;
TAPEIN                      :=  $c060           ; Read casette input / Switch input 3
BUTN0                       :=  $c061           ; Switch input 0 / Open-Apple key
BUTN1                       :=  $c062           ; Switch input 1 / Closed-Apple key
BUTN2                       :=  $c063           ; Switch input 2 / Shift key
PADDL0                      :=  $c064           ; Analog input 0
PADDL1                      :=  $c065           ; Analog input 1
PADDL2                      :=  $c066           ; Analog input 2
PADDL3                      :=  $c067           ; Analog input 3
PTRIG                       :=  $c070           ; Analog input reset

; 入出力装置 / Input/Output Unit
;
IOUDISON                    :=  $c07e           ; Disable IOU
IOUDISOFF                   :=  $c07f           ; Enable IOU

; AppleII の制御
;
CYAREG                      :=  $c036           ; Bits 0-3 = disk detect, 4 = shadow all banks, 7 = fast

; モニター ROM
;
PLOT                        :=  $f800           ; Plot a point at line (A) col. (Y) leaving GBASL,H and MASK set.
HLINE                       :=  $f819           ; Draw horizontal line at (A) from (Y) thru (H2), left to right.
VLINE                       :=  $f828           ; Plot vertical line at (Y) from (A) thru (V2).
CLRSCR                      :=  $f832           ; Clear full (48 lines) screen.
CLRTOP                      :=  $f836           ; Clear graphics area (40 lines).
NXTCOL                      :=  $f85f           ; Change COLOR to (COLOR) + 3.
SETCOL                      :=  $f864           ; Set COLOR for following points to (A).
SCRN                        :=  $f871           ; Load to A color of point (A),(Y).
PRNTYX                      :=  $f940           ; Print hex of Y,X regs.
PRNTAX                      :=  $f941           ; Print hex of A,X regs.
PRNTX                       :=  $f944           ; Print hex of X-reg.
PRBLNK                      :=  $f948           ; Print three blanks thru COUT.
PRBL2                       :=  $f94a           ; Print (X) blanks thru COUT.
PREAD                       :=  $fb1e           ; Read paddle (X) into (Y-reg).
BELL1                       :=  $fbd9           ; If (A)=$87 wait .01 seconds, then sound the "bell". Else, RTS.
WAIT                        :=  $fca8           ; Constructed in such a manner that the length of time spent in the loop varies geometrically with the entry A-reg. 
RDKEY                       :=  $fd0c           ; Set screen to blink at cursor saving original character in the A-reg from (BASL),Y.
KEYIN                       :=  $fd1b           ; Increment random number at RNDL,H while polling keyboard register.
RDCHAR                      :=  $fd35           ; Call RDKEY to get next character into A-reg.
GETLNZ                      :=  $fd67           ; Print carriage return thru COUT.
GETLN                       :=  $fd6a           ; Load PROMPT into A-reg.
GETLN1                      :=  $fd6f           ; Without PROMPT into A-reg.
CROUT1                      :=  $fd8b           ; Clear to EOL and CROUT.
CROUT                       :=  $fd8e           ; Print carriage return thru COUT.
PRBYTE                      :=  $fdda           ; Print A-reg as 2 hex nibbles.
PRHEX                       :=  $fde3           ; Print low nibble of A as hex char.
COUT                        :=  $fded           ; Write byte in A to screen at CV, CH.
COUT1                       :=  $fdf0           ; Write byte in A-reg to screen at cursor (CV),(CH) using INVFLG and supporting cursor move.
SETINV                      :=  $fe80           ; Set INVFLG to $3F inverse video.
SETNORM                     :=  $fe84           ; Set INVFLG to $FF normal video.
PRERR                       :=  $ff2d           ; Print thru COUT "ERR" and bell code.
BELL                        :=  $ff3a           ; Print bell code ($87) thru COUT.
RESTORE                     :=  $ff3f           ; Restore 6502 regs A,X,Y,P from $45-$48.
SAVE                        :=  $ff4a           ; Save 6502 regs A,X,Y,P,S at $45-$49.

; DOS 3.3
;

; 

; デフォルト
DOS_DEFAULT_VOLUME          :=  $aa66
DOS_DEFAULT_DRIVE           :=  $aa68
DOS_DEFAULT_SLOT            :=  $aa6a

; DOS BUFFER
.struct DosBuffer
    filename                .byte   30
    workarea_address        .word
    list_sector_address     .word
    data_sector_address     .word
    next_buffer_address     .word
.endstruct

; FILE MANAGER PARAMETER LIST
.struct DosParam
    call                    .byte
    subcall                 .byte
    params                  .byte   8
    return_code             .byte
    _0b                     .byte
    workarea_address        .word
    list_sector_address     .word
    data_sector_address     .word
.endstruct
.struct DosParamCatalog
    call                    .byte
    _01                     .byte
    _02                     .byte
    _03                     .byte
    _04                     .byte
    drive                   .byte
    slot                    .byte
    _07                     .byte
    _08                     .byte
    _09                     .byte
    return_code             .byte
    _0b                     .byte
    workarea_address        .word
    _0e                     .byte
    _0f                     .byte
    _10                     .byte
    _11                     .byte
.endstruct
.struct DosParamOpen
    call                    .byte
    _01                     .byte
    record_length           .word
    volume                  .byte
    drive                   .byte
    slot                    .byte
    filetype                .byte
    filename_address        .word
    return_code             .byte
    _0b                     .byte
    workarea_address        .word
    list_sector_address     .word
    data_sector_address     .word
.endstruct
.struct DosParamClose
    call                    .byte
    _01                     .byte
    _02                     .byte
    _03                     .byte
    _04                     .byte
    _05                     .byte
    _06                     .byte
    _07                     .byte
    _08                     .byte
    _09                     .byte
    return_code             .byte
    _0b                     .byte
    workarea_address        .word
    list_sector_address     .word
    data_sector_address     .word
.endstruct
.struct DosParamRead
    call                    .byte
    subcall                 .byte
    record_number           .word
    byte_offset             .word
    read_length             .word
    read_address            .word
    return_code             .byte
    _0b                     .byte
    workarea_address        .word
    list_sector_address     .word
    data_sector_address     .word
.endstruct
.struct DosParamWrite
    call                    .byte
    subcall                 .byte
    record_number           .word
    byte_offset             .word
    write_length            .word
    write_address           .word
    return_code             .byte
    _0b                     .byte
    workarea_address        .word
    list_sector_address     .word
    data_sector_address     .word
.endstruct
