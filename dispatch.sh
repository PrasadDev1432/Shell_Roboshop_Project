#!/bin/bash

USERID=$(id -u)
R="\e[31m"  # Red
G="\e[32m"  # Green
Y="\e[33m"  # Yellow
N="\e[0m"   # Reset

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)
SCRIPT_DIR=$(pwd)

mkdir -p $LOGS_FOLDER
echo -e "Project Executed at : $(date)"

if [ "$USERID" -ne 0 ]; then
	echo -e "ERROR:: Please run this script with root privelege" | tee -a "$LOGS_FILE"
	exit 1
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e "$2 $R .........................FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e "$2 $G .........................SUCCESS $N" | tee -a "$LOGS_FILE"
	fi
}

EXECUTED_TIME(){
	END_TIME="$(date +%s)"
	TOTAL_TIME="$(("$END_TIME" - "$START_TIME"))"
	echo -e "Total Executed Time In Seconds : $TOTAL_TIME"
}

dnf install golang -y &>>"$LOGS_FILE"
VALIDATE "$?" "Install GoLang"

id roboshop
if [ "$?" -ne 0 ]; then
	useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
	echo -e "$G ......................Adding application User $N" | tee -a "$LOGS_FILE"
else
	echo -e "$Y ......................USER Already Exist $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app &>>"$LOGS_FILE"
VALIDATE "$?" "Lets setup an app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip  &>>"$LOGS_FILE"
cd /app || exit 

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/dispatch.zip &>>"$LOGS_FILE"
VALIDATE "$?" "Download the application code to created app directory."

cd /app || exit &>>"$LOGS_FILE"
go mod init dispatch
go get &>>"$LOGS_FILE"
go build &>>"$LOGS_FILE"
VALIDATE "$?" "Lets download the dependencies & build the software."

cp "$SCRIPT_DIR/dispatch.service" "/etc/systemd/system/dispatch.service"  &>>"$LOGS_FILE"
VALIDATE "$?" "Setup SystemD Payment Service"


systemctl daemon-reload &>>"$LOGS_FILE"
VALIDATE "$?" "Load the service."

systemctl enable dispatch &>>"$LOGS_FILE"
systemctl start dispatch  &>>"$LOGS_FILE"
VALIDATE "$?" "Start  & Enable the service."

EXECUTED_TIME
