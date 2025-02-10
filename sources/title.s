; title.s - タイトル
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
.include    "app0.inc"
.include    "title.inc"


; コードの定義
;
.segment    "APP0"

; タイトルのエントリポイント
;
.global _TitleEntry
.proc   _TitleEntry

    ; アプリケーションの初期化

;   ; VRAM のクリア
;   jsr     _IocsClearVram

    ; タイトルの初期化
    lda     #$ff
    sta     title + Title::file

    ; 処理の設定
    lda     #<TitleIdle
    sta     APP0_0_PROC_L
    lda     #>TitleIdle
    sta     APP0_0_PROC_H
    lda     #$00
    sta     APP0_0_STATE

    ; 終了
    rts

.endproc

; タイトルを待機する
;
.proc   TitleIdle

    ; 初期化
    lda     APP0_0_STATE
    bne     @initialized

;   ; VRAM のクリア
;   jsr     _IocsClearVram

    ; イメージの読み込み
    ldx     #<@load_arg
    lda     #>@load_arg
    jsr     _IocsBload

    ; ファイルの確認
    jsr     _WorldAccess
    bne     :+
    jsr     _UserAccess
:
    sta     title + Title::file

    ; メニューの描画
    ldx     #<@draw_new_game_arg
    lda     #>@draw_new_game_arg
    jsr     _IocsDrawString
    lda     title + Title::file
    bne     :+
    ldx     #<@draw_continue_arg
    lda     #>@draw_continue_arg
    jsr     _IocsDrawString
:

    ; 初期化の完了
    inc     APP0_0_STATE
@initialized:

    ; キー入力
    lda     IOCS_0_KEYCODE
    cmp     #'N'
    beq     @new_game
    cmp     #'C'
    beq     @continue
    jmp     @end

    ; NEW GAME
@new_game:
    ldx     #<@erase_continue_arg
    lda     #>@erase_continue_arg
    jsr     _IocsDrawString
    jsr     @beep
    lda     #$01
    sta     APP0_0_BRUN
    jmp     @end

    ; CONTINUE
@continue:
    lda     title + Title::file
    bne     @end
    ldx     #<@erase_new_game_arg
    lda     #>@erase_new_game_arg
    jsr     _IocsDrawString
    jsr     @beep
    lda     #$02
    sta     APP0_0_BRUN
;   jmp     @end

    ; 終了
@end:
    rts

    ; BEEP
@beep:
    ldx     #IOCS_BEEP_PI
    lda     #IOCS_BEEP_L16
    jsr     _IocsBeepNote
    ldx     #IOCS_BEEP_PO
    lda     #IOCS_BEEP_L16
    jsr     _IocsBeepNote
    rts

; 読み込みの引数
@load_arg:
    .word   @load_name
    .word   $2000
@load_name:
    .asciiz "TITLE"

; 描画の引数
@draw_new_game_arg:
    .byte   $05, $10
    .word   @draw_new_game_string
@draw_new_game_string:
    .asciiz "[N]EW GAME"
@draw_continue_arg:
    .byte   $05, $12
    .word   @draw_continue_string
@draw_continue_string:
    .asciiz "[C]ONTINUE"
@erase_new_game_arg:
    .byte   $05, $10
    .word   @erase_new_game_string
@erase_new_game_string:
    .asciiz "          "
@erase_continue_arg:
    .byte   $05, $12
    .word   @erase_continue_string
@erase_continue_string:
    .asciiz "          "

.endproc


; データの定義
;
.segment    "BSS"

; タイトルの情報
;
title:

    .tag    Title

