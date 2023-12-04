#!/bin/sh

Describe "func_extract_file.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_extract_file.sh

    EXTRACTION_DIR_PATH=extractionDir
    EXTRACTION_FILE_NAME=extractionFile

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
        mkdir -p "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}
    }

    BeforeEach before_each

    It "開始ログに引数が全て出力されること"
        # 解凍対象のtarファイルを作成する
        mkdir -p "${WORK_DIR}"/input/subdir
        echo FOO > "${WORK_DIR}"/input/foo
        cd "${WORK_DIR}"/input || exit
        find . -name "*" -type f -print0 | tar cvzf "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME} --null -T -
        cd - || exit

        When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 0
        The output should start with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 0]
EOF
)"
    End

    It "FILE_TRANCEFER_BASE_DIRに存在しないディレクトリを指定している場合エラー終了となること"
        rm -rf "${FILE_TRANCEFER_BASE_DIR}"

        When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 0

        The status should equal 116
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999V08]　ベースディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [116]
EOF
)"
    End

    It "引数を3つ以外の数指定した場合エラー終了となること"
        When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 0 over

        The status should equal 110
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999V01]　引数の数に過不足があります。引数は3つ指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [110]
EOF
)"
    End

    It "解凍共通ディレクトリパスに存在しないパスを指定した場合エラー終了となること"
        When run source ${SUT} no-exist ${EXTRACTION_FILE_NAME} 0

        The status should equal 111
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999V02]　ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [111]
EOF
)"
    End

    It "対象ファイル0バイト精査区分に0,1以外の値を指定した場合エラー終了となること"
        When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 2

        The status should equal 114
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999V06]　0バイト精査区分が不正です。0または1を指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [114]
EOF
)"
    End

    Describe "解凍対象ファイルが空の場合"
        create_target_file_as_empty() {
            touch "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}
        }

        BeforeEach create_target_file_as_empty

        It "対象ファイル0バイト精査区分に0を指定した場合、正常終了すること"
            When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 0

            The status should equal 0
            The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
EOF
)"
        End

        It "対象ファイル0バイト精査区分に1を指定した場合、エラー終了すること"
            When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 1

            The status should equal 115
            The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999V07]　指定されたファイルは0バイトです。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [115]
EOF
)"
        End
    End

    It "解凍対象ファイルもorgファイルも存在しない場合、エラー終了となること"
        When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 0

        The status should equal 112
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999V04]　指定されたファイルが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] RENAME_PATH = ${FILE_TRANCEFER_BASE_DIR}/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}.org
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [112]
EOF
)"
    End

    It "解凍に失敗した場合"
        # 不正なフォーマットのファイルを解凍することでエラーにさせる
        echo hello > "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}

        When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 0
        The status should equal 113
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999V05]　ファイルの解凍に失敗しました。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [113]
EOF
)"
        The file "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME} should not be exist
        The file "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}.org should be exist
        The contents of file "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}.org should equal "hello"

        # 標準エラー出力を無視すると警告が出るので、アサートしている
        The stderr should include "gzip: stdin: not in gzip format"
    End

    It "解凍に成功した場合"
        # 解凍対象のtarファイルを作成する
        mkdir -p "${WORK_DIR}"/input/subdir
        echo FOO > "${WORK_DIR}"/input/foo
        echo BAR > "${WORK_DIR}"/input/subdir/bar
        cd "${WORK_DIR}"/input || exit
        find . -name "*" -type f -print0 | tar cvzf "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME} --null -T -
        cd - || exit

        When run source ${SUT} ${EXTRACTION_DIR_PATH} ${EXTRACTION_FILE_NAME} 0
        The status should equal 0
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXTRACTION_FILE_PATH = [${FILE_TRANCEFER_BASE_DIR}/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
EOF
)"
        The file "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME} should not be exist
        The file "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH}/${EXTRACTION_FILE_NAME}.org should not be exist

        # 解凍結果が圧縮前のものと同一であることを確認する
        The directory "${FILE_TRANCEFER_BASE_DIR}"/${EXTRACTION_DIR_PATH} should satisfy global_check_dir_diff "${WORK_DIR}"/input
    End
End