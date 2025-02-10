; iocs.s - Input/Output Control System
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


; コードの定義
;
.segment    "BOOT"

; IOCS を初期化する
;
.global _IocsInitialize
.proc   _IocsInitialize

    ; スタックの設定
;   tsx
;   stx     IOCS_0_STACK_L
;   lda     #$01
;   sta     IOCS_0_STACK_H

    ; FILE MANAGER PARAMETER LIST の取得
    lda     #$0e
    sta     IOCS_0_DOS_PARAM_L
    lda     DOSWARM + $0002
    sta     IOCS_0_DOS_PARAM_H
    ldy     #$00
    lda     (IOCS_0_DOS_PARAM), y
    tax
    iny
    lda     (IOCS_0_DOS_PARAM), y
    stx     IOCS_0_DOS_PARAM_L
    sta     IOCS_0_DOS_PARAM_H

    ; キーコードの初期化
    lda     #$00
    sta     IOCS_0_KEYCODE

    ; 乱数の初期化
    lda     #$24
    sta     IOCS_0_RANDOM_L
    lda     #$20
    sta     IOCS_0_RANDOM_H

    ; BEEP の初期化
.if     ::IOCS_BEEP
    lda     #$00
    sta     IOCS_0_BEEP_L
    sta     IOCS_0_BEEP_H
    sta     IOCS_0_BEEP_INDEX
    sta     IOCS_0_BEEP_COUNT
.endif

    ; カーソル位置を最下行に設定
    lda     #23
    sta     CV
    lda     #0
    sta     CH

    ; 終了
    rts

.endproc

; IOCS を更新する
;
.global _IocsUpdate
.proc   _IocsUpdate

    ; キーコードの取得
    lda     KBD
    bpl     :+
    sta     KBDSTRB
    and     #$7f
    jmp     :++
:
    lda     #$00
:
    sta     IOCS_0_KEYCODE

    ; 乱数の更新
    jsr     _IocsGetRandomNumber

    ; BEEP の再生
.if     ::IOCS_BEEP
    lda     IOCS_0_BEEP_L
    ora     IOCS_0_BEEP_H
    beq     @beep_end
    lda     IOCS_0_BEEP_COUNT
    bne     @beep_count
    ldy     IOCS_0_BEEP_INDEX
    lda     (IOCS_0_BEEP), y
    tax
    lda     #_L256
    cpx     #IOCS_BEEP_END
    bne     :+
    lda     #$00
    sta     IOCS_0_BEEP_L
    sta     IOCS_0_BEEP_H
    jmp     @beep_end
:
    cpx     #_R
    beq     :+
    jsr     _IocsBeepNote
    jmp     :++
:
    jsr     _IocsBeepRest
:
    ldy     IOCS_0_BEEP_INDEX
    iny
    lda     (IOCS_0_BEEP), y
    sta     IOCS_0_BEEP_COUNT
    iny
    sty     IOCS_0_BEEP_INDEX
@beep_count:
    dec     IOCS_0_BEEP_COUNT
@beep_end:
.endif

    ; 終了
    rts

.endproc

; CATALOG を実行する
;
.if     IOCS_CATALOG
.global _IocsCatalog
.proc   _IocsCatalog

    ; OUT
    ;   a = 0...成功 / else...エラーコード

    ; DOS BUFFER の取得
    jsr     IocsUseDosBuffer

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; FILE MANAGER PARAMETER LIST の設定
    ldy     #DosParamCatalog::call
    lda     #$06
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosParamCatalog::drive
    lda     DOS_DEFAULT_DRIVE
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosParamCatalog::slot
    lda     DOS_DEFAULT_SLOT
    sta     (IOCS_0_DOS_PARAM), y

    ; DOS BUFFER アドレスの設定
    jsr     IocsSetDosBufferAddress

    ; CATALOG の呼び出し
    jsr     DOSCALL

    ; DOS BUFFER の解放
    jsr     IocsUnuseDosBuffer

    ; 返り値の取得
    ldy     #DosParamCatalog::return_code
    lda     (IOCS_0_DOS_PARAM), y

    ; 終了
    rts

.endproc
.endif

; バイナリファイルを読み込む
;
.global _IocsBload
.proc   _IocsBload

    ; IN
    ;   ax[0..1] = ファイル名
    ;   ax[2..3] = 読み込み先
    ; OUT
    ;   a = 0...成功 / else...エラーコード

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; ファイル名の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_H

    ; リトライのエントリポイント
@retry:

    ; ファイルを開く
    lda     #$04
    ldx     #$01
    jsr     IocsOpen
    tax
    bne     @error

    ; ヘッダの読み込み
    lda     #<IOCS_0_DOS_HEADER
    sta     IOCS_0_DOS_ADDRESS_L
    lda     #>IOCS_0_DOS_HEADER
    sta     IOCS_0_DOS_ADDRESS_H
    lda     #<$0004
    sta     IOCS_0_DOS_LENGTH_L
    lda     #>$0004
    sta     IOCS_0_DOS_LENGTH_H
    jsr     IocsLoad
    tax
    bne     @close

    ; アドレスの取得
    ldy     #$02
    lda     (IOCS_0_ARG), y
    iny
    ora     (IOCS_0_ARG), y
    beq     :+
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_ADDRESS_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_ADDRESS_H
:
    
    ; データの読み込み
    jsr     IocsLoad
    tax
    bne     @close

    ; ファイルを閉じる
    jsr     IocsClose
    tax
    bne     @error

    ; 終了
    rts

    ; エラー
@close:
    jsr     IocsClose
@error:
    jsr     IocsDiskError
    cmp     #$1b
    bne     @retry
    rts

.endproc

; バイナリファイルを書き込む
;
.global _IocsBsave
.proc   _IocsBsave

    ; IN
    ;   ax[0..1] = ファイル名
    ;   ax[2..3] = 書き込み元
    ;   ax[4..5] = 書き込むバイト数
    ; OUT
    ;   a = 0...成功 / else...エラーコード

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; ファイル名の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_H

    ; リトライのエントリポイント
@retry:

    ; ファイルを開く
    lda     #$04
    sta     IOCS_0_DOS_FILETYPE
    lda     #$00
    sta     IOCS_0_DOS_FLAG
    jsr     IocsOpen
    tax
    bne     @error

    ; ヘッダの書き込み
    lda     IOCS_0_ARG_L
    clc
    adc     #$02
    sta     IOCS_0_DOS_ADDRESS_L
    lda     IOCS_0_ARG_H
    adc     #$00
    sta     IOCS_0_DOS_ADDRESS_H
    lda     #<$0004
    sta     IOCS_0_DOS_LENGTH_L
    lda     #>$0004
    sta     IOCS_0_DOS_LENGTH_H
    jsr     IocsSave
    tax
    bne     @close
    
    ; データの書き込み
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_ADDRESS_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_ADDRESS_H
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_LENGTH_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_LENGTH_H
    jsr     IocsSave
    tax
    bne     @close

    ; ファイルを閉じる
    jsr     IocsClose
    tax
    bne     @error

    ; 終了
    rts

    ; エラー
@close:
    jsr     IocsClose
@error:
    jsr     IocsDiskError
    cmp     #$1b
    bne     @retry
    rts

.endproc

; バイナリファイルを実行する
;
.global _IocsBrun
.proc   _IocsBrun

    ; IN
    ;   ax[0..1] = ファイル名
    ;   ax[2..3] = 読み込み/ジャンプ先

    ; ファイルの読み込み
    jsr     _IocsBload

    ; 実行
    jmp     (IOCS_0_DOS_ADDRESS)

.endproc

; ファイルの存在を確認する
;
.global _IocsAccess
.proc   _IocsAccess

    ; IN
    ;   ax[0..1] = ファイル名
    ; OUT
    ;   a = 0...ファイルはある / else...ファイルはない

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; ファイル名の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_H

    ; ファイルを開く
    lda     #$04
    ldx     #$01
    jsr     IocsOpen
    tax
    bne     @end

    ; ファイルを閉じる
    jsr     IocsClose
    lda     #$00

    ; 終了
@end:
    rts

.endproc

; 空いている DOS BUFFER をゼロページに取得する
;
.proc   IocsUseDosBuffer

    ; OUT
    ;   IOCS_0_DOS_BUFFER = DOS BUFFER

    ; DOS ルーチンから DOS BUFFER のエントリポイントを取得
    ldy     #$00
    sty     IOCS_0_DOS_BUFFER_L
    lda     DOSWARM + $0002
    sta     IOCS_0_DOS_BUFFER_H

    ; DOS BUFFER の確認
:
    lda     (IOCS_0_DOS_BUFFER), y
    tax
    iny
    lda     (IOCS_0_DOS_BUFFER), y
    sta     IOCS_0_DOS_BUFFER_H
    stx     IOCS_0_DOS_BUFFER_L
    bne     :+
    txa
    beq     @error
:

    ; ファイル名の確認
    ldy     #$00
    lda     (IOCS_0_DOS_BUFFER), y
    beq     :+
    ldy     #DosBuffer::next_buffer_address
    jmp     :--
:

    ; 終了
    rts

    ; エラー終了
@error:
    ldx     #<@error_message
    lda     #>@error_message
    jmp     _IocsError
@error_message:
    .asciiz "ERR - NO BUFFER"

.endproc

; DOS BUFFER を解放する
;
.proc   IocsUnuseDosBuffer

    ; IN
    ;   IOCS_0_DOS_BUFFER = DOS BUFFER

    ; DOS BUFFER のファイル名をクリア
    ldy     #DosBuffer::filename
    lda     #$00
    sta     (IOCS_0_DOS_BUFFER), y

    ; 終了
    rts

.endproc

; DOS BUFFER にファイル名をコピーする
;
.proc   IocsCopyFilenameToBuffer

    ; IN
    ;   IOCS_0_DOS_FILENAME = ファイル名
    ;   IOCS_0_DOS_BUFFER   = コピー先

    ; ファイル名のコピー
    ldy     #$00
    ldx     #$1e
:
    lda     (IOCS_0_DOS_FILENAME), y
    beq     :+
    ora     #$80
    sta     (IOCS_0_DOS_BUFFER), y
    iny
    dex
    bne     :-
    rts
:
    ; 残りを空白で埋める
    lda     #$a0
:
    sta     (IOCS_0_DOS_BUFFER), y
    iny
    dex
    bne     :-

    ; 終了
    rts

.endproc

; DOS BUFFER のアドレスを FILE MANAGER PARAMETER LIST に設定する
;
.proc   IocsSetDosBufferAddress

    ; IN
    ;   IOCS_0_DOS_BUFFER = DOS BUFFER
    ;   IOCS_0_DOS_PARAM  = FILE MANAGER PARAMETER LIST

    ; WORKAREA アドレスの設定
    ldy     #DosBuffer::workarea_address + $00
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::workarea_address + $00
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosBuffer::workarea_address + $01
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::workarea_address + $01
    sta     (IOCS_0_DOS_PARAM), y

    ; LIST SECTOR アドレスの設定
    ldy     #DosBuffer::list_sector_address + $00
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::list_sector_address + $00
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosBuffer::list_sector_address + $01
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::list_sector_address + $01
    sta     (IOCS_0_DOS_PARAM), y

    ; DATA SECTOR アドレスの設定
    ldy     #DosBuffer::data_sector_address + $00
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::data_sector_address + $00
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosBuffer::data_sector_address + $01
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::data_sector_address + $01
    sta     (IOCS_0_DOS_PARAM), y

    ; 終了
    rts

.endproc

; ディスクエラーの復帰待ちを行う
;
.proc   IocsDiskError

    ; OUT
    ;   a = キーコード

    ; メッセージの表示とキー入力待ち
    ldx     #<@error_message
    lda     #>@error_message
    jsr     _IocsRetry

    ; 終了
    rts

@error_message:
    .asciiz "INSERT CORRECT DISK AND PRESS KEY"

.endproc

; ファイルを開く
;
.proc   IocsOpen

    ; IN
    ;   IOCS_0_DOS_FILENAME = ファイル名
    ;   IOCS_0_DOS_FILETYPE = ファイルタイプ
    ;   IOCS_0_DOS_FLAG     = 0...ファイルがない場合は作成する
    ; OUT
    ;   a = 0...成功 / else...エラーコード

    ; DOS BUFFER の取得
    jsr     IocsUseDosBuffer

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; OPEN の設定
    ldy     #DosParamOpen::call
    lda     #$01
    sta     (IOCS_0_DOS_PARAM), y

    ; レコード長の設定
    ldy     #DosParamOpen::record_length
    lda     #$00
    sta     (IOCS_0_DOS_PARAM), y
    iny
    sta     (IOCS_0_DOS_PARAM), y

    ; ボリュームの設定
    ldy     #DosParamOpen::volume
;   lda     DOS_DEFAULT_VOLUME
;;  lda     #$00
    sta     (IOCS_0_DOS_PARAM), y

    ; ドライブの設定
    ldy     #DosParamOpen::drive
    lda     DOS_DEFAULT_DRIVE
    sta     (IOCS_0_DOS_PARAM), y

    ; スロットの設定
    ldy     #DosParamOpen::slot
    lda     DOS_DEFAULT_SLOT
    sta     (IOCS_0_DOS_PARAM), y

    ; ファイルタイプの設定
    ldy     #DosParamOpen::filetype
    lda     IOCS_0_DOS_FILETYPE
    sta     (IOCS_0_DOS_PARAM), y

    ; ファイル名アドレスの設定
    ldy     #DosParamOpen::filename_address
    lda     IOCS_0_DOS_BUFFER_L
    sta     (IOCS_0_DOS_PARAM), y
    iny
    lda     IOCS_0_DOS_BUFFER_H
    sta     (IOCS_0_DOS_PARAM), y

    ; ファイル名のコピー
    jsr     IocsCopyFilenameToBuffer

    ; DOS BUFFER アドレスの設定
    jsr     IocsSetDosBufferAddress

    ; OPEN の呼び出し
    ldx     IOCS_0_DOS_FLAG
    jsr     DOSCALL

    ; 返り値の取得
    lda     #$06
    ldx     IOCS_0_DOS_FLAG
    beq     :+
    lda     #$00
:
    jsr     IocsGetReturnCode
    tax
    beq     :+
    pha
    jsr     IocsUnuseDosBuffer
    pla
:

    ; 終了
    rts

.endproc

; ファイルを閉じる
;
.proc   IocsClose

    ; OUT
    ;   a = 0...成功 / else...エラーコード

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; CLOSE の設定
    ldy     #DosParamOpen::call
    lda     #$02
    sta     (IOCS_0_DOS_PARAM), y

    ; CLOSE の呼び出し
    jsr     DOSCALL

    ; DOS BUFFER の解放
    jsr     IocsUnuseDosBuffer

    ; 返り値の取得
    lda     #$00
    jsr     IocsGetReturnCode

    ; 終了
    rts

.endproc

; ファイルを読み込む
;
.proc   IocsLoad

    ; IN
    ;   IOCS_0_DOS_ADDRESS = 読み込み先
    ;   IOCS_0_DOS_LENGTH  = 読み込むバイト数
    ; OUT
    ;   a = 0...成功 / else...エラーコード

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; READ の設定
    ldy     #DosParamRead::call
    lda     #$03
    sta     (IOCS_0_DOS_PARAM), y
;;  ldy     #DosParamRead::subcall
    iny
    lda     #$02
    sta     (IOCS_0_DOS_PARAM), y

;   ; レコード番号の設定
;   ldy     #DosParamRead::record_number
;   lda     #$00
;   sta     (IOCS_0_DOS_PARAM), y
;   iny
;   sta     (IOCS_0_DOS_PARAM), y

;   ; オフセットの設定
;   ldy     #DosParamRead::byte_offset
;   lda     #$00
;   sta     (IOCS_0_DOS_PARAM), y
;   iny
;   sta     (IOCS_0_DOS_PARAM), y

    ; 読み込むバイト数の設定
    ldy     #DosParamRead::read_length
    lda     IOCS_0_DOS_LENGTH_L
    sta     (IOCS_0_DOS_PARAM), y
    iny
    lda     IOCS_0_DOS_LENGTH_H
    sta     (IOCS_0_DOS_PARAM), y

    ; 読み込み先の設定
    ldy     #DosParamRead::read_address
    lda     IOCS_0_DOS_ADDRESS_L
    sta     (IOCS_0_DOS_PARAM), y
    iny
    lda     IOCS_0_DOS_ADDRESS_H
    sta     (IOCS_0_DOS_PARAM), y

    ; READ の呼び出し
    jsr     DOSCALL
    
    ; 返り値の取得
    lda     #$00
    jsr     IocsGetReturnCode

    ; 終了
    rts

.endproc

; ファイルを書き込む
;
.proc   IocsSave

    ; IN
    ;   IOCS_0_DOS_ADDRESS = 書き込み元
    ;   IOCS_0_DOS_LENGTH  = 書き込むバイト数
    ; OUT
    ;   a = 0...成功 / else...エラーコード

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; WRITE の設定
    ldy     #DosParamWrite::call
    lda     #$04
    sta     (IOCS_0_DOS_PARAM), y
;;  ldy     #DosParamWrite::subcall
    iny
    lda     #$02
    sta     (IOCS_0_DOS_PARAM), y

;   ; レコード番号の設定
;   ldy     #DosParamWrite::record_number
;   lda     #$00
;   sta     (IOCS_0_DOS_PARAM), y
;   iny
;   sta     (IOCS_0_DOS_PARAM), y

;   ; オフセットの設定
;   ldy     #DosParamWrite::byte_offset
;   lda     #$00
;   sta     (IOCS_0_DOS_PARAM), y
;   iny
;   sta     (IOCS_0_DOS_PARAM), y

    ; 書き込むバイト数の設定（-1 する）
    ldy     #DosParamWrite::write_length
    lda     IOCS_0_DOS_LENGTH_L
    sec
    sbc     #$01
    sta     (IOCS_0_DOS_PARAM), y
    lda     IOCS_0_DOS_LENGTH_H
    sbc     #$00
    iny
    sta     (IOCS_0_DOS_PARAM), y

    ; 書き込み元の設定
    ldy     #DosParamWrite::write_address
    lda     IOCS_0_DOS_ADDRESS_L
    sta     (IOCS_0_DOS_PARAM), y
    iny
    lda     IOCS_0_DOS_ADDRESS_H
    sta     (IOCS_0_DOS_PARAM), y

    ; WRITE の呼び出し
    jsr     DOSCALL
    
    ; 返り値の取得
    lda     #$00
    jsr     IocsGetReturnCode

    ; 終了
    rts

.endproc

; リターンコードを取得する
;
.proc   IocsGetReturnCode

    ; IN
    ;   IOCS_0_DOS_PARAM = FILE MANAGER PARAMETER LIST
    ;   a                = エラーとしないコード
    ; OUT
    ;   a = 0...成功 / else...エラーコード

    ; リターンコードの取得
    ldy     #DosParam::return_code
    sec
    sbc     (IOCS_0_DOS_PARAM), y
    beq     :+
    lda     (IOCS_0_DOS_PARAM), y
    beq     :+

    ; エラーの出力
    pha
    ldx     #<@error_message
    lda     #>@error_message
    jsr     _IocsCoutString
    pla
    pha
    jsr     PRBYTE
    jsr     CROUT1
    pla
:

    ; 終了
    rts

    ; エラ〜メッセージ
@error_message:
    .asciiz "ERR - CODE "

.endproc

; VRAM をクリアする
;
.global _IocsClearVram
.proc   _IocsClearVram

    ; $2000..$3fff を 0 クリアする
    lda     #<HGR1SCRN
    sta     IOCS_0_HGR_DST_L
    lda     #>HGR1SCRN
    sta     IOCS_0_HGR_DST_H
    ldx     #$20
:
    ldy     #$00
    tya
:
    sta     (IOCS_0_HGR_DST), y
    inc     IOCS_0_HGR_DST_L
    bne     :-
    inc     IOCS_0_HGR_DST_H
    dex
    bne     :--

    ; 終了
    rts

.endproc

; VRAM のアドレスを取得する
;
.global _IocsGetVramAddress
.proc   _IocsGetVramAddress

    ; IN
    ;   x = X タイル位置
    ;   y = Y タイル位置
    ; OUT
    ;   ax = アドレス
    ; WORK
    ;   IOCS_0_WORK_0

    ; アドレス計算
    txa
    clc
    adc     _iocs_hgr_tile_y_address_low, y
    tax
    lda     #$00
    adc     _iocs_hgr_tile_y_address_high, y

    ; 終了
    rts

.endproc

; 7x8 タイルセットのピクセルパターンアドレスを取得する
;
.global _IocsGet7x8PatternAddress
.proc   _IocsGet7x8PatternAddress

    ; IN
    ;   yx = タイルセット
    ;   a  = タイル番号
    ; OUT
    ;   ax = 7x8 ピクセルパターン
    ; WORK
    ;   IOCS_0_WORK_0

    ; ax = yx + a * 8
    stx     IOCS_0_WORK_0
    ldx     #$00
    stx     IOCS_0_WORK_1
    asl     a
    rol     IOCS_0_WORK_1
    asl     a
    rol     IOCS_0_WORK_1
    asl     a
    rol     IOCS_0_WORK_1
;;  clc
    adc     IOCS_0_WORK_0
    tax
    tya
    adc     IOCS_0_WORK_1

    ; 終了
    rts

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンをタイル位置を指定して描画する
;
.proc   IocsDraw7x8PatternXy

    ; IN
    ;   IOCS_0_HGR_SRC = 7x8 ピクセルパターン
    ;   x              = X タイル位置
    ;   y              = Y タイル位置

    ; 転送先アドレスの取得
    jsr     _IocsGetVramAddress

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを VRAM アドレスを指定して描画する
;
.proc IocsDraw7x8PatternAx

    ; IN
    ;   IOCS_0_HGR_SRC = 7x8 ピクセルパターン
    ;   ax             = VRAM アドレス

    ; 転送先アドレスの設定
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_HGR_DST へ描画する
;
.proc IocsDraw7x8Pattern0

    ; IN
    ;   IOCS_0_HGR_SRC = 7x8 ピクセルパターン
    ;   IOCS_0_HGR_DST = VRAM アドレス

    ; IOCS_0_HGR_DST_H の保存
    lda     IOCS_0_HGR_DST_H
    pha

    ; 8 ライン分の描画
    ldx     #$00

    ; 1 ライン目
    ldy     #$00
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 2 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 3 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 4 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 5 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 6 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 7 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 8 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; IOCS_0_HGR_DST_H の復帰
    pla
    sta     IOCS_0_HGR_DST_H

    ; 終了
    rts

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_MASK でマスクして指定されたタイル位置へ描画する
;
.if     IOCS_MASKED
.proc   IocsDraw7x8MaskedXy

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   x               = X タイル位置
    ;   y               = Y タイル位置

    ; 転送先アドレスの取得
    jsr     _IocsGetVramAddress

.endproc
.endif

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_MASK でマスクして指定された VRAM アドレスへ描画する
;
.if     IOCS_MASKED
.proc   IocsDraw7x8MaskedAx

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   ax              = VRAM アドレス

    ; 転送先アドレスの設定
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

.endproc
.endif

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_MASK でマスクして IOCS_0_HGR_DST へ描画する
;
.if     IOCS_MASKED
.proc   IocsDraw7x8Masked0

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   IOCS_0_HGR_DST  = VRAM アドレス

    ; IOCS_0_HGR_DST_H の保存
    lda     IOCS_0_HGR_DST_H
    pha

    ; 8 ライン分の描画
    ldx     #$00

    ; 1 ライン目
    ldy     #$00
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 2 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 3 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 4 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 5 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 6 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 7 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 8 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; IOCS_0_HGR_DST_H の復帰
    pla
    sta     IOCS_0_HGR_DST_H

    ; 終了
    rts

.endproc
.endif

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_BASE に IOCS_0_MASK でマスクして重ね合わせて指定されたタイル位置へ描画する
;
.if     IOCS_LAYERED
.proc   IocsDraw7x8LayeredXy

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   IOCS_0_HGR_BASE = 7x8 重ね合わせられるピクセルパターン
    ;   x               = X タイル位置
    ;   y               = Y タイル位置

    ; 転送先アドレスの取得
    jsr     _IocsGetVramAddress

.endproc
.endif

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_BASE に IOCS_0_MASK でマスクして重ね合わせて指定された VRAM アドレスへ描画する
;
.if     IOCS_LAYERED
.proc   IocsDraw7x8LayeredAx


    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   IOCS_0_HGR_BASE = 7x8 重ね合わせられるピクセルパターン
    ;   ax              = VRAM アドレス

    ; 転送先アドレスの設定
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

.endproc
.endif

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_BASE に IOCS_0_MASK でマスクして重ね合わせて IOCS_0_HGR_DST へ描画する
;
.if     IOCS_LAYERED
.proc   IocsDraw7x8Layered0

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   IOCS_0_HGR_BASE = 7x8 重ね合わせられるピクセルパターン
    ;   IOCS_0_HGR_DST  = VRAM アドレス

    ; IOCS_0_HGR_DST_H の保存
    lda     IOCS_0_HGR_DST_H
    pha

    ; 8 ライン分の描画
    ldx     #$00

    ; 1 ライン目
    ldy     #$00
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 2 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 3 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 4 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 5 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 6 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 7 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 8 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; IOCS_0_HGR_DST_H の復帰
    pla
    sta     IOCS_0_HGR_DST_H

    ; 終了
    rts

.endproc
.endif

; 文字列を描画する
;
.global _IocsDrawString
.proc   _IocsDrawString

    ; IN
    ;   ax[0]    = X タイル位置
    ;   ax[1]    = Y タイル位置
    ;   ax[2..3] = 文字列

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; 描画アドレスの取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_STRING_VRAM_X
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_STRING_VRAM_Y
    tay
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 文字列の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_STRING_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_STRING_H

    ; 文字列の描画
    lda     #$00
    sta     IOCS_0_HGR_STRING_INDEX
@draw_start:

    ; 文字の取得
    ldy     IOCS_0_HGR_STRING_INDEX
    lda     (IOCS_0_HGR_STRING), y
    beq     @draw_end

    ; 改行
    cmp     #$0d
    beq     :+
    cmp     #$0a
    bne     :++
:
    ldy     #$00
    ldx     IOCS_0_HGR_STRING_VRAM_X
    inc     IOCS_0_HGR_STRING_VRAM_Y
    ldy     IOCS_0_HGR_STRING_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H
    inc     IOCS_0_HGR_STRING_INDEX
    jmp     @draw_start
:    

    ; 1 文字の描画
    ldx     #<_iocs_font
    ldy     #>_iocs_font
    sec
    sbc     #$20
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H
    jsr     IocsDraw7x8Pattern0
    inc     IOCS_0_HGR_DST_L
    inc     IOCS_0_HGR_STRING_INDEX
    jmp     @draw_start

    ; 文字列の描画の終了
@draw_end:

    ; 終了
    rts

.endproc

; 7x8 サイズのピクセルパターンを描画する
;
.global _IocsDraw7x8Pattern
.proc   _IocsDraw7x8Pattern

    ; IN
    ;   ax[0]    = X タイル位置
    ;   ax[1]    = Y タイル位置
    ;   ax[2..3] = タイルセット
    ;   ax[4]    = タイル番号

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; ピクセルパターンの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
    pha
    ldy     #$02
    lda     (IOCS_0_ARG), y
    tax
    iny
    lda     (IOCS_0_ARG), y
    tay
    pla
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; 位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    tax
    iny
    lda     (IOCS_0_ARG), y
    tay

    ; ピクセルパターンの描画
    jsr     IocsDraw7x8PatternXy
    
    ; 終了
    rts

.endproc

; 7x8 ピクセルパターンのタイルセットを描画する
;
.if     IOCS_TILESET
.global _IocsDraw7x8Tileset
.proc   _IocsDraw7x8Tileset

    ; IN
    ;   ax[0]      = X タイル位置
    ;   ax[1]      = Y タイル位置
    ;   ax[2]      = 描画の幅
    ;   ax[3]      = 描画の高さ
    ;   ax[4..5]   = タイルセット
    ;   ax[6]      = タイル番号

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; タイルセットの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_SRC_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SRC_H
    ldy     #$06
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_SRC_L
    ldy     IOCS_0_HGR_SRC_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; 描画位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_VRAM_X
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_VRAM_Y

    ; 描画の高さの設定
    ldy     #$03
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_Y
@draw_y:

    ; VRAM アドレスの取得
    ldx     IOCS_0_HGR_TILESET_VRAM_X
    ldy     IOCS_0_HGR_TILESET_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 描画の幅の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_X
@draw_x:

    ; 縦 8 ピクセル分のパターンの描画
    jsr     IocsDraw7x8Pattern0

    ; 次のタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_L
    bcc     :+
    inc     IOCS_0_HGR_SRC_H
:

    ; 次の桁へ
    dec     IOCS_0_HGR_TILESET_X
    beq     :++
    inc     IOCS_0_HGR_TILESET_L
    bne     :+
    inc     IOCS_0_HGR_TILESET_H
:
    inc     IOCS_0_HGR_DST_L
    jmp     @draw_x
:

    ; 次の行へ
    dec     IOCS_0_HGR_TILESET_Y
    beq     :+
    inc     IOCS_0_HGR_TILESET_VRAM_Y
    jmp     @draw_y
:

    ; 終了
    rts

.endproc
.endif

; 7x8 ピクセルパターンのマスクしたタイルセットを描画する
;
.if     IOCS_MASKED
.global _IocsDraw7x8MaskedTileset
.proc   _IocsDraw7x8MaskedTileset

    ; IN
    ;   ax[0]      = X タイル位置
    ;   ax[1]      = Y タイル位置
    ;   ax[2]      = 描画の幅
    ;   ax[3]      = 描画の高さ
    ;   ax[4..5]   = タイルセット
    ;   ax[6..7]   = マスクタイルセット
    ;   ax[8]      = タイル番号

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; タイルセットの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_SRC_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SRC_H
    ldy     #$08
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_SRC_L
    ldy     IOCS_0_HGR_SRC_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; マスクタイルセットの取得
    ldy     #$06
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_MASK_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_MASK_H
;;  ldy     #$08
    iny
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_MASK_L
    ldy     IOCS_0_HGR_MASK_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_MASK_L
    sta     IOCS_0_HGR_MASK_H

    ; 描画位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_VRAM_X
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_VRAM_Y

    ; 描画の高さの設定
    ldy     #$03
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_Y
@draw_y:

    ; VRAM アドレスの取得
    ldx     IOCS_0_HGR_TILESET_VRAM_X
    ldy     IOCS_0_HGR_TILESET_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 描画の幅の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_X
@draw_x:

    ; 縦 8 ピクセル分のパターンの描画
    jsr     IocsDraw7x8Masked0

    ; 次のタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_L
    bcc     :+
    inc     IOCS_0_HGR_SRC_H
:

    ; 次のマスクタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_MASK_L
    sta     IOCS_0_HGR_MASK_L
    bcc     :+
    inc     IOCS_0_HGR_MASK_H
:

    ; 次の桁へ
    dec     IOCS_0_HGR_TILESET_X
    beq     :++
    inc     IOCS_0_HGR_TILESET_L
    bne     :+
    inc     IOCS_0_HGR_TILESET_H
:
    inc     IOCS_0_HGR_DST_L
    jmp     @draw_x
:

    ; 次の行へ
    dec     IOCS_0_HGR_TILESET_Y
    beq     :+
    inc     IOCS_0_HGR_TILESET_VRAM_Y
    jmp     @draw_y
:

    ; 終了
    rts

.endproc
.endif

; 7x8 ピクセルパターンのタイルマップを描画する
;
.if     IOCS_TILEMAP
.global _IocsDraw7x8Tilemap
.proc   _IocsDraw7x8Tilemap

    ; IN
    ;   ax[0]    = X タイル位置
    ;   ax[1]    = Y タイル位置
    ;   ax[2]    = 描画の幅
    ;   ax[3]    = 描画の高さ
    ;   ax[4..5] = タイルセット
    ;   ax[6..7] = タイルマップ
    ;   ax[8]    = タイルマップの開始 X 位置
    ;   ax[9]    = タイルマップの開始 Y 位置

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; タイルセットの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_TILESET_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_TILESET_H

    ; タイルマップの取得
;;  ldy     #$06
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_H

    ; タイルマップの幅の取得
    ldy     #$00
    lda     (IOCS_0_HGR_TILEMAP), y
    sta     IOCS_0_HGR_TILEMAP_WIDTH

    ; タイルマップの次の行への加算値の取得
    ldy     #$02
    sec
    sbc     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_NEXTLINE
    inc     IOCS_0_HGR_TILEMAP_NEXTLINE

    ; タイルマップの開始アドレスの取得
    ldy     #$08
    lda     (IOCS_0_ARG), y
    clc
    adc     #$02                ; タイルマップの幅は 253 以下と仮定
    adc     IOCS_0_HGR_TILEMAP_L
    sta     IOCS_0_HGR_TILEMAP_L
    bcc     :+
    inc     IOCS_0_HGR_TILEMAP_H
:
    iny
    lda     (IOCS_0_ARG), y
    ldx     IOCS_0_HGR_TILEMAP_WIDTH
    jsr     _IocsAxX
    tay
    txa
    clc
    adc     IOCS_0_HGR_TILEMAP_L
    sta     IOCS_0_HGR_TILEMAP_L
    tya
    adc     IOCS_0_HGR_TILEMAP_H
    sta     IOCS_0_HGR_TILEMAP_H

    ; 描画位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_VRAM_X
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_VRAM_Y

    ; 描画の高さの設定
    ldy     #$03
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_Y
@draw_y:

    ; VRAM アドレスの取得
    ldx     IOCS_0_HGR_TILEMAP_VRAM_X
    ldy     IOCS_0_HGR_TILEMAP_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 描画の幅の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_X
@draw_x:

    ; ピクセルパターンの取得
    ldy     #$00
    lda     (IOCS_0_HGR_TILEMAP), y
    ldx     IOCS_0_HGR_TILEMAP_TILESET_L
    ldy     IOCS_0_HGR_TILEMAP_TILESET_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; 縦 8 ピクセル分のパターンの描画
    jsr     IocsDraw7x8Pattern0

    ; 次の桁へ
    dec     IOCS_0_HGR_TILEMAP_X
    beq     :++
    inc     IOCS_0_HGR_TILEMAP_L
    bne     :+
    inc     IOCS_0_HGR_TILEMAP_H
:
    inc     IOCS_0_HGR_DST_L
    jmp     @draw_x
:

    ; 次の行へ
    dec     IOCS_0_HGR_TILEMAP_Y
    beq     :++
    lda     IOCS_0_HGR_TILEMAP_NEXTLINE
    clc
    adc     IOCS_0_HGR_TILEMAP_L
    sta     IOCS_0_HGR_TILEMAP_L
    bcc     :+
    inc     IOCS_0_HGR_TILEMAP_H
:
    inc     IOCS_0_HGR_TILEMAP_VRAM_Y
    jmp     @draw_y
:

    ; 終了
    rts

.endproc
.endif

; 7x8 ピクセルパターンのスプライトを描画する
;
.if     IOCS_SPRITE
.global _IocsDraw7x8Sprite
.proc   _IocsDraw7x8Sprite

    ; IN
    ;   ax[0]      = X タイル位置
    ;   ax[1]      = Y タイル位置
    ;   ax[2]      = 描画の幅
    ;   ax[3]      = 描画の高さ
    ;   ax[4..5]   = スプライトタイルセット
    ;   ax[6..7]   = マスクタイルセット
    ;   ax[8]      = スプライトのタイル番号
    ;   ax[9..10]  = タイルマップタイルセット
    ;   ax[11..12] = タイルマップ
    ;   ax[13]     = タイルマップの開始 X 位置
    ;   ax[14]     = タイルマップの開始 Y 位置

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; スプライトタイルセットの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_SRC_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SRC_H
    ldy     #$08
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_SRC_L
    ldy     IOCS_0_HGR_SRC_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; マスクタイルセットの取得
    ldy     #$06
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_MASK_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_MASK_H
;;  ldy     #$08
    iny
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_MASK_L
    ldy     IOCS_0_HGR_MASK_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_MASK_L
    sta     IOCS_0_HGR_MASK_H

    ; タイルマップタイルセットの取得
    ldy     #$09
    lda     (IOCS_0_ARG), y
    sta     @tilemap_tileset_l
    iny
    lda     (IOCS_0_ARG), y
    sta     @tilemap_tileset_h

    ; タイルマップの取得
    ldy     #$0b
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_H

    ; タイルマップの幅の取得
    ldy     #$00
    lda     (IOCS_0_HGR_SPRITE_TILEMAP), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_WIDTH

    ; タイルマップの次の行への加算値の取得
    ldy     #$02
    sec
    sbc     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_NEXTLINE
    inc     IOCS_0_HGR_SPRITE_TILEMAP_NEXTLINE

    ; タイルマップの開始アドレスの取得
    ldy     #$0d
    lda     (IOCS_0_ARG), y
    clc
    adc     #$02                ; タイルマップの幅は 253 以下と仮定
    adc     IOCS_0_HGR_SPRITE_TILEMAP_L
    sta     IOCS_0_HGR_SPRITE_TILEMAP_L
    bcc     :+
    inc     IOCS_0_HGR_SPRITE_TILEMAP_H
:
    iny
    lda     (IOCS_0_ARG), y
    ldx     IOCS_0_HGR_SPRITE_TILEMAP_WIDTH
    jsr     _IocsAxX
    tay
    txa
    clc
    adc     IOCS_0_HGR_SPRITE_TILEMAP_L
    sta     IOCS_0_HGR_SPRITE_TILEMAP_L
    tya
    adc     IOCS_0_HGR_SPRITE_TILEMAP_H
    sta     IOCS_0_HGR_SPRITE_TILEMAP_H

    ; 描画位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_VRAM_X
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_VRAM_Y

    ; 描画の高さの設定
    ldy     #$03
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_Y
@draw_y:

    ; VRAM アドレスの取得
    ldx     IOCS_0_HGR_SPRITE_VRAM_X
    ldy     IOCS_0_HGR_SPRITE_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 描画の幅の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_X
@draw_x:

    ; タイルマップの取得
    ldy     #$00
    lda     (IOCS_0_HGR_SPRITE_TILEMAP), y
    ldx     @tilemap_tileset_l
    ldy     @tilemap_tileset_h
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_BASE_L
    sta     IOCS_0_HGR_BASE_H

    ; 縦 8 ピクセル分のパターンの重ね合わせ描画
    jsr     IocsDraw7x8Layered0

    ; 次のスプライトタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_L
    bcc     :+
    inc     IOCS_0_HGR_SRC_H
:

    ; 次のマスクタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_MASK_L
    sta     IOCS_0_HGR_MASK_L
    bcc     :+
    inc     IOCS_0_HGR_MASK_H
:

    ; 次の桁へ
    dec     IOCS_0_HGR_SPRITE_TILEMAP_X
    beq     :++
    inc     IOCS_0_HGR_SPRITE_TILEMAP_L
    bne     :+
    inc     IOCS_0_HGR_SPRITE_TILEMAP_H
:
    inc     IOCS_0_HGR_DST_L
    jmp     @draw_x
:

    ; 次の行へ
    dec     IOCS_0_HGR_SPRITE_TILEMAP_Y
    beq     :++
    lda     IOCS_0_HGR_SPRITE_TILEMAP_NEXTLINE
    clc
    adc     IOCS_0_HGR_SPRITE_TILEMAP_L
    sta     IOCS_0_HGR_SPRITE_TILEMAP_L
    bcc     :+
    inc     IOCS_0_HGR_SPRITE_TILEMAP_H
:
    inc     IOCS_0_HGR_SPRITE_VRAM_Y
    jmp     @draw_y
:

    ; 終了
    rts

; タイルマップタイルセット
@tilemap_tileset_l:
    .byte   $00
@tilemap_tileset_h:
    .byte   $00

.endproc
.endif

; COUT による文字列の出力を行う
;
.global _IocsCoutString
.proc   _IocsCoutString

    ; IN
    ;   ax = 文字列
    ; WORK
    ;   IOCS_0_WORK_0..1

    ; 文字列の出力
    stx     IOCS_0_WORK_0
    sta     IOCS_0_WORK_1
    ldy     #$00
:
    lda     (IOCS_0_WORK_0), y
    beq     :+
    ora     #$80
    jsr     COUT1
    iny
    jmp     :-
:

    ; 終了
    rts

.endproc

; メモリダンプする
;
.global _IocsDump
.proc   _IocsDump

    ; IN
    ;   ax = アドレス
    ;    y x 16 バイトをダンプ
    ; WORK
    ;   IOCS_0_WORK_0..2

    ; 
    stx     IOCS_0_WORK_0
    sta     IOCS_0_WORK_1
    sty     IOCS_0_WORK_2

    ; 16 バイトずつダンプ
:
    ldx     IOCS_0_WORK_0
    lda     IOCS_0_WORK_1
    jsr     PRNTAX
    lda     #$a0
    jsr     COUT1
    ldy     #$00
:
    lda     (IOCS_0_WORK_0), y
    jsr     PRBYTE
    iny
    tya
    and     #$07
    bne     :-
    lda     #$a0
    jsr     COUT1
    tya
    and     #$10
    beq     :-
    jsr     CROUT1
    dec     IOCS_0_WORK_2
    beq     :+
    lda     IOCS_0_WORK_0
    clc
    adc     #$10
    sta     IOCS_0_WORK_0
    bcc     :--
    inc     IOCS_0_WORK_1
    jmp     :--
:

    ; 終了
    rts

.endproc

; BEEP で音符を再生する
;
.if     IOCS_BEEP
.global _IocsBeepNote
.proc   _IocsBeepNote

    ; IN
    ;   x = 音階
    ;   a = 音長

    ; 1 回の音符の再生
    sta     IOCS_0_BEEP_LENGTH
    ldy     iocs_beep_l256_count, x
:
    lda     SPEAKER                 ;    4 cycle
    lda     iocs_beep_freq_count, x ;    4 cycle
                                    ; =  8 cycle
:
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    sec                             ;    2 cycle
    sbc     #$01                    ;    2 cycle
    bne     :-                      ;    3 cycle
                                    ; = 17 cycle
                                    ;   -1 cycle
    dey                             ;    2 cycle
    beq     :+                      ;    3 cycle
                                    ; =  4 cycle
                                    ;   -1 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    jmp     :--                     ;    3 cycle
                                    ; = 12 cycle
:
    ldy     iocs_beep_l256_count, x ;    4 cycle
    dec     IOCS_0_BEEP_LENGTH      ;    5 cycle
    bne     :---                    ;    3 cycle
                                    ; = 12 cycle

    ; 終了
    rts

.endproc
.endif

; BEEP で休符を再生する
;
.if     IOCS_BEEP
.global _IocsBeepRest
.proc   _IocsBeepRest

    ; IN
    ;   a = 音長

    ; 1 回の休符の再生
    sta     IOCS_0_BEEP_LENGTH
    ldx     #_O4A
    ldy     iocs_beep_l256_count, x
:
    lda     :-                      ;    4 cycle
    lda     iocs_beep_freq_count, x ;    4 cycle
                                    ; =  8 cycle
:
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    sec                             ;    2 cycle
    sbc     #$01                    ;    2 cycle
    bne     :-                      ;    3 cycle
                                    ; = 17 cycle
                                    ;   -1 cycle
    dey                             ;    2 cycle
    beq     :+                      ;    3 cycle
                                    ; =  4 cycle
                                    ;   -1 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    nop                             ;    2 cycle
    jmp     :--                     ;    3 cycle
                                    ; = 12 cycle
:
    ldy     iocs_beep_l256_count, x ;    4 cycle
    dec     IOCS_0_BEEP_LENGTH      ;    5 cycle
    bne     :---                    ;    3 cycle
                                    ; = 12 cycle

    ; 終了
    rts

.endproc
.endif

; BEEP で譜面を再生する
;
.if     IOCS_BEEP
.global _IocsBeepScore
.proc   _IocsBeepScore

    ; IN
    ;   ax = 譜面

    ; シーケンスの設定
    stx     IOCS_0_BEEP_SCORE_L
    sta     IOCS_0_BEEP_SCORE_H
    lda     #$00
    sta     IOCS_0_BEEP_SCORE_INDEX
    
    ; 譜面の再生
@score_loop:
    ldy     IOCS_0_BEEP_SCORE_INDEX
    lda     (IOCS_0_BEEP_SCORE), y
    bmi     @score_end
    tax
    iny
    lda     (IOCS_0_BEEP_SCORE), y
    cpx     #IOCS_BEEP_R
    beq     :+
    jsr     _IocsBeepNote
    jmp     :++
:
    jsr     _IocsBeepRest
:
    inc     IOCS_0_BEEP_SCORE_INDEX
    inc     IOCS_0_BEEP_SCORE_INDEX
    bne     @score_loop
    inc     IOCS_0_BEEP_SCORE_H
    jmp     @score_loop
@score_end:

    ; 終了
    rts

.endproc
.endif

; 更新毎に再生する BEEP を設定する
;
.if     IOCS_BEEP
.global _IocsBeepQue
.proc   _IocsBeepQue

    ; IN
    ;   ax = 譜面

    ; BEEP の設定
    stx     IOCS_0_BEEP_L
    sta     IOCS_0_BEEP_H
    lda     #$00
    sta     IOCS_0_BEEP_INDEX
    sta     IOCS_0_BEEP_COUNT

    ; 終了
    rts

.endproc
.endif

; 設定された BEEP を削除する
;
.if     IOCS_BEEP
.global _IocsBeepUnque
.proc   _IocsBeepUnque

    ; BEEP の設定
    lda     #$00
    sta     IOCS_0_BEEP_L
    sta     IOCS_0_BEEP_H

    ; 終了
    rts

.endproc
.endif

; A * X の計算を行う
;
.global _IocsAxX
.proc   _IocsAxX

    ; IN
    ;   a = かけられる数
    ;   x = かける数
    ; OUT
    ;   ax = 結果
    ; WORK
    ;   IOCS_WORK_0..1

    ; ax = a * x
    lsr     a
    sta     IOCS_0_WORK_0
    dex                         ; あらかじめ -1 しておく
    stx     IOCS_0_WORK_1
    lda     #0
    ldx     #8
@loop:
    bcc     @skip
;;  clc                         ; ここは必ず cf = 1 なので +1 される
    adc     IOCS_0_WORK_1
@skip:
    ror     a
    ror     IOCS_0_WORK_0
    dex
    bne     @loop
    ldx     IOCS_0_WORK_0
  
    ; 終了
    rts

.endproc

; YX + A * 8 の計算を行う
;
.global _IocsYXplus8A
.proc   _IocsYXplus8A

    ; IN
    ;   yx = 足される数
    ;   a  = 8 倍される数
    ; OUT
    ;   ax = 結果
    ; WORK
    ;   IOCS_WORK_0..1

    ; ax = yx + a * 8
    sta     IOCS_0_WORK_0
    lda     #$00
    asl     IOCS_0_WORK_0
    rol     a
    asl     IOCS_0_WORK_0
    rol     a
    asl     IOCS_0_WORK_0
    rol     a
    sta     IOCS_0_WORK_1
    txa
;;  clc
    adc     IOCS_0_WORK_0
    tax
    tya
    adc     IOCS_0_WORK_1

    ; 終了
    rts

.endproc

; 乱数を取得する
;
.global _IocsGetRandomNumber
.proc   _IocsGetRandomNumber

    ; OUT
    ;   a = 乱数
    ; WORK
    ;   IOCS_0_WORK_0

    ; IOCS_0_RANDOM = IOCS_0_RANDOM * 5 + 1
.if 1
    lda     IOCS_0_RANDOM_H
    sta     IOCS_0_WORK_0
    lda     IOCS_0_RANDOM_H
    asl     a
    rol     IOCS_0_WORK_0
    asl     a
    rol     IOCS_0_WORK_0
    clc
    adc     IOCS_0_RANDOM_L
    sta     IOCS_0_RANDOM_L
    lda     IOCS_0_WORK_0
    adc     IOCS_0_RANDOM_H
    sta     IOCS_0_RANDOM_H
    inc     IOCS_0_RANDOM_L
    bne     :+
    inc     IOCS_0_RANDOM_H
:
.else
    lda     IOCS_0_RANDOM_H
    asl     a
    asl     a
    clc
    adc     IOCS_0_RANDOM_H
    sta     IOCS_0_RANDOM_H
    inc     IOCS_0_RANDOM_H
.endif

    ; 乱数の取得
    lda     IOCS_0_RANDOM_H

    ; 終了
    rts

.endproc

; AX を 10 進数の文字列に変換する
;
.global _IocsGetNumberString
.proc   _IocsGetNumberString

    ; IN
    ;   ax = 数値
    ; OUT
    ;   ax = 文字列
    ; WORK
    ;   IOCS_0_WORK_0..3

    ; 桁数の判定
    sta     IOCS_0_WORK_1
    txa
    ldx     IOCS_0_WORK_1
    ldy     #$00
    cpx     #>10000
    bcc     :+
    bne     @number_10000
    cmp     #<10000
    bcs     @number_10000
:
    cpx     #>1000
    bcc     :+
    bne     @number_1000
    cmp     #<1000
    bcs     @number_1000
:
    cpx     #1
    bcs     @number_100
    cmp     #100
    bcs     @number_100
    cmp     #10
    bcs     @number_10
    ora     #$30
    sta     @string
    bne     @end

    ; 100 >=0 のカウント
@sub_16:
    stx     IOCS_0_WORK_2
    ldx     #$30
    bne     :++
:
    sta     IOCS_0_WORK_1
    inx
    lda     IOCS_0_WORK_0
:
    sbc     IOCS_0_WORK_2
    sta     IOCS_0_WORK_0
    lda     IOCS_0_WORK_1
    sbc     IOCS_0_WORK_3
    bcs     :--
    txa
    sta     @string, y
    iny
    lda     IOCS_0_WORK_0
    adc     IOCS_0_WORK_2
    sec
    rts

    ; 10000 の変換
@number_10000:
    ldx     #>10000
    stx     IOCS_0_WORK_3
    ldx     #<10000
    jsr     @sub_16

    ; 1000 の変換
@number_1000:
    ldx     #>1000
    stx     IOCS_0_WORK_3
    ldx     #<1000
    jsr     @sub_16

    ; 100 の変換
@number_100:
    ldx     #>100
    stx     IOCS_0_WORK_3
    ldx     #<100
    jsr     @sub_16

    ; 10, 1 の変換
@number_10:
    ldx     #$30 - $01
:
    inx
    sbc     #10
    bcs     :-
    adc     #10 + $30
    sta     @string + $0001, y
    txa
    sta     @string, y
    iny

    ; 終端文字の設定
@end:
    lda     #$00
    sta     @string + $0001, y
    ldx     #<@string
    lda     #>@string

    ; 終了
    rts

; 文字列
@space:
    .byte   $20, $20, $20, $20
@string:
    .byte   $00, $00, $00, $00, $00
    .byte   $00

.endproc

; AX を 5 桁の 10 進数の文字列に変換する
;
.global _IocsGetNumber5Chars
.proc   _IocsGetNumber5Chars

    ; IN
    ;   ax = 数値
    ; OUT
    ;   ax = 文字列
    ; WORK
    ;   IOCS_0_WORK_0..3

    ; 文字列の取得
    jsr     _IocsGetNumberString

    ; 5 桁に揃える
    stx     IOCS_0_WORK_0
    sta     IOCS_0_WORK_1
    ldy     #$00
:
    iny
    lda     (IOCS_0_WORK_0), y
    bne     :-
:
    dex
    cpx     #$ff
    bne     :+
    dec     IOCS_0_WORK_1
:
    iny
    cpy     #$05
    bne     :--
;   ldx     IOCS_0_WORK_0
    lda     IOCS_0_WORK_1

    ; 終了
    rts

.endproc

; atan2 の値を取得する
;
.if     IOCS_TRIGONOMETRIC
.global _IocsGetAtan2
.proc   _IocsGetAtan2

    ; IN
    ;   x = X 値
    ;   y = Y 値
    ; OUT
    ;   a = 角度（$00..$ff）
    
    ; X, Y 値の取得
    stx     IOCS_0_ATAN2_X
    sty     IOCS_0_ATAN2_Y
    
    ; 値の取得
    lda     #$00
    sta     IOCS_0_ATAN2_FLAG
    txa
    bpl     :++
    lda     IOCS_0_ATAN2_FLAG
    ora     #%00000001
    sta     IOCS_0_ATAN2_FLAG
    txa
    eor     #$ff
    clc
    adc     #$01
    bpl     :+
    lda     #$7f
:
    sta     IOCS_0_ATAN2_X
:
    tya
    bpl     :++
    lda     IOCS_0_ATAN2_FLAG
    ora     #%00000010
    sta     IOCS_0_ATAN2_FLAG
    tya
    eor     #$ff
    clc
    adc     #$01
    bpl     :+
    lda     #$7f
:
    sta     IOCS_0_ATAN2_Y
:
    lda     IOCS_0_ATAN2_X
    cmp     IOCS_0_ATAN2_Y
    bcs     :+
    lda     IOCS_0_ATAN2_Y
:
    cmp     #$08
    bcc     :+
    lsr     a
    lsr     IOCS_0_ATAN2_X
    lsr     IOCS_0_ATAN2_Y
    jmp     :-
:
    lda     IOCS_0_ATAN2_Y
    asl     a
    asl     a
    asl     a
    clc
    adc     IOCS_0_ATAN2_X
    tax
    lda     iocs_atan2_angle, x
    sta     IOCS_0_ATAN2_ANGLE
    lda     IOCS_0_ATAN2_FLAG
    clc
    adc     #$01
    and     #%00000010
    beq     :+
    lda     IOCS_0_ATAN2_ANGLE
    eor     #$ff
    clc
    adc     #$01
    sta     IOCS_0_ATAN2_ANGLE
:
    ldx     IOCS_0_ATAN2_FLAG
    lda     iocs_atan2_offset, x
    clc
    adc     IOCS_0_ATAN2_ANGLE
    
    ; 終了
    rts

.endproc
.endif

; 待機する
;
.global _IocsWait
.proc   _IocsWait

    ; IN
    ;   a = 待ち時間
    ; WORK
    ;   IOCS_0_WORK_0..1

    ; 待機
    sta     IOCS_0_WORK_0
    lda     #$00
    sta     IOCS_0_WORK_1
:
    dec     IOCS_0_WORK_1
    bne     :-
    dec     IOCS_0_WORK_0
    bne     :-

    ; 終了
    rts

.endproc

; エラーに対してリトライ待ちをする
;
.global _IocsRetry
.proc   _IocsRetry

    ; IN
    ;   ax = エラーメッセージ
    ; OUT
    ;   a  = キーコード

    ; MIX モードの設定
    sta     MIXSET

    ; メッセージの表示
    jsr     _IocsCoutString

    ; BEEP
    jsr     BELL

    ; キー入力待ち
:
    lda     KBD
    bpl     :-
    sta     KBDSTRB
    and     #$7f

    ; キーコードの保存
    pha

    ; 改行
    jsr     CROUT1

    ; MIX モードの解除
    sta     MIXCLR

    ; キーコードの復帰
    pla

    ; 終了
    rts

.endproc

; アプリケーションをエラー終了する
;
.global _IocsError
.proc   _IocsError

    ; IN
    ;   ax = エラーメッセージ

    ; テキストの設定
    sta     TXTSET
    sta     LOWSCR

    ; メッセージの表示
    jsr     _IocsCoutString

    ; BEEP
    jsr     BELL

    ; DOS への復帰
    jmp     DOSWARM

.endproc

; フォント
;
.global _iocs_font
_iocs_font:

.incbin     "resources/fonts/font-5.ts"

; かな
;
.if     IOCS_KANA
.global _iocs_kana
_iocs_kana:
.incbin     "resources/fonts/kana-7a.ts"
.incbin     "resources/fonts/kana-7b.ts"
.endif

; HiRes グラフィックス
;

; VRAM アドレス
.global _iocs_hgr_tile_y_address_low
_iocs_hgr_tile_y_address_low:

    .byte   <$2000, <$2080, <$2100, <$2180, <$2200, <$2280, <$2300, <$2380
    .byte   <$2028, <$20a8, <$2128, <$21a8, <$2228, <$22a8, <$2328, <$23a8
    .byte   <$2050, <$20d0, <$2150, <$21d0, <$2250, <$22d0, <$2350, <$23d0

.global _iocs_hgr_tile_y_address_high
_iocs_hgr_tile_y_address_high:

    .byte   >$2000, >$2080, >$2100, >$2180, >$2200, >$2280, >$2300, >$2380
    .byte   >$2028, >$20a8, >$2128, >$21a8, >$2228, >$22a8, >$2328, >$23a8
    .byte   >$2050, >$20d0, >$2150, >$21d0, >$2250, >$22d0, >$2350, >$23d0

; BEEP
;

; 1 周波数分の待機回数
.if     IOCS_BEEP
iocs_beep_freq_count:

    .byte   (IOCS_BEEP_CYCLE_O3C  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3Cp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3D  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3Dp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3E  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3F  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3Fp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3G  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3Gp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3A  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3Ap - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O3B  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4C  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4Cp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4D  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4Dp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4E  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4F  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4Fp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4G  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4Gp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4A  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4Ap - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O4B  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5C  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5Cp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5D  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5Dp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5E  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5F  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5Fp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5G  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5Gp - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5A  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5Ap - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_O5B  - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_PI   - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
    .byte   (IOCS_BEEP_CYCLE_PO   - IOCS_BEEP_CYCLE_BASE) / IOCS_BEEP_CYCLE_LOOP
.endif

; L256 の長さを再生ためのループ回数
.if     IOCS_BEEP
iocs_beep_l256_count:

    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3C
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3Cp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3D
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3Dp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3E
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3F
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3Fp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3G
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3Gp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3A
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3Ap
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O3B
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4C
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4Cp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4D
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4Dp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4E
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4F
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4Fp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4G
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4Gp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4A
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4Ap
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O4B
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5C
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5Cp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5D
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5Dp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5E
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5F
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5Fp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5G
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5Gp
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5A
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5Ap
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_O5B
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_PI
    .byte   IOCS_BEEP_CYCLE_L256 / IOCS_BEEP_CYCLE_PO
.endif


; 三角関数
;

; sin（小数部）
.if     IOCS_TRIGONOMETRIC
.global _iocs_sin_decimal
_iocs_sin_decimal:
    
    .byte   $00, $06, $0c, $12, $19, $1f, $25, $2b, $31, $38, $3e, $44, $4a, $50, $56, $5c
    .byte   $61, $67, $6d, $73, $78, $7e, $83, $88, $8e, $93, $98, $9d, $a2, $a7, $ab, $b0
    .byte   $b5, $b9, $bd, $c1, $c5, $c9, $cd, $d1, $d4, $d8, $db, $de, $e1, $e4, $e7, $ea
    .byte   $ec, $ee, $f1, $f3, $f4, $f6, $f8, $f9, $fb, $fc, $fd, $fe, $fe, $ff, $ff, $ff
    .byte   $00, $ff, $ff, $ff, $fe, $fe, $fd, $fc, $fb, $f9, $f8, $f6, $f4, $f3, $f1, $ee
    .byte   $ec, $ea, $e7, $e4, $e1, $de, $db, $d8, $d4, $d1, $cd, $c9, $c5, $c1, $bd, $b9
    .byte   $b5, $b0, $ab, $a7, $a2, $9d, $98, $93, $8e, $88, $83, $7e, $78, $73, $6d, $67
    .byte   $61, $5c, $56, $50, $4a, $44, $3e, $38, $31, $2b, $25, $1f, $19, $12, $0c, $06
    .byte   $00, $fa, $f4, $ee, $e7, $e1, $db, $d5, $cf, $c8, $c2, $bc, $b6, $b0, $aa, $a4
    .byte   $9f, $99, $93, $8d, $88, $82, $7d, $78, $72, $6d, $68, $63, $5e, $59, $55, $50
    .byte   $4b, $47, $43, $3f, $3b, $37, $33, $2f, $2c, $28, $25, $22, $1f, $1c, $19, $16
    .byte   $14, $12, $0f, $0d, $0c, $0a, $08, $07, $05, $04, $03, $02, $02, $01, $01, $01
    .byte   $00, $01, $01, $01, $02, $02, $03, $04, $05, $07, $08, $0a, $0c, $0d, $0f, $12
    .byte   $14, $16, $19, $1c, $1f, $22, $25, $28, $2c, $2f, $33, $37, $3b, $3f, $43, $47
    .byte   $4b, $50, $55, $59, $5e, $63, $68, $6d, $72, $78, $7d, $82, $88, $8d, $93, $99
    .byte   $9f, $a4, $aa, $b0, $b6, $bc, $c2, $c8, $cf, $d5, $db, $e1, $e7, $ee, $f4, $fa
.endif

; sin（整数部）
.if     IOCS_TRIGONOMETRIC
.global _iocs_sin_integer
_iocs_sin_integer:
    
    .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    .byte   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    .byte   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    .byte   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    .byte   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    .byte   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    .byte   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    .byte   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
.endif

; atan
.if     IOCS_TRIGONOMETRIC
iocs_atan2_angle:
    
    .byte   $20, $00, $00, $00, $00, $00, $00, $00
    .byte   $40, $20, $12, $0d, $09, $08, $06, $05
    .byte   $40, $2d, $20, $17, $12, $0f, $0d, $0b
    .byte   $40, $32, $28, $20, $1a, $16, $12, $10
    .byte   $40, $36, $2d, $25, $20, $1b, $17, $15
    .byte   $40, $37, $30, $29, $24, $20, $1c, $19
    .byte   $40, $39, $32, $2d, $28, $23, $20, $1c
    .byte   $40, $3a, $34, $2f, $2a, $26, $23, $20

iocs_atan2_offset:
    
    .byte   $00, $80, $00, $80
.endif
