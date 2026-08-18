#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-03b82330a83a2ba79"
H_ZONE_ID="Z1007411AWVOBZQ97XGF"
DOMAIN_NAME="prasaddev.shop"

for instance in "$@"
do
    # Instance create చేసి ID తీసుకోవడం
    Instance_ID=$( aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text )

    # Instance running అయ్యే వరకు wait చేయడం
    aws ec2 wait instance-running --instance-ids "$Instance_ID"

    # Private IP తీసుకోవడం
    Private_IP=$( aws ec2 describe-instances \
        --instance-ids "$Instance_ID" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text )

    # Public IP తీసుకోవడం
    Public_IP=$( aws ec2 describe-instances \
        --instance-ids "$Instance_ID" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text )

    RECORD_NAME="$instance.$DOMAIN_NAME"

    echo "$instance: PrivateIP=$Private_IP | PublicIP=$Public_IP"

    # Route53 లో DNS record update చేయడం (Private IP ని point చేస్తుంది)
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
                    \"ResourceRecords\": [{ \"Value\": \"$Private_IP\" }]
              }
            }]
      }"
done
