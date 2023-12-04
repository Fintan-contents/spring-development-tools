#!/bin/sh

#################################################################################
#  Script name  : func_extract_file.sh
#  Description  : 圧縮ファイル解凍
#  User         : batchuser
#  Usage        : func_extract_file.sh EXTRACTION_DIR_PATH EXTRACTION_FILE_NAME SIZE_CHK_KBN
#                     EXTRACTION_DIR_PATH
#                       解凍共通ディレクトリパス（環境ごとのベースディレクトリからのパス）
#                     EXTRACTION_FILE_NAME
#                       ファイル名
#                     SIZE_CHK_KBN
#                       対象ファイル0バイト精査区分
#                       (0:精査なし  1:精査あり)
#  Date         : 2014/04/28
#  Returns      : 0   正常終了
#                 110 異常終了(引数指定過不足)
#                 111 異常終了(ディレクトリ変数名取得失敗またはディレクトリ未存在)
#                 112 異常終了(ファイル未存在)
#                 113 異常終了(解凍失敗)
#                 114 異常終了(対象ファイル0バイト精査区分不正)
#                 115 異常終了(0バイトファイルエラー)
#                 116 異常終了(ベースディレクトリ未存在)
#################################################################################

### シェルスクリプト共通設定ファイルの読込 ###
. "${COMMON_CONF_DIR}"/common.sh

### ディレクトリ情報設定ファイルの読込 ###
. "${COMMON_CONF_DIR}"/batch_dir.config

### 障害メッセージ設定ファイルの読込 ###
. "${COMMON_DIR}"/conf/error.message

#################################################################################
# スクリプト本文
#################################################################################

### 処理開始ログ出力
LOG_MSG "PARAMETER = [${*}]"

### ベースディレクトリ存在チェック
if [ ! -d "${FILE_TRANCEFER_BASE_DIR}" ]; then
    LOG_MSG "${ES9999V08}"
    LOG_MSG "PATH = ${FILE_TRANCEFER_BASE_DIR}"
    LOG_MSG "EXIT_CODE = [116]"
    exit 116
fi

### 引数個数精査
if [ ${#} -ne 3 ]; then
    LOG_MSG "${ES9999V01}"
    LOG_MSG "EXIT_CODE = [110]"
    exit 110
fi

# 引数取得
EXTRACTION_DIR_PATH=${FILE_TRANCEFER_BASE_DIR}/${1}
shift
EXTRACTION_FILE_NAME=${1}
shift
SIZE_CHK_KBN=${1}
shift


### 解凍共通ディレクトリ存在チェック
if [ ! -d "${EXTRACTION_DIR_PATH}" ]; then
    LOG_MSG "${ES9999V02}"
    LOG_MSG "PATH = ${EXTRACTION_DIR_PATH}"
    LOG_MSG "EXIT_CODE = [111]"
    exit 111
fi

### 対象ファイル0バイト精査区分精査
if [ "${SIZE_CHK_KBN}" -ne 0 ] && [ "${SIZE_CHK_KBN}" -ne 1 ]; then
    LOG_MSG "${ES9999V06}"
    LOG_MSG "EXIT_CODE = [114]"
    exit 114
fi

### 解凍前ファイル存在チェック
EXTRACTION_FILE_PATH=${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}
EXTRACTION_FILE_RENAME_PATH=${EXTRACTION_FILE_PATH}.org

### 解凍前ファイルが存在する場合
if [ -e "${EXTRACTION_FILE_PATH}" ]; then

    ### 暗号化/復号化対象インタフェースファイルサイズ0バイト精査
    if [ ! -s "${EXTRACTION_FILE_PATH}" ]; then
        if [ "${SIZE_CHK_KBN}" -eq 0 ]; then
            LOG_MSG "EXIT_CODE = [0]"
            exit 0
        else
            LOG_MSG "${ES9999V07}"
            LOG_MSG "PATH = ${EXTRACTION_FILE_PATH}"
            LOG_MSG "EXIT_CODE = [115]"
            exit 115
        fi
    fi
    
    ### ファイル名が重複するのを避けるため、解凍前一時ファイル名にリネーム
    mv -f "${EXTRACTION_FILE_PATH}" "${EXTRACTION_FILE_RENAME_PATH}"

### 解凍前ファイルと解凍前一時ファイル両方が無い場合
elif [ ! -e "${EXTRACTION_FILE_RENAME_PATH}" ]; then
    LOG_MSG "${ES9999V04}"
    LOG_MSG "PATH = ${EXTRACTION_FILE_PATH}"
    LOG_MSG "RENAME_PATH = ${EXTRACTION_FILE_RENAME_PATH}"
    LOG_MSG "EXIT_CODE = [112]"
    exit 112
fi

### 対象ファイルの解凍
if ! tar zxvf "${EXTRACTION_FILE_RENAME_PATH}" -C "${EXTRACTION_DIR_PATH}"; then
    ### 対象ファイルの解凍に失敗した場合
    LOG_MSG "${ES9999V05}"
    LOG_MSG "EXIT_CODE = [113]"
    exit 113
fi

### 解凍前一時ファイルを削除
rm -f "${EXTRACTION_FILE_RENAME_PATH}"

### 処理終了ログ出力
LOG_MSG "EXTRACTION_FILE_PATH = [${EXTRACTION_FILE_PATH}]"
LOG_MSG "EXIT_CODE = [0]"

exit 0
