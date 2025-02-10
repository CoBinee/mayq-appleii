; actor_devil.s - デビル
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

; デビルを読み込む
;
.global _ActorDevilLoad
.proc   _ActorDevilLoad

    ; IN
    ;   x = アクタの参照

    ; ランダムな配置
    jsr     _ActorRandomPosition

    ; 描画の設定
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_DIRECTION
    sta     _actor_draw, x

    ; 反撃の設定
    lda     #ACTOR_DEVIL_COUNTER
    sta     _actor_param_0, x

    ; 方向転換の設定
    lda     #$01
    sta     _actor_param_1, x

    ; 詠唱の設定
    lda     #$03
    sta     _actor_param_2, x

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
    .byte   3, 4, 4, 5, 5, 6, 6, 7
@step_walk:
    .byte   5, 5, 6, 7, 8, 9, 10, 10

.endproc

; デビルを破棄する
;
.global _ActorDevilUnload
.proc   _ActorDevilUnload

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
    cmp     #WORLD_EVENT_CRYSTAL_BLUE
    bne     @skip
    lda     _user_event, x
    bne     @skip

    ; 残り 1 体ならば最後のデビル
    lda     #ACTOR_CLASS_DEVIL
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


; データの定義
;
.segment    "BSS"

