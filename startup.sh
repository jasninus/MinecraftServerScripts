#!/bin/bash

MINECRAFTUSER=minecraft
MINECRAFTDIR=/opt/minecraft/server
SCRIPTS_DIR=/opt/minecraft/scripts

# Copy scripts
mkdir -p $SCRIPTS_DIR
cp -r scripts/* $SCRIPTS_DIR/
chmod +x $SCRIPTS_DIR/*.sh
chown -R $MINECRAFTUSER:$MINECRAFTUSER $SCRIPTS_DIR

# Copy start/stop scripts to server folder
cp $SCRIPTS_DIR/start.sh $MINECRAFTDIR/start
cp $SCRIPTS_DIR/stop.sh $MINECRAFTDIR/stop
chmod +x $MINECRAFTDIR/start $MINECRAFTDIR/stop
chown $MINECRAFTUSER:$MINECRAFTUSER $MINECRAFTDIR/start $MINECRAFTDIR/stop

# Copy server files
cp -r server_files/* $MINECRAFTDIR/
chown -R $MINECRAFTUSER:$MINECRAFTUSER $MINECRAFTDIR

# Download server jar and eula
cd $MINECRAFTDIR
wget -q https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar -O server.jar
echo "eula=true" > eula.txt
chown $MINECRAFTUSER:$MINECRAFTUSER server.jar eula.txt

# Setup systemd services (Minecraft + shutdown)
# [same as before, no change]

systemctl daemon-reload
systemctl enable minecraft.service
systemctl start minecraft.service
systemctl enable minecraft-shutdown.service
systemctl start minecraft-shutdown.service