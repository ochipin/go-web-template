# OpenLDAPセットアップ手順
この手順は、**開発・検証用途**で使用するOpenLDAPの起動方法について説明する。

本手順で構築するOpenLDAP環境は、

 * **「アプリケーション開発時にLDAP操作を検証・デバッグする目的」** としており、
 * **「本番環境や認証基盤としての利用は想定していない」** 点に注意すること。

## compose.yamlの内容を確認する

 [`openldap`](/compose.yaml)セクションを使用する。

```yaml
services:
  :
  openldap:
    build:
      context: .
      dockerfile: ./infra/openldap/Dockerfile
      args:
        HTTP_PROXY: ${http_proxy:-}
        HTTPS_PROXY: ${https_proxy:-}
        CONTAINER_USER: ${UID:-0}
        CONTAINER_GROUP: ${GID:-0}
    ports:
      - 389 # LDAP
      - 636 # LDAPS
    hostname: openldap
    image: openldap
    env_file:
      - .env
    volumes:
      # LDAP起動時に適用するサーバ側のセットアップ用LDIFを配置する
      - ./infra/openldap/setup:/setup
      # LDAPクライアント側の設定ファイルを配置する
      - ./infra/openldap/ldap.conf:/etc/openldap/ldap.conf
      - ./infra/openldap/ldap.conf:/root/.ldaprc
      # 各種証明書の設定
      # - ./infra/openssl/data:/etc/openldap/certs
      # - ./infra/openssl/data/ca.crt:/usr/local/share/ca-certificates/cacert.crt
      # LDAPサーバが必要とするデータディレクトリ
      # - ./infra/openldap/data/configs:/etc/openldap/slapd.d
      # - ./infra/openldap/data/slapd:/var/lib/openldap/openldap-data
    ulimits:
      nofile:
        soft: 8192
        hard: 8192
```

## 環境変数の設定
`.env`ファイルに以下の設定を記載する。

```bash
# RootDNを設定する
LDAP_ROOT_DN="cn=Manager,dc=example,dc=com"

# OpenLDAPの管理者パスワードを設定する
LDAP_ROOT_PASSWORD=secret

# サフィックスを設定する
LDAP_ROOT_SUFFIX="dc=example,dc=com"

# LDAPサーバのIDを指定する。基本"1"でOK
LDAP_SERVER_ID=1

# バインドDN/パスワードを設定する
LDAP_BIND_DN="cn=Manager,dc=example,dc=com"
LDAP_BIND_PASSWORD=secret

# 検索位置となるベースDNを設定する
LDAP_BASE_DN="dc=example,dc=com"
```

### 注意点
 1. パスワードやユーザ名などが漏れてしまうと大事になるので、`.env`ファイルは漏洩しないよう大切に保管すること!
 2. Gitで管理しないよう、`.gitignore`ファイルに`.env`を追加すること!

## コンテナビルド
```
docker compose build openldap
```

基本的には、DevContainerによるオーケストレーション起動時に一括でビルドまで終わるため、自分でビルドする必要はない。何らかの設定ミスなどがあり、ビルドが通らない場合は上記の方法でビルドを行うこと。

## TLS証明書の準備
デプロイ先の環境が、`ldaps:///`での接続が必須の場合、開発環境もそれに合わせる必要がある。ここでは、TLS証明書の設定方法を説明する。

※もし、`ldap:///`での接続だけで問題ない場合は、本章を読み飛ばしても問題ない。

### TLS証明書の作成
サーバ証明書・CA証明書が未作成の場合は、次の手順を参考に証明書を作成すること。

 * [開発環境・ステージング環境用の証明書の発行](/infra/openssl/README.md)

`openssl.cnf`のSANに設定するマルチドメインのホスト名は、コンテナのホスト名と合わせること。

#### openssl.cnf 設定例
```ini
# ↓ 複数のDNS、IPアドレスを記載する
[alt_names]
DNS.1 = localhost
# 開発用のOpenLDAPコンテナのホスト名は'openldap'なので、openldapと記載する。
DNS.2 = openldap
DNS.3 = database

IP.1 = 127.0.0.1
```

### 発行した証明書をmountする
`compose.yaml`ファイルを修正し、証明書一式`mount`する。

```yaml
services:
  :
  openldap:
    :
    volumes:
      :
      # 各種証明書をコンテナへmount
      - ./infra/openssl/data:/etc/openldap/certs
      # CA証明書は別途OS側で認識させるために別のパスへmount
      - ./infra/openssl/data/ca.crt:/usr/local/share/ca-certificates/cacert.crt
```

### TLS証明書の適用
`infra/openldap/setup/startup/00-setup-basic.ldif` ファイル開き、以下の設定ファイルを修正する。

```yaml
# 証明書のパスを設定
dn: cn=config
changetype: modify
# mountしているCA証明書のパスを記載する
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/openldap/certs/ca.crt
-
# mountしているサーバ証明書のパスを記載する
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/server.crt
-
# mountしているサーバ秘密鍵のパスを記載する
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/server.key
-
# 下記の設定は、環境に応じて変更すること!
replace: olcTLSVerifyClient
olcTLSVerifyClient: try
```
上記の`ldif`ファイルは、コンテナ起動時に適用される設定である。指定する証明書のパスは、必ずコンテナ内に`mount`されたパスを記述すること。

### olcTLSVerifyClientの設定
OpenLDAPの接続方式は、次の4つが用意されている。

| 設定値 | セキュリティ強度 | クライアント証明書の要求 | クライアント証明書の有無 | CA証明書の有無 |
|:--       |:--          |:--                   |:--                   |:--            |
| `never`  | ★☆☆☆☆    | 要求しない           | 不要                  | 不要 |
| `allow`  | ★★☆☆☆    | あれば検証           | なしでもOK             | 必須(クライアント証明書があれば) |
| `try`    | ★★★★☆    | あれば検証           | なしでもOK             | 必須 |
| `demand`  | ★★★★★    | 必須                | 必須                  | 必須 |

「設定値」は、各々次の用途で使用するのが望ましい。

 - neverはクライアント証明書の要求や検証をしないので、主にテスト目的や単純な動作確認用として使用することが推奨される。
 - allowに関しては暗号化すればよい、などの比較的高いセキュリティレベルを要求しない環境でのみ使用すること。
 - tryに関しては、最低限CA証明書は必須となるため、ステージング環境ではtry以上を使用すること。
 - ステージング環境などは、クライアント証明書が必須になる`demand`での運用が望ましい。

### ldap.confの修正

```bash
 :
# try以上の場合は、CA証明書のパスを設定すること!
# コンテナ側に配置しているCA証明書のパスにすること!
TLS_CACERT /etc/openldap/certs/ca.crt
#TLS_CERT /etc/openldap/certs/client.crt
#TLS_KEY /etc/openldap/certs/client.key
TLS_REQCERT try
 :
```
設定ファイルは、セキュリティ強度によって修正方法が異なるため、都度動作確認をしながら修正すること。

## コンテナの起動準備
コンテナを起動する前に行う、設定ファイルやレコード追加方法などの準備方法を説明する。

### 設定ファイル群の構成
OpenLDAPの設定ファイルは、用途毎に以下のディレクトリで管理している。

```bash
 setup/
  `--+-- customize/   # コンテナ初回起動時に追加されるLDAPレコード情報
     |                #   ⇒ 主に、ユーザ・グループ・所属・ディレクトリ毎に記載する
     +-- initialize/  # コンテナ初回起動時のみ適用される設定ファイル群
     |                #   ⇒ LDAP本体やスキーマの設定、モジュールの適用など
     `-- startup/     # 起動する度に実行される設定ファイル群
                      #   ⇒ ACLやTLS証明書の適用、冗長化設定など
```

各設定ファイルは名前が決まっており、次のように命名されている。

| 設定ファイル名      | 実行タイミング | 分類 | 説明 |
|:--                  |:--           |:-- |:-- |
| `setup-slapd.ldif`   | 初回起動時    | initialize | LDAP本体の設定 |
| `setup-schema.ldif`  | 初回起動時    | initialize | カスタムスキーマの設定 |
| `setup-overlay.ldif` | 初回起動時    | initialize | 各種有効にしたモジュールの設定 |
| `00-setup-basic.ldif` | 毎起動時 | startup | サーバ証明書やパスワードの設定 |
| `10-setup-acl.ldif`   | 毎起動時 | startup | ACLの設定 |
| `20-setup-repl.ldif`  | 毎起動時 | startup | 冗長化構成などの設定 |
| `add-record.ldif`     | 初回起動時 | customize | LDAPレコードの追加設定 |

コンテナを起動すると自動的に上記の設定ファイルが順次読み込まれて、OpenLDAPコンテナが作成される。ここでは、これらの構成を使って、コンテナ起動前に行う設定方法について説明する。

### カスタムスキーマの設定
初回起動時に、以下の設定ファイルを修正することでカスタムスキーマを追加できる。

 * [`/infra/openldap/setup/initialize/setup-schema.ldif`](/infra/openldap/setup/initialize/setup-schema.ldif)

カスタムスキーマの設定方法は`setup-schema.ldif`ファイルのコメント欄に記載しているので、そちらを参照すること。

### ACLの追加設定
以下の設定ファイルを修正することでACLを設定できる。

 * [`/infra/openldap/setup/startup/10-setup-acl.ldif`](/infra/openldap/setup/startup/10-setup-acl.ldif)

ACLの設定方法は`10-setup-acl.ldif`ファイルのコメント欄に記載しているので、そちらを参照すること。

※この設定ファイルは修正後、コンテナの再起動が必要になる。

### LDAPレコードの追加
レコードの追加は以下のファイルで行う。

 * [`/infra/openldap/setup/customize/add-record.ldif`](/infra/openldap/setup/customize/add-record.ldif)

このファイルに、ディレクトリや所属、グループやユーザなどを追加していくことになる。設定するサフィックスによってDNの書き方は異なるので、必ずルートサフィックスの設定を基にレコード追加設定を記載すること。

### ルートサフィックス等の変更
デフォルトは`dc=example,dc=com`というサフィックスになっている。このサフィックスを変更する方法を説明する。ここでは、`dc=openldap,dc=net`に変えることを前提に説明する。

 1. `.env`を修正する
    ```sh
    LDAP_ROOT_DN="cn=Manager,dc=openldap,dc=net"
    LDAP_ROOT_PASSWORD=secret
    LDAP_ROOT_SUFFIX="dc=openldap,dc=net"

    LDAP_BIND_DN="cn=Manager,dc=openldap,dc=net"
    LDAP_BIND_PASSWORD=secret
    LDAP_BASE_DN="dc=openldap,dc=net"
    ```
 2. `ldap.conf`を修正する
    ```conf
    BASE   dc=openldap,dc=net
    URI    ldap://openldap
    ```
 3. `add-record.ldif`ファイルのサフィックスを変更する
    ```yaml
    dn: dc=openldap,dc=net
    objectClass: dcObject
    objectClass: organization
    dc: openldap
    o: openldap
     :
    # ユーザ・グループ分のレコード含め、すべてサフィックスを変更する
    dn: uid=uidXXX,ou=People,dc=system,dc=openldap,dc=net
    ```
 4. `10-setup-acl.ldif`に記載されているサフィックスを変更する
    ```yaml
    olcAccess: to attrs=userPassword
      by dn="cn=Manager,dc=openldap,dc=net" write
      :
    ```

サフィックスを変更する場合は、上記4つのファイルの修正が必要になる。
また、既存のレコードがある場合は、一旦レコードをすべて削除してから、変更する必要がある。

## コンテナの起動・停止・再起動

### コンテナの起動
```
docker compose --profile "development" up
```

### コンテナの停止
```
docker compose --profile "development" down
```

### コンテナの再起動
```
docker compose --profile "development" restart
```

## LDAPデータの永続化

データ永続化用のディレクトリを作成する
```sh
# LDAP設定ファイル群の保存先
mkdir -p ./infra/openldap/data/configs
# LDAPレコードの保存先
mkdir -p ./infra/openldap/data/slapd
```

compose.yamlを次のように修正する。

```yaml
 openldap:
   :
   volumes:
      # LDAPサーバが必要とするデータディレクトリ
      - ./infra/openldap/data/configs:/etc/openldap/slapd.d
      - ./infra/openldap/data/slapd:/var/lib/openldap/openldap-data
```
LDAPは、設定ファイルとレコードは別々の場所に保存されるため、2か所に必ずmountすること。

### LDAPデータの初期化
```sh
# データを一旦削除
rm -rf ./infra/openldap/data/configs
rm -rf ./infra/openldap/data/slapd

# 再度ディレクトリを作成する
mkdir -p ./infra/openldap/data/configs
mkdir -p ./infra/openldap/data/slapd
```

## LDAPデータのバックアップ/リストア
あまり必要になるケースはないが、既存のデータをすべてダンプさせリストアする方法を説明する。

### バックアップ
OpenLDAPコンテナ起動中に以下のコマンドを実行する。

```
docker compose exec -it openldap ldapsearch \
  -xLLLD cn=Manager,dc=example,dc=com \
  -b     dc=example,dc=com -w secret > backup.ldif
```

### リストア
`backup.ldif`と、`add-record.ldif`を置き換える。

```
mv -f backup.ldif ./infra/openldap/setup/customize/add-record.ldif
```

LDAPデータの初期化を行い、コンテナを再起動すればデータを復元できる。

## CUIでの接続テスト

接続テスト用コンテナへアタッチする。

```
docker compose run --entrypoint bash --rm -it ldap-cui
```

ldapsearchコマンドを実行し、検索結果を得られるか確認する。

```
ldapsearch -xLLLD cn=Manager,dc=example,dc=com -w secret
```

### 証明書が求められる場合
クライアント証明書が必要な場合は、[開発環境・ステージング環境用の証明書の発行](/infra/openssl/README.md)で作成した、CA証明書を使用して、クライアント証明書を作成する。

```bash
# 秘密鍵作成
openssl genrsa -out client.key 2048

# CSRファイルの作成
openssl req -new -key client.key -out client.csr \
  -subj "/C=JP/ST=Tokyo/L=Tokyo/O=MyOrg/OU=Dev/CN=openldap"

# クライアント側の証明書
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out client.crt -days 3650
```

証明書作成後、compose.yamlを修正する。

```yaml
  # CUI形式のOpenLDAPコンテナへの接続テスト用コンテナ
  ldap-cui:
    :
    volumes:
      :
      # 作成したクライアント証明書含む、証明書一式マウントする
      - ./infra/openssl/data:/etc/openldap/certs
```

#### ldap.confの修正
クライアント証明書がある場合は下記の設定を実施する。

```bash
 :
# try以上の場合は、CA証明書のパスを設定すること!
# コンテナ側に配置しているCA証明書のパスにすること!
TLS_CACERT /etc/openldap/certs/ca.crt
# クライアント証明書があれば、下記のコメントを外す
TLS_CERT /etc/openldap/certs/client.crt
TLS_KEY /etc/openldap/certs/client.key

TLS_REQCERT demand
 :
```
コンテナを再起動後、接続テストして問題なければテスト無事成功となる。

## GUIでの接続テスト
ブラウザから、下記URLヘアクセスする。

| PROTOCOL | URL                          |
|:--       |:--                           |
| HTTPS    | https://localhost:8443/ldap/ |
| HTTP     | http://localhost:8080/ldap/  |

接続後のパスワードは、BindDN/BindPWを入力する。以下に例を示す。

| 入力項目 | 入力する値 |
|:--      |:--    |
| Login DN: | `cn=Manager,dc=example,dc=com` |
| Password: | `secret` |
