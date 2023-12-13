#!/bin/sh

Describe "integration-test"
    # アサートしやすいように、RUN_MANUAL=yで実行してログを標準出力に出力する
    export RUN_MANUAL=y
    SCRIPTS_DIR=${SHELLSPEC_PROJECT_ROOT}/spec/integration-test/shells

    before_all() {
        # config ファイル配置
        cp "${SCRIPTS_DIR}"/conf/*.config /home/app/app/shell-common/conf
    }

    before_each() {
        # ファイル操作用のワーキングディレクトリをクリア
        rm -rf /home/app/work/trancefer
        mkdir /home/app/work/trancefer
    }

    BeforeAll before_all
    BeforeEach before_each

    It "ファイルバックアップ"
        mkdir -p /home/app/work/trancefer/backup/from
        echo "Hello World!" > /home/app/work/trancefer/backup/from/backupFrom.txt
        mkdir -p /home/app/work/trancefer/backup/to

        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイルバックアップ/T2200001

        The status should equal 0
        The output should include "[ func_backup_file.sh ] EXIT_CODE = [0]"

        BACKUP_FILE=$(find /home/app/work/trancefer/backup/to/backupFrom.txt_*)
        The contents of file "$BACKUP_FILE" should equal "Hello World!"
    End

    It "ファイル削除"
        mkdir -p /home/app/work/trancefer/delete/target
        echo "Hello World!" > /home/app/work/trancefer/delete/target/delete.txt
        
        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル削除/T2300001

        The status should equal 0
        The output should include "[ func_delete_file.sh ] EXIT_CODE = [0]"
        The file /home/app/work/trancefer/delete/target/delete.txt should not be exist
    End

    It "ファイル受信"
        echo "Hello World!" > /home/app/work/trancefer/original
        touch /home/app/work/trancefer/original.end
        global_sftp_put /home/app/work/trancefer/original fromDir/normal_get.txt
        global_sftp_put /home/app/work/trancefer/original.end fromDir/normal_get.txt.end

        mkdir -p /home/app/work/trancefer/sftp/to

        export SFTP_FROM_DIR=fromDir
        export SFTP_USER=sftp-user
        export SFTP_SERVER=sftp-server
        
        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル受信/T2800001

        The status should equal 0
        The output should include "[ func_get.sh ] EXIT_CODE = [0]"
        The contents of file /home/app/work/trancefer/sftp/to/normal_get.txt should equal "Hello World!"
    End

    It "ファイル圧縮"
        mkdir -p /home/app/work/trancefer/compress/target/normal/subdir
        echo "Foo!" > /home/app/work/trancefer/compress/target/normal/foo.txt
        echo "Bar!" > /home/app/work/trancefer/compress/target/normal/subdir/bar.txt

        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル圧縮/T2500001

        The status should equal 0
        The output should include "[ func_compress_file.sh ] EXIT_CODE = [0]"
        The file /home/app/work/trancefer/compress/target/normal.tgz should satisfy global_check_tar_diff \
            /home/app/work/trancefer/compress/target/normal
    End

    It "ファイル暗号化"
        mkdir -p /home/app/work/trancefer/openssl/from
        echo "Hello World!" > /home/app/work/trancefer/openssl/from/normal_encrypt.txt
        mkdir -p /home/app/work/trancefer/openssl/to

        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル暗号化復号/T2600001

        The status should equal 0
        The output should include "[ func_access_cryptographic_tool.sh ] EXIT_CODE = [0]"
        
        The file /home/app/work/trancefer/openssl/to/normal_encrypt.txt should satisfy global_check_encrypted_file \
            /home/app/work/trancefer/openssl/from/normal_encrypt.txt /home/app/key/crypt/ssl.key

        # 標準エラー出力を無視すると警告が出るのでアサートしている
        The stderr should include "*** WARNING : deprecated key derivation used."
    End

    It "ファイル復号"
        mkdir -p /home/app/work/trancefer/openssl/from
        mkdir -p /home/app/work/trancefer/openssl/to

        echo "Hello World!" > /home/app/work/trancefer/original.txt
        openssl enc -e -aes256 -in /home/app/work/trancefer/original.txt \
            -out /home/app/work/trancefer/openssl/from/normal_encrypt.txt \
            -kfile /home/app/key/crypt/ssl.key 2> /dev/null

        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル暗号化復号/T2600002

        The status should equal 0
        The output should include "[ func_access_cryptographic_tool.sh ] EXIT_CODE = [0]"
        
        The contents of file /home/app/work/trancefer/openssl/to/normal_encrypt.txt should equal "Hello World!"

        # 標準エラー出力を無視すると警告が出るのでアサートしている
        The stderr should include "*** WARNING : deprecated key derivation used."
    End

    It "ファイル移動"
        mkdir -p /home/app/work/trancefer/rename/from
        echo "Hello World!" > /home/app/work/trancefer/rename/from/moveFrom.txt
        mkdir -p /home/app/work/trancefer/rename/to

        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル移動・コピー/T2100001

        The status should equal 0
        The output should include "[ func_rename_file.sh ] EXIT_CODE = [0]"
        
        The file /home/app/work/trancefer/rename/from/moveFrom.txt should not be exist
        The contents of file /home/app/work/trancefer/rename/to/moveTo.txt should equal "Hello World!"
    End

    It "ファイルコピー"
        mkdir -p /home/app/work/trancefer/copy/from
        echo "Hello World!" > /home/app/work/trancefer/copy/from/copyFrom.txt
        mkdir -p /home/app/work/trancefer/copy/to

        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル移動・コピー/T2100002

        The status should equal 0
        The output should include "[ func_rename_file.sh ] EXIT_CODE = [0]"
        
        The file /home/app/work/trancefer/copy/from/copyFrom.txt should be exist
        The contents of file /home/app/work/trancefer/copy/to/copyTo.txt should equal "Hello World!"
    End

    It "ファイル解凍"
        mkdir -p /home/app/work/trancefer/extract/target

        mkdir -p /home/app/work/trancefer/input/subdir
        echo "Foo!" > /home/app/work/trancefer/input/foo.txt
        echo "Bar!" > /home/app/work/trancefer/input/subdir/bar.txt
        cd /home/app/work/trancefer/input || exit
        find . -name "*" -type f -print0 | tar cvzf /home/app/work/trancefer/extract/target/extracted --null -T -
        cd - || exit

        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル解凍/T2400001

        The status should equal 0
        The output should include "[ func_extract_file.sh ] EXIT_CODE = [0]"
        
        The directory /home/app/work/trancefer/extract/target should satisfy global_check_dir_diff /home/app/work/trancefer/input
    End

    It "ファイル送信"
        mkdir -p /home/app/work/trancefer/sftp/from
        echo "Hello World!" > /home/app/work/trancefer/sftp/from/normal_put.txt
        
        global_sftp_clear_dir /toDir

        export SFTP_TO_DIR=toDir
        export SFTP_USER=sftp-user
        export SFTP_SERVER=sftp-server
        
        Data "y"
        When run script "${SCRIPTS_DIR}"/ファイル送信/T2700001

        The status should equal 0
        The output should include "[ func_put.sh ] EXIT_CODE = [0]"
        The file /home/app/work/trancefer/sftp/from/normal_put.txt should satisfy global_check_sftp_file_diff /toDir/normal_put.txt
    End

    It "メール送信"
        Data "y"
        When run script "${SCRIPTS_DIR}"/メール送信/N2100006 file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The status should equal 0
        The output should include "[ func_mail_send.sh ] EXIT_CODE = [0]"
        The file "${WORK_DIR}"/result should satisfy global_include_text "JVM引数=\[-Dsample=mailValue1, -Xms256m, -DsysProp=sysPropValue]"
        The file "${WORK_DIR}"/result should satisfy global_include_text "コマンドライン引数=\[--resident-batch.enabled=true, --resident-batch.job-id=N2100006, --resident-batch.spring-batch-job-name=BA10301, --resident-batch.run-interval=60000, --boot-prop=bootPropValue, --app-prop=appValue, job-param=jobValue, file=/home/app/shellspec/work/result]"

        # 常駐起動しているjavaプロセスを強制終了
        pkill java
    End

    It "常駐バッチ"
        Data "y"
        When run script "${SCRIPTS_DIR}"/常駐バッチ/N2100002 file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The status should equal 0
        The output should include "[ func_resident_batch.sh ] EXIT_CODE = [0]"
        The file "${WORK_DIR}"/result should satisfy global_include_text "JVM引数=\[-Dsample=resiValue1, -Xms256m, -DsysProp=sysPropValue]"
        The file "${WORK_DIR}"/result should satisfy global_include_text "コマンドライン引数=\[--resident-batch.enabled=true, --resident-batch.job-id=N2100002, --resident-batch.spring-batch-job-name=BA10201, --resident-batch.run-interval=120000, --boot-prop=bootPropValue, --app-prop=appValue, job-param=jobValue, file=/home/app/shellspec/work/result]"

        # 常駐起動しているjavaプロセスを強制終了
        pkill java
    End

    It "都度起動バッチ"
        Data "y"
        When run script "${SCRIPTS_DIR}"/都度起動バッチ/N2100001 file="${WORK_DIR}"/result

        # バックグラウンド実行しているためファイル出力が完了するまで待機
        global_wait_for_make_file "${WORK_DIR}"/result

        The status should equal 0
        The output should include "[ func_single_batch.sh ] EXIT_CODE = [0]"
        The file "${WORK_DIR}"/result should satisfy global_include_text "JVM引数=\[-Dsample=singValue1, -Xms256m, -DsysProp=sysPropValue]"
        The file "${WORK_DIR}"/result should satisfy global_include_text "コマンドライン引数=\[--spring.batch.job.name=BA10101, --boot-prop=bootPropValue, --app-prop=appValue, job-param=jobValue, file=/home/app/shellspec/work/result]"
    End
End