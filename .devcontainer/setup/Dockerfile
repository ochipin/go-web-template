# syntax=docker/dockerfile:1

# =============================================================================
#   ベースステージ
# =============================================================================

# 1. コンテナイメージ
# -----------------------------------------------------------------------------
# Go環境はオフィシャルのものを使用する.
#   -> https://hub.docker.com/_/golang

# Go言語のデフォルトバージョン. compose.yamlから環境変数を設定することで、バージョン番号を変更できる.
ARG GO_VERSION=1.23
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION} AS base

# 2. Hugoをインストールする
# -----------------------------------------------------------------------------
RUN go install -tags extended github.com/gohugoio/hugo@latest

# 3. コンテナユーザの作成
# -----------------------------------------------------------------------------
# docker build時に渡されたユーザID・グループIDを受け取る(--build-argの値)
ARG USERID
ARG GROUPID
# ユーザ登録用スクリプトを作成する
COPY <<EOF /add_user.sh
# rootの場合は強制的にユーザID・グループIDを1000にして、rootで実行できないようにする
if [[ \$USERID = 0 ]]; then
  USERID=1000
  GROUPID=1000
fi

# "\$GROUPID"で指定したグループが存在するかgrepで確認する
cat /etc/group | grep :\$GROUPID:
RES=\$?
# グループがまだ作られていない場合は追加する
if [[ ! \$RES = 0 ]]; then
  groupadd -g \$GROUPID container
fi

# コンテナ内のユーザ一覧(/etc/shadow)に, "\$USERID"で指定したユーザが存在するかidコマンドで確認する
id -u \$USERID
RES=\$?
if [[ \$RES = 0 ]]; then
  # ユーザIDが既に作成済みの場合はcontainerという名前に変える.
  usermod -l container `id -u \$USERID -n`
else
  # ユーザIDが存在しない場合は、ユーザを追加する
  useradd container --uid \$USERID -g \$GROUPID -m -s /bin/bash
fi
EOF
# "container"というユーザ名でコンテナ内にユーザを追加する
RUN bash /add_user.sh && rm -rf /add_user.sh

# 4. 必須モジュールのインストール
# -----------------------------------------------------------------------------
# root以外のユーザが"go"コマンドを使えるようにパスを通す
RUN ln -s /usr/local/go/bin/go /usr/local/bin/ && ln -s /usr/local/go/bin/gofmt /usr/local/bin/
# インストール時に何らかの入力を求められてもインストールが停止しないようにする
ENV DEBIAN_FRONTEND=noninteractive

# 開発に必要なエディタやDBとの接続ライブラリ、OpenSSL周りのモジュールをインストールする
RUN apt update -y && apt install -y \
    vim \
    libpq-dev \
    libmecab-dev \
    sqlite3 \
    libsqlite3-dev \
    locales \
    fontconfig \
    lsof \
    build-essential \
    less \
    libssl-dev \
    iputils-ping \
    libyaml-dev \
    unzip \
    dumb-init \
    docker.io \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm-dev \
    bison \
    strace \
    iproute2 \
    lldb \
    libgtk-3-dev \
    libwebkit2gtk-4.1-dev \
    bash-completion

# docker composeをインストールする
RUN apt install -y ca-certificates gnupg lsb-release
RUN mkdir -m 0755 -p /etc/apt/keyrings &&  curl -fsSL https://download.docker.com/linux/debian/gpg\
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable"\
      | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update -y && apt install -y docker-compose-plugin

# Docker公式では"noninteractive"は非推奨と言っているため、設定値を元に戻す
ENV DEBIAN_FRONTEND=newt

# 5. ロケールを生成
# -----------------------------------------------------------------------------
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen &&\
  locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# 6. Goに必要なディレクトリを作成する
# -----------------------------------------------------------------------------
RUN mkdir -p /go/src/app /go/pkg/mod/cache && chmod 777 -R /go/pkg
WORKDIR /go/src/app

# 7. コンテナ管理者へユーザを切り替える
# -----------------------------------------------------------------------------
RUN chown -R container:container /go
# コンテナはデフォルトでroot権になっているので、冒頭で作成した"container"ユーザへ切り替える
USER container

# 8. Nodeインストール
# -----------------------------------------------------------------------------
# インストールするNodeのデフォルトバージョン. compose.yamlから環境変数を設定することで、バージョン番号を変更できる.
ARG NODE_VERSION=22
# TypeScript環境を作成する. node, tscはvoltaを使用してインストールする.
#   `curl https://get.volta.sh | bash` コマンドにより、$HOME/.bashrcに自動的にvoltaへのパスが追加され、
#   yarnでインストールしたtypescriptやnode本体へのパスも自動的に追加される.
RUN curl https://get.volta.sh | bash && \
    /home/container/.volta/bin/volta install node@${NODE_VERSION} && \
    /home/container/.volta/bin/volta install yarn@1.22
RUN /home/container/.volta/bin/volta install pnpm
# TypeScript関連のライブラリをyarnでグローバルに構築する
RUN /home/container/.volta/bin/yarn global add typescript tsx @types/node

# 10. Rustインストール
# -----------------------------------------------------------------------------
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# 11. Wailsインストール
# -----------------------------------------------------------------------------
RUN go install github.com/wailsapp/wails/v2/cmd/wails@latest

# 12. 使用ポート番号の設定
# -----------------------------------------------------------------------------
EXPOSE 3000 5173

# 13. 各種デフォルトの設定をコンテナ上に作成する
# -----------------------------------------------------------------------------
RUN echo '[url "https://host.docker.internal/"]' > /home/container/.git-include &&\
    echo '    insteadOf = https://localhost/' >> /home/container/.git-include &&\
    echo 'syntax on' > /home/container/.vimrc


# =============================================================================
#   開発用ステージ
# =============================================================================
FROM --platform=$BUILDPLATFORM base AS develop

# Goデバッガのインストール
RUN go install github.com/go-delve/delve/cmd/dlv@v1.24.2
# Go 静的解析ツールのインストール
RUN go install honnef.co/go/tools/cmd/staticcheck@v0.6.1
# Go ホットリロードツールのインストール
RUN go install github.com/air-verse/air@v1.61.7
# Go Lintのインストール
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.64.8
# Go補完・定義ジャンプツールのインストール
RUN go install golang.org/x/tools/gopls@v0.18.1
# Go O/RM ツールのインストール
RUN go install entgo.io/ent/cmd/ent@latest

# Goに必要なモジュールをインストールする
# -----------------------------------------------------------------------------
USER root
RUN --mount=type=cache,target=/go/pkg/mod/,sharing=locked \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download -x
USER container


# =============================================================================
#   テスト専用ステージ
# =============================================================================
FROM --platform=$BUILDPLATFORM base AS test


# =============================================================================
#   本番運用ステージ
# =============================================================================
FROM --platform=$BUILDPLATFORM base AS product
USER root
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go install
ENTRYPOINT ["/go/bin/app"]
