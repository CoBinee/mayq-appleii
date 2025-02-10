; actor_skeleton.s - スケルトン
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

; スケルトンを読み込む
;
.global _ActorSkeletonLoad
.proc   _ActorSkeletonLoad

    ; IN
    ;   x = アクタの参照

    ; ランダムな配置
    jsr     _ActorRandomPosition

    ; 描画の設定
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_DIRECTION
    sta     _actor_draw, x

    ; 反撃の設定
    lda     #ACTOR_SKELETON_COUNTER
    sta     _actor_param_0, x

;   ; 方向転換の設定
;   lda     #$00
;   sta     _actor_param_1, x

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
    .byte   3, 4, 5, 6, 7, 8, 9, 10
@step_walk:
    .byte   5, 6, 7, 8, 9, 10, 11, 12

.endproc

; スケルトンを破棄する
;
.global _ActorSkeletonUnload
.proc   _ActorSkeletonUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 終了
    rts

.endproc


; データの定義
;
.segment    "BSS"

