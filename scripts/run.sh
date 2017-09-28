#!/bin/bash

source .env

DOMAINS=(${1//,/ })
LENGTH=$(echo ${#DOMAINS[@]}-1 | bc)
for ((i=$LENGTH; i>=0; i--)); do
    if [ $i -eq 0 ]; then
        FIRST_DOMAIN=${DOMAINS[$i]}
    fi
    TARGETS="-d ${DOMAINS[$i]} $TARGETS"
done

sudo certbot certonly --manual \
    --preferred-challenges http \
    --email $EMAIL \
    --agree-tos \
    --manual-public-ip-logging-ok \
    --manual-auth-hook scripts/auth.sh \
    --renew-by-default \
    --expand \
    --debug \
    --staging \
    $TARGETS

mkdir -p cert && sudo cp -r /etc/letsencrypt/live/$FIRST_DOMAIN cert/$FIRST_DOMAIN
