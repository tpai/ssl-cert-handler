#!/usr/bin/env bash

source .env

# (npm|yarn) run ecs

function configure_aws_cli
{
    printf "${AWS_ACCESS_KEY_ID}\n${AWS_SECRET_ACCESS_KEY}\n${AWS_REGION}\n${AWS_OUTPUT_FORMAT}\n" | aws configure
    if [ "$CIRCLECI" == "true" ]; then
        $(aws ecr get-login) || exit 1
    else
        aws ecr get-login --no-include-email | $(sed 's/\-e none //g') || exit 1
    fi
}

function build_ecr_image
{
    echo "Building Docker image ($DOCKER_IMAGE:$HASH)"
    docker build -t $DOCKER_IMAGE:$HASH . || exit 1
}

function push_ecr_image
{
    docker push $DOCKER_IMAGE:$HASH || exit 1
}

function define_task
{
    TASK_DEF=$(printf "[
        {
            \"portMappings\": [
                {
                    \"hostPort\": 0,
                    \"containerPort\": 3000,
                    \"protocol\": \"tcp\"
                }
            ],
            \"name\": \"web\",
            \"environment\": [
                { \"name\": \"AWS_ACCESS_KEY_ID\", \"value\": \"$AWS_ACCESS_KEY_ID\" },
                { \"name\": \"AWS_SECRET_ACCESS_KEY\", \"value\": \"$AWS_SECRET_ACCESS_KEY\" },
                { \"name\": \"AWS_REGION\", \"value\": \"$AWS_REGION\" },
                { \"name\": \"DYNAMODB_SEARCH_KEY\", \"value\": \"$DYNAMODB_SEARCH_KEY\" },
                { \"name\": \"DYNAMODB_VALUE_KEY\", \"value\": \"$DYNAMODB_VALUE_KEY\" },
                { \"name\": \"DYNAMODB_TABLE\", \"value\": \"$DYNAMODB_TABLE\" }
            ],
            \"image\": \"$DOCKER_IMAGE:$HASH\",
            \"logConfiguration\": {
                \"logDriver\": \"awslogs\",
                \"options\": {
                    \"awslogs-group\": \"$1\",
                    \"awslogs-region\": \"$AWS_REGION\",
                    \"awslogs-stream-prefix\": \"$2\"
                }
            },
            \"cpu\": 0,
            \"memoryReservation\": 300
        }
    ]")
}

function register_task
{
    echo "> Creating new revision of task definition '$ECS_TASK_FAMILY_NAME'..."
    TASK_REVISION=$(aws ecs register-task-definition --container-definitions "$TASK_DEF" --family $ECS_TASK_FAMILY_NAME --task-role-arn $ECS_TASK_ROLE_ARN || exit 1)
}

function update_service
{
    if ! which jq &> /dev/null; then
        echo "> Installing jq..."
        if [ "$(uname)" == "Darwin" ]; then
            brew install jq
        elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
            wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
            chmod +x ./jq
            cp jq /usr/local/bin
        fi
        echo "> jq installed"
    fi

    echo "> Check existence of '$2' service in '$1' cluster..."
    HAS_SERVICE=$(aws ecs describe-services --cluster $1 --services $2 | jq ".services" || exit 1)

    if [ "$HAS_SERVICE" == "[]" ]; then
        echo "> Not exist, please create new service."
        exit 1
    else
        echo "> Service exist, updating version of task definition..."
        TASK_ARN=$(aws ecs update-service --cluster $1 --service $2 --task-definition $ECS_TASK_FAMILY_NAME --desired-count $ECS_DESIRED_COUNT | jq ".service.taskDefinition" || exit 1)
    fi

    IFS='/' read -a ARNS <<< "$TASK_ARN"
    ARN=$(echo "${ARNS[1]}" | sed s/\"//g)

    echo "> Pushing notification to slack..."
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\": \"\n[$1/$2] Service updated by $(id -un)\n\n>• Task Definition: \`$ARN\`\n>• Image Tag: \`$HASH\`\"}" \
        $SLACK_WEB_HOOK
}

function deploy_to
{
    configure_aws_cli
    build_ecr_image
    push_ecr_image
    define_task $1 $2
    register_task
}

deploy_to $ECS_CLUSTER $ECS_SERVICE
update_service $ECS_CLUSTER $ECS_SERVICE
