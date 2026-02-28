#!/bin/bash
# /opt/minecraft/scripts/shutdown_if_empty.sh
MINECRAFTDIR=/opt/minecraft/server
WORLD_DIR="$MINECRAFTDIR/world"
BACKUP="$MINECRAFTDIR/world.tar.gz"
BUCKET="jas-minecraft-server-backup"
REGION="eu-west-2"
EMPTY_TIMESTAMP_FILE="/tmp/minecraft-empty-timestamp"

# Check for players
PLAYERS=$(screen -S minecraft -p 0 -X stuff "list\n" 2>/dev/null | grep -oP 'There are \K\d+')
PLAYERS=${PLAYERS:-0}

echo "$(date): Checking if any players are online. Players=$PLAYERS"

if [ "$PLAYERS" -gt 0 ]; then
    echo "Players online, clearing empty timestamp."
    rm -f $EMPTY_TIMESTAMP_FILE
    exit 0
fi

# No players online
echo "No players online."

if [ ! -f $EMPTY_TIMESTAMP_FILE ]; then
    echo "Creating empty timestamp."
    date +%s > $EMPTY_TIMESTAMP_FILE
    exit 0
fi

# Check how long it's been empty
EMPTY_SINCE=$(cat $EMPTY_TIMESTAMP_FILE)
NOW=$(date +%s)
DIFF=$((NOW - EMPTY_SINCE))

if [ "$DIFF" -ge 300 ]; then  # 5 minutes
    echo "Server empty for 5 minutes. Backing up and shutting down..."

    # Save world
    screen -S minecraft -p 0 -X stuff "save-all\n"
    sleep 5

    # Compress
    tar -czf $BACKUP $WORLD_DIR

    # Upload
    aws s3 cp $BACKUP s3://$BUCKET/world-latest.tar.gz --region $REGION

    # Terminate instance
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    echo "Terminating instance $INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
else
    REMAIN=$((300 - DIFF))
    echo "Server has been empty for $DIFF seconds, waiting $REMAIN more seconds."
fi