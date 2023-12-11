#!/bin/sh

Describe "func_compress_file.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_compress_file.sh

    COMPRESSION_DIR_PATH=compressionDir
    COMPRESSION_TARGET_DIR_NAME=compressionTargetDir
    COMPRESSION_FILE_NAME=compressionFile

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
        mkdir -p "${FILE_TRANCEFER_BASE_DIR}"
        mkdir -p "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}
    }

    BeforeEach before_each

    It "開始ログに引数が全て出力されること"
        echo "FOO" > "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}/foo

        When run source ${SUT} ${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 0
        The output should start with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 0]
EOF
)"
    End

    It "FILE_TRANCEFER_BASE_DIRに存在しないディレクトリを指定している場合エラー終了となること"
        rm -rf "${FILE_TRANCEFER_BASE_DIR}"

        When run source ${SUT} ${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 0

        The status should equal 116
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999W08]　ベースディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [116]
EOF
)"
    End

    It "引数を4つ以外の数指定した場合エラー終了となること"
        When run source ${SUT} ${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 0 over

        The status should equal 110
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999W01]　引数の数に過不足があります。引数は4つ指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [110]
EOF
)"
    End

    It "圧縮共通ディレクトリパスに存在しないディレクトリパスを指定した場合エラー終了となること"
        When run source ${SUT} no-exist ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 0

        The status should equal 111
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999W02]　ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [111]
EOF
)"
    End

    It "圧縮対象ファイル配置ディレクトリ名に存在しないディレクトリ名を指定した場合エラー終了となること"
        When run source ${SUT} ${COMPRESSION_DIR_PATH} no-exist ${COMPRESSION_FILE_NAME} 0 

        The status should equal 111
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999W04]　圧縮対象ファイル配置ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${COMPRESSION_DIR_PATH}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [111]
EOF
)"
    End

    It "対象ファイル0バイト精査区分に0,1以外の値を指定した場合エラー終了となること"
        When run source ${SUT} ${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 2

        The status should equal 114
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999W06]　0バイト精査区分が不正です。0または1を指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [114]
EOF
)"
    End

    It "圧縮対象ファイル配置ディレクトリの下にファイルが存在しない場合"
        When run source ${SUT} ${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 0
        The status should equal 112
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999W03]　圧縮対象ファイルが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [112]
EOF
)"
    End

    Describe "圧縮対象ファイル配置ディレクトリの下に空ファイルが存在する場合"
        make_empty_files() {
            mkdir "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}/subdir
            touch "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}/subdir/empty_file
            echo "hello" > "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}/not_empty_file
        }

        BeforeEach make_empty_files

        It "対象ファイル0バイト精査区分に0(精査無し)を指定した場合"
            When run source ${SUT} ${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 0
            The status should equal 0
            The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] COMPRESSION_TARGET_PATH = [${FILE_TRANCEFER_BASE_DIR}/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] COMPRESSION_FILE_PATH = [${FILE_TRANCEFER_BASE_DIR}/${COMPRESSION_DIR_PATH}/${COMPRESSION_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
EOF
)"
            The file "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_FILE_NAME} should be empty file
        End

        It "対象ファイル0バイト精査区分に1(精査あり)を指定した場合"
            When run source ${SUT} ${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 1
            The status should equal 115
            The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999W07]　指定されたファイルは0バイトです。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}/subdir/empty_file
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [115]
EOF
)"
            The file "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_FILE_NAME} should not be exist
        End
    End

    It "圧縮に成功する場合"
        echo "FOO" > "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}/foo
        mkdir "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}/subdir
        echo "BAR" > "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}/subdir/bar

        When run source ${SUT} ${COMPRESSION_DIR_PATH} ${COMPRESSION_TARGET_DIR_NAME} ${COMPRESSION_FILE_NAME} 0
        The status should equal 0
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] COMPRESSION_TARGET_PATH = [${FILE_TRANCEFER_BASE_DIR}/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] COMPRESSION_FILE_PATH = [${FILE_TRANCEFER_BASE_DIR}/${COMPRESSION_DIR_PATH}/${COMPRESSION_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
EOF
)"

        The file "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_FILE_NAME} should satisfy global_check_tar_diff "${FILE_TRANCEFER_BASE_DIR}"/${COMPRESSION_DIR_PATH}/${COMPRESSION_TARGET_DIR_NAME}
    End
End