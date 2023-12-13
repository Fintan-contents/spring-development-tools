# https://hub.docker.com/layers/library/ubuntu/22.04/images/sha256-dda6886d8d153a2d86f046c9335123c6151d83fd63e446b752ed8d9da261205d
FROM ubuntu@sha256:dda6886d8d153a2d86f046c9335123c6151d83fd63e446b752ed8d9da261205d

ARG http_proxy
ARG https_proxy

# 各種ツールのインストール
# JDK のインストール先 > /usr/lib/jvm/java-17-openjdk-amd64
RUN apt-get update -y && apt-get install -y \
    # JDK: Java バッチの起動に必要
    openjdk-17-jdk \
    # ShellSpec のインストールに必要
    wget git \
    # ShellSpec でカバレッジを計測するのに必要
    kcov \
    # sftpコマンドの一時的なmoveに必要
    sudo \
    # その他、作業用ツール
    vim less

# ShellSpec のインストール
RUN cd /opt && git clone https://github.com/shellspec/shellspec.git -b 0.28.1 --depth 1 
RUN ln -s /opt/shellspec/shellspec /usr/local/bin/

# ユーザ作成
RUN useradd -m app && \
    # パスワード無しで sudo できるように設定
    echo "app ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chown -R app:app /opt/shellspec

# ディレクトリ作成
USER app

RUN mkdir -p /home/app/app/runningjar \
    /home/app/app/run \
    /home/app/work/trancefer \
    /home/app/shell/auto_sh \
    /home/app/key/crypt \
    /home/app/shellspec

RUN ln -s /usr/lib/jvm/java-17-openjdk-amd64 /home/app/jdk-17-openjdk

# 共通鍵生成
RUN openssl rand -base64 -out /home/app/key/crypt/ssl.key 256

# sftp用の秘密鍵配置
COPY ./test/sftp-key/sftp.key /home/app/key/sftp/sftp.key

# ShellSpec のプロジェクトディレクトリ初期化
RUN echo "--require spec_helper" > /home/app/shellspec/.shellspec
# カバレッジ計測対象を設定
RUN echo '--kcov-options "--include-path=/home/app/app/shell-common,/home/app/shellspec/spec/integration-test/shells"' >> /home/app/shellspec/.shellspec
# 拡張子なしのファイルも対象になるように設定
RUN echo '--kcov-options "--include-pattern="' >> /home/app/shellspec/.shellspec
# 結合テストのソースが対象になるように /spec/ を --exclude-pattern から除外
RUN echo '--kcov-options "--exclude-pattern=/.shellspec,/coverage/,/report/"' >> /home/app/shellspec/.shellspec

WORKDIR /home/app/shellspec

# 初期化スクリプト配置
COPY ./docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
