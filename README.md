# lab-week3-aws-cli

## script1

```bash
#!/usr/bin/env bash

set -eu

# Variables
region="us-west-2"
key_name="bcitkey"
public_key_file="~/.ssh/bcitkey.pub" # Update this path if your public key is located elsewhere

# Check if the public key file exists
if [[ ! -f $public_key_file ]]; then
  echo "Error: Public key file $public_key_file not found."
  exit 1
fi

# Import the public key to AWS
aws ec2 import-key-pair \
  --key-name "$key_name" \
  --public-key-material "$(cat $public_key_file)" \
  --region "$region"

# Confirm success
echo "Key pair '$key_name' successfully imported into AWS."
```
