#!/bin/sh

Describe "javaTemplate.sh"
    before_all() {
        global_make_script /home/app/app/shell-common/conf/batch_dir.config << EOF
RUN_LIB_PATH=/home/app/app/run/app-batch.jar
RUN_LIB_OUT=/home/app/app/runningjar
EOF
        global_make_script /home/app/app/shell-common/conf/java_env.config << EOF
SING_OPT="-Dsample=singValue1"
EOF
    }

    BeforeAll before_all

    TEST_SCRIPT_DIR=/home/app/shellspec/spec/template/javaTemplate
    TEST_NO_ARGS=$TEST_SCRIPT_DIR/TEST_NO_ARGS
    TEST_SINGLE_ARGS=$TEST_SCRIPT_DIR/TEST_SINGLE_ARGS
    TEST_MULTIPLE_ARGS=$TEST_SCRIPT_DIR/TEST_MULTIPLE_ARGS
    export RUN_MANUAL=y

    It "環境変数RUN_MANUALにyを設定した場合、手動実行の継続確認が行われること"
        Data "y"
        When run script $TEST_NO_ARGS
        The output should include "If you want to continue, Please return y[y|n]"
    End

    It "任意項目を全て空で出力したスクリプトで正常にJavaバッチが起動できることを確認"
        Data "y"
        When run script $TEST_NO_ARGS
        The output should include "JVM引数=[-Dsample=singValue1]"
        The output should include "コマンドライン引数=[--spring.batch.job.name=TEST_NO_ARGS]"
        The status should equal 0
    End

    It "任意項目を全て1つずつ埋めて出力したスクリプトで正常にJavaバッチが起動できてパラメータが渡せていることを確認"
        Data "y"
        When run script $TEST_SINGLE_ARGS
        The output should include "JVM引数=[-Dsample=singValue1, -Xms256m, -Dsystem-prop1=sysValue1]"
        The output should include "コマンドライン引数=[--spring.batch.job.name=TEST_SINGLE_ARGS, --app.prop1=appValue1, --job.param1=jobValue1]"
        The status should equal 0
    End

    It "任意項目を全て2つ以上ずつ埋めて出力したスクリプトで正常にJavaバッチが起動できてパラメータが渡せていることを確認"
        Data "y"
        When run script $TEST_MULTIPLE_ARGS
        The output should include "JVM引数=[-Dsample=singValue1, -Xms256m, -Xmx512m, -Dsystem-prop1=sysValue1, -Dsystem-prop2=sysValue2]"
        The output should include "コマンドライン引数=[--spring.batch.job.name=TEST_MULTIPLE_ARGS, --app.prop1=appValue1, --app.prop2=appValue2, --job.param1=jobValue1, --job.param2=jobValue2]"
        The status should equal 0
    End

    It "スクリプトに渡した引数が、そのまま子スクリプトに引数が渡せていること"
        Data "y"
        When run script $TEST_NO_ARGS foo bar fizz buzz
        The output should include "コマンドライン引数=[--spring.batch.job.name=TEST_NO_ARGS, foo, bar, fizz, buzz]"
        The status should equal 0
    End

    It "子スクリプトの終了コードがそのまま返されていること"
        Data "y"
        When run script $TEST_NO_ARGS exitCode=123
        The output should include "[ func_single_batch.sh ] EXIT_CODE = [123]"
        The status should equal 123
    End
End