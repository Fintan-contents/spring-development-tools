#!/bin/sh

####################################################################################
#  File name    : common.sh
#  Description  : シェルスクリプトで共通的に使用する変数、関数を定義する。
#  Date         : 2011/12/1
####################################################################################

###################################################
# 変数定義
###################################################
## コマンド名取得
CMD=${0##*/}

###################################################
# 関数定義
###################################################

###################################################
# Function      : LOG_MSG
# Description   : ログメッセージを表示する。
#                   引数に渡されたメッセージに次の情報を付与し、ログメッセージを表示する。
#                   ・日付
#                   ・ホスト名
#                   ・実行ユーザ名
#                   ・呼び出し元コマンド名
# Usage         : LOG_MSG MESSAGE
#                   MESSAGE
#                       表示するメッセージ
###################################################
LOG_MSG () {

    DATE_AT_LOGGING=$(date "+%Y/%m/%d %H:%M:%S")
    RNNODE=$(hostname)
    RNUSER=$(whoami)
    MSG_TO_DISP=${1}
    echo "${DATE_AT_LOGGING} ${RNNODE} ${RNUSER} : [ ${CMD} ] ${MSG_TO_DISP}"
}

###################################################
# Function      : LOG_HEADER
# Description   : ログヘッダーを表示する。
# Usage         : LOG_HEADER
###################################################
LOG_HEADER () {

    echo "###################################################"
    echo "##  $(date "+%Y/%m/%d %H:%M:%S")  < ${CMD} > START"
    echo "###################################################"
    LOG_MSG "Script was Started" 
}

###################################################
# Function      : LOG_FOOTER
# Description   : ログフッターを表示する。
# Usage         : LOG_FOOTER
###################################################
LOG_FOOTER () {

    LOG_MSG "Script was Finished"
    echo "###################################################"
    echo "##  $(date "+%Y/%m/%d %H:%M:%S")  < ${CMD} > END"
    echo "###################################################"
}

###################################################
# Function      : RUN_CHILD_SCRIPT
# Description   : 引数で指定された子スクリプトを実行する。
#                 手動実行の際のログファイルを指定したい場合には、呼び出し元にてLOG_NAME変数を宣言し、記述しておくこと。
#                 また、LOG_NAMEを宣言しない場合には、ジョブ管理システムディレクトリパスJOB_SHELL_DIRが記述されている
#                 設定ファイルを"."コマンドで読み込んでいること。
# Usage         : RUN_CHILD_SCRIPT CHILD_SCRIPT
#                   CHILD_SCRIPT
#                     子スクリプトを実行するためのコマンド文字列
###################################################
RUN_CHILD_SCRIPT () {

    ###  ログファイル名を設定する。 ###
    if [ -z "${LOG_NAME}" ]
    then
        LOG_DIR=${JOB_SHELL_DIR}"/auto_sh/JOBLOG"
        LOG_NAME="${LOG_DIR}/${CMD}-$(date +%Y%m%d%H%M%S).log"
    fi

    if [ -n "${RUN_MANUAL}" ] && [ "${RUN_MANUAL}" = "y" ]
    then
        LOG_HEADER
        eval "$*"
        EXIT_CODE=${?}
        if [ ${EXIT_CODE} -ne 0 ]
        then
            LOG_MSG "[$*] was failed!"
        else
            LOG_MSG "[$*] was success."
        fi
        LOG_FOOTER
    else
        {
        LOG_HEADER
        eval "$*"
        EXIT_CODE=${?}
        if [ ${EXIT_CODE} -ne 0 ]
        then
            LOG_MSG "[$*] was failed!"
        else
            LOG_MSG "[$*] was success."
        fi
        LOG_FOOTER
        } >> "${LOG_NAME}" 2>&1
    fi
    return ${EXIT_CODE}
}

###################################################
# Function      : CONFIRM_USER_INPUT
# Description   : 手動実行時(環境変数 RUN_MANUAL に "y" が設定されているとき)に継続確認メッセージを表示する。
# USAGE         : CONFIRM_USER_INPUT
###################################################
CONFIRM_USER_INPUT () {
    if [ -n "${RUN_MANUAL}" ] && [ "${RUN_MANUAL}" = "y" ]
    then
        cat "${COMMON_DIR}"/conf/user_confirm.message
        read -r USER_INPUT
        if [ "${USER_INPUT}" != "y" ]
        then
            LOG_MSG "Execution if ${CMD} was interrupted"
            exit 1
        fi
    fi
}

