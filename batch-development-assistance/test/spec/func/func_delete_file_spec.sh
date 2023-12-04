#!/bin/sh

Describe "func_delete_file.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_delete_file.sh

    DIR_PATH_VAR=targetDir
    DELETE_FILE_NAME=targetFile

    # date コマンドのモック
    date() {
        if [ "$1" = "+%Y/%m/%d %H:%M:%S" ]; then
            echo "2022/12/23 12:34:56"
        elif [ "$1" = "+%Y%m%d%H%M%S" ]; then
            echo "20221223123456"
        else
            # 期待しないフォーマット文字列が渡された場合は、
            # フォーマット文字列をそのまま返してテストを失敗させる
            echo "$1"
        fi
    }

    before_each() {
        global_make_script /home/app/app/shell-common/conf/batch_dir.config << EOF
FILE_TRANCEFER_BASE_DIR="${WORK_DIR}"/trancefer
EOF
        Include /home/app/app/shell-common/conf/batch_dir.config
        mkdir -p "${FILE_TRANCEFER_BASE_DIR}"/${DIR_PATH_VAR}
        touch "${FILE_TRANCEFER_BASE_DIR}"/${DIR_PATH_VAR}/${DELETE_FILE_NAME}
    }

    BeforeEach before_each

    It "開始ログに引数が全て出力されること"
        When run source ${SUT} ${DIR_PATH_VAR} ${DELETE_FILE_NAME}

        The output should start with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [${DIR_PATH_VAR} ${DELETE_FILE_NAME}]
EOF
)"
    End

    It "FILE_TRANCEFER_BASE_DIRに存在しないディレクトリを指定している場合エラー終了となること"
        rm -rf "${FILE_TRANCEFER_BASE_DIR}"

        When run source ${SUT} ${DIR_PATH_VAR} ${DELETE_FILE_NAME}

        The status should equal 114
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999906]　ベースディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [114]
EOF
)"
    End

    It "引数を2つ以外の数指定した場合エラー終了となること"
        When run source ${SUT} ${DIR_PATH_VAR} ${DELETE_FILE_NAME} over

        The status should equal 110
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999901]　引数の数に過不足があります。引数は2つ指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [110]
EOF
)"
    End

    It "ディレクトリパスに存在しないパスを指定した場合エラー終了となること"
        When run source ${SUT} no-exist ${DELETE_FILE_NAME}

        The status should equal 111
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999902]　ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [111]
EOF
)"
    End

    It "削除対象ファイル名に存在しないファイルの名前を指定した場合エラー終了となること"
        When run source ${SUT} ${DIR_PATH_VAR} no-exist

        The status should equal 112
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999904]　指定されたディレクトリ配下にファイルが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${DIR_PATH_VAR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [112]
EOF
)"
    End

    It "削除に失敗した場合"
        # 対象ファイルをディレクトリにしておくことで rm を失敗させる
        rm "${FILE_TRANCEFER_BASE_DIR}"/${DIR_PATH_VAR}/${DELETE_FILE_NAME}
        mkdir "${FILE_TRANCEFER_BASE_DIR}"/${DIR_PATH_VAR}/${DELETE_FILE_NAME}

        When run source ${SUT} ${DIR_PATH_VAR} ${DELETE_FILE_NAME}
        The status should equal 113
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999905]　ファイルの削除に失敗しました。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [113]
EOF
)"
        # 標準エラー出力を無視すると警告が出るので、アサートしている
        The stderr should equal "rm: cannot remove '${WORK_DIR}/trancefer/targetDir/targetFile': Is a directory"
    End

    It "削除に成功した場合"
        When run source ${SUT} ${DIR_PATH_VAR} ${DELETE_FILE_NAME}
        The status should equal 0
        The file "${FILE_TRANCEFER_BASE_DIR}"/${DIR_PATH_VAR}/${DELETE_FILE_NAME} should not be exist
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] DELETE_FILE_PATH = [${FILE_TRANCEFER_BASE_DIR}/${DIR_PATH_VAR}/${DELETE_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
EOF
)"
    End
End
