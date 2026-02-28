#!/bin/bash
set -e

MINECRAFTDIR=/opt/minecraft/server
SERVER_URL="https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar"

cd $MINECRAFTDIR

# Only download if missing
if [ ! -f server.jar ]; then
    echo "Downloading Minecraft server..."
    wget -q $SERVER_URL -O server.jar
    echo "eula=true" > eula.txt
    chown minecraft:minecraft server.jar eula.txt
else
    echo "server.jar already exists, skipping download."
fi