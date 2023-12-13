# mock-java-batch

これは、Javaバッチ系のシェルスクリプトの自動テストを容易にするために使用する、モックのJavaバッチプログラムです。

## ビルド方法

ビルドはJava 17以上で行ってください。

```
$ mvn clean package
```

`target`ディレクトリの下に、`app-batch.jar`というjarファイルが出力されます。

## 実行方法

```
$ java -Xmx512m -jar /home/app/app/run/app-batch.jar hello world
JVM引数=[-Xmx512m]
コマンドライン引数=[hello, world]
process=UID        PID  PPID  C STIME TTY          TIME CMD
app       9427    19  0 07:18 pts/1    00:00:00 java -Xmx512m -jar /home/app/app/run/app-batch.jar hello world
```

`-jar`オプションに`app-batch.jar`を渡すことで実行できます。
なお、このjarはLinux環境上で動かすことを前提としているため(psコマンドを使用して情報を出力している)、Windows上では実行できません。

## 動作内容

[実行方法](#実行方法)に記載されているように、実行したJavaプログラムに対する入力情報や、起動時のコマンドの情報などが標準出力に出力されます。
また、特定の引数を渡すことで終了ステータスを制御したり、常駐バッチ化させることができます。

### 出力内容

標準出力に出力される内容には、以下が含まれます。

- JVM引数(javaコマンドオプション)
- コマンドライン引数
- javaプロセスの情報をpsコマンドで出力した結果

#### ファイルに出力する

引数に`file=path/to/output`のように出力先のファイルパスを渡すと、標準出力に出力した内容と同じものが指定されたファイルにも出力されます。

### 常駐バッチで起動する

引数に`--resident-batch.enabled=true`を指定すると、常駐バッチとして起動します。
起動後は、1秒に1回ドット(`.`)を標準出力に出力し続けます。
停止する場合は、プロセスを強制終了させてください。

### 終了ステータスを指定する

引数に`exitCode=xxx`と指定すると、`xxx`で指定した値がjavaコマンドの終了ステータスとして返されるようになります。
