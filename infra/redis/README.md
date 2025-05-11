# Redisセットアップ手順
本コンテナは、 `app` コンテナで動作する、アプリのセッション情報を管理するものである。
開発環境・ステージング環境・本番環境のすべてにおいて、共通の構成で使用されることを想定している。

## compose.yamlの内容を確認する

```yaml
  # セッション設定
  session:
    hostname: session
    image: redis:8
    ports:
      - 6379
    profiles:
      - development
      - staging
      - production
    volumes:
      # Redisの設定ファイル
      - ./infra/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
      # ホスト側の /infra/redisをコンテナ側へマウント
      - ./infra/redis:/redis
      # データの永続化
      - redisdata:/data
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
```
基本的には、いずれの環境(開発・ステージング・本番)においても同一の構成で動作するように設計している。
ただし、必要に応じて `compose.yaml` を環境ごとに書き換えるか、オーバーライド設定を追加することで柔軟に対応することが可能である。

## 設定ファイルの変更方法
基本は変更する必要はないが、設定変更する場合は、[`/infra/redis/redis.conf`](/infra/redis/redis.conf) を変更して行う。

デフォルトの設定は以下のとおりである。

```bash
# AOFモードを有効化（最優先）
appendonly yes

# パフォーマンスと耐久性のバランス
appendfsync everysec

# 自動リライト設定（AOF肥大化防止）
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# その他の設定はデフォルトを使いたい場合、このファイルに追記可能
#maxmemory 256mb
#maxmemory-policy allkeys-lru
```

## コンテナの起動
```bash
# 単体起動
docker compose up session

# profile が "development" に所属しているコンテナを全て起動する
# staging, production など用途に応じて使い分けること
docker compose --profile development up -d
```

## コンテナの停止
```bash
# 単体停止
docker compose down session

# profile が "development" に所属しているコンテナを全て停止する
# staging, production など用途に応じて使い分けること
docker compose --profile development down
```

## コンテナの再起動
```bash
# 単体再起動
docker compose restart session

# profile が "development" に所属しているコンテナを全て再起動する
# staging, production など用途に応じて使い分けること
docker compose --profile development restart
```

## データ永続化
デフォルトでデータの永続化を有効にしている。

```yaml
volumes:
  # Redis のデータ永続化用ボリューム
  redisdata:

services:
  # セッション管理
  session:
    :
    volumes:
      # Redis のデータを永続化するためのボリュームをマウント
      - redisdata:/data
    :
```

### データ永続化の解除
以下の定義をコメントアウトし、コンテナを再起動することでデータの永続化を解除できる。

```yaml
    volumes:
      # - redisdata:/data <-- ココ!
```

### データ永続化の削除

#### 永続化ボリュームの確認

```bash
docker volume ls
DRIVER    VOLUME NAME
local     maildir
local     redisdata # これを削除したい
local     vscode
```

#### 永続化データの削除
コンテナを停止した上で以下のコマンドを実行する。

```bash
docker compose down session
docker volume rm redisdata
```

### データのバックアップ
`docker volume` にデータを保存している場合、そのままではサーバ移行時にデータが引き継がれない。コンテナから対象となるデータをホスト側へコピーする手法を用いて、以下にバックアップを取得する方法を示す。

#### バックアップ先・元を確認する
デフォルトでは、 `./infra/redis` ディレクトリをコンテナにマウントしている。

```yaml
    volumes:
      # バックアップコピーの保存先(ホスト側)
      - ./infra/redis:/redis
      # Redis の実データ(Docker ボリューム)
      - redisdata:/data
```

#### バックアップ対象の確認
今回対象となるRedisのデータは、コンテナ側の `/data` 配下に置かれている。

```bash
# Redis の appendonly.aof が格納されるディレクトリを確認
docker compose exec -it session ls -laR /data

# バックアップデータ
/data:
total 16
drwxr-xr-x 3 redis redis 4096 May 11 03:07 .
drwxr-xr-x 1 root  root  4096 May 11 03:07 ..
drwx------ 2 redis redis 4096 May 11 03:07 appendonlydir
-rw------- 1 redis redis   88 May 11 03:44 dump.rdb

/data/appendonlydir:
total 16
drwx------ 2 redis redis 4096 May 11 03:07 .
drwxr-xr-x 3 redis redis 4096 May 11 03:07 ..
-rw------- 1 redis redis   88 May 11 03:07 appendonly.aof.1.base.rdb
-rw------- 1 redis redis    0 May 11 03:07 appendonly.aof.1.incr.aof
-rw------- 1 redis redis  102 May 11 03:07 appendonly.aof.manifest
```

#### バックアップ開始

```bash
# コンテナへアタッチする
docker compose exec -it session bash

# docker volumeのデータをバックアップ先へコピーする
cp -Rfp /data /redis/
# ホスト側で閲覧できるように、権限を変える(ここはやらなくてもOK!)
chown -R 1000:1000 /redis/data/
```

#### データのリストア
コンテナが停止していることを確認し、以下のコマンドでリストア作業を行う。

```bash
# 一時的なコンテナを起動して、リストア作業を行う。
docker compose run --rm -it session bash

# データをコピーする
rm -rf /data/*
cp -Rfp /redis/data/* /data/

# コピー後、権限を"redis"にする (既にredisユーザになっている場合は不要)
chown -R redis:redis /data/
```

リストア後に `Redis` が正常に起動するかを確認し、問題がなければバックアップディレクトリ（`/infra/redis/data`）を削除してもよい。
