# Kali Docker Image

Just for my personal use, but feel free to use it if you want.

It's not optimized for size, but for ease of use. It is based on the official Kali Linux image, and it includes some additional tools that I use frequently.

There might be breaking changes at any time, so use it at your own risk.

## Quick Start (docker-compose)

1. Copy the example file:

   ```bash
   cp docker-compose.example.yaml docker-compose.yaml
   ```

2. Start the container:

   ```bash
   docker compose up -d
   ```

3. Connect via RDP at `localhost:3389` using any RDP client (e.g. Microsoft Remote Desktop, Remmina). The default credentials are `kali` / `kali`.

4. (Optional) SSH is available at `localhost:2222` when `SSHD_ENABLE=true`.

### Ports

| Host                 | Container | Service |
|----------------------|-----------|---------|
| `127.0.0.1:3389`    | `3389`    | XRDP    |
| `127.0.0.1:2222`    | `22`      | SSH     |

Both ports are bound to `127.0.0.1` only, so they are not exposed to the network.

### Volume Mount

```yaml
volumes:
  - ../kali-unencrypted-mount:/workspace/host-unencrypted/:rw
```

The host directory `../kali-unencrypted-mount` (relative to the compose file) is mounted into the container at `/workspace/host-unencrypted/`. This is the primary way to persist data across container restarts — anything written there is stored directly on the host. If gocryptfs is enabled, the encrypted ciphertext directory also lives inside this mount (see below).

### Environment Variables

| Variable              | Default   | Description                                              |
|-----------------------|-----------|----------------------------------------------------------|
| `SSHD_ENABLE`         | *(unset)* | Set to `true` to start the SSH server                    |
| `DIND_ENABLE`         | *(unset)* | Set to `true` to start Docker-in-Docker                  |
| `MSF_ENABLE`          | *(unset)* | Set to `true` to initialize PostgreSQL + Metasploit DB   |
| `GOCRYPTFS_PASSWORD`  | *(unset)* | Passphrase for the encrypted volume (enables gocryptfs)  |
| `SYNCTHING_ENABLE`    | *(unset)* | Set to `true` to start Syncthing                         |
| `HISTFILE`            | *(unset)* | Custom path for zsh history (useful for persistence)     |

### Capabilities & Privileges

The example compose file grants `NET_ADMIN`, access to `/dev/net/tun` (for VPN/proxy use), and `privileged: true` (required for things like NFS mounting and Docker-in-Docker with fuse-overlayfs).

## VPN (Gluetun — WireGuard, kill switch)

VPN is handled by a [Gluetun](https://github.com/qdm12/gluetun) sidecar container that owns the network namespace. Kali shares it via `network_mode: service:gluetun`, so all traffic is forced through the tunnel — if the tunnel drops, Gluetun's kill switch blocks everything and there are no leaks.

### How it works

- Gluetun holds `NET_ADMIN` and `/dev/net/tun`; Kali has no independent network stack.
- RDP/SSH ports are published on the Gluetun container, so they remain accessible on the host regardless of VPN state.
- DNS goes through Gluetun's built-in DoT resolver (Quad9 by default) — no plain UDP DNS queries leave the host.
- IPv6 is enabled end-to-end (`VPN_IPV6=on`); disable if your provider doesn't support it.

### Setup

1. Create the config directory next to `docker-compose.yaml`:

   ```bash
   mkdir -p vpn-configs
   ```

2. Place your WireGuard config file at `vpn-configs/wg0.conf`. Standard `wg-quick` format is expected:

   ```ini
   [Interface]
   PrivateKey = <your-private-key>
   Address = 10.x.x.x/32
   DNS = 10.x.x.1

   [Peer]
   PublicKey = <server-public-key>
   Endpoint = vpn.example.com:51820
   AllowedIPs = 0.0.0.0/0,::/0
   ```

   > **Note:** The `DNS =` line in the config is ignored by Gluetun — DNS is managed by its own DoT subsystem. Set `DNS_UPSTREAM_RESOLVERS` in the compose file to change the resolver.

3. Start the stack:

   ```bash
   docker compose up -d
   ```

   Gluetun starts first; Kali waits for it via `depends_on`.

### Environment Variables (on the `gluetun` service)

| Variable | Default | Description |
|---|---|---|
| `VPN_IPV6` | `on` | Enable IPv6 through the tunnel. Set to `off` if unsupported by your provider. |
| `FIREWALL_OUTBOUND_SUBNETS` | *(empty)* | Comma-separated CIDRs allowed outside the tunnel (e.g. `192.168.1.0/24` for LAN). |
| `DNS_UPSTREAM_RESOLVER_TYPE` | `dot` | DNS resolver type. Keep as `dot` for encrypted DNS. |
| `DNS_UPSTREAM_RESOLVERS` | `quad9` | DoT provider. Options: `quad9`, `cloudflare`, `google`. |

## gocryptfs (Encrypted Volume)

gocryptfs provides a transparent encryption layer on top of the host-mounted directory. Files written to the decrypted mount are automatically encrypted on the host.

### How it works

| Path (inside container)              | Purpose                                         |
|--------------------------------------|-------------------------------------------------|
| `/workspace/host-unencrypted/`       | Raw host mount                                  |
| `.../kali-encrypted-mount/`          | Encrypted ciphertext dir (lives on the host)    |
| `/workspace/host-encrypted/`         | Decrypted plaintext mount                       |

### Setup

1. Set the `GOCRYPTFS_PASSWORD` environment variable. If unset, gocryptfs is skipped entirely.

2. On first start the ciphertext directory is auto-initialized (`gocryptfs -init`). On subsequent starts it is simply mounted.

3. Read/write files under `/workspace/host-encrypted/` — they appear encrypted under `kali-encrypted-mount/` on the host.

### Environment variables

| Variable                | Default                            | Description                          |
|-------------------------|------------------------------------|--------------------------------------|
| `GOCRYPTFS_PASSWORD`    | *(none — required)*                | Passphrase for the encrypted volume  |
| `RAW_MOUNT`             | `/workspace/host-unencrypted`      | Host-mounted directory               |
| `ENCRYPTED_FOLDER_NAME` | `kali-encrypted-mount`             | Subfolder that holds ciphertext      |
| `ENCRYPTED_MOUNT`       | `/workspace/host-encrypted`        | Where the decrypted view is mounted  |

## Syncthing (Cross-Deployment Sync)

Syncthing keeps a `/workspace/syncthing/` directory in sync across all deployments (local docker-compose and k8s pods).

### Setup

1. Set `SYNCTHING_ENABLE=true` in your environment / deployment config. If not set to `true`, Syncthing will not start.

2. Start your deployments. Each instance logs its **Device ID** on startup.

3. Access the Syncthing Web UI at `http://localhost:8384` from inside the container (e.g. via your RDP desktop browser) and add the other instance's Device ID under **Remote Devices**. This is a one-time operation — the pairing persists across restarts.

4. When adding a remote device, enable **Auto Accept** so shared folders are accepted automatically.

No ports are exposed to the host. The Web UI is only accessible from inside the container. Syncthing uses global relay and discovery servers by default, so sync works out of the box as long as the container has outbound internet access.

