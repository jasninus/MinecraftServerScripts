#!/bin/bash
# /opt/minecraft/scripts/shutdown_if_empty.sh
# Continuously check Minecraft server and shut down if empty for threshold

MINECRAFTDIR=/opt/minecraft/server
WORLD_DIR="$MINECRAFTDIR/world"
BACKUP="$MINECRAFTDIR/world.tar.gz"
BUCKET="jas-minecraft-server-backup"
REGION="eu-west-2"
EMPTY_TIMESTAMP_FILE="/tmp/minecraft-empty-timestamp"
EMPTY_SECONDS_BEFORE_SHUTDOWN=120
CHECK_INTERVAL=10

# Require mcstatus
command -v mcstatus >/dev/null 2>&1 || {
    echo "mcstatus not installed. Install it via pip."
    exit 1
}

echo "$(date): Starting continuous shutdown checker."

while true; do
    # Get player count
    PLAYERS=$(mcstatus localhost:25565 query 2>/dev/null | grep -oP 'Players online: \K\d+')
    PLAYERS=${PLAYERS:-0}

    echo "$(date): Checking if any players are online. Players=$PLAYERS"

    if [ "$PLAYERS" -gt 0 ]; then
        echo "Players online, clearing empty timestamp."
        rm -f "$EMPTY_TIMESTAMP_FILE"
    else
        echo "No players online."
        if [ ! -f "$EMPTY_TIMESTAMP_FILE" ]; then
            echo "Creating empty timestamp."
            date +%s > "$EMPTY_TIMESTAMP_FILE"
        else
            EMPTY_SINCE=$(cat "$EMPTY_TIMESTAMP_FILE")
            NOW=$(date +%s)
            DIFF=$((NOW - EMPTY_SINCE))

            if [ "$DIFF" -ge "$EMPTY_SECONDS_BEFORE_SHUTDOWN" ]; then
                echo "Server empty for $EMPTY_SECONDS_BEFORE_SHUTDOWN seconds. Backing up and shutting down..."

                # Save world
                screen -S minecraft -p 0 -X stuff "save-all\n"
                sleep 5

                # Compress
                tar -czf "$BACKUP" "$WORLD_DIR"

                # Upload
                aws s3 cp "$BACKUP" "s3://$BUCKET/world-latest.tar.gz" --region "$REGION"

                # Terminate instance
                INSTANCE_ID=$(aws ec2 describe-instances \
                    --filters "Name=tag:ServerType,Values=minecraft-automatic-shutdown" \
                    --query "Reservations[].Instances[].InstanceId" \
                    --output text)
                echo "Terminating instance $INSTANCE_ID"
                #aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region "$REGION"
                exit 0
            else
                REMAIN=$((EMPTY_SECONDS_BEFORE_SHUTDOWN - DIFF))
                echo "Server has been empty for $DIFF seconds, waiting $REMAIN more seconds before shutdown."
            fi
        fi
    fi

    sleep "$CHECK_INTERVAL"
done