# 認証局セットアップ手順
マルチドメインに対応した、自前の認証局セットアップ方法を説明する。主に、以下の用途で使用する。

 * 開発環境
 * ステージング環境

発行した証明書はマルチドメインに対応した証明書となっており、他のコンテナでも使いまわしができる。サーバ証明書・CA証明書に関しては何度も発行する必要がない点に注意すること。

※自前の認証局は何の証明にもなっていないため、セキュリティ上よろしくない。本番環境での導入はしないこと。

## マルチドメイン証明書とは?
マルチドメイン証明書とは、1枚のSSL/TLS証明書で複数のFQDNをカバーできる証明書を指す。これは、証明書の拡張領域である SAN(Subject Alternative Name)に複数のFQDNを設定することで実現できる。

例えば、次のように1つの証明書で複数ドメインをまとめて管理することが可能になる。

```bash
 # 1枚のサーバ証明書(server.crt)で複数のFQDNを管理できる
 * server.crt
     `--+-- example.com
        +-- example.net
        `-- example.co.jp
```
主に各コンテナやサーバで必要なSSL/TLS通信を手軽に構築する手段として活用される。開発環境・ステージング環境では、この方式を利用して、各コンテナ内で必要となるSSL/TLS通信を実現する。

## 認証局を立ち上げる
本説明はDockerを利用した環境構築となっている。基本的なDockerの知識は必須なので、注意すること。

### compose.yamlの内容を確認する
`openssl`部分を使用する。要確認。

```yaml
services:
  :
  openssl:
    hostname: openssl
    image: nginx:1.27
    volumes:
      - ./infra/openssl:/certs
    working_dir: /certs
    profiles:
      - create-tls
    user: ${UID}:${GID}
```

### コンテナイメージ

 * 公式: https://hub.docker.com/_/nginx を利用

### コンテナへアタッチする
```
docker compose run --entrypoint bash --rm -it openssl
```

### 作業用ディレクトリを作成
証明書を発行する場所を作成する。

```
mkdir data
cd data
```

※`.gitignore` ファイルで、`data/`配下の証明書関連は除外する設定を記載している。そのため、作業場所となるディレクトリは"data"とすること。 

### OpenSSL設定ファイルを作成する
`/certs/openssl.cnf` ファイルを作成する。

```ini
[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext
# 以下はCA証明書作成時のみ使用（-x509 時に有効）
x509_extensions = v3_ca

[req_distinguished_name]

[req_ext]
subjectAltName = @alt_names
extendedKeyUsage = serverAuth, clientAuth

[v3_ca]
subjectAltName = @alt_names
extendedKeyUsage = serverAuth, clientAuth

# ↓ 複数のDNS、IPアドレスを記載することで、マルチドメインに対応できる!
[alt_names]
DNS.1 = localhost
DNS.2 = example
# ブラウザやgRPCなどの一部クライアントでは、
# IPアドレスをSAN値に含めていても証明書が無効とみなされる場合がある。
# なるべく、DNS.*を使用してホスト名でアクセスできるよう構成することを推奨する。
IP.1 = 127.0.0.1
```
`alt_names`には、証明書を使用するコンテナのホスト名を記載すること。

### CA証明書を作成する

```
openssl req -new -x509 -nodes \
  -days   3650 \
  -keyout ca.key \
  -out    ca.crt \
  -subj   "/C=JP/ST=Tokyo/L=Tokyo/O=ForTest/OU=TestTeam/CN=SelfSignedCA"
```
※オプションの`-subj`は環境に応じて変えること。開発環境で使う分には、上記のままで問題ない。

### サーバ秘密鍵とCSRを生成する
```
openssl req -new -nodes \
  -keyout server.key \
  -out    server.csr \
  -config /certs/openssl.cnf \
  -subj   "/C=JP/ST=Tokyo/L=Tokyo/O=ForTest/OU=TestTeam/CN=example"
```

### サーバ証明書を発行する
```
openssl x509 -req \
  -in    server.csr \
  -CA    ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out   server.crt \
  -days  3650 \
  -extensions req_ext \
  -extfile /certs/openssl.cnf
```

#### -CAcreateserial の仕様
`-CAcreateserial` オプションを指定することにより、`ca.srl`ファイルが作成される。

このファイルには、「次に使用する証明書のシリアル番号(16進数)」が1行だけ記録されており、証明書の一意性を担保するために使用される。
複数の証明書を発行する際には、 `ca.srl` を削除せずに使いまわすこと。削除してしまうと、同じシリアル番号が再度使用され、証明書の重複が発生する可能性があるため注意すること。

## 証明書の内容を確認する

### サーバ証明書を確認する

```
openssl x509 -in server.crt -text -noout
```
以下の項目を確認すること。

 1. Issuer: 証明書の発行者を確認する
    ```
    Issuer: C=JP, ST=Tokyo, L=Tokyo, O=ForTest, OU=TestTeam, CN=SelfSignedCA
    ```
 2. Subject: 証明書の対象情報を確認する
    ```
    Subject: C=JP, ST=Tokyo, L=Tokyo, O=ForTest, OU=TestTeam, CN=example
    ```
 3. Validity: 証明書の有効期間を確認する
    ```
    Validity
        Not Before: Apr 15 14:16:49 2025 GMT
        Not After : Apr 13 14:16:49 2035 GMT
    ```
 4. SAN: マルチドメイン証明書の場合、適切なホスト名・IPが設定されているか確認する
    ```
    X509v3 extensions:
        X509v3 Subject Alternative Name:
            DNS:localhost, DNS:example, IP Address:127.0.0.1
    ```

### 証明書と秘密鍵の整合性を確認する
「サーバ秘密鍵」と「サーバ証明書」のハッシュ値が同じ値であれば、正しくペアになっている。下記のコマンドを実行し、各々のハッシュ値を確認すること。

 * サーバ秘密鍵のハッシュ値を確認する
   ```
   openssl rsa -noout -modulus -in server.key | openssl md5
   ```
 * サーバ証明書のハッシュ値を確認する
   ```
   openssl x509 -noout -modulus -in server.crt | openssl md5
   ```

### 認証局(CA)の証明書の内容を確認する

サーバ証明書のSubjectと有効期限を確認する場合は、下記のコマンドを実行すること。
```
openssl x509 -in ca.crt -text -noout
```

### 認証局(CA)からサーバ証明書が発行されているか確認する
下記コマンドを実行し、結果が "OK" か確認する。
```
openssl verify -CAfile ca.crt server.crt
server.crt: OK
```
