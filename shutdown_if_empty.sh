#!/bin/bash
# /opt/minecraft/scripts/shutdown_if_empty.sh

MINECRAFTDIR=/opt/minecraft/server
WORLD_DIR="$MINECRAFTDIR/world"
BACKUP="$MINECRAFTDIR/world.tar.gz"
BUCKET="jas-minecraft-server-backup"
REGION="eu-west-2"
EMPTY_TIMESTAMP_FILE="/tmp/minecraft-empty-timestamp"
EMPTY_SECONDS_BEFORE_SHUTDOWN=120

# -------------------------------
# Capture Minecraft screen output
# -------------------------------
SCREEN_TMP=$(mktemp)
screen -S minecraft -p 0 -X hardcopy "$SCREEN_TMP"

# Extract number of players from last "There are X players" line
PLAYERS=$(grep -oP 'There are \K\d+' "$SCREEN_TMP" | tail -1)
PLAYERS=${PLAYERS:-0}

rm -f "$SCREEN_TMP"

echo "$(date): Checking if any players are online. Players=$PLAYERS"

# -------------------------------
# If players are online, reset timer
# -------------------------------
if [ "$PLAYERS" -gt 0 ]; then
    echo "Players online, clearing empty timestamp."
    rm -f $EMPTY_TIMESTAMP_FILE
    exit 0
fi

# -------------------------------
# No players online
# -------------------------------
echo "No players online."

if [ ! -f $EMPTY_TIMESTAMP_FILE ]; then
    echo "Creating empty timestamp."
    date +%s > $EMPTY_TIMESTAMP_FILE
    exit 0
fi

# -------------------------------
# Check how long server has been empty
# -------------------------------
EMPTY_SINCE=$(cat $EMPTY_TIMESTAMP_FILE)
NOW=$(date +%s)
DIFF=$((NOW - EMPTY_SINCE))

if [ "$DIFF" -ge $EMPTY_SECONDS_BEFORE_SHUTDOWN ]; then
    echo "Server empty for $DIFF seconds. Backing up and shutting down..."

    # Save world
    screen -S minecraft -p 0 -X stuff "save-all\n"
    sleep 5

    # Compress
    tar -czf $BACKUP $WORLD_DIR

    # Upload
    aws s3 cp $BACKUP s3://$BUCKET/world-latest.tar.gz --region $REGION

    # Terminate instance
    INSTANCE_ID=$(aws ec2 describe-instances \
      --filters "Name=tag:ServerType,Values=minecraft-automatic-shutdown" \
      --query "Reservations[].Instances[].InstanceId" \
      --output text)
    echo "Terminating instance $INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
else
    REMAIN=$((EMPTY_SECONDS_BEFORE_SHUTDOWN - DIFF))
    echo "Server has been empty for $DIFF seconds, waiting $REMAIN more seconds before shutdown."
fi