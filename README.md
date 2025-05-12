> **※このリポジトリは新規Webアプリ開発用のテンプレートです。** 使用時は本READMEを参考に、プロジェクトに合わせて各セクションを編集してください。

# <プロジェクト名を記載すること>

## 目的・背景
<!-- なぜこのプロジェクトが存在するのか、その主要な目的は何かを簡潔に説明する。 -->
<!-- 記載例:
○○アプリは、シンプルで直感的なタスク管理アプリケーションである。
このアプリを使うことで、ユーザはタスクを作成し、進捗状況をリアルタイムで追跡することができる。
タスクの優先順位付け、締め切りの設定、そしてチームメンバーとの共有機能を備え、効率的なプロジェクト管理をサポートする。-->

## 機能説明
<!-- 主要な機能や特徴を列挙する。 -->
<!-- 記載例:
主な機能は、
  1. タスクの一覧表示機能
  2. 完了済みタスクのアーカイブ機能
  3. チームごとのタスク共有機能
ビジネスや個人のプロジェクトを問わず、タスク管理の効率化を目指しているツールである。 -->

## リポジトリのクローン
<!-- リポジトリのクローン先. プロジェクトに応じて適宜書き換えること! -->
```
git clone https://github.com/ochipin/go-web-template.git
```

## 使用言語・ライブラリ

### 言語・ライブラリ

| Command       | Language   | Framework | Linter        |
|:--            |:--         |:--        |:--            |
| `go`          | GoLang     | Gin       | golangci-lint |
| `node`,`yarn` | TypeScript | React     | ESLint        |

### ミドルウェア

| Application | Type       | Usage |
|:--          |:--         |:--    |
| PostgreSQL  | RDBMS      | ユーザが入力したデータを保存する |
| OpenLDAP    | LDAP       | ユーザ情報(ID/Password)を管理する |
| Dex         | Auth       | 認証・認可サーバ. LDAPと連携する |
| Nginx       | WebServer  | DexやGoのWebアプリのリバースプロキシとして使用する |
| Redis       | Session    | セッション情報(アクセストークンやログイン状態など)の保存先として使用する |
| MailHog     | MailServer | テスト用のメールサーバとして使用する |

※MailHogは完全テスト用なので、本番環境での使用は避けること!

## 環境構築

### 開発環境セットアップ手順
1. [開発環境・ステージング環境用の証明書の発行](/infra/openssl/README.md)  
   未発行の場合は必ず発行すること。
2. [開発環境構築手順](/docs/setup-dev-environment.md)  
   開発環境が未構築の場合は、上記手順を参照し開発環境を構築すること。

※ホスト側から作業を行うのではなく、必ずDev Containerのコンテナ上で作業を行うこと。

#### 各種ミドルウェアのセットアップ方法
開発環境用のミドルウェアのセットアップは、デフォルト値が設定済みである。Dev Containerからであれば、以下のコマンドですぐに動きを確認できる。

```bash
# 開発環境用のコンテナ群は以下のコマンドで起動する
docker compose --profile development up -d
```

ただし、LDAPのDNを変更する、PostgreSQLのセキュア設定をする、など細かい設定を実施する場合は、下記のミドルウェア構築手順書を参考に設定を変更すること。

1. [PostgreSQLセットアップ手順](/infra/postgres/README.md)
2. [OpenLDAPセットアップ手順](/infra/openldap/README.md)
3. [Webサーバセットアップ手順](/infra/nginx/README.md)
4. [認証・認可サーバセットアップ手順](/infra/dex/README.md)
5. [セッション管理サーバセットアップ手順](/infra/redis/README.md)
6. [テスト用メールサーバのセットアップ手順](/infra/mailhog/README.md)

※ステージング環境や本番環境など、用途毎に設定が必要な場合はcompose.yamlを改修し使用すること。

<!-- デプロイ先の環境が増えてきたら、下記に追加していく
### [ステージング環境構築手順](docs/setup-staging-environment.md)
### [本番環境構築手順](docs/setup-prod-environment.md) -->

## 動作確認方法
実装中の動作確認等は、以下の方法で行うこと。

 1. [開発環境内での動作確認方法](/docs/dev-verification.md)

### デスクトップアプリの開発
デスクトップアプリを開発する場合は、Wailsを利用することで実現できる。

* [デスクトップアプリの開発](/docs/wails-setup-guide.md)

## プロジェクト参加方法
* 本プロジェクトは GitHub Flow に基づき、PRベースで開発を進める。
* コード規約・ブランチ運用ルールなどを記載しているため、詳細は[CONTRIBUTING.md](CONTRIBUTING.md)を参照すること。

## 連絡方法
<!-- Mattermost, Teams, Slack など、連絡手段を記載する -->
