#Assumption is caller will set all the required environment
function generateMIDataJson() {
    TEMPLATE_FILE=$1
    RESULTANT_FILE=$2

    envsubst < ${TEMPLATE_FILE} > ${RESULTANT_FILE}
}

# function sendMIData() {
#     DATA_FILE=$1
#     MI_SERVER="$2"

#     curl -d "@${DATA_FILE}" -X POST  -H "Content-Type: application/json"  ${MI_SERVER}/api/v1/maturity_dashboard/maturity_metrices/
# }

function sendMIData() {
    DATA_FILE=$1
    MI_SERVER="$2"

    # Capture curl output and status
    RESPONSE=$(curl -d "@${DATA_FILE}" -X POST -H "Content-Type: application/json" "${MI_SERVER}/api/v1/maturity_dashboard/maturity_metrices/" 2>&1)
    STATUS=$?

    # Log the response and status
    echo "Sending data to ${MI_SERVER}"
    echo "Response: $RESPONSE"

    if [ $STATUS -ne 0 ]; then
        echo "Failed to send data. Status: $STATUS, Response: $RESPONSE"
    fi
}