#!/usr/bin/env bash

# Check if the number of command-line arguments is correct
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <bucket_name>"
    exit 1
fi

# Pass the bucket name as a positional parameter
bucket_name=$1

# Check if the bucket exists
if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
    echo "Bucket $bucket_name already exists."
else
    aws s3api create-bucket \
        --bucket "$bucket_name" \
        --region us-west-2 \
        --create-bucket-configuration LocationConstraint=us-west-2
    
    if [ $? -eq 0 ]; then
        echo "$bucket_name has been created successfully in us-west-2!"
    else
        echo "Failed to create bucket $bucket_name."
        exit 1
    fi
fi