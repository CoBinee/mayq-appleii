; actor.s - アクタ
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

; アクタを初期化する
;
.global _ActorInitialize
.proc   _ActorInitialize

    ; アクタの初期化

    ; 終了
    rts

.endproc

; アクタをクリアする
;
.global _ActorClear
.proc   _ActorClear

    ; アクタのクリア
    lda     #$00
    sta     ACTOR_0_X
;   sta     ACTOR_0_Y
    sta     _actor_cycle
    sta     _actor_keycode
    tax
:
    sta     _actor_class, x
    inx
    cpx     #ACTOR_SIZE
    bne     :-

    ; 終了
    rts

.endproc

; アクタを新たに読み込む
;
.global _ActorLoad
.proc   _ActorLoad

    ; IN
    ;   a = クラス
    ; OUT
    ;   x = アクタの参照 / $ff = エラー
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; クラスの保存
    tay

    ; アクタの検索
    ldx     #$00
:
    lda     _actor_class, x
    beq     :+
    inx
    cpx     #ACTOR_SIZE
    bne     :-
    ldx     #$ff
    jmp     @end
:

    ; クラスの設定
    tya
    sta     _actor_class, x

    ; 状態の設定
    lda     #$00
    sta     _actor_state, x

    ; 生成の設定
;   lda     #$00
    sta     _actor_spawn, x

    ; 移動の設定
;   lda     #$00
    sta     _actor_move, x

    ; ヒットの設定
;   lda     #$00
    sta     _actor_hit, x

    ; ダメージの設定
;   lda     #$00
    sta     _actor_damage, x

    ; アニメーションの設定
;   lda     #$00
    sta     _actor_animation, x

    ; タイルの設定
;   lda     #$00
    sta     _actor_tile, x

    ; 描画の設定
;   lda     #$00
    sta     _actor_draw, x

    ; パラメータの設定
;   lda     #$00
    sta     _actor_param_0, x
    sta     _actor_param_1, x
    sta     _actor_param_2, x
    sta     _actor_param_3, x
    sta     _actor_param_4, x
    sta     _actor_param_5, x
    sta     _actor_param_6, x
    sta     _actor_param_7, x

    ; 体力の設定
    lda     actor_class_life, y
    sta     _actor_life, x

    ; アクタ別の読み込みの取得
    lda     actor_class_load_proc_l, y
    sta     ACTOR_0_WORK_0
    lda     actor_class_load_proc_h, y
    sta     ACTOR_0_WORK_1

    ; アクタ別の読み込みの実行
    lda     #>(:+ - $0001)
    pha
    lda     #<(:+ - $0001)
    pha
    jmp     (ACTOR_0_WORK_0)
:

    ; タイプ別の処理
    ldy     _actor_class, x
    lda     actor_class_type, y

    ; プレイヤの処理
@player:
    cmp     #ACTOR_TYPE_PLAYER
    bne     @enemy
    jmp     @end

    ; エネミーの処理
@enemy:
    cmp     #ACTOR_TYPE_ENEMY
    bne     @magic

    ; エネミーの生成の開始
    lda     _actor_spawn, x
    beq     :+
    lda     #ACTOR_EFFECT_SPAWN_0
    jsr     _ActorDrawEffect
:
    jmp     @end

    ; マジックの処理
@magic:
;   jmp     @end

    ; 終了
@end:
    rts

.endproc

; アクタを破棄する
;
.global _ActorUnload
.proc   _ActorUnload

    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; アクタの走査
    lda     #$00
    sta     ACTOR_0_X
@loop:

    ; アクタの取得
    ldx     ACTOR_0_X
    ldy     _actor_class, x
    beq     @next

    ; 処理の取得
    lda     actor_class_unload_proc_l, y
    sta     ACTOR_0_WORK_0
    lda     actor_class_unload_proc_h, y
    sta     ACTOR_0_WORK_1

    ; 処理の実行
    lda     #>(:+ - $0001)
    pha
    lda     #<(:+ - $0001)
    pha
    lda     #$00
    jmp     (ACTOR_0_WORK_0)
:

    ; 次のアクタへ
@next:
    inc     ACTOR_0_X
    lda     ACTOR_0_X
    cmp     #ACTOR_SIZE
    bne     @loop

    ; 終了
@end:
    rts

.endproc

; アクタを行動させる
;
.global _ActorPlay
.proc   _ActorPlay

    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; キーコードの取得
    lda     IOCS_0_KEYCODE
    beq     :+
    sta     _actor_keycode
:

    ; アクタの走査
    lda     #$00
    sta     ACTOR_0_X
@loop:

    ; アクタの取得
    ldx     ACTOR_0_X
    ldy     _actor_class, x
    beq     @dummy

    ; 生成中
    lda     _actor_spawn, x
    beq     @play
    lda     #ACTOR_SPEED_SPAWN
    and     _actor_cycle
    bne     @dummy
    lda     #<ActorSpawn
    sta     ACTOR_0_WORK_0
    lda     #>ActorSpawn
    sta     ACTOR_0_WORK_1
    jmp     @proc

    ; 行動中
@play:    
    lda     actor_class_speed, y
    and     _actor_cycle
    bne     @next
    lda     actor_class_play_proc_l, y
    sta     ACTOR_0_WORK_0
    lda     actor_class_play_proc_h, y
    sta     ACTOR_0_WORK_1
    jmp     @proc

    ; ダミー
@dummy:
    lda     #<ActorDummy
    sta     ACTOR_0_WORK_0
    lda     #>ActorDummy
    sta     ACTOR_0_WORK_1
;   jmp     @proc

    ; 処理の実行
@proc:
    lda     #>(:+ - $0001)
    pha
    lda     #<(:+ - $0001)
    pha
    jmp     (ACTOR_0_WORK_0)
:

    ; 次のアクタへ
@next:
    inc     ACTOR_0_X
    lda     ACTOR_0_X
    cmp     #ACTOR_SIZE
    bne     @loop

    ; 制御の更新
    lda     _actor_cycle
    clc
    adc     #$01
    and     #ACTOR_CYCLE_MASK
    sta     _actor_cycle

    ; 終了
    rts

.endproc

; 空のアクタを処理する
;
.proc   ActorNull

    ; 終了
    rts

.endproc

; ダミーのアクタを処理する
;
.proc   ActorDummy

    ; タイルの空描画
    lda     #$07
:
    pha
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern
    pla
    sec
    sbc     #$01
    bne     :-

    ; 終了
    rts

; 描画の引数
@draw_arg:
    .byte   $29, $10
    .word   actor_player_tileset
    .byte   $00

.endproc

; アクタが生成される
;
.proc   ActorSpawn

    ; IN
    ;   x = アクタの参照

    ; 初期化
    lda     _actor_state, x
    bne     @initialized

    ; エフェクトの設定／ACTOR_EFFECT_SPAWN_? > 0
    lda     #ACTOR_EFFECT_SPAWN_0
    sta     _actor_spawn, x

    ; 初期化の完了
    inc     _actor_state, x
@initialized:

    ; エフェクトの描画
    lda     _actor_spawn, x
    jsr     _ActorDrawEffect2x2

    ; P[0] : カウントの更新
    inc     _actor_spawn, x
    lda     _actor_spawn, x
    cmp     #(ACTOR_EFFECT_SPAWN_0 + $03)
    bne     @end

    ; 生成の完了
    lda     #$00
    sta     _actor_spawn, x
;   lda     #$00
    sta     _actor_state, x

    ; 終了
@end:
    rts

.endproc

; アクタをランダムな位置に配置する
;
.global _ActorRandomPosition
.proc   _ActorRandomPosition

    ; IN
    ;   x = アクタの参照
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; アクタの保存
    stx     ACTOR_0_RANDOM_POSITION_SELF
    ldy     _actor_class, x
    sty     ACTOR_0_RANDOM_POSITION_SELF_CLASS

    ; 最初のセルの取得
@cell_start:
    jsr     _IocsGetRandomNumber
    and     #%00011111
    sta     ACTOR_0_RANDOM_POSITION_CELL_START
    sta     ACTOR_0_RANDOM_POSITION_CELL_INDEX

    ; 空のセルの取得
@cell:
    ldy     @start
    lda     ACTOR_0_RANDOM_POSITION_CELL_INDEX
    and     #%00000111
    clc
    adc     @start_x, y
    sta     ACTOR_0_RANDOM_POSITION_CELL_X
    lda     ACTOR_0_RANDOM_POSITION_CELL_INDEX
    lsr     a
    lsr     a
    lsr     a
    and     #%00000011
    clc
    adc     @start_y, y
    sta     ACTOR_0_RANDOM_POSITION_CELL_Y
    ldx     ACTOR_0_RANDOM_POSITION_CELL_X
    ldy     ACTOR_0_RANDOM_POSITION_CELL_Y
    jsr     _WorldGetAreaCell
    tay
    lda     _world_cell_attribute, y
    and     #WORLD_CELL_ATTRIBUTE_SPAWN
    bne     @tile

    ; 次のセルの取得
@cell_next:
    lda     ACTOR_0_RANDOM_POSITION_CELL_INDEX
    clc
    adc     #$01
    and     #%00011111
    sta     ACTOR_0_RANDOM_POSITION_CELL_INDEX
    cmp     ACTOR_0_RANDOM_POSITION_CELL_START
    bne     @cell

    ; 次の範囲へ
    lda     @start
    clc
    adc     #$01
    and     #$03
    sta     @start
    jmp     @cell_start

    ; タイル位置の取得
@tile:
    ldy     ACTOR_0_RANDOM_POSITION_SELF_CLASS
    lda     ACTOR_0_RANDOM_POSITION_CELL_X
    asl     a
    sta     ACTOR_0_RANDOM_POSITION_SELF_X_0
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_RANDOM_POSITION_SELF_X_1
    lda     ACTOR_0_RANDOM_POSITION_CELL_Y
    asl     a
    sta     ACTOR_0_RANDOM_POSITION_SELF_Y_0
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_RANDOM_POSITION_SELF_Y_1

    ; アクタの走査
    ldx     #$00
@actor:
    cpx     ACTOR_0_RANDOM_POSITION_SELF
    beq     @actor_next
    ldy     _actor_class, x
    beq     @actor_next

    ; アクタの位置の取得
    lda     _actor_x, x
    sta     ACTOR_0_RANDOM_POSITION_SOME_X_0
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_RANDOM_POSITION_SOME_X_1
    lda     _actor_y, x
    sta     ACTOR_0_RANDOM_POSITION_SOME_Y_0
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_RANDOM_POSITION_SOME_Y_1

    ; プレイヤはひと回り大きく
    cpy     #ACTOR_CLASS_PLAYER
    bne     @check
    lda     ACTOR_0_RANDOM_POSITION_SOME_X_0
    sec
    sbc     #$02
    bcs     :+
    lda     #$00
:
    sta     ACTOR_0_RANDOM_POSITION_SOME_X_0
    lda     ACTOR_0_RANDOM_POSITION_SOME_X_1
    clc
    adc     #$02
    cmp     #WORLD_AREA_TILE_SIZE_X
    bcc     :+
    lda     #WORLD_AREA_TILE_SIZE_X
:
    sta     ACTOR_0_RANDOM_POSITION_SOME_X_1
    lda     ACTOR_0_RANDOM_POSITION_SOME_Y_0
    sec
    sbc     #$02
    bcs     :+
    lda     #$00
:
    sta     ACTOR_0_RANDOM_POSITION_SOME_Y_0
    lda     ACTOR_0_RANDOM_POSITION_SOME_Y_1
    clc
    adc     #$02
    cmp     #WORLD_AREA_TILE_SIZE_Y
    bcc     :+
    lda     #WORLD_AREA_TILE_SIZE_Y
:
    sta     ACTOR_0_RANDOM_POSITION_SOME_Y_1

    ; 位置の比較
@check:
    lda     ACTOR_0_RANDOM_POSITION_SOME_X_0
    cmp     ACTOR_0_RANDOM_POSITION_SELF_X_1
    bcs     @actor_next
    lda     ACTOR_0_RANDOM_POSITION_SOME_X_1
    cmp     ACTOR_0_RANDOM_POSITION_SELF_X_0
    bcc     @actor_next
    beq     @actor_next
    lda     ACTOR_0_RANDOM_POSITION_SOME_Y_0
    cmp     ACTOR_0_RANDOM_POSITION_SELF_Y_1
    bcs     @actor_next
    lda     ACTOR_0_RANDOM_POSITION_SOME_Y_1
    cmp     ACTOR_0_RANDOM_POSITION_SELF_Y_0
    bcc     @actor_next
    beq     @actor_next

    ; 重なっている
    jmp     @cell_next

    ; 次のアクタへ
@actor_next:
    inx
    cpx     #ACTOR_SIZE
    bne     @actor

    ; 位置の設定
    ldx     ACTOR_0_RANDOM_POSITION_SELF
    sta     _actor_direction, x
    lda     ACTOR_0_RANDOM_POSITION_SELF_X_0
    sta     _actor_x, x
    lda     ACTOR_0_RANDOM_POSITION_SELF_Y_0
    sta     _actor_y, x

    ; 向きの設定
    jsr     _IocsGetRandomNumber
    and     #$03
    ldx     ACTOR_0_RANDOM_POSITION_SELF
    sta     _actor_direction, x

    ; 開始位置の更新
    lda     @start
    clc
    adc     #$01
    and     #$03
    sta     @start

    ; アクタの復帰
    ldx     ACTOR_0_RANDOM_POSITION_SELF

    ; 終了
    rts

; 最初の位置
@start:
    .byte   $00
@start_x:
    .byte   $00, $07, $07, $00
@start_y:
    .byte   $01, $06, $01, $06

.endproc

; アクタを移動させる
;
.global _ActorMove
.proc   _ActorMove

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = 0...移動した / -1...エリア外 / else...移動できなかった

    ; クラスの取得
    ldy     _actor_class, x

    ; サイズの取得
    lda     actor_class_size, y
    sta     ACTOR_0_MOVE_SIZE

    ; ↑
@up:
    lda     _actor_direction, x
    bne     @down
    lda     _actor_y, x
    beq     @out
    clc
    adc     ACTOR_0_MOVE_SIZE
    sec
    sbc     #$02
    sta     ACTOR_0_MOVE_Y
    jsr     @is_y
    cmp     #$00
    bne     @end
    dec     _actor_y, x
    jmp     @end

    ; ↓
@down:
    cmp     #ACTOR_DIRECTION_DOWN
    bne     @left
    lda     _actor_y, x
    clc
    adc     ACTOR_0_MOVE_SIZE
    cmp     #WORLD_AREA_TILE_SIZE_Y
    bcs     @out
    sta     ACTOR_0_MOVE_Y
    jsr     @is_y
    cmp     #$00
    bne     @end
    inc     _actor_y, x
    jmp     @end

    ; ←
@left:
    cmp     #ACTOR_DIRECTION_LEFT
    bne     @right
    lda     _actor_x, x
    beq     @out
    sta     ACTOR_0_MOVE_X
    dec     ACTOR_0_MOVE_X
    jsr     @is_x
    cmp     #$00
    bne     @end
    dec     _actor_x, x
    jmp     @end

    ; →
@right:
    lda     _actor_x, x
    clc
    adc     ACTOR_0_MOVE_SIZE
    cmp     #WORLD_AREA_TILE_SIZE_X
    bcs     @out
    sta     ACTOR_0_MOVE_X
    jsr     @is_x
    cmp     #$00
    bne     @end
    inc     _actor_x, x
    jmp     @end

    ; エリア外
@out:
    lda     #$ff

    ; 終了
@end:
    rts

    ; 縦の移動の判定
@is_y:
    lda     _actor_x, x
    sta     ACTOR_0_MOVE_X
    txa
    pha
:
    ldx     ACTOR_0_MOVE_X
    ldy     ACTOR_0_MOVE_Y
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_COLLISION
    bne     :+
    inc     ACTOR_0_MOVE_X
    dec     ACTOR_0_MOVE_SIZE
    bne     :-
:
    pla
    tax
    lda     ACTOR_0_MOVE_SIZE
    rts

    ; 横の移動の判定
@is_x:
    lda     _actor_y, x
    clc
    adc     ACTOR_0_MOVE_SIZE
    tay
    dey
    txa
    pha
    ldx     ACTOR_0_MOVE_X
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_COLLISION
    tay
    pla
    tax
    tya
    rts

.endproc

; アクタ同士のヒットを判定する
;
.global _ActorHit
.proc   _ActorHit

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = ヒット数

    ; アクタの保存
    stx     ACTOR_0_HIT_SELF
    
    ; ヒット数のクリア
    lda     #$00
    sta     ACTOR_0_HIT_COUNT

    ; 位置の取得
    lda     _actor_direction, x
    tay
    lda     _actor_x, x
    clc
    adc     @direction_x, y
    sta     ACTOR_0_HIT_SELF_X_0
    lda     _actor_y, x
    clc
    adc     @direction_y, y
    sta     ACTOR_0_HIT_SELF_Y_0
    ldy     _actor_class, x
    lda     ACTOR_0_HIT_SELF_X_0
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_HIT_SELF_X_1
    lda     ACTOR_0_HIT_SELF_Y_0
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_HIT_SELF_Y_1

    ; アクタの走査
    ldx     #$00
@actor:
    lda     #$00
    sta     _actor_hit, x
    cpx     ACTOR_0_HIT_SELF
    beq     @actor_next
    ldy     _actor_class, x
    beq     @actor_next

    ; 位置の比較
    lda     _actor_x, x
    cmp     ACTOR_0_HIT_SELF_X_1
    bcs     @actor_next
    clc
    adc     actor_class_size, y
    cmp     ACTOR_0_HIT_SELF_X_0
    bcc     @actor_next
    beq     @actor_next
    lda     _actor_y, x
    cmp     ACTOR_0_HIT_SELF_Y_1
    bcs     @actor_next
    clc
    adc     actor_class_size, y
    cmp     ACTOR_0_HIT_SELF_Y_0
    bcc     @actor_next
    beq     @actor_next

    ; ヒットの更新
    inc     _actor_hit, x
    inc     ACTOR_0_HIT_COUNT

    ; 次のアクタへ
@actor_next:
    inx
    cpx     #ACTOR_SIZE
    bne     @actor

    ; ヒット数の取得
    lda     ACTOR_0_HIT_COUNT

    ; アクタの復帰
    ldx     ACTOR_0_HIT_SELF

    ; 終了
    rts

; 移動量
@direction_x:
    .byte   $00, $00, $ff, $01
@direction_y:
    .byte   $ff, $01, $00, $00

.endproc

; ヒットされた指定のアクタにダメージを与える
;
.global _ActorDamage
.proc   _ActorDamage

    ; IN
    ;   x = アクタの参照
    ;   y = 対象の種類
    ; OUT
    ;   a = ダメージを与えた数
    ; WORK
    ;   ACTOR_0_WORK_0

    ; アクタの保存
    stx     ACTOR_0_DAMAGE_SELF
    lda     _actor_class, x
    sta     ACTOR_0_DAMAGE_SELF_CLASS

    ; 種類の保存
    sty     ACTOR_0_DAMAGE_TYPE

    ; ダメージ数の設定
    lda     #$00
    sta     ACTOR_0_DAMAGE_COUNT

    ; アクタの走査
    ldx     #$00
@loop:
    ldy     _actor_class, x
    bne     :+
    jmp     @next
:
    lda     actor_class_type, y
    cmp     ACTOR_0_DAMAGE_TYPE
    beq     :+
    jmp     @next
:

    ; ヒットしたアクタ
    lda     _actor_hit, x
    bne     :+
    jmp     @next
:

    ; プレイヤの攻撃力の取得
@attack_player:
    ldy     ACTOR_0_DAMAGE_SELF_CLASS
    lda     actor_class_type, y
    cmp     #ACTOR_TYPE_PLAYER
    bne     @attack_enemy
    lda     _user_item + USER_ITEM_TALISMAN
    ldy     _user_strength
    clc
    adc     @player_attack, y
    jmp     @calc

    ; エネミー／マジックの攻撃力の取得
@attack_enemy:
    lda     _game_cheat_nodamage
    bne     @nodamage
    lda     actor_class_strength, y
    sec
    sbc     _user_strength
    sec
    sbc     _user_item + USER_ITEM_AMULET
    clc
    adc     actor_class_attack, y
    bmi     :+
    bne     @calc
:
    lda     #$01
;   jmp     @calc

    ; ダメージの計算
@calc:
    ldy     _actor_class, x
    sec
    sbc     actor_class_defense, y
    bcs     :+
    lda     #$01
:
    sta     ACTOR_0_WORK_0
    lda     _actor_life, x
    sec
    sbc     ACTOR_0_WORK_0
    bcs     :+
    lda     #$00
:
    sta     _actor_life, x

    ; 無敵
@nodamage:

    ; ダメージ数の更新
    inc     ACTOR_0_DAMAGE_COUNT

    ; プレイヤの体力の表示
@info_player:
    ldy     _actor_class, x
    lda     actor_class_type, y
    cmp     #ACTOR_TYPE_PLAYER
    bne     @info_enemy
    jsr     _GameDrawActorStatusLife
    jmp     @damage

    ; エネミーの情報の表示
@info_enemy:
    jsr     ActorDrawInformation
;   jmp     @damage

    ; ダメージアニメーション
@damage:
    ldy     ACTOR_0_DAMAGE_SELF_CLASS
    lda     actor_class_hit_beep, y
    tay
    jsr     _ActorAnimateDamage

    ; ダメージの更新
    inc     _actor_damage, x

    ; 生存
    lda     _actor_life, x
    beq     :+
    jmp     @next
:

    ; プレイヤの死亡
@dead_player:
    ldy     _actor_class, x
    lda     actor_class_type, y
    cmp     #ACTOR_TYPE_PLAYER
    bne     @dead_enemy

    ; 薬の使用
    lda     _user_item + USER_ITEM_POTION
    beq     @dead
    txa
    pha
    lda     #USER_ITEM_POTION
    jsr     _GameRemoveItem
    pla
    tax
:
    txa
    pha
    inc     _actor_life, x
    jsr     _GameDrawActorStatusLife
    ldx     #IOCS_BEEP_PI
    lda     #IOCS_BEEP_L256
    jsr     _IocsBeepNote
    lda     #IOCS_BEEP_L256
    jsr     _IocsBeepRest
    pla
    tax
    lda     _actor_life, x
    cmp     _user_life_maximum
    bcc     :-
    jmp     @next

    ; エネミーの死亡
@dead_enemy:
    cmp     #ACTOR_TYPE_ENEMY
    bne     @dead

    ; 経験値の加算
    lda     actor_class_strength, y
    sec
    sbc     _user_strength
;;  asl     a
    clc
    adc     actor_class_experience, y
    bmi     :+
    bne     :++
:
    lda     #$01
:
    sta     ACTOR_0_DAMAGE_EXPERIENCE
    lda     ACTOR_0_DAMAGE_EXPERIENCE
    jsr     _UserAddExperience
    txa
    pha
    ldx     ACTOR_0_DAMAGE_SELF
    jsr     _GameDrawActorStatus
    pla
    tax
;   jmp     @dead

    ; 死亡アニメーション
@dead:
    jsr     ActorAnimateDead

    ; アクタの破棄
    ldy     _actor_class, x
    lda     actor_class_unload_proc_l, y
    sta     ACTOR_0_DAMAGE_PROC_L
    lda     actor_class_unload_proc_h, y
    sta     ACTOR_0_DAMAGE_PROC_H

    ; 処理の実行
    lda     #>(:+ - $0001)
    pha
    lda     #<(:+ - $0001)
    pha
    lda     #$ff
    jmp     (ACTOR_0_DAMAGE_PROC)
:

    ; アクタの削除
    lda     #$00
    sta     _actor_class, x

    ; 情報のクリア
    jsr     _GameClearInformation
;   jmp     @next

    ; 次のアクタへ
@next:
    inx
    cpx     #ACTOR_SIZE
    beq     :+
    jmp     @loop
:

    ; アクタの復帰
    ldx     ACTOR_0_DAMAGE_SELF

    ; ダメージ数の取得
    lda     ACTOR_0_DAMAGE_COUNT

    ; 終了
    rts

; プレイヤの攻撃力
@player_attack:
    .byte   0,  2,  3,  4,  6,  8, 11, 14, 18, 22, 27

.endproc

; プレイヤアクタに反撃する方向を取得する
;
.global _ActorGetDirectionToCounter
.proc   _ActorGetDirectionToCounter

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = 方向 / $ff = 反撃できない
    ; WORK
    ;   ACTOR_0_WORK_0..3

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; アクタの取得
    ldy     _actor_class, x
    lda     _actor_x, x
    sta     ACTOR_0_WORK_1
    lda     _actor_y, x
    sta     ACTOR_0_WORK_2
    lda     actor_class_size, y
    sta     ACTOR_0_WORK_3

    ; プレイヤの取得
    lda     #ACTOR_CLASS_PLAYER
    jsr     _ActorGetByClass
    cpx     #$ff
    beq     @false
    ldy     _actor_class, x

    ; ↑↓
    lda     _actor_x, x
    clc
    adc     actor_class_size, y
    cmp     ACTOR_0_WORK_1
    bcc     :++
    lda     ACTOR_0_WORK_1
    clc
    adc     ACTOR_0_WORK_3
    cmp     _actor_x, x
    bcc     :++
    lda     _actor_y, x
    clc
    adc     actor_class_size, y
    cmp     ACTOR_0_WORK_2
    bne     :+
    lda     #ACTOR_DIRECTION_UP
    jmp     @end
:
    lda     ACTOR_0_WORK_2
    clc
    adc     ACTOR_0_WORK_3
    cmp     _actor_y, x
    bne     @false
    lda     #ACTOR_DIRECTION_DOWN
    jmp     @end
:

    ; ←→
    lda     _actor_y, x
    clc
    adc     actor_class_size, y
    cmp     ACTOR_0_WORK_2
    bcc     :++
    lda     ACTOR_0_WORK_2
    clc
    adc     ACTOR_0_WORK_3
    cmp     _actor_y, x
    bcc     :++
    lda     _actor_x, x
    clc
    adc     actor_class_size, y
    cmp     ACTOR_0_WORK_1
    bne     :+
    lda     #ACTOR_DIRECTION_LEFT
    jmp     @end
:
    lda     ACTOR_0_WORK_1
    clc
    adc     ACTOR_0_WORK_3
    cmp     _actor_x, x
    bne     @false
    lda     #ACTOR_DIRECTION_RIGHT
    jmp     @end
:

    ; 反撃できない
@false:
    lda     #$ff

    ; アクタの復帰
@end:
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

; プレイヤアクタに近づく方向を取得する
;
.global _ActorGetDirectionNearPlayer
.proc   _ActorGetDirectionNearPlayer

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = 方向 / $ff = プレイヤはいない
    ; WORK
    ;   ACTOR_0_WORK_0..3

    ; 距離の取得
    jsr     _ActorGetVectorToPlayer
    cmp     #$80
    beq     @false
    sta     ACTOR_0_WORK_1
    sty     ACTOR_0_WORK_2

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; すでにプレイヤの方向を向いている
    lda     ACTOR_0_WORK_1
    bpl     :+
    lda     _actor_direction, x
    cmp     #ACTOR_DIRECTION_LEFT
    beq     @end
    jmp     @near
:
    beq     :+
    lda     _actor_direction, x
    cmp     #ACTOR_DIRECTION_RIGHT
    beq     @end
    jmp     @near
:
    lda     ACTOR_0_WORK_2
    bpl     :+
    lda     _actor_direction, x
    cmp     #ACTOR_DIRECTION_UP
    beq     @end
    jmp     @near
:
    beq     :+
    lda     _actor_direction, x
    cmp     #ACTOR_DIRECTION_DOWN
    beq     @end
;   jmp     @near

    ; X と Y の距離の比較
@near:
    lda     ACTOR_0_WORK_1
    bpl     :+
    eor     #$ff
    clc
    adc     #$01
:
    sta     ACTOR_0_WORK_3
    lda     ACTOR_0_WORK_2
    bpl     :+
    eor     #$ff
    clc
    adc     #$01
:
    cmp     ACTOR_0_WORK_3
    bcc     :++
    lda     ACTOR_0_WORK_2
    bpl     :+
    lda     #ACTOR_DIRECTION_UP
    jmp     @end
:
    lda     #ACTOR_DIRECTION_DOWN
    jmp     @end
:
    lda     ACTOR_0_WORK_1
    bpl     :+
    lda     #ACTOR_DIRECTION_LEFT
    jmp     @end
:
    lda     #ACTOR_DIRECTION_RIGHT

    ; アクタの復帰
    ldx     ACTOR_0_WORK_0
    jmp     @end

    ; 近づけない
@false:
    lda     #$ff

    ; 終了
@end:
    rts

.endproc

; ランダムな方向を向く
;
.global _ActorTurnRandom
.proc   _ActorTurnRandom

    ; IN
    ;   x = アクタの参照

    ; 端にいる時はある程度内側へ行くようにする
    lda     _actor_x, x
    cmp     #$03
    bcs     :+
    lda     _actor_direction, x
    and     #%00000010
    bne     @random
    lda     #ACTOR_DIRECTION_RIGHT
    jmp     @turn
:
    cmp     #(WORLD_AREA_TILE_SIZE_X - $04)
    bcc     :+
    lda     _actor_direction, x
    and     #%00000010
    bne     @random
    lda     #ACTOR_DIRECTION_LEFT
    jmp     @turn
:
    lda     _actor_y, x
    cmp     #$03
    bcs     :+
    lda     _actor_direction, x
    and     #%00000010
    beq     @random
    lda     #ACTOR_DIRECTION_DOWN
    jmp     @turn
:
    cmp     #(WORLD_AREA_TILE_SIZE_Y - $04)
    bcc     :+
    lda     _actor_direction, x
    and     #%00000010
    beq     @random
    lda     #ACTOR_DIRECTION_UP
    jmp     @turn
:

    ; ランダムな方向転換
@random:
    jsr     _IocsGetRandomNumber
    and     #$03
    cmp     _actor_direction, x
    beq     @random

    ; 方向の決定
@turn:
    sta     _actor_direction, x

    ; 終了
    rts

.endproc

; 一定のダメージで反撃する方向を向かせる
;
.global _ActorTurnCounter
.proc   _ActorTurnCounter

    ; IN
    ;   x = アクタの参照
    ;   a = ダメージ量
    ; OUT
    ;   a = 0...方向を変えた / $ff...反撃できない

    ; 一定のダメージでプレイヤの方を向く
    cmp     _actor_damage, x
    bcc     :+
    bne     @false
:
    jsr     _ActorGetDirectionToCounter
    cmp     #$ff
    beq     @end
    cmp     _actor_direction, x
    beq     @false
    sta     _actor_direction, x
    lda     #$00
    sta     _actor_damage, x
    jmp     @end

    ; 反撃できない
@false:
    lda     #$ff

    ; 終了
@end:
    rts

.endproc

; プレイヤアクタに近づく方向に向かせる
;
.global _ActorTurnNearPlayer
.proc   _ActorTurnNearPlayer

    ; IN
    ;   x = アクタの参照

    ; 近づく方向を向く
    jsr     _ActorGetDirectionNearPlayer
    cmp     #$ff
    beq     :+
    sta     _actor_direction, x
    jmp     :++
:
    jsr     _ActorTurnRandom
:

    ; 終了
    rts

.endproc

; プレイヤアクタから遠ざかる方向に向かせる
;
.global _ActorTurnFarPlayer
.proc   _ActorTurnFarPlayer

    ; IN
    ;   x = アクタの参照

    ; 遠ざかる方向を向く
    jsr     _ActorGetDirectionNearPlayer
    cmp     #$ff
    beq     :+
    eor     #%00000001
    sta     _actor_direction, x
    jmp     :++
:
    jsr     _ActorTurnRandom
:

    ; 終了
    rts

.endproc

; プレイヤアクタとのベクトルを取得する
;
.global _ActorGetVectorToPlayer
.proc   _ActorGetVectorToPlayer

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = X のベクトル / $80...プレイヤが不在
    ;   y = Y のベクトル / $80...プレイヤが不在
    ; WORK
    ;   ACTOR_0_WORK_0..3

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; アクタの中心の取得
    ldy     _actor_class, x
    lda     actor_class_size, y
    lsr     a
    pha
    clc
    adc     _actor_x, x
    sta     ACTOR_0_WORK_1
    pla
    clc
    adc     _actor_y, x
    sta     ACTOR_0_WORK_2

    ; プレイヤの取得
    lda     #ACTOR_CLASS_PLAYER
    jsr     _ActorGetByClass
    txa
    cpx     #$ff
    bne     :+
    jmp     @false
:

    ; プレイヤの中心の取得
    ldy     _actor_class, x
    lda     actor_class_size, y
    lsr     a
    sta     ACTOR_0_WORK_3

    ; 距離の取得
    lda     _actor_y, x
    clc
    adc     ACTOR_0_WORK_3
    sec
    sbc     ACTOR_0_WORK_2
    tay
    lda     _actor_x, x
    clc
    adc     ACTOR_0_WORK_3
    sec
    sbc     ACTOR_0_WORK_1
    jmp     @end

    ; プレイヤは不在
@false:
    lda     #$80
    tay

    ; アクタの復帰
@end:
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

; プレイヤアクタとの距離を取得する
;
.global _ActorGetDistanceToPlayer
.proc   _ActorGetDistanceToPlayer

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = 距離 / $80 = プレイヤが不在
    ; WORK
    ;   ACTOR_0_WORK_0..3

    ; ベクトルの取得
    jsr     _ActorGetVectorToPlayer
    cmp     #$80
    beq     @end

    ; 距離の取得
    and     #$ff
    bpl     :+
    eor     #$ff
    clc
    adc     #$01
:
    sta     ACTOR_0_WORK_0
    tya
    bpl     :+
    eor     #$ff
    clc
    adc     #$01
:
    clc
    adc     ACTOR_0_WORK_0

    ; 終了
@end:
    rts

.endproc

; アクタがマジックボールを唱える
;
.global _ActorCastBall
.proc   _ActorCastBall

    ; IN
    ;   x = アクタの参照
    ;   a = 向き
    ; OUT
    ;   a = $00...詠唱成功 / $ff...詠唱失敗
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; 向きの保存
    sta     @direction

    ; 詠唱数の取得
    ldy     _actor_class, x
    lda     actor_class_size, y
    lsr     a
    sta     @count
    lda     #$00
    sta     @casted

    ; 方向別の詠唱
    lda     @direction
    beq     @up
    cmp     #ACTOR_DIRECTION_DOWN
    beq     @down
    cmp     #ACTOR_DIRECTION_LEFT
    beq     @left
    jmp     @right

    ; ↑
@up:
    lda     _actor_x, x
    sta     @position_x
    lda     _actor_y, x
    sec
    sbc     #$02
    sta     @position_y
    jmp     @cast_h

    ; ↓
@down:
    lda     _actor_x, x
    sta     @position_x
    lda     _actor_y, x
    clc
    adc     actor_class_size, y
    sta     @position_y
    jmp     @cast_h

    ; ←
@left:
    lda     _actor_x, x
    sec
    sbc     #$02
    sta     @position_x
    lda     _actor_y, x
    sta     @position_y
    jmp     @cast_v

    ; →
@right:
    lda     _actor_x, x
    clc
    adc     actor_class_size, y
    sta     @position_x
    lda     _actor_y, x
    sta     @position_y
    jmp     @cast_v

    ; 水平方向に詠唱
@cast_h:
    jsr     @cast
    dec     @count
    beq     @end
    lda     @position_x
    clc
    adc     #$02
    sta     @position_x
    jmp     @cast_h

    ; 垂直方向に詠唱
@cast_v:
    jsr     @cast
    dec     @count
    beq     @end
    lda     @position_y
    clc
    adc     #$02
    sta     @position_y
    jmp     @cast_v

    ; 1 回の詠唱
@cast:
    txa
    pha

    ; 空白の判定
    txa
    pha
    ldx     @position_x
    ldy     @position_y
    lda     @direction
    jsr     _ActorIsBlank2x2
    tay
    pla
    tax
    cpy     #$00
    bne     @cast_end

    ; マジックボールの読み込み
    ldy     _actor_class, x
    lda     actor_class_ball, y
    jsr     _ActorLoad
    cpx     #$ff
    beq     @cast_end

    ; 位置の設定
    lda     @position_x
    sta     _actor_x, x
    lda     @position_y
    sta     _actor_y, x
    lda     @direction
    sta     _actor_direction, x

    ; 最初の描画
    jsr     _ActorDrawTile2x2

    ; 詠唱の成功
    inc     @casted

    ; 詠唱の完了
@cast_end:
    pla
    tax
    rts

    ; 詠唱した数の確認
@end:
    lda     @casted
    beq     :+
    lda     #$00
    jmp     :++
:
    lda     #$ff
:

    ; 終了
    rts

; 位置
@position_x:
    .byte   $00
@position_y:
    .byte   $00

; 向き
@direction:
    .byte   $00

; 詠唱数
@count:
    .byte   $00

; 詠唱した数
@casted:
    .byte   $00

.endproc

; 指定された 2x2 が空白かどうかを判定する
;
.global _ActorIsBlank2x2
.proc   _ActorIsBlank2x2

    ; IN
    ;   x = X 位置
    ;   y = Y 位置
    ;   a = 向き
    ; OUT
    ;   a = $00...空白 / $ff...空白ではない

    ; エリアの判定
    cpx     #(WORLD_AREA_TILE_SIZE_X - $01)
    bcc     :+
    jmp     @false
:
    cpy     #(WORLD_AREA_TILE_SIZE_Y - $01)
    bcc     :+
    jmp     @false
:

    ; 位置の保存
    stx     ACTOR_0_BLANK_X_0
    inx
    inx
    stx     ACTOR_0_BLANK_X_1
    sty     ACTOR_0_BLANK_Y_0
    iny
    iny
    sty     ACTOR_0_BLANK_Y_1

    ; 向きの保存
;   sta     ACTOR_0_BLANK_DIRECTION

    ; タイルの比較
;   lda     ACTOR_0_BLANK_DIRECTION
    and     #%00000010
    bne     :+
    ldx     ACTOR_0_BLANK_X_0
    ldy     ACTOR_0_BLANK_Y_0
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_COLLISION
    bne     @false
    ldx     ACTOR_0_BLANK_X_0
    inx
    ldy     ACTOR_0_BLANK_Y_0
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_COLLISION
    bne     @false
:
    ldx     ACTOR_0_BLANK_X_0
    ldy     ACTOR_0_BLANK_Y_0
    iny
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_COLLISION
    bne     @false
    ldx     ACTOR_0_BLANK_X_0
    inx
    ldy     ACTOR_0_BLANK_Y_0
    iny
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_COLLISION
    bne     @false

    ; アクタの走査
    ldx     #$00
@actor:
    ldy     _actor_class, x
    beq     @actor_next

    ; アクタの位置の取得
    lda     _actor_x, x
    sta     ACTOR_0_BLANK_SOME_X_0
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_BLANK_SOME_X_1
    lda     _actor_y, x
    sta     ACTOR_0_BLANK_SOME_Y_0
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_BLANK_SOME_Y_1

    ; 位置の比較
    lda     ACTOR_0_BLANK_SOME_X_0
    cmp     ACTOR_0_BLANK_X_1
    bcs     @actor_next
    lda     ACTOR_0_BLANK_SOME_X_1
    cmp     ACTOR_0_BLANK_X_0
    bcc     @actor_next
    beq     @actor_next
    lda     ACTOR_0_BLANK_SOME_Y_0
    cmp     ACTOR_0_BLANK_Y_1
    bcs     @actor_next
    lda     ACTOR_0_BLANK_SOME_Y_1
    cmp     ACTOR_0_BLANK_Y_0
    bcc     @actor_next
    beq     @actor_next

    ; 重なっている
    jmp     @false

    ; 次のアクタへ
@actor_next:
    inx
    cpx     #ACTOR_SIZE
    bne     @actor

    ; 空白
    lda     #$00
    jmp     @end

    ; 空白ではない
@false:
    lda     #$ff

    ; 終了
@end:
    rts

.endproc

; アクタのアニメーションを更新する
;
.global _ActorAnimation
.proc   _ActorAnimation

    ; IN
    ;   x = アクタの参照

    ; アニメーションの更新
    ldy     _actor_class, x
    lda     _actor_animation, x
    clc
    adc     actor_class_animation, y
    sta     _actor_animation, x

    ; 終了
    rts

.endproc

; アクタのダメージアニメーションを表示する
;
.global _ActorAnimateDamage
.proc   _ActorAnimateDamage

    ; IN
    ;   x = アクタの参照
    ;   y = BEEP

    ; アクタの保存
    txa
    pha

    ; エフェクトの描画
    tya
    pha
    lda     #ACTOR_EFFECT_WHITE
    jsr     _ActorDrawEffect

    ; BEEP
    pla
    tax
;   ldx     #IOCS_BEEP_PI
    lda     #IOCS_BEEP_L32p
    jsr     _IocsBeepNote
    
    ; アクタの復帰
    pla
    tax

    ; アクタの描画
    lda     _actor_draw, x
    and     #ACTOR_DRAW_LAND
    bne     :+
    jsr     _ActorDrawTile
    jmp     :++
:
    jsr     _ActorDrawLand
:

    ; 終了
    rts

.endproc

; アクタの死亡アニメーションを表示する
;
.proc   ActorAnimateDead

    ; IN
    ;   x = アクタの参照

    ; 点滅
    ldy     _actor_class, x
    lda     actor_class_blink, y
:
    pha

    ; 明滅／滅
    txa
    pha
    jsr     _ActorDrawTile
    lda     #IOCS_BEEP_L32p
    jsr     _IocsBeepRest
    pla
    tax

    ; 明滅／明
    pha
    jsr     _ActorDrawLand
    lda     #IOCS_BEEP_L32p
    jsr     _IocsBeepRest
    pla
    tax

    ; 点滅の繰り返し
    pla
    sec
    sbc     #$01
    bne     :-

    ; 終了
    rts

.endproc

; 指定されたクラスのアクタを取得する
;
.global _ActorGetByClass
.proc   _ActorGetByClass

    ; IN
    ;   a = クラス
    ; OUT
    ;   x = アクタの参照

    ; アクタの検索
    ldx     #$00
:
    cmp     _actor_class, x
    beq     :+
    inx
    cpx     #ACTOR_SIZE
    bne     :-
    ldx     #$ff
:

    ; 終了
    rts

.endproc

; 指定された種類の数を取得する
;
.global _ActorGetTypeCount
.proc   _ActorGetTypeCount

    ; IN
    ;   a = 種類
    ; OUT
    ;   a = アクタの数
    ; WORK
    ;   ACTOR_0_WORK_0..2

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; 種類の取得
    sta     ACTOR_0_WORK_1

    ; 種類を数える
    ldx     #$00
    stx     ACTOR_0_WORK_2
:
    ldy     _actor_class, x
    lda     actor_class_type, y
    cmp     ACTOR_0_WORK_1
    bne     :+
    inc     ACTOR_0_WORK_2
:
    inx
    cpx     #ACTOR_SIZE
    bne     :--
    lda     ACTOR_0_WORK_2

    ; アクタの復帰
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

; 指定されたクラスの数を取得する
;
.global _ActorGetClassCount
.proc   _ActorGetClassCount

    ; IN
    ;   a = クラス
    ; OUT
    ;   a = アクタの数
    ; WORK
    ;   ACTOR_0_WORK_0..2

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; クラスの取得
    sta     ACTOR_0_WORK_1

    ; 種類を数える
    ldx     #$00
    stx     ACTOR_0_WORK_2
:
    lda     _actor_class, x
    cmp     ACTOR_0_WORK_1
    bne     :+
    inc     ACTOR_0_WORK_2
:
    inx
    cpx     #ACTOR_SIZE
    bne     :--
    lda     ACTOR_0_WORK_2

    ; アクタの復帰
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

; 足元のタイルを取得する
;
.global _ActorGetFootLeftTile
.proc   _ActorGetFootLeftTile

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = タイル
    ; WORK
    ;   ACTOR_0_WORK_0

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; タイルの取得
    ldy     _actor_y, x
    iny
    lda     _actor_x, x
    tax
    jsr     _WorldGetAreaTile

    ; アクタの復帰
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

.global _ActorGetFootRightTile
.proc   _ActorGetFootRightTile

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = タイル
    ; WORK
    ;   ACTOR_0_WORK_0

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; タイルの取得
    ldy     _actor_y, x
    iny
    lda     _actor_x, x
    tax
    inx
    jsr     _WorldGetAreaTile

    ; アクタの復帰
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

; 足元のタイルの属性を取得する
;
.global _ActorGetFootLeftTileAttribute
.proc   _ActorGetFootLeftTileAttribute

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = タイル
    ; WORK
    ;   ACTOR_0_WORK_0

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; タイルの取得
    ldy     _actor_y, x
    iny
    lda     _actor_x, x
    tax
    jsr     _WorldGetAreaTileAttribute

    ; アクタの復帰
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

.global _ActorGetFootRightTileAttribute
.proc   _ActorGetFootRightTileAttribute

    ; IN
    ;   x = アクタの参照
    ; OUT
    ;   a = タイル
    ; WORK
    ;   ACTOR_0_WORK_0

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; タイルの取得
    ldy     _actor_y, x
    iny
    lda     _actor_x, x
    tax
    inx
    jsr     _WorldGetAreaTileAttribute

    ; アクタの復帰
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

; 2x2 サイズのアクタのタイルを設定する
;
.global _ActorCalcTile2x2
.proc   _ActorCalcTile2x2

    ; IN
    ;   x = アクタの参照
    ;   a = タイルのベース
    ; WORK
    ;   ACTOR_0_WORK_0

    ; タイルの取得
    sta     ACTOR_0_WORK_0
    lda     _actor_animation, x
    and     #%00001000 ; ACTOR_ANIMATION_FRAME
    lsr     a
    clc
    adc     ACTOR_0_WORK_0
    sta     _actor_tile, x

    ; 終了
    rts

.endproc

; 向きを伴った 2x2 サイズのアクタのタイルを設定する
;
.global _ActorCalcDirectionTile2x2
.proc   _ActorCalcDirectionTile2x2

    ; IN
    ;   x = アクタの参照
    ;   a = タイルのベース
    ; WORK
    ;   ACTOR_0_WORK_0

    ; タイルの取得
    sta     ACTOR_0_WORK_0
    lda     _actor_direction, x
    asl     a
    asl     a
    asl     a
    clc
    adc     ACTOR_0_WORK_0
    sta     ACTOR_0_WORK_0
    lda     _actor_animation, x
    and     #%00001000 ; ACTOR_ANIMATION_FRAME
    lsr     a
    clc
    adc     ACTOR_0_WORK_0
    sta     _actor_tile, x

    ; 終了
    rts

.endproc

; 4x4 サイズのアクタのタイルを設定する
;
.global _ActorCalcTile4x4
.proc   _ActorCalcTile4x4

    ; IN
    ;   x = アクタの参照
    ;   a = タイルのベース
    ; WORK
    ;   ACTOR_0_WORK_0

    ; タイルの取得
    sta     ACTOR_0_WORK_0
    lda     _actor_animation, x
    and     #%00001000 ; ACTOR_ANIMATION_FRAME
    asl     a
    clc
    adc     ACTOR_0_WORK_0
    sta     _actor_tile, x

    ; 終了
    rts

.endproc

; アクタのタイルを描画する
;
.global _ActorDrawTile
.proc   _ActorDrawTile

    ; IN
    ;   x = アクタの参照

    ; サイズ別の描画
    ldy     _actor_class, x
    lda     actor_class_size, y
    cmp     #$04
    beq     :+
    jsr     _ActorDrawTile2x2
    jmp     :++
:
    jsr     _ActorDrawTile4x4
:

    ; 終了
    rts

.endproc

; 2x2 サイズのアクタのタイルを描画する
;
.global _ActorDrawTile2x2
.proc   _ActorDrawTile2x2

    ; IN
    ;   x = アクタの参照
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; タイルセットの取得
    ldy     _actor_class, x
    lda     actor_class_tileset_l, y
    sta     @draw_arg + $0002
    lda     actor_class_tileset_h, y
    sta     @draw_arg + $0003

    ; タイルの取得
    lda     _actor_tile, x
    sta     @draw_arg + $0004

    ; 位置の取得
    lda     _actor_x, x
    sta     ACTOR_0_WORK_0
;   clc
;   adc     #WORLD_DRAW_X
    sta     @draw_arg + $0000
    lda     _actor_y, x
    sta     ACTOR_0_WORK_1
    clc
    adc     #WORLD_DRAW_Y
    sta     @draw_arg + $0001

    ; アクタの保存
    txa
    pha

    ; 左上の描画
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; 右上の描画
    inc     @draw_arg + $0000
    inc     @draw_arg + $0004
;   inc     ACTOR_0_WORK_0
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; 左下の描画
    dec     @draw_arg + $0000
    inc     @draw_arg + $0001
    inc     @draw_arg + $0004
;   dec     ACTOR_0_WORK_0
    inc     ACTOR_0_WORK_1
    ldx     ACTOR_0_WORK_0
    ldy     ACTOR_0_WORK_1
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_HIDE
    bne     :+
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern
    jmp     :++
:
    ldx     ACTOR_0_WORK_0
    ldy     ACTOR_0_WORK_1
    jsr     _WorldDrawAreaTile
:

    ; 右下の描画
    inc     @draw_arg + $0000
    inc     @draw_arg + $0004
    inc     ACTOR_0_WORK_0
    ldx     ACTOR_0_WORK_0
    ldy     ACTOR_0_WORK_1
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_HIDE
    bne     :+
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern
    jmp     :++
:
    ldx     ACTOR_0_WORK_0
    ldy     ACTOR_0_WORK_1
    jsr     _WorldDrawAreaTile
:

    ; アクタの復帰
    pla
    tax

    ; 終了
    rts

; 描画の引数
@draw_arg:
    .byte   $00, $00
    .word   $0000
    .byte   $00

.endproc

; 4x4 サイズのアクタのタイルを描画する
;
.global _ActorDrawTile4x4
.proc   _ActorDrawTile4x4

    ; IN
    ;   x = アクタの参照
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; 左上 2x2 の描画
    jsr     _ActorDrawTile2x2

    ; 右上 2x2 の描画
    inc     _actor_x, x
    inc     _actor_x, x
    lda     _actor_tile, x
    clc
    adc     #$04
    sta     _actor_tile, x
    jsr     _ActorDrawTile2x2

    ; 左下 2x2 の描画
    dec     _actor_x, x
    dec     _actor_x, x
    inc     _actor_y, x
    inc     _actor_y, x
    lda     _actor_tile, x
    clc
    adc     #$04
    sta     _actor_tile, x
    jsr     _ActorDrawTile2x2

    ; 右下 2x2 の描画
    inc     _actor_x, x
    inc     _actor_x, x
    lda     _actor_tile, x
    clc
    adc     #$04
    sta     _actor_tile, x
    jsr     _ActorDrawTile2x2

    ; 位置の復帰
    dec     _actor_x, x
    dec     _actor_x, x
    dec     _actor_y, x
    dec     _actor_y, x

    ; タイルの復帰
    lda     _actor_tile, x
    sec
    sbc     #$0c
    sta     _actor_tile, x

    ; 終了
    rts

.endproc

; アクタの背後を描画する
;
.global _ActorDrawBack
.proc   _ActorDrawBack

    ; IN
    ;   x = アクタの参照
    ; WORK
    ;   ACTOR_0_WORK_0..3

    ; アクタの保存
    stx     ACTOR_0_WORK_0

    ; エリアタイルの描画
    ldy     _actor_class, x
    lda     _actor_direction, x
    beq     @up
    cmp     #ACTOR_DIRECTION_DOWN
    beq     @down
    cmp     #ACTOR_DIRECTION_LEFT
    beq     @left
    jmp     @right

    ; ↑
@up:
    lda     _actor_x, x
    sta     ACTOR_0_WORK_1
    lda     _actor_y, x
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_WORK_2
    jmp     @draw_h

    ; ↓
@down:
    lda     _actor_x, x
    sta     ACTOR_0_WORK_1
    lda     _actor_y, x
    sta     ACTOR_0_WORK_2
    dec     ACTOR_0_WORK_2
    jmp     @draw_h

    ; ←
@left:
    lda     _actor_x, x
    clc
    adc     actor_class_size, y
    sta     ACTOR_0_WORK_1
    lda     _actor_y, x
    sta     ACTOR_0_WORK_2
    jmp     @draw_v

    ; →
@right:
    lda     _actor_x, x
    sta     ACTOR_0_WORK_1
    dec     ACTOR_0_WORK_1
    lda     _actor_y, x
    sta     ACTOR_0_WORK_2
    jmp     @draw_v

    ; 横方向に描画
@draw_h:
    lda     actor_class_size, y
    sta     ACTOR_0_WORK_3
:
    ldx     ACTOR_0_WORK_1
    ldy     ACTOR_0_WORK_2
    jsr     _WorldDrawAreaTile
    inc     ACTOR_0_WORK_1
    dec     ACTOR_0_WORK_3
    bne     :-
    jmp     @end

    ; 縦方向に描画
@draw_v:
    lda     actor_class_size, y
    sta     ACTOR_0_WORK_3
:
    ldx     ACTOR_0_WORK_1
    ldy     ACTOR_0_WORK_2
    jsr     _WorldDrawAreaTile
    inc     ACTOR_0_WORK_2
    dec     ACTOR_0_WORK_3
    bne     :-
;   jmp     @end

    ; アクタの復帰
@end:
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

.endproc

; 2x2 サイズのアクタを描画する
;
.global _ActorDraw2x2
.proc   _ActorDraw2x2

    ; IN
    ;   x = アクタの参照

    ; 地形の描画
    ldy     _actor_class, x
    lda     _actor_draw, x
    and     #ACTOR_DRAW_LAND
    beq     @tile
    jsr     _ActorDrawLand2x2
    jmp     @back

    ; タイルの描画
@tile:
    lda     _actor_draw, x
    and     #ACTOR_DRAW_DIRECTION
    bne     :+
    lda     actor_class_tile, y
    jsr     _ActorCalcTile2x2
    jmp     :++
:
    lda     actor_class_tile, y
    jsr     _ActorCalcDirectionTile2x2
:
    jsr     _ActorDrawTile2x2
;   jmp     @back

    ; 背後の描画
@back:
    lda     _actor_draw, x
    and     #ACTOR_DRAW_BACK
    beq     :+
    jsr     _ActorDrawBack
    lda     _actor_draw, x
    and     #(~ACTOR_DRAW_BACK & $ff)
    sta     _actor_draw, x
:

    ; 終了
    rts

.endproc

; 4x4 サイズのアクタを描画する
;
.global _ActorDraw4x4
.proc   _ActorDraw4x4

    ; IN
    ;   x = アクタの参照

    ; タイルの取得
    ldy     _actor_class, x
    lda     actor_class_tile, y
    jsr     _ActorCalcTile4x4

    ; アクタの描画
    jsr     _ActorDrawTile4x4

    ; 背後の描画
@back:
    lda     _actor_draw, x
    and     #ACTOR_DRAW_BACK
    beq     :+
    jsr     _ActorDrawBack
    lda     _actor_draw, x
    and     #(~ACTOR_DRAW_BACK & $ff)
    sta     _actor_draw, x
:

    ; 終了
    rts

.endproc

; エフェクトを描画する
;
.global _ActorDrawEffect
.proc   _ActorDrawEffect

    ; IN
    ;   x = アクタの参照
    ;   a = エフェクト

    ; サイズ別の描画
    pha
    ldy     _actor_class, x
    lda     actor_class_size, y
    tay
    pla
    cpy     #$04
    beq     :+
    jsr     _ActorDrawEffect2x2
    jmp     :++
:
    jsr     _ActorDrawEffect4x4
:

    ; 終了
    rts

.endproc

; 2x2 サイズのエフェクトを描画する
;
.global _ActorDrawEffect2x2
.proc   _ActorDrawEffect2x2

    ; IN
    ;   x = アクタの参照
    ;   a = エフェクト

    ; タイルの取得
    asl     a
    asl     a
    sta     @draw_arg + $0004

    ; 位置の取得
    lda     _actor_x, x
;   clc
;   adc     #WORLD_DRAW_X
    sta     @draw_arg + $0000
    lda     _actor_y, x
    clc
    adc     #WORLD_DRAW_Y
    sta     @draw_arg + $0001

    ; アクタの保存
    txa
    pha

    ; 左上の描画
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; 右上の描画
    inc     @draw_arg + $0000
    inc     @draw_arg + $0004
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; 左下の描画
    dec     @draw_arg + $0000
    inc     @draw_arg + $0001
    inc     @draw_arg + $0004
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; 右下の描画
    inc     @draw_arg + $0000
    inc     @draw_arg + $0004
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; アクタの復帰
    pla
    tax

    ; 終了
    rts

; 描画の引数
@draw_arg:
    .byte   $00, $00
    .word   actor_effect_tileset
    .byte   $00

.endproc

; 4x4 サイズのエフェクトを描画する
;
.global _ActorDrawEffect4x4
.proc   _ActorDrawEffect4x4

    ; IN
    ;   x = アクタの参照
    ;   a = エフェクト

    ; 左上 2x2 の描画
    pha
    jsr     _ActorDrawEffect2x2
    pla

    ; 右上 2x2 の描画
    inc     _actor_x, x
    inc     _actor_x, x
    pha
    jsr     _ActorDrawEffect2x2
    pla

    ; 右下 2x2 の描画
    inc     _actor_y, x
    inc     _actor_y, x
    pha
    jsr     _ActorDrawEffect2x2
    pla

    ; 左下 2x2 の描画
    dec     _actor_x, x
    dec     _actor_x, x
    pha
    jsr     _ActorDrawEffect2x2
    pla

    ; 位置の復帰
    dec     _actor_y, x
    dec     _actor_y, x

    ; 終了
    rts

.endproc

; 地形を描画する
;
.global _ActorDrawLand
.proc   _ActorDrawLand

    ; IN
    ;   x = アクタの参照

    ; サイズ別の描画
    ldy     _actor_class, x
    lda     actor_class_size, y
    cmp     #$04
    beq     :+
    jsr     _ActorDrawLand2x2
    jmp     :++
:
    jsr     _ActorDrawLand4x4
:

    ; 終了
    rts

.endproc

; 2x2 サイズの地形を描画する
;
.global _ActorDrawLand2x2
.proc   _ActorDrawLand2x2

    ; IN
    ;   x = アクタの参照
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; 位置の取得
    lda     _actor_x, x
    sta     ACTOR_0_WORK_0
    lda     _actor_y, x
    sta     ACTOR_0_WORK_1

    ; x の保存
    txa
    pha

    ; 左上の描画
    ldx     ACTOR_0_WORK_0
    ldy     ACTOR_0_WORK_1
    jsr     _WorldDrawAreaTile

    ; 右上の描画
    ldx     ACTOR_0_WORK_0
    inx
    ldy     ACTOR_0_WORK_1
    jsr     _WorldDrawAreaTile

    ; 左下の描画
    ldx     ACTOR_0_WORK_0
    ldy     ACTOR_0_WORK_1
    iny
    jsr     _WorldDrawAreaTile

    ; 右下の描画
    ldx     ACTOR_0_WORK_0
    inx
    ldy     ACTOR_0_WORK_1
    iny
    jsr     _WorldDrawAreaTile

    ; x の復帰
    pla
    tax

    ; 終了
    rts

.endproc

; 4x4 サイズの地形を描画する
;
.global _ActorDrawLand4x4
.proc   _ActorDrawLand4x4

    ; IN
    ;   x = アクタの参照
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; 左上 2x2 の描画
    jsr     _ActorDrawLand2x2
    
    ; 右上 2x2 の描画
    inc     _actor_x, x
    inc     _actor_x, x
    jsr     _ActorDrawLand2x2
    
    ; 右下 2x2 の描画
    inc     _actor_y, x
    inc     _actor_y, x
    jsr     _ActorDrawLand2x2
    
    ; 左下 2x2 の描画
    dec     _actor_x, x
    dec     _actor_x, x
    jsr     _ActorDrawLand2x2
    
    ; 位置の復帰
    dec     _actor_y, x
    dec     _actor_y, x

    ; 終了
    rts

.endproc

; アクタの情報を描画する
;
.proc   ActorDrawInformation

    ; IN
    ;   x = アクタの参照
    ; WORK
    ;   ACTOR_0_WORK_0..1

    ; アクタの保存
    stx     ACTOR_0_WORK_0
    ldy     _actor_class, x
    sty     ACTOR_0_WORK_1

    ; 情報のクリア
    jsr     _GameClearInformation

    ; 名前の描画
    ldy     ACTOR_0_WORK_1
    lda     actor_class_name_l, y
    sta     @name_arg + $0002
    lda     actor_class_name_h, y
    sta     @name_arg + $0003
    ldx     #<@name_arg
    lda     #>@name_arg
    jsr     _IocsDrawString

    ; タイルの描画
    ldy     ACTOR_0_WORK_1
    lda     #$20
    sta     @tile_arg + $0000
    lda     #$13
    sta     @tile_arg + $0001
    lda     actor_class_tileset_l, y
    sta     @tile_arg + $0002
    lda     actor_class_tileset_h, y
    sta     @tile_arg + $0003
    lda     actor_class_tile_information, y
    sta     @tile_arg + $0004
    jsr     @tile_2x2
    ldy     ACTOR_0_WORK_1
    lda     actor_class_size, y
    cmp     #$04
    bne     :+
    lda     #$22
    sta     @tile_arg + $0000
;   lda     @tile_arg + $0004
;   clc
;   adc     #$04
;   sta     @tile_arg + $0004
    inc     @tile_arg + $0004
    jsr     @tile_2x2
:

    ; バーの描画
    ldx     ACTOR_0_WORK_0
    lda     _actor_life, x
    jsr     @range
    ldx     #$01
    ldy     #$15
    jsr     _GameDrawStatusBar
    ldy     ACTOR_0_WORK_1
    lda     actor_class_life, y
    jsr     @range
    ldy     #$15
    jsr     _GameDrawStatusLine
    ldx     #$1f
    lda     #%01111110
    sta     $2750, x
    lda     #%01111111
:
    sta     $2750, x
    inx
    cpx     #$27
    bne     :-
    lda     #%00011111
    sta     $2750, x

    ; アクタの復帰
    ldx     ACTOR_0_WORK_0

    ; 終了
    rts

    ; 値の調整
@range:
    and     #$ff
    beq     :+
    lsr     a
    lsr     a
    bne     :+
    lda     #$01
:
    rts

    ; 2x2 タイルの描画
@tile_2x2:

    ; 左上の描画
    ldx     #<@tile_arg
    lda     #>@tile_arg
    jsr     _IocsDraw7x8Pattern

    ; 右上の描画
    inc     @tile_arg + $0000
    inc     @tile_arg + $0004
    ldx     #<@tile_arg
    lda     #>@tile_arg
    jsr     _IocsDraw7x8Pattern

    ; 左下の描画
    dec     @tile_arg + $0000
    inc     @tile_arg + $0001
    inc     @tile_arg + $0004
    ldx     #<@tile_arg
    lda     #>@tile_arg
    jsr     _IocsDraw7x8Pattern

    ; 右下の描画
    inc     @tile_arg + $0000
    inc     @tile_arg + $0004
    ldx     #<@tile_arg
    lda     #>@tile_arg
    jsr     _IocsDraw7x8Pattern

    ; 位置の復帰
    dec     @tile_arg + $0000
    dec     @tile_arg + $0001
    rts

; 名前の引数
@name_arg:
    .byte   $1f, $12
    .word   $0000

; タイルの引数
@tile_arg:
    .byte   $00, $00
    .word   $0000
    .byte   $00

.endproc

; タイルセットを読み込む
;
.global _ActorLoadTileset
.proc   _ActorLoadTileset

    ; IN
    ;   a = レイヤ

    ; ファイル名の設定
    clc
    adc     #'0'
    sta     @load_name + $0005

    ; バイナリの読み込み
    ldx     #<@load_arg
    lda     #>@load_arg
    jsr     _IocsBload

    ; 終了
    rts

; 読み込みの引数
@load_arg:
    .word   @load_name
    .word   actor_enemy_tileset
@load_name:
    .asciiz "ENEMY0"

.endproc

; クラスの情報
;

; 種類
actor_class_type:

    .byte   ACTOR_TYPE_NULL             ; ACTOR_CLASS_NULL
    .byte   ACTOR_TYPE_PLAYER           ; ACTOR_CLASS_PLAYER
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_ORC
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_LIZARD
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_SLIME
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_SKELETON
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_SERPENT
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_SPIDER
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_GREMLIN
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_BAT
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_ZORN
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_PHANTOM
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_CYCLOPSE
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_WIZARD
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_HYDRA
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_DEVIL 
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_DRAGON
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_TREE
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_ROCK
    .byte   ACTOR_TYPE_ENEMY            ; ACTOR_CLASS_CACTUS
    .byte   ACTOR_TYPE_MAGIC            ; ACTOR_CLASS_BALL_PLAYER
    .byte   ACTOR_TYPE_MAGIC            ; ACTOR_CLASS_BALL_ZORN
    .byte   ACTOR_TYPE_MAGIC            ; ACTOR_CLASS_BALL_WIZARD
    .byte   ACTOR_TYPE_MAGIC            ; ACTOR_CLASS_BALL_HYDRA
    .byte   ACTOR_TYPE_MAGIC            ; ACTOR_CLASS_BALL_DEVIL 
    .byte   ACTOR_TYPE_MAGIC            ; ACTOR_CLASS_BALL_DRAGON

; 名前
actor_class_name_l:

    .byte   <actor_class_name_null      ; ACTOR_CLASS_NULL
    .byte   <actor_class_name_player    ; ACTOR_CLASS_PLAYER
    .byte   <actor_class_name_orc       ; ACTOR_CLASS_ORC
    .byte   <actor_class_name_zorn      ; ACTOR_CLASS_LIZARD
    .byte   <actor_class_name_slime     ; ACTOR_CLASS_SLIME
    .byte   <actor_class_name_skeleton  ; ACTOR_CLASS_SKELETON
    .byte   <actor_class_name_serpent   ; ACTOR_CLASS_SERPENT
    .byte   <actor_class_name_spider    ; ACTOR_CLASS_SPIDER
    .byte   <actor_class_name_gremlin   ; ACTOR_CLASS_GREMLIN
    .byte   <actor_class_name_bat       ; ACTOR_CLASS_BAT
    .byte   <actor_class_name_lizard    ; ACTOR_CLASS_ZORN
    .byte   <actor_class_name_phantom   ; ACTOR_CLASS_PHANTOM
    .byte   <actor_class_name_cyclopse  ; ACTOR_CLASS_CYCLOPSE
    .byte   <actor_class_name_wizard    ; ACTOR_CLASS_WIZARD
    .byte   <actor_class_name_hydra     ; ACTOR_CLASS_HYDRA
    .byte   <actor_class_name_devil     ; ACTOR_CLASS_DEVIL 
    .byte   <actor_class_name_dragon    ; ACTOR_CLASS_DRAGON
    .byte   <actor_class_name_tree      ; ACTOR_CLASS_TREE
    .byte   <actor_class_name_rock      ; ACTOR_CLASS_ROCK
    .byte   <actor_class_name_cactus    ; ACTOR_CLASS_CACTUS
    .byte   <actor_class_name_ball      ; ACTOR_CLASS_BALL_PLAYER
    .byte   <actor_class_name_ball      ; ACTOR_CLASS_BALL_ZORN
    .byte   <actor_class_name_ball      ; ACTOR_CLASS_BALL_WIZARD
    .byte   <actor_class_name_ball      ; ACTOR_CLASS_BALL_HYDRA
    .byte   <actor_class_name_ball      ; ACTOR_CLASS_BALL_DEVIL 
    .byte   <actor_class_name_ball      ; ACTOR_CLASS_BALL_DRAGON

actor_class_name_h:

    .byte   >actor_class_name_null      ; ACTOR_CLASS_NULL
    .byte   >actor_class_name_player    ; ACTOR_CLASS_PLAYER
    .byte   >actor_class_name_orc       ; ACTOR_CLASS_ORC
    .byte   >actor_class_name_zorn      ; ACTOR_CLASS_LIZARD
    .byte   >actor_class_name_slime     ; ACTOR_CLASS_SLIME
    .byte   >actor_class_name_skeleton  ; ACTOR_CLASS_SKELETON
    .byte   >actor_class_name_serpent   ; ACTOR_CLASS_SERPENT
    .byte   >actor_class_name_spider    ; ACTOR_CLASS_SPIDER
    .byte   >actor_class_name_gremlin   ; ACTOR_CLASS_GREMLIN
    .byte   >actor_class_name_bat       ; ACTOR_CLASS_BAT
    .byte   >actor_class_name_lizard    ; ACTOR_CLASS_ZORN
    .byte   >actor_class_name_phantom   ; ACTOR_CLASS_PHANTOM
    .byte   >actor_class_name_cyclopse  ; ACTOR_CLASS_CYCLOPSE
    .byte   >actor_class_name_wizard    ; ACTOR_CLASS_WIZARD
    .byte   >actor_class_name_hydra     ; ACTOR_CLASS_HYDRA
    .byte   >actor_class_name_devil     ; ACTOR_CLASS_DEVIL 
    .byte   >actor_class_name_dragon    ; ACTOR_CLASS_DRAGON
    .byte   >actor_class_name_tree      ; ACTOR_CLASS_TREE
    .byte   >actor_class_name_rock      ; ACTOR_CLASS_ROCK
    .byte   >actor_class_name_cactus    ; ACTOR_CLASS_CACTUS
    .byte   >actor_class_name_ball      ; ACTOR_CLASS_BALL_PLAYER
    .byte   >actor_class_name_ball      ; ACTOR_CLASS_BALL_ZORN
    .byte   >actor_class_name_ball      ; ACTOR_CLASS_BALL_WIZARD
    .byte   >actor_class_name_ball      ; ACTOR_CLASS_BALL_HYDRA
    .byte   >actor_class_name_ball      ; ACTOR_CLASS_BALL_DEVIL 
    .byte   >actor_class_name_ball      ; ACTOR_CLASS_BALL_DRAGON

actor_class_name_null:                  ; ACTOR_CLASS_NULL
    .asciiz ""
actor_class_name_player:                ; ACTOR_CLASS_PLAYER
    .asciiz "HERO"
actor_class_name_orc:                   ; ACTOR_CLASS_ORC
    .asciiz "ORC"
actor_class_name_zorn:                  ; ACTOR_CLASS_LIZARD
    .asciiz "LIZARD"
actor_class_name_slime:                 ; ACTOR_CLASS_SLIME
    .asciiz "SLIME"
actor_class_name_skeleton:              ; ACTOR_CLASS_SKELETON
    .asciiz "SKELTON"
actor_class_name_serpent:               ; ACTOR_CLASS_SERPENT
    .asciiz "SERPENT"
actor_class_name_spider:                ; ACTOR_CLASS_SPIDER
    .asciiz "SPIDER"
actor_class_name_gremlin:               ; ACTOR_CLASS_GREMLIN
    .asciiz "GREMLIN"
actor_class_name_bat:                   ; ACTOR_CLASS_BAT
    .asciiz "BAT"
actor_class_name_lizard:                ; ACTOR_CLASS_ZORN
    .asciiz "ZORN"
actor_class_name_phantom:               ; ACTOR_CLASS_PHANTOM
    .asciiz "PHANTOM"
actor_class_name_cyclopse:              ; ACTOR_CLASS_CYCLOPSE
    .asciiz "CYCLOPSE"
actor_class_name_wizard:                ; ACTOR_CLASS_WIZARD
    .asciiz "WIZARD"
actor_class_name_hydra:                 ; ACTOR_CLASS_HYDRA
    .asciiz "HYDRA"
actor_class_name_devil:                 ; ACTOR_CLASS_DEVIL 
    .asciiz "DEVIL"
actor_class_name_dragon:                ; ACTOR_CLASS_DRAGON
    .asciiz "DRAGON"
actor_class_name_tree:                  ; ACTOR_CLASS_TREE
    .asciiz "TREE"
actor_class_name_rock:                  ; ACTOR_CLASS_ROCK
    .asciiz "ROCK"
actor_class_name_cactus:                ; ACTOR_CLASS_CACTUS
    .asciiz "CACTUS"
actor_class_name_ball:                  ; ACTOR_CLASS_BALL_xxx
    .asciiz "MAGICBALL"

; 行動の処理
actor_class_play_proc_l:

    .byte   <ActorNull                  ; ACTOR_CLASS_NULL
    .byte   <_ActorPlayerPlay           ; ACTOR_CLASS_PLAYER
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_ORC
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_LIZARD
    .byte   <_ActorSlimePlay            ; ACTOR_CLASS_SLIME
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_SKELETON
    .byte   <_ActorSerpentPlay          ; ACTOR_CLASS_SERPENT
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_SPIDER
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_GREMLIN
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_BAT
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_ZORN
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_PHANTOM
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_CYCLOPSE
    .byte   <_ActorWizardPlay           ; ACTOR_CLASS_WIZARD
    .byte   <_ActorHydraPlay            ; ACTOR_CLASS_HYDRA
    .byte   <_ActorEnemyWalk            ; ACTOR_CLASS_DEVIL 
    .byte   <_ActorDragonPlay           ; ACTOR_CLASS_DRAGON
    .byte   <_ActorEnemyStay            ; ACTOR_CLASS_TREE
    .byte   <_ActorEnemyStay            ; ACTOR_CLASS_ROCK
    .byte   <_ActorEnemyStay            ; ACTOR_CLASS_CACTUS
    .byte   <_ActorBallPlay             ; ACTOR_CLASS_BALL_PLAYER
    .byte   <_ActorBallPlay             ; ACTOR_CLASS_BALL_ZORN
    .byte   <_ActorBallPlay             ; ACTOR_CLASS_BALL_WIZARD
    .byte   <_ActorBallPlay             ; ACTOR_CLASS_BALL_HYDRA
    .byte   <_ActorBallPlay             ; ACTOR_CLASS_BALL_DEVIL 
    .byte   <_ActorBallPlay             ; ACTOR_CLASS_BALL_DRAGON

actor_class_play_proc_h:

    .byte   >ActorNull                  ; ACTOR_CLASS_NULL
    .byte   >_ActorPlayerPlay           ; ACTOR_CLASS_PLAYER
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_ORC
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_LIZARD
    .byte   >_ActorSlimePlay            ; ACTOR_CLASS_SLIME
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_SKELETON
    .byte   >_ActorSerpentPlay          ; ACTOR_CLASS_SERPENT
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_SPIDER
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_GREMLIN
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_BAT
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_ZORN
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_PHANTOM
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_CYCLOPSE
    .byte   >_ActorWizardPlay           ; ACTOR_CLASS_WIZARD
    .byte   >_ActorHydraPlay            ; ACTOR_CLASS_HYDRA
    .byte   >_ActorEnemyWalk            ; ACTOR_CLASS_DEVIL 
    .byte   >_ActorDragonPlay           ; ACTOR_CLASS_DRAGON
    .byte   >_ActorEnemyStay            ; ACTOR_CLASS_TREE
    .byte   >_ActorEnemyStay            ; ACTOR_CLASS_ROCK
    .byte   >_ActorEnemyStay            ; ACTOR_CLASS_CACTUS
    .byte   >_ActorBallPlay             ; ACTOR_CLASS_BALL_PLAYER
    .byte   >_ActorBallPlay             ; ACTOR_CLASS_BALL_ZORN
    .byte   >_ActorBallPlay             ; ACTOR_CLASS_BALL_WIZARD
    .byte   >_ActorBallPlay             ; ACTOR_CLASS_BALL_HYDRA
    .byte   >_ActorBallPlay             ; ACTOR_CLASS_BALL_DEVIL 
    .byte   >_ActorBallPlay             ; ACTOR_CLASS_BALL_DRAGON

; 読み込みの処理
actor_class_load_proc_l:

    .byte   <ActorNull                  ; ACTOR_CLASS_NULL
    .byte   <_ActorPlayerLoad           ; ACTOR_CLASS_PLAYER
    .byte   <_ActorOrcLoad              ; ACTOR_CLASS_ORC
    .byte   <_ActorLizardLoad           ; ACTOR_CLASS_LIZARD
    .byte   <_ActorSlimeLoad            ; ACTOR_CLASS_SLIME
    .byte   <_ActorSkeletonLoad         ; ACTOR_CLASS_SKELETON
    .byte   <_ActorSerpentLoad          ; ACTOR_CLASS_SERPENT
    .byte   <_ActorSpiderLoad           ; ACTOR_CLASS_SPIDER
    .byte   <_ActorGremlinLoad          ; ACTOR_CLASS_GREMLIN
    .byte   <_ActorBatLoad              ; ACTOR_CLASS_BAT
    .byte   <_ActorZornLoad             ; ACTOR_CLASS_ZORN
    .byte   <_ActorPhantomLoad          ; ACTOR_CLASS_PHANTOM
    .byte   <_ActorCyclopseLoad         ; ACTOR_CLASS_CYCLOPSE
    .byte   <_ActorWizardLoad           ; ACTOR_CLASS_WIZARD
    .byte   <_ActorHydraLoad            ; ACTOR_CLASS_HYDRA
    .byte   <_ActorDevilLoad            ; ACTOR_CLASS_DEVIL 
    .byte   <_ActorDragonLoad           ; ACTOR_CLASS_DRAGON
    .byte   <_ActorTreeLoad             ; ACTOR_CLASS_TREE
    .byte   <_ActorRockLoad             ; ACTOR_CLASS_ROCK
    .byte   <_ActorCactusLoad           ; ACTOR_CLASS_CACTUS
    .byte   <_ActorBallLoad             ; ACTOR_CLASS_BALL_PLAYER
    .byte   <_ActorBallLoad             ; ACTOR_CLASS_BALL_ZORN
    .byte   <_ActorBallLoad             ; ACTOR_CLASS_BALL_WIZARD
    .byte   <_ActorBallLoad             ; ACTOR_CLASS_BALL_HYDRA
    .byte   <_ActorBallLoad             ; ACTOR_CLASS_BALL_DEVIL 
    .byte   <_ActorBallLoad             ; ACTOR_CLASS_BALL_DRAGON

actor_class_load_proc_h:

    .byte   >ActorNull                  ; ACTOR_CLASS_NULL
    .byte   >_ActorPlayerLoad           ; ACTOR_CLASS_PLAYER
    .byte   >_ActorOrcLoad              ; ACTOR_CLASS_ORC
    .byte   >_ActorLizardLoad           ; ACTOR_CLASS_LIZARD
    .byte   >_ActorSlimeLoad            ; ACTOR_CLASS_SLIME
    .byte   >_ActorSkeletonLoad         ; ACTOR_CLASS_SKELETON
    .byte   >_ActorSerpentLoad          ; ACTOR_CLASS_SERPENT
    .byte   >_ActorSpiderLoad           ; ACTOR_CLASS_SPIDER
    .byte   >_ActorGremlinLoad          ; ACTOR_CLASS_GREMLIN
    .byte   >_ActorBatLoad              ; ACTOR_CLASS_BAT
    .byte   >_ActorZornLoad             ; ACTOR_CLASS_ZORN
    .byte   >_ActorPhantomLoad          ; ACTOR_CLASS_PHANTOM
    .byte   >_ActorCyclopseLoad         ; ACTOR_CLASS_CYCLOPSE
    .byte   >_ActorWizardLoad           ; ACTOR_CLASS_WIZARD
    .byte   >_ActorHydraLoad            ; ACTOR_CLASS_HYDRA
    .byte   >_ActorDevilLoad            ; ACTOR_CLASS_DEVIL 
    .byte   >_ActorDragonLoad           ; ACTOR_CLASS_DRAGON
    .byte   >_ActorTreeLoad             ; ACTOR_CLASS_TREE
    .byte   >_ActorRockLoad             ; ACTOR_CLASS_ROCK
    .byte   >_ActorCactusLoad           ; ACTOR_CLASS_CACTUS
    .byte   >_ActorBallLoad             ; ACTOR_CLASS_BALL_PLAYER
    .byte   >_ActorBallLoad             ; ACTOR_CLASS_BALL_ZORN
    .byte   >_ActorBallLoad             ; ACTOR_CLASS_BALL_WIZARD
    .byte   >_ActorBallLoad             ; ACTOR_CLASS_BALL_HYDRA
    .byte   >_ActorBallLoad             ; ACTOR_CLASS_BALL_DEVIL 
    .byte   >_ActorBallLoad             ; ACTOR_CLASS_BALL_DRAGON

; 破棄の処理
actor_class_unload_proc_l:

    .byte   <ActorNull                  ; ACTOR_CLASS_NULL
    .byte   <_ActorPlayerUnload         ; ACTOR_CLASS_PLAYER
    .byte   <_ActorOrcUnload            ; ACTOR_CLASS_ORC
    .byte   <_ActorLizardUnload         ; ACTOR_CLASS_LIZARD
    .byte   <_ActorSlimeUnload          ; ACTOR_CLASS_SLIME
    .byte   <_ActorSkeletonUnload       ; ACTOR_CLASS_SKELETON
    .byte   <_ActorSerpentUnload        ; ACTOR_CLASS_SERPENT
    .byte   <_ActorSpiderUnload         ; ACTOR_CLASS_SPIDER
    .byte   <_ActorGremlinUnload        ; ACTOR_CLASS_GREMLIN
    .byte   <_ActorBatUnload            ; ACTOR_CLASS_BAT
    .byte   <_ActorZornUnload           ; ACTOR_CLASS_ZORN
    .byte   <_ActorPhantomUnload        ; ACTOR_CLASS_PHANTOM
    .byte   <_ActorCyclopseUnload       ; ACTOR_CLASS_CYCLOPSE
    .byte   <_ActorWizardUnload         ; ACTOR_CLASS_WIZARD
    .byte   <_ActorHydraUnload          ; ACTOR_CLASS_HYDRA
    .byte   <_ActorDevilUnload          ; ACTOR_CLASS_DEVIL 
    .byte   <_ActorDragonUnload         ; ACTOR_CLASS_DRAGON
    .byte   <_ActorTreeUnload           ; ACTOR_CLASS_TREE
    .byte   <_ActorRockUnload           ; ACTOR_CLASS_ROCK
    .byte   <_ActorCactusUnload         ; ACTOR_CLASS_CACTUS
    .byte   <_ActorBallUnload           ; ACTOR_CLASS_BALL_PLAYER
    .byte   <_ActorBallUnload           ; ACTOR_CLASS_BALL_ZORN
    .byte   <_ActorBallUnload           ; ACTOR_CLASS_BALL_WIZARD
    .byte   <_ActorBallUnload           ; ACTOR_CLASS_BALL_HYDRA
    .byte   <_ActorBallUnload           ; ACTOR_CLASS_BALL_DEVIL 
    .byte   <_ActorBallUnload           ; ACTOR_CLASS_BALL_DRAGON

actor_class_unload_proc_h:

    .byte   >ActorNull                  ; ACTOR_CLASS_NULL
    .byte   >_ActorPlayerUnload         ; ACTOR_CLASS_PLAYER
    .byte   >_ActorOrcUnload            ; ACTOR_CLASS_ORC
    .byte   >_ActorLizardUnload         ; ACTOR_CLASS_LIZARD
    .byte   >_ActorSlimeUnload          ; ACTOR_CLASS_SLIME
    .byte   >_ActorSkeletonUnload       ; ACTOR_CLASS_SKELETON
    .byte   >_ActorSerpentUnload        ; ACTOR_CLASS_SERPENT
    .byte   >_ActorSpiderUnload         ; ACTOR_CLASS_SPIDER
    .byte   >_ActorGremlinUnload        ; ACTOR_CLASS_GREMLIN
    .byte   >_ActorBatUnload            ; ACTOR_CLASS_BAT
    .byte   >_ActorZornUnload           ; ACTOR_CLASS_ZORN
    .byte   >_ActorPhantomUnload        ; ACTOR_CLASS_PHANTOM
    .byte   >_ActorCyclopseUnload       ; ACTOR_CLASS_CYCLOPSE
    .byte   >_ActorWizardUnload         ; ACTOR_CLASS_WIZARD
    .byte   >_ActorHydraUnload          ; ACTOR_CLASS_HYDRA
    .byte   >_ActorDevilUnload          ; ACTOR_CLASS_DEVIL 
    .byte   >_ActorDragonUnload         ; ACTOR_CLASS_DRAGON
    .byte   >_ActorTreeUnload           ; ACTOR_CLASS_TREE
    .byte   >_ActorRockUnload           ; ACTOR_CLASS_ROCK
    .byte   >_ActorCactusUnload         ; ACTOR_CLASS_CACTUS
    .byte   >_ActorBallUnload           ; ACTOR_CLASS_BALL_PLAYER
    .byte   >_ActorBallUnload           ; ACTOR_CLASS_BALL_ZORN
    .byte   >_ActorBallUnload           ; ACTOR_CLASS_BALL_WIZARD
    .byte   >_ActorBallUnload           ; ACTOR_CLASS_BALL_HYDRA
    .byte   >_ActorBallUnload           ; ACTOR_CLASS_BALL_DEVIL 
    .byte   >_ActorBallUnload           ; ACTOR_CLASS_BALL_DRAGON

; 体力
actor_class_life:

    .byte   0                           ; ACTOR_CLASS_NULL
    .byte   30                          ; ACTOR_CLASS_PLAYER
    .byte   9                           ; ACTOR_CLASS_ORC
    .byte   23                          ; ACTOR_CLASS_LIZARD
    .byte   5                           ; ACTOR_CLASS_SLIME
    .byte   13                          ; ACTOR_CLASS_SKELETON
    .byte   29                          ; ACTOR_CLASS_SERPENT
    .byte   9                           ; ACTOR_CLASS_SPIDER
    .byte   12                          ; ACTOR_CLASS_GREMLIN
    .byte   7                           ; ACTOR_CLASS_BAT
    .byte   17                          ; ACTOR_CLASS_ZORN
    .byte   23                          ; ACTOR_CLASS_PHANTOM
    .byte   54                          ; ACTOR_CLASS_CYCLOPSE
    .byte   24                          ; ACTOR_CLASS_WIZARD
    .byte   42                          ; ACTOR_CLASS_HYDRA
    .byte   66                          ; ACTOR_CLASS_DEVIL 
    .byte   255                         ; ACTOR_CLASS_DRAGON
    .byte   8                           ; ACTOR_CLASS_TREE
    .byte   8                           ; ACTOR_CLASS_ROCK
    .byte   8                           ; ACTOR_CLASS_CACTUS
    .byte   1                           ; ACTOR_CLASS_BALL_PLAYER
    .byte   1                           ; ACTOR_CLASS_BALL_ZORN
    .byte   1                           ; ACTOR_CLASS_BALL_WIZARD
    .byte   1                           ; ACTOR_CLASS_BALL_HYDRA
    .byte   1                           ; ACTOR_CLASS_BALL_DEVIL 
    .byte   1                           ; ACTOR_CLASS_BALL_DRAGON

; 強さ
actor_class_strength:

    .byte   0                           ; ACTOR_CLASS_NULL
    .byte   0                           ; ACTOR_CLASS_PLAYER
    .byte   3                           ; ACTOR_CLASS_ORC
    .byte   6                           ; ACTOR_CLASS_LIZARD
    .byte   1                           ; ACTOR_CLASS_SLIME
    .byte   4                           ; ACTOR_CLASS_SKELETON
    .byte   7                           ; ACTOR_CLASS_SERPENT
    .byte   2                           ; ACTOR_CLASS_SPIDER
    .byte   3                           ; ACTOR_CLASS_GREMLIN
    .byte   2                           ; ACTOR_CLASS_BAT
    .byte   5                           ; ACTOR_CLASS_ZORN
    .byte   6                           ; ACTOR_CLASS_PHANTOM
    .byte   8                           ; ACTOR_CLASS_CYCLOPSE
    .byte   5                           ; ACTOR_CLASS_WIZARD
    .byte   7                           ; ACTOR_CLASS_HYDRA
    .byte   9                           ; ACTOR_CLASS_DEVIL 
    .byte   10                          ; ACTOR_CLASS_DRAGON
    .byte   0                           ; ACTOR_CLASS_TREE
    .byte   0                           ; ACTOR_CLASS_ROCK
    .byte   0                           ; ACTOR_CLASS_CACTUS
    .byte   1                           ; ACTOR_CLASS_BALL_PLAYER
    .byte   5                           ; ACTOR_CLASS_BALL_ZORN
    .byte   5                           ; ACTOR_CLASS_BALL_WIZARD
    .byte   7                           ; ACTOR_CLASS_BALL_HYDRA
    .byte   9                           ; ACTOR_CLASS_BALL_DEVIL 
    .byte   10                          ; ACTOR_CLASS_BALL_DRAGON

; 経験値
actor_class_experience:

    .byte   0                           ; ACTOR_CLASS_NULL
    .byte   0                           ; ACTOR_CLASS_PLAYER
    .byte   4                           ; ACTOR_CLASS_ORC
    .byte   4                           ; ACTOR_CLASS_LIZARD
    .byte   4                           ; ACTOR_CLASS_SLIME
    .byte   4                           ; ACTOR_CLASS_SKELETON
    .byte   4                           ; ACTOR_CLASS_SERPENT
    .byte   4                           ; ACTOR_CLASS_SPIDER
    .byte   4                           ; ACTOR_CLASS_GREMLIN
    .byte   4                           ; ACTOR_CLASS_BAT
    .byte   4                           ; ACTOR_CLASS_ZORN
    .byte   4                           ; ACTOR_CLASS_PHANTOM
    .byte   4                           ; ACTOR_CLASS_CYCLOPSE
    .byte   4                           ; ACTOR_CLASS_WIZARD
    .byte   4                           ; ACTOR_CLASS_HYDRA
    .byte   4                           ; ACTOR_CLASS_DEVIL 
    .byte   4                           ; ACTOR_CLASS_DRAGON
    .byte   0                           ; ACTOR_CLASS_TREE
    .byte   0                           ; ACTOR_CLASS_ROCK
    .byte   0                           ; ACTOR_CLASS_CACTUS
    .byte   0                           ; ACTOR_CLASS_BALL_PLAYER
    .byte   0                           ; ACTOR_CLASS_BALL_ZORN
    .byte   0                           ; ACTOR_CLASS_BALL_WIZARD
    .byte   0                           ; ACTOR_CLASS_BALL_HYDRA
    .byte   0                           ; ACTOR_CLASS_BALL_DEVIL 
    .byte   0                           ; ACTOR_CLASS_BALL_DRAGON

; 攻撃力
actor_class_attack:

    .byte   0                           ; ACTOR_CLASS_NULL
    .byte   1                           ; ACTOR_CLASS_PLAYER
    .byte   7                           ; ACTOR_CLASS_ORC
    .byte   12                          ; ACTOR_CLASS_LIZARD
    .byte   5                           ; ACTOR_CLASS_SLIME
    .byte   10                          ; ACTOR_CLASS_SKELETON
    .byte   13                          ; ACTOR_CLASS_SERPENT
    .byte   6                           ; ACTOR_CLASS_SPIDER
    .byte   8                           ; ACTOR_CLASS_GREMLIN
    .byte   5                           ; ACTOR_CLASS_BAT
    .byte   10                          ; ACTOR_CLASS_ZORN
    .byte   12                          ; ACTOR_CLASS_PHANTOM
    .byte   14                          ; ACTOR_CLASS_CYCLOPSE
    .byte   9                           ; ACTOR_CLASS_WIZARD
    .byte   14                          ; ACTOR_CLASS_HYDRA
    .byte   16                          ; ACTOR_CLASS_DEVIL 
    .byte   23                          ; ACTOR_CLASS_DRAGON
    .byte   0                           ; ACTOR_CLASS_TREE
    .byte   0                           ; ACTOR_CLASS_ROCK
    .byte   0                           ; ACTOR_CLASS_CACTUS
    .byte   1                           ; ACTOR_CLASS_BALL_PLAYER
    .byte   9                           ; ACTOR_CLASS_BALL_ZORN
    .byte   10                          ; ACTOR_CLASS_BALL_WIZARD
    .byte   13                          ; ACTOR_CLASS_BALL_HYDRA
    .byte   17                          ; ACTOR_CLASS_BALL_DEVIL 
    .byte   25                          ; ACTOR_CLASS_BALL_DRAGON

; 防御力
actor_class_defense:

    .byte   0                           ; ACTOR_CLASS_NULL
    .byte   0                           ; ACTOR_CLASS_PLAYER
    .byte   0                           ; ACTOR_CLASS_ORC
    .byte   0                           ; ACTOR_CLASS_LIZARD
    .byte   0                           ; ACTOR_CLASS_SLIME
    .byte   0                           ; ACTOR_CLASS_SKELETON
    .byte   0                           ; ACTOR_CLASS_SERPENT
    .byte   0                           ; ACTOR_CLASS_SPIDER
    .byte   0                           ; ACTOR_CLASS_GREMLIN
    .byte   0                           ; ACTOR_CLASS_BAT
    .byte   0                           ; ACTOR_CLASS_ZORN
    .byte   0                           ; ACTOR_CLASS_PHANTOM
    .byte   0                           ; ACTOR_CLASS_CYCLOPSE
    .byte   0                           ; ACTOR_CLASS_WIZARD
    .byte   0                           ; ACTOR_CLASS_HYDRA
    .byte   0                           ; ACTOR_CLASS_DEVIL 
    .byte   19                          ; ACTOR_CLASS_DRAGON
    .byte   32                          ; ACTOR_CLASS_TREE
    .byte   32                          ; ACTOR_CLASS_ROCK
    .byte   32                          ; ACTOR_CLASS_CACTUS
    .byte   0                           ; ACTOR_CLASS_BALL_PLAYER
    .byte   0                           ; ACTOR_CLASS_BALL_ZORN
    .byte   0                           ; ACTOR_CLASS_BALL_WIZARD
    .byte   0                           ; ACTOR_CLASS_BALL_HYDRA
    .byte   0                           ; ACTOR_CLASS_BALL_DEVIL 
    .byte   0                           ; ACTOR_CLASS_BALL_DRAGON

; 速度
actor_class_speed:

    .byte   $00                         ; ACTOR_CLASS_NULL
    .byte   ACTOR_SPEED_NORMAL          ; ACTOR_CLASS_PLAYER
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_ORC
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_LIZARD
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_SLIME
    .byte   ACTOR_SPEED_SLOWER          ; ACTOR_CLASS_SKELETON
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_SERPENT
    .byte   ACTOR_SPEED_NORMAL          ; ACTOR_CLASS_SPIDER
    .byte   ACTOR_SPEED_NORMAL          ; ACTOR_CLASS_GREMLIN
    .byte   ACTOR_SPEED_NORMAL          ; ACTOR_CLASS_BAT
    .byte   ACTOR_SPEED_SLOWER          ; ACTOR_CLASS_ZORN
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_PHANTOM
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_CYCLOPSE
    .byte   ACTOR_SPEED_FAST            ; ACTOR_CLASS_WIZARD
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_HYDRA
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_DEVIL 
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_DRAGON
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_TREE
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_ROCK
    .byte   ACTOR_SPEED_SLOW            ; ACTOR_CLASS_CACTUS
    .byte   ACTOR_SPEED_FAST            ; ACTOR_CLASS_BALL_PLAYER
    .byte   ACTOR_SPEED_NORMAL          ; ACTOR_CLASS_BALL_ZORN
    .byte   ACTOR_SPEED_FAST            ; ACTOR_CLASS_BALL_WIZARD
    .byte   ACTOR_SPEED_NORMAL          ; ACTOR_CLASS_BALL_HYDRA
    .byte   ACTOR_SPEED_NORMAL          ; ACTOR_CLASS_BALL_DEVIL 
    .byte   ACTOR_SPEED_FAST            ; ACTOR_CLASS_BALL_DRAGON

; 大きさ
actor_class_size:

    .byte   $00                         ; ACTOR_CLASS_NULL
    .byte   $02                         ; ACTOR_CLASS_PLAYER
    .byte   $02                         ; ACTOR_CLASS_ORC
    .byte   $02                         ; ACTOR_CLASS_LIZARD
    .byte   $02                         ; ACTOR_CLASS_SLIME
    .byte   $02                         ; ACTOR_CLASS_SKELETON
    .byte   $02                         ; ACTOR_CLASS_SERPENT
    .byte   $02                         ; ACTOR_CLASS_SPIDER
    .byte   $02                         ; ACTOR_CLASS_GREMLIN
    .byte   $02                         ; ACTOR_CLASS_BAT
    .byte   $02                         ; ACTOR_CLASS_ZORN
    .byte   $02                         ; ACTOR_CLASS_PHANTOM
    .byte   $02                         ; ACTOR_CLASS_CYCLOPSE
    .byte   $02                         ; ACTOR_CLASS_WIZARD
    .byte   $02                         ; ACTOR_CLASS_HYDRA
    .byte   $02                         ; ACTOR_CLASS_DEVIL 
    .byte   $04                         ; ACTOR_CLASS_DRAGON
    .byte   $02                         ; ACTOR_CLASS_TREE
    .byte   $02                         ; ACTOR_CLASS_ROCK
    .byte   $02                         ; ACTOR_CLASS_CACTUS
    .byte   $02                         ; ACTOR_CLASS_BALL_PLAYER
    .byte   $02                         ; ACTOR_CLASS_BALL_ZORN
    .byte   $02                         ; ACTOR_CLASS_BALL_WIZARD
    .byte   $02                         ; ACTOR_CLASS_BALL_HYDRA
    .byte   $02                         ; ACTOR_CLASS_BALL_DEVIL 
    .byte   $02                         ; ACTOR_CLASS_BALL_DRAGON

; 点滅
actor_class_blink:

    .byte   $00                         ; ACTOR_CLASS_NULL
    .byte   $08                         ; ACTOR_CLASS_PLAYER
    .byte   $04                         ; ACTOR_CLASS_ORC
    .byte   $04                         ; ACTOR_CLASS_LIZARD
    .byte   $04                         ; ACTOR_CLASS_SLIME
    .byte   $04                         ; ACTOR_CLASS_SKELETON
    .byte   $04                         ; ACTOR_CLASS_SERPENT
    .byte   $04                         ; ACTOR_CLASS_SPIDER
    .byte   $04                         ; ACTOR_CLASS_GREMLIN
    .byte   $04                         ; ACTOR_CLASS_BAT
    .byte   $04                         ; ACTOR_CLASS_ZORN
    .byte   $04                         ; ACTOR_CLASS_PHANTOM
    .byte   $04                         ; ACTOR_CLASS_CYCLOPSE
    .byte   $04                         ; ACTOR_CLASS_WIZARD
    .byte   $04                         ; ACTOR_CLASS_HYDRA
    .byte   $04                         ; ACTOR_CLASS_DEVIL 
    .byte   $10                         ; ACTOR_CLASS_DRAGON
    .byte   $04                         ; ACTOR_CLASS_TREE
    .byte   $04                         ; ACTOR_CLASS_ROCK
    .byte   $04                         ; ACTOR_CLASS_CACTUS
    .byte   $01                         ; ACTOR_CLASS_BALL_PLAYER
    .byte   $01                         ; ACTOR_CLASS_BALL_ZORN
    .byte   $01                         ; ACTOR_CLASS_BALL_WIZARD
    .byte   $01                         ; ACTOR_CLASS_BALL_HYDRA
    .byte   $01                         ; ACTOR_CLASS_BALL_DEVIL 
    .byte   $01                         ; ACTOR_CLASS_BALL_DRAGON

; アニメーション
actor_class_animation:

    .byte   $00                         ; ACTOR_CLASS_NULL
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_PLAYER
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_ORC
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_LIZARD
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_SLIME
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_SKELETON
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_SERPENT
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_SPIDER
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_GREMLIN
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_BAT
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_ZORN
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_PHANTOM
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_CYCLOPSE
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_WIZARD
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_HYDRA
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_DEVIL 
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_DRAGON
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_TREE
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_ROCK
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_CACTUS
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_BALL_PLAYER
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_BALL_ZORN
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_BALL_WIZARD
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_BALL_HYDRA
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_BALL_DEVIL 
    .byte   ACTOR_ANIMATION_FRAME       ; ACTOR_CLASS_BALL_DRAGON

; タイルセット
actor_class_tileset_l:

    .byte   $00                         ; ACTOR_CLASS_NULL
    .byte   <actor_player_tileset       ; ACTOR_CLASS_PLAYER
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_ORC
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_LIZARD
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_SLIME
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_SKELETON
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_SERPENT
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_SPIDER
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_GREMLIN
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_BAT
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_ZORN
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_PHANTOM
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_CYCLOPSE
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_WIZARD
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_HYDRA
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_DEVIL 
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_DRAGON
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_TREE
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_ROCK
    .byte   <actor_enemy_tileset        ; ACTOR_CLASS_CACTUS
    .byte   <actor_effect_tileset       ; ACTOR_CLASS_BALL_PLAYER
    .byte   <actor_effect_tileset       ; ACTOR_CLASS_BALL_ZORN
    .byte   <actor_effect_tileset       ; ACTOR_CLASS_BALL_WIZARD
    .byte   <actor_effect_tileset       ; ACTOR_CLASS_BALL_HYDRA
    .byte   <actor_effect_tileset       ; ACTOR_CLASS_BALL_DEVIL 
    .byte   <actor_effect_tileset       ; ACTOR_CLASS_BALL_DRAGON

actor_class_tileset_h:

    .byte   $00                         ; ACTOR_CLASS_NULL
    .byte   >actor_player_tileset       ; ACTOR_CLASS_PLAYER
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_ORC
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_LIZARD
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_SLIME
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_SKELETON
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_SERPENT
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_SPIDER
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_GREMLIN
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_BAT
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_ZORN
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_PHANTOM
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_CYCLOPSE
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_WIZARD
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_HYDRA
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_DEVIL 
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_DRAGON
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_TREE
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_ROCK
    .byte   >actor_enemy_tileset        ; ACTOR_CLASS_CACTUS
    .byte   >actor_effect_tileset       ; ACTOR_CLASS_BALL_PLAYER
    .byte   >actor_effect_tileset       ; ACTOR_CLASS_BALL_ZORN
    .byte   >actor_effect_tileset       ; ACTOR_CLASS_BALL_WIZARD
    .byte   >actor_effect_tileset       ; ACTOR_CLASS_BALL_HYDRA
    .byte   >actor_effect_tileset       ; ACTOR_CLASS_BALL_DEVIL 
    .byte   >actor_effect_tileset       ; ACTOR_CLASS_BALL_DRAGON

; タイル
actor_class_tile:

    .byte   $00                         ; ACTOR_CLASS_NULL
    .byte   $00                         ; ACTOR_CLASS_PLAYER
    .byte   $00                         ; ACTOR_CLASS_ORC
    .byte   $20                         ; ACTOR_CLASS_LIZARD
    .byte   $40                         ; ACTOR_CLASS_SLIME
    .byte   $60                         ; ACTOR_CLASS_SKELETON
    .byte   $80                         ; ACTOR_CLASS_SERPENT
    .byte   $a0                         ; ACTOR_CLASS_SPIDER
    .byte   $c0                         ; ACTOR_CLASS_GREMLIN
    .byte   $00                         ; ACTOR_CLASS_BAT
    .byte   $20                         ; ACTOR_CLASS_ZORN
    .byte   $40                         ; ACTOR_CLASS_PHANTOM
    .byte   $60                         ; ACTOR_CLASS_CYCLOPSE
    .byte   $80                         ; ACTOR_CLASS_WIZARD
    .byte   $a0                         ; ACTOR_CLASS_HYDRA
    .byte   $c0                         ; ACTOR_CLASS_DEVIL 
    .byte   $e0                         ; ACTOR_CLASS_DRAGON
    .byte   $50                         ; ACTOR_CLASS_TREE
    .byte   $54                         ; ACTOR_CLASS_ROCK
    .byte   $58                         ; ACTOR_CLASS_CACTUS
    .byte   $14                         ; ACTOR_CLASS_BALL_PLAYER
    .byte   $14                         ; ACTOR_CLASS_BALL_ZORN
    .byte   $14                         ; ACTOR_CLASS_BALL_WIZARD
    .byte   $14                         ; ACTOR_CLASS_BALL_HYDRA
    .byte   $14                         ; ACTOR_CLASS_BALL_DEVIL 
    .byte   $14                         ; ACTOR_CLASS_BALL_DRAGON

actor_class_tile_information:

    .byte   $00                         ; ACTOR_CLASS_NULL
    .byte   $08                         ; ACTOR_CLASS_PLAYER
    .byte   $08                         ; ACTOR_CLASS_ORC
    .byte   $28                         ; ACTOR_CLASS_LIZARD
    .byte   $40                         ; ACTOR_CLASS_SLIME
    .byte   $68                         ; ACTOR_CLASS_SKELETON
    .byte   $88                         ; ACTOR_CLASS_SERPENT
    .byte   $a8                         ; ACTOR_CLASS_SPIDER
    .byte   $c8                         ; ACTOR_CLASS_GREMLIN
    .byte   $00                         ; ACTOR_CLASS_BAT
    .byte   $28                         ; ACTOR_CLASS_ZORN
    .byte   $40                         ; ACTOR_CLASS_PHANTOM
    .byte   $68                         ; ACTOR_CLASS_CYCLOPSE
    .byte   $88                         ; ACTOR_CLASS_WIZARD
    .byte   $a8                         ; ACTOR_CLASS_HYDRA
    .byte   $c8                         ; ACTOR_CLASS_DEVIL 
    .byte   $e0                         ; ACTOR_CLASS_DRAGON
    .byte   $50                         ; ACTOR_CLASS_TREE
    .byte   $54                         ; ACTOR_CLASS_ROCK
    .byte   $58                         ; ACTOR_CLASS_CACTUS
    .byte   $14                         ; ACTOR_CLASS_BALL_PLAYER
    .byte   $14                         ; ACTOR_CLASS_BALL_ZORN
    .byte   $14                         ; ACTOR_CLASS_BALL_WIZARD
    .byte   $14                         ; ACTOR_CLASS_BALL_HYDRA
    .byte   $14                         ; ACTOR_CLASS_BALL_DEVIL 
    .byte   $14                         ; ACTOR_CLASS_BALL_DRAGON

; ヒット時の BEEP
actor_class_hit_beep:

    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_NULL
    .byte   IOCS_BEEP_PI                ; ACTOR_CLASS_PLAYER
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_ORC
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_LIZARD
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_SLIME
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_SKELETON
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_SERPENT
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_SPIDER
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_GREMLIN
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_BAT
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_ZORN
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_PHANTOM
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_CYCLOPSE
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_WIZARD
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_HYDRA
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_DEVIL 
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_DRAGON
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_TREE
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_ROCK
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_CACTUS
    .byte   IOCS_BEEP_PI                ; ACTOR_CLASS_BALL_PLAYER
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_BALL_ZORN
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_BALL_WIZARD
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_BALL_HYDRA
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_BALL_DEVIL 
    .byte   IOCS_BEEP_PO                ; ACTOR_CLASS_BALL_DRAGON

; マジックボール
actor_class_ball:

    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_BALL_PLAYER     ; ACTOR_CLASS_PLAYER
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_LIZARD
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_SLIME
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_SKELETON
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_SERPENT
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_SPIDER
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_GREMLIN
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_BALL_ZORN       ; ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_PHANTOM
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_CYCLOPSE
    .byte   ACTOR_CLASS_BALL_WIZARD     ; ACTOR_CLASS_WIZARD
    .byte   ACTOR_CLASS_BALL_HYDRA      ; ACTOR_CLASS_HYDRA
    .byte   ACTOR_CLASS_BALL_DEVIL      ; ACTOR_CLASS_DEVIL 
    .byte   ACTOR_CLASS_BALL_DRAGON     ; ACTOR_CLASS_DRAGON
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_TREE
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_ROCK
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_CACTUS
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_BALL_PLAYER
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_BALL_ZORN
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_BALL_WIZARD
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_BALL_HYDRA
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_BALL_DEVIL 
    .byte   ACTOR_CLASS_NULL            ; ACTOR_CLASS_BALL_DRAGON

; タイルセット
;
actor_player_tileset:

.incbin     "resources/sprites/player.ts"

actor_enemy_tileset:

    .res    $0800

actor_effect_tileset:

.incbin     "resources/sprites/effect.ts"


; データの定義
;
.segment    "BSS"

; アクタの制御
;

; サイクル
.global _actor_cycle
_actor_cycle:

    .res    $01

; キーコード
.global _actor_keycode
_actor_keycode:

    .res    $01

; アクタの情報
;

; クラス
.global _actor_class
_actor_class:

    .res    ACTOR_SIZE

; 状態
.global _actor_state
_actor_state:

    .res    ACTOR_SIZE

; 体力
.global _actor_life
_actor_life:

    .res    ACTOR_SIZE

; 位置
.global _actor_x
_actor_x:

    .res    ACTOR_SIZE

.global _actor_y
_actor_y:

    .res    ACTOR_SIZE

; 向き
.global _actor_direction
_actor_direction:

    .res    ACTOR_SIZE

; 生成
.global _actor_spawn
_actor_spawn:

    .res    ACTOR_SIZE

; 移動
.global _actor_move
_actor_move:

    .res    ACTOR_SIZE

; ヒット
.global _actor_hit
_actor_hit:

    .res    ACTOR_SIZE

; ダメージ
.global _actor_damage
_actor_damage:

    .res    ACTOR_SIZE

; アニメーション
.global _actor_animation
_actor_animation:

    .res    ACTOR_SIZE

; タイル
.global _actor_tile
_actor_tile:

    .res    ACTOR_SIZE

; 描画
.global _actor_draw
_actor_draw:

    .res    ACTOR_SIZE

; パラメータ
.global _actor_param_0
_actor_param_0:

    .res    ACTOR_SIZE

.global _actor_param_1
_actor_param_1:

    .res    ACTOR_SIZE

.global _actor_param_2
_actor_param_2:

    .res    ACTOR_SIZE

.global _actor_param_3
_actor_param_3:

    .res    ACTOR_SIZE

.global _actor_param_4
_actor_param_4:

    .res    ACTOR_SIZE

.global _actor_param_5
_actor_param_5:

    .res    ACTOR_SIZE

.global _actor_param_6
_actor_param_6:

    .res    ACTOR_SIZE

.global _actor_param_7
_actor_param_7:

    .res    ACTOR_SIZE

