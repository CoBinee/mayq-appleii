; actor_wizard.s - ウィザード
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

; ウィザードを読み込む
;
.global _ActorWizardLoad
.proc   _ActorWizardLoad

    ; IN
    ;   x = アクタの参照

    ; ランダムな配置
    jsr     _ActorRandomPosition

    ; 描画の設定
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_DIRECTION
    sta     _actor_draw, x

    ; エネミーの生成演出
    lda     #$01
    sta     _actor_spawn, x

    ; 終了
    rts

.endproc

; ウィザードを破棄する
;
.global _ActorWizardUnload
.proc   _ActorWizardUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 死亡の判定
    cmp     #$ff
    bne     @end

    ; アクタの保存
    txa
    pha

    ; イベントの確認
    ldx     _game_area
    lda     _world_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_CRYSTAL_GREEN
    bne     @skip
    lda     _user_event, x
    bne     @skip

    ; 残り 1 体ならば最後のウィザード
    lda     #ACTOR_CLASS_WIZARD
    jsr     _ActorGetClassCount
    cmp     #$01
    bne     @skip

    ; イベントの進行
    ldx     _game_area
    inc     _user_event, x

    ; アクタの復帰
@skip:
    pla
    tax

    ; 終了
@end:
    rts

.endproc

; ウィザードを行動させる
;
.global _ActorWizardPlay
.proc   _ActorWizardPlay

    ; IN
    ;   x = アクタの参照
    ; PARAM
    ;   P[0] = 歩数
    ;   P[1] = 点滅

    ; 初期化
    lda     _actor_state, x
    bne     @initialized

    ; 歩数の設定／同時出現時に少しずらす
    jsr     @step_stay
    lda     #ACTOR_CLASS_WIZARD
    jsr     _ActorGetClassCount
    asl     a
    asl     a
    clc
    adc     _actor_param_0, x
    sta     _actor_param_0, x

    ; 初期化の完了
    inc     _actor_state, x
@initialized:

    ; 1: 待機
@stay:
    lda     _actor_state, x
    cmp     #$01
    bne     @cast

    ; 歩数の更新
    dec     _actor_param_0, x
    bne     @update

    ; 詠唱
    lda     _actor_direction, x
    jsr     _ActorCastBall

    ; アニメーションの設定
    lda     #ACTOR_ANIMATION_FRAME
    sta     _actor_animation, x

    ; 詠唱後へ
    jsr     @step_cast
    inc     _actor_state, x
    jmp     @update

    ; 2: 詠唱後
@cast:
;   lda     _actor_state, x
    cmp     #$02
    bne     @out

    ; 歩数の更新
    dec     _actor_param_0, x
    bne     @update

    ; 消えるへ
    lda     #$00
    sta     _actor_param_1, x
    inc     _actor_state, x
    jmp     @update

    ; 3: 消える
@out:
;   lda     _actor_state, x
    cmp     #$03
    bne     @move

    ; 点滅の更新
    inc     _actor_param_1, x
    lda     _actor_param_1, x
    cmp     #ACTOR_WIZARD_BLINK
    bne     @update

    ; 移動へ
    inc     _actor_state, x
    jmp     @update

    ; 4: 移動
@move:
;   lda     _actor_state, x
    cmp     #$04
    bne     @in

    ; 位置の設定
    jsr     _ActorRandomPosition
    jsr     _ActorGetDirectionNearPlayer
    cmp     #$ff
    beq     :+
    sta     _actor_direction, x
:

    ; アニメーションの設定
    lda     #$00
    sta     _actor_animation, x

    ; 現れるへ
;   lda     #ACTOR_WIZARD_BLINK
;   sta     _actor_param_1, x
    inc     _actor_state, x
;   jmp     @update

    ; 5: 現れる
@in:

    ; 点滅の更新
    dec     _actor_param_1, x
    bne     @update

    ; 待機へ
    jsr     @step_stay
    lda     #$01
    sta     _actor_state, x
;   jmp     @update

    ; アクタの更新
@update:

    ; アクタの描画
    lda     _actor_param_1, x
    and     #%00000001
    bne     :+
    lda     _actor_draw, x
    and     #(~ACTOR_DRAW_LAND & $ff)
    jmp     :++
:
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_LAND
:
    sta     _actor_draw, x
    jsr     _ActorDraw2x2
    
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
    .byte   9, 10, 11, 12, 13, 14, 15, 16
@step_cast:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :+, y
    sta     _actor_param_0, x
    rts
:
    .byte   6, 6, 7, 7, 8, 8, 9, 9
    
.endproc


; データの定義
;
.segment    "BSS"

