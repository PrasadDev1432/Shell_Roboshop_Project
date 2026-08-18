#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/logs/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1 )
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(pwd)
START_TIME=$(date +%s)

mkdir -p "$LOGS_FOLDER"
echo "Script started executed at: $(date)" | tee -a "$LOGS_FILE"

if [ "$USERID" -ne 0 ]; then
	echo -e " $R ERROR:: Please Run this script in root privelage $N " | tee -a "$LOGS_FILE"
	exit 1
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e "$2.............$R FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e "$2.............$G SUCCESS $N" | tee -a "$LOGS_FILE"
	fi
}

print_total_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( "$END_TIME" - "$START_TIME" ))
    echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N" | tee -a "$LOGS_FILE"
}

dnf module list nginx &>>"$LOGS_FILE"
VALIDATE "$?" "Checking nginx module list"

dnf module disable nginx -y &>>"$LOGS_FILE"
VALIDATE "$?" "disable nginx old module "

dnf module enable nginx:1.24 -y &>>"$LOGS_FILE"
VALIDATE "$?" "enable nginx required module"

dnf install nginx -y &>>"$LOGS_FILE"
VALIDATE "$?" "Installing.................. nginx"

systemctl enable nginx &>>"$LOGS_FILE"
VALIDATE "$?" "enable nginx service"

systemctl start nginx &>>"$LOGS_FILE"
VALIDATE "$?" "enable nginx service"

rm -rf /usr/share/nginx/html/* &>>"$LOGS_FILE"
VALIDATE "$?" "Remove the default content that web server is serving."

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>"$LOGS_FILE"
VALIDATE "$?" "Download the frontend content"

cd /usr/share/nginx/html || exit  &>>"$LOGS_FILE"
VALIDATE "$?" "chenging directory to frontend content path"

unzip /tmp/frontend.zip &>>"$LOGS_FILE"
VALIDATE "$?" "Unzip the frontend content"

rm -rf /etc/nginx/nginx.conf &>>"$LOGS_FILE"
cp "$SCRIPT_DIR"/nginx.conf /etc/nginx/nginx.conf &>>"$LOGS_FILE"
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx  &>>"$LOGS_FILE"
VALIDATE $? "Restarting Nginx"

print_total_time