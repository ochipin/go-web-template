#!/bin/bash

# 実行環境が増えて来たら、case $ENV in を使用して、条件を追加する
ENV=${ENV:-develop}

# docker pull golang で取得するイメージのバージョン (https://hub.docker.com/_/golang)
# Go言語のバージョン番号を変えたい場合は、下記環境変数に設定している番号を変更する
#   ex) GO_VERSION=1.20
GO_VERSION=${GO_VERSION:-1.24}
# インストールするNodeのバージョン. バージョン番号を変えたい場合は、下記環境変数に設定している番号を変更する
#   ex) NODE_VERSION=22
NODE_VERSION=${NODE_VERSION:-22}

# .gitconfigのパス
GIT_CONFIG_PATH=

# =============================================================================
#   各種関数を実装
# =============================================================================
# .gitconfigが存在するか確認する
function has_gitconfig() {
    if [[ -f $GIT_CONFIG ]]; then
        GIT_CONFIG_PATH=$GIT_CONFIG
    elif [[ -f ${HOME}/.gitconfig ]]; then
        GIT_CONFIG_PATH=${HOME}/.gitconfig
    fi

    if [[ -z "$GIT_CONFIG_PATH" ]]; then
        cat <<-EOF 1>&2
			=============================================================================

			  $HOME/.gitconfig is not found.

			=============================================================================
		EOF
        return 1
    fi
}

# .envがない場合は生成する
function create_docker_env() {
    local timezone=`get_timezone`

    cat <<-EOF > .env
		# このファイルはDevContainer実行時に自動的に作成される
		# 初回起動時のみ作成されるため、作成し直したい場合はこのファイルを削除すること

		# プロキシ設定
		# http_proxy=
		# https_proxy=
		no_proxy=localhost,127.0.0.1

		# compose.yamlからUID,GIDを参照するため、.envファイルにUID・GIDを環境変数としてセットする
		UID=$(id -u)
		GID=$(id -g)

		# Go言語, Nodeのバージョン
		GO_VERSION=${GO_VERSION}
		NODE_VERSION=${NODE_VERSION}

		# コンテナ内のタイムゾーン
		TZ=${timezone}
		# コンテナ内の言語設定
		LANG=en_US.UTF-8
		# ステージビルド
		STAGE_BUILD=${ENV}

		# プロジェクト名
		PROJECT_NAME=app
		# 起動モード
		RUN_APP=develop

		# シスログ設定
		# ---------------------------------------------------------------------
		# コンテナ内のログ情報をsyslogへ出力する場合は、下記のコメントを外す
		# この設定は、ステージング環境のみで有効となる。
		# LOGGING_DRIVER="syslog"
		# LOGGING_ADDRESS="tcp://localhost:514"

		# Nginx設定
		# ---------------------------------------------------------------------
		# Nginxのバージョン
		NGINX_VERSION=1.27

		# LDAP設定
		# ---------------------------------------------------------------------
		# LDAPのバージョン
		OPENLDAP_VERSION=2.6.8-r0
		# ルートDN
		LDAP_ROOT_DN="cn=Manager,dc=example,dc=com"
		# 管理者パスワードを設定する
		LDAP_ROOT_PASSWORD=secret
		# ルートサフィックス
		LDAP_ROOT_SUFFIX="dc=example,dc=com"
		# サーバID
		LDAP_SERVER_ID=1
		# バインドDN
		LDAP_BIND_DN="cn=Manager,dc=example,dc=com"
		# バインドDNのパスワード
		LDAP_BIND_PASSWORD=secret
		# ベースDN
		LDAP_BASE_DN="dc=example,dc=com"

		# PostgreSQL接続設定
		# ---------------------------------------------------------------------
		# DBホスト名。コンテナのホスト名となる。
		PGHOST=database
		# ポート番号。 5432 のままでよい。
		PGPORT=5432
		# DB名。
		PGDATABASE=mydb
		# DBユーザ・パスワードを指定する。
		PGUSER=postgres
		PGPASSWORD=secret
		# 使用するPostgreSQLのバージョン番号を記載する。
		PGVERSION=latest
		# PGSSLMODE=verify-full
		# PGSSLCERT=/certs/client.crt
		# PGSSLKEY=/certs/client.key
		# PGSSLROOTCERT=/certs/ca.crt

		# Dexの設定
		# ---------------------------------------------------------------------
		DEX_VERSION=v2.42.1
	EOF
}

# 既に.envが存在している場合、UIG,GIDを更新する
function update_docker_env() {
    grep -q "^UID=" .env && sed -i "s/^UID=.*/UID=$(id -u)/" .env || echo "UID=$(id -u)" >> .env
    grep -q "^GID=" .env && sed -i "s/^GID=.*/GID=$(id -g)/" .env || echo "GID=$(id -g)" >> .env
}

# タイムゾーンを取得する
function get_timezone() {
    local tz=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')
    if [[ -z "$tz" ]]; then
        echo "Warning: Failed to get timezone, defaulting to 'UTC'" 1>&2
        tz="UTC"
    fi
    echo $tz
}

# コンテナにマウントする際に必要になるディレクトリ群を作成する
function create_mount_dirs() {
    mkdir -p .cache/vscode .cache/gocache .cache/cursor .vscode
}

# go.mod, go.sumなどのバックエンドのモジュール管理に使用するファイルを生成する
function create_go_mod() {
    if [[ ! -f go.mod ]]; then
        echo 'module app' > go.mod
    fi

    if [[ ! -f go.sum ]]; then
        touch go.sum
    fi
}

# override.yaml を生成する
function create_override_yaml() {
    if [[ -f .devcontainer/override.yaml ]]; then
        return 0
    fi
	local working_dir=$(pwd)
    cat <<-EOF > .devcontainer/override.yaml
		services:
		  app:
		    env_file:
		      - .env
		    ports:
		      - 3000:3000
		      - 5173:5173
		    extra_hosts:
		      - "localhost:host-gateway"
		      - "host.docker.internal:host-gateway"
		    command: dumb-init -- sleep infinity
		    volumes:
		      # !!! DO NOT MODIFY THIS COMMENT !!!
		      - .:${working_dir}
		      - .:/go/src/app
		      # 各種キャッシュデータ
		      - ./.cache/gocache:/home/container/.cache
		      - ./.cache/vscode:/home/container/.vscode-server
		      - ./.cache/cursor:/home/container/.cursor-server
		      # Docker out side of Dockerを使用する場合は、ホスト側のdocker.sockをmountすること
		      - /var/run/docker.sock:/var/run/docker.sock
		      # 各種設定ファイル
		      - ./.devcontainer/container.bashrc:/home/container/.bash_aliases
		      - ${GIT_CONFIG_PATH}:/home/container/.gitconfig
	EOF
}

# bashrc, vscodeの設定などのファイルを生成する
function copy_template_for_env() {
    if [[ ! -f .devcontainer/container.bashrc ]]; then
        cp -f .devcontainer/setup/1.bashrc-template.sh .devcontainer/container.bashrc
    fi

    if [[ ! -f .vscode/settings.json ]]; then
        cp -f .devcontainer/setup/2.settings-template.jsonc .vscode/settings.json
    fi

    if [[ ! -f .vscode/markdown-preview.css ]]; then
        cat <<-EOF > .vscode/markdown-preview.css
			table {
			  display: block;
			  overflow-x: auto;
			  white-space: nowrap;
			}
		EOF
    fi
}

# Dockerイメージをpullする
function pull_docker_images() {
    docker pull golang:$GO_VERSION &
    local pid_golang=$!

    docker pull node:$NODE_VERSION &
    local pid_node=$!

    # 各プロセスの終了を待ち、終了ステータスを確認する
    wait $pid_golang
    if [[ $? -ne 0 ]]; then
        echo "Failed to pull golang:$GO_VERSION"
        exit 1
    fi

    wait $pid_node
    if [[ $? -ne 0 ]]; then
        echo "Failed to pull node:$NODE_VERSION"
        exit 1
    fi
}

# カレントディレクトリパスが正しくmountされているか確認する
check_working_dir() {
	local working_dir=$(pwd)
    if [[ ! -f .devcontainer/override.yaml ]]; then
		echo "Failed: not found .devcontainer/override.yaml"
		exit 1
    fi
    if [[ ! -f .devcontainer/devcontainer.json ]]; then
		echo "Failed: not found .devcontainer/devcontainer.json"
		exit 1
    fi

	cat .devcontainer/override.yaml | grep "${working_dir}" >/dev/null
	if [[ $? -ne 0 ]]; then
		echo "Failed: current dir .devcontainer/override.yaml" >&2
		echo ${working_dir}
		exit 1
	fi
	cat .devcontainer/devcontainer.json | grep "${working_dir}" >/dev/null
	if [[ $? -ne 0 ]]; then
		echo "Failed: current dir .devcontainer/devcontainer.json" >&2
		exit 1
	fi
}


# =============================================================================
#   処理の順番に応じて関数を呼び出す
# =============================================================================
main() {
    # .gitconfigの確認
    has_gitconfig || exit 1

    # .envファイルを生成
    if [[ ! -f .env ]]; then
        create_docker_env
    else
        update_docker_env
    fi

    # コンテナに必要なディレクトリや設定ファイル等を生成する
    create_mount_dirs || { echo "Failed to create directories"; exit 1; }
    create_go_mod || { echo "Failed to create Go module"; exit 1; }
    create_override_yaml || { echo "Failed to create override files"; exit 1; }
    copy_template_for_env || { echo "Failed to copy template files"; exit 1; }

    # Dockerイメージをpullする
    pull_docker_images

    # カレントディレクトリパスが正しくmountされているか確認する
    check_working_dir
}

if [[ "$1" != "create-env" ]]; then
    main
else
    # .envファイルを生成
    if [[ ! -f .env ]]; then
        create_docker_env
    else
        update_docker_env
    fi
fi
