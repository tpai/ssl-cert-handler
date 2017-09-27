#!/bin/bash

source .env
source scripts/func.sh

configure_aws_cli

aws dynamodb put-item --table-name certbot_verification --item $(jq -c -n "{
  \"$DYNAMODB_SEARCH_KEY\": {\"S\": \"$CERTBOT_TOKEN\"},
  \"$DYNAMODB_VALUE_KEY\": {\"S\": \"$CERTBOT_VALIDATION\"}
}")
