# shellcheck shell=sh

# テスト用のワーキングディレクトリ(都度クリアされる)
export WORK_DIR="${SHELLSPEC_PROJECT_ROOT}/work"


# Defining variables and functions here will affect all specfiles.
# Change shell options inside a function may cause different behavior,
# so it is better to set them here.
# set -eu

# This callback function will be invoked only once before loading specfiles.
spec_helper_precheck() {
  # Available functions: info, warn, error, abort, setenv, unsetenv
  # Available variables: VERSION, SHELL_TYPE, SHELL_VERSION
  : minimum_version "0.28.1"
}

# This callback function will be invoked after a specfile has been loaded.
spec_helper_loaded() {
  :
}

# This callback function will be invoked after core modules has been loaded.
spec_helper_configure() {
  # Available functions: import, before_each, after_each, before_all, after_all
  : import 'support/custom_matcher'

  before_each "global_before_each"
}

# 全テストで共通実行する前処理
global_before_each() {
    # 作業ディレクトリのクリア
    rm -rf "${WORK_DIR}"
    mkdir "${WORK_DIR}"

    # シェルのログ出力ディレクトリ
    rm -rf /home/app/shell/auto_sh/JOBLOG
    mkdir /home/app/shell/auto_sh/JOBLOG
}

# ディレクトリと内容を指定してシェルスクリプトを生成する(上書き)
# 引数に出力先ファイルのパスを渡し、シェルスクリプトの内容は標準入力から渡す
# (例)
# global_make_script path/to/script.sh << 'EOF'
# #!/bin/sh
# echo hello $1
# EOF
global_make_script() {
    path=$1
    content=$(cat -)

    echo "${content}" > "${path}"
    chmod +x "${path}"
}

# Subjectで指定されたファイルの中に、第一引数で指定されたパターン文字列が含まれているかを検証するMatcher関数
global_include_text() {
    # shellcheck disable=SC2154 # global_include_text変数はShellSpecによって設定されている
    grep "$1" "${global_include_text}"
}

# 引数で指定されたファイルが生成されるまで処理を待機する
global_wait_for_make_file() {
    while [ ! -e "$1" ]
    do
        sleep 1
    done
}

# Subjectで指定されたファイルと、引数で指定されたファイルが一致することを検証するMatcher関数
global_check_file_diff() {
    # shellcheck disable=SC2154 # global_check_file_diff変数はShellSpecによって設定されている
    diff "${global_check_file_diff}" "${1}"
}

# Subjectで指定されたディレクトリと、引数で指定されたディレクトリの中身が一致することを検証するMatcher関数
global_check_dir_diff() {
    # shellcheck disable=SC2154 # global_check_dir_diff変数はShellSpecによって設定されている
    diff -r "${global_check_dir_diff}" "$1"
}

# Subjectで指定されたtarファイルを解凍した結果と、引数で指定されたディレクトリの内容が一致することを検証するMatcher関数
global_check_tar_diff() {
    # 出力された tar ファイルを解凍して、圧縮前のディレクトリと差分がないことを確認する
    mkdir "${WORK_DIR}"/result
    # shellcheck disable=SC2154 # global_check_tar_diff変数はShellSpecによって設定されている
    tar xzvf "${global_check_tar_diff}" -C "${WORK_DIR}"/result
    diff -r "$1" "${WORK_DIR}"/result
}

# Subjectで指定された暗号化ファイルを復号した結果と、引数で指定されたファイルの内容が一致することを検証するMatcher関数
# 第一引数：比較対象のファイル
# 第二引数：復号で使用する鍵ファイル
global_check_encrypted_file() {
    # shellcheck disable=SC2154 # global_check_encrypted_file変数はShellSpecによって設定されている
    openssl enc -d -aes256 -in "${global_check_encrypted_file}" -out "${WORK_DIR}"/decrypted -kfile "$2" 2> /dev/null
    diff "${WORK_DIR}"/decrypted "$1"
}

# Subjectで指定されたファイルと、引数で指定されたサーバー側のファイルが一致することを検証するMatcher関数
global_check_sftp_file_diff() {
    LOCAL_FILE=${WORK_DIR}/localfile
    sftp -oIdentityFile=/home/app/key/sftp/sftp.key sftp-user@sftp-server << EOF 2>/dev/null
get $1 $LOCAL_FILE
quit
EOF
    # shellcheck disable=SC2154 # global_check_sftp_file_diff変数はShellSpecによって設定されている
    diff "${LOCAL_FILE}" "${global_check_sftp_file_diff}"
}

# 指定したファイルを sftp でサーバーに put する
# 第一引数：ローカルファイルのパス
# 第二引数：put先のサーバー側のパス
global_sftp_put() {
    sftp -oIdentityFile=/home/app/key/sftp/sftp.key sftp-user@sftp-server << EOF 2>/dev/null
put $1 $2
quit
EOF
}

# 指定したサーバー側のディレクトリの直下にある全ファイルを削除する
global_sftp_clear_dir() {
    sftp -oIdentityFile=/home/app/key/sftp/sftp.key sftp-user@sftp-server << EOF 2>/dev/null
cd $1
rm *
quit
EOF
}