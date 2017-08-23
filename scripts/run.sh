#!/usr/bin/env bash
set -e

# Setup

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OUTPUT_DIR="../."
if [ $# -eq 2 ]
then
    OUTPUT_DIR=$2
fi

DOCKER_DIR=$DIR/../docker
if [ $# -eq 3 ]
then
    DOCKER_DIR=$3
fi

OS="linux"
if [ "$(uname)" == "Darwin" ]
then
    OS="macwin"
fi

# Functions

function dockerComposeUp() {
    docker-compose -f $DOCKER_DIR/docker-compose.yml -f $DOCKER_DIR/docker-compose.$OS.yml up -d
}

function dockerComposeDown() {
    docker-compose -f $DOCKER_DIR/docker-compose.yml -f $DOCKER_DIR/docker-compose.$OS.yml down
}

function dockerPrune() {
    docker image prune -f
}

function updateLetsEncrypt() {
    if [ -d "${outputDir}/letsencrypt/live" ]
    then
        docker run -it --rm --name certbot -p 443:443 -p 80:80 -v $OUTPUT_DIR/letsencrypt:/etc/letsencrypt/ certbot/certbot \
            renew --logs-dir /etc/letsencrypt/logs
    fi
}

function updateDatabase() {
    docker run -it --rm --name setup --network container:mssql -v $OUTPUT_DIR:/bitwarden bitwarden/setup \
        dotnet Setup.dll -update 1 -db 1
    echo "Database update complete"
}

# Commands

if [ "$1" == "start" -o "$1" == "restart" ]
then
    dockerComposeDown
    updateLetsEncrypt
    dockerComposeUp
    dockerPrune
elif [ "$1" == "stop" ]
then
    dockerComposeDown
elif [ "$1" == "upadtedb" ]
then
    updateDatabase
fi