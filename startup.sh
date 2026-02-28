#!/bin/bash
set -e

MINECRAFTUSER=minecraft

echo "Starting Git-based system deployment..."

# Ensure user exists
id -u $MINECRAFTUSER &>/dev/null || useradd -r -m $MINECRAFTUSER

# Safely sync everything inside rootfs to /
rsync -a --ignore-existing --chown=minecraft:minecraft rootfs/ /

# Mark scripts as executable
chmod +x /opt/minecraft/scripts/*.sh

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
