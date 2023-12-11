#!/bin/sh

####################################################################################
#  Script name  : func_mail_send.sh
#  Description  : メール送信バッチプログラムを実行する
#  Server type  : Batch Server
#  User         : batchuser
#  Usage        : func_mail_send.sh JOB_ID [ARGS]...
#                     JOB_ID
#                       ジョブID
#                     ARGS
#                       javaコマンドの末尾に渡す引数。
#                       Spring Bootプロパティやジョブパラメータを渡す。
#  Date         : 2022/10/18
#  Returns      : Javaプログラムが返す終了コードをそのまま返却する
####################################################################################

### シェルスクリプト共通設定ファイルの読込 ###
. "${COMMON_CONF_DIR}"/common.sh

### ディレクトリ情報読み込み ###
. "${COMMON_CONF_DIR}"/batch_dir.config

### JAVA実行情報読み込み ###
. "${COMMON_CONF_DIR}"/java_env.config

### JAVA実行共通関数読み込み ###
. "${COMMON_DIR}"/func/conf/func_java_common.sh

####################################################################################
# スクリプト本文
####################################################################################

### 処理開始ログの出力 ###
LOG_MSG "PARAMETER = [${INP_JAVA_OPT} ${*}]"

### 引数情報を取得 ###
JOB_ID=${1}
shift

### 多重起動チェック
DUPLICATE_PROCESS_CHECK "${JOB_ID}"

### JARをプロセス毎にジョブ管理システム配下にコピーする。 ###
RUN_LIB_OUT_DIR=${RUN_LIB_OUT}/${JOB_ID}
DELETE_DIR "${RUN_LIB_OUT_DIR}"
COPY_RUN_JARS "${RUN_LIB_OUT_DIR}"
RUN_JAR_PATH=${RUN_LIB_OUT_DIR}/$(basename "${RUN_LIB_PATH}")

### 実行オプションの生成 ###
JAVA_OPT="${MAIL_OPT} ${INP_JAVA_OPT} "

### バッチ実行 ###
eval "${JAVA_HOME_PATH}"/bin/java "${JAVA_OPT}" -jar "${RUN_JAR_PATH}" "$*" &

### 処理終了ログの出力 ###
EXIT_CODE=${?}
LOG_MSG "EXIT_CODE = [${EXIT_CODE}]"

exit ${EXIT_CODE}

