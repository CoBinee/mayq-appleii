; actor_serpent.s - サーペント
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

; サーペントを読み込む
;
.global _ActorSerpentLoad
.proc   _ActorSerpentLoad

    ; IN
    ;   x = アクタの参照

    ; ランダムな配置
    jsr     _ActorRandomPosition

    ; エネミーの生成演出
    lda     #$01
    sta     _actor_spawn, x

    ; 終了
    rts

.endproc

; サーペントを破棄する
;
.global _ActorSerpentUnload
.proc   _ActorSerpentUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 終了
    rts

.endproc

; サーペントを行動させる
;
.global _ActorSerpentPlay
.proc   _ActorSerpentPlay

    ; IN
    ;   x = アクタの参照
    ; PARAM
    ;   P[0] = 歩数
    ;   P[1] = 待機

    ; 初期化
    lda     _actor_state, x
    bne     @initialized

    ; 歩数の設定
    jsr     @step_walk

    ; タイルの設定
    lda     #ACTOR_SERPENT_TILE
    sta     _actor_tile, x

    ; 初期化の完了
    inc     _actor_state, x
@initialized:

    ; 1, 3: 歩行
@walk:
    lda     _actor_state, x
    cmp     #$03
    beq     :+
    cmp     #$01
    bne     @dive

    ; 一定のダメージでプレイヤの方を向く
    lda     #ACTOR_SERPENT_COUNTER
    jsr     _ActorTurnCounter
    cmp     #$00
    bne     :+
    jsr     @step_walk
    jmp     @update
:

    ; 待機の更新
    lda     _actor_param_1, x
    beq     :+
    dec     _actor_param_1, x
    jmp     @update
:

    ; 歩行の継続
    lda     _actor_param_0, x
    bne     @walking
    lda     _actor_state, x
    cmp     #$03
    beq     :+
    jsr     _IocsGetRandomNumber
    and     #%01000000
    beq     :+
    jsr     _ActorTurnRandom
    jsr     @step_walk
    jmp     @walking
:

    ; 潜る、浮くの開始
    lda     #ACTOR_SERPENT_DIVE
    sta     _actor_param_0, x
    lda     #(ACTOR_SERPENT_TILE + $08)
    sta     _actor_tile, x
    inc     _actor_state, x
    lda     _actor_state, x
    jmp     @dive

    ; 歩数の更新
@walking:
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
    jmp     @update

    ; 2, 4: 潜る、浮く
@dive:

    ; 歩数の更新
    dec     _actor_param_0, x
    bne     @update

    ; 歩行の開始
    jsr     _ActorTurnRandom
    jsr     @step_walk
    lda     #ACTOR_SERPENT_TILE
    sta     _actor_tile, x    
    lda     _actor_state, x
    and     #$03
    clc
    adc     #$01
    sta     _actor_state, x
    cmp     #$01
    bne     :+
    lda     _actor_draw, x
    and     #(~ACTOR_DRAW_LAND & $ff)
    jmp     :++
:
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_LAND
:
    sta     _actor_draw, x
;   jmp     @update

    ; アクタの更新
@update:

    ; アクタの描画
    lda     _actor_draw, x
    and     #ACTOR_DRAW_LAND
    bne     :+
    jsr     _ActorDrawTile2x2
    lda     _actor_draw, x
    and     #ACTOR_DRAW_BACK
    beq     :++
    jsr     _ActorDrawBack
    lda     _actor_draw, x
    and     #(~ACTOR_DRAW_BACK & $ff)
    sta     _actor_draw, x
    jmp     :++
:
    jsr     _ActorDrawLand2x2
:
    
    ; タイルの更新
    lda     _actor_tile, x
    eor     #%00000100
    sta     _actor_tile, x

    ; 終了
    rts

    ; 歩数の設定
@step_walk:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :+, y
    sta     _actor_param_0, x
    lda     #ACTOR_SERPENT_STAY
    sta     _actor_param_1, x
    rts
:
    .byte   5, 6, 8, 9, 11, 12, 14, 15
    
.endproc


; データの定義
;
.segment    "BSS"

