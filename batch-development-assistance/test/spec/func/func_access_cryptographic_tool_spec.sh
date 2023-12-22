#!/bin/sh

Describe "func_access_cryptographic_tool.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_access_cryptographic_tool.sh
    INPUT_DIR_NAME=inputDir
    TARGET_FILE_NAME=targetFile
    OUTPUT_DIR_NAME=outputDir
    KEY_FILE_NAME=ssl.key
    
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
CRYPT_KEY_DIR=/home/app/key/crypt
EOF
        Include /home/app/app/shell-common/conf/batch_dir.config
        mkdir -p "${FILE_TRANCEFER_BASE_DIR}"
        mkdir "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}
        mkdir "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_NAME}
    }

    BeforeEach before_each

    It "開始ログに引数が全て出力されること"
        echo "Hello World!" > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${TARGET_FILE_NAME}

        When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0

        The output should start with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0]
EOF
)"
        # 標準エラー出力を無視すると警告がでるのでアサーションを入れている
        The stderr should equal "*** WARNING : deprecated key derivation used.
Using -iter or -pbkdf2 would be better."
    End

    It "FILE_TRANCEFER_BASE_DIRに存在しないディレクトリを指定している場合エラー終了となること"
        rm -rf "${FILE_TRANCEFER_BASE_DIR}"

        When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0

        The status should equal 121
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X11]　ベースディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [121]
EOF
)"
    End

    It "引数を6つ以外の数指定した場合エラー終了となること"
        When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0 over

        The status should equal 110
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X01]　引数の数に過不足があります。引数は6つ指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [110]
EOF
)"
    End

    It "処理区分に0,1以外の値を指定した場合エラー終了となること"
        When run source ${SUT} 2 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0

        The status should equal 111
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X02]　処理区分が不正です。0または1を指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [111]
EOF
)"
    End

    It "暗号化/復号対象ファイル名に存在しないファイル名を指定した場合エラー終了となること"
        When run source ${SUT} 0 no-exist ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0

        The status should equal 114
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X06]　対象ファイルが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_NAME}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [114]
EOF
)"
    End

    It "入力元ディレクトリパスに存在しないディレクトリパスを指定した場合エラー終了となること"
        When run source ${SUT} 0 ${TARGET_FILE_NAME} no-exist ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0

        The status should equal 112
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X04]　入力元ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [112]
EOF
)"
    End

    It "出力先ディレクトリパスに存在しないディレクトリパスを指定した場合エラー終了となること"
        When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} no-exist ${KEY_FILE_NAME} 0

        The status should equal 113
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X05]　出力先ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [113]
EOF
)"
    End

    It "対象ファイル0バイト精査区分に0,1以外の値を指定した場合エラー終了となること"
        When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 2

        The status should equal 118
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X03]　0バイト精査区分が不正です。0または1を指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [118]
EOF
)"
    End

    Describe "暗号化/復号対象ファイルが0バイトの場合"
        create_empty_file() {
            touch "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${TARGET_FILE_NAME}
        }

        BeforeEach create_empty_file

        It "対象ファイル0バイト精査区分に1を指定した場合エラー終了となること"
            When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 1

            The status should equal 120
            The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X08]　指定されたファイルは0バイトです。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_NAME}/${TARGET_FILE_NAME}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [120]
EOF
)"
        End

        It "対象ファイル0バイト精査区分に0を指定した場合、空ファイルが出力されること"
            When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0

            The status should equal 0
            The file "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_NAME}/${TARGET_FILE_NAME} should be empty file

            # 標準出力をアサートしないと警告が出るのでアサートしている
            The output should include "EXIT_CODE = [0]"
        End

        It "対象ファイル0バイト精査区分に0を指定して暗号化/復号対象ファイルのコピーに失敗した場合"
            chmod -w "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_NAME} # 書き込み権限を消してコピーを失敗させる

            When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0
            The status should equal 119
            The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X07]　0バイトファイルのコピーに失敗しました。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] from ${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_NAME}/${TARGET_FILE_NAME} to ${FILE_TRANCEFER_BASE_DIR}/${OUTPUT_DIR_NAME}/${TARGET_FILE_NAME}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [119]
EOF
)"
            # 標準エラー出力を無視すると警告がでるのでアサーションを入れている
            The stderr should equal "cp: cannot create regular file '${WORK_DIR}/trancefer/${OUTPUT_DIR_NAME}/${TARGET_FILE_NAME}': Permission denied"
        End
    End

    It "キーファイル名に存在しないファイルを指定した場合エラー終了となること"
        echo "Hello World!" > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${TARGET_FILE_NAME}

        When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} no-exist 0

        The status should equal 115
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X09]　キーファイルが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${CRYPT_KEY_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [115]
EOF
)"
    End

    It "誤ったキーファイルを指定した場合エラー終了となること"
        echo "Hello World!" > "${WORK_DIR}"/original.txt
        openssl enc -e -aes256 -in "${WORK_DIR}"/original.txt \
            -out "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${TARGET_FILE_NAME} \
            -kfile "${CRYPT_KEY_DIR}"/${KEY_FILE_NAME} 2> /dev/null
        
        echo "invalid" > "${CRYPT_KEY_DIR}"/invalid.key

        When run source ${SUT} 1 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} invalid.key 0

        The status should equal 116
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999X10]　ファイルの暗号化/復号に失敗しました。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [116]
EOF
)"

        # 標準エラー出力を無視すると警告がでるのでアサーションを入れている
        The stderr should include "*** WARNING : deprecated key derivation used."
    End

    It "暗号化に成功した場合"
        echo "Hello World!" > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${TARGET_FILE_NAME}

        When run source ${SUT} 0 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0
        The status should equal 0
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] OPENSSL_EXIT_CODE = [0]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] INPUT_FILE = [${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_NAME}/${TARGET_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] OUTPUT_FILE = [${FILE_TRANCEFER_BASE_DIR}/${OUTPUT_DIR_NAME}/${TARGET_FILE_NAME}]
EOF
)"
        # 標準エラー出力を無視すると警告がでるのでアサーションを入れている
        The stderr should equal "*** WARNING : deprecated key derivation used.
Using -iter or -pbkdf2 would be better."

        # 暗号化後のファイルを復号して元のファイルと一致することを検証することで、暗号化が意図通りにできていることを確認する
        The file "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_NAME}/${TARGET_FILE_NAME} should satisfy global_check_encrypted_file "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${TARGET_FILE_NAME} /home/app/key/crypt/${KEY_FILE_NAME}
    End

    It "復号に成功した場合"
        # 復号対象の暗号化済みファイルを生成
        echo "Hello World!" > "${WORK_DIR}"/original.txt
        openssl enc -e -aes256 -in "${WORK_DIR}"/original.txt \
            -out "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${TARGET_FILE_NAME} \
            -kfile "${CRYPT_KEY_DIR}"/${KEY_FILE_NAME} 2> /dev/null

        When run source ${SUT} 1 ${TARGET_FILE_NAME} ${INPUT_DIR_NAME} ${OUTPUT_DIR_NAME} ${KEY_FILE_NAME} 0
        # 復号できていることを確認
        The contents of file "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_NAME}/${TARGET_FILE_NAME} should equal "Hello World!"

        # 標準エラー出力・標準出力を無視すると警告がでるのでアサーションを入れている
        The stderr should include "*** WARNING : deprecated key derivation used."
        The output should include "EXIT_CODE = [0]"
    End
End