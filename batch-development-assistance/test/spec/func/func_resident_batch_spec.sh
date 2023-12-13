#!/bin/sh

Describe "func_resident_batch.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_resident_batch.sh

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
RUN_LIB_PATH=/home/app/app/run/app-batch.jar
RUN_LIB_OUT=/home/app/app/runningjar
EOF
        echo "" > /home/app/app/shell-common/conf/java_env.config

        Include /home/app/app/shell-common/conf/batch_dir.config
        rm -rf "${RUN_LIB_OUT}"
        mkdir "${RUN_LIB_OUT}"
    }

    BeforeEach before_each

    It "開始ログの確認(引数が1つの場合)"
        When run source ${SUT} aaa
        The output should start with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [ aaa]"
    End

    It "開始ログの確認(引数が2つ以上の場合)"
        When run source ${SUT} bbb foo bar
        The output should start with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [ bbb foo bar]"
    End

    It "開始ログの確認(INP_JAVA_OPTが定義されている場合)"
        export INP_JAVA_OPT="-Dkey1=value1 -Dkey2=value2"
        When run source ${SUT} ccc foo bar
        The output should start with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [-Dkey1=value1 -Dkey2=value2 ccc foo bar]"
    End

    It "起動済みのジョブIDで実行した場合"
        # 常駐起動
        "${SUT}" ddd --resident-batch.enabled=true
        
        When run source ${SUT} ddd
        The status should equal 1
        The output should end with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] specified JOB_ID is already used by another process."

        # 常駐起動しているjavaプロセスを強制終了
        pkill java
    End

    It "事前にRUN_LIB_OUT配下に配置したファイルは削除されること"
        mkdir "${RUN_LIB_OUT}"/eee
        touch "${RUN_LIB_OUT}"/eee/test

        When run source ${SUT} eee
        The file "${RUN_LIB_OUT}"/eee/test should not be exist
        # 標準出力を無視すると警告が出るので、アサートしている
        The output should include "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]"
    End

    It "JAVA_HOME_PATHで指定されたJavaが使用されていることとコピーしたjarで起動されていることの確認"
        global_make_script /home/app/app/shell-common/conf/java_env.config << EOF
JAVA_HOME_PATH=/home/app/jdk-17-openjdk
EOF
        When run source ${SUT} fff file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The file "${WORK_DIR}"/result should satisfy global_include_text "/home/app/jdk-17-openjdk/bin/java -jar ${RUN_LIB_OUT}/fff/app-batch.jar"

        # 標準出力を無視すると警告が出るので、アサートしている
        The output should include "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]"
    End

    It "RESI_OPTとINP_JAVA_OPTを定義しない場合、javaコマンドに渡されるオプションは空となること"
        When run source ${SUT} ggg file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The file "${WORK_DIR}"/result should satisfy global_include_text "JVM引数=\[]"

        # 標準出力を無視すると警告が出るので、アサートしている
        The output should include "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]"
    End

    It "RESI_OPTだけ定義してINP_JAVA_OPTは定義しない場合、javaコマンドに渡されるオプションはRESI_OPTだけとなること"
        global_make_script /home/app/app/shell-common/conf/java_env.config << EOF
RESI_OPT=-Dfoo=bar
EOF
        When run source ${SUT} hhh file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The file "${WORK_DIR}"/result should satisfy global_include_text "JVM引数=\[-Dfoo=bar]"

        # 標準出力を無視すると警告が出るので、アサートしている
        The output should include "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]"
    End

    It "RESI_OPTは定義せずINP_JAVA_OPTだけ定義した場合、javaコマンドに渡されるオプションはINP_JAVA_OPTだけとなること"
        export INP_JAVA_OPT=-Dfizz=buzz

        When run source ${SUT} iii file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The file "${WORK_DIR}"/result should satisfy global_include_text "JVM引数=\[-Dfizz=buzz]"

        # 標準出力を無視すると警告が出るので、アサートしている
        The output should include "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]"
    End

    It "RESI_OPTとINP_JAVA_OPTの両方を定義し場合、javaコマンドのオプションには両方の値が渡されること"
        global_make_script /home/app/app/shell-common/conf/java_env.config << EOF
RESI_OPT=-Dfoo=bar
EOF
        export INP_JAVA_OPT=-Dfizz=buzz

        When run source ${SUT} jjj file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The file "${WORK_DIR}"/result should satisfy global_include_text "JVM引数=\[-Dfoo=bar, -Dfizz=buzz]"

        # 標準出力を無視すると警告が出るので、アサートしている
        The output should include "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]"
    End

    It "2つ目以降の引数がjavaコマンドの引数に渡されることの確認"
        When run source ${SUT} kkk hello world foo bar file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The file "${WORK_DIR}"/result should satisfy global_include_text "コマンドライン引数=\[hello, world, foo, bar, file=${WORK_DIR}/result]"

        # 標準出力を無視すると警告が出るので、アサートしている
        The output should include "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]"
    End

    It "正常終了後の確認"
        When run source ${SUT} lll --resident-batch.enabled=true
        The output should end with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [0]"
        The status should equal 0

        pgrep_java_process() {
            # pgrep で java コマンドが実行中であることを確認
            if [ "$(pgrep -f "java -jar ${RUN_LIB_OUT}/lll/app-batch.jar")" ]; then
                echo "success"
            fi
        }

        The result of "pgrep_java_process()" should equal "success"

        # 常駐起動しているjavaプロセスを強制終了
        pkill java
    End
End