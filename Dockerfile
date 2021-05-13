FROM eclipse-mosquitto:openssl

USER root

RUN apk add --no-cache lego ca-certificates dcron sudo

COPY ./client.sh /bin/client.sh
RUN chmod 775 /bin/client.sh
RUN chown node-red:root /bin/client.sh

COPY ./lego /etc/crontabs/lego
RUN chmod 600 /etc/crontabs/lego

# EXPOSE PORT FOR LEGO CHALLENGE
EXPOSE 1882

# Expose the listening port of MQTT
EXPOSE 1883
EXPOSE 8883

ENTRYPOINT ["/bin/client.sh", "firstStart"]