#Assumption is caller will set all the required environment
function generateDIDataJson() {
    TEMPLATE_FILE=$1
    RESULTANT_FILE=$2

    envsubst < ${TEMPLATE_FILE} > ${RESULTANT_FILE}
}

function sendDIData() {
    DATA_FILE=$1


    response=$(curl -X POST -H "Content-Type: application/json" -d "{\"email\": \"$USER_NAME\", \"password\": \"$PASSWORD\"}" ${DI_SERVER}/api/v1/user/login/)
    TOKEN="$(echo $response | jq -r .access)"
    # Check if TOKEN is empty
    if [ -z "$TOKEN" ]; then
    echo "Token not found. Exiting..."
    exit 1
    fi

    # Make POST request with token
    curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @${DATA_FILE} ${BP_API_URL}/api/v1/maturity_dashboard/deploy_insights_post_data/



}


# Function to fetch sub-tasks and construct JSON
fetch_sub_tasks() {
    local json_file=$1
    local sub_tasks_length=$(jq '.["sub-tasks"] | length' "$json_file")
    local json_objects=()

    for ((i=0; i<sub_tasks_length; i++)); do
        local feature_ticket_id=$(jq -r --argjson i "$i" '.["sub-tasks"][$i].key' "$json_file")
        local description=$(jq -r --argjson i "$i" '.["sub-tasks"][$i].fields.status.description' "$json_file")
        if [ -z "$description" ]; then
            description="NA"
        fi

        local json_object="{ \"feature_ticket_id\": \"${feature_ticket_id}\", \"description\": \"${description}\" }"
        json_objects+=("$json_object")

        if [ $i -lt $((sub_tasks_length - 1)) ]; then
            json_objects+=(",")
        fi
    done

    echo "${json_objects[*]}"
}

# Function to fetch services and construct JSON
fetch_services() {
    local json_file=$1
    local services=$(jq -r '.service[] | .value' "$json_file")
    local services_length=$(jq '.service | length' "$json_file")
    local service_json_objects=()

    IFS=$'\n' read -rd '' -a services_array <<< "$services"

    for service in "${services_array[@]}"; do
        local service_json="{ \"service_name\": \"$service\", \"business_function_tags\": [] }"
        service_json_objects+=("$service_json")

        if [[ "$service" != "${services_array[-1]}" ]]; then
            service_json_objects+=(",")
        fi
    done

    echo "${service_json_objects[*]}"
}
fetch_change_ticket_id() {
    local json_file=$1
    local change_ticket_id=$(jq -r '.["stage.create ticket.job.job_1.jira_id.key"]' "$json_file")
    
    echo "$change_ticket_id"

}

fetch_change_ticket_id_description() {
    local json_file=$1
    local change_ticket_id_description=$(jq -r '.["description"]' "$json_file")

    echo "$change_ticket_id_description"
}

fetch_application_name() {
    local json_file=$1  
    local application_name=$(jq -r '.["jira_step_data"].application.value' "$json_file")

    echo "$application_name"
}
