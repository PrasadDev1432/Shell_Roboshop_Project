#!/bin/bash

USERID=$(id -u)
R="\e[31m"  # Red
G="\e[32m"  # Green
Y="\e[33m"  # Yellow
N="\e[0m"   # Reset


LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME="$(date +%s)"
SCRIPT_DIR=$(pwd)

mkdir -p $LOGS_FOLDER
echo -e "Project Executed at : $(date)"


if [ "$USERID" -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e "$2 $R .................FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e "$2 $G .................SUCCESS $N" | tee -a "$LOGS_FILE"
	fi
}

EXECUTE_TIME(){
	END_TIME="$(date +%s)"
	TOTAL_TIME=$(("$END_TIME" - "$START_TIME"))
	echo -e "Script executed time : $Y $TOTAL_TIME Seconds $N" | tee -a "$LOGS_FILE"	
}

{
dnf module disable nodejs -y 
dnf module enable nodejs:20 -y
dnf install nodejs -y
}&>>"$LOGS_FILE"
VALIDATE "$?" "Installing NodeJS"

id roboshop
if [ "$?" -ne 0 ]; then
	useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
	VALIDATE "$?" "Add application User"
else
	echo -e "System User Already Added" | tee -a "$LOGS_FILE"
fi

mkdir -p /app &>>"$LOGS_FILE"
VALIDATE "$?" "Lets setup an app directory."


curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>"$LOGS_FILE"
cd /app || exit &>>"$LOGS_FILE"
unzip /tmp/cart.zip &>>"$LOGS_FILE"
VALIDATE "$?" "Download the application code to created app directory."

cd /app || exit &>>"$LOGS_FILE"
npm install  &>>"$LOGS_FILE"
VALIDATE "$?" "Lets download the dependencies."

cp "$SCRIPT_DIR"/cart.service /etc/systemd/system/cart.service &>>"$LOGS_FILE"
VALIDATE "$?" "Setup SystemD Cart Service"

systemctl daemon-reload &>>"$LOGS_FILE"
VALIDATE "$?" "Load the service."

systemctl enable cart &>>"$LOGS_FILE"
systemctl start cart &>>"$LOGS_FILE"
VALIDATE "$?" "Start & Enable the service."

EXECUTE_TIME

