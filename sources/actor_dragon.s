; actor_dragon.s - ドラゴン
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

; ドラゴンを読み込む
;
.global _ActorDragonLoad
.proc   _ActorDragonLoad

    ; IN
    ;   x = アクタの参照

    ; 中央上に配置
    lda     #((WORLD_AREA_TILE_SIZE_X - $04) / 2)
    sta     _actor_x, x
    lda     #((WORLD_AREA_TILE_SIZE_Y - $04) / 2 - $05)
    sta     _actor_y, x
    lda     #ACTOR_DIRECTION_DOWN
    sta     _actor_direction, x

    ; 終了
    rts

.endproc

; ドラゴンを破棄する
;
.global _ActorDragonUnload
.proc   _ActorDragonUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 死亡の判定
    cmp     #$ff
    bne     @end

    ; ゲームをクリア
    inc     _game_clear

    ; 終了
@end:
    rts

.endproc

; ドラゴンを行動させる
;
.global _ActorDragonPlay
.proc   _ActorDragonPlay

    ; IN
    ;   x = アクタの参照
    ; PARAM
    ;   P[0] = 歩数
    ;   P[1] = 待機
    ;   P[2] = 詠唱
    ;   P[3] = 詠唱の向き

    ; 初期化
    lda     _actor_state, x
    bne     @initialized

    ; 歩数の設定
    jsr     @step_walk

    ; 待機の設定
    lda     #$00
    sta     _actor_param_1, x

    ; 詠唱の設定
    jsr     @step_cast

    ; 初期化の完了
    inc     _actor_state, x
@initialized:

    ; 待機の更新
    lda     _actor_param_1, x
    beq     :+
    dec     _actor_param_1, x
    jmp     @update
:

    ; 詠唱の更新
    lda     _actor_param_2, x
    bne     :++
    jsr     @step_cast
    lda     _actor_direction, x
    eor     #%00000001
    sta     _actor_param_3, x
    jsr     _IocsGetRandomNumber
    and     #$03
    cmp     _actor_param_3, x
    bne     :+
    lda     _actor_direction, x
:
    sta     _actor_param_3, x
    jsr     _ActorCastBall
    cmp     #$00
    bne     :+
;   lda     _actor_param_3, x
;   cmp     _actor_direction, x
;   bne     :+
    lda     #ACTOR_DRAGON_STAY
    sta     _actor_param_1, x
    jmp     @update
:
    dec     _actor_param_2, x

    ; 一定のダメージでプレイヤの方を向く
    lda     #ACTOR_DRAGON_COUNTER
    jsr     _ActorTurnCounter
    cmp     #$00
    bne     :+
    jsr     @step_walk
    jmp     @update
:

    ; 方向転換
    lda     _actor_param_0, x
    bne     @walk
    jsr     _IocsGetRandomNumber
    and     #%00101010
    beq     :+
    jsr     _ActorTurnNearPlayer
    jmp     :++
:
    jsr     _ActorTurnRandom
:
    jsr     @step_walk

    ; 歩数の更新
@walk:
    dec     _actor_param_0, x

    ; 移動
    jsr     _ActorHit
    cmp     #$00
    bne     @hit
    jsr     _ActorMove
    cmp     #$00
    bne     @stop
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_BACK
    sta     _actor_draw, x
    jmp     @update

    ; ヒット
@hit:
    ldy     #ACTOR_TYPE_PLAYER
    jsr     _ActorDamage
    cmp     #$00
    bne     @update

    ; 停止
@stop:
    jsr     _ActorTurnRandom
;   jmp     @update

    ; アクタの更新
@update:

    ; アクタの描画
    jsr     _ActorDraw4x4
    
    ; アニメーションの更新
    jsr     _ActorAnimation

    ; 終了
    rts

    ; 歩数の設定
@step_walk:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :+, y
    sta     _actor_param_0, x
    rts
:
    .byte   3, 5, 6, 8, 9, 11, 12, 14
@step_cast:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :+, y
    sta     _actor_param_2, x
    rts
:
    .byte   3, 3, 4, 4, 4, 5, 5, 6
    
.endproc


; データの定義
;
.segment    "BSS"

