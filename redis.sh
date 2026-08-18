#!/bin/bash

USERID=$(id -u)
R="\e[31m"  # Red
G="\e[32m"  # Green
Y="\e[33m"  # Yellow
N="\e[0m"   # Reset

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo "$0" | cut -d "." -f1 )
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
start_time="$(date +%s)"

mkdir -p "$LOGS_FOLDER"
echo "Script started executed at: $(date)" | tee -a "$LOGS_FILE"


if [ "$USERID" -ne 0 ]; then
	echo "$R ERROR:: Please RUN with root privelage $N"
	exit 1
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e " $2 $R ...........................FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e " $2 $G ...........................SUCCESS $N" | tee -a "$LOGS_FILE"
	fi
}

print_total_time(){
	end_time="$(date +%s)"
	total_time="$end_time - $start_time"
	echo -e "script executed time : $Y $total_time seconds $N"
}

dnf module disable redis -y  &>>"$LOGS_FILE"
VALIDATE "$?" "module disabling "

dnf module enable redis:7 -y  &>>"$LOGS_FILE"
VALIDATE "$?" "module enabling "

dnf install redis -y  &>>"$LOGS_FILE"
VALIDATE "$?" "installing redis module "

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf  &>>"$LOGS_FILE"
VALIDATE $? "Allowing Remote connections to Redis"

systemctl enable redis  &>>"$LOGS_FILE"
systemctl start redis  &>>"$LOGS_FILE"
VALIDATE "$?" "Start & Enable Redis Service"

print_total_time