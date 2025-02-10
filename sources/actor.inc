; actor.inc - アクタ
; 


; ゼロページ
;
ACTOR_0                                 :=  APP2_0_USER

; 参照
ACTOR_0_X                               :=  APP2_0_USER_END - $05
ACTOR_0_Y                               :=  APP2_0_USER_END - $04

; WORK
ACTOR_0_WORK_0                          :=  APP2_0_USER_END - $03
ACTOR_0_WORK_1                          :=  APP2_0_USER_END - $02
ACTOR_0_WORK_2                          :=  APP2_0_USER_END - $01
ACTOR_0_WORK_3                          :=  APP2_0_USER_END - $00

; RANDOM POSITION
ACTOR_0_RANDOM_POSITION_SELF            :=  ACTOR_0 + $00
ACTOR_0_RANDOM_POSITION_SELF_CLASS      :=  ACTOR_0 + $01
ACTOR_0_RANDOM_POSITION_CELL_START      :=  ACTOR_0 + $02
ACTOR_0_RANDOM_POSITION_CELL_INDEX      :=  ACTOR_0 + $03
ACTOR_0_RANDOM_POSITION_CELL_X          :=  ACTOR_0 + $04
ACTOR_0_RANDOM_POSITION_CELL_Y          :=  ACTOR_0 + $05
ACTOR_0_RANDOM_POSITION_SELF_X_0        :=  ACTOR_0 + $06
ACTOR_0_RANDOM_POSITION_SELF_Y_0        :=  ACTOR_0 + $07
ACTOR_0_RANDOM_POSITION_SELF_X_1        :=  ACTOR_0 + $08
ACTOR_0_RANDOM_POSITION_SELF_Y_1        :=  ACTOR_0 + $09
ACTOR_0_RANDOM_POSITION_SOME_X_0        :=  ACTOR_0 + $0a
ACTOR_0_RANDOM_POSITION_SOME_Y_0        :=  ACTOR_0 + $0b
ACTOR_0_RANDOM_POSITION_SOME_X_1        :=  ACTOR_0 + $0c
ACTOR_0_RANDOM_POSITION_SOME_Y_1        :=  ACTOR_0 + $0d

; MOVE
ACTOR_0_MOVE_X                          :=  ACTOR_0 + $00
ACTOR_0_MOVE_Y                          :=  ACTOR_0 + $01
ACTOR_0_MOVE_SIZE                       :=  ACTOR_0 + $02

; HIT
ACTOR_0_HIT_SELF                        :=  ACTOR_0 + $00
ACTOR_0_HIT_SELF_X_0                    :=  ACTOR_0 + $01
ACTOR_0_HIT_SELF_Y_0                    :=  ACTOR_0 + $02
ACTOR_0_HIT_SELF_X_1                    :=  ACTOR_0 + $03
ACTOR_0_HIT_SELF_Y_1                    :=  ACTOR_0 + $04
ACTOR_0_HIT_COUNT                       :=  ACTOR_0 + $05

; DAMAGE
ACTOR_0_DAMAGE_SELF                     :=  ACTOR_0 + $00
ACTOR_0_DAMAGE_SELF_CLASS               :=  ACTOR_0 + $01
ACTOR_0_DAMAGE_TYPE                     :=  ACTOR_0 + $02
ACTOR_0_DAMAGE_COUNT                    :=  ACTOR_0 + $03
ACTOR_0_DAMAGE_PROC                     :=  ACTOR_0 + $04
ACTOR_0_DAMAGE_PROC_L                   :=  ACTOR_0 + $04
ACTOR_0_DAMAGE_PROC_H                   :=  ACTOR_0 + $05
ACTOR_0_DAMAGE_EXPERIENCE               :=  ACTOR_0 + $06

; BLANK
ACTOR_0_BLANK_X_0                       :=  ACTOR_0 + $00
ACTOR_0_BLANK_Y_0                       :=  ACTOR_0 + $01
ACTOR_0_BLANK_X_1                       :=  ACTOR_0 + $02
ACTOR_0_BLANK_Y_1                       :=  ACTOR_0 + $03
ACTOR_0_BLANK_DIRECTION                 :=  ACTOR_0 + $04
ACTOR_0_BLANK_SOME_X_0                  :=  ACTOR_0 + $05
ACTOR_0_BLANK_SOME_Y_0                  :=  ACTOR_0 + $06
ACTOR_0_BLANK_SOME_X_1                  :=  ACTOR_0 + $07
ACTOR_0_BLANK_SOME_Y_1                  :=  ACTOR_0 + $08

; アクタ
;
ACTOR_SIZE                              =   11
ACTOR_CYCLE_MASK                        =   %00000111

; 種類
ACTOR_TYPE_NULL                         =   $00
ACTOR_TYPE_PLAYER                       =   $01
ACTOR_TYPE_ENEMY                        =   $02
ACTOR_TYPE_MAGIC                        =   $03

; クラス
ACTOR_CLASS_NULL                        =   $00
ACTOR_CLASS_PLAYER                      =   $01
ACTOR_CLASS_ORC                         =   $02
ACTOR_CLASS_LIZARD                      =   $03
ACTOR_CLASS_SLIME                       =   $04
ACTOR_CLASS_SKELETON                    =   $05
ACTOR_CLASS_SERPENT                     =   $06
ACTOR_CLASS_SPIDER                      =   $07
ACTOR_CLASS_GREMLIN                     =   $08
ACTOR_CLASS_BAT                         =   $09
ACTOR_CLASS_ZORN                        =   $0a
ACTOR_CLASS_PHANTOM                     =   $0b
ACTOR_CLASS_CYCLOPSE                    =   $0c
ACTOR_CLASS_WIZARD                      =   $0d
ACTOR_CLASS_HYDRA                       =   $0e
ACTOR_CLASS_DEVIL                       =   $0f
ACTOR_CLASS_DRAGON                      =   $10
ACTOR_CLASS_TREE                        =   $11
ACTOR_CLASS_ROCK                        =   $12
ACTOR_CLASS_CACTUS                      =   $13
ACTOR_CLASS_BALL_PLAYER                 =   $14
ACTOR_CLASS_BALL_ZORN                   =   $15
ACTOR_CLASS_BALL_WIZARD                 =   $16
ACTOR_CLASS_BALL_HYDRA                  =   $17
ACTOR_CLASS_BALL_DEVIL                  =   $18
ACTOR_CLASS_BALL_DRAGON                 =   $19

; 向き
ACTOR_DIRECTION_UP                      =   $00
ACTOR_DIRECTION_DOWN                    =   $01
ACTOR_DIRECTION_LEFT                    =   $02
ACTOR_DIRECTION_RIGHT                   =   $03

; 速度
ACTOR_SPEED_FAST                        =   %00000000
ACTOR_SPEED_NORMAL                      =   %00000001
ACTOR_SPEED_SLOW                        =   %00000011
ACTOR_SPEED_SLOWER                      =   %00000111
ACTOR_SPEED_SPAWN                       =   %00000001

; 移動
ACTOR_MOVE_NULL                         =   %00000000
ACTOR_MOVE_ON                           =   %00000001
ACTOR_MOVE_ED                           =   %00000010
ACTOR_MOVE_BLOCK                        =   %00000100
ACTOR_MOVE_STOMP                        =   %00001000
ACTOR_MOVE_START                        =   %10000000

; アニメーション
ACTOR_ANIMATION_FRAME                   =   %00001000

; 描画
ACTOR_DRAW_NULL                         =   %00000000
ACTOR_DRAW_LAND                         =   %00000001
ACTOR_DRAW_BACK                         =   %00000010
ACTOR_DRAW_DIRECTION                    =   %10000000

; パラメータ
ACTOR_PARAM_SIZE                        =   8

; クラス別のアクタ
;

; プレイヤ
ACTOR_PLAYER_REST                       =   12
ACTOR_PLAYER_HEAT                       =   6
ACTOR_PLAYER_HURT                       =   2

; オーク
ACTOR_ORC_COUNTER                       =   2

; リザード
ACTOR_LIZARD_COUNTER                    =   1

; スライム
ACTOR_SLIME_COUNTER                     =   99

; スケルトン
ACTOR_SKELETON_COUNTER                  =   1

; サーペント
ACTOR_SERPENT_COUNTER                   =   1
ACTOR_SERPENT_STAY                      =   4
ACTOR_SERPENT_DIVE                      =   4
ACTOR_SERPENT_TILE                      =   $80

; スパイダー
ACTOR_SPIDER_COUNTER                    =   99

; グレムリン
ACTOR_GREMLIN_COUNTER                   =   1

; バット
ACTOR_BAT_COUNTER                       =   99

; ゾーン
ACTOR_ZORN_COUNTER                      =   2

; ファントム
ACTOR_PHANTOM_COUNTER                   =   1

; サイクロプス
ACTOR_CYCLOPSE_COUNTER                  =   1

; ウィザード
ACTOR_WIZARD_COUNTER                    =   99
ACTOR_WIZARD_BLINK                      =   9

; ヒドラ
ACTOR_HYDRA_COUNTER                     =   1
ACTOR_HYDRA_STAY                        =   1

; デビル
ACTOR_DEVIL_COUNTER                     =   1

; ドラゴン
ACTOR_DRAGON_COUNTER                    =   1
ACTOR_DRAGON_STAY                       =   1

; ツリー
ACTOR_TREE_COUNTER                      =   99

; ロック
ACTOR_ROCK_COUNTER                      =   99

; サボテン
ACTOR_CACTUS_COUNTER                    =   99

; マジックボール

; エフェクト
;
ACTOR_EFFECT_BLACK                      =   $00
ACTOR_EFFECT_WHITE                      =   $01
ACTOR_EFFECT_SPAWN_0                    =   $02
ACTOR_EFFECT_SPAWN_1                    =   $03
ACTOR_EFFECT_SPAWN_2                    =   $04
ACTOR_EFFECT_BALL_0                     =   $05
ACTOR_EFFECT_BALL_1                     =   $06
