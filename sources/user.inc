; user.inc - ユーザ
; 


; ゼロページ
;


; ID
;
USER_ID_SIZE                            =   $02

; 体力
;
USER_LIFE_DEFAULT                       =   30
USER_LIFE_MAXIMUM                       =   120
USER_LIFE_LEVELUP                       =   10
USER_LIFE_SIZE                          =   $01

; 強さ
;
USER_STRENGTH_DEFAULT                   =   1
USER_STRENGTH_MAXIMUM                   =   10
USER_STRENGTH_SIZE                      =   $01

; 経験値
;
USER_EXPERIENCE_DEFAULT                 =   0
USER_EXPERIENCE_MAXIMUM                 =   120
USER_EXPERIENCE_SIZE                    =   $01

; アイテム
;
USER_ITEM_SWORD                         =   $00
USER_ITEM_BOOTS                         =   $01
USER_ITEM_CLOAK                         =   $02
USER_ITEM_MASK                          =   $03
USER_ITEM_TALISMAN                      =   $04
USER_ITEM_AMULET                        =   $05
USER_ITEM_KEY                           =   $06
USER_ITEM_TORCH                         =   $07
USER_ITEM_POTION                        =   $08
USER_ITEM_CRYSTAL_RED                   =   $09
USER_ITEM_CRYSTAL_BLUE                  =   $0a
USER_ITEM_CRYSTAL_GREEN                 =   $0b
USER_ITEM_SIZE                          =   $0c

; イベント
;
USER_EVENT_SIZE                         =   $05 * $05

; 位置
;
USER_X_START                            =   $07 * $02
USER_Y_START                            =   $05 * $02

; 向き
;
USER_DIRECTION_START                    =   $01
