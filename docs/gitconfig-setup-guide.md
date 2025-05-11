# .gitconfig セットアップガイド
Go言語は内部でGitを使用しているため、Gitのインストールが必要である。ここでは、UbuntuにGitをセットアップする方法を説明する。

## Gitのインストール
Gitはv2以上をインストールすること。

```
$ sudo apt intall git
$ git version
git version 2.39.2 # <-- 2.x 以上なら問題ない
```

## .gitconfigの設定
Gitをインストール後、`$HOME/.gitconfig`ファイルを作成し、必ず設定を行うこと。

```ini
# 以下設定例:
[init]
    # git initで作成した際に、自動的に作成されるブランチ名
    defaultBranch = main
[user]
    # 自分の名前とメールアドレス.
    # 未設定のままだとgitがエラーになるため、必ず設定を行うこと!
    name  = 自分の名前
    email = 自分のメールアドレス
[core]
    # git commit時に立ち上がるエディタの情報
    editor = vim
    pager = LESSCHARSET=utf-8 less
    quotepath = false
    # LFをGitがCRLFへ変更しようとするが、autoCRLFをfalseにすることで、変更しなくなる
    # warning: CRLF will be replaced by LF in ... 警告メッセージが出なくなる
    autoCRLF = false
# 必ずマージコミットを作成する
[merge]
    ff = false
# ローカルのブランチがリモートのブランチの履歴と一致していて、
# そのまま進められる場合のみ、pullが成功するようにする
[pull]
    ff = only
# git コマンドの色設定
[color]
    ui = auto
# git status 実行時の色設定
[color "status"]
    untracked = cyan
    added = green bold
    changed = red bold
# git diff 実行時の色設定
[color "diff"]
    old = red
    new = green
    meta = white
    context = yellow
    flag = cyan
    func = 5
[http]
    # 比較的大き目なファイルもコミットできるようにする
    postBuffer = 524880000
    # sslVerify = false
    # proxy = http://proxy.com:8080
[https]
    # 比較的大き目なファイルもコミットできるようにする
    postBuffer = 524880000
    # proxy = http://proxy.com:8080
[alias]
    g = log --pretty=format:'%C(red reverse)%d%Creset%C(white reverse)\
 %h% Creset %C(green reverse) %an %Creset %C(cyan)%ar%Creset%n%C(white bold)\
 %w(80)%s%Creset%n%n%w(80,2,2)%b' --graph --name-status
# GitHubなどのTokenを生成した場合は、下記の設定を追加し、
# .git-credentialsファイルにToken情報を追記すること
[credential]
    helper = store
```
