#!/bin/bash

function bucketExist() {
    BUCKET="$1"

    BUCKET_EXISTS=$(aws s3api head-bucket --bucket "$BUCKET" 2>&1 || true)
    if [ -z "$BUCKET_EXISTS" ]; then
        echo 0
    else
        echo 1
    fi
}

function getAccountId() {
    aws sts get-caller-identity --query "Account" --output text
}

function copyFileToS3() {
    SOURCE_FILE="$1"
    S3_BUCKET="$2"
    KEY_NAME="$3"

    aws s3 cp "${SOURCE_FILE}" "s3://${S3_BUCKET}/${KEY_NAME}"
}

function copyFileFromS3() {
    S3_BUCKET="$1"
    FILE_KEY="$2"
    FILE_PATH="$3"
    aws s3 cp "s3://${S3_BUCKET}/${FILE_KEY}" "${FILE_PATH}" 
}

function policyExists() {
    POLICY_ARN="$1"

    aws iam get-policy --policy-arn "${POLICY_ARN}" >/dev/null 2>&1
    echo $?
}

function createPolicy() {
    POLICY_NAME="$1"
    POLICY_FILE_PATH="$2"

    aws iam create-policy \
    --policy-name "${POLICY_NAME}" --no-paginate \
    --policy-document "file://${POLICY_FILE_PATH}"
}

function roleExists() {
    ROLE_NAME="$1"

    aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1
    echo $?
}

function createRole() {
    ROLE_NAME="$1"
    POLICY_DOCUMENT="$2"
    aws iam create-role --role-name "${ROLE_NAME}" --no-paginate --assume-role-policy-document "file://${POLICY_DOCUMENT}"
}

function getAssumeRole() {
    ROLE_ARN=$1

	role_output=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name default)

	if [ $? -ne 0 ]; then
	  echo "Failed to assume role."
	  exit 1
	fi

	AWS_ACCESS_KEY_ID=$(echo $role_output | jq -r '.Credentials.AccessKeyId')
	AWS_SECRET_ACCESS_KEY=$(echo $role_output | jq -r '.Credentials.SecretAccessKey')
	AWS_SESSION_TOKEN=$(echo $role_output | jq -r '.Credentials.SessionToken')

	export AWS_ACCESS_KEY_ID
	export AWS_SECRET_ACCESS_KEY
	export AWS_SESSION_TOKEN
}

function set_aws_credentials() {
    CREDENTIAL_MANAGEMENT_NAME=$1
    
    aws_creds=$(getEncryptedCredential "$CREDENTIAL_MANAGEMENT" "$CREDENTIAL_MANAGEMENT_NAME.CREDENTIAL_KEY_VALUE_PAIR")

    aws_access_key=$(echo $aws_creds | sed "s/'/\"/g" | jq -r '.aws_access_key')
    aws_secret_access_key=$(echo $aws_creds | sed "s/'/\"/g" | jq -r '.aws_secret_access_key')

    export AWS_ACCESS_KEY_ID="$aws_access_key"
    export AWS_SECRET_ACCESS_KEY="$aws_secret_access_key"
    }

function check_aws_authentication() {
    if ! aws sts get-caller-identity &>/dev/null; then
        logErrorMessage "Failed to authenticate with AWS CLI. Please configure AWS CLI authentication."
        exit 1
    else
        logInfoMessage "Successfully authenticated with AWS CLI."
    fi
}
