#!/bin/bash
# Backup and terminate EC2 instance (run manually or via cron/systemd)

MINECRAFTDIR="/opt/minecraft/server"
BACKUP="/opt/minecraft/server/world.tar.gz"
BUCKET="jas-minecraft-server-backup"

echo "Saving world..."
screen -S minecraft -p 0 -X stuff "save-all^M"
sleep 5

echo "Compressing world..."
tar -czf $BACKUP $MINECRAFTDIR/world

echo "Uploading to S3..."
aws s3 cp $BACKUP s3://$BUCKET/world-latest.tar.gz

echo "Getting instance ID..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:ServerType,Values=minecraft-automatic-shutdown" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)
echo "Instance ID is: $INSTANCE_ID"

echo "Terminating instance..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region eu-west-2