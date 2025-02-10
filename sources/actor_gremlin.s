; actor_gremlin.s - グレムリン
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

; グレムリンを読み込む
;
.global _ActorGremlinLoad
.proc   _ActorGremlinLoad

    ; IN
    ;   x = アクタの参照

    ; ランダムな配置
    jsr     _ActorRandomPosition

    ; 描画の設定
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_DIRECTION
    sta     _actor_draw, x

    ; 反撃の設定
    lda     #ACTOR_GREMLIN_COUNTER
    sta     _actor_param_0, x

    ; 方向転換の設定
    lda     #$02
    sta     _actor_param_1, x

;   ; 詠唱の設定
;   lda     #$00
;   sta     _actor_param_2, x

    ; 待機テーブルの設定
    lda     #<@step_stay
    sta     _actor_param_4, x
    lda     #>@step_stay
    sta     _actor_param_5, x

    ; 歩行テーブルの設定
    lda     #<@step_walk
    sta     _actor_param_6, x
    lda     #>@step_walk
    sta     _actor_param_7, x
    
    ; エネミーの生成演出
    lda     #$01
    sta     _actor_spawn, x

    ; 終了
    rts

; 歩数
@step_stay:
    .byte   4, 5, 6, 8, 9, 11, 12, 13
@step_walk:
    .byte   3, 4, 5, 6, 9, 10, 11, 12

.endproc

; グレムリンを破棄する
;
.global _ActorGremlinUnload
.proc   _ActorGremlinUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 死亡の判定
    cmp     #$ff
    bne     @end

    ; アクタの保存
    txa
    pha

    ; 鍵の取得
    lda     #USER_ITEM_KEY
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

