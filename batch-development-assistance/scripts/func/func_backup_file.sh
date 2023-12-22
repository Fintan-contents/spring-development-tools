#!/bin/sh

#########################################################################
#  Script name  : func_backup_file.sh
#  Description  : ファイルをバックアップする（ファイル名：元ファイル名_%Y%m%d%H%M%S）
#  User         : batchuser
#  Usage        : func_backup_file.sh INPUT_DIR_PATH INPUT_FILE_NAME BACKUP_DIR_PATH
#                     INPUT_DIR_PATH
#                       バックアップ元ディレクトリパス（環境ごとのベースディレクトリからのパス）
#                     INPUT_FILE_NAME
#                       ファイル名
#                     BACKUP_DIR_PATH
#                       バックアップ先ディレクトリパス（環境ごとのベースディレクトリからのパス）
#  Date         : 2014/04/24
#  Returns      : 0   正常終了
#                 110 異常終了(引数過不足)
#                 111 異常終了(バックアップ元ディレクトリ変数名不正、
#                              またはバックアップ元ディレクトリが未存在)
#                 112 異常終了(バックアップ先ディレクトリ変数名不正、
#                              またはバックアップ先ディレクトリが未存在)
#                 113 異常終了(バックアップ元ファイルが未存在)
#                 114 異常終了(バックアップに失敗した場合)
#                 115 異常終了(ベースディレクトリ未存在)
########################################################################

### シェルスクリプト共通設定ファイルの読込 ###
. "${COMMON_CONF_DIR}"/common.sh

### ディレクトリ情報設定ファイルの読込 ###
. "${COMMON_CONF_DIR}"/batch_dir.config

### 障害メッセージ設定ファイルの読込 ###
. "${COMMON_DIR}"/conf/error.message

########################################################################
# スクリプト本文
########################################################################

### 処理開始ログ出力
LOG_MSG "PARAMETER = [${*}]"

### ベースディレクトリ存在チェック
if [ ! -d "${FILE_TRANCEFER_BASE_DIR}" ]; then
    LOG_MSG "${ES9999807}"
    LOG_MSG "PATH = ${FILE_TRANCEFER_BASE_DIR}"
    LOG_MSG "EXIT_CODE = [115]"
    exit 115
fi

### 引数個数精査
if [ ${#} -ne 3 ]; then
    LOG_MSG "${ES9999801}"
    LOG_MSG "EXIT_CODE = [110]"
    exit 110
fi

# 引数取得
INPUT_DIR_PATH=${FILE_TRANCEFER_BASE_DIR}/${1}
shift
INPUT_FILE_NAME=${1}
shift
BACKUP_DIR_PATH=${FILE_TRANCEFER_BASE_DIR}/${1}
shift

### バックアップ元ディレクトリパス存在チェック
if [ ! -d "${INPUT_DIR_PATH}" ]; then
    LOG_MSG "${ES9999802}"
    LOG_MSG "PATH = ${INPUT_DIR_PATH}"
    LOG_MSG "EXIT_CODE = [111]"
    exit 111
fi

### バックアップ先ディレクトリパス存在チェック
if [ ! -d "${BACKUP_DIR_PATH}" ]; then
    LOG_MSG "${ES9999803}"
    LOG_MSG "PATH = ${BACKUP_DIR_PATH}"
    LOG_MSG "EXIT_CODE = [112]"
    exit 112
fi

### バックアップ対象ファイルの存在チェック
INPUT_FILE_PATH=${INPUT_DIR_PATH}/${INPUT_FILE_NAME}
if [ ! -e "${INPUT_FILE_PATH}" ]; then
    LOG_MSG "${ES9999805}"
    LOG_MSG "PATH = ${INPUT_FILE_PATH}"
    LOG_MSG "EXIT_CODE = [113]"
    exit 113
fi

### 送受信ファイルバックアップ
DATE=$(date "+%Y%m%d%H%M%S")
BACKUP_FILE_PATH=${BACKUP_DIR_PATH}/${INPUT_FILE_NAME}_${DATE}


### バックアップが失敗した場合
if ! cp -pf "${INPUT_FILE_PATH}" "${BACKUP_FILE_PATH}"; then
    LOG_MSG "${ES9999806}"
    LOG_MSG "EXIT_CODE = [114]"
    exit 114
fi

### 終了処理ログ出力
LOG_MSG "INPUT_FILE = [${INPUT_FILE_PATH}]"
LOG_MSG "BACKUP_FILE = [${BACKUP_FILE_PATH}]"
LOG_MSG "EXIT_CODE = [0]"

exit 0