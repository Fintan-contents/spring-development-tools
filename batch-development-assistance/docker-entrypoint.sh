#!/bin/sh

# sftp known_hosts 登録
if [ ! -e /home/app/.ssh/known_hosts ]; then
    mkdir -p /home/app/.ssh
    # sftp サーバーが立ち上がるまで待機
    while [ ! "$(ssh-keyscan -t rsa -H sftp-server)" ]
    do
        sleep 1
    done
    ssh-keyscan -t rsa -H sftp-server > /home/app/.ssh/known_hosts
fi

exec /bin/sh
