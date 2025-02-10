; title.inc - タイトル
; 


; ゼロページ
;
TITLE_0                             :=  APP0_0_USER

; DRAW FRAME
TITLE_0_DRAW_FRAME_PARAM            :=  TITLE_0 + $00
TITLE_0_DRAW_FRAME_PARAM_L          :=  TITLE_0 + $00
TITLE_0_DRAW_FRAME_PARAM_H          :=  TITLE_0 + $01
TITLE_0_DRAW_FRAME_Y                :=  TITLE_0 + $02
TITLE_0_DRAW_FRAME_SIZE             :=  TITLE_0 + $03

; タイトル情報
;
.struct Title

    ; ファイル
    file            .byte

.endstruct
