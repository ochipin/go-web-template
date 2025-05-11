#!/bin/bash

# slapdの初期化済みか確認する
function is_slapd_initialized() {
    # cn=config.ldif などのファイルが作成済みか、ディレクトリ内のファイル数をカウントする
    local -r file_count=$(ls /etc/openldap/slapd.d/* 2>/dev/null | wc -l)
    [[ $file_count -eq 0 ]]
}

# slapdの初期化を実施する
function initialize_slapd() {
    cat /setup/initialize/setup-slapd.ldif | envsubst > /etc/openldap/slapd.ldif
    slapadd -d -1 -F /etc/openldap/slapd.d -n 0 -l /etc/openldap/slapd.ldif
}

# slapdを起動する
function start_slapd() {
    if [[ $(pidof slapd) > 0 ]]; then
        return 0
    fi
    chown -R ldap:ldap /etc/openldap /var/lib/openldap/openldap-data
    /usr/sbin/slapd -h "ldapi://0.0.0.0 ldap://0.0.0.0 ldaps://0.0.0.0" -s 256 -u ldap -g ldap # -d 0
}

# 初回起動時のみ行う設定
function setup_initialize_config() {
    cat /setup/initialize/setup-schema.ldif | envsubst > /tmp/setup-schema.ldif
    ldapadd -Y EXTERNAL -H ldapi://0.0.0.0 -f /tmp/setup-schema.ldif
    if [[ ! $? = 0 ]]; then
        exit 1
    fi

    cat /setup/initialize/setup-overlay.ldif | envsubst > /tmp/setup-overlay.ldif
    ldapadd -Y EXTERNAL -H ldapi://0.0.0.0 -f /tmp/setup-overlay.ldif
    if [[ ! $? = 0 ]]; then
        exit 1
    fi
}

# 基本的な設定を行う
function setup_ldif() {
    for i in `ls /setup/startup/*-setup*`; do
        filename=`basename $i`
        cat $i | envsubst > /tmp/$filename
        echo ldapadd -Y EXTERNAL -H ldapi://0.0.0.0 -f /tmp/$filename
        ldapadd -Y EXTERNAL -H ldapi://0.0.0.0 -f /tmp/$filename
    done
}

# 初回起動時にレコードを追加する
function initialize_add_records() {
    for i in `ls /setup/customize/*.ldif`; do
        # /path/to/file.name ⇒ file.name の名前だけを取り出す
        filename=`basename $i`
        # file.nameの環境変数部分を展開した結果を /tmp/file.name へ保存する
        cat $i | envsubst > /tmp/$filename
        # ldapadd でレコードを追加する
        # ldapadd -xD cn=Manager,dc=example,c=com -f /setup/backup.ldif -w ************
        ldapadd -xD ${LDAP_ROOT_DN} -f /tmp/$filename -w ${LDAP_ROOT_PASSWORD}
    done
}

# =============================================================================
#   以下エントリポイント
# =============================================================================
update-ca-certificates
if is_slapd_initialized; then
    initialize_slapd
    if [[ ! $? = 0 ]]; then
        exit 1
    fi
    start_slapd
    # slapd起動後に設定を追加する
    setup_initialize_config
    setup_ldif
    initialize_add_records
else
    start_slapd
    setup_ldif
    initialize_add_records
fi

# --syslogオプションが付与されている場合のみ、LDAPサーバのログをsyslogへ出力する
for arg in "$@"; do
    if [[ "$arg" == "--syslog" ]]; then
        syslogd -n
        break
    fi
done
