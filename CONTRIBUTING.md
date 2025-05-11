# Contributing to [プロジェクト名]
プロジェクトの品質維持とスムーズなコミュニケーションを取るために、ルールやガイドラインを説明する。

## イシュー起票手順

### 不具合報告
イシュータイトルは簡潔に、内容は詳細に記載すること。可能であれば、再現手順や環境情報を含めて記載すること。

- [不具合報告イシューテンプレート](/.github/ISSUE_TEMPLATE/bug_report.md)

### 機能追加・変更要望
なぜその機能が必要か、具体的なユースケースを記載し、可能であれば、実装方法の提案含めて記載すること。

- [機能追加・変更要望イシューテンプレート](/.github/ISSUE_TEMPLATE/feature_report.md)

### ラベルの付与
適切なラベルを選択してイシューに付与すること。

- [ラベル運用方法](docs/github-label-description.md)

## プルリクエスト作成手順

1. リポジトリのクローン
   ```
   $ git clone https://localhost/forgejo/<name>/<prjname>
   ```
2. ブランチの作成
   ```
   $ git checkout -b ブランチ名
   ```
3. 変更のコミット
   ```
   $ git add . && git commit -m 'コミットメッセージ'
   ```
4. リモートブランチへのプッシュ
   ```
   $ git push origin ブランチ名
   # 初回のみ、 git push -u origin ブランチ名 とすること
   ```
5. プルリクエストの作成
   * プルリクエストを作成し、変更内容と目的を明確に記載すること
   * 関連するイシューがあれば、プルリクエストにリンクすること

プルリクエストに記載する内容は、[プルリクエストテンプレート](.github/PULL_REQUEST_TEMPLATE.md)を参照すること。

## コードスタイル

### Go言語のコーディングガイドライン
* 静的解析: `golangci-lint` を使うこと
* 命名規則: 関数名・変数名はキャメルケースを使用すること

### Reactコーディングガイドライン
* 品質管理: ESLint・Prettierを使用すること
* 型定義: TypeScriptの型定義を使用すること
* コンポーネント: Reactの関数コンポーネントを再利用可能な形で作成すること
* 命名規則: 関数名・変数名はスネークケースを使用すること

## テスト

### バックエンド(Go)
* testing パッケージを使用すること
* 実行方法:  
  ```
  $ go test ./...
  ```

### フロントエンド(Node)
* Jest, React Testing Libraryを使用すること
* 実行方法:
  ```
  $ yarn test
  ```

## 依存関係の管理

### バックエンド
```
$ go mod tidy
```

### フロントエンド
```
$ cd frontend
$ yarn
```

## ブランチ戦略

### Gitワークフロー
GitHub Flowに則り作業をすること。

- mainブランチ: 安定版のコード
- その他ブランチ: 新機能開発用やバグ修正用ブランチ

### ブランチの保護
- mainブランチを保護し、直接mainブランチに対して`git push`出来ないようにすること
- 承認フローを設け、必ず1人以上の承認を受けること

### ブランチの運用ルール

1. 1タスク・1機能ごとにブランチを切ること
2. 機能が大きくなる場合はブランチを分割すること

目安としては、1週間単位で何かしらの実装が目に見える形で報告できるようにブランチを切ることが望ましい。

#### ブランチ分割例
例えば、 **「○○システムにユーザを登録する機能を実装する」** というタスクが発生した場合、以下のような作業が発生すると考えられる。

* **UIの実装**
* **DB登録処理**
* **メール送信処理**

この作業毎にブランチを分割することにより、以下の恩恵を受けることができる。

1. 複数人で作業を進める必要がある場合、適切に作業を分割し、同時並行でタスクを進めることができる
2. 小さい単位でのコードレビューになるため、レビュー時の負担が軽くなる
3. タスク毎に目的が明確になるため、「何をやるのか分からない」という状態をチームで発生させにくくなり、各人が自発的に行動できるようになる
4. 各作業の見通しが良くなるため、見積もりが取りやすい

上記の利点をしっかり理解し、ブランチはなるべく細かく分割することを強く推奨する。

### ブランチの命名規則
ブランチ名から目的が分かるように、次の形式で命名することを推奨する。

* [プレフィックス]/[任意の名前]  
  例: `feature/add-function-name`

基本的には、ブランチ名は規則性があるものがほとんどなので、以下の用語を応用して命名すること。

| 意味 | 使用する名前 |
|:-- |:-- |
| 綺麗にする         | cleanup, clear |
| 機能追加する        | add |
| 更新・変更する       | update, change |
| 改善する、最適化する | improve, optimize |
| 不具合などの修正をする | fix, correct, patch |

- ハイフンやスラッシュを使い読みやすい名前をつけること
- 簡潔かつ一貫性を持たせて、意味が分かる名前をつけること

#### ブランチ名の例

* 機能開発
  - feature/add-search-function
  - feature/change-user-authentication
  - feature/update-dashboard-ui
* 不具合修正
  - bugfix/fix-login-error
  - bugfix/correct-status-ui
* 緊急対応
  - hotfix/patch-critical-security
  - hotfix/fix-request-error
* リファクタリング
  - refactor/cleanup-login-frontend
  - refactor/update-api-endpoints
  - refactor/improve-query-speed
* リリース
  - release/v1.0.0
  - release/20241224
* その他
  - chore/update-readme
  - chore/clear-cache
  - chore/optimize-build

## コミットメッセージ規約

### コミットメッセージのフォーマットとテンプレート
コミットメッセージは、タイトルとイシュー番号、本文の2構成で記載することが望ましい。

```
fix: SQLを最適化し、XXページの表示時間を短縮 (#1024)

- 無駄なクエリ文を削除
- タイムアウトする場合の文言を修正
```

* 1段落目はタイトルとイシュー番号  
  Forgejo上で表示される行になるので、分かりやすい明確なタイトルを記載すること。
  - fix: 不具合修正時に使用する
  - add: 新機能やファイルを追加した際に使用する
  - update: バージョンアップ、仕様変更、バグ以外の機能変更などの際に使用する
  - remove: ファイルを削除した際に使用する
  - clean: リファクタリングやキャッシュ削除などの整理時に使用する
* 2段落目は本文  
  タイトルだけでは表現できない詳細なメッセージを、箇条書きを踏まえて分かりやすく記載すること。

### 意味のあるコミットメッセージを書くためのガイドライン
コミット時のメッセージは、なるべく機能毎に分けて適切なコミットメッセージを記載すること。

* 例: 「○○画面表示時にボタンを分かりやすくするために、ボタンのサイズを調整」

また、ブランチ毎に適切な文言を使うこと。例えば、"feature"ブランチは新機能追加用なので、コミット時に"修正"などの文言は使わないこと。以下に例を示す。

* O: 「A画面とDBが連動するように○○機能を追加」
* X: 「○○機能を追加し、A画面とDBが連動するように修正」

## ログ・デバッグガイドライン

### バックエンド
* ログレベルをデプロイ先に応じて適切に設定すること(DEBUG,INFO,WARN,ERROR)
* 重要な操作やログ情報は必ず記録すること
* パスワードなどの機密情報はログに書き出さないように注意すること

### フロントエンド
* 開発環境のみ、コンソールに詳細なログを出力すること
* エラートラッキングツールを使用して、本番環境でのエラーをモニタリングすること
  - Sentry, LogRocket, Rollbar, Bugsnag, Raygun など、様々ツールが存在するので、運用に合わせて導入を検討すること

## エラーハンドリング

### バックエンド
* 一貫性: エラーレスポンスを統一すること(ex: `{error: "message..."}`)
* ステータスコード: 適切はHTTPステータスコードを返却すること

### フロントエンド
* ユーザへの通知: エラーが発生した際に、適切なメッセージを表示すること
* エラーバウンダリ: 予期せぬエラーをキャッチすること

## コードレビュー

1. プルリクエスト作成後、作業途中でもいいので細かくレビュー依頼を出すよう心がけること
2. プルリクエストは少なくとも1名のレビュワーによる承認が必要

詳細なコードレビューのプロセスガイドラインは[レビュープロセスガイドライン](docs/review-process-guidelines.md)を参照すること。

## ファイル構成
ソースコードは、次のディレクトリ構成で管理する。

```ini
PROJECT_NAME/
  `--+-- cmd/ # アプリケーションのエントリーポイントを格納
     +-- internal/
     |     `--+-- config/        # 設定や環境変数の管理
     |        +-- controllers/   # HTTPリクエストを処理するコントローラー
     |        +-- routes/        # ルーティングテーブルを管理する
     |        +-- middlewares/   # FWを仲介して共通の処理を行う必要があるロジックを管理する
     |        +-- models/        # データ構造やエンティティの定義
     |        +-- repositories/  # interfaceで定義されたDBアクセスの抽象化
     |        +-- services/      # ビジネスロジックを実装するサービス層
     |        +-- validators/    # バリデーションロジックを格納
     |        `-- utils/         # 汎用的なユーティリティ関数やヘルパ
     +-- templates/ # テンプレートや静的ファイルを格納
     :
     +-- go.mod
     `-- go.sum
```

## ディレクトリ補足説明

### cmdディレクトリ
エントリポイントだけでなく、追加のCLIコマンドツールなど、異なるCLIを同じプロジェクト内で管理する。

```ini
cmd/
  `--+-- app/      # エントリポイント
     +-- migrate/  # DBマイグレーション
     `-- worker/   # バッチ処理やキューにあるジョブを処理する
```

### configディレクトリ
アプリケーション全体の設定、初期化処理を管理する。環境毎の設定やサーバの初期化、ミドルウェアの登録など、アプリケーションを動作させるために必要な構成や実装を心掛けること。

1. 環境毎の設定(develop.yaml/product.yaml)をロードし、アプリケーション内で利用する
2. DB接続設定、APIキーの管理など、外部リソースとの接続情報を管理する
3. ミドルウェアの登録や、サーバの構成や基本的な設定を行う

### routesディレクトリ
プロジェクトの成長と共に、ルーティングテーブルが複雑にならないように`routes`に中間層を追加して管理するように心がけること。

**例**
```go
func SetupRoutes(router *gin.Engine) {
    setupUserRoutes(router)
    setupOrderRoutes(router)
}

:

func setupUserRoutes(router *gin.Engine) {
    userGroup := router.Group("/user")
    {
        userGroup.GET("/", controllers.GetUsers)
        userGroup.POST("/", controllers.CreateUser)
        userGroup.GET("/:id", controllers.GetUserById)
    }
}

:

func setupOrderRoutes(router *gin.Engine) {
    orderGroup := router.Group("/order")
    {
        orderGroup.GET("/", controllers.GetOrders)
        orderGroup.POST("/", controllers.CreateOrder)
        orderGroup.GET("/:id", controllers.GetOrderById)
    }
}
```

### middlewaresディレクトリ
主に、ログの出力処理やリクエストメソッドの書き換え、認証・認可など、 **リクエストの前後に何かしらの共通処理を挟むための「仲介処理」** を管理すること。

### servicesディレクトリ
ビジネスロジックが大きくなる場合は、サービス毎にファイルを細分化して管理すること。

### repositoriesディレクトリ
ビジネスロジックとデータアクセス層の分離を目的としたディレクトリのため、CRUD操作に重点を置き、各ドメイン毎に適切にディレクトリを分けるように心がけること。

```
repositories/
  `--+-- users/
     |     +-- user_repository.go
     |     `-- user_profile_repository.go
     +-- orders/
     |     +-- order_repository.go
     |     `-- order_detail_repository.go
     +-- products/
     |     +-- product_repository.go
     |     `-- product_detail_repository.go
     `-- categories/
           `-- category_repository.go 
```
あくまで、repositoriesは「データアクセス層」なので、必ずinterfaceを使用して抽象化を心がけること。

#### ビジネスロジック・データアクセスを分離した例

**repositories**
```go
type UserRepository interface {
    FindByID(id int) (*models.User, error)
    Create(user *models.User) error
}

// DBアクセスの実体
type UserRepositoryDB struct {
    db *sql.DB
}

func (u *UserRepositoryDB) FindByID(id int) (*models.User, error) {
    ...
}

func (u *UserRepositoryDB) Create(user *models.User) error {
    ...
}

func NewUserRepository(db *sql.DB) *UserRepositoryDB {
    return &UserRepositoryDB{db:db}
}
```

**services**
```go
type UserService struct {
    userRepo repositories.UserRepository
}

func NewUserService(repo repositories.UserRepository) *UserService {
    return &UserService{userRepo: repo}
}

func (s *UserService) GetUserByID(id int) (*models.User, error) {
    return s.userRepo.FindByID(id)
}

func (s *UserService) CreateUser(user *models.User) error {
    return s.userRepo.Create(user)
}
```
**使用例**
```go
func main() {
    db, _ := sql.Open("mysql", "user:password@/dbname")
    // repositries初期化
    userRepo := repositories.NewUserRepository(db)
    // servicesを初期化
    userService := services.NewUserService(userRepo)
    fmt.Println(userService.GetUserByID(1))
}
```
