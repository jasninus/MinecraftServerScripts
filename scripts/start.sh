#!/bin/bash
# Start Minecraft server
cd /opt/minecraft/server
exec java -Xmx1300M -Xms1300M -jar server.jar nogui