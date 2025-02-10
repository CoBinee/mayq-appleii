// 参照ファイルのインクルード
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sys/stat.h>
#include <png.h>



// メインプログラムのエントリ
//
int main(int argc, const char *argv[])
{
    // 入力ファイル名の初期化
    const char *inname = NULL;
    
    // 出力ファイル名の初期化
    const char *outname = NULL;
    
    // 引数の取得
    while (--argc > 0) {
        ++argv;
        if (strcasecmp(*argv, "-o") == 0) {
            outname = *++argv;
            --argc;
        } else {
            inname = *argv;
        }
    }
    
    // 入力ファイルがない
    if (inname == NULL) {
        return -1;
    }

    // 出力ファイル名の取得
    if (outname == NULL) {
        int length = strlen(inname);
        int i = length;
        while (i > 0 && inname[i - 1] != '/' && inname[i - 1] != '\\') {
            --i;
        }
        while (i < length && inname[i] != '.') {
            ++i;
        }
        char *s = new char[i + 5];
        strncpy(&s[0], inname, i);
        strcpy(&s[i], ".png");
        outname = s;
    }

    // 処理の開始
    fprintf(stdout, "chr2png ...\n");
    
    // .chr ファイルの読み込み
    fprintf(stdout, ".chr: %s\n", inname);
    unsigned char *chr_data = NULL;
    int chr_size = 0;
    {
        // .chr ファイルを開く
        FILE *file = fopen(inname, "rb");
        if (file == NULL) {
            fprintf(stderr, "error: file is not open.\n");
            return -1;
        }

        // ファイルサイズの取得
        struct stat statbuff;
        stat(inname, &statbuff);
        chr_size = (int)statbuff.st_size;

        // ファイルの読み込み
        chr_data = new unsigned char[chr_size];
        fread(chr_data, chr_size, 1, file);

        // .chr ファイルを閉じる
        fclose(file);
    }

    // .pngファイルへの書き出し
    fprintf(stdout, ".png: %s\n", outname);
    {
        // 画像サイズの取得
        int png_width = 128;
        int png_height = chr_size / 16;
        fprintf(stdout, "image: %d x %d\n", png_width, png_height);

        // .png ファイルを開く
        FILE *file = fopen(outname, "w");
        if (file == NULL) {
            fprintf(stderr, "error: file is not open.\n");
            return -1;
        }

        // .png 構造体の初期化
        png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
        if (png == NULL) {
            fprintf(stderr, "error: png struct is not create.\n");
            return -1;
        }
        png_infop info = png_create_info_struct(png);
        if (info == NULL) {
            fprintf(stderr, "error: png info struct is not create.\n");
            return -1;
        }

        // ファイルを渡す
        png_init_io(png, file);

        // 画像情報の登録
        png_set_IHDR(png, info, png_width, png_height, 8, PNG_COLOR_TYPE_PALETTE, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);

        // 画像メモリの確保
        png_bytepp rows = (png_bytepp)png_malloc(png, sizeof(png_bytep) * png_height);
        if (rows == NULL) {
            fprintf(stderr, "error: png memory is not allocate.\n");
            return -1;
        }
        memset(rows, 0, sizeof(png_bytep) * png_height);
        for (int i = 0; i < png_height; i++) {
            rows[i] = (png_bytep)png_malloc(png, sizeof(png_byte) * png_width);
            if (rows[i] == NULL) {
                fprintf(stderr, "error: png memory is not allocate.\n");
                return -1;
            }
        }
        png_set_rows(png, info, rows);

        // パレット情報の登録
        {
            png_colorp palette = (png_colorp)png_malloc(png, sizeof(png_color) * 256);
            for (int i = 0; i < 256; i++) {
                palette[i].red = 0x00;
                palette[i].green = 0x00;
                palette[i].blue = 0x00;
            }
            unsigned long tms9918[] = {
                0x000000, 0x000000, 0x3EB849, 0x74D07D, 0x5955E0, 0x8076F1, 0xB95E51, 0x65DBEF, 
                0xDB6559, 0xFF897D, 0xCCC35E, 0xDED087, 0x3AA241, 0xB766B5, 0xCCCCCC, 0xFFFFFF, 
            };
            for (int i = 0; i < 16; i++) {
                palette[i].red = (tms9918[i] >> 16) & 0xff;
                palette[i].green = (tms9918[i] >> 8) & 0xff;
                palette[i].blue = tms9918[i] & 0xff;
            }
            png_set_PLTE(png, info, palette, 256);
            png_free(png, palette);
        }

        // 画像の登録
        {
            for (int y = 0; y < png_height; y++) {
                png_bytep p = rows[y];
                for (int x = 0; x < png_width; x++) {
                    if ((chr_data[((y / 8) * (0x08 * 0x10)) + ((x / 8) * 0x08) + (y % 8)] & (0x80 >> (x % 8))) != 0) {
                        *p = 0x0f;
                    } else {
                        *p = 0x00;
                    }
                    ++p;
                }
            }
        }

        // .png ファイルの書き出し
        png_write_png(png, info, PNG_TRANSFORM_IDENTITY, NULL);

        // 画像メモリの解放
        for (int i = png_height - 1; i >= 0; i--) {
            png_free(png, rows[i]);
        }
        png_free(png, rows);

        // .png 構造体の解放
        png_destroy_write_struct(&png, &info);

        // .png ファイルを閉じる
        fclose(file);
    }

    // .chr の解放
    if (chr_data != NULL) {
        delete[] chr_data;
    }

    // 処理の完了
    fprintf(stdout, "done.\n");

    // 終了
    return 0;
}


