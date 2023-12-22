#!/bin/sh

Describe "shellTemplate.sh"
    before_each() {
        global_make_script /home/app/app/shell-common/conf/batch_dir.config << EOF
FILE_TRANCEFER_BASE_DIR="${WORK_DIR}"/trancefer
EOF
        Include /home/app/app/shell-common/conf/batch_dir.config

        mkdir -p "${FILE_TRANCEFER_BASE_DIR}"/targetDir
        echo "Hello shellTemplate!" > "${FILE_TRANCEFER_BASE_DIR}"/targetDir/delete.txt
    }

    BeforeEach before_each

    TEST_SCRIPT_DIR=/home/app/shellspec/spec/template/shellTemplate
    TEST_SHELL_TEMPLATE=$TEST_SCRIPT_DIR/TEST_SHELL_TEMPLATE
    export RUN_MANUAL=y

    It "引数を1つだけ指定した場合、エラー終了となること"
        When run script $TEST_SHELL_TEMPLATE foo
        The status should equal 1
        The output should include "Usage :$TEST_SHELL_TEMPLATE"
    End

    It "環境変数RUN_MANUALにyを設定した場合、手動実行の継続確認が行われること"
        Data "y"
        When run script $TEST_SHELL_TEMPLATE
        The output should include "If you want to continue, Please return y[y|n]"
    End

    It "子スクリプトが正常に実行できていること"
        Data "y"
        When run script $TEST_SHELL_TEMPLATE
        The status should equal 0
        The output should include "EXIT_CODE = [0]"

        # 削除スクリプトが正常に動作してファイルが削除できていることを確認
        The file "${FILE_TRANCEFER_BASE_DIR}"/targetDir/delete.txt should not be exist
    End

End