
# アーキテクチャ図補足資料
下記図は全体構成を一枚にまとめたものである。

![](/docs/images/containers.png)

情報量が多いため、章ごとに分解しながら説明する。

## 使用ミドルウェア一覧
開発環境では、主に以下のミドルウェアを使用する。(`compose.yaml`内の表記と合わせています)

|    | Compose側の名前 | 使用ミドルウェア     | 資料上の名前       | 用途 |
|:-- |:--                         |:--               |:--                |:-- |
| [★](/infra/nginx/README.md)    | `web-dev-server` | `Nginx`           | Nginx | Webサーバ。各ミドルウェア、Appコンテナのサービスへのリバースプロキシとして使用する。 |
| [★](/infra/mailhog/README.md)  | `mailserver`     | `MailHog`         | Mail  | テスト用のメールサーバ。 |
| [★](/infra/postgres/README.md) | `database`       | `PostgreSQL`      | DB   | RDBMS。ユーザが入力したデータ等を保存する役割を持つ。 |
| [★](/infra/openldap/README.md) | `openldap`       | `OpenLDAP (LDAP)` | LDAP   | ユーザ・グループ情報(ID/Password)を管理する。 Dexと連携する。 |
| [★](/infra/dex/README.md)      | `auth`           | `Dex (Auth)`      | Auth   | 認証・認可サーバ。LDAPと連携し、認証周りを担当する。 |
| [★](/infra/redis/README.md)    | `session`        | `Redis`           | Redis   | セッション情報(アクセストークンやログイン状態など)の保存先として使用する。 |

※各ミドルウェアの **「セットアップ手順」** は「★」マークをクリックして参照すること。

### ミドルウェアのコンテナイメージ
各ミドルウェアはDockerコンテナとなっており、Docker Hubを起点に、次のようにイメージを取得して環境を構築している。

![](/docs/images/docker-images.png)

### ミドルウェアの起動・停止方法
各ミドルウェアはデフォルト値が設定済みとなっており、Dev Containerからであれば、以下のコマンドですぐに動きを確認できる。

```bash
# 開発環境用のコンテナは以下のコマンドで一括起動できる
docker compose --profile development up -d

# 開発環境コンテナの一括停止
docker compose --profile development down
```

### 注意事項
1. MailHogはテスト用なので、本番環境での使用は避けること!
2. 各ミドルウェアのデフォルト値を変更する場合は、セットアップ手順書に従って設定を行うこと!

## 開発用コンテナ
Dev Containerを利用した開発になっており、開発者は以下の赤枠である、「App Container」内で主に開発することになる。

![](/docs/images/app-container.png)

このコンテナのベースは "golang" 公式イメージを利用しており、Web開発用に改良したものになっている。詳細は以下のDockerfileを参照すること。

 * [Dockerfile](/.devcontainer/setup/Dockerfile)

## ネットワーク
開発用コンテナ・各種ミドルウェアはすべて同一の Docker Network 内に存在している。そのため、次のような構成で各ミドルウェアとの連携が可能になる。

![](/docs/images/docker-network.png)

各コンテナはすべて1つのcompose.yamlで構成されているため、以下のように同じネットワーク内での通信が可能になる。

![](/docs/images/compose-network.png)

## 動作確認方法
Webアプリの動作確認は、Nginxのリバースプロキシを利用した動作確認方法となる。`publish`しているポートヘアクセスすることで、許可しているサービスヘアクセスできる。 (図下のChromeアイコンに注目)

![](/docs/images/browser-access.png)

Nginxは8080ポートをpublishしており、メール(mailhog)や認証(dex)、開発用コンテナ(app)などのルーティングを担当している。動作確認する際には、次のようにクエリパスを使用して、各サービスへホスト側から接続できる。

| Access URL                  | Container  | Usage |
|:--                          |:--         |:--          |
| http://localhost:8080/      | app        | アプリケーション本体の動作確認 | 
| http://localhost:8080/mail/ | mailserver | テスト用メールサーバの受信履歴 |
| http://localhost:8080/dex/  | dex        | 認証・認可サーバ  |
| http://localhost:8080/ldap/ | openldap   | LDAPクライアント(動作確認用で、開発環境でのみ動作する. 図には未記載) |


## 各種ボリュームの構成
基本的に、データは永続化されない設定になっている。もし、データを永続化する場合は、 `compose.yaml` 内に永続化設定を記載し、ホスト側のデータをコンテナ側へマウントすることでデータの永続化ができる。

### データ永続化イメージ

![](/docs/images/docker-volumes.png)

#### 各フォルダ・ファイルの色と意味

| アイコン | 説明 |
|:--     |:-- |
| 緑ファイル | 設定ファイルや、スクリプト、 .envなどの環境変数定義ファイルを指す |
| 青フォルダ | 永続化ディレクトリ(DB・Redis,Slapdなど) |
| コマンド   | `docker exec`, `docker log`などを利用したホスト側から操作するアイコンを指す |

## ログファイルの確認
各コンテナのログは以下のコマンドで確認すること。

```bash
# 開発環境の場合は、developmentを指定する
docker compose --profile development logs -f
```

コンテナ単体でのログ情報を確認する場合は、以下のコマンドを実行する。
```
docker compose logs -f <container_name>
```
