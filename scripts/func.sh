#!/bin/bash

source .env

function configure_aws_cli
{
    echo "> Setup AWS configuration..."
    printf "${AWS_ACCESS_KEY_ID}\n${AWS_SECRET_ACCESS_KEY}\n${AWS_DEFAULT_REGION}\n${AWS_OUTPUT_FORMAT}\n" | sudo aws configure
    sudo chmod 644 ~/.aws/*
    echo "> Success"
}
