#!/bin/bash

USERID=$(id -u)
R="\e[33m"
G="\e[32m"
Y="\e[31m"
R="\e[0m"

LOGS_FOLDER="/var/logs/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%S)

SCRIPT_DIR=$(pwd)
mkdir -p $LOGS_FOLDER
echo -e "Project Executed at : $(date)"

if [ "$USERID" -ne 0 ]; then
	echo -e "ERROR:: Please run this script with root privelege" | tee -a "$LOGS_FILE"
	exit 1
fi

VALIDATE(){
	if [ "$?" -ne 0 ]; then
		echo -e "$2 $R .........................FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e "$2 $G .........................SUCCESS $N" | tee -a "$LOGS_FILE"
	fi
}

EXECUTED_TIME(){
	END_TIME="$(date +%S)"
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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>"$LOGS_FILE"
cd /app || exit  &>>"$LOGS_FILE"
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

mysql -h "$MYSQL_HOST" -uroot -pRoboShop@1 < /app/db/schema.sql  &>>"$LOGS_FILE"
VALIDATE "$?" "Load Schema"

mysql -h "$MYSQL_HOST" -uroot -pRoboShop@1 < /app/db/app-user.sql &>>"$LOGS_FILE"
VALIDATE "$?" "Create App User "

mysql -h "$MYSQL_HOST" -uroot -pRoboShop@1 < /app/db/master-data.sql  &>>"$LOGS_FILE"
VALIDATE "$?" "Load The Master Data" 

systemctl restart shipping  &>>"$LOGS_FILE"
VALIDATE "$?" "Restart Shipping Service"

EXECUTED_TIME