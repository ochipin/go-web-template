# -ldflags に設定する値
GOOS         := $(shell go env GOOS)
GOARCH       := $(shell go env GOARCH)
PLATFORM     := $(GOOS)/$(GOARCH)
TAG_NAME     := $(shell [ -z "$(git describe --abbrev=0 2>/dev/null)" ] && echo v0.0 || git describe --abbrev=0)
BLANCH_NAME  := $(shell git branch --show-current)
COMMIT_ID    := $(shell git rev-parse --short HEAD)
COMMIT_DATE  := $(shell git log -1 --format="%cd" --date=format:"%Y/%m/%d")
COMMIT_COUNT := $(shell git rev-list --count HEAD)
TREE_STATE   := $(shell [ -z "$$(git status --porcelain)" ] && echo clean || echo dirty)
BUILD_DATE   := $(shell date +"%Y/%m/%d")
GOVERSION    := $(shell go env GOVERSION)
BUILD_USER   := $(shell id -un)@$(shell uname -n)
OS_NAME      := $(shell . /etc/os-release && echo $$ID)
OS_VERSION   := $(shell . /etc/os-release && echo $$VERSION_ID)
# 公開向け
# COPYRIGHT    := MIT License (C) $(shell date +"%Y") $(shell git config user.name).
# 非公開向け
COPYRIGHT    := (C) $(shell date +"%Y") $(shell git config user.name). All rights reserved.

# -ldflags に渡すオプション
LDFLAGS      := -X 'main.tagName=$(TAG_NAME)' \
				-X 'main.branchName=$(BLANCH_NAME)' \
				-X 'main.commitID=$(COMMIT_ID)' \
				-X 'main.commitDate=$(COMMIT_DATE)' \
				-X 'main.commitCount=$(COMMIT_COUNT)' \
				-X 'main.treeState=$(TREE_STATE)' \
				-X 'main.buildDate=$(BUILD_DATE)' \
				-X 'main.copyright=$(COPYRIGHT)' \
				-X 'main.goVersion=$(GOVERSION)' \
				-X 'main.buildUser=$(BUILD_USER)' \
				-X 'main.platform=$(PLATFORM)' \
				-X 'main.osName=$(OS_NAME)' \
				-X 'main.osVersion=$(OS_VERSION)' \
				-X 'main.projectName=$(PROJECT_NAME)'

# 開発環境・ステージング環境用
all:
	go build -ldflags "$(LDFLAGS)" -o bin/$(PROJECT_NAME) ./cmd/app

# 本番環境用
deploy:
	CGO_ENABLED=0 go build -trimpath -ldflags "-s -w $(LDFLAGS)" -o bin/$(PROJECT_NAME) ./cmd/app
