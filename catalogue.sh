#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/logs/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(PWD)
app_name=catalogue
MONGODB_HOST="mongodb.prasaddev.shop"


mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a "$LOGS_FILE"

if [ "$USERID" -ne 0 ]; then
	echo -e "ERROR:: $R Please run this script with root privelege $N "
	exit 1
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e "$2 ... $R FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e "$2 ... $G SUCCESS $N " | tee -a "$LOGS_FILE"
	fi
}

print_total_time(){
	START_TIME=$(date +%s)
    END_TIME=$(date +%s)
    TOTAL_TIME=$((END_TIME-START_TIME))
    echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N" | tee -a "$LOGS_FILE"
}

dnf module disable nodejs -y &>>"$LOGS_FILE"
VALIDATE "$?" "Disable current module"

dnf module enable nodejs:20 -y &>>"$LOGS_FILE"
VALIDATE "$?" "Enable required module"

dnf install nodejs -y &>>"$LOGS_FILE"
VALIDATE "$?" "Install NodeJS"

id roboshop &>>"$LOGS_FILE"
if [ "$?" -ne 0 ]; then
	useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
	VALIDATE "$?" "Creating System User"
else
	echo -e "User Alredy Exist .......$Y SKIPPING $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app &>>"$LOGS_FILE"
VALIDATE "$?" "Lets setup an app directory."

curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>"$LOGS_FILE"
cd /app || exit &>>"$LOGS_FILE"

VALIDATE "$?" "Download the application code to created app directory."

unzip /tmp/$app_name.zip &>>"$LOGS_FILE"
VALIDATE "$?" "Unzip catalouge"

cd /app || exit
npm install &>>"$LOGS_FILE"
VALIDATE "$?" "Lets downloading the dependencies."

cp "$SCRIPT_DIR/$app_name.service" /etc/systemd/system/$app_name.service

systemctl daemon-reload &>>"$LOGS_FILE"
VALIDATE "$?" "Load the service."

systemctl enable $app_name &>>"$LOGS_FILE"
systemctl start $app_name &>>"$LOGS_FILE"
VALIDATE "$?" "Start & Enable $app_name service"

cp "$SCRIPT_DIR/mongodb.repo" "/etc/yum.repos.d/mongo.repo" &>>"$LOGS_FILE"
VALIDATE "$?" "Installing mongodb-client service"

dnf install mongodb-mongosh -y &>>"$LOGS_FILE"
VALIDATE "$?" "installing client mongodb-service"

INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ "$INDEX" -le 0 ]; then
    mongosh --host "$MONGODB_HOST" </app/db/master-data.js &>>"$LOGS_FILE"
    VALIDATE $? "Load $app_name products"
else
    echo -e "$app_name products already loaded ... $Y SKIPPING $N" | tee -a "$LOGS_FILE"
fi

systemctl restart $app_name &>>"$LOGS_FILE"
VALIDATE "$?" "retart $app_name service"

print_total_time
