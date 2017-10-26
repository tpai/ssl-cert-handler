#!/bin/bash

source scripts/run.sh
source scripts/func.sh

if [ "$1" == "" ]; then
    echo "> You must input source file!"
    exit 1
fi

configure_aws_cli

while IFS='' read -r line || [[ -n "$line" ]]; do
    RESULT="$RESULT,$line"
done < "$1"

certbot $RESULT $2
