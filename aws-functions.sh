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
	  echo "Failed to assume role :- $ROLE_ARN."
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

function create_ec2_instance() {
    AMI_ID="$1"
    INSTANCE_TYPE="$2"
    SSH_KEY_NAME="$3"
    SUBNET_ID="$4"
    SECURITY_GROUP_IDS="$5"
    INSTANCE_COUNT="$6"
    INSTANCE_NAME="$7"
    BUILDX_ENABLE="$8"
    TAG_SPECIFICATIONS="${9}"
    USER_DATA="${10:-}"  # Optional user data

    if [ -n "$USER_DATA" ]; then
        # Use base64-encoded user data and include in the EC2 creation command
        EC2_CREATE_OUTPUT=$(aws ec2 run-instances \
            --image-id "$AMI_ID" \
            --instance-type "$INSTANCE_TYPE" \
            --key-name "$SSH_KEY_NAME" \
            --subnet-id "$SUBNET_ID" \
            --security-group-ids "$SECURITY_GROUP_IDS" \
            --count "$INSTANCE_COUNT" \
            --tag-specifications "$TAG_SPECIFICATIONS" \
            --user-data "$USER_DATA")
    else
        # EC2 creation without user data
        EC2_CREATE_OUTPUT=$(aws ec2 run-instances \
            --image-id "$AMI_ID" \
            --instance-type "$INSTANCE_TYPE" \
            --key-name "$SSH_KEY_NAME" \
            --subnet-id "$SUBNET_ID" \
            --security-group-ids "$SECURITY_GROUP_IDS" \
            --count "$INSTANCE_COUNT" \
            --tag-specifications "$TAG_SPECIFICATIONS")
    fi
    # Check if the EC2 creation command succeeded
    if [ $? -ne 0 ]; then
        echo "Error creating EC2 instance."
        echo "$EC2_CREATE_OUTPUT"
        return 1
    fi

    echo "$EC2_CREATE_OUTPUT"
    return 0
}

check_instance_status() {
  local INSTANCE_ID="$1"
  local INSTANCE_TYPE="$2"

  logInfoMessage "Checking $INSTANCE_TYPE instance [ID: $INSTANCE_ID]."

  INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[].Instances[].State.Name" --output text)

  if [[ "$INSTANCE_STATE" == "terminated" || "$INSTANCE_STATE" == "stopped" ]]; then
    logInfoMessage "$INSTANCE_TYPE instance [ID: $INSTANCE_ID] is in $INSTANCE_STATE state. Skipping status check and moving on."
    return 1  
  fi

  logInfoMessage "Waiting for $INSTANCE_TYPE instance [ID: $INSTANCE_ID] to be in 'running' state and pass status checks."

  MAX_WAIT_TIME=600   # Maximum wait time in seconds (10 minutes)
  SLEEP_INTERVAL=15   # Interval to check the status (15 seconds)
  TOTAL_WAIT=0

  while true; do
    INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[].Instances[].State.Name" --output text)
    INSTANCE_STATUS_CHECK=$(aws ec2 describe-instance-status --instance-ids "$INSTANCE_ID" --query "InstanceStatuses[].InstanceStatus.Status" --output text)

    logInfoMessage "$INSTANCE_TYPE instance [ID: $INSTANCE_ID] current state: $INSTANCE_STATE"
    logInfoMessage "$INSTANCE_TYPE instance [ID: $INSTANCE_ID] status check: $INSTANCE_STATUS_CHECK"

    if [ "$INSTANCE_STATE" = "running" ] && [ "$INSTANCE_STATUS_CHECK" = "ok" ]; then
      logInfoMessage "$INSTANCE_TYPE instance [ID: $INSTANCE_ID] is now running and passed all status checks."
      return 0 
    fi

    if [ "$TOTAL_WAIT" -ge "$MAX_WAIT_TIME" ]; then
      logErrorMessage "Timeout reached for $INSTANCE_TYPE instance [ID: $INSTANCE_ID]. Not in 'running' state or did not pass status checks."
      return 1  
    fi

    sleep $SLEEP_INTERVAL
    TOTAL_WAIT=$((TOTAL_WAIT + SLEEP_INTERVAL))
  done
}

terminate_instance() {
  local INSTANCE_ID="$1"
  local INSTANCE_TYPE="$2"

  INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[].Instances[].State.Name" --output text)

  if [[ "$INSTANCE_STATE" != "terminated" && "$INSTANCE_STATE" != "stopped" ]]; then
    logErrorMessage "Terminating $INSTANCE_TYPE instance [ID: $INSTANCE_ID]."
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
    logInfoMessage "$INSTANCE_TYPE instance [ID: $INSTANCE_ID] has been terminated."
  else
    logInfoMessage "$INSTANCE_TYPE instance [ID: $INSTANCE_ID] is already in $INSTANCE_STATE state. No need to terminate."
  fi
}
