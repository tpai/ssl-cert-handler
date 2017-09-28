#!/bin/bash

source scripts/run.sh

if [ "$1" == "" ]; then
    echo "> You must input source file!"
    exit 1
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
    RESULT="$RESULT,$line"
done < "$1"

certbot $RESULT
