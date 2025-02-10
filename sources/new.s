; new.s - ニューゲーム
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
.include    "app1.inc"
.include    "new.inc"


; コードの定義
;
.segment    "APP1"

; ニューゲームのエントリポイント
;
.global _NewEntry
.proc   _NewEntry

    ; アプリケーションの初期化

    ; ニューゲームの初期化
    lda     #$00
    sta     new + New::debug

    ; 処理の設定
    lda     #<NewInitialize
    sta     APP1_0_PROC_L
    lda     #>NewInitialize
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

    ; 終了
    rts

.endproc

; 初期化する
;
.proc   NewInitialize

;   ; 初期化／作成の開始
;   lda     APP1_0_STATE
;   bne     @initialized

;   ; VRAM のクリア
;   jsr     _IocsClearVram

    ; 文字列の描画
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDrawString

    ; ワールドの初期化
    jsr     _WorldInitialize

    ; ライトの設定
    lda     #$01
    sta     _world_area_light

    ; ユーザの初期化
    jsr     _UserInitialize

    ; ID の設定
    lda     IOCS_0_RANDOM_L
    sta     _world_id + $0000
    sta     _user_id + $0000
    lda     IOCS_0_RANDOM_H
    sta     _world_id + $0001
    sta     _user_id + $0001

;   ; 初期化の完了
;   inc     APP1_0_STATE
;@initialized:

    ; 処理の設定
    lda     #<NewBuildArea
    sta     APP1_0_PROC_L
    lda     #>NewBuildArea
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

    ; 終了
    rts

; 描画の引数
@draw_arg:
    .byte   $00, $10
    .word   @draw_string
@draw_string:
    .asciiz "   CREATING WORLD   "

.endproc

; エリアを作成する
;
.proc   NewBuildArea

    ; 初期化／作成の開始
    lda     APP1_0_STATE
    bne     @initialized

    ; エリアのクリア
    lda     #$00
    tax
:
    sta     new_area, x
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :-

    ; 開始位置の設定
    lda     #(WORLD_EVENT_START | WORLD_AREA_INSIDE)
    jsr     NewRandomAreaEvent

    ; エリアの分割
    lda     #WORLD_AREA_INSIDE_SIZE
    jsr     NewDivideArea

    ; イベント／階段の設定
    lda     #WORLD_EVENT_STAIRS
    jsr     NewRandomInsideAreaEvent
    lda     #WORLD_EVENT_STAIRS
    jsr     NewRandomOutsideAreaEvent

    ; イベント／鍵の設定
    lda     #WORLD_EVENT_KEY
    jsr     NewRandomInsideAreaEvent

    ; イベント／松明の設定
    lda     #WORLD_EVENT_TORCH
    jsr     NewRandomInsideAreaEvent

    ; イベント／剣の設定
    lda     #WORLD_EVENT_SWORD
    jsr     NewRandomAreaEvent

    ; イベント／靴の設定
    lda     #WORLD_EVENT_BOOTS
    jsr     NewRandomAreaEvent

    ; イベント／外套の設定
    lda     #WORLD_EVENT_CLOAK
    jsr     NewRandomAreaEvent

    ; イベント／仮面の設定
    lda     #WORLD_EVENT_MASK
    jsr     NewRandomAreaEvent

    ; イベント／お守りの設定
    lda     #WORLD_EVENT_TALISMAN
    jsr     NewRandomAreaEvent

    ; イベント／魔除けの設定
    lda     #WORLD_EVENT_AMULET
    jsr     NewRandomAreaEvent

    ; イベント／薬の設定
    lda     #WORLD_EVENT_POTION
    jsr     NewRandomAreaEvent

    ; イベント／結晶の設定
    lda     #WORLD_EVENT_CRYSTAL_RED
    jsr     NewRandomAreaEvent
    lda     #WORLD_EVENT_CRYSTAL_BLUE
    jsr     NewRandomAreaEvent
    lda     #WORLD_EVENT_CRYSTAL_GREEN
    jsr     NewRandomAreaEvent

    ; デバッグのスキップ
    lda     new + New::debug
    beq     @next

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; エリアの描画
    jsr     NewDrawArea

    ; 初期化の完了
    inc     APP1_0_STATE
@initialized:

    ; キー入力待ち
    lda     IOCS_0_KEYCODE
    beq     @end

    ; SPACE の入力
    cmp     #' '
    beq     @next
    jmp     @end

    ; 処理の設定
@next:
    lda     #<NewBuildFieldBlock
    sta     APP1_0_PROC_L
    lda     #>NewBuildFieldBlock
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

    ; 終了
@end:
    rts

.endproc

; フィールド／ブロックを作成する
;
.proc   NewBuildFieldBlock

    ; 初期化／作成の開始
    lda     APP1_0_STATE
    bne     @initialized

    ; ブロックのクリア
    ldx     #$00
    lda     #WORLD_FIELD_BLOCK_LAND_GRASS
:
    sta     new_field_block, x
    inx
    cpx     #(WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y)
    bne     :-

    ; 開始位置の設定
    lda     #WORLD_EVENT_START
    ldx     #(WORLD_FIELD_BLOCK_LOCK | WORLD_FIELD_BLOCK_LAND_GRASS)
    jsr     @event

    ; お守りの設定
    lda     #WORLD_EVENT_TALISMAN
    ldx     #(WORLD_FIELD_BLOCK_LOCK | WORLD_FIELD_BLOCK_LAND_SAND)
    jsr     @event

    ; 魔除けの設定
    lda     #WORLD_EVENT_AMULET
    ldx     #(WORLD_FIELD_BLOCK_LOCK | WORLD_FIELD_BLOCK_LAND_DIRT)
    jsr     @event

    ; 薬の設定
    lda     #WORLD_EVENT_POTION
    ldx     #(WORLD_FIELD_BLOCK_LOCK | WORLD_FIELD_BLOCK_LAND_GRASS)
    jsr     @event

    ; 砂地の設定
    lda     #WORLD_FIELD_BLOCK_LAND_SAND
    ldx     #WORLD_FIELD_BLOCK_SIZE_SAND
    jsr     NewExpandFieldBlockLand

    ; 荒地の設定
    lda     #WORLD_FIELD_BLOCK_LAND_DIRT
    ldx     #WORLD_FIELD_BLOCK_SIZE_DIRT_EXPAND
    jsr     NewExpandFieldBlockLand
    lda     #WORLD_FIELD_BLOCK_LAND_DIRT
    ldx     #WORLD_FIELD_BLOCK_SIZE_DIRT_RANDOM
    jsr     NewRandomFieldBlockLand

    ; 森林の設定
    lda     #WORLD_FIELD_BLOCK_LAND_FOREST
    ldx     #WORLD_FIELD_BLOCK_SIZE_FOREST_EXPAND
    jsr     NewExpandFieldBlockLand
    lda     #WORLD_FIELD_BLOCK_LAND_FOREST
    ldx     #WORLD_FIELD_BLOCK_SIZE_FOREST_RANDOM
    jsr     NewRandomFieldBlockLand

    ; エリアに地形を設定する
    ldx     #$00
:
    ldy     new_field_area_block, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    asl     a
    asl     a
    asl     a
    asl     a
    ora     new_area, x
    sta     new_area, x
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_X)
    bne     :-

    ; デバッグのスキップ
    lda     new + New::debug
    beq     @next

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; ブロックの描画
    jsr     NewDrawFieldBlock

    ; 初期化の完了
    inc     APP1_0_STATE
@initialized:

    ; キー入力待ち
    lda     IOCS_0_KEYCODE
    beq     @end

    ; SPACE の入力
    cmp     #' '
    beq     @next
    jmp     @end

    ; 処理の設定
@next:
    lda     #<NewBuildFieldCell
    sta     APP1_0_PROC_L
    lda     #>NewBuildFieldCell
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

    ; 終了
@end:
    rts

    ; イベントブロックの取得
@event:
    sta     NEW_0_WORK_0
    stx     NEW_0_WORK_1
    ldx     #$00
:
    lda     new_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     NEW_0_WORK_0
    beq     :+
    inx
    jmp     :-
:
    ldy     new_field_area_block, x
    lda     NEW_0_WORK_1
    sta     new_field_block, y
    rts

.endproc

; フィールド／セルを作成する
;
.proc   NewBuildFieldCell

    ; 初期化／作成の開始
    lda     APP1_0_STATE
    bne     @initialized

    ; セルのクリア
    lda     #<new_field_cell
    sta     NEW_0_WORK_0
    lda     #>new_field_cell
    sta     NEW_0_WORK_1
    ldx     #WORLD_FIELD_CELL_SIZE_Y
:
    ldy     #$00
    lda     #WORLD_CELL_GRASS
:
    sta     (NEW_0_WORK_0), y
    iny
    cpy     #WORLD_FIELD_CELL_SIZE_X
    bne     :-
    lda     NEW_0_WORK_0
    clc
    adc     #WORLD_FIELD_CELL_SIZE_X
    sta     NEW_0_WORK_0
    bcc     :+
    inc     NEW_0_WORK_1
:
    dex
    bne     :---

    ; セルの塗り潰し
    jsr     NewFillFieldCell

    ; セルの境界をぼかす
    jsr     NewModifyFieldCellBorder

    ; 草地に木を置く
    lda     #WORLD_CELL_TREE
    ldx     #WORLD_FIELD_BLOCK_LAND_GRASS
    jsr     NewRandomFieldCellLand

    ; 荒地に岩を置く
    lda     #WORLD_CELL_ROCK
    ldx     #WORLD_FIELD_BLOCK_LAND_DIRT
    jsr     NewRandomFieldCellLand

    ; 砂地にサボテンを置く
    lda     #WORLD_CELL_CACTUS
    ldx     #WORLD_FIELD_BLOCK_LAND_SAND
    jsr     NewRandomFieldCellLand

    ; 森に草地を置く
    lda     #WORLD_CELL_GRASS
    ldx     #WORLD_FIELD_BLOCK_LAND_FOREST
    jsr     NewRandomFieldCellLand

    ; 水を流す
    jsr     NewFlowFieldCell

    ; 壁を立てる
    jsr     NewWallFieldCell

    ; イベントを置く
    jsr     NewEventFieldCell

    ; 森を密集させる
    jsr     NewThickFieldCell

    ; セルをずらす
    jsr     NewShiftFieldCell

    ; デバッグのスキップ
    jmp     @next

    ; 位置の設定
    lda     #$00
    sta     @cell_x
    sta     @cell_y

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; セルの描画
    ldx     @cell_x
    ldy     @cell_y
    jsr     NewDrawFieldCell

    ; 初期化の完了
    inc     APP1_0_STATE
@initialized:

    ; キー入力待ち
    lda     IOCS_0_KEYCODE
    beq     @end

    ; SPACE の入力
    cmp     #' '
    beq     @next

    ; 位置の取得
    ldx     @cell_x
    ldy     @cell_y

    ; WASD の入力
    cmp     #'W'
    bne     :++
    tya
    sec
    sbc     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y)
    bcs     :+
    lda     #(WORLD_FIELD_CELL_SIZE_Y - (WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y))
:
    tay
    jmp     @draw
:
    cmp     #'S'
    bne     :++
    tya
    clc
    adc     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y)
    cmp     #WORLD_FIELD_CELL_SIZE_Y
    bcc     :+
    lda     #$00
:
    tay
    jmp     @draw
:
    cmp     #'A'
    bne     :++
    txa
    sec
    sbc     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X)
    bcs     :+
    lda     #(WORLD_FIELD_CELL_SIZE_X - (WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X))
:
    tax
    jmp     @draw
:
    cmp     #'D'
    bne     :++
    txa
    clc
    adc     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X)
    cmp     #WORLD_FIELD_CELL_SIZE_X
    bcc     :+
    lda     #$00
:
    tax
    jmp     @draw
:
    jmp     @end

    ; セルの描画
@draw:
    stx     @cell_x
    sty     @cell_y
    jsr     NewDrawFieldCell
    jmp     @end

    ; 処理の設定
@next:
    lda     #<NewBuildDungeonLink
    sta     APP1_0_PROC_L
    lda     #>NewBuildDungeonLink
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

    ; 終了
@end:
    rts

; セルの位置
@cell_x:
    .byte   $00
@cell_y:
    .byte   $00

.endproc

; ダンジョン／リンクを作成する
;
.proc   NewBuildDungeonLink

    ; 初期化／作成の開始
    lda     APP1_0_STATE
    bne     @initialized

    ; リンクのクリア
    ldx     #$00
    txa
:
    sta     new_dungeon_link, x
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :-
    ldx     #$00

    ; 迷路の作成
    jsr     NewMazeDungeonLink

    ; 行き止まりをなくす
    jsr     NewUnendDungeonLink

    ; ドラゴンの部屋を開く
    jsr     NewOpenDungeonLinkSword

    ; デバッグのスキップ
    lda     new + New::debug
    beq     @next

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; リンクの描画
    jsr     NewDrawDungeonLink

    ; 初期化の完了
    inc     APP1_0_STATE
@initialized:

    ; キー入力待ち
    lda     IOCS_0_KEYCODE
    beq     @end

    ; SPACE の入力
    cmp     #' '
    beq     @next
    jmp     @end

    ; 処理の設定
@next:
    lda     #<NewBuildDungeonCell
    sta     APP1_0_PROC_L
    lda     #>NewBuildDungeonCell
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

    ; 終了
@end:
    rts

.endproc

; ダンジョン／セルを作成する
;
.proc   NewBuildDungeonCell

    ; 初期化／作成の開始
    lda     APP1_0_STATE
    bne     @initialized

    ; セルのクリア
    lda     #<new_dungeon_cell
    sta     NEW_0_WORK_0
    lda     #>new_dungeon_cell
    sta     NEW_0_WORK_1
    lda     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    sta     NEW_0_WORK_2
    ldy     #$00
:
    ldx     #(WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
:
    lda     #WORLD_CELL_GROUND
    sta     (NEW_0_WORK_0), y
    inc     NEW_0_WORK_0
    bne     :+
    inc     NEW_0_WORK_1
:
    dex
    bne     :--
    dec     NEW_0_WORK_2
    bne     :---

    ; セルを囲む
    jsr     NewFrameDungeonCell

    ; ダメージ床を置く
    jsr     NewDamageDungeonCell

    ; セルをつなげる
    jsr     NewLinkDungeonCell

    ; イベントを置く
    jsr     NewEventDungeonCell

    ; デバッグのスキップ
    jmp     @next

    ; エリアの設定
    lda     #$00
    sta     @area

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; セルの描画
    jsr     NewDrawDungeonCell

    ; 初期化の完了
    inc     APP1_0_STATE
@initialized:

    ; キー入力待ち
    lda     IOCS_0_KEYCODE
    beq     @end

    ; SPACE の入力
    cmp     #' '
    beq     @next

    ; 位置の取得
    ldx     @area

    ; WASD の入力
    cmp     #'W'
    bne     :+
    lda     _world_area_up, x
    tax
    jmp     @draw
:
    cmp     #'S'
    bne     :+
    lda     _world_area_down, x
    tax
    jmp     @draw
    tya
:
    cmp     #'A'
    bne     :+
    lda     _world_area_left, x
    tax
    jmp     @draw
:
    cmp     #'D'
    bne     :+
    lda     _world_area_right, x
    tax
    jmp     @draw
:
    jmp     @end

    ; セルの描画
@draw:
    stx     @area
    txa
    jsr     NewDrawDungeonCell
    jmp     @end

    ; 処理の設定
@next:
    lda     #<NewBuildWorld
    sta     APP1_0_PROC_L
    lda     #>NewBuildWorld
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

    ; 終了
@end:
    rts

; エリア
@area:
    .byte   $00

.endproc

; ワールドを作成する
;
.proc   NewBuildWorld

    ; 初期化／作成の開始
    lda     APP1_0_STATE
    bne     @initialized

    ; エリアの設定
    jsr     NewSetWorldArea

    ; フィールド／セルの設定
    jsr     NewSetWorldFieldCell

    ; ダンジョン／セルの設定
    jsr     NewSetWorldDungeonCell

    ; デバッグのスキップ
    lda     new + New::debug
    beq     @next

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; 上下の設定
    lda     #$00
    sta     @updown

    ; エリアの設定
    lda     #$00
    sta     @area

    ; エリアの描画
    jsr     @update

    ; 初期化の完了
    inc     APP1_0_STATE
@initialized:

    ; キー入力待ち
    lda     IOCS_0_KEYCODE
    beq     @end

    ; SPACE の入力
    cmp     #' '
    beq     @next

    ; RETURN の入力
    cmp     #$0d
    bne     :+
    lda     #$01
    sec
    sbc     @updown
    sta     @updown
    jmp     @draw
:

    ; WASD の入力
    cmp     #'W'
    bne     :+
    ldx     @area
    lda     _world_area_up, x
    sta     @area
    jmp     @draw
:
    cmp     #'S'
    bne     :+
    ldx     @area
    lda     _world_area_down, x
    sta     @area
    jmp     @draw
:
    cmp     #'A'
    bne     :+
    ldx     @area
    lda     _world_area_left, x
    sta     @area
    jmp     @draw
:
    cmp     #'D'
    bne     :+
    ldx     @area
    lda     _world_area_right, x
    sta     @area
    jmp     @draw
:
    jmp     @end

    ; エリアの描画
@draw:
    jsr     @update
    jmp     @end

    ; 処理の設定
@next:
    lda     #<NewSave
    sta     APP1_0_PROC_L
    lda     #>NewSave
    sta     APP1_0_PROC_H
    lda     #$00
    sta     APP1_0_STATE

    ; 終了
@end:
    rts

    ; エリアの更新
@update:
    lda     @updown
    bne     :+
    lda     @area
    jsr     _WorldLDuplicateFieldAreaCell
    jmp     :++
:
    lda     @area
    jsr     _WorldLDuplicateDungeonAreaCell
:
    jsr     _WorldLayoutAreaCellTile
    jsr     _WorldDrawArea
    rts

; 上下
@updown:
    .byte   $00

; エリア
@area:
    .byte   $00

.endproc

; 保存する
;
.proc   NewSave

;   ; 初期化／作成の開始
;   lda     APP1_0_STATE
;   bne     @initialized

;   ; VRAM のクリア
;   jsr     _IocsClearVram

    ; 文字列の描画
    ldx     #<@save_arg
    lda     #>@save_arg
    jsr     _IocsDrawString

    ; ワールドの保存
    jsr     _WorldSave

    ; ユーザの保存
    jsr     _UserSave

    ; 文字列の描画
    ldx     #<@enter_arg
    lda     #>@enter_arg
    jsr     _IocsDrawString

;   ; 初期化の完了
;   inc     APP1_0_STATE
;@initialized:

;   ; 処理の設定
;   lda     #<NewBuildArea
;   sta     APP1_0_PROC_L
;   lda     #>NewBuildArea
;   sta     APP1_0_PROC_H
;   lda     #$00
;   sta     APP1_0_STATE
    lda     #$02
    sta     APP1_0_BRUN

    ; 終了
    rts

; 描画の引数
@save_arg:
    .byte   $00, $10
    .word   @save_string
@save_string:
    .asciiz "    SAVING WORLD    "
@enter_arg:
    .byte   $00, $10
    .word   @enter_string
@enter_string:
    .asciiz "                    "

.endproc

; ランダムに選ばれたエリアにイベントを設定する
;
.proc   NewRandomAreaEvent

    ; IN
    ;   a = イベント

    ; 値の保存
    sta     NEW_0_RANDOM_AREA_EVENT

    ; ランダムな選択
    jsr     _IocsGetRandomNumber
    and     #$1f
    tay
    iny
    ldx     #$00
:
    lda     new_area, x
    and     #WORLD_AREA_EVENT_MASK
    bne     :+
    dey
    beq     :++
:
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :--
    ldx     #$00
    jmp     :--
:

    ; 値の設定
    lda     new_area, x
    and     #(~WORLD_AREA_EVENT_MASK & $ff)
    ora     NEW_0_RANDOM_AREA_EVENT
    sta     new_area, x

    ; 終了
    rts

.endproc

; ランダムに選ばれたインサイドのエリアにイベントを設定する
;
.proc   NewRandomInsideAreaEvent

    ; IN
    ;   a = イベント

    ; 値の保存
    sta     NEW_0_RANDOM_AREA_EVENT

    ; ランダムな選択
    jsr     _IocsGetRandomNumber
    and     #$1f
    tay
    iny
    ldx     #$00
:
    lda     new_area, x
    and     #WORLD_AREA_INSIDE
    beq     :+
    lda     new_area, x
    and     #WORLD_AREA_EVENT_MASK
    bne     :+
    dey
    beq     :++
:
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :--
    ldx     #$00
    jmp     :--
:

    ; 値の設定
    lda     new_area, x
    and     #(~WORLD_AREA_EVENT_MASK & $ff)
    ora     NEW_0_RANDOM_AREA_EVENT
    sta     new_area, x

    ; 終了
    rts

.endproc

; ランダムに選ばれたアウトサイドのエリアにイベントを設定する
;
.proc   NewRandomOutsideAreaEvent

    ; IN
    ;   a = イベント

    ; 値の保存
    sta     NEW_0_RANDOM_AREA_EVENT

    ; ランダムな選択
    jsr     _IocsGetRandomNumber
    and     #$1f
    tay
    iny
    ldx     #$00
:
    lda     new_area, x
    and     #WORLD_AREA_INSIDE
    bne     :+
    lda     new_area, x
    and     #WORLD_AREA_EVENT_MASK
    bne     :+
    dey
    beq     :++
:
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :--
    ldx     #$00
    jmp     :--
:

    ; 値の設定
    lda     new_area, x
    and     #(~WORLD_AREA_EVENT_MASK & $ff)
    ora     NEW_0_RANDOM_AREA_EVENT
    sta     new_area, x

    ; 終了
    rts

.endproc

; エリアを分割する
;
.proc   NewDivideArea

    ; IN
    ;   a = インサイドの数

    ; 引数の保持
    sta     NEW_0_DIVIDE_AREA_SIZE

    ; プールの初期化
    ldx     #$00
    ldy     #$00
:
    lda     new_area, x
    and     #WORLD_AREA_INSIDE
    beq     :+
    txa
    sta     @pool, y
    iny
:
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :--
    sty     NEW_0_DIVIDE_AREA_POOL_LENGTH
    ldy     #$00

    ; インサイドを拡げる
@search:
    sty     NEW_0_DIVIDE_AREA_POOL_START
    sty     NEW_0_DIVIDE_AREA_POOL_CHECK

    ; 拡げられるかどうかの確認
@check:
    lda     @pool, y
    tax
    lda     #$04
    sta     NEW_0_DIVIDE_AREA_UDLR
    jsr     _IocsGetRandomNumber
    and     #$03
    beq     @check_down
    sec
    sbc     #$01
    beq     @check_left
    sec
    sbc     #$01
    beq     @check_right
;   jmp     @check_up

    ; 上へ拡げられるか
@check_up:
    ldy     _world_area_up, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    beq     @expand
    dec     NEW_0_DIVIDE_AREA_UDLR
    beq     @check_error

    ; 下へ拡げられるか
@check_down:
    ldy     _world_area_down, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    beq     @expand
    dec     NEW_0_DIVIDE_AREA_UDLR
    beq     @check_error

    ; 左へ拡げられるか
@check_left:
    ldy     _world_area_left, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    beq     @expand
    dec     NEW_0_DIVIDE_AREA_UDLR
    beq     @check_error

    ; 右へ拡げられるか
@check_right:
    ldy     _world_area_right, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    beq     @expand
    dec     NEW_0_DIVIDE_AREA_UDLR
    bne     @check_up

    ; 拡げられない
@check_error:
    inc     NEW_0_DIVIDE_AREA_POOL_CHECK
    ldy     NEW_0_DIVIDE_AREA_POOL_CHECK
    cpy     NEW_0_DIVIDE_AREA_POOL_LENGTH
    bne     :+
    ldy     #$00
    sty     NEW_0_DIVIDE_AREA_POOL_CHECK
:
    jmp     @check

    ; 拡げる
@expand:
    lda     new_area, y
    ora     #WORLD_AREA_INSIDE
    sta     new_area, y
    tya
    ldy     NEW_0_DIVIDE_AREA_POOL_LENGTH
    sta     @pool, y
    inc     NEW_0_DIVIDE_AREA_POOL_LENGTH
    dec     NEW_0_DIVIDE_AREA_SIZE
    beq     @fill

    ; 次に拡げる位置をランダムに取得
    jsr     _IocsGetRandomNumber
    lsr     a
    sec
:
    sbc     NEW_0_DIVIDE_AREA_POOL_LENGTH
    bcs     :-
    adc     NEW_0_DIVIDE_AREA_POOL_LENGTH
    tay
    jmp     @search

    ; アウトサイドがインサイドに囲まれていたらインサイドにする
@fill:
    ldx     #$00
:
    lda     new_area, x
    and     #WORLD_AREA_INSIDE
    bne     :+
    ldy     _world_area_up, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    beq     :+
    ldy     _world_area_down, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    beq     :+
    ldy     _world_area_left, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    beq     :+
    ldy     _world_area_right, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    beq     :+
    lda     new_area, x
    ora     #WORLD_AREA_INSIDE
    sta     new_area, x
:
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :--

    ; 終了
@end:
    rts

; プール
@pool:
    .res    25 ; WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y

.endproc

; ワールドへエリアを設定する
;
.proc   NewSetWorldArea

    ; ワールドへエリアを設定
    ldx     #$00
:
    lda     new_area, x
    sta     _world_area, x
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :-

    ; 終了
    rts

.endproc

; エリアを描画する
;
.proc   NewDrawArea

    ; 描画の設定
    lda     #$00
    sta     @draw_arg + $0000
    sta     @draw_arg + $0001

    ; 描画の開始
    lda     #$00
    sta     NEW_0_DRAW_AREA
:
    lda     #WORLD_AREA_SIZE_X
    sta     NEW_0_DRAW_AREA_SIZE_X
:
    ldx     NEW_0_DRAW_AREA
    lda     new_area, x
    sta     NEW_0_DRAW_AREA_VALUE

    ; 文字列の作成
    lsr     a
    lsr     a
    lsr     a
    lsr     a
    tay
    lda     @hex, y
    sta     @draw_string + $0000
    lda     NEW_0_DRAW_AREA_VALUE
    and     #$0f
    tay
    lda     @hex, y
    sta     @draw_string + $0001

    ; 文字列の描画
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDrawString

    ; 次のエリアへ
    inc     @draw_arg + $0000
    inc     @draw_arg + $0000
    inc     NEW_0_DRAW_AREA
    lda     NEW_0_DRAW_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bcs     :+
    dec     NEW_0_DRAW_AREA_SIZE_X
    bne     :-
    lda     #$00
    sta     @draw_arg + $0000
    inc     @draw_arg + $0001
    jmp     :--
:

    ; 終了
    rts

; 16 進数
@hex:
    .byte   "0123456789ABCDEF"

; 描画の引数
@draw_arg:
    .byte   $00, $00
    .word   @draw_string
@draw_string:
    .asciiz "00"

.endproc

; 指定された値のフィールド／ブロックをランダムに取得する
;
.proc   NewGetRandomFieldBlock

    ; IN
    ;   a = 取得する地形
    ;   x = マスク値
    ; OUT
    ;   a = ブロック
    ; WORK
    ;   NEW_0_WORK_0..1

    ; 引数の保存
    sta     NEW_0_WORK_0
    stx     NEW_0_WORK_1

    ; 検索を開始する位置の取得
:
    jsr     _IocsGetRandomNumber
    lsr     a
    cmp     #(WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y)
    bcs     :-

    ; 一致するブロックの取得
    tax
:
    lda     new_field_block, x
    and     NEW_0_WORK_1
    cmp     NEW_0_WORK_0
    beq     :+
    inx
    cpx     #(WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y)
    bne     :-
    ldx     #$00
    jmp     :-
:
    txa

    ; 終了
    rts

.endproc

; フィールド／ブロックに地形を拡げる
;
.proc   NewExpandFieldBlockLand

    ; IN
    ;   a = 地形
    ;   x = 広さ

    ; 引数の保持
    sta     NEW_0_EXPAND_FIELD_BLOCK_LAND
    stx     NEW_0_EXPAND_FIELD_BLOCK_SIZE

    ; プールの初期化
    ldx     #$00
    ldy     #$00
:
    lda     new_field_block, x
    cmp     NEW_0_EXPAND_FIELD_BLOCK_LAND
    bne     :+
    txa
    sta     @pool, y
    iny
:
    inx
    cpx     #(WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y)
    bne     :--
    sty     NEW_0_EXPAND_FIELD_BLOCK_POOL_LENGTH
    tya
    beq     @random
    dey
    jmp     @search

    ; ランダムに地形を置く
@random:
    lda     #WORLD_FIELD_BLOCK_LAND_GRASS
    ldx     #$ff
    jsr     NewGetRandomFieldBlock
    ldy     NEW_0_EXPAND_FIELD_BLOCK_POOL_LENGTH
    sta     @pool, y
    inc     NEW_0_EXPAND_FIELD_BLOCK_POOL_LENGTH
    tax
    lda     NEW_0_EXPAND_FIELD_BLOCK_LAND
    sta     new_field_block, x
    dec     NEW_0_EXPAND_FIELD_BLOCK_SIZE
    bne     :+
    jmp     @end
:

    ; 置かれた地形から拡げる
@search:
    sty     NEW_0_EXPAND_FIELD_BLOCK_POOL_START
    sty     NEW_0_EXPAND_FIELD_BLOCK_POOL_CHECK

    ; 拡げられるかどうかの確認
@check:
    lda     @pool, y
    tax
    lda     #$04
    sta     NEW_0_EXPAND_FIELD_BLOCK_UDLR
    jsr     _IocsGetRandomNumber
    and     #$03
    beq     @check_down
    sec
    sbc     #$01
    beq     @check_left
    sec
    sbc     #$01
    beq     @check_right
;   jmp     @check_up

    ; 上へ拡げられるか
@check_up:
    ldy     new_field_block_up, x
    lda     new_field_block, y
    cmp     #WORLD_FIELD_BLOCK_LAND_GRASS
    beq     @expand
    dec     NEW_0_EXPAND_FIELD_BLOCK_UDLR
    beq     @check_error

    ; 下へ拡げられるか
@check_down:
    ldy     new_field_block_down, x
    lda     new_field_block, y
    cmp     #WORLD_FIELD_BLOCK_LAND_GRASS
    beq     @expand
    dec     NEW_0_EXPAND_FIELD_BLOCK_UDLR
    beq     @check_error

    ; 左へ拡げられるか
@check_left:
    ldy     new_field_block_left, x
    lda     new_field_block, y
    cmp     #WORLD_FIELD_BLOCK_LAND_GRASS
    beq     @expand
    dec     NEW_0_EXPAND_FIELD_BLOCK_UDLR
    beq     @check_error

    ; 右へ拡げられるか
@check_right:
    ldy     new_field_block_right, x
    lda     new_field_block, y
    cmp     #WORLD_FIELD_BLOCK_LAND_GRASS
    beq     @expand
    dec     NEW_0_EXPAND_FIELD_BLOCK_UDLR
    bne     @check_up

    ; 拡げられない
@check_error:
    inc     NEW_0_EXPAND_FIELD_BLOCK_POOL_CHECK
    ldy     NEW_0_EXPAND_FIELD_BLOCK_POOL_CHECK
    cpy     NEW_0_EXPAND_FIELD_BLOCK_POOL_LENGTH
    bne     :+
    ldy     #$00
    sty     NEW_0_EXPAND_FIELD_BLOCK_POOL_CHECK
:
    cpy     NEW_0_EXPAND_FIELD_BLOCK_POOL_START
    bne     @check
    jmp     @random

    ; 拡げる
@expand:
    lda     NEW_0_EXPAND_FIELD_BLOCK_LAND
    sta     new_field_block, y
    tya
    ldy     NEW_0_EXPAND_FIELD_BLOCK_POOL_LENGTH
    sta     @pool, y
    inc     NEW_0_EXPAND_FIELD_BLOCK_POOL_LENGTH
    dec     NEW_0_EXPAND_FIELD_BLOCK_SIZE
    beq     @end

    ; 次に拡げる位置をランダムに取得
    jsr     _IocsGetRandomNumber
    lsr     a
    sec
:
    sbc     NEW_0_EXPAND_FIELD_BLOCK_POOL_LENGTH
    bcs     :-
    adc     NEW_0_EXPAND_FIELD_BLOCK_POOL_LENGTH
    tay
    jmp     @search

    ; 終了
@end:
    rts

; プール
@pool:
    .res    100 ; WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y

.endproc

; ランダムに選ばれたフィールド／ブロックに地形を置く
;
.proc   NewRandomFieldBlockLand

    ; IN
    ;   a = 地形
    ;   x = 広さ
    ; WORK
    ;   NEW_0_WORK_0

    ; 引数の保持
    sta     NEW_0_RANDOM_FIELD_BLOCK_LAND
    stx     NEW_0_RANDOM_FIELD_BLOCK_SIZE

    ; ランダムに地形を置く
:
    lda     #WORLD_FIELD_BLOCK_LAND_GRASS
    ldx     #$ff
    jsr     NewGetRandomFieldBlock
    tax
    lda     NEW_0_RANDOM_FIELD_BLOCK_LAND
    sta     new_field_block, x
    dec     NEW_0_RANDOM_FIELD_BLOCK_SIZE
    bne     :-

    ; 終了
    rts

.endproc

; フィールド／ブロックを描画する
;
.proc   NewDrawFieldBlock

    ; 描画の設定
    lda     #$00
    sta     NEW_0_DRAW_FIELD_BLOCK_DRAW_X
    sta     NEW_0_DRAW_FIELD_BLOCK_DRAW_Y

    ; 描画の開始
    lda     #$00
    sta     NEW_0_DRAW_FIELD_BLOCK
:
    lda     #WORLD_FIELD_BLOCK_SIZE_X
    sta     NEW_0_DRAW_FIELD_BLOCK_SIZE_X
:

    ; セルの描画
    ldx     NEW_0_DRAW_FIELD_BLOCK
    lda     new_field_block, x
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    ldx     NEW_0_DRAW_FIELD_BLOCK_DRAW_X
    ldy     NEW_0_DRAW_FIELD_BLOCK_DRAW_Y
    jsr     _WorldDrawCell

    ; 次のタイルへ
    inc     NEW_0_DRAW_FIELD_BLOCK_DRAW_X
    inc     NEW_0_DRAW_FIELD_BLOCK_DRAW_X
    inc     NEW_0_DRAW_FIELD_BLOCK
    lda     NEW_0_DRAW_FIELD_BLOCK
    cmp     #(WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y)
    bcs     :+
    dec     NEW_0_DRAW_FIELD_BLOCK_SIZE_X
    bne     :-
    lda     #$00
    sta     NEW_0_DRAW_FIELD_BLOCK_DRAW_X
    inc     NEW_0_DRAW_FIELD_BLOCK_DRAW_Y
    inc     NEW_0_DRAW_FIELD_BLOCK_DRAW_Y
    jmp     :--
:

    ; 終了
    rts

.endproc

; フィールド／セルの参照を取得する
;
.proc   NewGetFieldCellAddress

    ; IN
    ;   x = X 位置
    ;   y = Y 位置
    ; OUT
    ;   ax = セルの参照
    ; WORK
    ;   NEW_0_WORK_0..2

    ; X 位置の補正
    txa
    bpl     :+
    clc
    adc     #WORLD_FIELD_CELL_SIZE_X
:
    cmp     #WORLD_FIELD_CELL_SIZE_X
    bcc     :+
    sec
    sbc     #WORLD_FIELD_CELL_SIZE_X
:
    sta     NEW_0_WORK_2

    ; Y 位置の補正
    tya
    bpl     :+
    clc
    adc     #WORLD_FIELD_CELL_SIZE_Y
:
    cmp     #WORLD_FIELD_CELL_SIZE_Y
    bcc     :+
    sec
    sbc     #WORLD_FIELD_CELL_SIZE_Y
:

    ; セルの参照の取得
    ldx     #WORLD_FIELD_CELL_SIZE_X
    jsr     _IocsAxX
    sta     NEW_0_WORK_1
    txa
    clc
    adc     #<new_field_cell
    sta     NEW_0_WORK_0
    lda     NEW_0_WORK_1
    adc     #>new_field_cell
    sta     NEW_0_WORK_1
    lda     NEW_0_WORK_0
    clc
    adc     NEW_0_WORK_2
    tax
    lda     NEW_0_WORK_1
    adc     #$00

    ; 終了
    rts

.endproc

; フィールド／セルを取得する
;
.proc   NewGetFieldCell

    ; IN
    ;   x = X 位置
    ;   y = Y 位置
    ; OUT
    ;   a = セルの値
    ; WORK
    ;   NEW_0_WORK_0..1

    ; セルの参照の取得
    jsr     NewGetFieldCellAddress
    stx     NEW_0_WORK_0
    sta     NEW_0_WORK_1

    ; セルの取得
    ldy     #$00
    lda     (NEW_0_WORK_0), y

    ; 終了
    rts

.endproc

; フィールド／セルを設定する
;
.proc   NewSetFieldCell

    ; IN
    ;   a = セルの値
    ;   x = X 位置
    ;   y = Y 位置
    ; WORK
    ;   NEW_0_WORK_0..1

    ; セルの参照の取得
    pha
    jsr     NewGetFieldCellAddress
    stx     NEW_0_WORK_0
    sta     NEW_0_WORK_1

    ; セルの設定
    pla
    ldy     #$00
    sta     (NEW_0_WORK_0), y

    ; 終了
    rts

.endproc

; フィールド／セルを塗りつぶす
;
.proc   NewFillFieldCell

    ; ブロックの走査
    lda     #$00
    sta     NEW_0_FILL_FIELD_BLOCK
@block:

    ; 地形の取得
    ldx     NEW_0_FILL_FIELD_BLOCK
    lda     new_field_block, x
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     #WORLD_FIELD_BLOCK_LAND_GRASS
    beq     @next
    sta     NEW_0_FILL_FIELD_CELL_VALUE

    ; セル位置の取得
;   ldx     NEW_0_FILL_FIELD_BLOCK
    lda     new_field_block_cell_x, x
    sta     NEW_0_FILL_FIELD_CELL_START_X
    clc
    adc     #WORLD_FIELD_BLOCK_CELL_SIZE_X
    sta     NEW_0_FILL_FIELD_CELL_END_X
    lda     new_field_block_cell_y, x
    sta     NEW_0_FILL_FIELD_CELL_START_Y
    clc
    adc     #WORLD_FIELD_BLOCK_CELL_SIZE_Y
    sta     NEW_0_FILL_FIELD_CELL_END_Y

    ; 上のブロックとのつながり
;   ldx     NEW_0_FILL_FIELD_BLOCK
    ldy     new_field_block_up, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     NEW_0_FILL_FIELD_CELL_VALUE
    beq     :+
    inc     NEW_0_FILL_FIELD_CELL_START_Y
:
    
    ; 下のブロックとのつながり
;   ldx     NEW_0_FILL_FIELD_BLOCK
    ldy     new_field_block_down, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     NEW_0_FILL_FIELD_CELL_VALUE
    beq     :+
    dec     NEW_0_FILL_FIELD_CELL_END_Y
:
    
    ; 左のブロックとのつながり
;   ldx     NEW_0_FILL_FIELD_BLOCK
    ldy     new_field_block_left, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     NEW_0_FILL_FIELD_CELL_VALUE
    beq     :+
    inc     NEW_0_FILL_FIELD_CELL_START_X
:
    
    ; 右のブロックとのつながり
;   ldx     NEW_0_FILL_FIELD_BLOCK
    ldy     new_field_block_right, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     NEW_0_FILL_FIELD_CELL_VALUE
    beq     :+
    dec     NEW_0_FILL_FIELD_CELL_END_X
:
    
    ; セルの塗り潰し
    lda     NEW_0_FILL_FIELD_CELL_START_Y
    sta     NEW_0_FILL_FIELD_CELL_Y
:
    lda     NEW_0_FILL_FIELD_CELL_START_X
    sta     NEW_0_FILL_FIELD_CELL_X
:
    ldx     NEW_0_FILL_FIELD_CELL_X
    ldy     NEW_0_FILL_FIELD_CELL_Y
    lda     NEW_0_FILL_FIELD_CELL_VALUE
    jsr     NewSetFieldCell
    inc     NEW_0_FILL_FIELD_CELL_X
    lda     NEW_0_FILL_FIELD_CELL_X
    cmp     NEW_0_FILL_FIELD_CELL_END_X
    bne     :-
    inc     NEW_0_FILL_FIELD_CELL_Y
    lda     NEW_0_FILL_FIELD_CELL_Y
    cmp     NEW_0_FILL_FIELD_CELL_END_Y
    bne     :--

    ; 次のブロックへ
@next:
    inc     NEW_0_FILL_FIELD_BLOCK
    lda     NEW_0_FILL_FIELD_BLOCK
    cmp     #(WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y)
    beq     :+
    jmp     @block
:

    ; 終了
    rts

.endproc

; フィールド／セルの境界をぼかす
;
.proc   NewModifyFieldCellBorder

    ; ブロックの走査
    lda     #$00
    sta     NEW_0_MODIFY_FIELD_BLOCK
@block:

    ; 地形の取得
    ldx     NEW_0_MODIFY_FIELD_BLOCK
    lda     new_field_block, x
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     #WORLD_FIELD_BLOCK_LAND_GRASS
    bne     :+
    jmp     @next
:
    sta     NEW_0_MODIFY_FIELD_CELL_VALUE

    ; セル位置の取得
;   ldx     NEW_0_MODIFY_FIELD_BLOCK
    lda     new_field_block_cell_x, x
    sta     NEW_0_MODIFY_FIELD_CELL_O_X
    lda     new_field_block_cell_y, x
    sta     NEW_0_MODIFY_FIELD_CELL_O_Y

    ; 上のブロックとの繋がり
    ldx     NEW_0_FILL_FIELD_BLOCK
    ldy     new_field_block_up, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     NEW_0_FILL_FIELD_CELL_VALUE
    beq     :+
    lda     NEW_0_MODIFY_FIELD_CELL_O_X
    sta     NEW_0_MODIFY_FIELD_CELL_X
    lda     NEW_0_MODIFY_FIELD_CELL_O_Y
    sta     NEW_0_MODIFY_FIELD_CELL_Y
    jsr     @modify_h_2
    lda     NEW_0_MODIFY_FIELD_CELL_O_X
    sta     NEW_0_MODIFY_FIELD_CELL_X
    lda     NEW_0_MODIFY_FIELD_CELL_O_Y
    sec
    sbc     #$01
    sta     NEW_0_MODIFY_FIELD_CELL_Y
    jsr     @modify_h_4
:

    ; 下のブロックとの繋がり
    ldx     NEW_0_FILL_FIELD_BLOCK
    ldy     new_field_block_down, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     NEW_0_FILL_FIELD_CELL_VALUE
    beq     :+
    lda     NEW_0_MODIFY_FIELD_CELL_O_X
    sta     NEW_0_MODIFY_FIELD_CELL_X
    lda     NEW_0_MODIFY_FIELD_CELL_O_Y
    clc
    adc     #(WORLD_FIELD_BLOCK_CELL_SIZE_Y - $01)
    sta     NEW_0_MODIFY_FIELD_CELL_Y
    jsr     @modify_h_2
    lda     NEW_0_MODIFY_FIELD_CELL_O_X
    sta     NEW_0_MODIFY_FIELD_CELL_X
    lda     NEW_0_MODIFY_FIELD_CELL_O_Y
    clc
    adc     #WORLD_FIELD_BLOCK_CELL_SIZE_Y
    sta     NEW_0_MODIFY_FIELD_CELL_Y
    jsr     @modify_h_4
:

    ; 左のブロックとの繋がり
    ldx     NEW_0_FILL_FIELD_BLOCK
    ldy     new_field_block_left, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     NEW_0_FILL_FIELD_CELL_VALUE
    beq     :+
    lda     NEW_0_MODIFY_FIELD_CELL_O_X
    sta     NEW_0_MODIFY_FIELD_CELL_X
    lda     NEW_0_MODIFY_FIELD_CELL_O_Y
    sta     NEW_0_MODIFY_FIELD_CELL_Y
    jsr     @modify_v_2
    lda     NEW_0_MODIFY_FIELD_CELL_O_X
    sec
    sbc     #$01
    sta     NEW_0_MODIFY_FIELD_CELL_X
    lda     NEW_0_MODIFY_FIELD_CELL_O_Y
    sta     NEW_0_MODIFY_FIELD_CELL_Y
    jsr     @modify_v_4
:

    ; 右のブロックとの繋がり
    ldx     NEW_0_FILL_FIELD_BLOCK
    ldy     new_field_block_right, x
    lda     new_field_block, y
    and     #WORLD_FIELD_BLOCK_LAND_MASK
    cmp     NEW_0_FILL_FIELD_CELL_VALUE
    beq     :+
    lda     NEW_0_MODIFY_FIELD_CELL_O_X
    clc
    adc     #(WORLD_FIELD_BLOCK_CELL_SIZE_X - $01)
    sta     NEW_0_MODIFY_FIELD_CELL_X
    lda     NEW_0_MODIFY_FIELD_CELL_O_Y
    sta     NEW_0_MODIFY_FIELD_CELL_Y
    jsr     @modify_v_2
    lda     NEW_0_MODIFY_FIELD_CELL_O_X
    clc
    adc     #WORLD_FIELD_BLOCK_CELL_SIZE_X
    sta     NEW_0_MODIFY_FIELD_CELL_X
    lda     NEW_0_MODIFY_FIELD_CELL_O_Y
    sta     NEW_0_MODIFY_FIELD_CELL_Y
    jsr     @modify_v_4
:

    ; 次のブロックへ
@next:
    inc     NEW_0_MODIFY_FIELD_BLOCK
    lda     NEW_0_MODIFY_FIELD_BLOCK
    cmp     #(WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y)
    beq     :+
    jmp     @block
:

    ; 終了
    rts

    ; 横方向にぼかす
@modify_h_2:
    lda     #$ff
    sta     NEW_0_MODIFY_FIELD_CELL_RATE
    jmp     @modify_h
@modify_h_4:
    jsr     _IocsGetRandomNumber
    sta     NEW_0_MODIFY_FIELD_CELL_RATE
;   jmp     @modify_h
@modify_h:
    jsr     _IocsGetRandomNumber
    and     NEW_0_MODIFY_FIELD_CELL_RATE
    sta     NEW_0_MODIFY_FIELD_CELL_RATE
    lda     #WORLD_FIELD_BLOCK_CELL_SIZE_X
    sta     NEW_0_MODIFY_FIELD_CELL_SIZE
:
    clc
    rol     NEW_0_MODIFY_FIELD_CELL_RATE
    bcc     :+
    inc     NEW_0_MODIFY_FIELD_CELL_RATE
    ldx     NEW_0_MODIFY_FIELD_CELL_X
    ldy     NEW_0_MODIFY_FIELD_CELL_Y
    lda     NEW_0_MODIFY_FIELD_CELL_VALUE
    jsr     NewSetFieldCell
:
    inc     NEW_0_MODIFY_FIELD_CELL_X
    dec     NEW_0_MODIFY_FIELD_CELL_SIZE
    bne     :--
    rts

    ; 縦方向にぼかす
@modify_v_2:
    lda     #$ff
    sta     NEW_0_MODIFY_FIELD_CELL_RATE
    jmp     @modify_v
@modify_v_4:
    jsr     _IocsGetRandomNumber
    sta     NEW_0_MODIFY_FIELD_CELL_RATE
;   jmp     @modify_v
@modify_v:
    jsr     _IocsGetRandomNumber
    and     NEW_0_MODIFY_FIELD_CELL_RATE
    sta     NEW_0_MODIFY_FIELD_CELL_RATE
    lda     #WORLD_FIELD_BLOCK_CELL_SIZE_Y
    sta     NEW_0_MODIFY_FIELD_CELL_SIZE
:
    clc
    rol     NEW_0_MODIFY_FIELD_CELL_RATE
    bcc     :+
    inc     NEW_0_MODIFY_FIELD_CELL_RATE
    ldx     NEW_0_MODIFY_FIELD_CELL_X
    ldy     NEW_0_MODIFY_FIELD_CELL_Y
    lda     NEW_0_MODIFY_FIELD_CELL_VALUE
    jsr     NewSetFieldCell
:
    inc     NEW_0_MODIFY_FIELD_CELL_Y
    dec     NEW_0_MODIFY_FIELD_CELL_SIZE
    bne     :--
    rts

.endproc

; フィールド／セルに地形をちりばめる
;
.proc   NewRandomFieldCellLand

    ; IN
    ;   a = ちりばめる地形
    ;   x = 対象となるブロック

    ; 引数の保持
    sta     NEW_0_RANDOM_FIELD_CELL_LAND
    stx     NEW_0_RANDOM_FIELD_CELL_BLOCK

    ; ブロックの走査
    lda     #$00
    sta     NEW_0_RANDOM_FIELD_CELL_INDEX
@block:

    ; ブロックの一致
    ldx     NEW_0_RANDOM_FIELD_CELL_INDEX
    lda     new_field_block, x
    cmp     NEW_0_RANDOM_FIELD_CELL_BLOCK
    bne     @next

    ; ちりばめる数の取得
    jsr     _IocsGetRandomNumber
    and     #$01
    clc
    adc     #$01
    sta     NEW_0_RANDOM_FIELD_CELL_SIZE

    ; 地形を置く
@set:
:
    jsr     _IocsGetRandomNumber
    ror     a
    and     #$07
    cmp     #WORLD_FIELD_BLOCK_CELL_SIZE_X
    bcs     :-
    clc
    ldx     NEW_0_RANDOM_FIELD_CELL_INDEX
    clc
    adc     new_field_block_cell_x, x
    sta     NEW_0_RANDOM_FIELD_CELL_X
:
    jsr     _IocsGetRandomNumber
    rol     a
    and     #$07
    cmp     #WORLD_FIELD_BLOCK_CELL_SIZE_Y
    bcs     :-
    ldx     NEW_0_RANDOM_FIELD_CELL_INDEX
    clc
    adc     new_field_block_cell_y, x
    sta     NEW_0_RANDOM_FIELD_CELL_Y
    ldx     NEW_0_RANDOM_FIELD_CELL_X
    ldy     NEW_0_RANDOM_FIELD_CELL_Y
    lda     NEW_0_RANDOM_FIELD_CELL_LAND
    jsr     NewSetFieldCell
    dec     NEW_0_RANDOM_FIELD_CELL_SIZE
    bne     @set

    ; 次のブロックへ
@next:
    inc     NEW_0_RANDOM_FIELD_CELL_INDEX
    lda     NEW_0_RANDOM_FIELD_CELL_INDEX
    cmp     #(WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y)
    bne     @block

    ; 終了
@end:
    rts

.endproc

; フィールド／セルに水を流す
;
.proc   NewFlowFieldCell

    ; エリアの走査
    lda     #$00
    sta     NEW_0_FLOW_FIELD_CELL_AREA
@area:

    ; インサイドの判定
    ldx     NEW_0_FLOW_FIELD_CELL_AREA
    lda     new_area, x
    and     #WORLD_AREA_INSIDE
    bne     :+
    jmp     @next
:

    ; 上に流す
    ldx     NEW_0_FLOW_FIELD_CELL_AREA
    ldy     _world_area_up, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    bne     :+
    lda     new_field_area_cell_x, x
    sta     NEW_0_FLOW_FIELD_CELL_X
    lda     new_field_area_cell_y, x
    sta     NEW_0_FLOW_FIELD_CELL_Y
    dec     NEW_0_FLOW_FIELD_CELL_Y
    jsr     @flow_h
:

    ; 下に流す
    ldx     NEW_0_FLOW_FIELD_CELL_AREA
    ldy     _world_area_down, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    bne     :+
    lda     new_field_area_cell_x, x
    sta     NEW_0_FLOW_FIELD_CELL_X
    lda     new_field_area_cell_y, x
    clc
    adc     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y - $01)
    sta     NEW_0_FLOW_FIELD_CELL_Y
    jsr     @flow_h
:

    ; 左に流す
    ldx     NEW_0_FLOW_FIELD_CELL_AREA
    ldy     _world_area_left, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    bne     :+
    lda     new_field_area_cell_x, x
    sta     NEW_0_FLOW_FIELD_CELL_X
    dec     NEW_0_FLOW_FIELD_CELL_X
    lda     new_field_area_cell_y, x
    sta     NEW_0_FLOW_FIELD_CELL_Y
    jsr     @flow_v
:

    ; 右に流す
    ldx     NEW_0_FLOW_FIELD_CELL_AREA
    ldy     _world_area_right, x
    lda     new_area, y
    and     #WORLD_AREA_INSIDE
    bne     :+
    lda     new_field_area_cell_x, x
    clc
    adc     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X - $01)
    sta     NEW_0_FLOW_FIELD_CELL_X
    lda     new_field_area_cell_y, x
    sta     NEW_0_FLOW_FIELD_CELL_Y
    jsr     @flow_v
:

    ; 次のエリアへ
@next:
    inc     NEW_0_FLOW_FIELD_CELL_AREA
    lda     NEW_0_FLOW_FIELD_CELL_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    beq     :+
    jmp     @area
:

    ; 終了
    rts

    ; 横に流す
@flow_h:
    dec     NEW_0_FLOW_FIELD_CELL_X
    lda     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X + $02)
    sta     NEW_0_FLOW_FIELD_CELL_SIZE
:
    ldx     NEW_0_FLOW_FIELD_CELL_X
    ldy     NEW_0_FLOW_FIELD_CELL_Y
    lda     #WORLD_CELL_WATER_0000
    jsr     NewSetFieldCell
    ldx     NEW_0_FLOW_FIELD_CELL_X
    ldy     NEW_0_FLOW_FIELD_CELL_Y
    iny
    lda     #WORLD_CELL_WATER_0000
    jsr     NewSetFieldCell
    inc     NEW_0_FLOW_FIELD_CELL_X
    dec     NEW_0_FLOW_FIELD_CELL_SIZE
    bne     :-
    rts    

    ; 縦に流す
@flow_v:
    lda     #WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y
    sta     NEW_0_FLOW_FIELD_CELL_SIZE
:
    ldx     NEW_0_FLOW_FIELD_CELL_X
    ldy     NEW_0_FLOW_FIELD_CELL_Y
    lda     #WORLD_CELL_WATER_0000
    jsr     NewSetFieldCell
    ldx     NEW_0_FLOW_FIELD_CELL_X
    inx
    ldy     NEW_0_FLOW_FIELD_CELL_Y
    lda     #WORLD_CELL_WATER_0000
    jsr     NewSetFieldCell
    inc     NEW_0_FLOW_FIELD_CELL_Y
    dec     NEW_0_FLOW_FIELD_CELL_SIZE
    bne     :-
    rts

.endproc

; フィールド／セルの水に壁を立てる
;
.proc   NewWallFieldCell

    ; セルの走査
    lda     #$00
    sta     NEW_0_WALL_FIELD_CELL_Y
@search_y:
    lda     #$00
    sta     NEW_0_WALL_FIELD_CELL_X
@search_x:

    ; 水の存在
    ldx     NEW_0_WALL_FIELD_CELL_X
    ldy     NEW_0_WALL_FIELD_CELL_Y
    jsr     @is_water
    bcs     :+
    jmp     @next
:

    ; 壁の作成
    lda     #WORLD_CELL_WATER_0000
    sta     NEW_0_WALL_FIELD_CELL_WATER
    ldx     NEW_0_WALL_FIELD_CELL_X
    ldy     NEW_0_WALL_FIELD_CELL_Y
    dey
    jsr     @is_water
    bcs     :+
    lda     NEW_0_WALL_FIELD_CELL_WATER
    ora     #%00000011
    sta     NEW_0_WALL_FIELD_CELL_WATER
:
    ldx     NEW_0_WALL_FIELD_CELL_X
    ldy     NEW_0_WALL_FIELD_CELL_Y
    iny
    jsr     @is_water
    bcs     :+
    lda     NEW_0_WALL_FIELD_CELL_WATER
    ora     #%00001100
    sta     NEW_0_WALL_FIELD_CELL_WATER
:
    ldx     NEW_0_WALL_FIELD_CELL_X
    dex
    ldy     NEW_0_WALL_FIELD_CELL_Y
    jsr     @is_water
    bcs     :+
    lda     NEW_0_WALL_FIELD_CELL_WATER
    ora     #%00000101
    sta     NEW_0_WALL_FIELD_CELL_WATER
:
    ldx     NEW_0_WALL_FIELD_CELL_X
    inx
    ldy     NEW_0_WALL_FIELD_CELL_Y
    jsr     @is_water
    bcs     :+
    lda     NEW_0_WALL_FIELD_CELL_WATER
    ora     #%00001010
    sta     NEW_0_WALL_FIELD_CELL_WATER
:
    ldx     NEW_0_WALL_FIELD_CELL_X
    dex
    ldy     NEW_0_WALL_FIELD_CELL_Y
    dey
    jsr     @is_water
    bcs     :+
    lda     NEW_0_WALL_FIELD_CELL_WATER
    ora     #%00000001
    sta     NEW_0_WALL_FIELD_CELL_WATER
:
    ldx     NEW_0_WALL_FIELD_CELL_X
    inx
    ldy     NEW_0_WALL_FIELD_CELL_Y
    dey
    jsr     @is_water
    bcs     :+
    lda     NEW_0_WALL_FIELD_CELL_WATER
    ora     #%00000010
    sta     NEW_0_WALL_FIELD_CELL_WATER
:
    ldx     NEW_0_WALL_FIELD_CELL_X
    dex
    ldy     NEW_0_WALL_FIELD_CELL_Y
    iny
    jsr     @is_water
    bcs     :+
    lda     NEW_0_WALL_FIELD_CELL_WATER
    ora     #%00000100
    sta     NEW_0_WALL_FIELD_CELL_WATER
:
    ldx     NEW_0_WALL_FIELD_CELL_X
    inx
    ldy     NEW_0_WALL_FIELD_CELL_Y
    iny
    jsr     @is_water
    bcs     :+
    lda     NEW_0_WALL_FIELD_CELL_WATER
    ora     #%00001000
    sta     NEW_0_WALL_FIELD_CELL_WATER
:
    ldx     NEW_0_WALL_FIELD_CELL_X
    ldy     NEW_0_WALL_FIELD_CELL_Y
    lda     NEW_0_WALL_FIELD_CELL_WATER
    jsr     NewSetFieldCell

    ; 次のセルへ
@next:
    inc     NEW_0_WALL_FIELD_CELL_X
    lda     NEW_0_WALL_FIELD_CELL_X
    cmp     #WORLD_FIELD_CELL_SIZE_X
    beq     :+
    jmp     @search_x
:
    inc     NEW_0_WALL_FIELD_CELL_Y
    lda     NEW_0_WALL_FIELD_CELL_Y
    cmp     #WORLD_FIELD_CELL_SIZE_Y
    beq     :+
    jmp     @search_y
:

    ; 終了
    rts

    ; 川の判定
@is_water:
    jsr     NewGetFieldCell
    cmp     #WORLD_CELL_WATER_0000
    bcc     :+
    cmp     #(WORLD_CELL_WATER_1111 + $01)
    bcs     :+
    sec
    jmp     :++
:
    clc
:
    rts

.endproc

; フィールド／セルにイベントを配置する
;
.proc   NewEventFieldCell

    ; エリアの走査
    lda     #$00
    sta     NEW_0_EVENT_FIELD_CELL_AREA
@area:

    ; イベントの取得
    ldx     NEW_0_EVENT_FIELD_CELL_AREA
    lda     new_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_START
    beq     @start
    cmp     #WORLD_EVENT_STAIRS
    beq     @stairs
    cmp     #WORLD_EVENT_SWORD
    beq     @sword
    cmp     #WORLD_EVENT_BOOTS
    bne     :+
    jmp     @box
:
    cmp     #WORLD_EVENT_CLOAK
    bne     :+
    jmp     @box
:
    cmp     #WORLD_EVENT_MASK
    bne     :+
    jmp     @box
:
    cmp     #WORLD_EVENT_TORCH
    bne     :+
    jmp     @box
:
    cmp     #WORLD_EVENT_CRYSTAL_RED
    bne     :+
    jmp     @crystal
:
    cmp     #WORLD_EVENT_CRYSTAL_BLUE
    bne     :+
    jmp     @crystal
:
    cmp     #WORLD_EVENT_CRYSTAL_GREEN
    bne     :+
    jmp     @crystal
:
    jmp     @next

    ; 開始
@start:
    jmp     @next

    ; 階段
@stairs:
    jsr     @random
    lda     #WORLD_CELL_STAIRS_DOWN
    jsr     NewSetFieldCell
    jmp     @next

    ; 剣
@sword:
    ldx     NEW_0_EVENT_FIELD_CELL_AREA
    lda     new_field_area_block_cell_y, x
    clc
    adc     #((WORLD_FIELD_BLOCK_CELL_SIZE_Y - $03) / $02)
    sta     NEW_0_EVENT_FIELD_CELL_Y
    lda     #$03
    sta     NEW_0_EVENT_FIELD_CELL_SIZE_Y
:
    ldx     NEW_0_EVENT_FIELD_CELL_AREA
    lda     new_field_area_block_cell_x, x
    clc
    adc     #((WORLD_FIELD_BLOCK_CELL_SIZE_X - $05) / $02)
    sta     NEW_0_EVENT_FIELD_CELL_X
    lda     #$05
    sta     NEW_0_EVENT_FIELD_CELL_SIZE_X
    jsr     _IocsGetRandomNumber
    sta     NEW_0_EVENT_FIELD_CELL_PARAM
:
    asl     NEW_0_EVENT_FIELD_CELL_PARAM
    bcc     :+
    ldx     NEW_0_EVENT_FIELD_CELL_X
    ldy     NEW_0_EVENT_FIELD_CELL_Y
    lda     #WORLD_CELL_PAVE
    jsr     NewSetFieldCell
:
    inc     NEW_0_EVENT_FIELD_CELL_X
    dec     NEW_0_EVENT_FIELD_CELL_SIZE_X
    bne     :--
    inc     NEW_0_EVENT_FIELD_CELL_Y
    dec     NEW_0_EVENT_FIELD_CELL_SIZE_Y
    bne     :---
    ldx     NEW_0_EVENT_FIELD_CELL_AREA
    lda     new_field_area_block_cell_x, x
    clc
    adc     #((WORLD_FIELD_BLOCK_CELL_SIZE_X / $02) - $01)
    sta     NEW_0_EVENT_FIELD_CELL_X
    lda     new_field_area_block_cell_y, x
    clc
    adc     #(WORLD_FIELD_BLOCK_CELL_SIZE_Y / $02)
    sta     NEW_0_EVENT_FIELD_CELL_Y
    ldx     NEW_0_EVENT_FIELD_CELL_X
    ldy     NEW_0_EVENT_FIELD_CELL_Y
    lda     #WORLD_CELL_PAVE
    jsr     NewSetFieldCell
    inc     NEW_0_EVENT_FIELD_CELL_X
    ldx     NEW_0_EVENT_FIELD_CELL_X
    ldy     NEW_0_EVENT_FIELD_CELL_Y
    lda     #WORLD_CELL_SWORD
    jsr     NewSetFieldCell
    inc     NEW_0_EVENT_FIELD_CELL_X
    ldx     NEW_0_EVENT_FIELD_CELL_X
    ldy     NEW_0_EVENT_FIELD_CELL_Y
    lda     #WORLD_CELL_PAVE
    jsr     NewSetFieldCell
    jmp     @next

    ; 宝箱
@box:
    jsr     @random
    stx     NEW_0_EVENT_FIELD_CELL_X
    sty     NEW_0_EVENT_FIELD_CELL_Y
    lda     #WORLD_CELL_BOX
    jsr     NewSetFieldCell
    jsr     _IocsGetRandomNumber
    sta     NEW_0_EVENT_FIELD_CELL_PARAM
    ldx     #$00
:
    asl     NEW_0_EVENT_FIELD_CELL_PARAM
    bcc     :++
    txa
    pha
    lda     @pave_x, x
    clc
    adc     NEW_0_EVENT_FIELD_CELL_X
    sta     NEW_0_EVENT_FIELD_CELL_PAVE_X
    lda     @pave_y, x
    clc
    adc     NEW_0_EVENT_FIELD_CELL_Y
    sta     NEW_0_EVENT_FIELD_CELL_PAVE_Y
    ldx     NEW_0_EVENT_FIELD_CELL_PAVE_X
    ldy     NEW_0_EVENT_FIELD_CELL_PAVE_Y
    jsr     NewGetFieldCell
    cmp     #WORLD_CELL_WATER_0000
    bcs     :+
    ldx     NEW_0_EVENT_FIELD_CELL_PAVE_X
    ldy     NEW_0_EVENT_FIELD_CELL_PAVE_Y
    lda     #WORLD_CELL_PAVE
    jsr     NewSetFieldCell
:
    pla
    tax
:
    inx
    cpx     #$08
    bne     :---
    jmp     @next

    ; 水晶
@crystal:
    jsr     @random
    lda     #WORLD_CELL_PAVE
    jsr     NewSetFieldCell
    jmp     @next

    ; 次のエリアへ
@next:
    inc     NEW_0_EVENT_FIELD_CELL_AREA
    lda     NEW_0_EVENT_FIELD_CELL_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    beq     :+
    jmp     @area
:

    ; 終了
    rts

    ; ランダムな位置の取得
@random:
:
    jsr     _IocsGetRandomNumber
    and     #$1f
    tay
    ldx     NEW_0_EVENT_FIELD_CELL_AREA
    lda     new_field_area_block_cell_x, x
    clc
    adc     @random_x, y
    sta     NEW_0_EVENT_FIELD_CELL_X
    lda     new_field_area_block_cell_y, x
    clc
    adc     @random_y, y
    sta     NEW_0_EVENT_FIELD_CELL_Y
    ldx     NEW_0_EVENT_FIELD_CELL_X
    ldy     NEW_0_EVENT_FIELD_CELL_Y
    jsr     NewGetFieldCell
    cmp     #WORLD_CELL_WATER_0000
    bcs     :-
    ldx     NEW_0_EVENT_FIELD_CELL_X
    ldy     NEW_0_EVENT_FIELD_CELL_Y
    rts

; ランダムな位置
@random_x:
    .byte   $00, $01, $02, $03, $04, $05, $06
    .byte   $00, $01, $02, $03, $04, $05, $06
    .byte   $00, $01,                $05, $06
    .byte   $00, $01, $02, $03, $04, $05, $06
    .byte   $00, $01, $02, $03, $04, $05, $06
@random_y:
    .byte   $00, $00, $00, $00, $00, $00, $00
    .byte   $01, $01, $01, $01, $01, $01, $01
    .byte   $02, $02,                $02, $02
    .byte   $03, $03, $03, $03, $03, $03, $03
    .byte   $04, $04, $04, $04, $04, $04, $04

; 舗装の位置
@pave_x:
    .byte   $ff, $00, $01, $ff, $01, $ff, $00, $01
@pave_y:
    .byte   $ff, $ff, $ff, $00, $00, $01, $01, $01

.endproc

; フィールド／セルの森を密集させる
;
.proc   NewThickFieldCell

    ; セルの走査
    lda     #$00
    sta     NEW_0_THICK_FIELD_CELL_Y
@search_y:
    lda     #$00
    sta     NEW_0_THICK_FIELD_CELL_X
@search_x:

    ; 森の判定
    ldx     NEW_0_THICK_FIELD_CELL_X
    ldy     NEW_0_THICK_FIELD_CELL_Y
    jsr     @is_forest
    bcc     @next

    ; 森を密集させる
    lda     #WORLD_CELL_FOREST
    sta     NEW_0_THICK_FIELD_CELL_FOREST
    ldx     NEW_0_THICK_FIELD_CELL_X
    ldy     NEW_0_THICK_FIELD_CELL_Y
    dey
    jsr     @is_forest
    bcc     :+
    lda     NEW_0_THICK_FIELD_CELL_FOREST
    ora     #%00000001
    sta     NEW_0_THICK_FIELD_CELL_FOREST
:
    ldx     NEW_0_THICK_FIELD_CELL_X
    ldy     NEW_0_THICK_FIELD_CELL_Y
    iny
    jsr     @is_forest
    bcc     :+
    lda     NEW_0_THICK_FIELD_CELL_FOREST
    ora     #%00000010
    sta     NEW_0_THICK_FIELD_CELL_FOREST
:
    ldx     NEW_0_THICK_FIELD_CELL_X
    ldy     NEW_0_THICK_FIELD_CELL_Y
    lda     NEW_0_THICK_FIELD_CELL_FOREST
    jsr     NewSetFieldCell

    ; 次のセルへ
@next:
    inc     NEW_0_THICK_FIELD_CELL_X
    lda     NEW_0_THICK_FIELD_CELL_X
    cmp     #WORLD_FIELD_CELL_SIZE_X
    bne     @search_x
    inc     NEW_0_THICK_FIELD_CELL_Y
    lda     NEW_0_THICK_FIELD_CELL_Y
    cmp     #WORLD_FIELD_CELL_SIZE_Y
    bne     @search_y

    ; 終了
    rts

    ; 森の判定
@is_forest:
    jsr     NewGetFieldCell
    cmp     #WORLD_CELL_FOREST
    bcc     :+
    cmp     #(WORLD_CELL_FOREST_THICK_UD + $01)
    bcs     :+
    sec
    jmp     :++
:
    clc
:
    rts

.endproc

; フィールド／セルをずらす
;
.proc   NewShiftFieldCell

    ; 横にずらす
    lda     #$00
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_Y
@shift_x:

    ; セルの位置の取得
    lda     NEW_0_SHIFT_FIELD_CELL_SRC_Y
    ldx     #WORLD_FIELD_CELL_SIZE_X
    jsr     _IocsAxX
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_H
    txa
    clc
    adc     #<new_field_cell
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_L
    sta     NEW_0_SHIFT_FIELD_CELL_DST_ADDRESS_L
    lda     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_H
    adc     #>new_field_cell
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_H
    sta     NEW_0_SHIFT_FIELD_CELL_DST_ADDRESS_H

    ; 先頭のセルの保存
    ldy     #$00
:
    lda     (NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS), y
    sta     @work, y
    iny
    cpy     #(WORLD_FIELD_BLOCK_CELL_SIZE_X / 2)
    bne     :-

    ; セルの移動
    sty     NEW_0_SHIFT_FIELD_CELL_SRC_X
    lda     #$00
    sta     NEW_0_SHIFT_FIELD_CELL_DST_X
:
    ldy     NEW_0_SHIFT_FIELD_CELL_SRC_X
    lda     (NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS), y
    ldy     NEW_0_SHIFT_FIELD_CELL_DST_X
    sta     (NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS), y
    inc     NEW_0_SHIFT_FIELD_CELL_SRC_X
    inc     NEW_0_SHIFT_FIELD_CELL_DST_X
    lda     NEW_0_SHIFT_FIELD_CELL_SRC_X
    cmp     #WORLD_FIELD_CELL_SIZE_X
    bne     :-

    ; 先頭のセルの追加
    ldx     #$00
    ldy     NEW_0_SHIFT_FIELD_CELL_DST_X
:
    lda     @work, x
    sta     (NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS), y
    inx
    iny
    cpy     #WORLD_FIELD_CELL_SIZE_X
    bne     :-

    ; 次のセルへ
    inc     NEW_0_SHIFT_FIELD_CELL_SRC_Y
    lda     NEW_0_SHIFT_FIELD_CELL_SRC_Y
    cmp     #WORLD_FIELD_CELL_SIZE_Y
    bne     @shift_x

    ; 先頭行のセルの保存
    lda     #<new_field_cell
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_L
    lda     #>new_field_cell
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_H
    ldy     #$00
:
    lda     (NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS), y
    sta     @work, y
    iny
    cpy     #(WORLD_FIELD_CELL_SIZE_X * (WORLD_FIELD_BLOCK_CELL_SIZE_Y / 2))
    bne     :-

    ; 縦にずらす
    lda     #(WORLD_FIELD_BLOCK_CELL_SIZE_Y / 2)
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_Y
    lda     #$00
    sta     NEW_0_SHIFT_FIELD_CELL_DST_Y
@shift_y:

    ; セルの位置の取得
    lda     NEW_0_SHIFT_FIELD_CELL_SRC_Y
    ldx     #WORLD_FIELD_CELL_SIZE_X
    jsr     _IocsAxX
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_H
    txa
    clc
    adc     #<new_field_cell
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_L
    lda     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_H
    adc     #>new_field_cell
    sta     NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS_H
    lda     NEW_0_SHIFT_FIELD_CELL_DST_Y
    ldx     #WORLD_FIELD_CELL_SIZE_X
    jsr     _IocsAxX
    sta     NEW_0_SHIFT_FIELD_CELL_DST_ADDRESS_H
    txa
    clc
    adc     #<new_field_cell
    sta     NEW_0_SHIFT_FIELD_CELL_DST_ADDRESS_L
    lda     NEW_0_SHIFT_FIELD_CELL_DST_ADDRESS_H
    adc     #>new_field_cell
    sta     NEW_0_SHIFT_FIELD_CELL_DST_ADDRESS_H

    ; セルの移動
    ldy     #$00
:
    lda     (NEW_0_SHIFT_FIELD_CELL_SRC_ADDRESS), y
    sta     (NEW_0_SHIFT_FIELD_CELL_DST_ADDRESS), y
    iny
    cpy     #WORLD_FIELD_CELL_SIZE_X
    bne     :-

    ; 次のセルへ
    inc     NEW_0_SHIFT_FIELD_CELL_SRC_Y
    inc     NEW_0_SHIFT_FIELD_CELL_DST_Y
    lda     NEW_0_SHIFT_FIELD_CELL_SRC_Y
    cmp     #WORLD_FIELD_CELL_SIZE_Y
    bne     @shift_y

    ; 先頭行のセルの追加
    ldx     #$00
    ldy     #WORLD_FIELD_CELL_SIZE_X
:
    lda     @work, x
    sta     (NEW_0_SHIFT_FIELD_CELL_DST_ADDRESS), y
    inx
    iny
    cpx     #(WORLD_FIELD_CELL_SIZE_X * (WORLD_FIELD_BLOCK_CELL_SIZE_Y / 2))
    bne     :-

    ; 終了
    rts

; ワーク
@work:
    .res    70 * 2      ; WORLD_FIELD_CELL_SIZE_X * (WORLD_FIELD_BLOCK_CELL_SIZE_Y / 2)

.endproc

; ワールドへフィールド／セルを設定する
;
.proc   NewSetWorldFieldCell

    ; ワールドへセルを設定
    lda     #$00
    sta     NEW_0_SET_FIELD_CELL_AREA
@area:

    ; エリアの取得
    ldx     NEW_0_SET_FIELD_CELL_AREA
    lda     _world_cell_address_l, x
    sta     NEW_0_SET_FIELD_CELL_ADDRESS_L
    lda     _world_cell_address_h, x
    sta     NEW_0_SET_FIELD_CELL_ADDRESS_H
    lda     #$00
    sta     NEW_0_SET_FIELD_CELL_INDEX

    ; エリア単位でセルを設定
    ldx     NEW_0_SET_FIELD_CELL_AREA
    lda     new_field_area_cell_y, x
    sta     NEW_0_SET_FIELD_CELL_Y
    lda     #WORLD_AREA_CELL_SIZE_Y
    sta     NEW_0_SET_FIELD_CELL_SIZE_Y
@cell_y:
    ldx     NEW_0_SET_FIELD_CELL_AREA
    lda     new_field_area_cell_x, x
    sta     NEW_0_SET_FIELD_CELL_X
    lda     #WORLD_AREA_CELL_SIZE_X
    sta     NEW_0_SET_FIELD_CELL_SIZE_X
@cell_x:

    ; セルのクリア
    ldy     NEW_0_SET_FIELD_CELL_INDEX
    lda     (NEW_0_SET_FIELD_CELL_ADDRESS), y
    and     #(~WORLD_CELL_FIELD_MASK & $ff)
    sta     (NEW_0_SET_FIELD_CELL_ADDRESS), y

    ; セルの取得
    ldx     NEW_0_SET_FIELD_CELL_X
    ldy     NEW_0_SET_FIELD_CELL_Y
    jsr     NewGetFieldCell

    ; セルの設定
    ldy     NEW_0_SET_FIELD_CELL_INDEX
    ora     (NEW_0_SET_FIELD_CELL_ADDRESS), y
    sta     (NEW_0_SET_FIELD_CELL_ADDRESS), y

    ; 次のセルへ
    inc     NEW_0_SET_FIELD_CELL_INDEX
    inc     NEW_0_SET_FIELD_CELL_X
    dec     NEW_0_SET_FIELD_CELL_SIZE_X
    bne     @cell_x
    inc     NEW_0_SET_FIELD_CELL_Y
    dec     NEW_0_SET_FIELD_CELL_SIZE_Y
    bne     @cell_y

    ; 次のエリアへ
    inc     NEW_0_SET_FIELD_CELL_AREA
    lda     NEW_0_SET_FIELD_CELL_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     @area

    ; 終了
    rts

.endproc

; フィールド／セルを描画する
;
.proc   NewDrawFieldCell

    ; IN
    ;   x = セルの開始 X 位置
    ;   y = セルの開始 Y 位置

    ; 引数の保持
    stx     NEW_0_DRAW_FIELD_CELL_X
    sty     NEW_0_DRAW_FIELD_CELL_Y

    ; 描画の設定
    lda     #$00
    sta     NEW_0_DRAW_FIELD_CELL_DRAW_X
    sta     NEW_0_DRAW_FIELD_CELL_DRAW_Y

    ; 描画の開始
    lda     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y)
    sta     NEW_0_DRAW_FIELD_CELL_SIZE_Y
@line:

    ; セルの位置の取得
    lda     NEW_0_DRAW_FIELD_CELL_Y
    ldx     #WORLD_FIELD_CELL_SIZE_X
    jsr     _IocsAxX
    sta     NEW_0_DRAW_FIELD_CELL_ADDRESS_H
    txa
    clc
    adc     #<new_field_cell
    sta     NEW_0_DRAW_FIELD_CELL_ADDRESS_L
    lda     NEW_0_DRAW_FIELD_CELL_ADDRESS_H
    adc     #>new_field_cell
    sta     NEW_0_DRAW_FIELD_CELL_ADDRESS_H

    ; １行の描画
    lda     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X)
    sta     NEW_0_DRAW_FIELD_CELL_SIZE_X
@line_1:

    ; セルの描画
    ldy     NEW_0_DRAW_FIELD_CELL_X
    lda     (NEW_0_DRAW_FIELD_CELL_ADDRESS), y
    ldx     NEW_0_DRAW_FIELD_CELL_DRAW_X
    ldy     NEW_0_DRAW_FIELD_CELL_DRAW_Y
    jsr     _WorldDrawCell

    ; 次の桁へ
    inc     NEW_0_DRAW_FIELD_CELL_DRAW_X
    inc     NEW_0_DRAW_FIELD_CELL_DRAW_X
    inc     NEW_0_DRAW_FIELD_CELL_X
    dec     NEW_0_DRAW_FIELD_CELL_SIZE_X
    bne     @line_1

    ; 次の行へ
    lda     #$00
    sta     NEW_0_DRAW_FIELD_CELL_DRAW_X
    inc     NEW_0_DRAW_FIELD_CELL_DRAW_Y
    inc     NEW_0_DRAW_FIELD_CELL_DRAW_Y
    lda     NEW_0_DRAW_FIELD_CELL_X
    sec
    sbc     #(WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X)
    sta     NEW_0_DRAW_FIELD_CELL_X
    inc     NEW_0_DRAW_FIELD_CELL_Y
    dec     NEW_0_DRAW_FIELD_CELL_SIZE_Y
    beq     :+
    jmp     @line
:

    ; 終了
    rts

.endproc

; ダンジョン／リンクの迷路を作成する
;
.proc   NewMazeDungeonLink

    ; スタックの初期化
    lda     #$00
    sta     @stack
    lda     #$01
    sta     NEW_0_MAZE_DUNGEON_LINK_STACK_SIZE

    ; ドラゴンの位置はつながない
    ldx     #$00
:
    lda     new_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_SWORD
    beq     :+
    inx
    jmp     :-
:
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_LOCK
    sta     new_dungeon_link, x

    ; 迷路の作成
@loop:

    ; ランダムな方向に迷路つなげる
    ldx     NEW_0_MAZE_DUNGEON_LINK_STACK_SIZE
    dex
    lda     @stack, x
    sta     NEW_0_MAZE_DUNGEON_LINK_M
    lda     #$04
    sta     NEW_0_MAZE_DUNGEON_LINK_I
    jsr     _IocsGetRandomNumber
    and     #$03
    beq     @link_up
    cmp     #$01
    beq     @link_down
    cmp     #$02
    beq     @link_left
    jmp     @link_right

    ; 上につなげる
@link_up:
    ldx     NEW_0_MAZE_DUNGEON_LINK_M
    ldy     _world_area_up, x
    lda     new_dungeon_link, y
    beq     :+
    dec     NEW_0_MAZE_DUNGEON_LINK_I
    bne     @link_down
    jmp     @pop
:
    lda     new_dungeon_link, y
    ora     #WORLD_DUNGEON_LINK_DOWN
    sta     new_dungeon_link, y
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_UP
    sta     new_dungeon_link, x
    jmp     @push_y

    ; 下につなげる
@link_down:
    ldx     NEW_0_MAZE_DUNGEON_LINK_M
    ldy     _world_area_down, x
    lda     new_dungeon_link, y
    beq     :+
    dec     NEW_0_MAZE_DUNGEON_LINK_I
    bne     @link_left
    jmp     @pop
:
    lda     new_dungeon_link, y
    ora     #WORLD_DUNGEON_LINK_UP
    sta     new_dungeon_link, y
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_DOWN
    sta     new_dungeon_link, x
    jmp     @push_y

    ; 左につなげる
@link_left:
    ldx     NEW_0_MAZE_DUNGEON_LINK_M
    ldy     _world_area_left, x
    lda     new_dungeon_link, y
    beq     :+
    dec     NEW_0_MAZE_DUNGEON_LINK_I
    bne     @link_right
    jmp     @pop
:
    lda     new_dungeon_link, y
    ora     #WORLD_DUNGEON_LINK_RIGHT
    sta     new_dungeon_link, y
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_LEFT
    sta     new_dungeon_link, x
    jmp     @push_y

    ; 右につなげる
@link_right:
    ldx     NEW_0_MAZE_DUNGEON_LINK_M
    ldy     _world_area_right, x
    lda     new_dungeon_link, y
    beq     :+
    dec     NEW_0_MAZE_DUNGEON_LINK_I
    bne     @link_up
    jmp     @pop
:
    lda     new_dungeon_link, y
    ora     #WORLD_DUNGEON_LINK_LEFT
    sta     new_dungeon_link, y
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_RIGHT
    sta     new_dungeon_link, x
    jmp     @push_y

    ; y をスタックに積む
@push_y:
    tya
    ldx     NEW_0_MAZE_DUNGEON_LINK_STACK_SIZE
    sta     @stack, x
    inc     NEW_0_MAZE_DUNGEON_LINK_STACK_SIZE
    jmp     @loop

    ; スタックから取り出す
@pop:
    dec     NEW_0_MAZE_DUNGEON_LINK_STACK_SIZE
    beq     :+
    jmp     @loop
:

    ; 終了
    rts

; スタック
@stack:
    .res    25 ; WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y

.endproc

; ダンジョン／リンクの行き止まりをなくす
;
.proc   NewUnendDungeonLink

    ; リンクの走査
    ldx     #$00
@search:

    ; 行き止まりの取得
    lda     new_dungeon_link, x

    ; 上に行き止まり
@end_up:
    cmp     #WORLD_DUNGEON_LINK_UP
    bne     @end_down
    ldy     _world_area_down, x
    lda     new_dungeon_link, y
    and     #WORLD_DUNGEON_LINK_LOCK
    bne     @next
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_DOWN
    sta     new_dungeon_link, x
    lda     new_dungeon_link, y
    ora     #WORLD_DUNGEON_LINK_UP
    sta     new_dungeon_link, y
    jmp     @next

    ; 下に行き止まり
@end_down:
    cmp     #WORLD_DUNGEON_LINK_DOWN
    bne     @end_left
    ldy     _world_area_up, x
    lda     new_dungeon_link, y
    and     #WORLD_DUNGEON_LINK_LOCK
    bne     @next
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_UP
    sta     new_dungeon_link, x
    lda     new_dungeon_link, y
    ora     #WORLD_DUNGEON_LINK_DOWN
    sta     new_dungeon_link, y
    jmp     @next

    ; 左に行き止まり
@end_left:
    cmp     #WORLD_DUNGEON_LINK_LEFT
    bne     @end_right
    ldy     _world_area_right, x
    lda     new_dungeon_link, y
    and     #WORLD_DUNGEON_LINK_LOCK
    bne     @next
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_RIGHT
    sta     new_dungeon_link, x
    lda     new_dungeon_link, y
    ora     #WORLD_DUNGEON_LINK_LEFT
    sta     new_dungeon_link, y
    jmp     @next

    ; 右に行き止まり
@end_right:
    cmp     #WORLD_DUNGEON_LINK_RIGHT
    bne     @next
    ldy     _world_area_left, x
    lda     new_dungeon_link, y
    and     #WORLD_DUNGEON_LINK_LOCK
    bne     @next
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_LEFT
    sta     new_dungeon_link, x
    lda     new_dungeon_link, y
    ora     #WORLD_DUNGEON_LINK_RIGHT
    sta     new_dungeon_link, y
    jmp     @next

    ; 次のリンクへ
@next:
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    beq     :+
    jmp     @search
:

    ; 終了
    rts

.endproc

; ダンジョン／ドラゴンの部屋を開く
;
.proc   NewOpenDungeonLinkSword

    ; ドラゴンの部屋の走査
    ldx     #$00
:
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_LOCK
    bne     :+
    inx
    jmp     :-
:

    ; 下の部屋へつなげる
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_DOWN
    sta     new_dungeon_link, x

    ; 下の部屋からつなげる
    lda     _world_area_down, x
    tax
    lda     new_dungeon_link, x
    ora     #WORLD_DUNGEON_LINK_UP
    sta     new_dungeon_link, x

    ; 終了
    rts

.endproc

; ダンジョン／リンクを描画する
;
.proc   NewDrawDungeonLink

    ; 四隅の描画
    lda     #$00
    sta     NEW_0_DRAW_DUNGEON_LINK_AREA
    sta     NEW_0_DRAW_DUNGEON_LINK_Y
:
    lda     #$00
    sta     NEW_0_DRAW_DUNGEON_LINK_X
:
    ldx     NEW_0_DRAW_DUNGEON_LINK_X
    ldy     NEW_0_DRAW_DUNGEON_LINK_Y
    lda     #WORLD_CELL_WALL
    jsr     _WorldDrawCell
    ldx     NEW_0_DRAW_DUNGEON_LINK_X
    inx
    inx
    inx
    inx
    ldy     NEW_0_DRAW_DUNGEON_LINK_Y
    lda     #WORLD_CELL_WALL
    jsr     _WorldDrawCell
    ldx     NEW_0_DRAW_DUNGEON_LINK_X
    ldy     NEW_0_DRAW_DUNGEON_LINK_Y
    iny
    iny
    iny
    iny
    lda     #WORLD_CELL_WALL
    jsr     _WorldDrawCell
    ldx     NEW_0_DRAW_DUNGEON_LINK_X
    inx
    inx
    inx
    inx
    ldy     NEW_0_DRAW_DUNGEON_LINK_Y
    iny
    iny
    iny
    iny
    lda     #WORLD_CELL_WALL
    jsr     _WorldDrawCell
    lda     NEW_0_DRAW_DUNGEON_LINK_X
    clc
    adc     #$04
    sta     NEW_0_DRAW_DUNGEON_LINK_X
    cmp     #(WORLD_AREA_SIZE_X * $04)
    bne     :-
    lda     NEW_0_DRAW_DUNGEON_LINK_Y
    clc
    adc     #$04
    sta     NEW_0_DRAW_DUNGEON_LINK_Y
    cmp     #(WORLD_AREA_SIZE_Y * $04)
    bne     :--

    ; 壁の描画
    lda     #$00
    sta     NEW_0_DRAW_DUNGEON_LINK_AREA
    sta     NEW_0_DRAW_DUNGEON_LINK_Y
@link_y:
    lda     #$00
    sta     NEW_0_DRAW_DUNGEON_LINK_X
@link_x:
    ldx     NEW_0_DRAW_DUNGEON_LINK_AREA
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_UP
    bne     :+
    ldx     NEW_0_DRAW_DUNGEON_LINK_X
    inx
    inx
    ldy     NEW_0_DRAW_DUNGEON_LINK_Y
    lda     #WORLD_CELL_WALL
    jsr     _WorldDrawCell
:    
    ldx     NEW_0_DRAW_DUNGEON_LINK_AREA
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_DOWN
    bne     :+
    ldx     NEW_0_DRAW_DUNGEON_LINK_X
    inx
    inx
    ldy     NEW_0_DRAW_DUNGEON_LINK_Y
    iny
    iny
    iny
    iny
    lda     #WORLD_CELL_WALL
    jsr     _WorldDrawCell
:
    ldx     NEW_0_DRAW_DUNGEON_LINK_AREA
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_LEFT
    bne     :+
    ldx     NEW_0_DRAW_DUNGEON_LINK_X
    ldy     NEW_0_DRAW_DUNGEON_LINK_Y
    iny
    iny
    lda     #WORLD_CELL_WALL
    jsr     _WorldDrawCell
:    
    ldx     NEW_0_DRAW_DUNGEON_LINK_AREA
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_RIGHT
    bne     :+
    ldx     NEW_0_DRAW_DUNGEON_LINK_X
    inx
    inx
    inx
    inx
    ldy     NEW_0_DRAW_DUNGEON_LINK_Y
    iny
    iny
    lda     #WORLD_CELL_WALL
    jsr     _WorldDrawCell
:
    inc     NEW_0_DRAW_DUNGEON_LINK_AREA
    lda     NEW_0_DRAW_DUNGEON_LINK_X
    clc
    adc     #$04
    sta     NEW_0_DRAW_DUNGEON_LINK_X
    cmp     #(WORLD_AREA_SIZE_X * $04)
    bne     @link_x
    lda     NEW_0_DRAW_DUNGEON_LINK_Y
    clc
    adc     #$04
    sta     NEW_0_DRAW_DUNGEON_LINK_Y
    cmp     #(WORLD_AREA_SIZE_Y * $04)
    bne     @link_y

    ; 終了
    rts

; 描画の引数
@draw_arg:
    .byte   $00, $00
    .word   _world_tileset
    .byte   $00

.endproc

; ダンジョン／セルを囲む
;
.proc   NewFrameDungeonCell

    ; 各エリアを壁で囲む
    lda     #<new_dungeon_cell
    sta     NEW_0_FRAME_DUNGEON_CELL_ADDRESS_L
    lda     #>new_dungeon_cell
    sta     NEW_0_FRAME_DUNGEON_CELL_ADDRESS_H
    lda     #$00
    sta     NEW_0_FRAME_DUNGEON_CELL_AREA
@area:
    lda     #$00
    sta     NEW_0_FRAME_DUNGEON_CELL_Y
@area_y:
    lda     #$00
    sta     NEW_0_FRAME_DUNGEON_CELL_X
@area_x:
    lda     NEW_0_FRAME_DUNGEON_CELL_Y
    beq     @wall
    cmp     #(WORLD_AREA_CELL_SIZE_Y - $01)
    beq     @wall
    lda     NEW_0_FRAME_DUNGEON_CELL_X
    beq     @wall
    cmp     #(WORLD_AREA_CELL_SIZE_X - $01)
    beq     @wall
;   jsr     _IocsGetRandomNumber
;   and     #%00110110
;   beq     @damage
    lda     #WORLD_CELL_GROUND
    jmp     :+
;@damage:
;   lda     #WORLD_CELL_POISON
;   jmp     :+
@wall:
    lda     #WORLD_CELL_WALL
:
    ldy     #$00
    sta     (NEW_0_FRAME_DUNGEON_CELL_ADDRESS), y
    inc     NEW_0_FRAME_DUNGEON_CELL_ADDRESS_L
    bne     :+
    inc     NEW_0_FRAME_DUNGEON_CELL_ADDRESS_H
:
    inc     NEW_0_FRAME_DUNGEON_CELL_X
    lda     NEW_0_FRAME_DUNGEON_CELL_X
    cmp     #WORLD_AREA_CELL_SIZE_X
    bne     @area_x
    inc     NEW_0_FRAME_DUNGEON_CELL_Y
    lda     NEW_0_FRAME_DUNGEON_CELL_Y
    cmp     #WORLD_AREA_CELL_SIZE_Y
    bne     @area_y
    inc     NEW_0_FRAME_DUNGEON_CELL_AREA
    lda     NEW_0_FRAME_DUNGEON_CELL_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     @area

    ; 終了
    rts

.endproc

; ダンジョン／セルにダメージ床を配置する
;
.proc   NewDamageDungeonCell

    ; エリアの走査
    lda     #$00
    sta     NEW_0_DAMAGE_DUNGEON_CELL_AREA
@area:
    ldx     NEW_0_DAMAGE_DUNGEON_CELL_AREA
    lda     new_area, x
    and     #WORLD_AREA_INSIDE
    bne     @next
    lda     new_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_SWORD
    beq     @next

    ; ダメージ床を置く
    ldx     NEW_0_DAMAGE_DUNGEON_CELL_AREA
    lda     new_dungeon_cell_address_l, x
    sta     NEW_0_DAMAGE_DUNGEON_CELL_ADDRESS_L
    lda     new_dungeon_cell_address_h, x
    sta     NEW_0_DAMAGE_DUNGEON_CELL_ADDRESS_H
    lda     #<@random_ul
    sta     NEW_0_DAMAGE_DUNGEON_CELL_RANDOM_L
    lda     #>@random_ul
    sta     NEW_0_DAMAGE_DUNGEON_CELL_RANDOM_H
    jsr     @damage
    lda     #<@random_ur
    sta     NEW_0_DAMAGE_DUNGEON_CELL_RANDOM_L
    lda     #>@random_ur
    sta     NEW_0_DAMAGE_DUNGEON_CELL_RANDOM_H
    jsr     @damage
    lda     #<@random_dl
    sta     NEW_0_DAMAGE_DUNGEON_CELL_RANDOM_L
    lda     #>@random_dl
    sta     NEW_0_DAMAGE_DUNGEON_CELL_RANDOM_H
    jsr     @damage
    lda     #<@random_dr
    sta     NEW_0_DAMAGE_DUNGEON_CELL_RANDOM_L
    lda     #>@random_dr
    sta     NEW_0_DAMAGE_DUNGEON_CELL_RANDOM_H
    jsr     @damage

    ; 次のエリアへ
@next:
    inc     NEW_0_DAMAGE_DUNGEON_CELL_AREA
    lda     NEW_0_DAMAGE_DUNGEON_CELL_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     @area

    ; 終了
    rts

    ; ダメージ床を置く
@damage:
    jsr     _IocsGetRandomNumber
    and     #$03
    clc
    adc     #$01
    sta     NEW_0_DAMAGE_DUNGEON_CELL_COUNT
:
    jsr     _IocsGetRandomNumber
    lsr     a
    and     #$1f
    tay
    lda     (NEW_0_DAMAGE_DUNGEON_CELL_RANDOM), y
    tay
    lda     (NEW_0_DAMAGE_DUNGEON_CELL_ADDRESS), y
    cmp     #WORLD_CELL_GROUND
    bne     :+
    lda     #WORLD_CELL_POISON
    sta     (NEW_0_DAMAGE_DUNGEON_CELL_ADDRESS), y
:
    dec     NEW_0_DAMAGE_DUNGEON_CELL_COUNT
    bne     :--
    rts

; ランダムな位置
@random_ul:
    .byte    16,  17,  18,  19,  20,  21,  22
    .byte    31,  32,  33,  34,  35,  36,  37
    .byte    46,  47,  48,  49,  50,  51,  52
    .byte    61,  62,  63,  64,  65,  66,  67
    .byte    76,  77,  78,  79
@random_ur:
    .byte    22,  23,  24,  25,  26,  27,  28
    .byte    37,  48,  39,  40,  41,  42,  43
    .byte    52,  53,  54,  55,  56,  57,  58
    .byte    67,  68,  69,  70,  71,  72,  73
    .byte                   85,  86,  87,  88
@random_dl:
    .byte                   79,  80,  81,  82
    .byte    91,  92,  93,  94,  95,  96,  97
    .byte   106, 107, 108, 109, 110, 111, 112
    .byte   121, 122, 123, 124, 125, 126, 127
    .byte   136, 137, 138, 139, 140, 141, 142
@random_dr:
    .byte    82,  83,  84,  85
    .byte    97,  98,  99, 100, 101, 102, 103
    .byte   112, 113, 114, 115, 116, 117, 118
    .byte   127, 128, 129, 130, 131, 132, 133
    .byte   142, 143, 144, 145, 146, 147, 148

.endproc

; ダンジョン／セルをつなげる
;
.proc   NewLinkDungeonCell

    ; エリアの走査
    lda     #$00
    sta     NEW_0_LINK_DUNGEON_CELL_AREA
@area:
    ldx     NEW_0_LINK_DUNGEON_CELL_AREA
    lda     new_dungeon_cell_address_l, x
    sta     NEW_0_LINK_DUNGEON_CELL_ADDRESS_L
    lda     new_dungeon_cell_address_h, x
    sta     NEW_0_LINK_DUNGEON_CELL_ADDRESS_H

    ; 上をつなげる
@link_up:
    ldx     NEW_0_LINK_DUNGEON_CELL_AREA
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_UP
    beq     @link_down
    ldy     #((WORLD_AREA_CELL_SIZE_X - WORLD_DUNGEON_LINK_EXIT_SIZE) / 2)
    ldx     #WORLD_DUNGEON_LINK_EXIT_SIZE
    lda     #WORLD_CELL_GROUND
:
    sta     (NEW_0_LINK_DUNGEON_CELL_ADDRESS), y
    iny
    dex
    bne     :-

    ; 下をつなげる
@link_down:
    ldx     NEW_0_LINK_DUNGEON_CELL_AREA
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_DOWN
    beq     @link_left
    ldy     #(((WORLD_AREA_CELL_SIZE_X - WORLD_DUNGEON_LINK_EXIT_SIZE) / 2) + ((WORLD_AREA_CELL_SIZE_Y - $01) * WORLD_AREA_CELL_SIZE_X))
    ldx     #WORLD_DUNGEON_LINK_EXIT_SIZE
    lda     #WORLD_CELL_GROUND
:
    sta     (NEW_0_LINK_DUNGEON_CELL_ADDRESS), y
    iny
    dex
    bne     :-

    ; 左をつなげる
@link_left:
    ldx     NEW_0_LINK_DUNGEON_CELL_AREA
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_LEFT
    beq     @link_right
    ldy     #(((WORLD_AREA_CELL_SIZE_Y - WORLD_DUNGEON_LINK_EXIT_SIZE) / 2) * WORLD_AREA_CELL_SIZE_X)
    ldx     #WORLD_DUNGEON_LINK_EXIT_SIZE
:
    lda     #WORLD_CELL_GROUND
    sta     (NEW_0_LINK_DUNGEON_CELL_ADDRESS), y
    tya
    clc
    adc     #WORLD_AREA_CELL_SIZE_X
    tay
    dex
    bne     :-

    ; 右をつなげる
@link_right:
    ldx     NEW_0_LINK_DUNGEON_CELL_AREA
    lda     new_dungeon_link, x
    and     #WORLD_DUNGEON_LINK_RIGHT
    beq     @next
    ldy     #(((WORLD_AREA_CELL_SIZE_Y - WORLD_DUNGEON_LINK_EXIT_SIZE) / 2) * WORLD_AREA_CELL_SIZE_X) + (WORLD_AREA_CELL_SIZE_X - $01)
    ldx     #WORLD_DUNGEON_LINK_EXIT_SIZE
:
    lda     #WORLD_CELL_GROUND
    sta     (NEW_0_LINK_DUNGEON_CELL_ADDRESS), y
    tya
    clc
    adc     #WORLD_AREA_CELL_SIZE_X
    tay
    dex
    bne     :-

    ; 次のエリアへ
@next:
    inc     NEW_0_LINK_DUNGEON_CELL_AREA
    lda     NEW_0_LINK_DUNGEON_CELL_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     @area

    ; 終了
    rts

.endproc

; ダンジョン／セルにイベントを配置する
;
.proc   NewEventDungeonCell

    ; エリアの走査
    lda     #$00
    sta     NEW_0_EVENT_DUNGEON_CELL_AREA
@area:
    ldx     NEW_0_EVENT_DUNGEON_CELL_AREA
    lda     new_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_STAIRS
    beq     @stairs
    cmp     #WORLD_EVENT_SWORD
    beq     @sword
    jmp     @next

    ; 階段
@stairs:
    ldx     NEW_0_EVENT_DUNGEON_CELL_AREA
    lda     new_field_area_cell_y, x
    sta     NEW_0_EVENT_DUNGEON_CELL_Y
    lda     #WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y
    sta     NEW_0_EVENT_DUNGEON_CELL_SIZE_Y
:
    ldx     NEW_0_EVENT_DUNGEON_CELL_AREA
    lda     new_field_area_cell_x, x
    sta     NEW_0_EVENT_DUNGEON_CELL_X
    lda     #WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X
    sta     NEW_0_EVENT_DUNGEON_CELL_SIZE_X
:
    ldx     NEW_0_EVENT_DUNGEON_CELL_X
    ldy     NEW_0_EVENT_DUNGEON_CELL_Y
    jsr     NewGetFieldCell
    cmp     #WORLD_CELL_STAIRS_DOWN
    beq     :+
    inc     NEW_0_EVENT_DUNGEON_CELL_X
    dec     NEW_0_EVENT_DUNGEON_CELL_SIZE_X
    bne     :-
    inc     NEW_0_EVENT_DUNGEON_CELL_Y
    dec     NEW_0_EVENT_DUNGEON_CELL_SIZE_Y
    bne     :--
    jmp     @next
:
    ldx     NEW_0_EVENT_DUNGEON_CELL_AREA
    lda     new_dungeon_cell_address_l, x
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_L
    lda     new_dungeon_cell_address_h, x
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_H
    lda     NEW_0_EVENT_DUNGEON_CELL_X
    sec
    sbc     new_field_area_cell_x, x
    sta     NEW_0_EVENT_DUNGEON_CELL_X
    lda     NEW_0_EVENT_DUNGEON_CELL_Y
    sec
    sbc     new_field_area_cell_y, x
    ldx     #WORLD_AREA_CELL_SIZE_X
    jsr     _IocsAxX
    txa
    clc
    adc     NEW_0_EVENT_DUNGEON_CELL_X
    tay
    lda     #WORLD_CELL_STAIRS_UP
    sta     (NEW_0_EVENT_DUNGEON_CELL_ADDRESS), y
    jmp     @next

    ; 剣／ドラゴン
@sword:
    ldx     NEW_0_EVENT_DUNGEON_CELL_AREA
    lda     new_dungeon_cell_address_l, x
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_L
    lda     new_dungeon_cell_address_h, x
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_H
    lda     #$00
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_Y
    lda     new_field_area_cell_y, x
    sta     NEW_0_EVENT_DUNGEON_CELL_Y
    lda     #WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y
    sta     NEW_0_EVENT_DUNGEON_CELL_SIZE_Y
:
    ldx     NEW_0_EVENT_DUNGEON_CELL_AREA
    lda     new_field_area_cell_x, x
    sta     NEW_0_EVENT_DUNGEON_CELL_X
    lda     #WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X
    sta     NEW_0_EVENT_DUNGEON_CELL_SIZE_X
:
    ldx     NEW_0_EVENT_DUNGEON_CELL_X
    ldy     NEW_0_EVENT_DUNGEON_CELL_Y
    jsr     NewGetFieldCell
    cmp     #WORLD_CELL_PAVE
    beq     :+
    cmp     #WORLD_CELL_SWORD
    bne     :++
:
    ldy     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_Y
    lda     #WORLD_CELL_FLOOR
    sta     (NEW_0_EVENT_DUNGEON_CELL_ADDRESS), y
:
    inc     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_Y
    inc     NEW_0_EVENT_DUNGEON_CELL_X
    dec     NEW_0_EVENT_DUNGEON_CELL_SIZE_X
    bne     :---
    lda     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_Y
    clc
    adc     #(WORLD_AREA_CELL_SIZE_X - WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X)
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_Y
    inc     NEW_0_EVENT_DUNGEON_CELL_Y
    dec     NEW_0_EVENT_DUNGEON_CELL_SIZE_Y
    bne     :----
    ldx     NEW_0_EVENT_DUNGEON_CELL_AREA
    lda     new_dungeon_cell_address_l, x
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_L
    lda     new_dungeon_cell_address_h, x
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_H
    ldy     #(WORLD_AREA_CELL_SIZE_X * (WORLD_AREA_CELL_SIZE_Y - $01) + (WORLD_AREA_CELL_SIZE_X - WORLD_DUNGEON_LINK_EXIT_SIZE) / 2)
    ldx     #WORLD_DUNGEON_LINK_EXIT_SIZE
    lda     #WORLD_CELL_FLOOR
:
    sta     (NEW_0_EVENT_DUNGEON_CELL_ADDRESS), y
    iny
    dex
    bne     :-
@sword_down:
    ldx     NEW_0_EVENT_DUNGEON_CELL_AREA
    ldy     _world_area_down, x
    lda     new_dungeon_cell_address_l, y
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_L
    lda     new_dungeon_cell_address_h, y
    sta     NEW_0_EVENT_DUNGEON_CELL_ADDRESS_H
    ldy     #((WORLD_AREA_CELL_SIZE_X - WORLD_DUNGEON_LINK_EXIT_SIZE) / 2)
    ldx     #WORLD_DUNGEON_LINK_EXIT_SIZE
    lda     #WORLD_CELL_SEAL
:
    sta     (NEW_0_EVENT_DUNGEON_CELL_ADDRESS), y
    iny
    dex
    bne     :-
    jmp     @next

    ; 次のエリアへ
@next:
    inc     NEW_0_EVENT_DUNGEON_CELL_AREA
    lda     NEW_0_EVENT_DUNGEON_CELL_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    beq     :+
    jmp     @area
:

    ; 終了
    rts

.endproc

; ワールドへダンジョン／セルを設定する
;
.proc   NewSetWorldDungeonCell

    ; ワールドへセルを設定
    lda     #<new_dungeon_cell
    sta     NEW_0_SET_DUNGEON_CELL_SRC_ADDRESS_L
    lda     #>new_dungeon_cell
    sta     NEW_0_SET_DUNGEON_CELL_SRC_ADDRESS_H
    lda     #<_world_cell
    sta     NEW_0_SET_DUNGEON_CELL_DST_ADDRESS_L
    lda     #>_world_cell
    sta     NEW_0_SET_DUNGEON_CELL_DST_ADDRESS_H
    lda     #$00
    sta     NEW_0_SET_DUNGEON_CELL_AREA
    tay
:
    ldx     #(WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
:
    lda     (NEW_0_SET_DUNGEON_CELL_DST_ADDRESS), y
    and     #(~WORLD_CELL_DUNGEON_MASK & $ff)
    sta     (NEW_0_SET_DUNGEON_CELL_DST_ADDRESS), y
    lda     (NEW_0_SET_DUNGEON_CELL_SRC_ADDRESS), y
    sec
    sbc     #WORLD_CELL_DUNGEON
    asl     a
    asl     a
    asl     a
    asl     a
    asl     a
    ora     (NEW_0_SET_DUNGEON_CELL_DST_ADDRESS), y
    sta     (NEW_0_SET_DUNGEON_CELL_DST_ADDRESS), y
    inc     NEW_0_SET_DUNGEON_CELL_SRC_ADDRESS_L
    bne     :+
    inc     NEW_0_SET_DUNGEON_CELL_SRC_ADDRESS_H
:
    inc     NEW_0_SET_DUNGEON_CELL_DST_ADDRESS_L
    bne     :+
    inc     NEW_0_SET_DUNGEON_CELL_DST_ADDRESS_H
:
    dex
    bne     :---
    inc     NEW_0_SET_DUNGEON_CELL_AREA
    lda     NEW_0_SET_DUNGEON_CELL_AREA
    cmp     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :----

    ; 終了
    rts

.endproc

; ダンジョン／セルを描画する
;
.proc   NewDrawDungeonCell

    ; IN
    ;   a = エリア

    ; セルの取得
    tax
    lda     new_dungeon_cell_address_l, x
    sta     NEW_0_DRAW_DUNGEON_CELL_ADDRESS_L
    lda     new_dungeon_cell_address_h, x
    sta     NEW_0_DRAW_DUNGEON_CELL_ADDRESS_H

    ; セルの描画
    lda     #$00
    sta     NEW_0_DRAW_DUNGEON_CELL_INDEX
    sta     NEW_0_DRAW_DUNGEON_CELL_DRAW_Y
:
    lda     #$00
    sta     NEW_0_DRAW_DUNGEON_CELL_DRAW_X
:
    ldy     NEW_0_DRAW_DUNGEON_CELL_INDEX
    lda     (NEW_0_DRAW_DUNGEON_CELL_ADDRESS), y
    ldx     NEW_0_DRAW_DUNGEON_CELL_DRAW_X
    ldy     NEW_0_DRAW_DUNGEON_CELL_DRAW_Y
    jsr     _WorldDrawCell
    inc     NEW_0_DRAW_DUNGEON_CELL_INDEX
    inc     NEW_0_DRAW_DUNGEON_CELL_DRAW_X
    inc     NEW_0_DRAW_DUNGEON_CELL_DRAW_X
    lda     NEW_0_DRAW_DUNGEON_CELL_DRAW_X
    cmp     #(WORLD_AREA_CELL_SIZE_X * $02)
    bne     :-
    inc     NEW_0_DRAW_DUNGEON_CELL_DRAW_Y
    inc     NEW_0_DRAW_DUNGEON_CELL_DRAW_Y
    lda     NEW_0_DRAW_DUNGEON_CELL_DRAW_Y
    cmp     #(WORLD_AREA_CELL_SIZE_Y * $02)
    bne     :--

    ; 終了
    rts

.endproc

; エリアの情報
;

; エリア
new_area:

    .res    WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y

; フィールドの情報
;

; フィールド／エリアのブロック位置
new_field_area_block:

    .byte   11, 13, 15, 17, 19
    .byte   31, 33, 35, 37, 39
    .byte   51, 53, 55, 57, 59
    .byte   71, 73, 75, 77, 79
    .byte   91, 93, 95, 97, 99

; フィールド／エリアのブロックのセル位置
new_field_area_block_cell_x:

    .byte    7, 21, 35, 49, 63
    .byte    7, 21, 35, 49, 63
    .byte    7, 21, 35, 49, 63
    .byte    7, 21, 35, 49, 63
    .byte    7, 21, 35, 49, 63

new_field_area_block_cell_y:

    .byte    5,  5,  5,  5,  5
    .byte   15, 15, 15, 15, 15
    .byte   25, 25, 25, 25, 25
    .byte   35, 35, 35, 35, 35
    .byte   45, 45, 45, 45, 45

; フィールド／エリアのセル位置
new_field_area_cell_x:

    .byte    0, 14, 28, 42, 56
    .byte    0, 14, 28, 42, 56
    .byte    0, 14, 28, 42, 56
    .byte    0, 14, 28, 42, 56
    .byte    0, 14, 28, 42, 56

new_field_area_cell_y:

    .byte    0,  0,  0,  0,  0
    .byte   10, 10, 10, 10, 10
    .byte   20, 20, 20, 20, 20
    .byte   30, 30, 30, 30, 30
    .byte   40, 40, 40, 40, 40

; フィールド／ブロック
new_field_block:

    .res    WORLD_FIELD_BLOCK_SIZE_X * WORLD_FIELD_BLOCK_SIZE_Y

; フィールド／ブロックの上下左右
new_field_block_up:

    .byte   90, 91, 92, 93, 94, 95, 96, 97, 98, 99
    .byte    0,  1,  2,  3,  4,  5,  6,  7,  8,  9
    .byte   10, 11, 12, 13, 14, 15, 16, 17, 18, 19
    .byte   20, 21, 22, 23, 24, 25, 26, 27, 28, 29
    .byte   30, 31, 32, 33, 34, 35, 36, 37, 38, 39
    .byte   40, 41, 42, 43, 44, 45, 46, 47, 48, 49
    .byte   50, 51, 52, 53, 54, 55, 56, 57, 58, 59
    .byte   60, 61, 62, 63, 64, 65, 66, 67, 68, 69
    .byte   70, 71, 72, 73, 74, 75, 76, 77, 78, 79
    .byte   80, 81, 82, 83, 84, 85, 86, 87, 88, 89

new_field_block_down:

    .byte   10, 11, 12, 13, 14, 15, 16, 17, 18, 19
    .byte   20, 21, 22, 23, 24, 25, 26, 27, 28, 29
    .byte   30, 31, 32, 33, 34, 35, 36, 37, 38, 39
    .byte   40, 41, 42, 43, 44, 45, 46, 47, 48, 49
    .byte   50, 51, 52, 53, 54, 55, 56, 57, 58, 59
    .byte   60, 61, 62, 63, 64, 65, 66, 67, 68, 69
    .byte   70, 71, 72, 73, 74, 75, 76, 77, 78, 79
    .byte   80, 81, 82, 83, 84, 85, 86, 87, 88, 89
    .byte   90, 91, 92, 93, 94, 95, 96, 97, 98, 99
    .byte    0,  1,  2,  3,  4,  5,  6,  7,  8,  9

new_field_block_left:

    .byte    9,  0,  1,  2,  3,  4,  5,  6,  7,  8
    .byte   19, 10, 11, 12, 13, 14, 15, 16, 17, 18
    .byte   29, 20, 21, 22, 23, 24, 25, 26, 27, 28
    .byte   39, 30, 31, 32, 33, 34, 35, 36, 37, 38
    .byte   49, 40, 41, 42, 43, 44, 45, 46, 47, 48
    .byte   59, 50, 51, 52, 53, 54, 55, 56, 57, 58
    .byte   69, 60, 61, 62, 63, 64, 65, 66, 67, 68
    .byte   79, 70, 71, 72, 73, 74, 75, 76, 77, 78
    .byte   89, 80, 81, 82, 83, 84, 85, 86, 87, 88
    .byte   99, 90, 91, 92, 93, 94, 95, 96, 97, 98

new_field_block_right:

    .byte    1,  2,  3,  4,  5,  6,  7,  8,  9,  0
    .byte   11, 12, 13, 14, 15, 16, 17, 18, 19, 10
    .byte   21, 22, 23, 24, 25, 26, 27, 28, 29, 20
    .byte   31, 32, 33, 34, 35, 36, 37, 38, 39, 30
    .byte   41, 42, 43, 44, 45, 46, 47, 48, 49, 40
    .byte   51, 52, 53, 54, 55, 56, 57, 58, 59, 50
    .byte   61, 62, 63, 64, 65, 66, 67, 68, 69, 60
    .byte   71, 72, 73, 74, 75, 76, 77, 78, 79, 70
    .byte   81, 82, 83, 84, 85, 86, 87, 88, 89, 80
    .byte   91, 92, 93, 94, 95, 96, 97, 98, 99, 90

; フィールド／ブロックのセル位置
new_field_block_cell_x:

    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63
    .byte    0,  7, 14, 21, 28, 35, 42, 49, 56, 63

new_field_block_cell_y:

    .byte    0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte    5,  5,  5,  5,  5,  5,  5,  5,  5,  5
    .byte   10, 10, 10, 10, 10, 10, 10, 10, 10, 10
    .byte   15, 15, 15, 15, 15, 15, 15, 15, 15, 15
    .byte   20, 20, 20, 20, 20, 20, 20, 20, 20, 20
    .byte   25, 25, 25, 25, 25, 25, 25, 25, 25, 25
    .byte   30, 30, 30, 30, 30, 30, 30, 30, 30, 30
    .byte   35, 35, 35, 35, 35, 35, 35, 35, 35, 35
    .byte   40, 40, 40, 40, 40, 40, 40, 40, 40, 40
    .byte   45, 45, 45, 45, 45, 45, 45, 45, 45, 45

; フィールド／セル
new_field_cell:

    .res    WORLD_FIELD_CELL_SIZE_X * WORLD_FIELD_CELL_SIZE_Y

; ダンジョンの情報
;

; ダンジョン／リンク
new_dungeon_link:

    .res    WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y

; ダンジョン／セル
new_dungeon_cell:

    .res    WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y

new_dungeon_cell_address_l:

    .byte   <(new_dungeon_cell +  0 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  1 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  2 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  3 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  4 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  5 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  6 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  7 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  8 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell +  9 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 10 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 11 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 12 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 13 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 14 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 15 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 16 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 17 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 18 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 19 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 20 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 21 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 22 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 23 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(new_dungeon_cell + 24 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)

new_dungeon_cell_address_h:

    .byte   >(new_dungeon_cell +  0 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  1 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  2 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  3 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  4 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  5 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  6 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  7 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  8 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell +  9 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 10 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 11 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 12 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 13 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 14 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 15 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 16 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 17 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 18 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 19 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 20 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 21 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 22 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 23 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(new_dungeon_cell + 24 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)


; データの定義
;
.segment    "BSS"

; ニューゲームの情報
;
new:

    .tag    New

