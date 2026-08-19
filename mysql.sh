#!/bin/bash

USERID=$(id -u)
R="\e[33m"
G="\e[32m"
Y="\e[31m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-shop"
SCRIPT_NAME="$( echo "$0" | cut -d "." -f1)"
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME="$(date +%s)"

mkdir -p $LOGS_FOLDER
echo -e "Started execuation at : $Y $(date) $N" | tee -a "$LOGS_FILE"


if [ "$USERID" -ne 0 ]; then
    echo -e "ERROR::Please run this script with root privelege $N" | tee -a "$LOGS_FILE"
    exit 1
fi


VALIDATE(){
    if [ "$1" -ne 0 ]; then
        echo -e "$2 $R .................FAILURE $N" | tee -a "$LOGS_FILE"
        exit 1
    else
        echo -e "$2 $G .................SUCCESS $N" | tee -a "$LOGS_FILE"
    fi
}

EXECUTED_TIME(){
    END_TIME="$(date +%s)"
    TOTAL_TIME=$(("$END_TIME" - "$START_TIME"))
    echo -e "Total Executed Time : $TOTAL_TIME "
}

dnf install mysql-server -y &>>"$LOGS_FILE"
VALIDATE "$?" "Install MySQL Server"

systemctl enable mysqld &>>"$LOGS_FILE"
VALIDATE "$?" "enable MySQL Service"

systemctl start mysqld &>>"$LOGS_FILE" 
VALIDATE "$?" "Start MySQL Service"

mysql_secure_installation --set-root-pass RoboShop@1 &>>"$LOGS_FILE"
VALIDATE "$?" "changing the default root password"

EXECUTED_TIME