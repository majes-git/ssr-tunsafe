#!/bin/bash

CONFIG_FILE=/etc/128technology/tunsafe/tunsafe.conf
NEW_PEERS=/var/lib/tunsafe/tunsafe.config
NEW_HEADER=$(mktemp)

if [ ! -e $CONFIG_FILE ]; then
    echo "ERROR: Config file $CONFIG_FILE does not exits."
    exit 1
fi

OLD_CHECK_SUM=$(md5sum $CONFIG_FILE | cut -b1-32)
{
    sed -n '1,/^$/p' $CONFIG_FILE
    echo '#--- automatically generated peers below ---#'
}  > $NEW_HEADER

# if peers
if [ $(wc -l < $NEW_PEERS) -ne 0 ]; then
    echo "INFO: Creating new config"
    cat $NEW_HEADER $NEW_PEERS > $CONFIG_FILE
fi
rm -f $NEW_HEADER

NEW_CHECK_SUM=$(md5sum $CONFIG_FILE | cut -b1-32)
if [ "$OLD_CHECK_SUM" != "$NEW_CHECK_SUM" ]; then
    echo "INFO: Reloading ssr-tunsafe"
    systemctl restart ssr-tunsafe
fi
