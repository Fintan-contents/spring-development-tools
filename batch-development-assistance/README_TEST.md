# 自動テストについて

ここでは、シェルスクリプトの自動テストの仕組みや実行方法について説明します。

## 自動テストの構成・仕組み

`batch-development-assistance`ディレクトリには、以下のように自動テストに関するファイルが配置されています。

```
batch-development-assistance/
 |-scripts/                : テスト対象のスクリプトファイル(script.zipの中身)
 |-test/
 | |-mock-java-batch/      : Javaバッチのテストで使用するモックのJavaプログラム
 | |-sftp-key/             : sftpのテストで使用する鍵ファイルを配置したディレクトリ
 | `-spec/                 : ShellSpecのテスト仕様ファイルを配置したディレクトリ
 |   |-conf/               : scripts/conf/以下のシェルスクリプトのテスト仕様を配置したディレクトリ
 |   |-func/               : scripts/func/以下のシェルスクリプトのテスト仕様を配置したディレクトリ
 |   |-integration-test/   : 結合テストのテスト仕様を配置したディレクトリ
 |   | `-shells/           : 結合テストで使用する自動生成された起動スクリプトを配置するディレクトリ
 |   |-template/           : 自動生成する起動スクリプトのjavaTemplate, shellTemplateに対するテスト仕様を配置したディレクトリ
 |   `-spec_helper.sh      : ShellSpecのヘルパー関数ファイル
 |-compose.yml             : テスト用の環境を起動するためのdocker-composeファイル
 |-Dockerfile              : テスト用のDockerイメージを構築ためのDockerfile(app環境)
 |-docker-entrypoint.sh    : app 環境用の初期化スクリプト
 |-Dockerfile-sftp-sever   : テスト用のSFTPサーバーを構築するためのDockerfile(sftp-server環境)
```

シェルスクリプトの自動テストには、シェルスクリプト用のテスティングフレームワークである[ShellSpec](https://github.com/shellspec/shellspec)を使用しています。

また、ShellSpecのテストを実行するための環境を、Dockerを使って構築するようにしています。
Docker環境は、以下2つのコンテナを立ち上げる構成を採っています。

- app環境
    - テスト対象のシェルスクリプトやShellSpecのテスト仕様ファイルを配置し、実際にテストを実行する環境
- sftp-server環境
    - sftp関係のシェルスクリプトのテストをするための、SFTPサーバー環境

`compose.yml`を使ってDocker環境を起動したら、app環境のコンテナに接続し、規定のディレクトリでShellSpecのコマンドを実行することで自動テストが実行できる仕組みになっています。

なお、app環境の内部は以下のようなディレクトリ構成となっています。

```
/home/app/
 |-jdk-17-openjdk/    : JDKインストールディレクトリ(apt-get でインストールした JDK へのシンボリックリンク)
 |-app/
 | |-run/              : 実行対象の jar を配置しておくディレクトリ
 | |  `-app-batch.jar  : Javaバッチのjarファイル(volume:./test/mock-java-batch/target/app-batch.jar)
 | |-runningjar/       : 実行時に jar をコピーしてくるディレクトリ
 | `-shell-common/     : script.zipの中身を配置するディレクトリ(volume:./scripts/)
 |-work/
 | `-trancefer         : ファイル操作の対象となるファイルなどを配置する作業ディレクトリ
 |-key/
 | |-sftp/
 | | `sftp.key         : sftpで使用する秘密鍵(copy:./test/sftp-key/sftp.key)
 | `-crypt/
 |   `-ssl.key         : 暗号化・復号で使用する共通鍵
 `-shellspec/
   |-work/             : ShellSpec実行時に利用する一時ディレクトリ(テスト前に毎回削除＋作成)
   |-.shellspec        : ShellSpecのプロジェクトディレクトリを決めるファイル
   `-spec/             : ShellSpecのテスト仕様を配置するディレクトリ(volume:./test/spec/)
```

説明の後ろに`(volume:...)`と記載しているものは、Dockerコンテナ起動時に`--volume`でローカルのファイルやディレクトリを割り当てることを表しています。
また、`(copy:...)`と記載しているものは、Dockerイメージ構築時にローカルのファイルをCOPYして配置していることを表しています。

テスト対象のシェルスクリプト(`./scripts/`)やテスト仕様を配置したディレクトリ(`./test/spec/`)はボリュームで割り当てています。
したがって、ローカルでファイルを編集しながらDockerコンテナ上でテストを実行することができます（コンテナを作り直さなくていい）。


## 実行方法

自動テストは、以下の手順で実行します。

1. mock-java-batchをビルドする
2. 結合テスト用のスクリプトを自動生成して規定のディレクトリに配置する
3. Dockerコンテナを起動する
4. app環境に接続してShellSpecのコマンドを実行する

### mock-java-batchをビルドする

Javaバッチの起動スクリプトに対するテストで使用する、Javaバッチのモックアプリケーションを事前にビルドします。
ビルド方法は、[mock-java-batchのREADME](test/mock-java-batch/README.md)を参照してください。

### 結合テスト用の起動スクリプトを自動生成して規定のディレクトリに配置する

結合テストで使用する起動スクリプトを自動生成します。
結合テスト用の設定は、このディレクトリにデフォルトで配置されている各設定ファイル(Excel)に既に記載済みです。
したがって、このディレクトリにある各種設定ファイルを元に起動スクリプトの自動生成を行ってください。

生成した結果は、そのまま`test/spec/integration-test/shells/`ディレクトリの下に配置してください。
配置後のイメージは、以下のようになります。

```
batch-development-assistance/
 |-test/
 : `-spec/
     |-integration-test/
     : `-shells/                 : この下に自動生成結果をそのままコピーする
         |-conf/
         |-ファイルバックアップ/
         |-ファイル圧縮/
         |-ファイル暗号化復号/
         |-ファイル削除/
         |-ファイル受信/
         |-ファイル圧縮/
         |-ファイル暗号化復号/
         |-ファイル移動・コピー/
         |-ファイル解凍/
         |-ファイル送信/
         |-メール送信/
         |-常駐バッチ/
         `-都度起動バッチ/
```

### Dockerコンテナを起動する

テスト用のDockerコンテナを、docker-composeを使って起動します。
コマンドラインで`batch-development-assistance`ディレクトリに移動し、以下のコマンドを実行してください。

```
$ docker compose up -d
```

Dockerのイメージがビルドされ、コンテナが起動します。

※プロキシ環境下で起動する場合は、環境変数`HTTP_PROXY`, `HTTPS_PROXY`に、プロキシのURL(例:`http://proxy:8000/`)を設定してから実行してください。

なお、終了するときは以下のコマンドを実行してください。

```
$ docker compose down -v --rmi all
```

### app環境に接続してShellSpecのコマンドを実行する

起動したDockerコンテナのうち、app環境の方に接続します。

```
# 下記コマンドは、batch-development-assistanceディレクトリ配下で実行してください
$ docker compose exec app sh

$ pwd
/home/app/shellspec
```

接続直後のディレクトリ(`/home/app/shellspec`)が、ShellSpecを実行するためのディレクトリとなっています。
したがって、このまま`shellspec`コマンドを実行することで自動テストが起動します。

```
$ shellspec
Running: /bin/sh [sh]
................................./foo
（中略）
..........

Finished in 37.04 seconds (user 4.50 seconds, sys 2.86 seconds)
99 examples, 0 failures
```

テストが成功すれば、`0 failures`となって終了します。

### カバレッジの取得方法

カバレッジを取得する場合は、`--kcov`オプションを指定してShellSpecを実行します。

```
$ shellspec --kcov
```

結果が`/home/app/shellspec/coverage`の下に出力されます。
