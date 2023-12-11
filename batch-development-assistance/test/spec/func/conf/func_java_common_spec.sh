#!/bin/sh

Describe "func_java_common.sh"
    Include /home/app/app/shell-common/conf/common.sh
    Include /home/app/app/shell-common/func/conf/func_java_common.sh
    CMD=${0##*/}

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

    Describe "DIE"
        It "処理が中断され、直前に実行した処理の終了コードがログに出力されて返却されることの確認"
            # 直前に実行する関数
            dummy_function() {
                return 123
            }

            global_make_script "${WORK_DIR}"/test.sh << EOF
#!/bin/sh
. /home/app/app/shell-common/conf/common.sh
. /home/app/app/shell-common/func/conf/func_java_common.sh
echo "ここは実行される"
dummy_function
DIE
echo "ここは実行されない"
EOF

            When run source "${WORK_DIR}"/test.sh
            The status should equal 123
            The output should equal "$(cat << EOF
ここは実行される
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [123]
EOF
)"
        End
    End

    Describe "COPY_RUN_JARS"
        It "既に存在するディレクトリを指定するとエラーになること"
            mkdir "${WORK_DIR}"/run_lib_out_dir

            # When call だとエラー時の exit 1 でテスト自体が中断されてしまい、
            # When run source は、シェルスクリプトしか実行できないので、
            # COPY_RUN_JARS を実行するシェルスクリプトをテスト用に生成して、
            # それを run source で実行することでテストしている
            global_make_script "${WORK_DIR}"/test.sh << EOF
#!/bin/sh
. /home/app/app/shell-common/conf/common.sh
. /home/app/app/shell-common/func/conf/func_java_common.sh
COPY_RUN_JARS ${WORK_DIR}/run_lib_out_dir
EOF

            When run source "${WORK_DIR}"/test.sh
            The status should equal 1
            The output should equal "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [1]"

            #標準エラー出力を無視すると警告が出るので、アサートしている
            The stderr should equal "mkdir: cannot create directory ‘${WORK_DIR}/run_lib_out_dir’: File exists"
        End

        It "RUN_LIB_PATHにコピー対象のjarを1つだけ指定した場合"
            mkdir "${WORK_DIR}"/from
            echo aaa > "${WORK_DIR}"/from/aaa.jar
            export RUN_LIB_PATH="${WORK_DIR}"/from/aaa.jar

            When call COPY_RUN_JARS "${WORK_DIR}"/run_lib_out_dir

            The file "${WORK_DIR}"/run_lib_out_dir/aaa.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/aaa.jar
        End

        It "RUN_LIB_PATHにコピー対象のjarを2つ以上指定した場合"
            mkdir "${WORK_DIR}"/from
            echo aaa > "${WORK_DIR}"/from/aaa.jar
            echo bbb > "${WORK_DIR}"/from/bbb.jar
            echo ccc > "${WORK_DIR}"/from/ccc.jar

            export RUN_LIB_PATH="${WORK_DIR}"/from/aaa.jar:"${WORK_DIR}"/from/bbb.jar:"${WORK_DIR}"/from/ccc.jar

            When call COPY_RUN_JARS "${WORK_DIR}"/run_lib_out_dir

            The file "${WORK_DIR}"/run_lib_out_dir/aaa.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/aaa.jar
            The file "${WORK_DIR}"/run_lib_out_dir/bbb.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/bbb.jar
            The file "${WORK_DIR}"/run_lib_out_dir/ccc.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/ccc.jar
        End

        It "RUN_LIB_PATHにコピー対象のjarを含むディレクトリの中をワイルドカードで指定した場合"
            mkdir "${WORK_DIR}"/from
            echo aaa > "${WORK_DIR}"/from/aaa.jar
            echo bbb > "${WORK_DIR}"/from/bbb.jar
            echo ccc > "${WORK_DIR}"/from/ccc.jar

            export RUN_LIB_PATH="${WORK_DIR}/from/*"

            When call COPY_RUN_JARS "${WORK_DIR}"/run_lib_out_dir

            The file "${WORK_DIR}"/run_lib_out_dir/aaa.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/aaa.jar
            The file "${WORK_DIR}"/run_lib_out_dir/bbb.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/bbb.jar
            The file "${WORK_DIR}"/run_lib_out_dir/ccc.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/ccc.jar
        End

        It "RUN_LIB_PATHにコピー対象のjarと、jarを含むディレクトリの中をワイルドカードで指定した場合"
            mkdir "${WORK_DIR}"/from
            echo aaa > "${WORK_DIR}"/from/aaa.jar
            echo bbb > "${WORK_DIR}"/from/bbb.jar
            echo ccc > "${WORK_DIR}"/from/ccc.jar

            mkdir "${WORK_DIR}"/from2
            echo ddd > "${WORK_DIR}"/from2/ddd.jar

            export RUN_LIB_PATH="${WORK_DIR}/from/*:${WORK_DIR}/from2/ddd.jar"

            When call COPY_RUN_JARS "${WORK_DIR}"/run_lib_out_dir

            The file "${WORK_DIR}"/run_lib_out_dir/aaa.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/aaa.jar
            The file "${WORK_DIR}"/run_lib_out_dir/bbb.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/bbb.jar
            The file "${WORK_DIR}"/run_lib_out_dir/ccc.jar should satisfy global_check_file_diff "${WORK_DIR}"/from/ccc.jar
            The file "${WORK_DIR}"/run_lib_out_dir/ddd.jar should satisfy global_check_file_diff "${WORK_DIR}"/from2/ddd.jar
        End
    End

    Describe "DELETE_DIR"
        It "存在する空ではないディレクトリを指定すると、ディレクトリが削除されること"
            mkdir -p "${WORK_DIR}"/target/subdir
            touch "${WORK_DIR}"/target/foo "${WORK_DIR}"/target/subdir/bar

            When call DELETE_DIR "${WORK_DIR}"/target
            The directory "${WORK_DIR}"/target should not be exist
        End

        It "存在しないディレクトリを指定した場合、何も処理をしないこと"
            When call DELETE_DIR "${WORK_DIR}"/no-exist
            The status should equal 0
        End

        It "削除に失敗した場合、処理が中断されること"
            mkdir -p "${WORK_DIR}"/foo/target
            # 削除対象ディレクトリの削除権限を無くすことでエラーにさせる
            chmod -w "${WORK_DIR}"/foo
        
            global_make_script "${WORK_DIR}"/test.sh << EOF
#!/bin/sh
. /home/app/app/shell-common/conf/common.sh
. /home/app/app/shell-common/func/conf/func_java_common.sh
echo "ここは実行される"
DELETE_DIR "${WORK_DIR}"/foo/target
echo "ここは実行されない"
EOF
            When run source "${WORK_DIR}"/test.sh
            The output should equal "$(cat << EOF
ここは実行される
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] EXIT_CODE = [1]
EOF
)"

            # 終了コードと標準エラー出力をアサートしないと警告がでるので、アサートしている
            The status should equal 1
            The stderr should include "rm: cannot remove '${WORK_DIR}/foo/target': Permission denied"

            # 書き込み権限を戻す
            chmod +w "${WORK_DIR}"/foo
        End
    End

    Describe "DUPLICATE_PROCESS_CHECK"
        It "他で起動されていないコマンド文字列を引数に渡した場合は何も起こらないこと"
            When call DUPLICATE_PROCESS_CHECK "hogefugapiyo"
            The status should equal 0
        End

        It "他で起動済みのコマンド文字列を引数に渡した場合、処理が中断されること"
            # 常駐バッチをバックグラウンドで動かしておく
            java -jar /home/app/app/run/app-batch.jar --resident-batch.enabled=true &
            java_pid=$!

            global_make_script "${WORK_DIR}"/test.sh << EOF
#!/bin/sh
. /home/app/app/shell-common/conf/common.sh
. /home/app/app/shell-common/func/conf/func_java_common.sh

echo "ここは実行される"
DUPLICATE_PROCESS_CHECK "app-batch.jar"
echo "ここは実行されない"
EOF

            When run source "${WORK_DIR}"/test.sh
            The status should equal 1
            The output should equal "$(cat << EOF
ここは実行される
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] specified JOB_ID is already used by another process.
EOF
)"

            # 常駐バッチ停止
            kill $java_pid
        End

        It "親プロセスが重複チェックの対象外となっていることの確認"
            global_make_script "${WORK_DIR}"/script1.sh << 'EOF'
#!/bin/sh
${WORK_DIR}/script2.sh $1
EOF
            global_make_script "${WORK_DIR}"/script2.sh << 'EOF'
#!/bin/sh
. /home/app/app/shell-common/conf/common.sh
. /home/app/app/shell-common/func/conf/func_java_common.sh

echo "ここは実行される"
DUPLICATE_PROCESS_CHECK $1
echo "ここも実行される"
EOF

            When run script "${WORK_DIR}"/script1.sh "hogefugapiyo"
            The status should equal 0
            The output should equal "ここは実行される
ここも実行される"
        End
    End
End