#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/logs/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1 )
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(PWD)
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a "$LOGS_FILE"

if [ "$USERID" -ne 0 ]; then
	echo -e "ERROR:: $R Please run this script with root privelege $N " | tee -a "$LOGS_FILE"
	exit 1
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e "$2 ... $R FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e "$2 ... $G SUCCESS $N" | tee -a "$LOGS_FILE"
	fi	
}

print_total_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( "$END_TIME" - "$START_TIME" ))
    echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N" | tee -a "$LOGS_FILE"
}


cp "$SCRIPT_DIR"/mongo.repo  /etc/yum.repos.d/mongo.repo  &>>"$LOGS_FILE"
VALIDATE "$?" "Adding Mongo repo"

dnf install mongodb-org -y  &>>"$LOGS_FILE" 
VALIDATE "$?" "Installing Mongodb service"

systemctl enable mongod  &>>"$LOGS_FILE" 
systemctl start mongod  &>>"$LOGS_FILE"  
VALIDATE "$?" "Start & enable Mongodb service"


sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf  &>>"$LOGS_FILE"
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod  &>>"$LOGS_FILE"
VALIDATE "$?" "Restart Mongodb service"

print_total_time

