; world.inc - ワールド
; 


; ゼロページ
;
WORLD_0                                 :=  $10

; WORK
WORLD_0_WORK_0                          :=  $1c
WORLD_0_WORK_1                          :=  $1d
WORLD_0_WORK_2                          :=  $1e
WORLD_0_WORK_3                          :=  $1f

; LAYOUT AREA
WORLD_0_LAYOUT_AERA_X                   :=  $10
WORLD_0_LAYOUT_AERA_Y                   :=  $11

; ID
;
WORLD_ID_SIZE                           =   $02

; エリア
;
WORLD_AREA_SIZE_X                       =   5
WORLD_AREA_SIZE_Y                       =   5
WORLD_AREA_CELL_SIZE_X                  =   15
WORLD_AREA_CELL_SIZE_Y                  =   11
WORLD_AREA_CELL_TILE_SIZE_X             =   2
WORLD_AREA_CELL_TILE_SIZE_Y             =   2
WORLD_AREA_TILE_SIZE_X                  =   30
WORLD_AREA_TILE_SIZE_Y                  =   22
WORLD_AREA_INSIDE                       =   $80
WORLD_AREA_INSIDE_SIZE                  =   8
WORLD_AREA_EVENT_MASK                   =   $0f
WORLD_AREA_LAND_MASK                    =   $70

; レイヤ
;
WORLD_LAYER_FIELD                       =   $00
WORLD_LAYER_DUNGEON                     =   $01

; フィールド
;
WORLD_FIELD_CELL_SIZE_X                 =   70
WORLD_FIELD_CELL_SIZE_Y                 =   50
WORLD_FIELD_TILE_SIZE_X                 =   140
WORLD_FIELD_TILE_SIZE_Y                 =   100
WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_X     =   14
WORLD_FIELD_AREA_2BLOCK_CELL_SIZE_Y     =   10
WORLD_FIELD_BLOCK_SIZE_X                =   10
WORLD_FIELD_BLOCK_SIZE_Y                =   10
WORLD_FIELD_BLOCK_CELL_SIZE_X           =   7
WORLD_FIELD_BLOCK_CELL_SIZE_Y           =   5

; フィールド／ブロック
WORLD_FIELD_BLOCK_LAND_GRASS            =   $00
WORLD_FIELD_BLOCK_LAND_DIRT             =   $01
WORLD_FIELD_BLOCK_LAND_SAND             =   $02
WORLD_FIELD_BLOCK_LAND_FOREST           =   $04
WORLD_FIELD_BLOCK_LAND_MASK             =   $07
WORLD_FIELD_BLOCK_LOCK                  =   $80
WORLD_FIELD_BLOCK_SIZE_DIRT_EXPAND      =   11
WORLD_FIELD_BLOCK_SIZE_DIRT_RANDOM      =   5
WORLD_FIELD_BLOCK_SIZE_SAND             =   20
WORLD_FIELD_BLOCK_SIZE_FOREST_EXPAND    =   13
WORLD_FIELD_BLOCK_SIZE_FOREST_RANDOM    =   19

; ダンジョン
;

; ダンジョン／リンク
WORLD_DUNGEON_LINK_NULL                 =   $00
WORLD_DUNGEON_LINK_UP                   =   $01
WORLD_DUNGEON_LINK_DOWN                 =   $02
WORLD_DUNGEON_LINK_LEFT                 =   $04
WORLD_DUNGEON_LINK_RIGHT                =   $08
WORLD_DUNGEON_LINK_LOCK                 =   $80
WORLD_DUNGEON_LINK_EXIT_SIZE            =   $05

; ダンジョン／セル

; セル
;
WORLD_CELL_FIELD                        =   $00
WORLD_CELL_FIELD_MASK                   =   $1f
WORLD_CELL_DUNGEON                      =   $20
WORLD_CELL_DUNGEON_MASK                 =   $e0
WORLD_CELL_GRASS                        =   $00
WORLD_CELL_DIRT                         =   $01
WORLD_CELL_SAND                         =   $02
WORLD_CELL_PAVE                         =   $03
WORLD_CELL_FOREST                       =   $04
WORLD_CELL_FOREST_THICK_U               =   $05
WORLD_CELL_FOREST_THICK_D               =   $06
WORLD_CELL_FOREST_THICK_UD              =   $07
WORLD_CELL_TREE                         =   $08
WORLD_CELL_ROCK                         =   $09
WORLD_CELL_CACTUS                       =   $0a
WORLD_CELL_STAIRS_DOWN                  =   $0b
WORLD_CELL_BOX                          =   $0c
WORLD_CELL_SWORD                        =   $0d
WORLD_CELL_0E                           =   $0e
WORLD_CELL_0F                           =   $0f
WORLD_CELL_WATER_0000                   =   $10
WORLD_CELL_WATER_1000                   =   $11
WORLD_CELL_WATER_0100                   =   $12
WORLD_CELL_WATER_1100                   =   $13
WORLD_CELL_WATER_0010                   =   $14
WORLD_CELL_WATER_1010                   =   $15
WORLD_CELL_WATER_0110                   =   $16
WORLD_CELL_WATER_1110                   =   $17
WORLD_CELL_WATER_0001                   =   $18
WORLD_CELL_WATER_1001                   =   $19
WORLD_CELL_WATER_0101                   =   $1a
WORLD_CELL_WATER_1101                   =   $1b
WORLD_CELL_WATER_0011                   =   $1c
WORLD_CELL_WATER_1011                   =   $1d
WORLD_CELL_WATER_0111                   =   $1e
WORLD_CELL_WATER_1111                   =   $1f
WORLD_CELL_GROUND                       =   $20
WORLD_CELL_POISON                       =   $21
WORLD_CELL_WALL                         =   $22
WORLD_CELL_STAIRS_UP                    =   $23
WORLD_CELL_SEAL                         =   $24
WORLD_CELL_FLOOR                        =   $25

; セルの属性
WORLD_CELL_ATTRIBUTE_NULL               =   %00000000
WORLD_CELL_ATTRIBUTE_SPAWN              =   %00000001

; タイル
;
WORLD_TILE_GRASS_L                      =   $00
WORLD_TILE_GRASS_R                      =   $01
WORLD_TILE_DIRT_L                       =   $02
WORLD_TILE_DIRT_R                       =   $03
WORLD_TILE_SAND_L                       =   $04
WORLD_TILE_SAND_R                       =   $05
WORLD_TILE_FOREST_UL                    =   $06
WORLD_TILE_FOREST_UR                    =   $07
WORLD_TILE_FOREST_DL                    =   $08
WORLD_TILE_FOREST_DR                    =   $09
WORLD_TILE_FOREST_THICK_L               =   $0a
WORLD_TILE_FOREST_THICK_R               =   $0b
WORLD_TILE_WATER_L                      =   $0c
WORLD_TILE_WATER_R                      =   $0d
WORLD_TILE_WALL_L                       =   $0e
WORLD_TILE_WALL_R                       =   $0f
WORLD_TILE_TREE_UL                      =   $10
WORLD_TILE_TREE_UR                      =   $11
WORLD_TILE_TREE_DL                      =   $12
WORLD_TILE_TREE_DR                      =   $13
WORLD_TILE_ROCK_UL                      =   $14
WORLD_TILE_ROCK_UR                      =   $15
WORLD_TILE_ROCK_DL                      =   $16
WORLD_TILE_ROCK_DR                      =   $17
WORLD_TILE_CACTUS_UL                    =   $18
WORLD_TILE_CACTUS_UR                    =   $19
WORLD_TILE_CACTUS_DL                    =   $1a
WORLD_TILE_CACTUS_DR                    =   $1b
WORLD_TILE_PAVE_L                       =   $1c
WORLD_TILE_PAVE_R                       =   $1d
WORLD_TILE_NULL_L                       =   $1e
WORLD_TILE_NULL_R                       =   $1f
WORLD_TILE_STAIRS_DOWN_UL               =   $20
WORLD_TILE_STAIRS_DOWN_UR               =   $21
WORLD_TILE_STAIRS_DOWN_DL               =   $22
WORLD_TILE_STAIRS_DOWN_DR               =   $23
WORLD_TILE_BOX_UL                       =   $24
WORLD_TILE_BOX_UR                       =   $25
WORLD_TILE_BOX_DL                       =   $26
WORLD_TILE_BOX_DR                       =   $27
WORLD_TILE_SWORD_UL                     =   $28
WORLD_TILE_SWORD_UR                     =   $29
WORLD_TILE_SWORD_DL                     =   $2a
WORLD_TILE_SWORD_DR                     =   $2b
WORLD_TILE_2C                           =   $2c
WORLD_TILE_2D                           =   $2d
WORLD_TILE_2E                           =   $2e
WORLD_TILE_2F                           =   $2f
WORLD_TILE_GROUND_L                     =   $30
WORLD_TILE_GROUND_R                     =   $31
WORLD_TILE_POISON_L                     =   $32
WORLD_TILE_POISON_R                     =   $33
WORLD_TILE_WALL_UL                      =   $34
WORLD_TILE_WALL_UR                      =   $35
WORLD_TILE_WALL_DL                      =   $36
WORLD_TILE_WALL_DR                      =   $37
WORLD_TILE_STAIRS_UP_UL                 =   $38
WORLD_TILE_STAIRS_UP_UR                 =   $39
WORLD_TILE_STAIRS_UP_DL                 =   $3a
WORLD_TILE_STAIRS_UP_DR                 =   $3b
WORLD_TILE_SEAL_UL                      =   $3c
WORLD_TILE_SEAL_UR                      =   $3d
WORLD_TILE_SEAL_DL                      =   $3e
WORLD_TILE_SEAL_DR                      =   $3f

; タイルの属性
WORLD_TILE_ATTRIBUTE_NULL               =   %00000000
WORLD_TILE_ATTRIBUTE_COLLISION          =   %00000001
WORLD_TILE_ATTRIBUTE_HIDE               =   %00000010
WORLD_TILE_ATTRIBUTE_STAIRS             =   %00000100
WORLD_TILE_ATTRIBUTE_BOX                =   %00001000
WORLD_TILE_ATTRIBUTE_REST               =   %00010000
WORLD_TILE_ATTRIBUTE_SLOW               =   %00100000
WORLD_TILE_ATTRIBUTE_HEAT               =   %01000000
WORLD_TILE_ATTRIBUTE_HURT               =   %10000000

; イベント
;
WORLD_EVENT_NULL                        =   $00
WORLD_EVENT_START                       =   $01
WORLD_EVENT_STAIRS                      =   $02
WORLD_EVENT_SWORD                       =   $03
WORLD_EVENT_BOOTS                       =   $04
WORLD_EVENT_CLOAK                       =   $05
WORLD_EVENT_MASK                        =   $06
WORLD_EVENT_KEY                         =   $07
WORLD_EVENT_TORCH                       =   $08
WORLD_EVENT_TALISMAN                    =   $09
WORLD_EVENT_AMULET                      =   $0a
WORLD_EVENT_POTION                      =   $0b
WORLD_EVENT_CRYSTAL_RED                 =   $0c
WORLD_EVENT_CRYSTAL_BLUE                =   $0d
WORLD_EVENT_CRYSTAL_GREEN               =   $0e

; 地形
WORLD_LAND_GRASS                        =   $00
WORLD_LAND_DIRT                         =   $10
WORLD_LAND_SAND                         =   $20
WORLD_LAND_FOREST                       =   $40

; 描画
;
WORLD_DRAW_X                            =   $00
WORLD_DRAW_Y                            =   $01
WORLD_DRAW_CENTER                       =   $00
WORLD_DRAW_UP_DOWN                      =   $01
WORLD_DRAW_DOWN_UP                      =   $02
WORLD_DRAW_LEFT_RIGHT                   =   $03
WORLD_DRAW_RIGHT_LEFT                   =   $04

