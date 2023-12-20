#!/bin/bash

function getAzureServicePrinciple() {
    ARM_CLIENT_ID=$1
    ARM_CLIENT_SECRET=$2
    ARM_TENANT_ID=$3
    export ARM_CLIENT_ID="$ARM_CLIENT_ID"
    export ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET"
    export ARM_TENANT_ID="$ARM_TENANT_ID"
}