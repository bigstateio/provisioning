# BigState Edge Node — Docker Setup (Linux)

Installs and runs a BigState edge node using Docker Compose. The installer downloads `docker-compose.yml` and `.docker.env`, saves your edge keys into the env file, creates data/log directories, pulls the public images, and starts the stack.

## Prerequisites

- Linux host
- [Docker Engine](https://docs.docker.com/engine/install/) installed and running
- Docker Compose (the `docker compose` plugin or standalone `docker-compose`)
- `curl` or `wget`
- Your edge node key pair (public and private key, hex)

## Quick start

Run the installer, passing your edge keys as required arguments:

```sh
curl -fsSL https://raw.githubusercontent.com/bigstateio/provisioning/main/docker-linux-raw/install.sh | sh -s -- \
  --edge-public-key <YOUR_EDGE_PUBLIC_KEY> \
  --edge-private-key <YOUR_EDGE_PRIVATE_KEY>
```

The stack is installed into the current directory by default.

## Options

### Required arguments

| Argument | Description |
|---|---|
| `--edge-public-key` | Edge node public key (hex) |
| `--edge-private-key` | Edge node private key (hex) |

### Optional environment overrides

| Variable | Default | Description |
|---|---|---|
| `BIGSTATE_BASE_URL` | this repo's `docker-linux-raw` folder | Base URL to download install files from |
| `BIGSTATE_INSTALL_DIR` | current directory | Target install directory |
| `BUILD_VERSION` | `latest` | Image tag to deploy |

Example with overrides:

```sh
BIGSTATE_INSTALL_DIR=/opt/bigstate BUILD_VERSION=latest \
curl -fsSL https://raw.githubusercontent.com/bigstateio/provisioning/main/docker-linux-raw/install.sh | sh -s -- \
  --edge-public-key <YOUR_EDGE_PUBLIC_KEY> \
  --edge-private-key <YOUR_EDGE_PRIVATE_KEY>
```

Runnable example:

```sh
curl -fsSL https://raw.githubusercontent.com/bigstateio/provisioning/main/docker-linux-raw/install.sh | sh -s -- \
  --edge-public-key 49BE291110EF0B93DFA0666C589002C748651D5FC727A1C5A1CDDEAF832EFC1D \
  --edge-private-key 30379AA00EAE7B02F8367A6702EB1F6FFACB6F7F2155CAD9F951B236B6FFC752
```

## What gets installed

| Service | Image | Port |
|---|---|---|
| API | `bigstateio/api` | `17080` |
| Delivery WS | `bigstateio/delivery.ws` | `17090` |
| Redis | `redis:7.4.2` | `127.0.0.1:6380` |

After installation:

- API: `http://localhost:17080`
- Delivery WS: `http://localhost:17090`

## Managing the stack

Run these commands from the install directory:

```sh
# Status
docker compose --env-file .docker.env ps

# Logs
docker compose --env-file .docker.env logs -f

# Stop
docker compose --env-file .docker.env down

# Update to the latest images and restart
docker compose --env-file .docker.env pull
docker compose --env-file .docker.env up -d
```

## Configuration

Settings are stored in `.docker.env` in the install directory, including the edge keys saved by the installer. Edit the file and re-run `docker compose --env-file .docker.env up -d` to apply changes.

> **Note:** `.docker.env` contains your edge private key — keep the file secure and do not commit it to version control.

