; actor_slime.s - スライム
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

; スライムを読み込む
;
.global _ActorSlimeLoad
.proc   _ActorSlimeLoad

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

; スライムを破棄する
;
.global _ActorSlimeUnload
.proc   _ActorSlimeUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 終了
    rts

.endproc

; スライムを行動させる
;
.global _ActorSlimePlay
.proc   _ActorSlimePlay

    ; IN
    ;   x = アクタの参照
    ; PARAM
    ;   P[0] = 歩数

    ; 初期化
    lda     _actor_state, x
    bne     @initialized

    ; 歩数の設定
    jsr     _IocsGetRandomNumber
    and     #$03
    beq     :++
    cmp     #$01
    beq     :+
    jsr     @step_stay
    lda     #$01
    jmp     :+++
:
    jsr     @step_walk
    lda     #$02
    jmp     :++
:
    jsr     @step_sway
    lda     #$03
:

    ; 初期化の完了
    sta     _actor_state, x
@initialized:

    ; 1: 待機
@stay:
    lda     _actor_state, x
    cmp     #$01
    bne     @walk

    ; 移動の設定
    lda     _actor_move, x
    and     #(~ACTOR_MOVE_STOMP & $ff)
    sta     _actor_move, x

    ; 歩数の更新
    dec     _actor_param_0, x
    bne     @update

    ; 歩行か揺れるか
    jsr     _IocsGetRandomNumber
    and     #%00010000
    bne     :+
    jsr     _ActorTurnRandom
    jsr     @step_walk
    lda     #$02
    sta     _actor_state, x
    jmp     @update
:
    jsr     @step_sway
    lda     #$03
    sta     _actor_state, x
    jmp     @update

    ; 2: 歩行
@walk:
    lda     _actor_state, x
    cmp     #$02
    bne     @sway

    ; 移動の設定
    lda     _actor_move, x
    ora     #ACTOR_MOVE_STOMP
    sta     _actor_move, x

    ; 歩数の更新
    lda     _actor_param_0, x
    beq     @stop
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
    jsr     @step_stay
    lda     #$01
    sta     _actor_state, x
    jmp     @update

    ; 3: 揺れる
@sway:

    ; 移動の設定
    lda     _actor_move, x
    ora     #ACTOR_MOVE_STOMP
    sta     _actor_move, x

    ; 歩数の更新
    dec     _actor_param_0, x
    bne     @update

    ; 停止
    jsr     @step_stay
    lda     #$01
    sta     _actor_state, x
;   jmp     @update

    ; アクタの更新
@update:

    ; アクタの描画
    jsr     _ActorDraw2x2
    
    ; アニメーションの更新
    lda     _actor_move, x
    and     #ACTOR_MOVE_STOMP
    beq     :+
    jsr     _ActorAnimation
:

    ; 終了
    rts

    ; 歩数の設定
@step_stay:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :+, y
    sta     _actor_param_0, x
    rts
:
    .byte   5, 6, 7, 8, 9, 10, 11, 12
@step_walk:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :+, y
    sta     _actor_param_0, x
    rts
:
    .byte   2, 3, 4, 4, 5, 5, 6, 7
@step_sway:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :+, y
    sta     _actor_param_0, x
    rts
:
    .byte   3, 3, 4, 4, 5, 5, 6, 6
    
.endproc


; データの定義
;
.segment    "BSS"

