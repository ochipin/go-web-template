# Webサーバセットアップ手順
本コンテナは、app コンテナで動作するサービスに対するリバースプロキシの役割を担う。開発環境・ステージング環境だけでなく、本番環境でも使用される。

## compose.yamlの内容を確認する

### 共通設定
下記の共通設定を、開発・ステージング・本番の3つの環境毎に用意して使用することになる。

```yaml
  # 共通設定
  web-server-setting: &web-server-setting
    build:
      context: .
      dockerfile: ./infra/nginx/Dockerfile
      args:
        - HTTP_PROXY=${http_proxy:-}
        - HTTPS_PROXY=${https_proxy:-}
    image: ${PROJECT_NAME}/web-server
    ports:
      - 8080:80
      - 8443:443
    hostname: web-server
    profiles:
      - settings
    volumes:
      - ./infra/nginx/setup/http.conf:/etc/nginx/conf.d/default.conf
      # SSL/TLSが有効な場合は下記のコメントを外してHTTPSを有効化する
      # - ./infra/nginx/setup/https.conf:/etc/nginx/conf.d/ssl.conf
      # - ./infra/openssl/data:/certs
    extra_hosts:
      - "localhost:host-gateway"
      - "host.docker.internal:host-gateway"

  # 本番環境
  web-prod-server:
    <<: *web-server-setting
    profiles: ["production"]
    # 本番用の volumes や logging 設定をここに追加すること
```

### 開発環境
```yaml
  # 開発時に使用するWebサーバ
  web-dev-server:
    <<: *web-server-setting
    profiles: ["development"]
    volumes:
      - ./infra/nginx/setup/dev-http.conf:/etc/nginx/conf.d/default.conf
      # SSL/TLSを有効にする場合は下記のコメントを外してHTTPSを有効化する
      # - ./infra/nginx/setup/dev-https.conf:/etc/nginx/conf.d/ssl.conf
      # - ./infra/openssl/data:/certs
```

### ステージング環境
```yaml
  # ステージング環境で使用するWebサーバ
  web-staging-server:
    <<: *web-server-setting
    profiles: ["staging"]
    volumes:
      # ステージング環境で動かす場合はサーバ証明書は必須とする
      - ./infra/nginx/setup/staging-https.conf:/etc/nginx/conf.d/default.conf
      - ./infra/openssl/data:/certs
    logging:
      driver: "${LOGGING_DRIVER:-none}"
      options:
        syslog-address: "${LOGGING_ADDRESS:-}"
        tag: "nginx"
```
デフォルトでは、開発・ステージング環境だけは定義している。用途毎にセクションを修正しながら使用すること。また、本番環境に関しても随時設定を追加すること。

## 環境変数の設定
```sh
# コンテナ内のログ情報をsyslogへ出力する場合は、下記のコメントを外す
# この設定は、ステージング環境のみで有効となる。
# LOGGING_DRIVER="syslog"
# LOGGING_ADDRESS="tcp://localhost:514"

# Nginxのバージョンを記載する
NGINX_VERSION=1.27
```

## コンテナビルド
```
docker compose build web-server-setting
```

## コンテナの起動準備
Webサーバコンテナを起動する前に行う、事前準備について説明する。

### 設定ファイル群の構成
Nginxの設定ファイルは、以下のように各環境毎に用意する必要がある。

```bash
 nginx/setup
   `--+-- dev-http.conf       # 開発環境用
      +-- prod-https.conf     # 本番環境用
      `-- staging-https.conf  # ステージング環境用
```
また、各設定ファイル毎に冒頭で説明したようにcompose.yamlファイルにセクションを追加していくことになる。

### TLS証明書の準備
本番環境では、正式なサーバ証明書を用いて運用するのが一般的である。したがって、開発環境・ステージング環境においても、本番と同様の構成で動作確認が行えるように、TLS証明書を事前に用意しておくことが望ましい。

開発・ステージング環境では自己署名証明書を使用するが、以下の手順であらかじめ構築可能である。

 * [開発環境・ステージング環境用の証明書の発行](/infra/openssl/README.md)

なお、`openssl.cnf` に記載する SAN (Subject Alternative Name) のホスト名は、Nginx の `server_name` や Docker の `hostname` と一致させること（デフォルトでは `"web-server"` となっている）。

一致していない場合、ブラウザの証明書警告が発生するため注意すること。

#### TLS証明書の配置設定
`compose.yaml`ファイルを修正し、証明書一式を配置する。

```yaml
    volumes:
      - ./infra/nginx/setup/dev-https.conf:/etc/nginx/conf.d/ssl.conf
      - ./infra/openssl/data:/certs
```

#### TLS証明書の適用
mountするNginxの設定ファイルを次のように修正する。

```sh
server {
    listen       443 ssl; # HTTPを有効にする場合は 80 に変更する
    listen  [::]:443 ssl; # 同上（IPv6の場合）
    server_name  localhost;

    # SSL証明書ファイルと秘密鍵
    ssl_certificate     /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    :
```

以上がTLS/SSLの設定となる。

### 転送ファイルサイズ設定
設定ファイルの下記項目を変更する。

```sh
# 最大転送ファイルサイズ設定
client_max_body_size 200M;
```

## コンテナの起動
```
docker compose --profile "development" up
```

## コンテナの停止
```
docker compose --profile "development" down
```

## コンテナの再起動
```
docker compose --profile "development" restart
```
