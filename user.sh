#!/bin/bash

USERID=$(id -u)
R="\e[31m"  # Red
G="\e[32m"  # Green
Y="\e[33m"  # Yellow
N="\e[0m"   # Reset

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1 )
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(pwd)
START_TIME="$(date +%s)"

mkdir -p $LOGS_FOLDER
echo -e "Script Started Executed at : $(date)" | tee -a "$LOGS_FILE"


if [ "$USERID" -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e "$2 $R................................FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e "$2 $G................................SUCCESS $N" | tee -a "$LOGS_FILE"
	fi
}

EXECUTE_TIME(){
	END_TIME="$(date +%s)"
	TOTAL_TIME=$(( "$END_TIME" - "$START_TIME" ))
	echo -e "Script executed time in seconds : $Y $TOTAL_TIME Seconds $N" | tee -a "$LOGS_FILE"	
}

dnf module disable nodejs -y &>>"$LOGS_FILE"
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y  &>>"$LOGS_FILE"
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>"$LOGS_FILE"
VALIDATE "$?" "Installing NodeJS"

id roboshop &>>"$LOGS_FILE"

if [ "$?" -ne 0 ]; then
	useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
	VALIDATE "$?" "Adding System User"
else
	echo -e "User Already Added $Y ............SKIPPING $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app 
VALIDATE "$?" "create App Directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "Downloading user application"

cd /app || exit 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>"$LOGS_FILE"
VALIDATE "$?" "Unzip the user"

npm install &>>"$LOGS_FILE"
VALIDATE "$?" "Lets download the dependencies."

cp "$SCRIPT_DIR/user.service" "/etc/systemd/system/user.service"
VALIDATE "$?" "Setup SystemD User Service"

systemctl daemon-reload
VALIDATE "$?" "Load the service."

systemctl enable user &>>"$LOGS_FILE"
systemctl restart user &>>"$LOGS_FILE"
VALIDATE "$?" "Start the service."

EXECUTE_TIME


