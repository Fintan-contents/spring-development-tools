#!/bin/sh

Describe "func_single_batch.sh"
    export COMMON_DIR="/home/app/app/shell-common"
    export COMMON_CONF_DIR="${COMMON_DIR}/conf"

    CMD=${0##*/}
    SUT=${COMMON_DIR}/func/func_single_batch.sh

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
        Include /home/app/app/shell-common/conf/batch_dir.config
    }

    BeforeEach before_each

    It "開始ログの確認(引数が1つの場合)"
        When run source ${SUT} test
        The output should start with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [ test]"
    End

    It "開始ログの確認(引数が2つ以上の場合)"
        When run source ${SUT} test foo bar
        The output should start with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [ test foo bar]"
    End

    It "開始ログの確認(INP_JAVA_OPTが定義されている場合)"
        export INP_JAVA_OPT="-Dkey1=value1 -Dkey2=value2"
        When run source ${SUT} foo bar
        The output should start with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] PARAMETER = [-Dkey1=value1 -Dkey2=value2 foo bar]"
    End

    It "SING_OPTとINP_JAVA_OPTを定義しない場合、javaコマンドに渡されるオプションは空となること"
        echo "" > /home/app/app/shell-common/conf/java_env.config
        When run source ${SUT} test_job_id
        The output should include "JVM引数=[]"
    End

    It "SING_OPTだけ定義してINP_JAVA_OPTは定義しない場合、javaコマンドに渡されるオプションはSING_OPTだけとなること"
        global_make_script /home/app/app/shell-common/conf/java_env.config << EOF
SING_OPT=-Dfoo=bar
EOF
        When run source ${SUT} test_job_id
        The output should include "JVM引数=[-Dfoo=bar]"
    End

    It "SING_OPTは定義せずINP_JAVA_OPTだけ定義した場合、javaコマンドに渡されるオプションはINP_JAVA_OPTだけとなること"
        echo "" > /home/app/app/shell-common/conf/java_env.config
        export INP_JAVA_OPT=-Dfizz=buzz

        When run source ${SUT} test_job_id
        The output should include "JVM引数=[-Dfizz=buzz]"
    End

    It "SING_OPTとINP_JAVA_OPTの両方を定義し場合、javaコマンドのオプションには両方の値が渡されること"
        global_make_script /home/app/app/shell-common/conf/java_env.config << EOF
SING_OPT=-Dfoo=bar
EOF
        export INP_JAVA_OPT=-Dfizz=buzz

        When run source ${SUT} test_job_id
        The output should include "JVM引数=[-Dfoo=bar, -Dfizz=buzz]"
    End

    It "JAVA_HOME_PATHで指定されたJavaが使用されていることとコピーしたjarで起動されていることの確認"
        global_make_script /home/app/app/shell-common/conf/java_env.config << EOF
JAVA_HOME_PATH=/home/app/jdk-11.0.16.1+1
EOF
        When run source ${SUT} test_job_id
        The output should include "/home/app/jdk-11.0.16.1+1/bin/java -jar ${RUN_LIB_OUT}/test_job_id_$$/app-batch.jar"
    End

    It "2つ目以降の引数がjavaコマンドの引数に渡されることの確認"
        When run source ${SUT} job_id hello world foo bar
        The output should include "コマンドライン引数=[hello, world, foo, bar]"
    End

    It "正常終了後の確認"
        When run source ${SUT} job_id exitCode=3
        The output should end with "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [3]"
        The status should equal 3
        The file "${RUN_LIB_OUT}"/test_job_id_$$ should not be exist
    End

End