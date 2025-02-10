; actor_ball.s - マジックボール
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

; マジックボールを読み込む
;
.global _ActorBallLoad
.proc   _ActorBallLoad

    ; IN
    ;   x = アクタの参照

    ; 終了
    rts

.endproc

; マジックボールを破棄する
;
.global _ActorBallUnload
.proc   _ActorBallUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 終了
    rts

.endproc

; マジックボールを行動させる
;
.global _ActorBallPlay
.proc   _ActorBallPlay

    ; IN
    ;   x = アクタの参照

    ; 初期化
@initialize:
    lda     _actor_state, x
    bne     @move

    ; 初期化の完了
    inc     _actor_state, x
    jmp     @update

    ; 移動
@move:
    jsr     _ActorHit
    cmp     #$00
    bne     @hit
    jsr     _ActorMove
    cmp     #$00
    bne     @kill
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_BACK
    sta     _actor_draw, x
    jmp     @update

    ; ヒット
@hit:
    ldy     #ACTOR_TYPE_PLAYER
    jsr     _ActorDamage

    ; アクタの破棄
@kill:
    jsr     _ActorBallUnload
    jsr     _ActorDrawLand2x2
    lda     #$00
    sta     _actor_class, x
    jmp     @end

    ; アクタの更新
@update:

    ; アクタの描画
    jsr     _ActorDraw2x2
    
    ; アニメーションの更新
    lda     _actor_direction, x
    and     #%00000010
    bne     :+
    jsr     _ActorAnimation
:

    ; 終了
@end:
    rts
    
.endproc


; データの定義
;
.segment    "BSS"

