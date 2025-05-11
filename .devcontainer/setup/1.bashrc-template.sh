# .bashrc

# -----------------------------------------------------------------------------
# コンテナ内にマウントする bashrc ファイル.
# -----------------------------------------------------------------------------

# rm/cp/mv コマンドは、毎回確認する
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias vim='vim --'
alias ls='LC_COLLATE=C /usr/bin/ls --color=auto -v --group-directories-first'

# 最新のgitタグを表示するx
gittag() {
    local tagname=`git describe --tags --first-parent --abbrev=0 2>/dev/null`
    if [[ $tagname != "" ]] ; then echo ":$tagname"; fi
}

# ブランチ名を取得する
__gitbranch() {
    local branch=`git rev-parse --abbrev-ref HEAD 2>/dev/null`
    case $branch in
        "") ;;
        HEAD)
            branch=`git rev-parse --short HEAD 2>/dev/null`
            if [ "$branch" = "" ]; then
                branch=$__DEFAULT_BRANCH
            fi
            ;;
    esac
    echo $branch
}

# 右側にGitプロンプトを表示する
__gitprompt() {
    if [[ "`git rev-parse --is-inside-work-tree 2>/dev/null`" = "true" ]]; then
        local branch=`__gitbranch`
        local toplevel=`git rev-parse --show-toplevel`
        local dirname=`basename $toplevel`
        local unstage
        local nocommit
        local untrack
        local RPROMPT1="[$dirname][$branch]"
        # ステージングされておらず、変更されたファイルがある場合(*)
        git diff --no-ext-diff --quiet
        if [[ ! $? = 0 ]]; then
            unstage='\e[1;31m*'
            RPROMPT1="*$RPROMPT1"
        fi
        # コミットされていない場合(+)
        git diff --no-ext-diff --cached --quiet
        if [[ ! $? = 0 ]]; then
            nocommit='\e[0;33m+'
            RPROMPT1="+$RPROMPT1"
        fi
        # 未追跡ファイルがある場合(%)
        git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' >/dev/null 2>&1
        if [ $? = 0 ]; then
            untrack='\e[0;34m%%'
            RPROMPT1="%$RPROMPT1"
        fi
        # 右側にGitプロンプトを表示する
        local RPROMPT="$untrack$nocommit$unstage[$dirname][$branch]\e[m"
        local width=$(($COLUMNS - ${#RPROMPT1} - 2))
        printf "%${width}s\e[1;32m$RPROMPT\\r" ''
    fi
}

# git コマンドが存在するかチェックする
which git >/dev/null 2>&1
if [[ ! $? = 0 ]]; then
    # git コマンドがない場合は __gitprompt 関数を何もしない処理にする
    __gitprompt() { echo -n ; }
else
    # git コマンドがある場合はデフォルトブランチ名を設定する
    __DEFAULT_BRANCH="`git config init.defaultBranch`"
    if [ "$__DEFAULT_BRANCH" = "" ]; then
        __DEFAULT_BRANCH=main
    fi
fi

# プロンプトの設定
__prompt_user='\u@\h'
# root の場合は、usernameとhostnameを赤色に設定する
if [ "`id -u`" = "0" ]; then
    __prompt_user='\[\033[01;31m\]\u@\h\[\033[00m\]'
fi

# コマンド実行の成否をプロンプトに表示する
PROMPT_COMMAND=__prompt_command
__prompt_command() {
    local RES=$?

    # カレントディレクトリがシンボリックリンクか否かを判定する
    if [ -L ${PWD} ]; then
        DIR='\[\033[01;36m\]\W\[\033[00m\]'
    else
        DIR='\[\033[01;34m\]\W\[\033[00m\]'
    fi

    # コマンドの実行結果を判定する
    if [ "$RES" = "0" ]; then
        EC="\\[\\033[01;32m\\]$RES\\[\\033[00m\\]]\\[\\033[01;32m\\]\\$\\[\\033[00m\\]"
    else
        EC="\\[\\033[01;31m\\]$RES\\[\\033[00m\\]]\\[\\033[01;31m\\]\\$\\[\\033[00m\\]"
    fi

    # [時間][ユーザID@ホスト名:ディレクトリ名 (ブランチ名) コマンド実行成否] を表示する
    PS1="\\[\\033[33m\\][\\t]\\[\\033[00m\\][$__prompt_user:$DIR $EC "

    # 右プロンプトにブランチ名やステージング、プロジェクトディレクトリ情報を表示する
    __gitprompt
}

# 実行日時(YYYY-MM-DD HH:MI:SS)を.bash_historyへ保存する.
# history コマンドを実行することで、コマンドの実行履歴を追えるようにする
export HISTTIMEFORMAT='%F %T '

# コマンド履歴に保存する量を増やす
export HISTSIZE=100000
export HISTFILESIZE=100000

# 言語設定
export LANG=en_US.UTF-8

# プロキシ設定
# export http_proxy=http://proxy.example.com:8080
# export https_proxy=https://proxy.example.com:8443
export no_proxy=localhost,127.0.0.1

# Gitコマンドの補完
source /usr/share/bash-completion/completions/git

# umask を設定
umask 022

# docker サブコマンドの補完
if [[ -f /usr/share/bash-completion/completions/docker ]]; then
    source /usr/share/bash-completion/completions/docker
fi
