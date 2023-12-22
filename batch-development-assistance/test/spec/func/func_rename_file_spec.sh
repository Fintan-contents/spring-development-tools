#!/bin/sh

Describe "func_rename_file.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_rename_file.sh

    INPUT_DIR_NAME=inputDir
    INPUT_FILE_NAME=inputFile
    OUTPUT_DIR_PATH=outputDir
    OUTPUT_FILE_NAME=outputFile

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
        mkdir -p "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}
        mkdir -p "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_PATH}
    }

    BeforeEach before_each

    It "開始ログに引数が全て出力されること"
        echo hello > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${INPUT_FILE_NAME}
        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1

        The output should start with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1]
EOF
)"
    End

    It "FILE_TRANCEFER_BASE_DIRに存在しないディレクトリを指定している場合エラー終了となること"
        rm -rf "${FILE_TRANCEFER_BASE_DIR}"

        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1

        The status should equal 118
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999510]　ベースディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [118]
EOF
)"
    End

    It "引数を6つ以外の数指定した場合エラー終了となること"
        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1 over

        The status should equal 110
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999501]　引数の数に過不足があります。引数は6つ指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [110]
EOF
)"
    End

    It "リネーム・コピー先ファイルの上書き可否に0,1以外の値を指定した場合エラー終了となること"
        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 2 1

        The status should equal 111
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999502]　上書き可否パターンが不正です。0または1を指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [111]
EOF
)"
    End

    It "ファイル処理方法に0,1以外の値を指定した場合エラー終了となること"
        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 2

        The status should equal 112
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999503]　処理パターンが不正です。0または1を指定してください。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [112]
EOF
)"
    End

    It "リネーム・コピー元ディレクトリパスに存在しないディレクトリパスを指定した場合エラー終了となること"
        When run source ${SUT} no-exist ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1

        The status should equal 113
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999504]　移動元ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [113]
EOF
)"
    End

    It "リネーム・コピー先ディレクトリパスに存在しないディレクトリパスを指定した場合エラー終了となること"
        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} no-exist ${OUTPUT_FILE_NAME} 0 1

        The status should equal 114
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999505]　移動先ディレクトリが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [114]
EOF
)"
    End

    It "リネーム・コピー元ファイル名に存在しないファイル名を指定した場合エラー終了となること"
        When run source ${SUT} ${INPUT_DIR_NAME} no-exist ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1

        The status should equal 115
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999507]　指定された移動元ディレクトリ配下にファイルが存在しません。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_NAME}/no-exist
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [115]
EOF
)"
    End

    Describe "リネーム・コピー先ファイル名に指定した名前のファイルが、移動先に既に存在する場合"
        create_files() {
            echo "input file" > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${INPUT_FILE_NAME}
            echo "already exist" > "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME}
        }

        BeforeEach create_files

        It "リネーム・コピー先ファイルの上書き可否に0(上書き否)を指定した場合、エラー終了となること"
            When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1

            The status should equal 116
            The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999508]　指定された移動先ディレクトリ配下にファイルが存在します。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PATH = ${FILE_TRANCEFER_BASE_DIR}/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME}
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [116]
EOF
)"
        End

        It "リネーム・コピー先ファイルの上書き可否に1(上書き可)を指定してファイル処理方法に0(リネーム)を指定した場合、リネームが行われること"
            When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 1 0

            The file "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${INPUT_FILE_NAME} should not be exist
            The contents of file "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME} should equal "input file"

            # 標準出力を無視すると警告が出るのでアサートしている
            The output should include "EXIT_CODE = [0]"
        End

        It "リネーム・コピー先ファイルの上書き可否に1(上書き可)を指定してファイル処理方法に1(コピー)を指定した場合、コピーが行われること"
            When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 1 1

            The contents of file "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${INPUT_FILE_NAME} should equal "input file"
            The contents of file "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME} should equal "input file"

            # 標準出力を無視すると警告が出るのでアサートしている
            The output should include "EXIT_CODE = [0]"
        End
    End


    It "コピー・リネームに失敗した場合"
        echo hello > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${INPUT_FILE_NAME}
        # 出力先ディレクトリの書き込み権限を削除してコピーを失敗させる
        chmod a-w "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_PATH}

        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1

        The status should equal 117
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] CODE = [ES9999509]　ファイルの移動に失敗しました。
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [117]
EOF
)"
        # 標準エラー出力を無視すると警告が出るので、アサートしている
        The stderr should equal "cp: cannot create regular file '${FILE_TRANCEFER_BASE_DIR}/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME}': Permission denied"
    End

    It "リネーム・コピー先ファイルの上書き可否に0(上書き否)を、ファイル処理方法に0(リネーム)を指定して正常にリネームできた場合"
        echo hello > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${INPUT_FILE_NAME}
        
        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 0
        
        The status should equal 0
        
        The file "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${INPUT_FILE_NAME} should not be exist
        The contents of file "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME} should equal "hello"
        
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] INPUT_FILE_PATH = [${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_NAME}/${INPUT_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] MOVE_FILE_PATH = [${FILE_TRANCEFER_BASE_DIR}/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
EOF
)"
    End

    It "リネーム・コピー先ファイルの上書き可否に0(上書き否)を、ファイル処理方法に1(コピー)を指定して正常にコピーできた場合"
        echo hello > "${FILE_TRANCEFER_BASE_DIR}"/${INPUT_DIR_NAME}/${INPUT_FILE_NAME}
        
        When run source ${SUT} ${INPUT_DIR_NAME} ${INPUT_FILE_NAME} ${OUTPUT_DIR_PATH} ${OUTPUT_FILE_NAME} 0 1
        
        The status should equal 0
        
        The contents of file "${FILE_TRANCEFER_BASE_DIR}"/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME} should equal "hello"
        
        The output should end with "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] INPUT_FILE_PATH = [${FILE_TRANCEFER_BASE_DIR}/${INPUT_DIR_NAME}/${INPUT_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] COPY_FILE_PATH = [${FILE_TRANCEFER_BASE_DIR}/${OUTPUT_DIR_PATH}/${OUTPUT_FILE_NAME}]
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]
EOF
)"
    End
End