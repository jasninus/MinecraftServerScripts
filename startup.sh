#!/bin/bash
set -e

MINECRAFTUSER=minecraft
MINECRAFTDIR=/opt/minecraft/server
WORLD_DIR="$MINECRAFTDIR/world"
BACKUP="$MINECRAFTDIR/world.tar.gz"
BUCKET="jas-minecraft-server-backup"
REGION="eu-west-2"

echo "Starting Git-based system deployment..."

# Ensure user exists
id -u $MINECRAFTUSER &>/dev/null || useradd -r -m $MINECRAFTUSER

# Safely sync everything inside rootfs to /
rsync -a --ignore-existing --chown=minecraft:minecraft rootfs/ /

# Mark scripts as executable
chmod +x /opt/minecraft/scripts/*.sh

# Install dependencies
sudo yum install -y python3 python3-pip 
sudo pip3 install mcstatus

# Download backup from S3 (if it exists)
echo "$(date): Checking for world backup on S3..."
aws s3 cp s3://$BUCKET/world-latest.tar.gz $BACKUP --region $REGION

if [ -f $BACKUP ]; then
    echo "$(date): Backup found, extracting world..."
    # Remove existing world folder if it exists
	cd /opt/minecraft/server
	rm -rf world
	tar -xzf world.tar.gz
    echo "$(date): World restored from backup."
else
    echo "$(date): No backup found, starting a fresh world."
fi

# Install server if needed
bash /opt/minecraft/scripts/install_server.sh

# Fix ownership
chown -R minecraft:minecraft /opt/minecraft

# Reload systemd
systemctl daemon-reload

# Enable services
systemctl enable minecraft.service
systemctl enable minecraft-shutdown.service

# Start services
systemctl start minecraft.service
systemctl start minecraft-shutdown.service

echo "Deployment complete."
