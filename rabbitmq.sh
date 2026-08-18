#!/bin/bash

USERID=$(id -u)
R="\e[31m"  # Red
G="\e[32m"  # Green
Y="\e[33m"  # Yellow
N="\e[0m"   # Reset

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME="$(echo "$0" | cut -d "." -f1)"
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

SCRIPT_DIR=$(pwd)
START_TIME=$(date +%s)


if [ "$USERID" -ne 0 ]; then
	echo -e " $R ERROR:: Please run this script with root Privelege $N " | tee -a "$LOGS_FILE"
	exit 1
fi

VALIDATE(){
	if [ "$1" -ne 0 ]; then
		echo -e "$2 $R ....................FAILURE $N" | tee -a "$LOGS_FILE"
		exit 1
	else
		echo -e "$2 $G ....................SUCCESS $N" | tee -a "$LOGS_FILE"
	fi
}

EXECUTE_TIME(){
	END_TIME="$(date +%s)"
	TOTAL_TIME=$(("$END_TIME" - "$START_TIME"))
	echo -e "Script Executed Time In Seconds : $Y $TOTAL_TIME $N" | tee -a "$LOGS_FILE" 
}


cp "$SCRIPT_DIR"/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>"$LOGS_FILE"
VALIDATE $? "Adding RabbitMQ repo"


dnf install rabbitmq-server -y &>>"$LOGS_FILE"
VALIDATE "$?" " Installing rabbitmq server "

systemctl enable rabbitmq-server &>>"$LOGS_FILE"
systemctl start rabbitmq-server &>>"$LOGS_FILE"
VALIDATE "$?" "Start & Enable rabbitmq server"

rabbitmqctl add_user roboshop roboshop123 &>>"$LOGS_FILE"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>"$LOGS_FILE"
VALIDATE $? "Setting up permissions"

EXECUTE_TIME