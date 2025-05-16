# 開発環境内での動作確認方法
開発環境内での動作確認の方法について説明する。必ず開発環境の構築、ミドルウェアの構築まで完了していること。

 * [開発環境構築手順](/docs/setup-dev-environment.md)
 * [アーキテクチャ補足事項](/docs/middleware.md)

## PostgreSQLの確認方法
以下拡張機能を導入しており、GUIでデータベースに正しくデータが格納されているか確認できる。

![](/docs/images/postgresql-extension.png)

コンテナのPostgreSQLにアクセスする方法を説明する。

### 接続方法

1. サイドバーにある、PostgreSQLアイコンをクリックする
2. 上部の "+" ボタンをクリックすると、PostgreSQLに接続するための入力を求められる。
3. `[The hostname of the database]`  
   `.env`の`PGHOST`の値を入力する
4. `[The PostgreSQL user to authenticate as]`  
   `.env`の`PGUSER`の値を入力する
5. `[The password of the PostgreSQL user]`  
   `.env`の`PGPASSWORD`の値を入力する
6. `[The port number to connect to]`  
   5432を入力する
7. `[Use Secure Connection or Standard Connection]`  
   開発環境では "Standard Connection" で接続する
8. データベースを選択する  
   `.env`の`PGDATABASE`の値を選択する
9. `[The display name of the database connection]`  
   接続名を入力する。

以上で、コンテナ内で動作するPostgreSQLとの接続が出来るようになる。

### データベースの内容を確認する
多種多様な方法でデータベースの中身を確認する方法が存在するため、ここではクエリ文からデータを取得する方法を説明する。

1. データを確認したいテーブルを右クリックする
2. 「New Query」メニューをクリックする
3. クエリ入力用の画面が開くので、目的のクエリ文を入力する
4. クエリ入力用の画面内を右クリックして、「Run Query」を実行する(F5でも実行可)

上記の手順を実行することで、目的のテーブルの内容を確認できる。

## RestAPIの確認方法

RestAPIの動作確認は、以下の拡張機能を使う。既に開発環境にはインストール済みで、ここでは使い方を説明する。

![](/docs/images/rest-client-extension.png)

### 使用方法

1. 拡張子を ".http" のファイルを作成する。 ⇒ ここでは "test.http" とする。
2. ファイルは次のように記載する。
   ```bash
   ### Hello Worldを実行する
   GET http://localhost:8080/hello

   ### JSON送信
   POST http://localhost:8080/echo HTTP/1.1
   Content-Type: application/json

   {
       "YourName": "Suguru Ochiai"
   }

   ### Login
   POST http://localhost:8080/login HTTP/1.1
   Content-Type: application/json

   {
       "username": "admin",
       "password": "password"
   }
   ```
3. "###" で、動作確認したいリクエスト毎に区切ることができる

上記手順で作成したファイルを開くと、各リクエスト毎に「Send Request」ボタンが表示され、簡単にRestAPIの動作確認ができる。

---

一通りの動作確認方法については以上となる。
