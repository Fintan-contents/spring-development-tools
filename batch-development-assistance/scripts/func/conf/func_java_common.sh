#!/bin/sh

####################################################################################
#  File name    : func_java_common.sh
#  Description  : Java実行用シェルで共通的に使用する変数・関数を定義する。
#  Date         : 2011/12/1
####################################################################################


###################################################
# 関数定義
###################################################

###################################################
# Function      : DIE
# Description   : 最後に実行したコマンドの終了ステータスをもってシェルスクリプトを終了させる。
# Usage         : DIE
###################################################
DIE () {
    EXIT_CODE=$?
    LOG_MSG "EXIT_CODE = [${EXIT_CODE}]"
    exit ${EXIT_CODE}
}

###################################################
# Function      : COPY_RUN_JARS
# Description   : 変数RUN_LIB_PATHにて指定されたコピー対象JARをRUN_LIB_OUT_DIRにコピーする。
# Usage         : SET_RUNTIME_CLASSPATH RUN_LIB_OUT_DIR
#                    RUN_LIB_OUT_DIR
#                      プロセス毎にコピーしたJARのコピー先ディレクトリ
###################################################
COPY_RUN_JARS () {

    RUN_LIB_OUT_DIR=${1}

    mkdir "${RUN_LIB_OUT_DIR}" || DIE
    for RUN_LIB in $(echo "${RUN_LIB_PATH}" | sed -e "s/:/\n/g"); do
        if echo "${RUN_LIB}" | grep -q -e "\.jar$"
        then
            # 通常は失敗しえないが、ディスク障害などが発生した場合を考慮する。
            cp -fp "${RUN_LIB}" "${RUN_LIB_OUT_DIR}" || DIE
        fi
    done
}

###################################################
# Function      : DELETE_DIR
# Description   : 指定されたディレクトリを削除する。(配下も含めて)
# Usage         : DELETE_DIR 削除対象のディレクトリ名
###################################################
DELETE_DIR () {

    DELETE_DIR=${1}

    if [ -d "${DELETE_DIR}" ]
    then
        rm -rf "${DELETE_DIR}" || DIE
    fi
}


###################################################
# Function      : DUPLICATE_PROCESS_CHECK
# Description   : 指定されたジョブIDが既に実行中であるかチェックする。
#                 実行中の場合は、終了コード「1」で処理を終了する。
# Usage         : DUPLICATE_PROCESS_CHECK ジョブID
###################################################
DUPLICATE_PROCESS_CHECK() {
    JOB_ID=${1}

    # JOB_IDをコマンドに含むプロセスの中で
    for pid in $(pgrep -f "${JOB_ID}")
    do
        # 自身と親プロセスID以外のモノがあれば起動済みと判定
        if [ "${pid}" != "$$" ] && [ "${pid}" != "${PPID}" ]
        then
            # 既にJOBIDが起動済みの場合は、異常終了する。
            LOG_MSG "specified JOB_ID is already used by another process."
            exit 1
        fi
    done
}

