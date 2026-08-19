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

MYSQL_HOST="mysql.prasaddev.shop"

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


dnf install maven -y  &>>"$LOGS_FILE"
VALIDATE "$?" "Installing Maven"

id roboshop  &>>"$LOGS_FILE"
if [ "$?" -ne 0 ]; then
	useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>"$LOGS_FILE"
	echo -e "$G ......................Adding application User $N" | tee -a "$LOGS_FILE"
else
	echo -e "$Y ......................USER Already Exist $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app  &>>"$LOGS_FILE"
VALIDATE "$?" "Lets setup an app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>"$LOGS_FILE"
VALIDATE $? "Downloading shipping application"


cd /app || exit  &>>"$LOGS_FILE"
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip  &>>"$LOGS_FILE"
VALIDATE "$?" "Download the application code to created app directory."

cd /app || exit  &>>"$LOGS_FILE"
mvn clean package  &>>"$LOGS_FILE"
mv target/shipping-1.0.jar shipping.jar  &>>"$LOGS_FILE"
VALIDATE "$?" "Lets download the dependencies & build the application"

cp "$SCRIPT_DIR"/shipping.service "/etc/systemd/system/shipping.service"  &>>"$LOGS_FILE"
VALIDATE "$?" "Setup SystemD Shipping Service"

systemctl daemon-reload  &>>"$LOGS_FILE"
VALIDATE "$?" "Load the service."

systemctl enable shipping  &>>"$LOGS_FILE"
VALIDATE "$?" "enable the service."

systemctl start shipping  &>>"$LOGS_FILE"
VALIDATE "$?" "start the service."


dnf install mysql -y  &>>"$LOGS_FILE"
VALIDATE "$?" "Installing Mysql Server"


mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql

systemctl restart shipping  &>>"$LOGS_FILE"
VALIDATE "$?" "Restart Shipping Service"

EXECUTED_TIME