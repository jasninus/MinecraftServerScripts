# MinecraftServerSetup

This repository deploys a fully automated Minecraft server on EC2.

## Structure

- rootfs/ mirrors the Linux filesystem.
- Anything placed inside rootfs/ will be copied directly to / on the server.
- startup.sh performs the deployment using rsync.

## Usage

EC2 user data should:

1. Install dependencies (git, java, screen, awscli, rsync)
2. Clone this repo
3. Run startup.sh
