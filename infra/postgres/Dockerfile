ARG PGVERSION=latest
FROM --platform=$BUILDPLATFORM postgres:${PGVERSION} AS base

# locale-gen を使用して日本語環境を整備する
RUN apt-get update && \
    apt-get install -y locales vim && \
    sed -i '/ja_JP.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
# vim を設定
RUN echo 'syntax on' >> ~/.vimrc

# サーバ証明書の配置を考慮したentrypoint.shをコピーする
COPY <<EOF /usr/bin/entrypoint.sh
#!/bin/bash

if [[ -f /certs/server.crt ]]; then
    cp /certs/server.crt /var/lib/postgresql/server.crt
    chown postgres:postgres /var/lib/postgresql/server.crt
fi
if [[ -f /certs/server.key ]]; then
    cp /certs/server.key /var/lib/postgresql/server.key
    chown postgres:postgres /var/lib/postgresql/server.key
    chmod 600 /var/lib/postgresql/server.key
fi
if [[ -f /certs/ca.crt ]]; then
    cp /certs/ca.crt /var/lib/postgresql/ca.crt
    chown postgres:postgres /var/lib/postgresql/ca.crt
fi

exec docker-entrypoint.sh postgres
EOF
RUN chmod 755 /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
