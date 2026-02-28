#!/bin/bash
set -e

MINECRAFTUSER=minecraft

echo "Starting Git-based system deployment..."

# Ensure user exists
id -u $MINECRAFTUSER &>/dev/null || useradd -r -m $MINECRAFTUSER

# Safely sync everything inside rootfs to /
rsync -a --ignore-existing rootfs/ /

# Install server if needed
/opt/minecraft/scripts/install_server.sh

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
