#!/bin/sh

#################################################################################
#  Script name  : func_rename_file.sh
#  Description  : ファイルをリネームする
#  User         : batchuser
#  Usage        : func_rename_file.sh SEND_DIR_PATH INPUT_FILE_NAME RECEIVE_DIR_PATH MOVE_FILE_NAME OVERWRITE_FLG PROC_PATTERN
#                     SEND_DIR_PATH
#                       リネーム・コピー元ディレクトリパス（環境ごとのベースディレクトリからのパス）
#                     INPUT_FILE_NAME
#                       リネーム・コピー元ファイル名
#                     RECEIVE_DIR_PATH
#                       リネーム・コピー先ディレクトリパス（環境ごとのベースディレクトリからのパス）
#                     MOVE_FILE_NAME
#                       リネーム・コピー先ファイル名
#                     OVERWRITE_FLG
#                       リネーム・コピー先ファイルの上書き可否
#                       (上書き可:1、上書き否:0)
#                     PROC_PATTERN
#                       ファイル処理方法
#                       (ファイルコピー:1、ファイルリネーム:0)
#  Date         : 2014/03/27
#  Returns      : 0   正常終了
#                 110 異常終了(引数指定過不足)
#                 111 異常終了(上書き可否引数不正)
#                 112 異常終了(ファイル処理方法不正)
#                 113 異常終了(リネーム・コピー元ディレクトリ変数名不正、または
#                              リネーム・コピー元ディレクトリが存在しない場合)
#                 114 異常終了(リネーム・コピー先ディレクトリ変数名不正、または
#                              リネーム・コピー先ディレクトリが存在しない場合)
#                 115 異常終了(リネーム・コピー元ファイル未存在)
#                 116 異常終了(リネーム・コピー先に同名ファイル存在)
#                 117 異常終了(コピーまたはリネームに失敗)
#                 118 異常終了(ベースディレクトリ未存在)
#################################################################################

### シェルスクリプト共通設定ファイルの読込 ###
. "${COMMON_CONF_DIR}"/common.sh

### ディレクトリ情報読み込み ###
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
    LOG_MSG "${ES9999510}"
    LOG_MSG "PATH = ${FILE_TRANCEFER_BASE_DIR}"
    LOG_MSG "EXIT_CODE = [118]"
    exit 118
fi

### 引数個数精査
if [ ${#} -ne 6 ]; then
    LOG_MSG "${ES9999501}"
    LOG_MSG "EXIT_CODE = [110]"
    exit 110
fi

# 引数取得
SEND_DIR_PATH=${FILE_TRANCEFER_BASE_DIR}/${1}
shift
INPUT_FILE_NAME=${1}
shift
RECEIVE_DIR_PATH=${FILE_TRANCEFER_BASE_DIR}/${1}
shift
MOVE_FILE_NAME=${1}
shift
OVERWRITE_FLG=${1}
shift
PROC_PATTERN=${1}
shift

### 上書き可否のパターンチェック
if [ "${OVERWRITE_FLG}" -ne 0 ] && [ "${OVERWRITE_FLG}" -ne 1 ]; then
    LOG_MSG "${ES9999502}"
    LOG_MSG "EXIT_CODE = [111]"
    exit 111
fi

### 処理パターンのパターンチェック
if [ "${PROC_PATTERN}" -ne 0 ] && [ "${PROC_PATTERN}" -ne 1 ]; then
    LOG_MSG "${ES9999503}"
    LOG_MSG "EXIT_CODE = [112]"
    exit 112
fi

### リネーム・コピー元ディレクトリパス存在チェック
if [ ! -d "${SEND_DIR_PATH}" ]; then
    LOG_MSG "${ES9999504}"
    LOG_MSG "PATH = ${SEND_DIR_PATH}"
    LOG_MSG "EXIT_CODE = [113]"
    exit 113
fi

### リネーム・コピー先ディレクトリパス存在チェック
if [ ! -d "${RECEIVE_DIR_PATH}" ]; then
    LOG_MSG "${ES9999505}"
    LOG_MSG "PATH = ${RECEIVE_DIR_PATH}"
    LOG_MSG "EXIT_CODE = [114]"
    exit 114
fi

### リネーム・コピー元ファイル存在チェック
INPUT_FILE_PATH=${SEND_DIR_PATH}/${INPUT_FILE_NAME}
if [ ! -e "${INPUT_FILE_PATH}" ]; then
    LOG_MSG "${ES9999507}"
    LOG_MSG "PATH = ${INPUT_FILE_PATH}"
    LOG_MSG "EXIT_CODE = [115]"
    exit 115
fi

### リネーム・コピー先ファイル存在チェック
MOVE_FILE_PATH=${RECEIVE_DIR_PATH}/${MOVE_FILE_NAME}
if [ "${OVERWRITE_FLG}" -eq  0 ] && [ -e "${MOVE_FILE_PATH}" ]; then
    LOG_MSG "${ES9999508}"
    LOG_MSG "PATH = ${MOVE_FILE_PATH}"
    LOG_MSG "EXIT_CODE = [116]"
    exit 116
fi

### 対象ファイルのリネーム・コピー
if [ "${OVERWRITE_FLG}" -eq 1 ] && [ "${PROC_PATTERN}" -eq 1 ]; then
    cp -pf "${INPUT_FILE_PATH}" "${MOVE_FILE_PATH}"
elif [ "${OVERWRITE_FLG}" -eq 0 ] && [ "${PROC_PATTERN}" -eq 1 ]; then
    cp -p "${INPUT_FILE_PATH}" "${MOVE_FILE_PATH}"
elif [ "${OVERWRITE_FLG}" -eq 1 ] && [ "${PROC_PATTERN}" -eq 0 ]; then
    mv -f "${INPUT_FILE_PATH}" "${MOVE_FILE_PATH}"
elif [ "${OVERWRITE_FLG}" -eq 0 ] && [ "${PROC_PATTERN}" -eq 0 ]; then
    mv "${INPUT_FILE_PATH}" "${MOVE_FILE_PATH}"
fi
RENAME_COPY_STATUS=${?}

### 対象ファイルのリネーム・コピーに失敗した場合
if [ ${RENAME_COPY_STATUS} -ne 0 ]; then
    LOG_MSG "${ES9999509}"
    LOG_MSG "EXIT_CODE = [117]"
    exit 117
fi

### 処理終了ログ出力
LOG_MSG "INPUT_FILE_PATH = [${INPUT_FILE_PATH}]"

if [ "${PROC_PATTERN}" -eq 0 ]; then
    LOG_MSG "MOVE_FILE_PATH = [${MOVE_FILE_PATH}]"
elif [ "${PROC_PATTERN}" -eq 1 ]; then
    LOG_MSG "COPY_FILE_PATH = [${MOVE_FILE_PATH}]"
fi

LOG_MSG "EXIT_CODE = [0]"

exit 0
