#!/bin/bash

USERID=$(id -u)
R="\e[33m"
G="\e[32"
Y="\e[31"
N="\e[0"

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

dnf install python3 gcc python3-devel -y &>>"$LOGS_FILE"
VALIDATE "$?" "Install Python 3"

id roboshop
if [ "$?" -ne 0 ]; then
	useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
	echo -e " $G Adding application User ...................Skipping $N" | tee -a "$LOGS_FILE"
else
	echo -e " USER Already Added $Y ...................Skipping $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app  &>>"$LOGS_FILE"
VALIDATE "$?" " Lets setup an app directory."

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>"$LOGS_FILE"  
cd /app || exit  &>>"$LOGS_FILE"
unzip /tmp/payment.zip  &>>"$LOGS_FILE"
VALIDATE "$?" "Download the application code to created app directory"

cd /app || exit &>>"$LOGS_FILE"
pip3 install -r requirements.txt  &>>"$LOGS_FILE"
VALIDATE "$?" "Lets download the dependencies."

cp "$SCRIPT_DIR/payment.service" "/etc/systemd/system/payment.service" &>>"$LOGS_FILE"
VALIDATE "$?" "Setup SystemD Payment Service"


systemctl daemon-reload  &>>"$LOGS_FILE"
VALIDATE "$?" "Load the service."

systemctl enable payment  &>>"$LOGS_FILE"
systemctl start payment  &>>"$LOGS_FILE"
VALIDATE "$?" "enable & start the service."

EXECUTE_TIME
