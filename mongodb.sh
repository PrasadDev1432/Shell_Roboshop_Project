#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/logs/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(PWD)

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a "$LOG_FILE"

if [ "$USERID" -ne 0 ]; then
	echo -e "ERROR:: $R Please run this script with root privelege $N "
	exit 1
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e "$2 ... $R FAILURE $N" | tee -a "$LOG_FILE"
		exit 1
	else
		echo -e "$2 ... $G SUCCESS $N" | tee -a "$LOG_FILE"
	fi	
}

print_total_time(){
	START_TIME=$(date +%s)
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( $END_TIME - $START_TIME ))
    echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
}


cp "$SCRIPT_DIR"/mongo.repo  /etc/yum.repos.d/mongo.repo
VALIDATE "$?" "Adding Mongo repo"

dnf install mongodb-org -y 
VALIDATE "$?" "Installing Mongodb service"

systemctl enable mongod 
systemctl start mongod 
VALIDATE "$?" "Start & enable Mongodb service"


sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE "$?" "Restart Mongodb service"

print_total_time

