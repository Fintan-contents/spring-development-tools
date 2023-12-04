#!/bin/sh

Describe "func_get.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_get.sh
    
    TARGET_FILE=targetFile
    FROM_DIR_VAR=FROM_DIR
    TO_DIR=toDir
    USER_NAME_VAR=SFTP_USER
    SERVER_NAME_VAR=SFTP_SERVER
    KEY_FILE_NAME=sftp.key

    export SFTP_USER=sftp-user
    export SFTP_SERVER=sftp-server
    export FROM_DIR=fromDir

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
SFTP_KEY_DIR=/home/app/key/sftp
EOF
        Include /home/app/app/shell-common/conf/batch_dir.config
        mkdir -p "${FILE_TRANCEFER_BASE_DIR}/${TO_DIR}"
        mkdir -p "${COMMON_DIR}"/func/sftp

        global_sftp_clear_dir /"${FROM_DIR}"
    }

    after_each() {
        if [ ! -e /usr/bin/sftp ] && [ -e /usr/bin/sftp.bk ]; then
            # sftpコマンドがリネームされたままの場合は戻す
            sudo mv /usr/bin/sftp.bk /usr/bin/sftp
        fi
    }

    BeforeEach before_each
    AfterEach after_each

    It "開始ログに引数が全て出力されること"
        echo "Hello SFTP!" > "${WORK_DIR}"/${TARGET_FILE}
        echo "Hello SFTP! end" > "${WORK_DIR}"/${TARGET_FILE}.end
        global_sftp_put "${WORK_DIR}"/${TARGET_FILE} /${FROM_DIR}/${TARGET_FILE}
        global_sftp_put "${WORK_DIR}"/${TARGET_FILE}.end /${FROM_DIR}/${TARGET_FILE}.end

        When run source $SUT $TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR $KEY_FILE_NAME

        The output should start with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [$TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR $KEY_FILE_NAME]
EOF
)"
    End

    It "FILE_TRANCEFER_BASE_DIRに存在しないディレクトリを指定している場合エラー終了となること"
        rm -rf "${FILE_TRANCEFER_BASE_DIR}"

        When run source $SUT $TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR $KEY_FILE_NAME

        The status should equal 119
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999Z10]　ベースディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [119]
EOF
)"
    End

    It "引数を6つ以外の数指定した場合エラー終了となること"
        When run source $SUT $TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR $KEY_FILE_NAME over

        The status should equal 110
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999Z01]　引数の数に過不足があります。引数は6つ指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [110]
EOF
)"
    End

    It "sftpコマンドが存在しない場合"
        # sftpコマンドをリネームして存在しない状態にする
        sudo mv /usr/bin/sftp /usr/bin/sftp.bk
        
        When run source $SUT $TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR $KEY_FILE_NAME
        The status should equal 118
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999Z09]　SFTPコマンドが存在しません。インストールして下さい。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [118]
EOF
)"
    End

    It "授受先ディレクトリパスに存在しないディレクトリを指定した場合エラーになること"
        export TO_DIR=no-exist-dir
        When run source $SUT $TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR $KEY_FILE_NAME
        The status should equal 113
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999Z04]　授受先ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${TO_DIR}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [113]
EOF
)"
    End

    It "キーファイル名に存在しないファイル名を指定している場合エラー終了となること"
        When run source $SUT $TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR no-exist

        The status should equal 117
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999Z08]　キーファイルが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${SFTP_KEY_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [117]
EOF
)"
    End

    It "正常終了した場合"
        echo "Hello SFTP!" > "${WORK_DIR}"/${TARGET_FILE}
        echo "Hello SFTP! end" > "${WORK_DIR}"/${TARGET_FILE}.end
        global_sftp_put "${WORK_DIR}"/${TARGET_FILE} /${FROM_DIR}/${TARGET_FILE}
        global_sftp_put "${WORK_DIR}"/${TARGET_FILE}.end /${FROM_DIR}/${TARGET_FILE}.end

        When run source $SUT $TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR $KEY_FILE_NAME
        The status should equal 0
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] TARGET_FILE = [${FROM_DIR}/${TARGET_FILE}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] OUTPUT_FILE = [${FILE_TRANCEFER_BASE_DIR}/${TO_DIR}/${TARGET_FILE}]
EOF
)"
        The file "${FILE_TRANCEFER_BASE_DIR}"/${TO_DIR}/${TARGET_FILE} should satisfy global_check_file_diff "${WORK_DIR}"/${TARGET_FILE}
        The file "${FILE_TRANCEFER_BASE_DIR}"/${TO_DIR}/${TARGET_FILE}.end should satisfy global_check_file_diff "${WORK_DIR}"/${TARGET_FILE}.end
    End

    It "sftp接続に失敗した場合"
        export SFTP_USER=invalid-user

        When run source $SUT $TARGET_FILE $FROM_DIR_VAR $TO_DIR $USER_NAME_VAR $SERVER_NAME_VAR $KEY_FILE_NAME
        The status should equal 116
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999Z07]　ファイルの授受に失敗しました。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [116]
EOF
)"

        # 標準エラー出力を無視すると警告が出るのでアサートしている
        The stderr should include "invalid-user@sftp-server: Permission denied (publickey,password,keyboard-interactive)."
    End
End