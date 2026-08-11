#!/bin/bash

# Create Instance and get the instance id

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

    # Create PublicIpAddress or PrivateIpAddress based on InstanceId
    if [ "$instance" != "frontend" ]; then
        IP=$( aws ec2 describe-instances \
            --instance-ids "$Instance_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text )
			RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$( aws ec2 describe-instances \
            --instance-ids "$Instance_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text )
			RECORD_NAME="$instance.$DOMAIN_NAME"
    fi

    echo "$instance: $IP"

	aws route53 change-resource-record-sets \
	  --hosted-zone-id $H_ZONE_ID \
	  --change-batch '
	  {
	  	"Comment": "Udating Record Set",
		"Changes": [{
		  "Action": "UPSERT",
		  "ResourceRecordSet": {
			"Name": "'"$RECORD_NAME"'",
			"Type": "A",
			"TTL": 1,
			"ResourceRecords": [{ "Value": "'$IP'" }]
		  }
		}]
	  }
	  '
done