function bucketExist() {
    BUCKET=$1

    BUCKET_EXISTS=$(aws s3api head-bucket --bucket $BUCKET 2>&1 || true)
    if [ -z "$BUCKET_EXISTS" ]; then
        echo 0
    else
        echo 1
    fi
}