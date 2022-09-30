# MyBatis Generatorセットアップガイド

## 概要

MyBatisで使用するドメインモデルやマッパーを自動生成するツールです。
MyBatisが公式に提供しているツールであり、ここではセットアップ方法をガイドします。

より詳細な使い方を知りたい場合は以下の公式ドキュメントを参照してください。

- https://mybatis.org/generator/


## Mavenへの組み込み方

MyBatis GeneratorはMavenから利用できます。

`pom.xml`へ`mybatis-generator-maven-plugin`を追加してください。

```xml
  <build>
    <plugins>
      <plugin>
        <groupId>org.mybatis.generator</groupId>
        <artifactId>mybatis-generator-maven-plugin</artifactId>
        <version>1.4.1</version>
        <configuration>
          <!-- dependency要素で定義されている依存を追加して実行する -->
          <includeAllDependencies>true</includeAllDependencies>
          <!-- 自動生成されたファイルが既にある場合、上書きする -->
          <overwrite>true</overwrite>
        </configuration>
      </plugin>
    <plugins>
  <build>
```

上記の例では`includeAllDependencies`と`overwrite`のみ設定を行なっています。
他の設定項目については以下のリファレンスを参照してください。

- https://mybatis.org/generator/running/runningWithMaven.html

例で設定している項目のうち、`includeAllDependencies`は実行時にJDBCドライバを追加したいために記述しています。

もし明示的にJDBCドライバを設定したい場合、`plugin`の下に`dependencies`および`dependency`を記述できます。

```xml
  <build>
    <plugins>
      <plugin>
        <groupId>org.mybatis.generator</groupId>
        <artifactId>mybatis-generator-maven-plugin</artifactId>
        <dependencies>
          <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <version>42.4.0</version>
          </dependency>
        </dependencies>
        <configuration>
          <overwrite>true</overwrite>
        </configuration>
      </plugin>
    <plugins>
  <build>
```


## 基本的な設定

自動生成に関する設定はデフォルトではクラスパス上にある`generatorConfig.xml`から読み取られます。

`src/main/resources/`に`generatorConfig.xml`を作成してください。

`generatorConfig.xml`の例は次の通りです。

```xml
<!DOCTYPE generatorConfiguration PUBLIC
    "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
    "http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">
<generatorConfiguration>
  <context id="simple" targetRuntime="MyBatis3">

    <!-- 自動生成されたモデルにequalsメソッドとhashCodeメソッドを実装するプラグイン -->
    <plugin type="org.mybatis.generator.plugins.EqualsHashCodePlugin" />
    <!-- 自動生成されたモデルにtoStringメソッドを実装するプラグイン -->
    <plugin type="org.mybatis.generator.plugins.ToStringPlugin" />
    <!-- 自動生成されたマッパーインターフェースにMapperアノテーションを付けるプラグイン -->
    <plugin type="org.mybatis.generator.plugins.MapperAnnotationPlugin" />

    <!-- 生成されたコメントにタイムスタンプを含めない -->
    <commentGenerator>
      <property name="suppressDate" value="true" />
    </commentGenerator>

    <!-- JDBC接続設定 -->
    <jdbcConnection
        driverClass="org.postgresql.Driver"
        connectionURL="jdbc:postgresql://localhost:5432/postgres"
        userId="postgres"
        password="password" />

    <javaTypeResolver>
      <!-- データ型がDECIMALかNUMERICの場合にフィールドの型を強制的にBigDecimalにする設定 -->
      <!-- この設定を行わない場合、デフォルトでは桁数や小数の有無でフィールドの型が決定される -->
      <!-- 詳細はMyBatisの公式リファレンスを参照すること https://mybatis.org/generator/configreference/javaTypeResolver.html -->
      <property name="forceBigDecimals" value="true"/>
      <!-- 日時をLocalDateTime、LocalDate、LocalTimeで扱う設定 -->
      <property name="useJSR310Types" value="true"/>
    </javaTypeResolver>

    <!-- テーブルを表すモデルクラスを自動生成する -->
    <javaModelGenerator
        targetPackage="com.example.common.generated.model"
        targetProject="src/main/java" />

    <!-- Mapper XMLを自動生成する -->
    <sqlMapGenerator
        targetPackage="com.example.common.generated.mapper"
        targetProject="src/main/resources" />

    <!-- テーブルに対応するマッパーインターフェースを自動生成する -->
    <javaClientGenerator
        type="XMLMAPPER"
        targetPackage="com.example.common.generated.mapper"
        targetProject="src/main/java" />

    <!-- 自動生成対象となるテーブル -->
    <table tableName="client"/>
    <table tableName="project"/>

  </context>
</generatorConfiguration>
```

自動生成対象となるテーブルは上記例のように`table`要素に1つずつテーブルを記述しても良いですし、
以下のようにSQLの`like`演算で用いるワイルドカードを利用して記述することも可能です。

```xml
  <table tableName="T_%"/>
```

自動生成されるマッパーインターフェースには、主キーによる検索や複合的な条件による検索、登録、更新、削除など
様々なクエリーに対応したメソッドが自動生成されます。
これらのメソッドの自動生成を抑制したい場合、`table`要素が持つ`enable<メソッド名>`属性へ`false`を設定します。

例えば、`client`テーブルに対応するマッパーインターフェースでは登録メソッドと主キーによる検索メソッドを自動生成しない場合は
以下のような`table`要素を記述してください。

```xml
  <table tableName="client"
      enableInsert="false"
      enableSelectByPrimaryKey="false"/>
```

また、マッパーインターフェースそのものが不要な場合は`javaClientGenerator`要素と`sqlMapGenerator`要素を記述しないでください。
そうするとモデルだけが自動生成されるようになります。

`generatorConfig.xml`に関するより詳しい設定については以下の公式リファレンスを参照してください。

- https://mybatis.org/generator/configreference/xmlconfig.html


## 自動生成を行う

`pom.xml`へのMavenプラグイン組み込みと、`generatorConfig.xml`の準備が出来たら以下のコマンドで自動生成を行えます。

```bash
mvn mybatis-generator:generate
```

自動生成の処理はデータベースに接続し、取得したメタデータをもとに行われます。
そのため、`generatorConfig.xml`の`jdbcConnection`要素で設定したデータベースへ接続が可能な状態で自動生成を行うようにしてください。

