#!/bin/bash

MINECRAFTDIR=/opt/minecraft/server
WORLD_DIR="$MINECRAFTDIR/world"
BACKUP="$MINECRAFTDIR/world.tar.gz"
BUCKET="jas-minecraft-server-backup"
REGION="eu-west-2"
EMPTY_SECONDS_BEFORE_SHUTDOWN=120
EMPTY_TIMESTAMP_FILE="/tmp/minecraft-empty-timestamp"
MC_SERVER_HOST=127.0.0.1
MC_SERVER_PORT=25565  # the server port in server.properties

echo "$(date): Starting continuous shutdown checker."

while true; do
	PLAYERS=$(mcstatus "$MC_SERVER_HOST:$MC_SERVER_PORT" query 2>/dev/null | grep -oP '^players: \K\d+')
	PLAYERS=${PLAYERS:-0}  # fallback to 0 if empty

    echo "$(date): Players=$PLAYERS"

    if [ "$PLAYERS" -gt 0 ]; then
		echo "Players present, removing timestamp file"
        rm -f $EMPTY_TIMESTAMP_FILE
    else
        if [ ! -f $EMPTY_TIMESTAMP_FILE ]; then
			echo "No timestamp file found, creating one"
            date +%s > $EMPTY_TIMESTAMP_FILE
        else
            EMPTY_SINCE=$(cat $EMPTY_TIMESTAMP_FILE)
            NOW=$(date +%s)
            DIFF=$((NOW - EMPTY_SINCE))
			REMAINING=$((EMPTY_SECONDS_BEFORE_SHUTDOWN - DIFF))
			echo "Empty for $DIFF sec, shutting down in $REMAINING sec if still empty"

            if [ "$DIFF" -ge "$EMPTY_SECONDS_BEFORE_SHUTDOWN" ]; then
                echo "Server empty. Backing up and shutting down..."

                tar -czf $BACKUP $WORLD_DIR
                aws s3 cp $BACKUP s3://$BUCKET/world-latest.tar.gz --region $REGION

                INSTANCE_ID=$(aws ec2 describe-instances \
                  --filters "Name=tag:ServerType,Values=minecraft-automatic-shutdown" \
                  --query "Reservations[].Instances[].InstanceId" \
                  --output text)
                #aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
                exit 0
            fi
        fi
    fi

    sleep 10
done
