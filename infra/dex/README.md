# 認証サーバセットアップ手順
この手順は、**開発・検証用途**で使用する認証・認可サーバの起動方法について説明する。

※本手順は Dex を用いた環境構築に限定される。本番環境などで Keycloak や OpenAM、 Hydra など、別のソフトウェアを使用する場合は、それぞれに応じた認証基盤の導入が必要になる。


## compose.yamlの内容を確認する
 [`auth`](/compose.yaml)セクションを使用する。以下のように定義されているので、確認すること。
 
```yaml
  auth:
    # コンテナホスト名
    hostname: auth
    # DEX_VERSION環境変数で、バージョンを切り替える
    # デフォルトは、 "v2.42.1"
    image: dexidp/dex:${DEX_VERSION:-v2.42.1}
    # 基本的にポートフォワーディングは行わず、 Nginxからリバースプロキシでアクセスすることを前提としている。
    ports:
      - 5556
    # 設定ファイルやデザイン関連をマウントする。見た目は後から変更することもできる。
    volumes:
      # dex設定ファイル
      - ./infra/dex/config.yaml:/etc/dex/config.yaml
      # Dex のテーマ・スタイル・UI
      - ./infra/dex/setup/static:/srv/dex/web/static
      - ./infra/dex/setup/theme:/srv/dex/web/themes/dex.org
      - ./infra/dex/setup/templates:/srv/dex/web/templates
    command: ["dex", "serve", "/etc/dex/config.yaml"]
```

## DexのUIを変更する
UIの変更は `/infra/dex/setup` ディレクトリ配下の3つのディレクトリ内にあるファイルを修正して行う。

```sh
 setup/
   `--+-- static/     # 入力フォームやヘッダなどのDexの見た目そのものが定義されており、CSS形式で記載する
      +-- templates/  # HTML形式で記載する
      `-- theme/      # CSSに該当するファイルで、Dexのスタイルを記載する
```

### テーマ変更例

#### 構成を変える
ログイン画面を変更するには `templates/password.html` を修正する。

```html
{{ template "header.html" . }}
<div class="theme-panel">
  <!-- ここのHTMLを変更する。 -->
</div>
{{ template "footer.html" . }}
```

#### 背景色変更例
背景色などの色だけを変える場合は、 `theme/styles.css` を修正する。

```css
.theme-body {
  background-color: #efefef; /* 色を変える場合はここを修正する */
  color: #333;
  font-family: 'Source Sans Pro', Helvetica, sans-serif;
}
```

### 注意事項
1. 前提条件として、UIの変更には HTML/CSS の基礎知識が必要である
2. 公式ページにも詳しいカスタマイズ方法は記載されていないため、実際に動作確認しながら、必要に応じてUIや配色などを調整すること

## Dex設定ファイルの全体像
基本的にDexは`config.yaml`に全ての設定を記載することになる。 `config.yaml` は次のような構成になっている。

```yaml
# ベースURL
issuer: http://localhost:5556/dex

# セッションの保存場所
storage:

# ユーザ情報(LDAP/DB)との接続方法
connectors:

# 認証時に必要なクエリパラメータと、それに対応する設定項目
staticClients:
  - id: your-go-app
    redirectURIs:
      - "http://localhost:8080/callback"
    name: "Go Web App"
    secret: your-client-secret
```
設定ファイルを何らかの理由で修正した後は、必ずコンテナの再起動を行う必要がある。

各設定方法に関して、次節から説明する。

## ベースURLの変更
次のように `./infra/dex/config.yaml` ファイルを修正して、コンテナを再起動する。

```yaml
# ベースURL。デフォルトでは "/dex" となっているが、サービスの都合や用途次第で任意のベースURLを設定できる。
issuer: http://localhost:5556/example
```
ベースURL変更後は、Nginxの proxy_pass に指定するパスプレフィックスも合わせること。

```nginx
    # ベースURLが /example の場合は、 dex ⇒ example に変える
    location /example/ {
        rewrite ^/auth(/.*)$ /example$1 break;
        proxy_pass http://auth:5556;
    }
```

## Connectorsの変更
Dexは、LDAPやMock、PostgreSQLなどの多種多様な認証・認可ができる。設定方法に関する詳細は、以下URLを参考に行うこと。

 * https://dexidp.io/docs/connectors/ 

## セッション情報の保存先を変更する
`./infra/dex/config.yaml` の `storage` に保存方法を記述することで、オンメモリだけでなく、PostgreSQLやSQLite3に保存できる。各保存先は、用途によって、適切なものを選択すること。

| ストレージ方式 | 高速性 | 永続性 | スケーラビリティ | 運用の容易性 | 用途 |
|:--           |:--     |:--   |:--            |:--          |:--   |
| `memory`     | ★★★ | ☆☆☆ | ☆☆☆         | ★★★      | 開発・テスト |
| `sqlite3`    | ★☆☆ | ★★☆ | ★☆☆         | ★★☆      | 小規模・検証 |
| `postgres`   | ★★☆ | ★★★ | ★★★         | ☆☆☆      | 本番環境 |

### オンメモリへの保存
セッション情報がメモリ上に保存されるため高速ではあるが、コンテナを停止するとすべてのセッションが削除されるため注意すること。
`config.yaml`を次のように修正する。

```yaml
storage:
  type: memory
```

### sqlite3 の場合
セッション情報がファイル単位で保存されるため、コンテナを停止してもセッション情報が消えることはない。ただし、アクセス数が多いと速度に難があるため、基本的には小規模、またはステージング環境などの検証用途で使用するのが望ましい。

1. config.yamlを次のように修正する
   ```yaml
   storage:
     type: sqlite3
     config:
       file: /srv/dex/web/dex.db
   ```
2. sqlite3コマンドで空DBを作成する
   ```py
   # 空のDBファイルを作成するだけなので、何も渡さない
   sqlite3 dex.db ""
   ```
3. DBに書き込み権限を付与する
   ```py
   # Dexコンテナ側で、DBファイルへの書き込みが行われるため、権限を付与する
   chmod 777 dex.db
   ```
4. compose.yamlを修正して、コンテナにmountする
   ```yaml
   volumes:
     - ./infra/dex/dex.db:/srv/dex/web/dex.db
   ```

### PostgreSQLの場合
セッション情報をデータベースに保存するため、コンテナを停止してもセッション情報が消えることはない。同時アクセス性も優れており、主に本番環境用途では、PostgreSQLに保存することが推奨される。

```yaml
storage:
  type: postgres
  config:
    database: postgres://user:password@database:5432/dex?sslmode=disable
```

## staticClients 設定と認証パラメータ
Dexでは、認証クライアントを `staticClients` セクションで事前に定義する必要がある。

```yaml
staticClients:
  - id: your-go-app              # クライアントID (client_id)
    redirectURIs:                # 認証後のリダイレクト先URL (redirect_uri)
      - "http://localhost:8080/callback"
    name: "Go Web App"           # クライアント名 (表示用)
    secret: your-client-secret   # クライアントシークレット
```

### 認証リクエストのクエリパラメータ例
`staticClients`に設定した値`id`, `redirectURIs`を基に、次のような認証URLが作られることになる。

 * [http://localhost/dex/auth?client_id=...&redirect_uri=http://...&response_type=code&scope=openid+...state=random](http://localhost:8080/dex/auth?client_id=your-go-app&redirect_uri=http://localhost:8080/callback&response_type=code&scope=openid+email&state=random123)

上記URLの各パラメータは、次のような構成となっている。

| パラメータ       | 説明                               | Dex設定との対応 |
|:--              |:--                                |:--
| `client_id`     | 認証対象のアプリを識別するためのID    | id |
| `redirect_uri`  | 認証後に遷移するURL                 | redirectURIs |
| `response_type` | OIDCフローの種類 (通常はcode)       | 固定 |
| `scope`         | 要求する情報の範囲 (後述)           | 定義不要 |
| `state`         | 任意のCSRF対策トークン (後述)        | アプリ側で管理する |

### scope とは
`scope` は、 **認可したい情報の範囲を示す文字列** で、クライアントが「何を要求するか」を明確にする。複数指定する場合は `+` で繋いだURLにする必要がある。各クエリパラメータは次の意味を持つ。

| scope            | 説明 |
|:--               |:--    |
| `openid`         | 必須。OpenID Connectに準拠していることを示す |
| `email`          | ユーザーのメールアドレス情報を要求 |
| `profile`        | 名前、ユーザー名などの基本的な情報を要求 |
| `offline_access` | リフレッシュトークンの取得を要求 |
| `groups`         | グループ情報 (LDAP連携時など) を取得する (Dexで対応時) |

scopeに設定した範囲内から得たデータをclaimと呼んでおり、各パラメータは次のようにマッピングされている。

| scope            | 説明 |
|:--               |:--    |
| `openid`         | `sub` (ユーザID) |
| `email`          | `email`, `email_verified` |
| `profile`        | `name`, `family_name`, `given_name`, `picture`, etc... |
| `offline_access` | リフレッシュトークン |
| `groups`         | グループ情報 (LDAP連携時など) を取得する (Dexで対応時) |

scopeは上記のように、claimのグルーピングになっている。

### LDAP連携時の属性取得
LDAPを使う場合、以下のように `userSearch` でClaimのマッピングを指定する。

```yaml
connectors:
  - type: ldap
    id: ldap
    name: "LDAP"
    config:
      host: ldap.example.com:389
      bindDN: cn=admin,dc=example,dc=com
      bindPW: your_password
      userSearch:
        baseDN: ou=People,dc=example,dc=com
        filter: "(objectClass=person)"
        username: uid
        idAttr: uid           # OIDCのsubに対応
        emailAttr: mail       # OIDCのemailに対応
        nameAttr: cn          # OIDCのnameに対応
        extraAttrs:           # カスタム属性を追加するにはこれ！
          - shadowExpire
```
この設定により、LDAPエントリの中の `shadowExpire` などの追加属性も、認証後のIDトークンの中に `claims` として含まれるようになる。

```json
{
  "sub": "testuser",
  "email": "test@example.com",
  "name": "Test User",
  "shadowExpire": "19500"
}
```
`sub`, `email`, `name` などの claim 名は `OpenID Connect` の仕様で定義されており、それぞれに対応するLDAP属性を `idAttr`, `emailAttr`, `nameAttr` によって指定することで、Dexが自動的にマッピングしてくれる。

| Dex内部項目  | マッピング先のLDAP属性 | OIDCの `claims` での意味 |
|:--          |:--                   |:--                      |
| `idAttr`    | 例: `uid`            | `sub`                   |
| `emailAttr` | 例: `mail`           | `email`                 |
| `nameAttr`  | 例: `cn`             | `name`                  |

#### 注意点
1. `extraAttrs` を指定しないと、標準スコープ以外の属性はトークンに含まれない
2. LDAPにその属性が存在している必要がある (例: shadowExpire. ユーザによって存在したり、しなかったりというパラメータは設定できない)
3. 取得した属性は、主に IDトークン (JWT) 内に格納され、クライアント側でデコードして利用する

### state の意味と取り扱い
`state` パラメータは、認可リクエストとレスポンス間の **整合性を検証するための識別子** であり、主に CSRF 攻撃の防止に使われる。

#### 運用ポイント
 * 認証リクエスト時に、クライアント側 (アプリ) でランダムな文字列を生成して付与する  
   ```
   例: UUIDやランダムな英数字 (20文字～32文字以上が望ましい)
   ```
 * サーバ側で "state" を保存し、認証レスポンスで返ってきた "state" と一致するかを検証する必要がある

#### "state" 保存方法

| 保存先          | 保存方法  | ポイント |
|:--             |:--        |:--     |
| ユーザのブラウザ | HTTP Only Cookie に保存 | JSからアクセスできないようにし、XSS耐性を高める |
| サーバ          | セッションストアに保存     | セッションIDでトラッキングし、整合性を確保する  |

#### 注意点
1. `state`はリクエストごとに毎回新しく生成するのが理想 (セッション固定攻撃防止)
2. 古い `state` は不要になったら破棄 (セッションタイムアウト含む)
3. `state` が一致しない場合は、セキュリティリスクと判断し、**403 Forbidden** などのエラーで処理を中断するのが望ましい
4. ログに詳細を記録しておくことで、CSRF攻撃や不正アクセスのトレースにも役立つ

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

`--profile` を付けない場合は、サービス単位での起動・停止・再起動もできる。

```
docker compose restart auth
```
