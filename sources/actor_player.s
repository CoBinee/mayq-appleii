; actor_player.s - プレイヤ
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

; プレイヤを読み込む
;
.global _ActorPlayerLoad
.proc   _ActorPlayerLoad

    ; IN
    ;   x = アクタの参照

    ; 体力の設定
    lda     _user_life
    sta     _actor_life, x

    ; 位置の設定
    lda     _user_x
    sta     _actor_x, x
    lda     _user_y
    sta     _actor_y, x

    ; 向きの設定
    lda     _user_direction
    sta     _actor_direction, x

    ; 描画の設定
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_DIRECTION
    sta     _actor_draw, x

    ; 最初の描画
    jsr     _ActorDrawTile2x2

    ; 終了
    rts

.endproc

; プレイヤを破棄する
;
.global _ActorPlayerUnload
.proc   _ActorPlayerUnload

    ; IN
    ;   x = アクタの参照
    ;   a = $00...通常 / $ff...死亡

    ; 体力の保存
    lda     _actor_life, x
    sta     _user_life

    ; 位置の保存
    lda     _actor_x, x
    sta     _user_x
    lda     _actor_y, x
    sta     _user_y

    ; 向きの保存
    lda     _actor_direction, x
    sta     _user_direction

    ; 終了
    rts

.endproc

; プレイヤを行動させる
;
.global _ActorPlayerPlay
.proc   _ActorPlayerPlay

    ; IN
    ;   x = アクタの参照
    ; PARAM
    ;   P[0] = 足元のタイルの属性（左）
    ;   P[1] = 足元のタイルの属性（右）
    ;   P[2] = 回復
    ;   P[3] = 鈍さ
    ;   P[4] = 暑さ
    ;   P[5] = 毒

    ; 初期化
    lda     _actor_state, x
    bne     @initialized

    ; パラメータの設定
    lda     #$00
;   sta     _actor_param_0, x
;   sta     _actor_param_1, x
    sta     _actor_param_2, x
    sta     _actor_param_3, x
    sta     _actor_param_4, x
    sta     _actor_param_5, x

    ; 初期化の完了
    inc     _actor_state, x
@initialized:

    ; キーの入力
    lda     _actor_keycode
    cmp     #'W'
    beq     @up
    cmp     #'I'
    beq     @up
    cmp     #'S'
    beq     @down
    cmp     #'K'
    beq     @down
    cmp     #'A'
    beq     @left
    cmp     #'J'
    beq     @left
    cmp     #'D'
    beq     @right
    cmp     #'L'
    beq     @right
;   cmp     #' '
;   bne     :+
;   jmp     @cast
;:
    jmp     @move

    ; ↑
@up:
    lda     #ACTOR_DIRECTION_UP
    jmp     @turn

    ; ↓
@down:
    lda     #ACTOR_DIRECTION_DOWN
    jmp     @turn

    ; ←
@left:
    lda     #ACTOR_DIRECTION_LEFT
    jmp     @turn

    ; →
@right:
    lda     #ACTOR_DIRECTION_RIGHT
;   jmp     @turn

    ; 方向転換
@turn:
    cmp     _actor_direction, x
    beq     :+
    sta     _actor_direction, x
    lda     _actor_move, x
    ora     #(ACTOR_MOVE_ON | ACTOR_MOVE_STOMP)
    sta     _actor_move, x
    jmp     @update
:
    lda     _actor_move, x
    eor     #ACTOR_MOVE_ON
    sta     _actor_move, x
    lda     #$00
    sta     _actor_param_3, x
;   jmp     @move

    ; 移動
@move:
    lda     _actor_move, x
    ora     #ACTOR_MOVE_STOMP
    sta     _actor_move, x
    and     #ACTOR_MOVE_ON
    beq     @stop
    lda     _actor_param_3, x
    and     #%00000001
    beq     :+
    jmp     @update
:
    jsr     _ActorHit
    cmp     #$00
    bne     @hit
    jsr     _ActorMove
    and     #$ff
    bmi     @exit
    bne     @block
    lda     _actor_move, x
    ora     #(ACTOR_MOVE_START | ACTOR_MOVE_ED)
    sta     _actor_move, x
    lda     _actor_draw, x
    ora     #ACTOR_DRAW_BACK
    sta     _actor_draw, x
    jmp     @update

    ; ヒット
@hit:
    ldy     #ACTOR_TYPE_ENEMY
    jsr     _ActorDamage
    jmp     @update

    ; エリアから出る
@exit:
    lda     _actor_direction, x
    sta     _game_area_exit

    ; 停止
@stop:
    lda     _actor_move, x
    and     #(~ACTOR_MOVE_STOMP & $ff)
    sta     _actor_move, x
    jmp     @update

    ; コリジョンにブロックされる
@block:
    lda     _actor_move, x
    and     #(~ACTOR_MOVE_STOMP & $ff)
    ora     #ACTOR_MOVE_BLOCK
    sta     _actor_move, x
    jmp     @update

    ; マジックボールを詠唱する
@cast:
    lda     _actor_direction, x
    jsr     _ActorCastBall
    lda     _actor_move, x
    and     #(~(ACTOR_MOVE_STOMP | ACTOR_MOVE_ON) & $ff)
    sta     _actor_move, x
;   jmp     @update

    ; アクタの更新
@update:

    ; アクタの描画
    jsr     _ActorDraw2x2

    ; アニメーションの更新
    lda     _actor_move, x
    and     #ACTOR_MOVE_STOMP
    beq     :+
    lda     _actor_param_3, x
    and     #%00000001
    bne     :+
    jsr     _ActorAnimation
:

    ; 足元の取得
    jsr     _ActorGetFootLeftTileAttribute
    sta     _actor_param_0, x
    jsr     _ActorGetFootRightTileAttribute
    sta     _actor_param_1, x

    ; 階段の上り下り
    lda     _actor_move, x
    and     #ACTOR_MOVE_START
    beq     :+
    lda     _actor_param_0, x
    cmp     #WORLD_TILE_ATTRIBUTE_STAIRS
    bne     :+
    lda     #$00
    sta     _game_layer_exit
    jmp     @done
:

    ; 止まっての回復
    lda     _actor_life, x
    cmp     _user_life_maximum
    beq     :+
    lda     _actor_move, x
    and     #ACTOR_MOVE_ON
    bne     :+
    lda     _actor_param_0, x
    cmp     #WORLD_TILE_ATTRIBUTE_REST
    bne     :+
    lda     _actor_param_1, x
    cmp     #WORLD_TILE_ATTRIBUTE_REST
    bne     :+
    inc     _actor_param_2, x
    lda     _actor_param_2, x
    cmp     #ACTOR_PLAYER_REST
    bcc     :++
    inc     _actor_life, x
    jsr     _GameDrawActorStatusLife
:
    lda     #$00
    sta     _actor_param_2, x
:

    ; 荒地で動きが鈍くなる
    lda     _user_item + USER_ITEM_BOOTS
    bne     :++
    lda     _actor_move, x
    and     #ACTOR_MOVE_ON
    beq     :++
    lda     _actor_param_0, x
    cmp     #WORLD_TILE_ATTRIBUTE_SLOW
    bne     :+
    lda     _actor_param_1, x
    cmp     #WORLD_TILE_ATTRIBUTE_SLOW
    bne     :+
    inc     _actor_param_3, x
    jmp     :++
:
    lda     #$00
    sta     _actor_param_3, x
:

    ; 砂地で体力を奪われる
    lda     _user_item + USER_ITEM_CLOAK
    bne     :++
    lda     _actor_param_0, x
    cmp     #WORLD_TILE_ATTRIBUTE_HEAT
    bne     :+
    lda     _actor_param_1, x
    cmp     #WORLD_TILE_ATTRIBUTE_HEAT
    bne     :+
    inc     _actor_param_4, x
    lda     _actor_param_4, x
    cmp     #ACTOR_PLAYER_HEAT
    bcc     :++
    lda     _actor_life, x
    cmp     #$02
    bcc     :+
    dec     _actor_life, x
    jsr     _GameDrawActorStatusLife
    ldy     #IOCS_BEEP_PO
    jsr     _ActorAnimateDamage
:
    lda     #$00
    sta     _actor_param_4, x
:

    ; 毒でダメージを受ける
    lda     _user_item + USER_ITEM_MASK
    bne     :+++
    lda     _actor_move, x
    and     #ACTOR_MOVE_ED
    beq     :+++
    lda     _actor_param_0, x
    cmp     #WORLD_TILE_ATTRIBUTE_HURT
    beq     :+
    lda     _actor_param_1, x
    cmp     #WORLD_TILE_ATTRIBUTE_HURT
    bne     :++
:
    inc     _actor_param_5, x
    lda     _actor_param_5, x
    cmp     #ACTOR_PLAYER_HURT
    bcc     :++
    lda     _actor_life, x
    cmp     #$02
    bcc     :+
    dec     _actor_life, x
    jsr     _GameDrawActorStatusLife
    ldy     #IOCS_BEEP_PO
    jsr     _ActorAnimateDamage
:
    lda     #$00
    sta     _actor_param_5, x
:

    ; 宝箱にぶつかる
    lda     _actor_move, x
    and     #ACTOR_MOVE_BLOCK
    bne     @box
    jmp     @collided
@box:
    txa
    pha
    lda     _actor_direction, x
    bne     :+
    ldy     _actor_y, x
    lda     _actor_x, x
    tax
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_BOX
    bne     @box_open
    pla
    pha
    tax
    ldy     _actor_y, x
    lda     _actor_x, x
    tax
    inx
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_BOX
    bne     @box_open
    jmp     @boxed
:
    cmp     #ACTOR_DIRECTION_DOWN
    bne     :+
    ldy     _actor_y, x
    iny
    iny
    lda     _actor_x, x
    tax
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_BOX
    bne     @box_open
    pla
    pha
    tax
    ldy     _actor_y, x
    iny
    iny
    lda     _actor_x, x
    tax
    inx
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_BOX
    bne     @box_open
    jmp     @boxed
:
    cmp     #ACTOR_DIRECTION_LEFT
    bne     :+
    ldy     _actor_y, x
    iny
    lda     _actor_x, x
    tax
    dex
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_BOX
    bne     @box_open
    jmp     @boxed
:
    ldy     _actor_y, x
    iny
    lda     _actor_x, x
    tax
    inx
    inx
    jsr     _WorldGetAreaTileAttribute
    and     #WORLD_TILE_ATTRIBUTE_BOX
    bne     @box_open
    jmp     @boxed
@box_open:
    jsr     _GameOpenBox
;   jmp     @boxed
@boxed:
    pla
    tax
@collided:

    ; 行動の終了
@done:

    ; 移動のクリア
    lda     _actor_move, x
    and     #(~(ACTOR_MOVE_ED | ACTOR_MOVE_BLOCK) & $ff)
    sta     _actor_move, x

    ; キーコードのクリア
    lda     #$00
    sta     _actor_keycode

    ; 終了
    rts

.endproc


; データの定義
;
.segment    "BSS"

