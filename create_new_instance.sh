#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-03b82330a83a2ba79"
H_ZONE_ID="Z1007411AWVOBZQ97XGF"
DOMAIN_NAME="prasaddev.shop"

for instance in "$@"
do
    Instance_ID=$( aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text )

    # Wait until instance is running
    aws ec2 wait instance-running --instance-ids "$Instance_ID"

    # Fetch IP
    if [ "$instance" != "frontend" ]; then
        IP=$( aws ec2 describe-instances \
            --instance-ids "$Instance_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text )
    else
        IP=$( aws ec2 describe-instances \
            --instance-ids "$Instance_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text )
    fi

    RECORD_NAME="$instance.$DOMAIN_NAME"
    echo "$instance: $IP"

    # Update DNS record
    aws route53 change-resource-record-sets \
      --hosted-zone-id $H_ZONE_ID \
      --change-batch "{
            \"Comment\": \"Updating Record Set\",
            \"Changes\": [{
              \"Action\": \"UPSERT\",
              \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 300,
                    \"ResourceRecords\": [{ \"Value\": \"$IP\" }]
              }
            }]
      }"
done
