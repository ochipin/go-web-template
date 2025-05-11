ARG ALPINE_LINUX=latest
FROM --platform=$BUILDPLATFORM alpine:${ALPINE_LINUX} AS base

LABEL maintainer="Suguru Ochiai <suguru.ochiai.doc@gmail.com>"
LABEL version="1.0"

ARG CONTAINER_USER=0
ARG CONTAINER_GROUP=0
# LDAPユーザを追加する
RUN if [[ ${CONTAINER_GROUP} -gt 0 ]]; then addgroup -g ${CONTAINER_GROUP} ldap; fi && \
    if [[ ${CONTAINER_USER} -gt 0 ]]; then adduser ldap -u ${CONTAINER_USER} -G ldap -HD -s /sbin/nologin; fi

ARG OPENLDAP_VERSION=2.6.8-r0

RUN apk --no-cache add \
    bash \
    procps-ng \
    openssl \
    envsubst \
    tzdata \
    git \
    ca-certificates \
    openldap=${OPENLDAP_VERSION} \
    openldap-clients=${OPENLDAP_VERSION} \
    openldap-back-mdb=${OPENLDAP_VERSION} \
    openldap-overlay-syncprov=${OPENLDAP_VERSION} \
    openldap-overlay-memberof=${OPENLDAP_VERSION} \
    openldap-overlay-ppolicy=${OPENLDAP_VERSION}
# apkキャッシュをすべて削除
RUN rm -rf /var/cache/apk/*
# OpenLDAP環境設定ファイル置き場を作成する
RUN mkdir -p /etc/openldap/slapd.d /run/openldap &&\
    chown ldap:ldap -R /etc/openldap /var/lib/openldap /run/openldap

# 5. コンテナ起動時の初期位置
# -----------------------------------------------------------------------------
WORKDIR /

# 6. 使用するポート番号
# -----------------------------------------------------------------------------
EXPOSE 389 636

# 7. slapd のログを標準出力へ
# -----------------------------------------------------------------------------
RUN echo 'local4.* -' >> /etc/syslog.conf

# 5. entrypointを実行する
# -----------------------------------------------------------------------------
COPY /infra/openldap/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh", "--syslog"]
