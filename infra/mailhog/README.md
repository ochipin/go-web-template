# テスト用メールサーバのセットアップ手順
この手順は、**開発・検証用途**で使用するメールサーバの起動方法について説明する。

## compose.yamlの内容を確認する

[`mailserver`](/compose.yaml)セクションを使用する。
 
```yaml
volumes:
  maildir:

  mailserver:
    image: mailhog/mailhog
    ports:
      - 8025
      - 1025
    profiles:
      - development
      - staging
    environment:
      MH_STORAGE: maildir
      MH_MAILDIR_PATH: /tmp
    volumes:
      - maildir:/tmp
```

テスト用メールサーバの動作に必要な環境変数はない。

## コンテナイメージ

 * 公式: https://hub.docker.com/r/mailhog/mailhog を利用

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

## メール送信データの永続化
Dockerが管理しているデータ領域に保存されており、デフォルトでは何も設定しなくとも、データは永続化されている。

```yaml
volumes:
  maildir: {}
```

データを初期化する場合は、以下の方法を用いて初期化を行うこと。

1. コンテナを停止する
   ```
   docker compose down mailserver
   ```
2. 削除するボリュームを確認する
   ```
   docker volume ls
   DRIVER    VOLUME NAME
   local     maildir
   ```
3. ボリュームを削除する
   ```
   docker volume rm maildir
   ```
4. コンテナを起動する
   ```
   docker compose up mailserver -d
   ```

※コンテナは起動中はデータの削除はできないため、必ずコンテナを停止してから作業を行うこと!
