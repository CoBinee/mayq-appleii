; user.s - ユーザ
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
.include    "user.inc"


; コードの定義
;
.segment    "BOOT"

; ユーザを初期化する
;
.global _UserInitialize
.proc   _UserInitialize

    ; ユーザの初期化
    
    ; 体力の設定
    lda     #USER_LIFE_DEFAULT
    sta     _user_life
    sta     _user_life_maximum

    ; 強さの設定
    lda     #USER_STRENGTH_DEFAULT
    sta     _user_strength

    ; 経験値の設定
    lda     #USER_EXPERIENCE_DEFAULT
    sta     _user_experience

    ; アイテムの設定
    lda     #$00
    tax
:
    sta     _user_item, x
    inx
    cpx     #USER_ITEM_SIZE
    bne     :-

    ; イベントの設定
    lda     #$00
    tax
:
    sta     _user_event, x
    inx
    cpx     #USER_EVENT_SIZE
    bne     :-

    ; 終了
    rts

.endproc

; ユーザを読み込む
;
.global _UserLoad
.proc   _UserLoad

    ; バイナリの読み込み
    ldx     #<@load_arg
    lda     #>@load_arg
    jsr     _IocsBload

    ; ユーザの開始
    jsr     _UserStart

    ; 終了
    rts

; 読み込みの引数
@load_arg:
    .word   user_file_name
    .word   user_file_head

.endproc

; ユーザを書き込む
;
.global _UserSave
.proc   _UserSave

    ; バイナリの書き込み
    ldx     #<@save_arg
    lda     #>@save_arg
    jsr     _IocsBsave

    ; 終了
    rts

; 書き込みの引数
@save_arg:
    .word   user_file_name
    .word   user_file_head
    .word   user_file_tail - user_file_head

.endproc

; ユーザの存在を確認する
;
.global _UserAccess
.proc   _UserAccess

    ; OUT
    ;   a = 0...ファイルはある / else...ファイルはない

    ; ファイルの存在確認
    ldx     #<@access_arg
    lda     #>@access_arg
    jsr     _IocsAccess

    ; 終了
    rts

; 存在確認の引数
@access_arg:
    .word   user_file_name

.endproc

; ユーザを開始する
;
.global _UserStart
.proc   _UserStart

    ; 位置の設定
    lda     #USER_X_START
    sta     _user_x
    lda     #USER_Y_START
    sta     _user_y
    lda     #USER_DIRECTION_START
    sta     _user_direction

    ; 体力の設定
    lda     _user_life_maximum
    sta     _user_life

    ; 終了
    rts

.endproc

; 経験値を加算する
;
.global _UserAddExperience
.proc   _UserAddExperience

    ; IN
    ;   a = 経験値
    ; OUT
    ;   a = 0...レベルアップなし / else...レベルアップ

    ; 強さの確認
    ldy     _user_strength
    cpy     #USER_STRENGTH_MAXIMUM
    beq     @stay

    ; 経験値の加算
    clc
    adc     _user_experience
    sta     _user_experience
    cmp     #USER_EXPERIENCE_MAXIMUM
    bcc     @stay

    ; レベルアップ
    inc     _user_strength
    lda     #$00
    sta     _user_experience
    lda     _user_life_maximum
    clc
    adc     #USER_LIFE_LEVELUP
    sta     _user_life_maximum
    lda     #$01
    jmp     @end

    ; レベルアップなし
@stay:
    lda     #$00

    ; 終了
@end:
    rts

.endproc

; アイテムを描画する
;
.global _UserDrawItem
.proc   _UserDrawItem

    ; IN
    ;   x = X 位置
    ;   y = Y 位置
    ;   a = アイテム

    ; アイテムの描画
    cmp     #USER_ITEM_SIZE
    bcs     @null
    stx     @item_arg + $0000
    sty     @item_arg + $0001
    asl     a
    asl     a
    sta     @item_arg + $0004
    ldx     #<@item_arg
    lda     #>@item_arg
    jsr     _IocsDraw7x8Pattern
    inc     @item_arg + $0000
    inc     @item_arg + $0004
    ldx     #<@item_arg
    lda     #>@item_arg
    jsr     _IocsDraw7x8Pattern
    dec     @item_arg + $0000
    inc     @item_arg + $0001
    inc     @item_arg + $0004
    ldx     #<@item_arg
    lda     #>@item_arg
    jsr     _IocsDraw7x8Pattern
    inc     @item_arg + $0000
    inc     @item_arg + $0004
    ldx     #<@item_arg
    lda     #>@item_arg
    jsr     _IocsDraw7x8Pattern
    jmp     @end

    ; 空の描画
@null:
    stx     @null_arg + $0000
    sty     @null_arg + $0001
    ldx     #<@null_arg
    lda     #>@null_arg
    jsr     _IocsDrawString
;   jmp     @end

    ; 終了
@end:
    rts

; 描画の引数
@item_arg:
    .byte   $00, $00
    .word   _user_item_tileset
    .byte   $00
@null_arg:
    .byte   $00, $00
    .word   @null_string
@null_string:
    .asciiz "  \n  "

.endproc

; ファイル名
;
user_file_name:

    .asciiz "USER"

; アイテム
;
.global _user_item_tileset
_user_item_tileset:

.incbin     "resources/sprites/item.ts"


; データの定義
;
.segment    "BSS"

; ファイル
;

; ファイルの先頭
user_file_head:

; ID
.global _user_id
_user_id:

    .res    USER_ID_SIZE

; 体力
.global _user_life
_user_life:

    .res    USER_LIFE_SIZE

.global _user_life_maximum
_user_life_maximum:

    .res    USER_LIFE_SIZE

; 強さ
.global _user_strength
_user_strength:

    .res    USER_STRENGTH_SIZE

; 経験値
.global _user_experience
_user_experience:

    .res    USER_EXPERIENCE_SIZE

; アイテム
;
.global _user_item
_user_item:

    .res    USER_ITEM_SIZE

; イベント
;
.global _user_event
_user_event:

    .res    USER_EVENT_SIZE

; ファイルの末端
user_file_tail:

; ファイル外のユーザの情報
;

; 位置
.global _user_x
_user_x:

    .res    $01

.global _user_y
_user_y:

    .res    $01

; 向き
.global _user_direction
_user_direction:

    .res    $01
