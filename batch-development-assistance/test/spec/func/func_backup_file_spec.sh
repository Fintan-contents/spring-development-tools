#!/bin/sh

Describe "func_backup_file.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_backup_file.sh

    INPUT_DIR_PATH=inputDir
    INPUT_FILE_NAME=inputFile
    BACKUP_DIR_PATH=backupDir
    
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
        mkdir "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_PATH}
        mkdir "${FILE_TRANCEFER_BASE_DIR}"/${BACKUP_DIR_PATH}
    }

    BeforeEach before_each

    It "開始ログに引数が全て出力されること"
        echo "Hello World!!" > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_PATH}/${INPUT_FILE_NAME}

        When run source ${SUT} ${INPUT_DIR_PATH} ${INPUT_FILE_NAME} ${BACKUP_DIR_PATH}
        The output should start with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [${INPUT_DIR_PATH} ${INPUT_FILE_NAME} ${BACKUP_DIR_PATH}]
EOF
)"
    End

    It "FILE_TRANCEFER_BASE_DIRに存在しないディレクトリを指定している場合エラー終了となること"
        rm -rf "${FILE_TRANCEFER_BASE_DIR}"

        When run source ${SUT} ${INPUT_DIR_PATH} ${INPUT_FILE_NAME} ${BACKUP_DIR_PATH}

        The status should equal 115
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999807]　ベースディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [115]
EOF
)"
    End

    It "引数を3つ以外の数指定した場合エラー終了となること"
        When run source ${SUT} ${INPUT_DIR_PATH} ${INPUT_FILE_NAME} ${BACKUP_DIR_PATH} over

        The status should equal 110
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999801]　引数の数に過不足があります。引数は3つ指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [110]
EOF
)"
    End

    It "バックアップ元ディレクトリパスに存在しないディレクトリパスを指定した場合エラー終了となること"
        When run source ${SUT} no-exist ${INPUT_FILE_NAME} ${BACKUP_DIR_PATH}

        The status should equal 111
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999802]　移動元ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [111]
EOF
)"
    End

    It "ファイル名に存在しないファイルの名前を指定した場合エラー終了となること"
        When run source ${SUT} ${INPUT_DIR_PATH} no-exist ${BACKUP_DIR_PATH}

        The status should equal 113
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999805]　指定された移動元ディレクトリ配下にファイルが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_PATH}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [113]
EOF
)"
    End

    It "バックアップ先ディレクトリパスに存在しないディレクトリパスを指定した場合エラー終了となること"
        When run source ${SUT} ${INPUT_DIR_PATH} ${INPUT_FILE_NAME} no-exist

        The status should equal 112
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999803]　移動先ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [112]
EOF
)"
    End
    
    It "バックアップに成功した場合"
        echo "Hello World!!" > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_PATH}/${INPUT_FILE_NAME}

        When run source ${SUT} ${INPUT_DIR_PATH} ${INPUT_FILE_NAME} ${BACKUP_DIR_PATH}
        The status should equal 0
        The contents of file "${FILE_TRANCEFER_BASE_DIR}"/${BACKUP_DIR_PATH}/${INPUT_FILE_NAME}_20221223123456 should equal "Hello World!!"
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] INPUT_FILE = [${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_PATH}/${INPUT_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] BACKUP_FILE = [${FILE_TRANCEFER_BASE_DIR}/${BACKUP_DIR_PATH}/${INPUT_FILE_NAME}_20221223123456]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
EOF
)"
    End

    It "バックアップに失敗した場合"
        echo "Hello World!!" > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_PATH}/${INPUT_FILE_NAME}
        # 読み取り権限を外してコピーを失敗させる
        chmod a-r "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_PATH}/${INPUT_FILE_NAME}

        When run source ${SUT} ${INPUT_DIR_PATH} ${INPUT_FILE_NAME} ${BACKUP_DIR_PATH}
        The status should equal 114
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999806]　ファイルのバックアップに失敗しました。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [114]
EOF
)"
        # 標準エラー出力を無視すると警告がでるのでアサートしている
        The stderr should equal "cp: cannot open '${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_PATH}/${INPUT_FILE_NAME}' for reading: Permission denied"
    End
End