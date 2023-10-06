FROM alpine:latest

# Environment variables
ENV MC_VERSION="latest" \
    PAPER_BUILD="latest" \
    MC_RAM="" \
    JAVA_OPTS=""

COPY papermc.sh .
RUN apk update \
    && apk add openjdk17-jre \
    && apk add bash \
    && apk add wget \
    && apk add jq \
    && mkdir /papermc \
    && rm -rf /var/cache/apk/*

# Start script
CMD ["bash", "./papermc.sh"]

# Container setup
EXPOSE 25565
VOLUME /papermc