#!/bin/sh

Describe "common.sh"
    Include /home/app/app/shell-common/conf/common.sh
    
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

    It "LOG_MSG"
        When call LOG_MSG "hello world"
        The output should equal "2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] hello world"
    End

    It "LOG_HEADER"
        When call LOG_HEADER
        The output should equal "$(cat << EOF
###################################################
##  2022/12/23 12:34:56  < ${CMD} > START
###################################################
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Started
EOF
)"
    End

    It "LOG_FOOTER"
        When call LOG_FOOTER
        The output should equal "$(cat << EOF
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Finished
###################################################
##  2022/12/23 12:34:56  < ${CMD} > END
###################################################
EOF
)"
    End

    Describe "RUN_CHILD_SCRIPT"
        make_batch_dir_config() {
            global_make_script /home/app/app/shell-common/conf/batch_dir.config << EOF
JOB_SHELL_DIR="/home/app/shell"
EOF
            Include /home/app/app/shell-common/conf/batch_dir.config
        }

        BeforeEach make_batch_dir_config

        subscript=${WORK_DIR}/subscript.sh

        It "指定したシェルスクリプトを実行できていること"
            global_make_script "${subscript}" << 'EOF'
#!/bin/sh
echo subscript args="$@" >> ${WORK_DIR}/subscript_output
EOF

            When call RUN_CHILD_SCRIPT "${subscript}" hello world
            The contents of file "${WORK_DIR}"/subscript_output should equal "subscript args=hello world"
        End

        It "指定したシェルスクリプトの終了コードが返却されていること"
            global_make_script "${subscript}" << EOF
#!/bin/sh
exit 12
EOF

            When call RUN_CHILD_SCRIPT "${subscript}"
            The status should equal 12
        End

        It "デフォルトのログ出力の確認(正常終了)"
            When call RUN_CHILD_SCRIPT echo hello
            The contents of file "${JOB_SHELL_DIR}/auto_sh/JOBLOG/${CMD}-20221223123456.log" should equal "$(cat << EOF
###################################################
##  2022/12/23 12:34:56  < ${CMD} > START
###################################################
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Started
hello
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] [echo hello] was success.
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Finished
###################################################
##  2022/12/23 12:34:56  < ${CMD} > END
###################################################
EOF
)"
        End

        It "デフォルトのログ出力の確認(正常終了, RUN_MANUAL=X)"
            export RUN_MANUAL=X
            When call RUN_CHILD_SCRIPT echo hello
            The file "${JOB_SHELL_DIR}/auto_sh/JOBLOG/${CMD}-20221223123456.log" should be exist
        End

        It "デフォルトのログ出力の確認(異常終了)"
            global_make_script "${subscript}" << EOF
#!/bin/sh
echo subscript error
exit 1
EOF

            When call RUN_CHILD_SCRIPT "${subscript}" foo bar
            The contents of file "${JOB_SHELL_DIR}/auto_sh/JOBLOG/${CMD}-20221223123456.log" should equal "$(cat << EOF
###################################################
##  2022/12/23 12:34:56  < ${CMD} > START
###################################################
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Started
subscript error
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] [${subscript} foo bar] was failed!
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Finished
###################################################
##  2022/12/23 12:34:56  < ${CMD} > END
###################################################
EOF
)"
            The status should equal 1 # 終了コードが 0 以外の場合、アサートをしないと警告が出るので検証している
        End

        It "LOG_NAMEでログの出力先を指定できること"
            export LOG_NAME="${WORK_DIR}"/test.log

            When call RUN_CHILD_SCRIPT echo hello world
            The contents of file "${LOG_NAME}" should include "hello world"
        End

        Describe "RUN_MANUALにyを設定した場合"
            export RUN_MANUAL=y

            It "指定したシェルスクリプトを実行できていること"
                global_make_script "${subscript}" << 'EOF'
#!/bin/sh
echo subscript args="$@" >> ${WORK_DIR}/subscript_output
EOF

                When call RUN_CHILD_SCRIPT "${subscript}" hello world
                The contents of file "${WORK_DIR}"/subscript_output should equal "subscript args=hello world"
                The output should include "was success." # 標準出力を無視すると警告が出るので検証している
            End

            It "指定したシェルスクリプトの終了コードが返却されていること"
                global_make_script "${subscript}" << EOF
#!/bin/sh
exit 12
EOF
                When call RUN_CHILD_SCRIPT "${subscript}"
                The status should equal 12
                The output should include "was failed!" # 標準出力を無視すると警告が出るので検証している
            End

            It "ログが標準出力に出力されること(正常終了)"
                When call RUN_CHILD_SCRIPT echo hello
                The output should equal "$(cat << EOF
###################################################
##  2022/12/23 12:34:56  < ${CMD} > START
###################################################
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Started
hello
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] [echo hello] was success.
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Finished
###################################################
##  2022/12/23 12:34:56  < ${CMD} > END
###################################################
EOF
)"
            End


            It "ログが標準出力に出力されること(異常終了)"
                global_make_script "${subscript}" << EOF
#!/bin/sh
echo subscript error
exit 1
EOF

                When call RUN_CHILD_SCRIPT "${subscript}" foo bar
                The status should equal 1

                # 標準出力を無視すると警告が出るので検証している
                The output should equal "$(cat << EOF
###################################################
##  2022/12/23 12:34:56  < ${CMD} > START
###################################################
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Started
subscript error
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] [${subscript} foo bar] was failed!
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Script was Finished
###################################################
##  2022/12/23 12:34:56  < ${CMD} > END
###################################################
EOF
)"
            End
        End
    End

    Describe "CONFIRM_USER_INPUT"
        subscript=${WORK_DIR}/subscript.sh
        
        It "RUN_MANUALが未定義の場合、処理が続行されること"
            global_make_script "${subscript}" << EOF
#!/bin/sh
echo この行は実行される
CONFIRM_USER_INPUT
echo この行も実行される
EOF

            When run source "${subscript}"
            The output should equal "$(cat << EOF
この行は実行される
この行も実行される
EOF
)"
            The status should equal 0
        End

        It "RUN_MANUALにy以外の値が設定されている場合、処理が続行されること"
            export RUN_MANUAL=n
            global_make_script "${subscript}" << EOF
#!/bin/sh
echo この行は実行される
CONFIRM_USER_INPUT
echo この行も実行される
EOF

            When run source "${subscript}"
            The output should equal "$(cat << EOF
この行は実行される
この行も実行される
EOF
)"
            The status should equal 0
        End

        Describe "RUN_MANUALにyが設定されている場合"
            export RUN_MANUAL=y
            export COMMON_DIR="${WORK_DIR}"

            make_user_confirm() {
                mkdir "${COMMON_DIR}"/conf
                echo "test user confirm" >> "${COMMON_DIR}"/conf/user_confirm.message
            }

            BeforeEach make_user_confirm

            It "user_confirm.messageの内容が出力され、yを入力すると処理が続行すること"
                global_make_script "${subscript}" << EOF
#!/bin/sh
echo この行は実行される
CONFIRM_USER_INPUT
echo この行も実行される
EOF

                Data "y"
                When run source "${subscript}"
                The output should equal "$(cat << EOF
この行は実行される
test user confirm
この行も実行される
EOF
)"
                The status should equal 0
            End

            It "y以外を入力すると呼び出し元のシェルが中断され、終了コード1が返されること"
                global_make_script "${subscript}" << EOF
#!/bin/sh
echo この行は実行される
CONFIRM_USER_INPUT
echo この行は実行されない
EOF

                Data "n"
                When run source "${subscript}"
                The output should equal "$(cat << EOF
この行は実行される
test user confirm
2022/12/23 12:34:56 $(hostname) $(whoami) : [ ${CMD} ] Execution if ${CMD} was interrupted
EOF
)"
                The status should equal 1
            End
        End
    End
End