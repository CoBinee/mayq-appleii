; lib.s - ライブラリ
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
.include    "lib.inc"


; コードの定義
;
.segment    "BOOT"

; ライブラリを初期化する
;
.global _LibInitialize
.proc   _LibInitialize

    ; ライブラリの初期化

    ; 終了
    rts

.endproc


; データの定義
;
.segment    "BSS"

