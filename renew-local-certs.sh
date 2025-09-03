#!/bin/bash

CERT_FILE="./certs/app.pk.pem"
DAYS_BEFORE_EXPIRY=30
LOGFILE="/var/log/mkcert-renewal.log"

# Function to check days until expiry
check_expiry() {
    if [ ! -f "$CERT_FILE" ]; then
        echo "Certificate not found"
        return 1
    fi

    expiry_date=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry_date" +%s)
    current_epoch=$(date +%s)
    days_left=$(( ($expiry_epoch - $current_epoch) / 86400 ))

    echo $days_left
}

# Check if renewal is needed
days_remaining=$(check_expiry)

if [ $? -eq 1 ] || [ $days_remaining -le $DAYS_BEFORE_EXPIRY ]; then
    echo "[$(date)] Certificate expires in $days_remaining days. Renewing..." >> $LOGFILE

    cd /path/to/your/project

    # Generate new certificates
    cd ./certs
    mkcert app.pk www.app.pk localhost 127.0.0.1 ::1
    mv app.pk+4.pem app.pk.pem 2>/dev/null || mv app.pk+*.pem app.pk.pem
    mv app.pk+4-key.pem app.pk-key.pem 2>/dev/null || mv app.pk+*-key.pem app.pk-key.pem

    # Reload nginx
    docker exec nginx-web nginx -s reload

    echo "[$(date)] Certificate renewed successfully" >> $LOGFILE
else
    echo "[$(date)] Certificate still valid for $days_remaining days" >> $LOGFILE
fi