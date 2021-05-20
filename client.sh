#!/bin/ash
## LEGO CA Certificate Request

# TZ SET - Requires tzdata package
if [[ "$TZ" == "" ]]; then
    echo timezone not defined using ENV 'TZ', using UTC.
    TIMEZONE=UTC
else
    if [ -e /usr/share/zoneinfo/$TZ ]; then
        echo Using timezone: $TZ
        TIMEZONE=$TZ
    else
        echo Invalid timezone defined in input.conf file, using UTC.
        TIMEZONE=UTC
    fi
fi
cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo $TIMEZONE >  /etc/timezone

if [ ! -e /tmp/lego ]; then
    mkdir /tmp/lego
fi
ng=0
if [ ! -e /mosquitto/config/lego/certServer ]; then
    if [ ! -e /mosquitto/config/lego ]; then
        mkdir /mosquitto/config/lego
    fi
    touch /mosquitto/config/lego/certServer
fi
if [[ $(cat /mosquitto/config/lego/certServer | head -n 1) == "" ]]; then
    echo Enter the Certificate Server Address in /mosquitto/config/lego/certServer
    ng=1
fi
if [ ! -e /mosquitto/config/lego/email ]; then
    if [ ! -e /mosquitto/config/lego ]; then
        mkdir /mosquitto/config/lego
    fi
    touch /mosquitto/config/lego/email
fi
if [[ $(cat /mosquitto/config/lego/email | head -n 1) == "" ]]; then
    echo Enter the registration email in /mosquitto/config/lego/email
    ng=1
fi
if [ $ng -eq 1 ]; then
    echo Unsatisfied configuration files.  Cannot update certificates.
    exit 0
fi

if [ -e /mosquitto/config/ca_certificates/ca.crt ]; then
    cp -f /mosquitto/config/ca_certificates/ca.crt /usr/local/share/ca-certificates/root_ca.crt
    update-ca-certificates
else
    echo CA Certificate must be located at /mosquitto/config/ca_certificates/ca.crt.
    exit 0
fi

domain=$(nslookup $(ifconfig $(route | grep default | awk '{print $8}') | grep "inet addr" | awk '{print $2}' | cut -d: -f2) | grep name | awk '{print $4}')
certServer=$(cat /mosquitto/config/lego/certServer | head -n 1)
email=$(cat /mosquitto/config/lego/email | head -n 1)
lego -s "$certServer" -a -m "$email" --path /mosquitto/config/.lego -d "$domain" --tls --http-timeout 10 renew || \
lego -s "$certServer" -a -m "$email" --path /mosquitto/config/.lego -d "$domain" --tls --http-timeout 10 run
cp -f /mosquitto/config/.lego/certificates/$domain.crt /mosquitto/config/certs/server.crt
cp -f /mosquitto/config/.lego/certificates/$domain.key /mosquitto/config/certs/server.key

if [[ "$1" == "firstStart" ]]; then
    echo -n $(date) - First Start...
    crond -b -L /tmp/cron.log
    /docker-entrypoint.sh /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf
fi

exit 0
