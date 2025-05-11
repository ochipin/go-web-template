# Go + React セットアップガイド

## React + TypeScript環境の構築する

```
$ yarn create vite frontend --template react-ts
$ cd frontend
$ yarn
```

## Reactの開発用サーバを起動する

### 開発用サーバの設定
デフォルトでは`yarn run dev`コマンドで起動するViteサーバは、ローカルホストにのみバインドされており、ローカルホスト外部からアクセスできない。これを解決し、外部アクセスを許可できるようにするため、以下のようにpackage.jsonを修正する。

```json
  ...,
  "scripts": {
    // "dev --host" オプションを追加することで、ホストのすべてのインターフェースにバインドされ、
    // 外部からアクセス可能になる
    "dev": "vite dev --host",
    "build": "tsc -b && vite build",
    "lint": "eslint .",
    "preview": "vite preview"
  },
  ...
```

この修正により、ブラウザからViteサーバへアクセスできるようになる。

### 開発用サーバの起動

```
$ yarn run dev
```
サーバ起動後に、 http://localhost:5173 でViteサーバにアクセスして開発環境を確認できる。

## 本番環境・ステージング環境などで実行する場合

### フロントエンドを埋め込む

`go:generate`コメントを使うことで、**Goのコード生成プロセス中に**、フロントエンドのビルドコマンドを実行できる。下記の例では、"frontend"ディレクトリで`yarn build`を実行し、静的ファイルを生成する、という意味になる。

```go
package main

import (
    "embed"
    "io/fs"
    "log"
    "net/http"
)

//go:generate sh -c "cd frontend; yarn build"
//go:embed frontend/dist/*
var frontend embed.FS

func main() {
    // 埋め込まれたデータをhttp.FileServerに渡せるようFS型にする
    public, err := fs.Sub(frontend, "frontend/dist")
    if err != nil {
        log.Fatal(err)
    }

    // 静的ファイルの配信サーバを起動
    http.Handle("/", http.FileServer(http.FS(public)))
    log.Println("サーバが起動しました: http://localhost:8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```
このコードにより、フロントエンドのファイルがGoバイナリに埋め込まれ、外部サーバやファイルシステムへの依存なしに配信できる。

### Webサーバを起動する
以下のコマンドを使用してフロントエンドをビルドし、Goサーバに埋め込んで起動する。

```sh
$ go generate   # React静的ファイルを生成
$ go run <path> # フロントエンドを埋め込んだ状態でサーバを起動する
```

これにより、ブラウザで http://localhost:8080 にアクセスし、フロントエンドとバックエンドが一緒に動作することを確認できる。
