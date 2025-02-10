; actor_enemy.s - エネミー
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

; 待機するエネミーを行動させる
;
.global _ActorEnemyStay
.proc   _ActorEnemyStay

    ; IN
    ;   x = アクタの参照

    ; 初期化
    lda     _actor_state, x
    bne     @initialized

    ; 初期化の完了
    inc     _actor_state, x
@initialized:

    ; アクタの更新
@update:

    ; アクタの描画
    jsr     _ActorDraw2x2

    ; 終了
    rts

.endproc

; 歩行するエネミーを行動させる
;
.global _ActorEnemyWalk
.proc   _ActorEnemyWalk

    ; IN
    ;   x = アクタの参照
    ; PARAM
    ;   P[0]    = 反撃のダメージ数
    ;   P[1]    = 0...ランダム / 1...近づく / 2...遠ざかる
    ;   P[2]    = 0...詠唱なし / 1...1 発撃つ / else...3 発撃つ
    ;   P[3]    = 歩数
    ;   P[4..5] = 待機テーブルの参照
    ;   P[6..7] = 歩行テーブルの参照
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; 初期化
    lda     _actor_state, x
    bne     @initialized

    ; 行動の設定
    lda     _actor_param_4, x
    ora     _actor_param_5, x
    beq     :+
    jsr     _IocsGetRandomNumber
    and     #%00000100
    bne     :+
    jsr     @step_stay
    lda     #$01
    jmp     :++
:
    jsr     @step_walk
    lda     #$02
:

    ; 初期化の完了
    sta     _actor_state, x
@initialized:

    ; 一定のダメージでプレイヤの方を向く
    lda     _actor_param_0, x
    jsr     _ActorTurnCounter
    cmp     #$00
    bne     :+
    jsr     @step_walk
    lda     #$02
    sta     _actor_state, x
    jmp     @update
:

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
    dec     _actor_param_3, x
    beq     :+
    jmp     @update
:

    ; 歩行の開始
    jsr     @turn
    jsr     @step_walk
    lda     #$02
    sta     _actor_state, x
    jmp     @update

    ; 2: 歩行
@walk:

    ; 歩数の更新
    lda     _actor_param_3, x
    bne     @walking

    ; 詠唱の開始
    lda     _actor_param_2, x
    beq     :+
    jsr     _IocsGetRandomNumber
    and     #%00011000
    beq     :+
    lda     _actor_direction, x
    jsr     _ActorCastBall
    lda     _actor_param_2, x
    cmp     #$01
    beq     @walk_stay
    lda     _actor_direction, x
    eor     #%00000010
    and     #%00000010
    jsr     _ActorCastBall
    lda     _actor_direction, x
    eor     #%00000010
    ora     #%00000001
    jsr     _ActorCastBall
    jmp     @walk_stay
:

    ; 次の行動へ
    lda     _actor_param_4, x
    ora     _actor_param_5, x
    beq     @walk_walk
    jsr     _IocsGetRandomNumber
    and     #%00100100
    bne     @walk_walk
@walk_stay:
    jsr     @step_stay
    lda     #$01
    sta     _actor_state, x
    jmp     @update
@walk_walk:
    jsr     @turn
    jsr     @step_walk
;   jmp     @walking

    ; 歩数の更新
@walking:
    dec     _actor_param_3, x

    ; 移動の設定
    lda     _actor_move, x
    ora     #ACTOR_MOVE_STOMP
    sta     _actor_move, x

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
    lda     _actor_param_4, x
    sta     ACTOR_0_WORK_0
    lda     _actor_param_5, x
    sta     ACTOR_0_WORK_1
    jmp     @step
@step_walk:
    lda     _actor_param_6, x
    sta     ACTOR_0_WORK_0
    lda     _actor_param_7, x
    sta     ACTOR_0_WORK_1
@step:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     (ACTOR_0_WORK_0), y
    sta     _actor_param_3, x
    rts

    ; 方向転換する
@turn:
    jsr     _IocsGetRandomNumber
    and     #%00101010
    beq     :++
    lda     _actor_param_1, x
    beq     :++
    cmp     #$01
    beq     :+
    jsr     _ActorTurnFarPlayer
    jmp     :+++
:
    jsr     _ActorTurnNearPlayer
    jmp     :++
:
    jsr     _ActorTurnRandom
:
    rts

.endproc


; データの定義
;
.segment    "BSS"

