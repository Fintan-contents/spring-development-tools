#!/bin/sh

#################################################################################################
#  Script name  : func_put.sh
#  Description  : ファイル送信処理を行う
#                     SFTPを使用してファイルの送信を行う。
#  User         : batchuser
#  Usage        : func_put.sh TARGET_FILE FROM_DIR TO_DIR_VAR USER_NAME_VAR SERVER_NAME_VAR KEY_FILE_NAME
#                     TARGET_FILE
#                       授受対象ファイル名
#                     FROM_DIR
#                       授受元ディレクトリパス（環境ごとのベースディレクトリからのパス）
#                     TO_DIR_VAR
#                       授受先ディレクトリ変数名
#                     USER_NAME_VAR
#                       ユーザー変数名
#                     SERVER_NAME_VAR
#                       サーバー変数名
#                     KEY_FILE_NAME
#                       キーファイル名
#  Date         : 2014/04/28
#  Returns      : 0   正常終了
#                 110 異常終了(引数過不足)
#                 112 異常終了(授受元ディレクトリ変数名不正、または授受元ディレクトリ未存在)
#                 114 異常終了(授受対象ファイル未存在)
#                 115 異常終了(送達確認ファイル作成失敗)
#                 116 異常終了(ファイル授受失敗)
#                 117 異常終了(キーファイル未存在)
#                 118 異常終了(SFTPコマンド未インストール)
#                 119 異常終了(ベースディレクトリ未存在)
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
    LOG_MSG "${ES9999Y10}"
    LOG_MSG "PATH = ${FILE_TRANCEFER_BASE_DIR}"
    LOG_MSG "EXIT_CODE = [119]"
    exit 119
fi

### 引数個数精査
if [ ${#} -ne 6 ]; then
    LOG_MSG "${ES9999Y01}"
    LOG_MSG "EXIT_CODE = [110]"
    exit 110
fi

# 引数取得
TARGET_FILE=${1}
shift
eval FROM_DIR="${FILE_TRANCEFER_BASE_DIR}"/"${1}"
shift
eval TO_DIR='$'"${1}"
shift
eval USER_NAME='$'"${1}"
shift
eval SERVER_NAME='$'"${1}"
shift
KEY_FILE_NAME=${1}
shift

### SFTPコマンドの存在チェック
if ! which sftp; then
    LOG_MSG "${ES9999Y09}"
    LOG_MSG "EXIT_CODE = [118]"
    exit 118
fi

### 授受元ディレクトリパス存在チェック
TARGET_FILE_PATH=${FROM_DIR}/${TARGET_FILE}
if [ ! -d "${FROM_DIR}" ]; then
    LOG_MSG "${ES9999Y03}"
    LOG_MSG "PATH = ${FROM_DIR}"
    LOG_MSG "EXIT_CODE = [112]"
    exit 112
fi

### 授受対象インタフェースファイルの存在チェック
if [ ! -e "${TARGET_FILE_PATH}" ]; then
    LOG_MSG "${ES9999Y05}"
    LOG_MSG "PATH = ${TARGET_FILE_PATH}"
    LOG_MSG "EXIT_CODE = [114]"
    exit 114
fi

### キーファイルの存在チェック
KEY_FILE_PATH=${SFTP_KEY_DIR}/${KEY_FILE_NAME}
if [ ! -e "${KEY_FILE_PATH}" ]; then
    LOG_MSG "${ES9999Y08}"
    LOG_MSG "PATH = ${KEY_FILE_PATH}"
    LOG_MSG "EXIT_CODE = [117]"
    exit 117
fi

### ファイル授受処理
OUTPUT_FILE_PATH=${TO_DIR}/${TARGET_FILE}
HOST_NAME=${USER_NAME}@${SERVER_NAME}

### 送達確認ファイルパス
TARGET_END_FILE_PATH=${TARGET_FILE_PATH}.end
OUTPUT_END_FILE_PATH=${OUTPUT_FILE_PATH}.end

### 送達確認用ファイルを作成
if ! touch "${TARGET_END_FILE_PATH}"; then
    LOG_MSG "${ES9999Y06}"
    LOG_MSG "PATH = ${TARGET_END_FILE_PATH}"
    LOG_MSG "EXIT_CODE = [115]"
    exit 115
fi

### 送信処理用バッチ作成
### パスを動的に変更するため、本処理内でバッチを作成する
DATE=$(date "+%Y%m%d%H%M%S")
SFTP_BATCH_FILE_PATH="${COMMON_DIR}/func/sftp/"sftp_batch_${DATE}.sh
{
    echo "#!/bin/sh"
    echo put "${TARGET_FILE_PATH}" "${OUTPUT_FILE_PATH}"
    echo put "${TARGET_END_FILE_PATH}" "${OUTPUT_END_FILE_PATH}"
    echo quit
} > "${SFTP_BATCH_FILE_PATH}"

### SFTPの実行
sftp -b "${SFTP_BATCH_FILE_PATH}" -oIdentityFile="${KEY_FILE_PATH}" "${HOST_NAME}"
SFTP_EXIT_CODE=${?}

### バッチファイル削除
rm "${SFTP_BATCH_FILE_PATH}"

### ファイル授受に失敗した場合
if [ ${SFTP_EXIT_CODE} -ne 0 ]; then
    LOG_MSG "${ES9999Y07}"
    LOG_MSG "EXIT_CODE = [116]"
    exit 116
fi

### 終了処理ログ出力
LOG_MSG "EXIT_CODE = [${SFTP_EXIT_CODE}]"
LOG_MSG "TARGET_FILE = [${TARGET_FILE_PATH}]"
LOG_MSG "OUTPUT_FILE = [${OUTPUT_FILE_PATH}]"
exit ${SFTP_EXIT_CODE}

