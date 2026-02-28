#!/bin/bash
# /opt/minecraft/server/shutdown_if_empty.sh

MINECRAFTDIR=/opt/minecraft/server
WORLD_DIR="$MINECRAFTDIR/world"
BACKUP="$MINECRAFTDIR/world.tar.gz"
BUCKET="jas-minecraft-server-backup"
REGION="eu-west-2"

# Check for players
PLAYERS=$(screen -S minecraft -p 0 -X stuff "list\n" 2>/dev/null | grep -oP 'There are \K\d+')
PLAYERS=${PLAYERS:-0}

echo "Checking if any players are online"
if [ "$PLAYERS" -eq 0 ]; then
    echo "No players online. Waiting 30 seconds..."
    sleep 30

    # Re-check
    PLAYERS=$(screen -S minecraft -p 0 -X stuff "list\n" 2>/dev/null | grep -oP 'There are \K\d+')
    PLAYERS=${PLAYERS:-0}

    if [ "$PLAYERS" -eq 0 ]; then
        echo "Still no players. Backing up and shutting down..."
        # Save world
        screen -S minecraft -p 0 -X stuff "save-all\n"
        sleep 5

        # Compress
        tar -czf $BACKUP $WORLD_DIR

        # Upload
        aws s3 cp $BACKUP s3://$BUCKET/world-latest.tar.gz --region $REGION

        # Terminate instance
        INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
    fi
fi