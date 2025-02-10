; app1.s - アプリケーション／ニューゲーム
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
.include    "app1.inc"


; コードの定義
;
.segment    "APP1"

; アプリケーションのエントリポイント
;
.proc   AppEntry

    ; アプリケーションの初期化

;   ; VRAM のクリア
;   jsr     _IocsClearVram

    ; 画面モードの設定
    sta     HIRES
    sta     LOWSCR
    sta     MIXCLR
    sta     TXTCLR

    ; ゼロページのクリア
    ldy     #APP1_0
    lda     #$00
:
    sta     $00, y
    iny
    bne     :-

    ; アプリケーションの設定
    lda     #$01
    sta     APP1_0_BRUN
    
    ; 処理の設定
    lda     #<_NewEntry
    sta     APP1_0_PROC_L
    lda     #>_NewEntry
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

.endproc

; アプリケーションを更新する
;
.proc   AppUpdate

    ; 処理の繰り返し
@loop:

    ; IOCS の更新
    jsr     _IocsUpdate

    ; 処理の実行
    lda     #>(:+ - $0001)
    pha
    lda     #<(:+ - $0001)
    pha
    jmp     (APP1_0_PROC)
:

    ; デバッグ表示
    lda     IOCS_0_KEYCODE
    cmp     #$09
    bne     :++
    lda     @debug
    bne     :+
    sta     MIXSET
    lda     #$01
    sta     @debug
    jmp     :++
:
    sta     MIXCLR
    lda     #$00
    sta     @debug
:

    ; ループ
    lda     APP1_0_BRUN
    cmp     #$01
    beq     @loop

    ; 次のアプリケーションの実行
    clc
    adc     #'0'
    sta     @app_name + $0003
    ldx     #<@app_arg
    lda     #>@app_arg
    jmp     _IocsBrun

; APP の引数
@app_arg:
    .word   @app_name
    .word   __APP1_START__
@app_name:
    .asciiz "APP1"

; デバッグ
@debug:
    .byte   $00

.endproc


; データの定義
;
.segment    "BSS"

