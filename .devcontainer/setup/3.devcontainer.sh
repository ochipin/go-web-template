#!/bin/bash

#
# このスクリプトは直接動かすのではなく、必ず以下の手順で実行すること!
#   * 「タスクの実行」 -> 「devcontainer.jsonを作成する」
#

target_file=.devcontainer/devcontainer.json

working_dir=$(pwd)
add_line="    \"workspaceFolder\": \"${working_dir}\","

create_devcontainer_json() {
cat <<-EOF > ${target_file}
{
    // !!! DO NOT MODIFY THIS COMMENT !!!
    "workspaceFolder": "${working_dir}",
    // DevContainer実行時に環境変数やマウントポイントを作成する
    "initializeCommand": "bash .devcontainer/setup/0.initialize.bash",
    // compose.yamlを実行する. 配列形式になっているので、複数指定可能.
    //   ex) docker compose -f ../compose.yaml
    "dockerComposeFile": ["../compose.yaml", "override.yaml"],
    // 起動サービス
    "service": "app",
    "runServices": ["app"],
    // コンテナユーザ
    "remoteUser": "container",
    // コンテナ起動後に実行される
    "postAttachCommand": "go mod tidy -e",
    // コンテナ作成時に必要なプラグインをインストールする
    "customizations": {
        "vscode": {
            "extensions": [
                // Go: Go言語拡張機能
                "golang.go",
                // Go Template: GoのTemplate補完プラグイン
                "jinliming2.vscode-go-template",
                // LDIFファイル
                "jtavin.ldif",
                // EchoAPI: GUI形式のREST API確認用ツール
                "echoapi.echoapi-for-vscode",
                // REST API: ファイル形式のREST API確認用ツール
                "humao.rest-client",
                // Todo Tree: ToDo 管理用プラグイン
                "gruntfuggly.todo-tree",
                // ESLint: JSLintingツール
                "dbaeumer.vscode-eslint",
                // Git Lens: Gitプラグイン
                "eamodio.gitlens",
                // Draw.io: お絵描きソフト
                "hediet.vscode-drawio",
                // GitHub Theme: エディタの配色テーマ
                "github.github-vscode-theme",
                // PostgreSQL: データベース管理プラグイン
                "ckolkman.vscode-postgres",
                // Even Better TOML: TOML設定ファイルプラグイン
                "tamasfe.even-better-toml",
                // Rust Analyzer
                "rust-lang.rust-analyzer",
                // CodeLLDB
                "vadimcn.vscode-lldb"
            ]
        }
    }
}
EOF
}


modify_devcontainer() {
    if [[ -f ${target_file} ]]; then
        # .devcontainer.jsonが存在していた場合、workspaceFolderのみを再生成する。
        local lines=()
        local found=0

        while IFS= read -r line; do
            # 既存のworkspaceFolderは削除するので、スキップする
            if [[ "${line}" =~ \"workspaceFolder\"\ *: ]]; then
                continue
            fi

            lines+=("${line}")
            if [[ ${found} -eq 0 && "$line" == *"DO NOT MODIFY THIS COMMENT"* ]]; then
                lines+=("${add_line}")
                found=1
            fi
        done < "${target_file}"
        # devcontainer.jsonを出力する
        printf "%s\n" "${lines[@]}" > $target_file

        # "DO NOT MODIFY THIS COMMENT" が存在しない場合、既存のJSONファイルをバックアップして新しいdevcontainer.jsonを作成する
        if [[ ${found} -eq 0 ]]; then
            mv -f ${target_file} .devcontainer/devcontainer.bak.json
            create_devcontainer_json
        fi
    else
        # .devcontainer.jsonを作成する
        create_devcontainer_json
    fi
}

modify_yaml() {
    local override_yaml=.devcontainer/override.yaml

    if [[ -f ${override_yaml} ]]; then
        # override.yamlが存在していた場合、mount先を更新する
        local lines=()
        local found=0

        while IFS= read -r line; do
            # DO NOT MODIFY ... コメントのすぐ下の行を無視する
            if [[ ${found} = 1 ]]; then
                found=0
                continue
            fi

            lines+=("${line}")
            if [[ ${found} -eq 0 && "$line" == *"DO NOT MODIFY THIS COMMENT"* ]]; then
                lines+=("      - .:${working_dir}")
                found=1
            fi
        done < "${override_yaml}"
        # devcontainer.jsonを出力する
        printf "%s\n" "${lines[@]}" > ${override_yaml}
    fi
}

# 各々パスを更新する
modify_devcontainer
modify_yaml
