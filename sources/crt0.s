; crt0.s - エントリポイント
;


; 6502 - CPU の選択
.setcpu     "6502"

; 自動インポート
.autoimport +

; エスケープシーケンスのサポート
.feature    string_escapes


; ファイルの参照
;
.include    "apple2.inc"
.include    "iocs.inc"
.include    "lib.inc"


; ヘッダの定義
;
.segment    "HEADER"

; AppleSingle ヘッダ
;
.proc       Header

    ; header
@header:

    .byte   $00, $05, $16, $00                  ; magic number
    .byte   $00, $02, $00, $00                  ; version number
    .res    16                                  ; filler
    .byte   0, 2                                ; number of entries

    ; entry id 1 - data fork
@id1:

    .byte   0, 0, 0, 1                          ; entry id
    .byte   0                                   ; offset
    .byte   0
    .byte   >(@headerEnd - @header)
    .byte   <(@headerEnd - @header)
    .byte   0                                   ; length
    .byte   0
    .byte   >(__BOOT_LAST__ - __BOOT_START__)
    .byte   <(__BOOT_LAST__ - __BOOT_START__)

@id1End:

    ; entry id 11 - ProDOS file info
@id11:

    .byte   0, 0, 0, 11                         ; entry id
    .byte   0                                   ; offset
    .byte   0
    .byte   >(@id11End - @header)
    .byte   <(@id11End - @header)
    .byte   0                                   ; length
    .byte   0
    .byte   >(@headerEnd - @id11End)
    .byte   <(@headerEnd - @id11End)

@id11End:

    .byte   %00000000, %11000011                ; access - destroy, rename, write, read
    .byte   >__FILETYPE__                       ; file type
    .byte   <__FILETYPE__
    .byte   0                                   ; auxiliary type high
    .byte   0
    .byte   >__BOOT_START__                     ; auxiliary type low
    .byte   <__BOOT_START__

@headerEnd:

.endproc


; コードの定義
;
.segment    "BOOT"

; プログラムのエントリポイント
;
.proc       Boot

    ; 割り込み禁止
    sei
    
    ; BCD モードのクリア
    cld
    
;   ; スタックの初期化
;   ldx     #$ff
;   txs
    
;   ; ゼロページの初期化
;   lda     #$00
;   ldx     #$00
;:
;   sta     <$0000, x
;   inx
;   bne     :-
    
    ; 割り込みの許可
    cli    

    ; IOCS の初期化
    jsr     _IocsInitialize

    ; ライブラリの初期化
    jsr     _LibInitialize

    ; アプリケーションの実行
    ldx     #<@app_arg
    lda     #>@app_arg
    jmp     _IocsBrun

@app_arg:
    .word   @app_name
    .word   __APP0_START__
@app_name:
    .asciiz "APP0"

.endproc


