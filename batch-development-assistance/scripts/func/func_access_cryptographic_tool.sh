#!/bin/sh

#################################################################################################
#  Script name  : func_access_cryptographic_tool.sh
#  Description  : 暗号化ツールを利用してファイルの暗号化/復号を行う
#  User         : batchuser
#  Usage        : func_access_cryptographic_tool.sh SRI_KBN INPUT_FILE INPUT_DIR_PATH OUTPUT_DIR_PATH KEY_FILE_NAME SIZE_CHK_KBN
#                     SRI_KBN
#                       処理区分
#                       (暗号化:0、復号:1)
#                     INPUT_FILE
#                       暗号化/復号対象ファイル名
#                     INPUT_DIR_PATH
#                       入力元ディレクトリパス（環境ごとのベースディレクトリからのパス）
#                     OUTPUT_DIR_PATH
#                       出力先ディレクトリパス（環境ごとのベースディレクトリからのパス）
#                     KEY_FILE_NAME
#                       キーファイル名
#                     SIZE_CHK_KBN
#                       対象ファイル0バイト精査区分
#                       (0:精査なし  1:精査あり)
#  Date         : 2014/04/28
#  Returns      : 0   正常終了
#                 110 異常終了(引数過不足)
#                 111 異常終了(処理区分不正)
#                 112 異常終了(入力元ディレクトリ変数名不正、または入力元ディレクトリ未存在)
#                 113 異常終了(出力先ディレクトリ変数名不正、または出力先ディレクトリ未存在)
#                 114 異常終了(暗号化/復号対象ファイル未存在)
#                 115 異常終了(キーファイル未存在)
#                 116 異常終了(暗号化/復号失敗)
#                 118 異常終了(対象ファイル0バイト精査区分不正)
#                 119 異常終了(暗号化/復号対象ファイルコピー失敗)
#                 120 異常終了(0バイトファイルエラー)
#                 121 異常終了(ベースディレクトリ未存在)
################################################################################################

### シェルスクリプト共通設定ファイルの読込 ###
. "${COMMON_CONF_DIR}"/common.sh

### ディレクトリ情報設定ファイルの読込 ###
. "${COMMON_CONF_DIR}"/batch_dir.config

### 障害メッセージ設定ファイルの読込 ###
. "${COMMON_DIR}"/conf/error.message

################################################################################################
# スクリプト本文
################################################################################################

### 処理開始ログ出力
LOG_MSG "PARAMETER = [${*}]"

### ベースディレクトリ存在チェック
if [ ! -d "${FILE_TRANCEFER_BASE_DIR}" ]; then
    LOG_MSG "${ES9999X11}"
    LOG_MSG "PATH = ${FILE_TRANCEFER_BASE_DIR}"
    LOG_MSG "EXIT_CODE = [121]"
    exit 121
fi

### 引数個数精査
if [ ${#} -ne 6 ]; then
    LOG_MSG "${ES9999X01}"
    LOG_MSG "EXIT_CODE = [110]"
    exit 110
fi

### 引数取得
SRI_KBN=${1}
shift
INPUT_FILE=${1}
shift
INPUT_DIR_PATH=${FILE_TRANCEFER_BASE_DIR}/${1}
shift
OUTPUT_DIR_PATH=${FILE_TRANCEFER_BASE_DIR}/${1}
shift
KEY_FILE_NAME=${1}
shift
SIZE_CHK_KBN=${1}
shift

### 処理区分精査
if [ "${SRI_KBN}" -ne 0 ] && [ "${SRI_KBN}" -ne 1 ]; then
    LOG_MSG "${ES9999X02}"
    LOG_MSG "EXIT_CODE = [111]"
    exit 111
fi

### 対象ファイル0バイト精査区分精査
if [ "${SIZE_CHK_KBN}" -ne 0 ] && [ "${SIZE_CHK_KBN}" -ne 1 ]; then
    LOG_MSG "${ES9999X03}"
    LOG_MSG "EXIT_CODE = [118]"
    exit 118
fi

### 入力元ディレクトリ存在チェック
if [ ! -d "${INPUT_DIR_PATH}" ]; then
    LOG_MSG "${ES9999X04}"
    LOG_MSG "PATH = ${INPUT_DIR_PATH}"
    LOG_MSG "EXIT_CODE = [112]"
    exit 112
fi

### 出力先ディレクトリ存在チェック
if [ ! -d "${OUTPUT_DIR_PATH}" ]; then
    LOG_MSG "${ES9999X05}"
    LOG_MSG "PATH = ${OUTPUT_DIR_PATH}"
    LOG_MSG "EXIT_CODE = [113]"
    exit 113
fi

### 暗号化/復号対象ファイルの存在チェック
INPUT_FILE_PATH=${INPUT_DIR_PATH}/${INPUT_FILE}
if [ ! -e "${INPUT_FILE_PATH}" ]; then
    LOG_MSG "${ES9999X06}"
    LOG_MSG "PATH = ${INPUT_FILE_PATH}"
    LOG_MSG "EXIT_CODE = [114]"
    exit 114
fi

### 暗号化/復号対象ファイルサイズが0バイトの場合
OUTPUT_FILE_PATH=${OUTPUT_DIR_PATH}/${INPUT_FILE}
if [ ! -s "${INPUT_FILE_PATH}" ]; then

    ### 暗号化/復号対象ファイルサイズ0バイト精査
    if [ "${SIZE_CHK_KBN}" -eq 0 ]; then
        ### 暗号化/復号対象ファイルを出力先ディレクトリにコピー
        if ! cp -f "${INPUT_FILE_PATH}" "${OUTPUT_FILE_PATH}"; then
            ### コピーに失敗した場合
            LOG_MSG "${ES9999X07}"
            LOG_MSG "from ${INPUT_FILE_PATH} to ${OUTPUT_FILE_PATH}"
            LOG_MSG "EXIT_CODE = [119]"
            exit 119
        fi
        OPENSSL_EXIT_CODE="0"
    else
        LOG_MSG "${ES9999X08}"
        LOG_MSG "PATH = ${INPUT_FILE_PATH}"
        LOG_MSG "EXIT_CODE = [120]"
        exit 120
    fi

### 暗号化/復号対象ファイルサイズが0バイトではない場合
else
    ### キーファイルの存在チェック
    KEY_FILE_PATH=${CRYPT_KEY_DIR}/${KEY_FILE_NAME}
    if [ ! -e "${KEY_FILE_PATH}" ]; then
        LOG_MSG "${ES9999X09}"
        LOG_MSG "PATH = ${KEY_FILE_PATH}"
        LOG_MSG "EXIT_CODE = [115]"
        exit 115
    fi

    ### OpenSSLの実行
    if [ "${SRI_KBN}" -eq "0" ]; then
      openssl enc -e -aes256 -in "${INPUT_FILE_PATH}" -out "${OUTPUT_FILE_PATH}" -kfile "${KEY_FILE_PATH}"
    else
      openssl enc -d -aes256 -in "${INPUT_FILE_PATH}" -out "${OUTPUT_FILE_PATH}" -kfile "${KEY_FILE_PATH}"
    fi
    OPENSSL_EXIT_CODE=${?}
    LOG_MSG "OPENSSL_EXIT_CODE = [${OPENSSL_EXIT_CODE}]"

    ### 暗号化/復号に失敗した場合
    if [ ${OPENSSL_EXIT_CODE} -ne 0 ]; then
        LOG_MSG "${ES9999X10}"
        LOG_MSG "EXIT_CODE = [116]"
        exit 116
    fi
fi

### 終了処理ログ出力
LOG_MSG "EXIT_CODE = [${OPENSSL_EXIT_CODE}]"
LOG_MSG "INPUT_FILE = [${INPUT_FILE_PATH}]"
LOG_MSG "OUTPUT_FILE = [${OUTPUT_FILE_PATH}]"
exit ${OPENSSL_EXIT_CODE}

