#!/bin/bash

generateOutput() {
    ACTIVITY_SUB_TASK_CODE="$1"
    Status="$2"
    Message="$3"

    EXECUTION_DIR="/bp/execution_dir"
    OUTPUT_DIR="${EXECUTION_DIR}/${EXECUTION_TASK_ID}"
    file_name="$OUTPUT_DIR/summary.json"

    mkdir -p "$OUTPUT_DIR"

    file_content=""
    if [[ -f "$file_name" ]]; then
        file_content=$(<"$file_name")
    fi
    [[ "$file_content" != "["* ]] && file_content="[$file_content]"
    updated_content=$(jq -c ". += [{ \"$ACTIVITY_SUB_TASK_CODE\": { \"status\": \"$Status\", \"message\": \"$Message\" } }]" <<< "$file_content")
    echo "$updated_content" | jq "." > "$file_name"
    echo "{ \"$ACTIVITY_SUB_TASK_CODE\": { \"status\": \"$Status\", \"message\": \"$Message\" } }" | jq "." > "${OUTPUT_DIR}/${ACTIVITY_SUB_TASK_CODE}.json"
    echo "Job step response updated in: $file_name"
}

function getComponentName() {
  COMPONENT_NAME=$(jq -r .build_detail.repository.name < /bp/data/environment_build )
  echo "$COMPONENT_NAME"
}

function getRepositoryTag() {
  BUILD_REPOSITORY_TAG=$(jq -r .build_detail.repository.tag < /bp/data/environment_build)
  echo "$BUILD_REPOSITORY_TAG"
}

function getDockerfileParentPath() {
  DOCKERFILE_ENTRY=$(jq -r .build_detail.dockerfile_path  < /bp/data/environment_build)
  getNthTextInALine "$DOCKERFILE_ENTRY" : 2
}

function getDockerfileName() {
  DOCKERFILE_ENTRY=$(jq -r .build_detail.dockerfile_path  < /bp/data/environment_build)
  getNthTextInALine "$DOCKERFILE_ENTRY" : 1
}

function saveTaskStatus() {
  TASK_STATUS="$1"
  ACTIVITY_SUB_TASK_CODE="$2"  

  if [ "$TASK_STATUS" -eq 0 ]
  then
    logInfoMessage "Congratulations ${ACTIVITY_SUB_TASK_CODE} succeeded!!!"
    generateOutput "${ACTIVITY_SUB_TASK_CODE}" true "Congratulations ${ACTIVITY_SUB_TASK_CODE} succeeded!!!"
  elif [ "$VALIDATION_FAILURE_ACTION" == "FAILURE" ]
    then
      logErrorMessage "Please check ${ACTIVITY_SUB_TASK_CODE} failed!!!"
      generateOutput "${ACTIVITY_SUB_TASK_CODE}" false "Please check ${ACTIVITY_SUB_TASK_CODE} failed!!!"
      exit 1
    else
      logWarningMessage "Please check ${ACTIVITY_SUB_TASK_CODE} failed!!!"
      generateOutput "${ACTIVITY_SUB_TASK_CODE}" true "Please check ${ACTIVITY_SUB_TASK_CODE} failed!!!"
  fi
}

function getDecryptedCredential() {
    local fernet_key="$1"
    local encrypted_value="$2"

    python3 -c "
from cryptography.fernet import Fernet

fernet_key = '$fernet_key'
f = Fernet(fernet_key.encode('utf-8'))
encrypted_value = b'$encrypted_value'

try:
    decrypted_value = f.decrypt(encrypted_value)
    print(decrypted_value.decode())
except Exception as e:
    print(f'Decryption error: {e}')
"
}

function passwordStrengthChecker() {
    local password="$1"
    local len=${#password}

    if [ "${#password}" -ge 8 ] &&  [[ $password == *[A-Za-z]* ]] &&  [[ $password == *[0-9]* ]] && [[ $password == *['#?!@$\ %^\&*-']* ]]
    then
      logInfoMessage ''
    else
      logErrorMessage "Weak password. Please ensure the password meets the criteria: at least 8 characters, one uppercase letter, one lowercase letter, one digit, and one special character."
      exit 1
    fi
}

function validDBname() {
    local db_name="$1"

    # Check if the database name is not empty
    if [ -z "$db_name" ]; then
        logErrorMessage "Database name cannot be empty."
        exit 1
    fi

    # Check if the database name contains invalid characters
    if echo "$db_name" | grep -q -E '[^a-zA-Z0-9_\-]'; then
        logErrorMessage "Invalid characters in the database name. Only alphanumeric characters, underscore (_), and hyphen (-) are allowed."
        exit 1
    fi
}

function getEncryptedCredential() {
    local credentialManagement="$1"
    local credentialKey="$2"

    echo "$(echo "$credentialManagement" | jq -r ".$credentialKey")"
}

function mysqlcheckDatabaseConnection() {
    local username="$1"
    local password="$2"
    local host="$3"

    mysql -u "$username" -p"$password" -h "$host" -e "SELECT 1;" || {
        logErrorMessage "Failed to login to the database server. Check your credentials and connection."
        exit 1
    }
}

function mysqlcreateDatabase() {
    local username="$1"
    local password="$2"
    local host="$3"
    local dbName="$4"

    mysql -u "$username" -p"$password" -h "$host" -e "CREATE DATABASE $dbName;" || {
        logErrorMessage "Failed to create the database."
        exit 1
    }
}

function mysqlcreateUser() {
    local username="$1"
    local password="$2"
    local host="$3"
    local dbName="$4"
    local userName="$5"
    local userPassword="$6"

    mysql -u "$username" -p"$password" -h "$host" -e "CREATE USER '$userName'@'$host' IDENTIFIED BY '$userPassword';" || {
        logErrorMessage "Failed to create the user [$userName]."
        exit 1
    }
}

function mysqlgrantPrivileges() {
    local username="$1"
    local password="$2"
    local host="$3"
    local dbName="$4"
    local userName="$5"

    mysql -u "$username" -p"$password" -h "$host" -e "GRANT ALL PRIVILEGES ON $dbName.* TO '$userName'@'$host'; FLUSH PRIVILEGES;" || {
        logErrorMessage "Failed to give privileges to the user [$userName]."
        exit 1
    }
}

function mysqlcheckUserPrivileges() {
    local username="$1"
    local password="$2"
    local host="$3"
    local userName="$4"

    mysql -u "$username" -p"$password" -h "$host" -e "SHOW GRANTS FOR '$userName'@'$host';" || {
        logErrorMessage "Failed to check privileges for the user [$userName]."
        exit 1
    }
}

