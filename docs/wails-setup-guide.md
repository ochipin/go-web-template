# デスクトップアプリの開発

基本的には、以下のWails公式のページを参照すること。

 * https://wails.io

## プロジェクトの作成
React TS開発環境は以下のコマンドを実行する。

```
wails init -n <prjname> -d <dirname> -g -t react-ts -ide vscode -q 
```
各コマンドに渡すオプションの詳細に関して知りたい場合は、以下のページを参照すること。

 * https://wails.io/docs/reference/cli

## プロジェクトのビルド

```
wails build -tags webkit2_41
```

### `-tags`に`webkit2_41`を渡している理由
コンテナ内では`libwebkit2gtk-4.0-dev`が存在しないため、`libwebkit2gtk-4.1-dev`を採用している。Wailsはデフォルトでは4.0を使用するため、4.1を使うように指示している。

## ロードモジュールを実行

```
./build/bin/sampleapp
```

コンテナ内でロードモジュールを実行することで、GUIアプリが立ち上がる。
