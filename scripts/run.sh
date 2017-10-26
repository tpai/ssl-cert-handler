#!/bin/bash

source .env

function certbot
{
    DOMAINS=(${1//,/ })
    LENGTH=$(echo ${#DOMAINS[@]}-1 | bc)
    for ((i=$LENGTH; i>=0; i--)); do
        if [ $i -eq 0 ]; then
            FIRST_DOMAIN=${DOMAINS[$i]}
        fi
        TARGETS="-d ${DOMAINS[$i]} $TARGETS"
    done

    if [ "$2" == "production" ]; then
        sudo certbot certonly --manual --preferred-challenges http --email $EMAIL --agree-tos --manual-public-ip-logging-ok --manual-auth-hook scripts/auth.sh --renew-by-default --expand --debug $TARGETS
    else
        sudo certbot certonly --manual --preferred-challenges http --email $EMAIL --agree-tos --manual-public-ip-logging-ok --manual-auth-hook scripts/auth.sh --renew-by-default --expand --debug --staging $TARGETS
    fi

    mkdir -p cert && sudo cp -r /etc/letsencrypt/live/$FIRST_DOMAIN cert/
}
