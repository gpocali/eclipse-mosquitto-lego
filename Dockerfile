FROM eclipse-mosquitto:openssl

USER root

RUN apk add --no-cache lego ca-certificates dcron sudo tzdata

COPY ./client.sh /bin/client.sh
RUN chmod 775 /bin/client.sh

COPY ./lego /etc/cron.d/lego
RUN chmod 600 /etc/cron.d/lego

# Expose the listening port of MQTT
EXPOSE 1883
EXPOSE 8883

ENTRYPOINT ["/bin/client.sh", "firstStart"]
