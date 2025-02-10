; world.s - ワールド
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


; コードの定義
;
.segment    "BOOT"

; ワールドを初期化する
;
.global _WorldInitialize
.proc   _WorldInitialize

    ; WORK
    ;   WORLD_0_WORK_0..3

    ; ワールドの初期化
    lda     #<world_file_head
    sta     WORLD_0_WORK_0
    lda     #>world_file_head
    sta     WORLD_0_WORK_1
    lda     #<(world_file_tail - world_file_head)
    sta     WORLD_0_WORK_2
    lda     #>(world_file_tail - world_file_head)
    sta     WORLD_0_WORK_3
:
    lda     #$00
    tay
    sta     (WORLD_0_WORK_0), y
    inc     WORLD_0_WORK_0
    bne     :+
    inc     WORLD_0_WORK_1
:
    lda     WORLD_0_WORK_2
    bne     :+
    dec     WORLD_0_WORK_2
    dec     WORLD_0_WORK_3
    jmp     :--
:
    dec     WORLD_0_WORK_2
    lda     WORLD_0_WORK_2
    ora     WORLD_0_WORK_3
    bne     :---

    ; 終了
    rts

.endproc

; ワールドを読み込む
;
.global _WorldLoad
.proc   _WorldLoad

    ; バイナリの読み込み
    ldx     #<@load_arg
    lda     #>@load_arg
    jsr     _IocsBload

    ; 終了
    rts

; 読み込みの引数
@load_arg:
    .word   world_file_name
    .word   world_file_head
    .word   world_file_tail - world_file_head

.endproc

; ワールドを書き込む
;
.global _WorldSave
.proc   _WorldSave

    ; バイナリの書き込み
    ldx     #<@save_arg
    lda     #>@save_arg
    jsr     _IocsBsave

    ; 終了
    rts

; 書き込みの引数
@save_arg:
    .word   world_file_name
    .word   world_file_head
    .word   world_file_tail - world_file_head

.endproc

; ワールドの存在を確認する
;
.global _WorldAccess
.proc   _WorldAccess

    ; OUT
    ;   a = 0...ファイルはある / else...ファイルはない

    ; ファイルの存在確認
    ldx     #<@access_arg
    lda     #>@access_arg
    jsr     _IocsAccess

    ; 終了
    rts

; 存在確認の引数
@access_arg:
    .word   world_file_name

.endproc

; 指定されたイベントのエリアを取得する
;
.global _WorldGetEventArea
.proc   _WorldGetEventArea

    ; IN
    ;   a = イベント
    ; OUT
    ;   a = エリア
    ; WORK
    ;   WORLD_0_WORK_0

    ; エリアの保存
    sta     WORLD_0_WORK_0

    ; エリアの検索
    ldx     #$00
:
    lda     _world_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     WORLD_0_WORK_0
    beq     :+
    inx
    cpx     #(WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y)
    bne     :-
    ldx     #$00
:
    txa

    ; 終了
    rts

.endproc

; 指定されたフィールド／エリアのセルを複製する
;
.global _WorldLDuplicateFieldAreaCell
.proc   _WorldLDuplicateFieldAreaCell

    ; IN
    ;   a = エリア
    ; WORK
    ;   WORLD_0_WORK_0..1

    ; エリアの取得
    tax
    lda     _world_cell_address_l, x
    sta     WORLD_0_WORK_0
    lda     _world_cell_address_h, x
    sta     WORLD_0_WORK_1

    ; セルの複製
    ldy     #$00
:
    lda     (WORLD_0_WORK_0), y
    and     #WORLD_CELL_FIELD_MASK
    sta     _world_area_cell, y
    iny
    cpy     #(WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    bne     :-

    ; 終了
    rts

.endproc

; 指定されたダンジョン／エリアのセルを複製する
;
.global _WorldLDuplicateDungeonAreaCell
.proc   _WorldLDuplicateDungeonAreaCell

    ; IN
    ;   a = エリア
    ; WORK
    ;   WORLD_0_WORK_0..1

    ; エリアの取得
    tax
    lda     _world_cell_address_l, x
    sta     WORLD_0_WORK_0
    lda     _world_cell_address_h, x
    sta     WORLD_0_WORK_1

    ; セルの複製
    ldy     #$00
:
    lda     (WORLD_0_WORK_0), y
    and     #WORLD_CELL_DUNGEON_MASK
    lsr     a
    lsr     a
    lsr     a
    lsr     a
    lsr     a
    clc
    adc     #WORLD_CELL_DUNGEON
    sta     _world_area_cell, y
    iny
    cpy     #(WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    bne     :-

    ; 終了
    rts

.endproc

; エリアにセルを設定する
;
.global _WorldSetAreaCell
.proc   _WorldSetAreaCell

    ; IN
    ;   x = セルの X 位置
    ;   y = セルの Y 位置
    ;   a = セル
    ; WORK
    ;   WORLD_0_WORK_0..3

    ; 位置の保存
    stx     WORLD_0_WORK_0
    sty     WORLD_0_WORK_1

    ; セル位置の取得
    pha
    lda     _world_area_cell_y_address_l, y
    sta     WORLD_0_WORK_2
    lda     _world_area_cell_y_address_h, y
    sta     WORLD_0_WORK_3

    ; セルの設定
    pla
    ldy     WORLD_0_WORK_0
    sta     (WORLD_0_WORK_2), y

    ; タイルの設定
    ldx     WORLD_0_WORK_0
    ldy     WORLD_0_WORK_1
    jsr     _WorldSetAreaCellTile

    ; 終了
    rts

.endproc

; エリアにセルのタイルを設定する
;
.global _WorldSetAreaCellTile
.proc   _WorldSetAreaCellTile

    ; IN
    ;   x = セルの X 位置
    ;   y = セルの Y 位置
    ; WORK
    ;   WORLD_0_WORK_0..3

    ; セル位置の取得
    lda     _world_area_cell_y_address_l, y
    sta     WORLD_0_WORK_0
    lda     _world_area_cell_y_address_h, y
    sta     WORLD_0_WORK_1

    ; タイル位置の取得
    lda     _world_area_tile_cell_y_address_l, y
    sta     WORLD_0_WORK_2
    lda     _world_area_tile_cell_y_address_h, y
    sta     WORLD_0_WORK_3

    ; セルの取得
    txa
    tay
    lda     (WORLD_0_WORK_0), y
    sta     WORLD_0_WORK_0

    ; タイルの X 位置の取得
    txa
    asl     a
    tay

    ; タイルの設定
    ldx     WORLD_0_WORK_0
    lda     _world_cell_tile_up_left, x
    sta     (WORLD_0_WORK_2), y
    iny
    lda     _world_cell_tile_up_right, x
    sta     (WORLD_0_WORK_2), y
    tya
    clc
    adc     #(WORLD_AREA_TILE_SIZE_X - $01)
    tay
    lda     _world_cell_tile_down_left, x
    sta     (WORLD_0_WORK_2), y
    iny
    lda     _world_cell_tile_down_right, x
    sta     (WORLD_0_WORK_2), y

    ; 終了
    rts

.endproc

; エリアのセルからタイルを展開する
;
.global _WorldLayoutAreaCellTile
.proc   _WorldLayoutAreaCellTile

    ; WORK
    ;   WORLD_0_WORK_0..3

    ; セルの展開
    lda     #$00
    sta     WORLD_0_LAYOUT_AERA_Y
:
    lda     #$00
    sta     WORLD_0_LAYOUT_AERA_X
:
    ldx     WORLD_0_LAYOUT_AERA_X
    ldy     WORLD_0_LAYOUT_AERA_Y
    jsr     _WorldSetAreaCellTile
    inc     WORLD_0_LAYOUT_AERA_X
    lda     WORLD_0_LAYOUT_AERA_X
    cmp     #WORLD_AREA_CELL_SIZE_X
    bne     :-
    inc     WORLD_0_LAYOUT_AERA_Y
    lda     WORLD_0_LAYOUT_AERA_Y
    cmp     #WORLD_AREA_CELL_SIZE_Y
    bne     :--

    ; 終了
    rts

.endproc

; エリアのセルを取得する
;
.global _WorldGetAreaCell
.proc   _WorldGetAreaCell

    ; IN
    ;   x = セルの X 位置
    ;   y = セルの Y 位置
    ; OUT
    ;   a = セル
    ; WORK
    ;   WORLD_0_WORK_0..1

    ; セル位置の取得
    lda     _world_area_cell_y_address_l, y
    sta     WORLD_0_WORK_0
    lda     _world_area_cell_y_address_h, y
    sta     WORLD_0_WORK_1

    ; セルの取得
    txa
    tay
    lda     (WORLD_0_WORK_0), y

    ; 終了
    rts

.endproc

; エリアのタイルを取得する
;
.global _WorldGetAreaTile
.proc   _WorldGetAreaTile

    ; IN
    ;   x = タイルの X 位置
    ;   y = タイルの Y 位置
    ; OUT
    ;   a = タイル
    ; WORK
    ;   WORLD_0_WORK_0..1

    ; タイル位置の取得
    lda     _world_area_tile_y_address_l, y
    sta     WORLD_0_WORK_0
    lda     _world_area_tile_y_address_h, y
    sta     WORLD_0_WORK_1

    ; タイルの取得
    txa
    tay
    lda     (WORLD_0_WORK_0), y

    ; 終了
    rts

.endproc

; エリアのタイルの属性を取得する
;
.global _WorldGetAreaTileAttribute
.proc   _WorldGetAreaTileAttribute

    ; IN
    ;   x = タイルの X 位置
    ;   y = タイルの Y 位置
    ; OUT
    ;   a = タイルの属性
    ; WORK
    ;   WORLD_0_WORK_0..1

    ; タイルの取得
    jsr     _WorldGetAreaTile

    ; 属性の取得
    tax
    lda     _world_tile_attribute, x

    ; 終了
    rts

.endproc

; エリアの舗装に宝箱を設置する
;
.global _WorldPlaceBox
.proc   _WorldPlaceBox

    ; IN
    ;   a = $00...描画しない / else...描画する
    ; WORK
    ;   WORLD_0_WORK_0..3

    ; 描画の保存
    tay

    ; 舗装の取得
    ldx     #$00
    stx     WORLD_0_WORK_0
    stx     WORLD_0_WORK_1
:
    lda     _world_area_cell, x
    cmp     #WORLD_CELL_PAVE
    beq     :++
    inc     WORLD_0_WORK_0
    lda     WORLD_0_WORK_0
    cmp     #WORLD_AREA_CELL_SIZE_X
    bne     :+
    lda     #$00
    sta     WORLD_0_WORK_0
    inc     WORLD_0_WORK_1
:
    inx
    cpx     #(WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    bne     :--
    jmp     @end
:

    ; 舗装を宝箱に変える
    tya
    pha
    lda     #WORLD_CELL_BOX
    sta     _world_area_cell, x
    lda     WORLD_0_WORK_0
    pha
    tax
    lda     WORLD_0_WORK_1
    pha
    tay
    jsr     _WorldSetAreaCellTile

    ; 舗装の描画
    pla
    tay
    pla
    tax
    pla
    beq     :+
    jsr     _WorldDrawAreaCell
:

    ; 終了
@end:
    rts

.endproc

; エリアの宝箱を削除する
;
.global _WorldRemoveBox
.proc   _WorldRemoveBox

    ; IN
    ;   a = $00...描画しない / else...描画する
    ; WORK
    ;   WORLD_0_WORK_0..3

    ; 描画の保存
    tay

    ; 宝箱の取得
    ldx     #$00
    stx     WORLD_0_WORK_0
    stx     WORLD_0_WORK_1
:
    lda     _world_area_cell, x
    cmp     #WORLD_CELL_BOX
    beq     :++
    cmp     #WORLD_CELL_SWORD
    beq     :++
    inc     WORLD_0_WORK_0
    lda     WORLD_0_WORK_0
    cmp     #WORLD_AREA_CELL_SIZE_X
    bne     :+
    lda     #$00
    sta     WORLD_0_WORK_0
    inc     WORLD_0_WORK_1
:
    inx
    cpx     #(WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    bne     :--
    jmp     @end
:

    ; 宝箱を舗装に変える
    tya
    pha
    lda     #WORLD_CELL_PAVE
    sta     _world_area_cell, x
    lda     WORLD_0_WORK_0
    pha
    tax
    lda     WORLD_0_WORK_1
    pha
    tay
    jsr     _WorldSetAreaCellTile

    ; 舗装の描画
    pla
    tay
    pla
    tax
    pla
    beq     :+
    jsr     _WorldDrawAreaCell
:

    ; 終了
@end:
    rts

.endproc

; エリアの封印を解く
;
.global _WorldUnseal
.proc   _WorldUnseal

    ; WORK
    ;   WORLD_0_WORK_0..3

    ; 封印の走査／最上段のみ検索
    ldx     #$00
:
    lda     _world_area_cell, x
    cmp     #WORLD_CELL_SEAL
    bne     :+
    lda     #WORLD_CELL_PAVE
    sta     _world_area_cell, x
    txa
    pha
    ldy     #$00
    jsr     _WorldSetAreaCellTile
    pla
    tax
:
    inx
    cpx     #WORLD_AREA_CELL_SIZE_X
    bne     :--

    ; 終了　
    rts

.endproc

; エリアを描画する
;
.global _WorldDrawArea
.proc   _WorldDrawArea

    ; IN
    ;   a = 描画の種類
    ; WORK
    ;   WORLD_0_WORK_0..1

    ; 種類別の描画
    cmp     #WORLD_DRAW_CENTER
    beq     @center
    cmp     #WORLD_DRAW_UP_DOWN
    beq     @up_down
    cmp     #WORLD_DRAW_DOWN_UP
    beq     @down_up
    cmp     #WORLD_DRAW_LEFT_RIGHT
    beq     @left_right
    jmp     @right_left

    ; 中央から上下に描画
@center:
    ldy     #(WORLD_AREA_TILE_SIZE_Y / 2 - 1)
    ldx     #$01
@center_y:
    txa
    pha
    ldx     #$00
@center_x:
    txa
    pha
    tya
    pha
    jsr     _WorldDrawAreaTile
    pla
    tay
    pla
    tax
    inx
    cpx     #WORLD_AREA_TILE_SIZE_X
    bne     @center_x
    pla
    tax
    inx
    sty     WORLD_0_WORK_0
    sta     WORLD_0_WORK_1
    and     #$01
    bne     :+
    lda     WORLD_0_WORK_1
    eor     #$ff
    clc
    adc     #$01
    jmp     :++
:
    lda     WORLD_0_WORK_1
:
    clc
    adc     WORLD_0_WORK_0
    tay
    bpl     @center_y
    rts

    ; 上から下に描画
@up_down:
    ldy     #$00
@up_down_y:
    ldx     #$00
@up_down_x:
    txa
    pha
    tya
    pha
    jsr     _WorldDrawAreaTile
    pla
    tay
    pla
    tax
    inx
    cpx     #WORLD_AREA_TILE_SIZE_X
    bne     @up_down_x
    iny
    cpy     #WORLD_AREA_TILE_SIZE_Y
    bne     @up_down_y
    rts

    ; 下から上に描画
@down_up:
    ldy     #(WORLD_AREA_TILE_SIZE_Y - $01)
@down_up_y:
    ldx     #$00
@down_up_x:
    txa
    pha
    tya
    pha
    jsr     _WorldDrawAreaTile
    pla
    tay
    pla
    tax
    inx
    cpx     #WORLD_AREA_TILE_SIZE_X
    bne     @down_up_x
    dey
    bpl     @down_up_y
    rts

    ; 左から右に描画
@left_right:
    ldx     #$00
@left_right_x:
    ldy     #$00
@left_right_y:
    txa
    pha
    tya
    pha
    jsr     _WorldDrawAreaTile
    pla
    tay
    pla
    tax
    iny
    cpy     #WORLD_AREA_TILE_SIZE_Y
    bne     @left_right_y
    inx
    cpx     #WORLD_AREA_TILE_SIZE_X
    bne     @left_right_x
    rts

    ; 右から左に描画
@right_left:
    ldx     #(WORLD_AREA_TILE_SIZE_X - $01)
@right_left_x:
    ldy     #$00
@right_left_y:
    txa
    pha
    tya
    pha
    jsr     _WorldDrawAreaTile
    pla
    tay
    pla
    tax
    iny
    cpy     #WORLD_AREA_TILE_SIZE_Y
    bne     @right_left_y
    dex
    bpl     @right_left_x
    rts

.endproc

; エリアのセルを描画する
;
.global _WorldDrawAreaCell
.proc   _WorldDrawAreaCell

    ; IN
    ;   x = セルの X 位置
    ;   y = セルの Y 位置
    ; WORK
    ;   WORLD_0_WORK_0..3

    ; タイル位置の取得
    stx     WORLD_0_WORK_2
    asl     WORLD_0_WORK_2
    sty     WORLD_0_WORK_3
    asl     WORLD_0_WORK_3

    ; タイルの描画
    ldx     WORLD_0_WORK_2
    ldy     WORLD_0_WORK_3
    jsr     _WorldDrawAreaTile
    ldx     WORLD_0_WORK_2
    inx
    ldy     WORLD_0_WORK_3
    jsr     _WorldDrawAreaTile
    ldx     WORLD_0_WORK_2
    ldy     WORLD_0_WORK_3
    iny
    jsr     _WorldDrawAreaTile
    ldx     WORLD_0_WORK_2
    inx
    ldy     WORLD_0_WORK_3
    iny
    jsr     _WorldDrawAreaTile

    ; 終了
    rts

.endproc

; エリアのタイルを描画する
;
.global _WorldDrawAreaTile
.proc   _WorldDrawAreaTile

    ; IN
    ;   x = タイルの X 位置
    ;   y = タイルの Y 位置
    ; WORK
    ;   WORLD_0_WORK_0..1

    ; 位置の確認
    cpx     #WORLD_AREA_TILE_SIZE_X
    bcs     @end
    cpy     #WORLD_AREA_TILE_SIZE_Y
    bcs     @end

    ; 位置の取得
;   txa
;   clc
;   adc     #WORLD_DRAW_X
;   sta     @draw_arg + $0000
    stx     @draw_arg + $0000
    tya
    clc
    adc     #WORLD_DRAW_Y
    sta     @draw_arg + $0001

    ; タイルの取得
    lda     _world_area_light
    beq     :+
    jsr     _WorldGetAreaTile
    jmp     :++
:
    lda     #WORLD_TILE_NULL_R
:
    sta     @draw_arg + $0004

    ; タイルの描画
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; 終了
@end:
    rts

; 描画の引数
@draw_arg:
    .byte   $00, $00
    .word   _world_tileset
    .byte   $00

.endproc

; セルを描画する
;
.global _WorldDrawCell
.proc   _WorldDrawCell

    ; IN
    ;   x = X 位置
    ;   y = Y 位置
    ;   a = セル

    ; 位置の設定
    stx     @draw_arg + $0000
    sty     @draw_arg + $0001

    ; セルの保持
    sta     @cell

    ; セル左上のタイルの描画
    tax
    lda     _world_cell_tile_up_left, x
    sta     @draw_arg + $0004
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; セル右上のタイルの描画
    inc     @draw_arg + $0000
    ldx     @cell
    lda     _world_cell_tile_up_right, x
    sta     @draw_arg + $0004
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; セル左下のタイルの描画
    dec     @draw_arg + $0000
    inc     @draw_arg + $0001
    ldx     @cell
    lda     _world_cell_tile_down_left, x
    sta     @draw_arg + $0004
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; セル右下のタイルの描画
    inc     @draw_arg + $0000
    ldx     @cell
    lda     _world_cell_tile_down_right, x
    sta     @draw_arg + $0004
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern

    ; 終了
    rts

; セル
@cell:
    .byte   $00

; 描画の引数
@draw_arg:
    .byte   $00, $00
    .word   _world_tileset
    .byte   $00

.endproc

; エリアを消去する
;
.global _WorldEraseArea
.proc   _WorldEraseArea

    ; エリアの消去
    lda     #$01
    sta     @draw_arg + $0001
    ldy     #(WORLD_AREA_TILE_SIZE_Y - $01)
@erase_y:
    tya
    pha
    lda     #$00
    sta     @draw_arg + $0000
@erase_x:
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDraw7x8Pattern
    inc     @draw_arg + $0000
    lda     @draw_arg + $0000
    cmp     #WORLD_AREA_TILE_SIZE_X
    bne     @erase_x
    lda     #IOCS_BEEP_L256
    jsr     _IocsBeepRest
    pla
    tay
    tax
    and     #$01
    bne     :+
    txa
    eor     #$ff
    clc
    adc     #$01
    jmp     :++
:
    txa
:
    clc
    adc     @draw_arg + $0001
    sta     @draw_arg + $0001
    dey
    bpl     @erase_y
    rts

; 描画の引数
@draw_arg:
    .byte   $00, $00
    .word   _world_tileset
    .byte   WORLD_TILE_NULL_R

.endproc

; エリア
;

; エリアの上下左右
.global _world_area_up
_world_area_up:

    .byte   20, 21, 22, 23, 24
    .byte    0,  1,  2,  3,  4
    .byte    5,  6,  7,  8,  9
    .byte   10, 11, 12, 13, 14
    .byte   15, 16, 17, 18, 19

.global _world_area_down
_world_area_down:

    .byte    5,  6,  7,  8,  9
    .byte   10, 11, 12, 13, 14
    .byte   15, 16, 17, 18, 19
    .byte   20, 21, 22, 23, 24
    .byte    0,  1,  2,  3,  4

.global _world_area_left
_world_area_left:

    .byte    4,  0,  1,  2,  3
    .byte    9,  5,  6,  7,  8
    .byte   14, 10, 11, 12, 13
    .byte   19, 15, 16, 17, 18
    .byte   24, 20, 21, 22, 23

.global _world_area_right
_world_area_right:

    .byte    1,  2,  3,  4,  0
    .byte    6,  7,  8,  9,  5
    .byte   11, 12, 13, 14, 10
    .byte   16, 17, 18, 19, 15
    .byte   21, 22, 23, 24, 20

; エリア／セルの参照
.global _world_area_cell_y_address_l
_world_area_cell_y_address_l:

    .byte   <(_world_area_cell +  0 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  1 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  2 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  3 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  4 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  5 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  6 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  7 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  8 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell +  9 * WORLD_AREA_CELL_SIZE_X)
    .byte   <(_world_area_cell + 10 * WORLD_AREA_CELL_SIZE_X)

.global _world_area_cell_y_address_h
_world_area_cell_y_address_h:

    .byte   >(_world_area_cell +  0 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  1 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  2 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  3 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  4 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  5 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  6 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  7 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  8 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell +  9 * WORLD_AREA_CELL_SIZE_X)
    .byte   >(_world_area_cell + 10 * WORLD_AREA_CELL_SIZE_X)

; エリア／タイルの参照
.global _world_area_tile_cell_y_address_l
_world_area_tile_cell_y_address_l:

    .byte   <(_world_area_tile +  0 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  2 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  4 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  6 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  8 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 10 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 12 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 14 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 16 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 18 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 20 * WORLD_AREA_TILE_SIZE_X)

.global _world_area_tile_cell_y_address_h
_world_area_tile_cell_y_address_h:

    .byte   >(_world_area_tile +  0 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  2 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  4 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  6 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  8 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 10 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 12 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 14 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 16 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 18 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 20 * WORLD_AREA_TILE_SIZE_X)

.global _world_area_tile_y_address_l
_world_area_tile_y_address_l:

    .byte   <(_world_area_tile +  0 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  1 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  2 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  3 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  4 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  5 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  6 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  7 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  8 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile +  9 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 10 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 11 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 12 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 13 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 14 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 15 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 16 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 17 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 18 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 19 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 20 * WORLD_AREA_TILE_SIZE_X)
    .byte   <(_world_area_tile + 21 * WORLD_AREA_TILE_SIZE_X)

.global _world_area_tile_y_address_h
_world_area_tile_y_address_h:

    .byte   >(_world_area_tile +  0 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  1 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  2 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  3 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  4 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  5 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  6 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  7 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  8 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile +  9 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 10 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 11 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 12 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 13 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 14 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 15 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 16 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 17 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 18 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 19 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 20 * WORLD_AREA_TILE_SIZE_X)
    .byte   >(_world_area_tile + 21 * WORLD_AREA_TILE_SIZE_X)

; セル
;
.global _world_cell_address_l
_world_cell_address_l:

    .byte   <(_world_cell +  0 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  1 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  2 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  3 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  4 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  5 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  6 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  7 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  8 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell +  9 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 10 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 11 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 12 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 13 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 14 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 15 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 16 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 17 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 18 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 19 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 20 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 21 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 22 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 23 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   <(_world_cell + 24 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)

.global _world_cell_address_h
_world_cell_address_h:

    .byte   >(_world_cell +  0 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  1 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  2 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  3 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  4 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  5 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  6 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  7 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  8 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell +  9 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 10 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 11 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 12 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 13 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 14 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 15 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 16 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 17 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 18 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 19 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 20 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 21 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 22 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 23 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)
    .byte   >(_world_cell + 24 * WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)

.global _world_cell_attribute
_world_cell_attribute:

    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_GRASS
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_DIRT
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_SAND
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_PAVE
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_FOREST
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_FOREST_THICK_U
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_FOREST_THICK_D
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_FOREST_THICK_UD
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_TREE
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_ROCK
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_CACTUS
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_STAIRS_DOWN
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_BOX
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_SWORD
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_0E
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_0F
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_0000
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_1000
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_0100
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_1100
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_0010
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_1010
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_0110
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_1110
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_0001
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_1001
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_0101
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_1101
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_0011
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_1011
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_0111
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WATER_1111
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_GROUND
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_POISON
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_WALL
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_STAIRS_UP
    .byte   WORLD_CELL_ATTRIBUTE_NULL                                   ; WORLD_CELL_SEAL
    .byte   WORLD_CELL_ATTRIBUTE_SPAWN                                  ; WORLD_CELL_FLOOR

; セル／タイル
;
.global _world_cell_tile_up_left
_world_cell_tile_up_left:

    .byte   WORLD_TILE_GRASS_L          ; WORLD_CELL_GRASS
    .byte   WORLD_TILE_DIRT_L           ; WORLD_CELL_DIRT
    .byte   WORLD_TILE_SAND_L           ; WORLD_CELL_SAND
    .byte   WORLD_TILE_PAVE_L           ; WORLD_CELL_PAVE
    .byte   WORLD_TILE_FOREST_UL        ; WORLD_CELL_FOREST
    .byte   WORLD_TILE_FOREST_THICK_L   ; WORLD_CELL_FOREST_THICK_U
    .byte   WORLD_TILE_FOREST_UL        ; WORLD_CELL_FOREST_THICK_D
    .byte   WORLD_TILE_FOREST_THICK_L   ; WORLD_CELL_FOREST_THICK_UD
    .byte   WORLD_TILE_TREE_UL          ; WORLD_CELL_TREE
    .byte   WORLD_TILE_ROCK_UL          ; WORLD_CELL_ROCK
    .byte   WORLD_TILE_CACTUS_UL        ; WORLD_CELL_CACTUS
    .byte   WORLD_TILE_STAIRS_DOWN_UL   ; WORLD_CELL_STAIRS_DOWN
    .byte   WORLD_TILE_BOX_UL           ; WORLD_CELL_BOX
    .byte   WORLD_TILE_SWORD_UL         ; WORLD_CELL_SWORD
    .byte   $00
    .byte   $00
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0000
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1000
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0100
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1100
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0010
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1010
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0110
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1110
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0001
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1001
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0101
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1101
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0011
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1011
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0111
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1111
    .byte   WORLD_TILE_GROUND_L         ; WORLD_CELL_GROUND
    .byte   WORLD_TILE_POISON_L         ; WORLD_CELL_POISON
    .byte   WORLD_TILE_WALL_UL          ; WORLD_CELL_WALL
    .byte   WORLD_TILE_STAIRS_UP_UL     ; WORLD_CELL_STAIRS_UP
    .byte   WORLD_TILE_SEAL_UL          ; WORLD_CELL_SEAL
    .byte   WORLD_TILE_PAVE_L           ; WORLD_CELL_FLOOR

.global _world_cell_tile_up_right
_world_cell_tile_up_right:

    .byte   WORLD_TILE_GRASS_R          ; WORLD_CELL_GRASS
    .byte   WORLD_TILE_DIRT_R           ; WORLD_CELL_DIRT
    .byte   WORLD_TILE_SAND_R           ; WORLD_CELL_SAND
    .byte   WORLD_TILE_PAVE_R           ; WORLD_CELL_PAVE
    .byte   WORLD_TILE_FOREST_UR        ; WORLD_CELL_FOREST
    .byte   WORLD_TILE_FOREST_THICK_R   ; WORLD_CELL_FOREST_THICK_U
    .byte   WORLD_TILE_FOREST_UR        ; WORLD_CELL_FOREST_THICK_D
    .byte   WORLD_TILE_FOREST_THICK_R   ; WORLD_CELL_FOREST_THICK_UD
    .byte   WORLD_TILE_TREE_UR          ; WORLD_CELL_TREE
    .byte   WORLD_TILE_ROCK_UR          ; WORLD_CELL_ROCK
    .byte   WORLD_TILE_CACTUS_UR        ; WORLD_CELL_CACTUS
    .byte   WORLD_TILE_STAIRS_DOWN_UR   ; WORLD_CELL_STAIRS_DOWN
    .byte   WORLD_TILE_BOX_UR           ; WORLD_CELL_BOX
    .byte   WORLD_TILE_SWORD_UR         ; WORLD_CELL_SWORD
    .byte   $00
    .byte   $00
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_0000
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_1000
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_0100
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_1100
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_0010
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_1010
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_0110
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_1110
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_0001
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_1001
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_0101
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_1101
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_0011
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_1011
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_0111
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_1111
    .byte   WORLD_TILE_GROUND_R         ; WORLD_CELL_GROUND
    .byte   WORLD_TILE_POISON_R         ; WORLD_CELL_POISON
    .byte   WORLD_TILE_WALL_UR          ; WORLD_CELL_WALL
    .byte   WORLD_TILE_STAIRS_UP_UR     ; WORLD_CELL_STAIRS_UP
    .byte   WORLD_TILE_SEAL_UR          ; WORLD_CELL_SEAL
    .byte   WORLD_TILE_PAVE_R           ; WORLD_CELL_FLOOR

.global _world_cell_tile_down_left
_world_cell_tile_down_left:

    .byte   WORLD_TILE_GRASS_L          ; WORLD_CELL_GRASS
    .byte   WORLD_TILE_DIRT_L           ; WORLD_CELL_DIRT
    .byte   WORLD_TILE_SAND_L           ; WORLD_CELL_SAND
    .byte   WORLD_TILE_PAVE_L           ; WORLD_CELL_PAVE
    .byte   WORLD_TILE_FOREST_DL        ; WORLD_CELL_FOREST
    .byte   WORLD_TILE_FOREST_DL        ; WORLD_CELL_FOREST_THICK_U
    .byte   WORLD_TILE_FOREST_THICK_L   ; WORLD_CELL_FOREST_THICK_D
    .byte   WORLD_TILE_FOREST_THICK_L   ; WORLD_CELL_FOREST_THICK_UD
    .byte   WORLD_TILE_TREE_DL          ; WORLD_CELL_TREE
    .byte   WORLD_TILE_ROCK_DL          ; WORLD_CELL_ROCK
    .byte   WORLD_TILE_CACTUS_DL        ; WORLD_CELL_CACTUS
    .byte   WORLD_TILE_STAIRS_DOWN_DL   ; WORLD_CELL_STAIRS_DOWN
    .byte   WORLD_TILE_BOX_DL           ; WORLD_CELL_BOX
    .byte   WORLD_TILE_SWORD_DL         ; WORLD_CELL_SWORD
    .byte   $00
    .byte   $00
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0000
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_1000
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0100
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_1100
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_0010
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1010
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_0110
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1110
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0001
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_1001
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_0101
    .byte   WORLD_TILE_WATER_L          ; WORLD_CELL_WATER_1101
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_0011
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1011
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_0111
    .byte   WORLD_TILE_WALL_L           ; WORLD_CELL_WATER_1111
    .byte   WORLD_TILE_GROUND_L         ; WORLD_CELL_GROUND
    .byte   WORLD_TILE_POISON_L         ; WORLD_CELL_POISON
    .byte   WORLD_TILE_WALL_DL          ; WORLD_CELL_WALL
    .byte   WORLD_TILE_STAIRS_UP_DL     ; WORLD_CELL_STAIRS_UP
    .byte   WORLD_TILE_SEAL_DL          ; WORLD_CELL_SEAL
    .byte   WORLD_TILE_PAVE_L           ; WORLD_CELL_FLOOR

.global _world_cell_tile_down_right
_world_cell_tile_down_right:

    .byte   WORLD_TILE_GRASS_R          ; WORLD_CELL_GRASS
    .byte   WORLD_TILE_DIRT_R           ; WORLD_CELL_DIRT
    .byte   WORLD_TILE_SAND_R           ; WORLD_CELL_SAND
    .byte   WORLD_TILE_PAVE_R           ; WORLD_CELL_PAVE
    .byte   WORLD_TILE_FOREST_DR        ; WORLD_CELL_FOREST
    .byte   WORLD_TILE_FOREST_DR        ; WORLD_CELL_FOREST_THICK_U
    .byte   WORLD_TILE_FOREST_THICK_R   ; WORLD_CELL_FOREST_THICK_D
    .byte   WORLD_TILE_FOREST_THICK_R   ; WORLD_CELL_FOREST_THICK_UD
    .byte   WORLD_TILE_TREE_DR          ; WORLD_CELL_TREE
    .byte   WORLD_TILE_ROCK_DR          ; WORLD_CELL_ROCK
    .byte   WORLD_TILE_CACTUS_DR        ; WORLD_CELL_CACTUS
    .byte   WORLD_TILE_STAIRS_DOWN_DR   ; WORLD_CELL_STAIRS_DOWN
    .byte   WORLD_TILE_BOX_DR           ; WORLD_CELL_BOX
    .byte   WORLD_TILE_SWORD_DR         ; WORLD_CELL_SWORD
    .byte   $00
    .byte   $00
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_0000
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_1000
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_0100
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_1100
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_0010
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_1010
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_0110
    .byte   WORLD_TILE_WATER_R          ; WORLD_CELL_WATER_1110
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_0001
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_1001
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_0101
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_1101
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_0011
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_1011
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_0111
    .byte   WORLD_TILE_WALL_R           ; WORLD_CELL_WATER_1111
    .byte   WORLD_TILE_GROUND_R         ; WORLD_CELL_GROUND
    .byte   WORLD_TILE_POISON_R         ; WORLD_CELL_POISON
    .byte   WORLD_TILE_WALL_DR          ; WORLD_CELL_WALL
    .byte   WORLD_TILE_STAIRS_UP_DR     ; WORLD_CELL_STAIRS_UP
    .byte   WORLD_TILE_SEAL_DR          ; WORLD_CELL_SEAL
    .byte   WORLD_TILE_PAVE_R           ; WORLD_CELL_FLOOR

; タイルセット
;
.global _world_tileset
_world_tileset:

.incbin     "resources/tiles/world.ts"

; タイル
;
.global _world_tile_attribute
_world_tile_attribute:

    .byte   WORLD_TILE_ATTRIBUTE_REST                                   ; WORLD_TILE_GRASS_L
    .byte   WORLD_TILE_ATTRIBUTE_REST                                   ; WORLD_TILE_GRASS_R
    .byte   WORLD_TILE_ATTRIBUTE_SLOW                                   ; WORLD_TILE_DIRT_L
    .byte   WORLD_TILE_ATTRIBUTE_SLOW                                   ; WORLD_TILE_DIRT_R
    .byte   WORLD_TILE_ATTRIBUTE_HEAT                                   ; WORLD_TILE_SAND_L
    .byte   WORLD_TILE_ATTRIBUTE_HEAT                                   ; WORLD_TILE_SAND_R
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_FOREST_UL
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_FOREST_UR
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_FOREST_DL
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_FOREST_DR
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_FOREST_THICK_L
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_FOREST_THICK_R
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_WATER_L
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_WATER_R
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_WALL_L
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_WALL_R
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_TREE_UL
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_TREE_UR
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_TREE_DL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_TREE_DR
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_ROCK_UL
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_ROCK_UR
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_ROCK_DL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_ROCK_DR
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_CACTUS_UL
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_CACTUS_UR
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_CACTUS_DL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_CACTUS_DR
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_PAVE_L
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_PAVE_R
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_1E
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_1F
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_STAIRS_DOWN_UL
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_STAIRS_DOWN_UR
    .byte   WORLD_TILE_ATTRIBUTE_STAIRS                                 ; WORLD_TILE_STAIRS_DOWN_DL
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_STAIRS_DOWN_DR
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_BOX_UL
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_BOX_UR
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION | WORLD_TILE_ATTRIBUTE_BOX   ; WORLD_TILE_BOX_DL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION | WORLD_TILE_ATTRIBUTE_BOX   ; WORLD_TILE_BOX_DR
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_SWORD_UL
    .byte   WORLD_TILE_ATTRIBUTE_HIDE                                   ; WORLD_TILE_SWORD_UR
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION | WORLD_TILE_ATTRIBUTE_BOX   ; WORLD_TILE_SWORD_DL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION | WORLD_TILE_ATTRIBUTE_BOX   ; WORLD_TILE_SWORD_DR
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_2C
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_2D
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_2E
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_2F
    .byte   WORLD_TILE_ATTRIBUTE_REST                                   ; WORLD_TILE_GROUND_L
    .byte   WORLD_TILE_ATTRIBUTE_REST                                   ; WORLD_TILE_GROUND_R
    .byte   WORLD_TILE_ATTRIBUTE_HURT                                   ; WORLD_TILE_POISON_L
    .byte   WORLD_TILE_ATTRIBUTE_HURT                                   ; WORLD_TILE_POISON_R
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_WALL_UL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_WALL_UR
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_WALL_DL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_WALL_DR
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_STAIRS_UP_UL
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_STAIRS_UP_UR
    .byte   WORLD_TILE_ATTRIBUTE_STAIRS                                 ; WORLD_TILE_STAIRS_UP_DL
    .byte   WORLD_TILE_ATTRIBUTE_NULL                                   ; WORLD_TILE_STAIRS_UP_DR
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_SEAL_UL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_SEAL_UR
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_SEAL_DL
    .byte   WORLD_TILE_ATTRIBUTE_COLLISION                              ; WORLD_TILE_SEAL_DR

; ファイル名
;
world_file_name:

    .asciiz "WORLD"


; データの定義
;
.segment    "BSS"

; エリア
;

; セル
.global _world_area_cell
_world_area_cell:

    .res    WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y

; タイル
.global _world_area_tile
_world_area_tile:

    .res    WORLD_AREA_TILE_SIZE_X * WORLD_AREA_TILE_SIZE_Y

; ライト
.global _world_area_light
_world_area_light:

    .res    $01

; ファイル
;

; ファイルの先頭
world_file_head:

; ID
.global _world_id
_world_id:

    .res    WORLD_ID_SIZE

; エリア
.global _world_area
_world_area:

    .res    WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y

; セル
.global _world_cell
_world_cell:

    .res    (WORLD_AREA_SIZE_X * WORLD_AREA_SIZE_Y) * (WORLD_AREA_CELL_SIZE_X * WORLD_AREA_CELL_SIZE_Y)

; ファイルの末端
world_file_tail:

