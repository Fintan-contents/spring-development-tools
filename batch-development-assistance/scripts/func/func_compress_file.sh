#!/bin/sh

#################################################################################
#  Script name  : func_compress_file.sh
#  Description  : ファイル圧縮
#  User         : batchuser
#  Usage        : func_compress_file.sh COMPRESSION_DIR_PATH COMPRESSION_TARGET_DIR_NAME COMPRESSION_FILE_NAME SIZE_CHK_KBN
#                     COMPRESSION_DIR_PATH
#                       圧縮共通ディレクトリパス（環境ごとのベースディレクトリからのパス）
#                     COMPRESSION_TARGET_DIR_NAME
#                       圧縮対象ファイル配置ディレクトリ名
#                     COMPRESSION_FILE_NAME
#                       圧縮後のファイル名
#                     SIZE_CHK_KBN
#                       対象ファイル0バイト精査区分
#                       (0:精査なし  1:精査あり)
#  Date         : 2014/04/28
#  Returns      : 0   正常終了
#                 110 異常終了(引数指定過不足)
#                 111 異常終了(ディレクトリ変数名取得失敗またはディレクトリ未存在)
#                 112 異常終了(圧縮対象ファイル未存在)
#                 113 異常終了(圧縮失敗)
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
    LOG_MSG "${ES9999W08}"
    LOG_MSG "PATH = ${FILE_TRANCEFER_BASE_DIR}"
    LOG_MSG "EXIT_CODE = [116]"
    exit 116
fi

### 引数個数精査
if [ ${#} -ne 4 ]; then
    LOG_MSG "${ES9999W01}"
    LOG_MSG "EXIT_CODE = [110]"
    exit 110
fi

### 引数取得
COMPRESSION_DIR_PATH=${FILE_TRANCEFER_BASE_DIR}/${1}
shift
COMPRESSION_TARGET_DIR_NAME=${1}
shift
COMPRESSION_FILE_NAME=${1}
shift
SIZE_CHK_KBN=${1}
shift

### 対象ファイル0バイト精査区分精査
if [ "${SIZE_CHK_KBN}" -ne 0 ] && [ "${SIZE_CHK_KBN}" -ne 1 ]; then
    LOG_MSG "${ES9999W06}"
    LOG_MSG "EXIT_CODE = [114]"
    exit 114
fi

### 圧縮共通ディレクトリ存在チェック
if [ ! -d "${COMPRESSION_DIR_PATH}" ]; then
    LOG_MSG "${ES9999W02}"
    LOG_MSG "PATH = ${COMPRESSION_DIR_PATH}"
    LOG_MSG "EXIT_CODE = [111]"
    exit 111
fi

### 圧縮対象ファイル配置ディレクトリ存在チェック
COMPRESSION_TARGET_PATH=${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}
if [ ! -d "${COMPRESSION_TARGET_PATH}" ]; then
    LOG_MSG "${ES9999W04}"
    LOG_MSG "PATH = ${COMPRESSION_TARGET_PATH}"
    LOG_MSG "EXIT_CODE = [111]"
    exit 111
fi

### 圧縮対象ファイル存在精査
if [ "$(find "${COMPRESSION_TARGET_PATH}" -name '*' -type f | wc -l)" -le 0 ]; then
    LOG_MSG "${ES9999W03}"
    LOG_MSG "PATH = ${COMPRESSION_TARGET_PATH}"
    LOG_MSG "EXIT_CODE = [112]"
    exit 112
fi

### ファイル0バイト精査
### 対象ディレクトリに0バイトファイルが存在するかをチェック
COMPRESSION_FILE_PATH=${COMPRESSION_DIR_PATH}/${COMPRESSION_FILE_NAME}
while IFS= read -r file_path_name
do
    if [ ! -s "${file_path_name}" ]; then
        if [ "${SIZE_CHK_KBN}" -eq 0 ]; then
            # 0バイトファイルを許容する場合、指定したファイル名で空ファイルを作成する
            touch "${COMPRESSION_FILE_PATH}"
            LOG_MSG "COMPRESSION_TARGET_PATH = [${COMPRESSION_TARGET_PATH}]"
            LOG_MSG "COMPRESSION_FILE_PATH = [${COMPRESSION_FILE_PATH}]"
            LOG_MSG "EXIT_CODE = [0]"
            exit 0
        else
            LOG_MSG "${ES9999W07}"
            LOG_MSG "PATH = ${file_path_name}"
            LOG_MSG "EXIT_CODE = [115]"
            exit 115
        fi
    fi
done << EOF
$(find "${COMPRESSION_TARGET_PATH}" -name "*" -type f)
EOF

### 圧縮対象ファイル配置ディレクトリに移動
### 圧縮時のファイルパスが絶対パスだと、解凍時に意図しない上書きが発生する可能性があるため、相対パスで指定する
if ! cd "${COMPRESSION_TARGET_PATH}"; then
    LOG_MSG "${ES9999W04}"
    LOG_MSG "EXIT_CODE = [111]"
    exit 111
fi

### 対象ファイルの圧縮
if ! find . -name "*" -type f -print0 | tar cvzf "${COMPRESSION_FILE_PATH}" --null -T -; then
    ### 対象ファイルの圧縮に失敗した場合
    LOG_MSG "${ES9999W05}"
    LOG_MSG "EXIT_CODE = [113]"
    exit 113
fi

### 処理終了ログ出力
LOG_MSG "COMPRESSION_TARGET_PATH = [${COMPRESSION_TARGET_PATH}]"
LOG_MSG "COMPRESSION_FILE_PATH = [${COMPRESSION_FILE_PATH}]"
LOG_MSG "EXIT_CODE = [0]"

exit 0
