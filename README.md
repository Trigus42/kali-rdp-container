# Kali Docker Image

Just for my personal use, but feel free to use it if you want.

It's not optimized for size, but for ease of use. It is based on the official Kali Linux image, and it includes some additional tools that I use frequently.

There might be breaking changes at any time, so use it at your own risk.

## Syncthing (Cross-Deployment Sync)

Syncthing keeps a `/workspace/syncthing/` directory in sync across all deployments (local docker-compose and k8s pods).

### Setup

1. Set `SYNCTHING_ENABLE=true` in your environment / deployment config. If not set to `true`, Syncthing will not start.

2. Start your deployments. Each instance logs its **Device ID** on startup.

3. Access the Syncthing Web UI at `http://localhost:8384` from inside the container (e.g. via your RDP desktop browser) and add the other instance's Device ID under **Remote Devices**. This is a one-time operation — the pairing persists across restarts.

4. When adding a remote device, enable **Auto Accept** so shared folders are accepted automatically.

No ports are exposed to the host. The Web UI is only accessible from inside the container. Syncthing uses global relay and discovery servers by default, so sync works out of the box as long as the container has outbound internet access.
