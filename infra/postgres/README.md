# PostgreSQLセットアップ手順
開発用途で使用するPostgreSQL起動方法について説明する。

## compose.yamlの内容を確認する
`database` 部分を使用する。

```yaml
services:
  :
  database:
    build:
      context: .
      dockerfile: ./infra/postgres/Dockerfile
      args:
        - PGVERSION=${PGVERSION}
        - HTTP_PROXY=${http_proxy:-}
        - HTTPS_PROXY=${https_proxy:-}
    hostname: database
    image: database
    # ホスト側からのアクセスはできません。 コンテナ間での接続のみを許可しています。
    #   - "5432:5432" とするとホストにもバインドされますが、今回は不要です。
    ports:
      - 5432
    environment:
      TZ: ${TZ}
      POSTGRES_DB: ${PGDATABASE}
      POSTGRES_USER: ${PGUSER}
      POSTGRES_PASSWORD: ${PGPASSWORD}
    # volumes:
      # データ永続化
      # - ./infra/postgres/data:/var/lib/postgresql/data
      # verify-fullなどの対応用
      # - ./infra/openssl/data/server.crt:/certs/server.crt
      # - ./infra/openssl/data/server.key:/certs/server.key
      # - ./infra/openssl/data/ca.crt:/certs/ca.crt
```

## コンテナイメージ

 * 公式: https://hub.docker.com/_/postgres を利用

## 環境変数の設定
`.env`ファイルに以下の設定を記載する。

```sh
# データベースホスト名を記載する。コンテナのホスト名となる。
PGHOST=database

# 5432を記載する。
PGPORT=5432

# データベース名を記載する。
# psql -U postgres -d <この部分> に設定するデータベース名となる
PGDATABASE=mydb

# データベースユーザとパスワードを指定する
PGUSER=postgres
PGPASSWORD=secret

# 使用するPostgreSQLのバージョンを記載する.
# なるべく、使用するバージョン番号を記載すること.
#   ex: PGVERSION=17.2
PGVERSION=latest
```

### verify-full用の接続変数（必要に応じて有効化）
verify-full設定が有効の場合、下記のコメントを外して接続確認を実施すること。

```sh
# PGSSLMODE=verify-full
# PGSSLCERT=/certs/client.crt
# PGSSLKEY=/certs/client.key
# PGSSLROOTCERT=/certs/ca.crt
```

#### 注意点

1. パスワードやユーザ名などが漏れてしまうと大事になるので、`.env`ファイルは漏洩しないよう大切に保管すること!
2. Gitで管理しないよう、`.gitignore`ファイルに`.env`を追加すること

## コンテナビルド

```
docker compose build database
```

## コンテナ起動
基本的には、 `docker compose up` によるオーケストレーション起動でOK。ただし、DBだけに不具合があるかを切り分けて調査したい場合は、DBサービスだけを個別起動することもできる。

```
docker compose up database
```

## コンテナの停止
単体での停止は以下のコマンドで行う。
```
docker compose down database
```

## データ永続化
PostgreSQLのデータを永続化するには、"data"ディレクトリを作成する。

```
mkdir ./infra/postgres/data
```
`compose.yaml`の以下のコメントを外す。

```yaml
services:
  :
  database:
    :
    volumes:
      # ↓ このコメントを外す
      # - ./infra/postgres/data:/var/lib/postgresql/data
      :
```
PostgreSQLの実データの置き場所は `/var/lib/postgresql/data` となっている。故に上記の対応を実施後にコンテナを起動すれば、データが永続化される。

## DBデータの削除
永続化したデータを初期化する場合は、"data"ディレクトリを削除する。
```
sudo rm -rf ./infra/postgres/data
mkdir -p ./infra/postgres/data
```
※ホストとコンテナでUID/GIDが異なるため、削除時にはsudoが必要になることがあります。

## verify-full対応
開発用途は基本`verify-full`の設定は不要だが、ステージング環境で動作させる場合はなるべくセキュアな暗号化が推奨される。ここでは `verify-full` でDBと接続する方法を説明する。

### verify-fullとは?
DBとのセキュアな接続設定のことを指す。以下は、PostgreSQLが提供する`sslmode`の種類とその比較表である。

| sslmode       | 暗号化 | CAの検証 | ホスト名の検証 | 必要な証明書 |
|:--            |:--     |:--    |:--    |:-- |
| `disable`     | 無効   | X     | X     | なし |
| `allow`       | 任意   | X     | X     | 任意 |
| `prefer`      | 任意   | X     | X     | 任意 |
| `require`     | 必須   | X     | X     | 任意 |
| `verify-ca`   | 必須   | O     | X     | CAが署名 |
| `verify-full` | 必須   | O     | O     | CA署名 + CNがホスト名と一致 |

このことからも、`verify-full`は本番環境やステージング環境に最も推奨される接続方法であることがわかる。

### サーバ証明書を作成する
以下の手順を用いて、サーバ秘密鍵や証明書など、一通りCA証明書含めて作成しておくこと(既に作成済みの場合は証明書の再構築は不要)。

 * [開発環境・ステージング環境用の証明書の発行](/infra/openssl/README.md)

サーバ証明書やCA証明書を作成し、適切な場所へ保存した後、compose.yamlの以下のコメントを外して証明書関連をmountする。

```yaml
services:
  :
  database:
    :
    volumes:
      :
      # ↓のコメントを全て外す
      # - ./infra/openssl/data/server.crt:/certs/server.crt
      # - ./infra/openssl/data/server.key:/certs/server.key
      # - ./infra/openssl/data/ca.crt:/certs/ca.crt
```

### クライアント証明書を作成する
[開発環境・ステージング環境用の証明書の発行](/infra/openssl/README.md)で作成した、CA証明書を使用して、クライアント証明書を作成する。

```bash
# 秘密鍵作成
openssl genrsa -out client.key 2048

# CSRファイルの作成
openssl req -new -key client.key -out client.csr \
  -subj "/C=JP/ST=Tokyo/L=Tokyo/O=MyOrg/OU=Dev/CN=database"

# クライアント側の証明書
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out client.crt -days 3650
```
※このCNはPostgreSQLサーバのホスト名（database）と完全一致させる必要があります。異なると verify-full に失敗します！

### 各種設定ファイルを修正する
コンテナを起動してアタッチする。

```
docker compose up -d database
docker compose exec -it database bash
```

アタッチ後 `/var/lib/postgresql/data` 配下の設定ファイルを修正し、証明書を使用した接続を有効にする。基本操作はvimでの作業となるため、注意すること。

#### postgresql.conf

```conf
ssl = on
# 証明書はコンテナ起動直後に /var/lib/postgresql ディレクトリ配下に置かれている.
ssl_ca_file = /var/lib/postgresql/ca.crt
ssl_cert_file = /var/lib/postgresql/server.crt
ssl_key_file = /var/lib/postgresql/server.key
```

#### pg_hba.conf

```conf
# ↓の行だけ追記
# TYPE  DATABASE  USER  ADDRESS    METHOD
hostssl all       all   0.0.0.0/0  cert clientcert=verify-full map=certmap

# ↓ local ～から下は修正する必要なし
# "local" is for Unix domain socket connections only
local   all             all                                     trust
 :
host all all all scram-sha-256
```
※"host"設定を削除すると、ローカルからのアクセス含めて、すべてのホスト・すべてのユーザからの接続に対し、クライアント証明書が必須になる。

#### pg_ident.conf
```conf
# MAPNAME       SYSTEM-USERNAME         PG-USERNAME
certmap         database                postgres
```

`pg_ident.conf`の設定は若干注意が必要。この設定は、クライアント証明書を使用して、どのユーザを使わせるか? という設定になっている。

 * `SYSTEM-USERNAME`:  
   クライアント証明書のCNと一致させること。
 * `PG-USERNAME`:  
   接続に使用したいPostgreSQLユーザ名を記載すること。

---

設定完了後、コンテナを再起動することで、`verify-full`設定が有効化される。


### DB接続確認
`compose.yaml`の`dbconn`にDB接続動作確認用コンテナの設定を記載している。

```yaml
  # DB接続検証用コンテナ. 動作確認用
  #   使用例: docker compose run --rm -it dbconn psql ...
  dbconn:
    image: postgres
    env_file:
      - .env
    profiles:
      - connect-test
    volumes:
      # verify-fullなどの対応用. クライアント証明書がマウントされている確認すること!
      - ./infra/openssl/data/client.crt:/certs/client.crt
      - ./infra/openssl/data/client.key:/certs/client.key
      - ./infra/openssl/data/ca.crt:/certs/ca.crt
```
証明書・秘密鍵関連が適切にマウントされているか確認し、以下のコマンドを実行してちゃんと接続できるか確認する。

#### 環境変数を確認する
`.env`ファイルの下記のコメントを外して、クライアント証明書を使用した接続確認をできるようにする。

```sh
PGSSLMODE=verify-full
PGSSLCERT=/certs/client.crt
PGSSLKEY=/certs/client.key
PGSSLROOTCERT=/certs/ca.crt
```

#### 接続テスト開始
psqlコマンドを実行してみる。

```bash
docker compose run --rm -it dbconn psql
```
以下の結果になれば、クライアント証明書を使用した接続は成功している。

```
psql (17.2 (Debian 17.2-1.pgdg120+1), server 16.8 (Debian 16.8-1.pgdg120+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off, ALPN: none)
Type "help" for help.

mydb=#
```

最後に`\conninfo`等実行して、以下のような情報が表示されれば成功となる。

```
mydb=# \conninfo
 :
You are connected to database "mydb" ...
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, ...)
```

## PostgreSQLのアップデート
PostgreSQLはメジャーバージョン間でデータディレクトリの互換性がない。そのため、PostgreSQLコンテナのバージョンを無暗に変えてしまうと次のようなエラーになり、コンテナが起動しなくなる。

```
FATAL: database files are incompatible with server
DETAIL: The data directory was initialized by PostgreSQL version 16, 
        which is not compatible with this version 17.2.
```

この点においては、`.env`ファイルの`PGVERSION`を`latest`で設定していると起きる可能性がある。なるべく`PGVERSION`に関してはバージョン番号を指定するのが望ましい。

### アップデート対応方法
 * PostgreSQLのバージョンをアップデートしたい
 * 意図しないコンテナのアップデートにより、エラーでPostgreSQLコンテナが起動しなくなったので、やむを得ずバージョンアップに対応したい
 
などの場合は、PostgreSQLのバージョンアップを実施すること。
ここで説明する例は、冒頭で記載した通り v16 ⇒ v17 に意図せずバージョンが変わってしまった例を用いて説明する。

#### DBバックアップする
v16用のDockerコンテナを入れ直し、PostgreSQLの論理バックアップを実施する。

1. `.env`ファイルを修正する - (ホスト側作業)
   ```bash
   # バージョンを旧バージョンであるv16に戻す
   PGVERSION=16
   ```
2. コンテナをビルドする - (ホスト側作業)
   ```
   docker compose build
   ```
3. 論理バックアップを実施する - (ホスト側作業)
   ```bash
   docker compose exec -it database pg_dumpall -U postgres > backup.sql
   ```
4. コンテナを停止する - (ホスト側作業)
   ```
   docker compose down
   ```

以上で論理バックアップは完了となる。

#### アップグレードする
コンテナのバージョンをv17へアップグレードする。

1. `.env`ファイルを修正する - (ホスト側作業)
   ```bash
   # 最新バージョンへ・・・
   PGVERSION=17.2
   ```
2. コンテナをビルドする - (ホスト側作業)
   ```
   docker compose build
   ```
3. "data"ディレクトリをリネームする - (ホスト側作業)
   ```bash
   # 旧データをmountさせないようにする
   sudo mv ./infra/postgres/data ./infra/postgres/data.old
   # 新データ置き場を作成する
   mkdir -p ./infra/postgres/data
   ```
4. compose.yamlを次のように修正する - (ホスト側作業)
   ```yaml
   database:
     :
     volumes:
       # backup.sqlを起動時に実行できるようにマウントする
       - ./backup.sql:/docker-entrypoint-initdb.d/backup.sql
   ```
5. コンテナを起動する - (ホスト側作業)
   ```bash
   # これにより、backup.sqlが実行され、データが復元される
   docker compose up -d database
   ```
6. リストアされたかDBを確認する - (ホスト側作業)
   ```
   docker compose exec -it database psql -U postgres  -c "\l"
   ```
7. compose.yamlからbackup.sqlマウントを外して、コンテナを起動し直す - (ホスト側作業)
8. データが正しくリストアされたか確認後、後片付けを実施する - (ホスト側作業)
   ```
   sudo rm -rf ./infra/postgres/data.old
   rm -f backup.sql
   ```

以上で、PostgreSQLのアップグレードは完了となる。
