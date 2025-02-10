; game.s - ゲーム
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

; ゲームのエントリポイント
;
.global _GameEntry
.proc   _GameEntry

    ; ゲームの初期化
    lda     #$00
    sta     _game_clear
    lda     #GAME_SPEED_NORMAL
    sta     game_speed

    ; チートの初期化
    lda     #$00
    sta     _game_cheat_nodamage

    ; 処理の設定
    lda     #<GameLoad
    sta     APP2_0_PROC_L
    lda     #>GameLoad
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE

    ; 終了
    rts

.endproc

; ゲームをロードする
;
.proc   GameLoad

;   ; 初期化
;   lda     APP2_0_STATE
;   bne     @initialized

;   ; VRAM のクリア
;   jsr     _IocsClearVram

    ; イメージの読み込み
    ldx     #<@load_arg
    lda     #>@load_arg
    jsr     _IocsBload

    ; ワールドの読み込み
    jsr     _WorldLoad

    ; ユーザの読み込み
    jsr     _UserLoad

    ; ステータスの描画
    jsr     GameDrawUserStatus

    ; アイテムの描画
    jsr     GameDrawUserItem

    ; 文字列の描画
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDrawString

    ; 開始位置の取得
    lda     #WORLD_EVENT_START
    jsr     _WorldGetEventArea
    sta     _game_area
    lda     #WORLD_LAYER_FIELD
    sta     _game_layer
    lda     #WORLD_DRAW_CENTER
    sta     game_enter

    ;; ドラゴンの部屋の入り口に立つ／デバッグ
.if 0
    lda     #WORLD_EVENT_SWORD
    jsr     _WorldGetEventArea
    tax
    lda     _world_area_down, x
    sta     _game_area
    lda     #WORLD_LAYER_DUNGEON
    sta     _game_layer
    inc     _user_item + USER_ITEM_SWORD
    inc     _user_item + USER_ITEM_TORCH
.endif

    ; タイルセットの読み込み
    lda     _game_layer
    jsr     _ActorLoadTileset

    ; アクタの初期化
    jsr     _ActorInitialize

;   ; 初期化の完了
;   inc     APP2_0_STATE
;@initialized:

    ; 処理の設定
    lda     #<GameEnter
    sta     APP2_0_PROC_L
    lda     #>GameEnter
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE

    ; 終了
    rts

; 読み込みの引数
@load_arg:
    .word   @load_name
    .word   $2000
@load_name:
    .asciiz "FRAME"

; 描画の引数
@draw_arg:
    .byte   $0a, $0b
    .word   @draw_string
@draw_string:
    .asciiz "UNLEASH IT"

.endproc

; ゲームを再ロードする
;
.proc   GameReload

;   ; 初期化
;   lda     APP2_0_STATE
;   bne     @initialized

    ; ユーザの開始
    jsr     _UserStart

    ; ステータスの描画
    jsr     GameDrawUserStatus

    ; アイテムの描画
    jsr     GameDrawUserItem

    ; 開始位置の取得
    lda     #WORLD_EVENT_START
    jsr     _WorldGetEventArea
    sta     _game_area
    lda     #WORLD_LAYER_FIELD
    sta     _game_layer
    lda     #WORLD_DRAW_CENTER
    sta     game_enter

    ; タイルセットの読み込み
    lda     _game_layer
    jsr     _ActorLoadTileset

    ; アクタの初期化
    jsr     _ActorInitialize

;   ; 初期化の完了
;   inc     APP2_0_STATE
;@initialized:

    ; 処理の設定
    lda     #<GameEnter
    sta     APP2_0_PROC_L
    lda     #>GameEnter
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE

    ; 終了
    rts

.endproc

; エリアに入る
;
.proc   GameEnter

;   ; 初期化
;   lda     APP2_0_STATE
;   bne     @initialized

    ; エリアの展開
    lda     _game_layer
    bne     :+
    lda     _game_area
    jsr     _WorldLDuplicateFieldAreaCell
    jmp     :++
:
    lda     _game_area
    jsr     _WorldLDuplicateDungeonAreaCell
:
    jsr     _WorldLayoutAreaCellTile

    ; イベントの進行
    jsr     GameEvent

    ; アクタのクリア
    jsr     _ActorClear

    ; ライトの設定
    lda     _game_layer
    beq     :+
    lda     _user_item + USER_ITEM_TORCH
    jmp     :++
:
    lda     #$01
:
    sta     _world_area_light

    ; ワールドの描画
    lda     game_enter
    jsr     _WorldDrawArea

    ; プレイヤの読み込み
    lda     #ACTOR_CLASS_PLAYER
    jsr     _ActorLoad

    ; エネミーの初期配置
    jsr     GameSpawnInitial

;   ; 初期化の完了
;   inc     APP2_0_STATE
;@initialized:

    ; 処理の設定
    lda     #<GamePlay
    sta     APP2_0_PROC_L
    lda     #>GamePlay
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE

    ; 終了
    rts

.endproc

; ゲームをプレイする
;
.proc   GamePlay

    ; 初期化
    lda     APP2_0_STATE
    bne     @initialized

    ; エリアの設定
    lda     #$ff
    sta     _game_area_exit

    ; レイヤの設定
;   lda     #$ff
    sta     _game_layer_exit

    ; エネミーの生成の設定
    lda     #$00
    sta     game_spawn_count

    ; 初期化の完了
    inc     APP2_0_STATE
@initialized:

    ; エネミーの生成
    jsr     GameSpawnContinue

    ; アクタの行動
    jsr     _ActorPlay

    ; ゲームをクリア
    lda     _game_clear
    bne     @clear

    ; プレイヤの監視
    lda     #ACTOR_CLASS_PLAYER
    jsr     _ActorGetClassCount
    cmp     #$00
    beq     @over

    ; エリア移動の監視
    lda     _game_area_exit
    bpl     @exit

    ; レイヤ移動の監視
    lda     _game_layer_exit
    bpl     @exit

    ; セーブ
    lda     IOCS_0_KEYCODE
    cmp     #$1b
    beq     @save

    ; チート
    lda     IOCS_0_KEYCODE
    cmp     #'@'
    beq     @cheat

    ; ゲーム速度の変更
    jsr     GameChangeSpeed

    ; ウェイト
    ldx     game_speed
    lda     @speed, x
    jsr     _IocsBeepRest
    jmp     @end

    ; ゲームをクリアする
@clear:
    lda     #<GameClear
    sta     APP2_0_PROC_L
    lda     #>GameClear
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE
    jmp     @end

    ; ゲームオーバーになる
@over:
    lda     #<GameOver
    sta     APP2_0_PROC_L
    lda     #>GameOver
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE
    jmp     @end

    ; エリアから出る
@exit:
    lda     #<GameExit
    sta     APP2_0_PROC_L
    lda     #>GameExit
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE
    jmp     @end

    ; セーブする
@save:
    lda     #<GameSave
    sta     APP2_0_PROC_L
    lda     #>GameSave
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE
    jmp     @end

    ; チートする
@cheat:
    lda     #<GameCheat
    sta     APP2_0_PROC_L
    lda     #>GameCheat
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE
    jmp     @end

    ; 終了
@end:
    rts

; 速度
@speed:
    .byte   IOCS_BEEP_L32
    .byte   IOCS_BEEP_L64
    .byte   IOCS_BEEP_L128

.endproc

; エリアから出る
;
.proc   GameExit

;   ; 初期化
;   lda     APP2_0_STATE
;   bne     @initialized

    ; 情報のクリア
    jsr     _GameClearInformation

;   ; 初期化の完了
;   inc     APP2_0_STATE
;@initialized:

    ; アクタの破棄
    jsr     _ActorUnload

    ; エリアの移動
@area:
    ldx     _game_area
    ldy     _game_area_exit
    bmi     @layer
    bne     :+
    lda     #(WORLD_AREA_TILE_SIZE_Y - $02)
    sta     _user_y
    lda     #WORLD_DRAW_UP_DOWN
    sta     game_enter
    lda     _world_area_up, x
    jmp     @area_end
:
    dey
    bne     :+
    lda     #$00
    sta     _user_y
    lda     #WORLD_DRAW_DOWN_UP
    sta     game_enter
    lda     _world_area_down, x
    jmp     @area_end
:
    dey
    bne     :+
    lda     #(WORLD_AREA_TILE_SIZE_X - $02)
    sta     _user_x
    lda     #WORLD_DRAW_LEFT_RIGHT
    sta     game_enter
    lda     _world_area_left, x
    jmp     @area_end
:
    lda     #$00
    sta     _user_x
    lda     #WORLD_DRAW_RIGHT_LEFT
    sta     game_enter
    lda     _world_area_right, x
;   jmp     @area_end
@area_end:
    sta     _game_area
    jmp     @next

    ; レイヤの移動
@layer:
;   lda     _game_layer_exit
;   bmi     @layer_end
    lda     _game_layer
    eor     #$01
    sta     _game_layer
    jsr     _ActorLoadTileset
    lda     #WORLD_DRAW_CENTER
    sta     game_enter
    jsr     _WorldEraseArea
;   jmp     @next

    ; 処理の設定
@next:
    lda     #<GameEnter
    sta     APP2_0_PROC_L
    lda     #>GameEnter
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE

    ; 終了
    rts

.endproc

; ゲームをクリアする
;
.proc   GameClear

    ; 初期化
    lda     APP2_0_STATE
    bne     @initialized

    ; 情報のクリア
    jsr     _GameClearInformation

    ; イメージの読み込み
    ldx     #<@load_arg
    lda     #>@load_arg
    jsr     _IocsBload

    ; 初期化の完了
    inc     APP2_0_STATE
@initialized:

;   ; キー入力
;   lda     IOCS_0_KEYCODE
;   beq     @end

;   ; BEEP
;   ldx     #IOCS_BEEP_PI
;   lda     #IOCS_BEEP_L16
;   jsr     _IocsBeepNote

;   ; 処理の設定
;   lda     #$00
;   sta     APP2_0_BRUN
;   jmp     @end

    ; 終了
@end:
    rts

; 読み込みの引数
@load_arg:
    .word   @load_name
    .word   $2000
@load_name:
    .asciiz "END"

.endproc

; ゲームオーバーになる
;
.proc   GameOver

;   ; 初期化
;   lda     APP2_0_STATE
;   bne     @initialized

    ; 情報のクリア
    jsr     _GameClearInformation

    ; エリアの消去
    jsr     _WorldEraseArea

;   ; 初期化の完了
;   inc     APP2_0_STATE
;@initialized:

    ; 処理の設定
    lda     #<GameReload
    sta     APP2_0_PROC_L
    lda     #>GameReload
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE

    ; 終了
    rts

.endproc

; ゲームをセーブする
;
.proc   GameSave

    ; 初期化
    lda     APP2_0_STATE
    bne     @initialized

    ; 情報のクリア
    jsr     _GameClearInformation

    ; 文字列の描画
    ldx     #<@draw_0_arg
    lda     #>@draw_0_arg
    jsr     _IocsDrawString

    ; 初期化の完了
    inc     APP2_0_STATE
@initialized:

    ; キーの入力
    lda     IOCS_0_KEYCODE
    
    ; [Y]ES
@yes:
    cmp     #'Y'
    bne     @no

    ; 情報のクリア
    jsr     _GameClearInformation

    ; 文字列の描画
    ldx     #<@draw_1_arg
    lda     #>@draw_1_arg
    jsr     _IocsDrawString

    ; 体力の更新
    lda     #ACTOR_CLASS_PLAYER
    jsr     _ActorGetByClass
    cpx     #$ff
    beq     :+
    lda     _actor_life, x
    sta     _user_life
:

    ; ユーザの保存
    jsr     _UserSave
    jmp     @done

    ; [N]O
@no:
    cmp     #'N'
    bne     @end

    ; セーブの完了
@done:

;   ; 情報のクリア
;   jsr     _GameClearInformation

    ; 処理の設定
    lda     #<GameQuit
    sta     APP2_0_PROC_L
    lda     #>GameQuit
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE

    ; 終了
@end:
    rts

; 描画の引数
@draw_0_arg:
    .byte   $1f, $12
    .word   @draw_0_string
@draw_0_string:
    .asciiz "SAVE?\n\n[Y]ES\n[N]O"
@draw_1_arg:
    .byte   $1f, $12
    .word   @draw_1_string
@draw_1_string:
    .asciiz "SAVING..."

.endproc

; ゲームを終了する
;
.proc   GameQuit

    ; 初期化
    lda     APP2_0_STATE
    bne     @initialized

    ; 情報のクリア
    jsr     _GameClearInformation

    ; 文字列の描画
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDrawString

    ; 初期化の完了
    inc     APP2_0_STATE
@initialized:

    ; キーの入力
    lda     IOCS_0_KEYCODE
    
    ; [Y]ES
@yes:
    cmp     #'Y'
    bne     @no

    ; 情報のクリア
    jsr     _GameClearInformation

    ; 処理の設定
    ; 処理の設定
    lda     #<GamePlay
    sta     APP2_0_PROC_L
    lda     #>GamePlay
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE
    jmp     @end

    ; [N]O
@no:
    cmp     #'N'
    bne     @end

    ; 処理の設定
    lda     #$00
    sta     APP2_0_BRUN
;   jmp     @end

    ; 終了
@end:
    rts

; 描画の引数
@draw_arg:
    .byte   $1f, $12
    .word   @draw_string
@draw_string:
    .asciiz "CONTINUE?\n\n[Y]ES\n[N]O"

.endproc

; ゲームをチートする
;
.proc   GameCheat

    ; 初期化
    lda     APP2_0_STATE
    bne     @initialized

    ; 情報のクリア
    jsr     _GameClearInformation

    ; 文字列の描画
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDrawString

    ; 初期化の完了
    inc     APP2_0_STATE
@initialized:

    ; キーの入力
    lda     IOCS_0_KEYCODE
    
    ; 強さの変更
    cmp     #'0'
    bcc     :+
    cmp     #('9' + $01)
    bcs     :+
    jsr     @level
    jmp     @done
:

    ; アイテムの取得
    ldx     #$00
:
    cmp     @item_keycode, x
    beq     :+
    inx
    cpx     #USER_ITEM_SIZE
    bne     :-
    jmp     :++
:
    jsr     @item
    jmp     @done
:

    ; 無敵の設定
    cmp     #'N'
    bne     :+
    lda     _game_cheat_nodamage
    eor     #%00000001
    sta     _game_cheat_nodamage
    jmp     @done
:

    ; チートの終了
    cmp     #'@'
    bne     @end
@done:

    ; 情報のクリア
    jsr     _GameClearInformation

    ; 処理の設定
    lda     #<GamePlay
    sta     APP2_0_PROC_L
    lda     #>GamePlay
    sta     APP2_0_PROC_H
    lda     #$00
    sta     APP2_0_STATE

    ; 終了
@end:
    rts

; 描画の引数
@draw_arg:
    .byte   $1f, $12
    .word   @draw_string
@draw_string:
    .asciiz "CHEAT?"

    ; レベルの変更
@level:
    sec
    sbc     #'0'
    pha
    lda     #ACTOR_CLASS_PLAYER
    jsr     _ActorGetByClass
    pla
    cpx     #$ff
    beq     :+
    tay
    lda     @level_strength, y
    sta     _user_strength
    lda     @level_life, y
    sta     _user_life_maximum
    sta     _actor_life, x
    lda     #$00
    sta     _user_experience
    jsr     _GameDrawActorStatus
:
    rts

@level_strength:
    .byte    10,   1,   2,   3,   4,   5,   6,   7,   8,   9
@level_life:
    .byte   120,  30,  40,  50,  60,  70,  80,  90, 100, 110 

    ; アイテムの取得
@item:
    lda     _user_item, x
    bne     :+
    txa
    jsr     _GameAddItem
    jmp     :++
:
    txa
    jsr     _GameRemoveItem
:
    rts

@item_keycode:
    .asciiz "SBCMTAKOPRLG"

.endproc

; イベントを進行する
;
.proc   GameEvent

    ; WORK
    ;   GAME_0_WORK_0..1

    ; フィールドイベントの進行
@field:
    lda     _game_layer
    bne     @dungeon
    ldx     _game_area
    lda     _world_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_SWORD
    beq     @field_box
    cmp     #WORLD_EVENT_BOOTS
    beq     @field_box
    cmp     #WORLD_EVENT_CLOAK
    beq     @field_box
    cmp     #WORLD_EVENT_MASK
    beq     @field_box
    cmp     #WORLD_EVENT_TORCH
    beq     @field_box
    cmp     #WORLD_EVENT_TALISMAN
    beq     @field_talisman
    cmp     #WORLD_EVENT_AMULET
    beq     @field_amulet
    cmp     #WORLD_EVENT_POTION
    beq     @field_potion
    cmp     #WORLD_EVENT_CRYSTAL_RED
    beq     @field_crystal
    cmp     #WORLD_EVENT_CRYSTAL_BLUE
    beq     @field_crystal
    cmp     #WORLD_EVENT_CRYSTAL_GREEN
    beq     @field_crystal
    jmp     @null

    ; ダンジョンイベントの進行
@dungeon:
    ldx     _game_area
    ldy     _world_area_up, x
    lda     _world_area, y
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_SWORD
    beq     @dungeon_sword
    jmp     @null

    ; なし
@null:
    rts

    ; 宝箱
@field_box:
    lda     _user_event, x
    beq     :+
    lda     #$00
    jsr     _WorldRemoveBox
:
    rts

    ; お守り
@field_talisman:
    lda     _user_event, x
    bne     :+
    jsr     @random_xy
    ldx     _game_event_x
    ldy     _game_event_y
    lda     #WORLD_CELL_CACTUS
    jsr     _WorldSetAreaCell
:
    rts

    ; 魔除け
@field_amulet:
    lda     _user_event, x
    bne     :+
    jsr     @random_xy
    ldx     _game_event_x
    ldy     _game_event_y
    lda     #WORLD_CELL_ROCK
    jsr     _WorldSetAreaCell
:
    rts

    ; 薬
@field_potion:
    lda     _user_event, x
    bne     :+
    jsr     @random_xy
    ldx     _game_event_x
    ldy     _game_event_y
    lda     #WORLD_CELL_TREE
    jsr     _WorldSetAreaCell
:
    rts

    ; 水晶
@field_crystal:
    lda     _user_event, x
    cmp     #$01
    bne     :+
    lda     #$00
    jsr     _WorldPlaceBox
:
    rts

    ; 剣
@dungeon_sword:
    lda     _user_item + USER_ITEM_SWORD
    beq     :+
    jsr     _WorldUnseal
:
    rts

    ; ランダムな位置を取得する
@random_xy:
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :+, y
    sta     _game_event_x
    jsr     _IocsGetRandomNumber
    and     #$07
    tay
    lda     :++, y
    sta     _game_event_y
    ldx     _game_event_x
    ldy     _game_event_y
    jsr     _WorldGetAreaCell
    cmp     #WORLD_CELL_WATER_0000
    bcs     @random_xy
    rts
:
    .byte   1, 3, 5, 6, 8, 9, 11, 13
:
    .byte   1, 2, 3, 4, 6, 7, 8, 9

.endproc

; エネミーを初期配置する
;
.proc   GameSpawnInitial

    ; WORK
    ;   GAME_0_WORK_0

    ; フィールドの配置
@field:
    lda     _game_layer
    bne     @dungeon

    ; イベント別の処理
    ldx     _game_area
    lda     _world_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_START
    beq     @field_start
    cmp     #WORLD_EVENT_KEY
    beq     @field_key
    cmp     #WORLD_EVENT_TALISMAN
    beq     @field_talisman
    cmp     #WORLD_EVENT_AMULET
    beq     @field_amulet
    cmp     #WORLD_EVENT_POTION
    beq     @field_potion
    jmp     @last

    ; WORLD_EVENT_START／フィールド
@field_start:
    lda     #ACTOR_CLASS_SLIME
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_SLIME
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_SLIME
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_SLIME
    jsr     _ActorLoad
    jmp     @end

    ; WORLD_EVENT_KEY／フィールド
@field_key:
    lda     _user_event, x
    bne     :+
    lda     #ACTOR_CLASS_GREMLIN
    jsr     _ActorLoad
:
    jmp     @last

    ; WORLD_EVENT_TALISMAN／フィールド
@field_talisman:
    lda     _user_event, x
    bne     :+
    lda     #ACTOR_CLASS_CACTUS
    jsr     _ActorLoad
:
    jmp     @last

    ; WORLD_EVENT_AMULET／フィールド
@field_amulet:
    lda     _user_event, x
    bne     :+
    lda     #ACTOR_CLASS_ROCK
    jsr     _ActorLoad
:
    jmp     @last

    ; WORLD_EVENT_POTION／フィールド
@field_potion:
    lda     _user_event, x
    bne     :+
    lda     #ACTOR_CLASS_TREE
    jsr     _ActorLoad
:
    jmp     @last

    ; ダンジョンの配置
@dungeon:
    ldx     _game_area
    lda     _world_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_STAIRS
    beq     @dungeon_stairs
    cmp     #WORLD_EVENT_SWORD
    beq     @dungeon_sword
    cmp     #WORLD_EVENT_CRYSTAL_RED
    beq     @dungeon_crystal_red
    cmp     #WORLD_EVENT_CRYSTAL_BLUE
    beq     @dungeon_crystal_blue
    cmp     #WORLD_EVENT_CRYSTAL_GREEN
    beq     @dungeon_crystal_green
    jmp     @last

    ; WORLD_EVENT_STAIRS／ダンジョン
@dungeon_stairs:
    lda     #ACTOR_CLASS_BAT
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_BAT
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_BAT
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_BAT
    jsr     _ActorLoad
    jmp     @last

    ; WORLD_EVENT_SWORD／ダンジョン
@dungeon_sword:
    lda     #ACTOR_CLASS_DRAGON
    jsr     _ActorLoad
    jmp     @end

    ; WORLD_EVENT_CRYSTAL_RED／ダンジョン
@dungeon_crystal_red:
    lda     _user_event, x
    bne     :+
    lda     #ACTOR_CLASS_HYDRA
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_HYDRA
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_HYDRA
    jsr     _ActorLoad
:
    jmp     @last

    ; WORLD_EVENT_CRYSTAL_BLUE／ダンジョン
@dungeon_crystal_blue:
    lda     _user_event, x
    bne     :+
    lda     #ACTOR_CLASS_DEVIL
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_DEVIL
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_DEVIL
    jsr     _ActorLoad
:
    jmp     @last

    ; WORLD_EVENT_CRYSTAL_GREEN／ダンジョン
@dungeon_crystal_green:
    lda     _user_event, x
    bne     :+
    lda     #ACTOR_CLASS_WIZARD
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_WIZARD
    jsr     _ActorLoad
    lda     #ACTOR_CLASS_WIZARD
    jsr     _ActorLoad
:
    jmp     @last

    ; 残りは規定のエネミーを生成
@last:
    lda     #ACTOR_TYPE_ENEMY
    jsr     _ActorGetTypeCount
:
    cmp     #GAME_SPAWN_SIZE
    bcs     @end
    pha
    jsr     GameSpawnRandom
    pla
    clc
    adc     #$01
    jmp     :-

    ; 終了
@end:
    rts

.endproc

; 継続してエネミーを生成する
;
.proc   GameSpawnContinue

    ; WORK
    ;   GAME_0_WORK_0

    ; 0 サイクル時に生成
    lda     _actor_cycle
    bne     @end

    ;  エネミーの数の取得
    lda     #ACTOR_TYPE_ENEMY
    jsr     _ActorGetTypeCount
    cmp     #GAME_SPAWN_SIZE
    bcs     @end

    ; カウントの更新
    lda     game_spawn_count
    beq     :+
    dec     game_spawn_count
    jmp     @end
:

    ; エネミーの生成
    jsr     GameSpawnRandom

    ; 生成の完了
    lda     #GAME_SPAWN_INTERVAL
    sta     game_spawn_count

    ; 終了
@end:
    rts

.endproc

; ランダムに 1 体エネミーを生成する
;
.proc   GameSpawnRandom

    ; WORK
    ;   GAME_0_WORK_0

    ; フィールドの生成
@field:
    lda     _game_layer
    bne     @dungeon
    ldx     _game_area
    lda     _world_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_START
    beq     @field_start
    jmp     @random

    ; WORLD_EVENT_START／フィールド
@field_start:
    lda     #ACTOR_CLASS_SLIME
    jmp     @load

    ; ダンジョンの生成
@dungeon:
    ldx     _game_area
    lda     _world_area, x
    and     #WORLD_AREA_EVENT_MASK
    cmp     #WORLD_EVENT_STAIRS
    beq     @dungeon_stairs
    cmp     #WORLD_EVENT_SWORD
    beq     @dungeon_sword
    lda     _user_item + USER_ITEM_SWORD
    bne     @dungeon_random
    jmp     @random

    ; WORLD_EVENT_STAIRS／ダンジョン
@dungeon_stairs:
    lda     #ACTOR_CLASS_BAT
    jmp     @load

    ; WORLD_EVENT_SWORD／ダンジョン
@dungeon_sword:
    jmp     @end

    ; 剣入手後／ダンジョン
@dungeon_random:
    jsr     _IocsGetRandomNumber
    and     #$07
    tax
    lda     game_spawn_class_sword, x
    jmp     @load

    ; テーブルからランダムに生成
@random:
    ldx     _game_area
    lda     _world_area, x
    and     #(WORLD_AREA_INSIDE | WORLD_AREA_LAND_MASK)
    lsr     a
    lsr     a
    sta     GAME_0_WORK_0
    jsr     _IocsGetRandomNumber
    and     #$03
    clc
    adc     GAME_0_WORK_0
    tax
    lda     _game_layer
    bne     :+
    lda     game_spawn_class_field, x
    jmp     @load
:
    lda     game_spawn_class_dungeon, x
    jmp     @load

    ; アクタの読み込み
@load:
    cmp     #$00
    beq     :+
    jsr     _ActorLoad
:

    ; 終了
@end:
    rts

.endproc

; アイテムを追加する
;
.global _GameAddItem
.proc   _GameAddItem

    ; IN
    ;   a = アイテム

    ; アイテムの追加
    pha
    tax
    lda     #$01
    sta     _user_item, x

;   ; 松明の更新
;   cpx     #USER_ITEM_TORCH
;   bne     :+
;   lda     #$01
;   sta     _world_area_light
;:

    ; アイテムの描画と点滅
    jsr     GameDrawUserItem
    pla
    jsr     GameBlinkUserItem

    ; 終了
    rts

.endproc

; アイテムを破棄する
;
.global _GameRemoveItem
.proc   _GameRemoveItem

    ; IN
    ;   a = アイテム

    ; アイテムの点滅
    pha
    jsr     GameBlinkUserItem
    pla

    ; アイテムの破棄
    tax
    lda     #$00
    sta     _user_item, x

;   ; 松明の更新
;   cpx     #USER_ITEM_TORCH
;   bne     :+
;   lda     #$00
;   sta     _world_area_light
;:

    ; アイテムの描画
    jsr     GameDrawUserItem

    ; 終了
    rts

.endproc

; 宝箱を開ける
;
.global _GameOpenBox
.proc   _GameOpenBox

    ; 宝箱はフィールドのみに配置

    ; アイテムの取得
    ldx     _game_area
    lda     _world_area, x
    and     #WORLD_AREA_EVENT_MASK
    tay
    lda     @item, y
    bmi     @end

    ; 鍵で開ける
    cmp     #USER_ITEM_SWORD
    bne     :+
    ldy     _user_item + USER_ITEM_CRYSTAL_RED
    beq     @end
    ldy     _user_item + USER_ITEM_CRYSTAL_BLUE
    beq     @end
    ldy     _user_item + USER_ITEM_CRYSTAL_GREEN
    beq     @end
    jmp     :++
:
    ldy     _user_item + USER_ITEM_KEY
    beq     @end
:
    jsr     _GameAddItem

    ; イベントの更新
    ldx     _game_area
    inc     _user_event, x

    ; 描画ありで宝箱を削除
    lda     #$01
    jsr     _WorldRemoveBox

    ; 終了
@end:
    rts

; アイテム
@item:
    .byte   $ff                     ; WORLD_EVENT_NULL
    .byte   $ff                     ; WORLD_EVENT_START
    .byte   $ff                     ; WORLD_EVENT_STAIRS
    .byte   USER_ITEM_SWORD         ; WORLD_EVENT_SWORD
    .byte   USER_ITEM_BOOTS         ; WORLD_EVENT_BOOTS
    .byte   USER_ITEM_CLOAK         ; WORLD_EVENT_CLOAK
    .byte   USER_ITEM_MASK          ; WORLD_EVENT_MASK
    .byte   $ff                     ; WORLD_EVENT_KEY
    .byte   USER_ITEM_TORCH         ; WORLD_EVENT_TORCH
    .byte   $ff                     ; WORLD_EVENT_TALISMAN
    .byte   $ff                     ; WORLD_EVENT_AMULET
    .byte   $ff                     ; WORLD_EVENT_POTION
    .byte   USER_ITEM_CRYSTAL_RED   ; WORLD_EVENT_CRYSTAL_RED
    .byte   USER_ITEM_CRYSTAL_BLUE  ; WORLD_EVENT_CRYSTAL_BLUE
    .byte   USER_ITEM_CRYSTAL_GREEN ; WORLD_EVENT_CRYSTAL_GREEN

.endproc

; ゲームの速度を変更する
;
.proc   GameChangeSpeed

    ; キーの入力
    lda     IOCS_0_KEYCODE
    cmp     #'1'
    bne     :+
    ldy     #GAME_SPEED_FAST
    ldx     #<@draw_arg_fast
    lda     #>@draw_arg_fast
    jmp     @change
:
    cmp     #'2'
    bne     :+
    ldy     #GAME_SPEED_NORMAL
    ldx     #<@draw_arg_normal
    lda     #>@draw_arg_normal
    jmp     @change
:
    cmp     #'3'
    bne     @end
    ldy     #GAME_SPEED_SLOW
    ldx     #<@draw_arg_slow
    lda     #>@draw_arg_slow
;   jmp     @change

    ; 速度の変更
@change:
    sty     game_speed
    pha
    txa
    pha
    jsr     _GameClearInformation
    pla
    tax
    pla
    jsr     _IocsDrawString

    ; 終了
@end:
    rts

; 描画の引数
@draw_arg_slow:
    .byte   $1f, $12
    .word   @draw_string_slow
@draw_string_slow:
    .asciiz "WALK\nSLOWLY"
@draw_arg_normal:
    .byte   $1f, $12
    .word   @draw_string_normal
@draw_string_normal:
    .asciiz "WALK\nNORMALLY"
@draw_arg_fast:
    .byte   $1f, $12
    .word   @draw_string_fast
@draw_string_fast:
    .asciiz "WALK\nQUICKLY"

.endproc

; ユーザのステータスを描画する
;
.proc   GameDrawUserStatus

    ; 体力の描画
    lda     _user_life
    jsr     GameDrawStatusLife

    ; 強さの描画
    lda     _user_strength
    jsr     GameDrawStatusStrength

    ; 経験値の描画
    lda     _user_experience
    jsr     GameDrawStatusExperience

    ; 終了
    rts

.endproc

; アクタのステータスを描画する
;
.global _GameDrawActorStatus
.proc   _GameDrawActorStatus

    ; IN
    ;   x = アクタの参照

    ; アクタの保存
    txa
    pha

    ; 体力の描画
    lda     _actor_life, x
    jsr     GameDrawStatusLife

    ; 強さの描画
    lda     _user_strength
    jsr     GameDrawStatusStrength

    ; 経験値の描画
    lda     _user_experience
    jsr     GameDrawStatusExperience

    ; アクタの復帰
    pla
    tax

    ; 終了
    rts

.endproc

; アクタの体力を描画する
;
.global _GameDrawActorStatusLife
.proc   _GameDrawActorStatusLife

    ; IN
    ;   x = アクタの参照

    ; アクタの保存
    txa
    pha

    ; 体力の描画
    lda     _actor_life, x
    jsr     GameDrawStatusLife

    ; アクタの復帰
    pla
    tax

    ; 終了
    rts

.endproc

; 体力を描画する
;
.proc   GameDrawStatusLife

    ; IN
    ;   a = 体力

    ;; 体力の数値の描画／デバッグ
.if 0
    pha
    tax
    lda     #$00
    jsr     _IocsGetNumber5Chars
    stx     @draw_arg + $0002
    sta     @draw_arg + $0003
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDrawString
    pla
.endif

    ; ステータスバーの描画
    jsr     @range
    ldx     #$01
    ldy     #$02
    jsr     _GameDrawStatusBar

    ; ステータスラインの描画
    lda     _user_life_maximum
    jsr     @range
    ldy     #$02
    jsr     _GameDrawStatusLine

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

; 描画の引数
@draw_arg:
    .byte   $23, $01
    .word   $0000

.endproc

; 強さを描画する
;
.proc   GameDrawStatusStrength

    ; IN
    ;   a = 強さ
    ; WORK
    ;   GAME_0_WORK_0

    ; 値の調整
    sta     GAME_0_WORK_0
    asl     a
    clc
    adc     GAME_0_WORK_0

    ; ステータスバーの描画
    ldx     #$02
    ldy     #$05
    jsr     _GameDrawStatusBar

    ; 終了
    rts

.endproc

; 経験値を描画する
;
.proc   GameDrawStatusExperience

    ; IN
    ;   a = 経験値

    ; 値の調整
    and     #$ff
    beq     :+
    lsr     a
    lsr     a
    bne     :+
    lda     #$01
:

    ; ステータスバーの描画
    ldx     #$03
    ldy     #$08
    jsr     _GameDrawStatusBar

    ; 終了
    rts

.endproc

; ステータスバーを描画する
;
.global _GameDrawStatusBar
.proc   _GameDrawStatusBar

    ; IN
    ;   a = 値（0..30）
    ;   x = 色
    ;   y = Y 位置
    ; WORK
    ;   GAME_0_WORK_0..3

    ; 値の保存
    sta     @value

    ; 目盛りの取得
    lda     @scale_l, x
    sta     GAME_0_WORK_0
    lda     @scale_h, x
    sta     GAME_0_WORK_1

    ; VRAM アドレスの取得
    lda     _iocs_hgr_tile_y_address_low, y
    sta     GAME_0_WORK_2
    lda     _iocs_hgr_tile_y_address_high, y
    clc
    adc     #$08
    sta     GAME_0_WORK_3

    ; X 位置の取得
    lda     #$1f
    sta     @x

    ; 最初の 0..3 の描画
    lda     #$03
    sta     @maximum
    jsr     @range
    jsr     @draw
    lda     GAME_0_WORK_0
    clc
    adc     #$04
    sta     GAME_0_WORK_0
    bcc     :+
    inc     GAME_0_WORK_1
:

    ; 次から 7 単位での描画
    lda     #$07
    sta     @maximum
    lda     #$04
:
    pha
    jsr     @range
    pha
    jsr     @draw
    pla
    clc
    adc     #$08
    jsr     @draw
    pla
    sec
    sbc     #$01
    bne     :-

    ;   終了
    rts

    ; 0..@maximum の数値の取得
@range:
    lda     @value
    sec
    sbc     @maximum
    bcc     :+
    sta     @value
    lda     @maximum
    rts
:
    lda     @value
    pha
    lda     #$00
    sta     @value
    pla
    rts

    ; 1 メモリの描画
@draw:
    tay
    lda     (GAME_0_WORK_0), y
    ldx     #$06
:
    ldy     @x
    sta     (GAME_0_WORK_2), y
    inc     GAME_0_WORK_3
    inc     GAME_0_WORK_3
    inc     GAME_0_WORK_3
    inc     GAME_0_WORK_3
    dex
    bne     :-
    lda     GAME_0_WORK_3
    sec
    sbc     #($04 * $06)
    sta     GAME_0_WORK_3
    inc     @x
    rts

; 値
@value:
    .byte   $00

; 最大値
@maximum:
    .byte   $00

; X 位置
@x:
    .byte   $00

; 目盛り
@scale_l:
    .byte   <@scale_color_0
    .byte   <@scale_color_1
    .byte   <@scale_color_2
    .byte   <@scale_color_3
@scale_h:
    .byte   >@scale_color_0
    .byte   >@scale_color_1
    .byte   >@scale_color_2
    .byte   >@scale_color_3
@scale_color_0:
    .byte   %00000000, %00000010, %00001010, %00101010
    .byte   %00000000, %00000001, %00000101, %00010101, %01010101, %01010101, %01010101, %01010101
    .byte   %00000000, %00000000, %00000000, %00000000, %00000000, %00000010, %00001010, %00101010 
@scale_color_1:
    .byte   %00000000, %00000100, %00010100, %01010100
    .byte   %00000000, %00000010, %00001010, %00101010, %00101010, %00101010, %00101010, %00101010
    .byte   %00000000, %00000000, %00000000, %00000000, %00000001, %00000101, %00010101, %01010101
@scale_color_2:
    .byte   %10000000, %10000010, %10001010, %10101010
    .byte   %10000000, %10000001, %10000101, %10010101, %11010101, %11010101, %11010101, %11010101
    .byte   %10000000, %10000000, %10000000, %10000000, %10000000, %10000010, %10001010, %10101010 
@scale_color_3:
    .byte   %10000000, %10000100, %10010100, %11010100
    .byte   %10000000, %10000010, %10001010, %10101010, %10101010, %10101010, %10101010, %10101010
    .byte   %10000000, %10000000, %10000000, %10000000, %10000001, %10000101, %10010101, %11010101

.endproc

; ステータスの最大値を示す線を描画する
;
.global _GameDrawStatusLine
.proc   _GameDrawStatusLine

    ; IN
    ;   a = 値（0..30）
    ;   y = Y 位置
    ; WORK
    ;   GAME_0_WORK_0..3

    ; 範囲外は非表示
    cmp     #$1f
    bcs     @end

    ; 値の保存
    pha

    ; X 位置の取得
    lda     #$1f
    sta     @x

    ; VRAM アドレスの取得
    lda     _iocs_hgr_tile_y_address_low, y
    sta     GAME_0_WORK_2
    lda     _iocs_hgr_tile_y_address_high, y
    clc
    adc     #$08
    sta     GAME_0_WORK_3

    ; 最初の 0..3 の描画
    pla
    cmp     #$04
    bcs     @each_7

    ; 目盛りの取得
    pha
    lda     #<@scale_3
    sta     GAME_0_WORK_0
    lda     #>@scale_3
    sta     GAME_0_WORK_1
    pla

    ; 線の描画
    jsr     @draw
    jmp     @end

    ; 7 単位での描画
@each_7:
    inc     @x
    sec
    sbc     #$03
:
    cmp     #$08
    bcc     :+
    sec
    sbc     #$07
    inc     @x
    inc     @x
    jmp     :-
:

    ; 目盛りの取得
    pha
    lda     #<@scale_7
    sta     GAME_0_WORK_0
    lda     #>@scale_7
    sta     GAME_0_WORK_1
    pla

    ; 線の描画
    pha
    jsr     @draw
    pla
    clc
    adc     #$08
    inc     @x
    jsr     @draw

    ;   終了
@end:
    rts

    ; 1 目盛りの描画
@draw:
    tay
    lda     (GAME_0_WORK_0), y
    tax
    ldy     @x
    lda     #$06
:
    pha
    txa
    ora     (GAME_0_WORK_2), y
    sta     (GAME_0_WORK_2), y
    inc     GAME_0_WORK_3
    inc     GAME_0_WORK_3
    inc     GAME_0_WORK_3
    inc     GAME_0_WORK_3
    pla
    sec
    sbc     #$01
    bne     :-
    lda     GAME_0_WORK_3
    sec
    sbc     #($04 * $06)
    sta     GAME_0_WORK_3
    rts

; X 位置
@x:
    .byte   $00

; 目盛り
@scale_3:
    .byte   %00000000, %00000110, %00011000, %01100000
@scale_7:
    .byte   %00000000, %00000011, %00001100, %00110000, %01000000, %00000000, %00000000, %00000000
    .byte   %00000000, %00000000, %00000000, %00000000, %00000001, %00000110, %00011000, %01100000

.endproc

; 所持するアイテムを描画する
;
.proc   GameDrawUserItem

    ; WORK
    ;   GAME_0_WORK_0..1

    ; 描画の設定
    lda     #$1f
    sta     GAME_0_WORK_0
    lda     #$0a
    sta     GAME_0_WORK_1

    ; アイテムの描画
    ldx     #$00
@loop:
    cpx     #USER_ITEM_SIZE
    bcs     :+
    lda     _user_item, x
    bne     :+
    inx
    jmp     @loop
:
    txa
    pha
    ldx     GAME_0_WORK_0
    ldy     GAME_0_WORK_1
    jsr     _UserDrawItem
    lda     GAME_0_WORK_0
    clc
    adc     #$02
    cmp     #($1f + $02 * $04)
    bne     :+
    inc     GAME_0_WORK_1
    inc     GAME_0_WORK_1
    lda     #$1f
:
    sta     GAME_0_WORK_0
    pla
    tax
    inx
    lda     GAME_0_WORK_1
    cmp     #($0a + $02 * $03)
    bne     @loop

    ; 終了
    rts

.endproc

; アイテムを点滅させる
;
.proc   GameBlinkUserItem

    ; IN
    ;   a = アイテム
    ; WORK
    ;   GAME_0_WORK_0..2

    ; アイテムの存在
    tax
    lda     _user_item, x
    beq     @end
    stx     GAME_0_WORK_0

    ; 位置の取得
    ldx     #$00
    ldy     #$00
:
    cpx     GAME_0_WORK_0
    beq     :++
    lda     _user_item, x
    beq     :+
    iny
:
    inx
    jmp     :--
:
    tya
    and     #$03
    asl     a
    clc
    adc     #$1f
    sta     GAME_0_WORK_1
    tya
    and     #$0c
    lsr     a
    clc
    adc     #$0a
    sta     GAME_0_WORK_2

    ; 点滅
    lda     #$03
:
    pha

    ; 明滅／滅
    ldx     GAME_0_WORK_1
    ldy     GAME_0_WORK_2
    lda     #$ff
    jsr     _UserDrawItem
    lda     #IOCS_BEEP_L32p
    jsr     _IocsBeepRest

    ; 明滅／明
    ldx     GAME_0_WORK_1
    ldy     GAME_0_WORK_2
    lda     GAME_0_WORK_0
    jsr     _UserDrawItem
    ldx     #IOCS_BEEP_O5F
    lda     #IOCS_BEEP_L32p
    jsr     _IocsBeepNote

    ; 点滅の繰り返し
    pla
    sec
    sbc     #$01
    bne     :-

    ; 終了
@end:
    rts

.endproc

; 情報をクリアする
;
.global _GameClearInformation
.proc   _GameClearInformation

    ; 空白文字でクリア
    lda     #$11
    sta     @draw_arg + $0001
:
    ldx     #<@draw_arg
    lda     #>@draw_arg
    jsr     _IocsDrawString
    inc     @draw_arg + $0001
    lda     @draw_arg + $0001
    cmp     #$17
    bne     :-

    ; 終了
    rts

; 描画の引数
@draw_arg:
    .byte   $1f, $11
    .word   @draw_string
@draw_string:
    .asciiz "         "

.endproc

; エネミーの生成
;

; 生成するクラス
game_spawn_class_field:

    .byte   ACTOR_CLASS_SLIME       ; %0000 : OUTSIDE, GRASS
    .byte   ACTOR_CLASS_LIZARD
    .byte   ACTOR_CLASS_LIZARD
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_SKELETON    ; %0001 : OUTSIDE, DIRT
    .byte   ACTOR_CLASS_SKELETON
    .byte   ACTOR_CLASS_LIZARD
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_SERPENT     ; %0010 : OUTSIDE, SAND
    .byte   ACTOR_CLASS_SERPENT
    .byte   ACTOR_CLASS_LIZARD
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_NULL        ; %0011 : OUTSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_SPIDER      ; %0100 : OUTSIDE, FOREST
    .byte   ACTOR_CLASS_LIZARD
    .byte   ACTOR_CLASS_LIZARD
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_NULL        ; %0101 : OUTSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL        ; %0110 : OUTSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL        ; %0111 : OUTSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_SLIME       ; %1000 : INSIDE, GRASS
    .byte   ACTOR_CLASS_SLIME
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_SKELETON    ; %1001 : INSIDE, DIRT
    .byte   ACTOR_CLASS_SKELETON
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_SERPENT     ; %1010 : INSIDE, SAND
    .byte   ACTOR_CLASS_SERPENT
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_NULL        ; %1011 : INSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_SPIDER      ; %1100 : INSIDE, FOREST
    .byte   ACTOR_CLASS_SPIDER
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_ORC
    .byte   ACTOR_CLASS_NULL        ; %1101 : INSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL        ; %1110 : INSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL        ; %1111 : INSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL

game_spawn_class_dungeon:

    .byte   ACTOR_CLASS_CYCLOPSE    ; %0000 : OUTSIDE, GRASS
    .byte   ACTOR_CLASS_PHANTOM
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_PHANTOM     ; %0001 : OUTSIDE, DIRT
    .byte   ACTOR_CLASS_PHANTOM
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_CYCLOPSE    ; %0010 : OUTSIDE, SAND
    .byte   ACTOR_CLASS_CYCLOPSE
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_NULL        ; %0011 : OUTSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_ZORN        ; %0100 : OUTSIDE, FOREST
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_NULL        ; %0101 : OUTSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL        ; %0110 : OUTSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL        ; %0111 : OUTSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_ZORN        ; %1000 : INSIDE, GRASS
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_PHANTOM     ; %1001 : INSIDE, DIRT
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_CYCLOPSE    ; %1010 : INSIDE, SAND
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_NULL        ; %1011 : INSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_ZORN        ; %1100 : INSIDE, FOREST
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_NULL        ; %1101 : INSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL        ; %1110 : INSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL        ; %1111 : INSIDE, -
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL
    .byte   ACTOR_CLASS_NULL

game_spawn_class_sword:

    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_BAT
    .byte   ACTOR_CLASS_ZORN
    .byte   ACTOR_CLASS_PHANTOM
    .byte   ACTOR_CLASS_CYCLOPSE
    .byte   ACTOR_CLASS_WIZARD
    .byte   ACTOR_CLASS_HYDRA
    .byte   ACTOR_CLASS_DEVIL


; データの定義
;
.segment    "BSS"

; ゲームの情報
;

; エリア
.global _game_area
_game_area:

    .res    $01

.global _game_area_exit
_game_area_exit:

    .res    $01

; レイヤ
.global _game_layer
_game_layer:

    .res    $01

.global _game_layer_exit
_game_layer_exit:

    .res        $01

; イベント
.global _game_event_x
_game_event_x:

    .res        $01

.global _game_event_y
_game_event_y:

    .res        $01

; クリア
.global _game_clear
_game_clear:

    .res        $01

; 入り方
game_enter:

    .res        $01

; エネミーの生成
game_spawn_count:

    .res        $01

; 速度
game_speed:

    .res        $01

; チート
.global _game_cheat_nodamage
_game_cheat_nodamage:

    .res        $01

