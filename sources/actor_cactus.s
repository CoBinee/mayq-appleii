; actor_cactus.s - サボテン
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
.include    "world.inc"
.include    "user.inc"
.include    "app2.inc"
.include    "game.inc"
.include    "actor.inc"


; コードの定義
;
.segment    "APP2"

; サボテンを読み込む
;
.global _ActorCactusLoad
.proc   _ActorCactusLoad

    ; IN
    ;   x = アクタの参照

    ; イベントの位置への配置
    lda     _game_event_x
    asl     a
    sta     _actor_x, x
    lda     _game_event_y
    asl     a
    sta     _actor_y, x

    ; セルの設定
    txa
    pha
    ldx     _game_event_x
    ldy     _game_event_y
    lda     #WORLD_CELL_SAND
    jsr     _WorldSetAreaCell
    pla
    tax

    ; 最初の描画
    jsr     _ActorDraw2x2

    ; 終了
    rts

.endproc

; サボテンを破棄する
;
.global _ActorCactusUnload
.proc   _ActorCactusUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 死亡の判定
    cmp     #$ff
    bne     @end

    ; アクタの保存
    txa
    pha

    ; 薬の取得
    lda     #USER_ITEM_TALISMAN
    jsr     _GameAddItem

    ; イベントの進行
    ldx     _game_area
    inc     _user_event, x

    ; アクタの復帰
    pla
    tax

    ; 終了
@end:
    rts

.endproc


; データの定義
;
.segment    "BSS"

