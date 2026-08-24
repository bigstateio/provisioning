#!/bin/sh
#
# BigState installer
#
# Usage:
#   curl -fsSL https://example.com/install.sh | sh -s -- --edge-public-key <hex> --edge-private-key <hex>
#
# Required arguments:
#   --edge-public-key   - edge node public key
#   --edge-private-key  - edge node private key
#
# Optional environment overrides:
#   BIGSTATE_BASE_URL     - base URL to download install files from
#   BIGSTATE_INSTALL_DIR  - target install directory (default: current folder)
#   BUILD_VERSION         - image tag to deploy (default: latest)

set -eu

BIGSTATE_BASE_URL="${BIGSTATE_BASE_URL:-https://raw.githubusercontent.com/bigstateio/provisioning/main/docker-linux-raw}"
BIGSTATE_INSTALL_DIR="${BIGSTATE_INSTALL_DIR:-$(pwd)}"
BIGSTATE_FILES="docker-compose.yml .docker.env"

info()  { printf '\033[1;34m[bigstate]\033[0m %s\n' "$1"; }
error() { printf '\033[1;31m[bigstate] ERROR:\033[0m %s\n' "$1" >&2; }

usage() {
	echo "Usage: $0 --edge-public-key <hex> --edge-private-key <hex>" >&2
}

# --- 0. Parse arguments -------------------------------------------------------

EDGE_PUBLIC_KEY=""
EDGE_PRIVATE_KEY=""

while [ $# -gt 0 ]; do
	case "$1" in
		--edge-public-key)
			EDGE_PUBLIC_KEY="${2:-}"
			shift 2
			;;
		--edge-private-key)
			EDGE_PRIVATE_KEY="${2:-}"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			error "Unknown argument: $1"
			usage
			exit 1
			;;
	esac
done

if [ -z "$EDGE_PUBLIC_KEY" ] || [ -z "$EDGE_PRIVATE_KEY" ]; then
	error "--edge-public-key and --edge-private-key are required."
	usage
	exit 1
fi

export EDGE_PUBLIC_KEY EDGE_PRIVATE_KEY

# --- 1. Check prerequisites -------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
	error "Docker is not installed. Please install Docker first: https://docs.docker.com/engine/install/"
	exit 1
fi

if ! docker info >/dev/null 2>&1; then
	error "Docker is installed but the daemon is not running (or you lack permissions). Start Docker and retry."
	exit 1
fi

if docker compose version >/dev/null 2>&1; then
	COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
	COMPOSE="docker-compose"
else
	error "Docker Compose is not available. Please install the Docker Compose plugin."
	exit 1
fi

if command -v curl >/dev/null 2>&1; then
	download() { curl -fsSL -o "$1" "$2"; }
elif command -v wget >/dev/null 2>&1; then
	download() { wget -qO "$1" "$2"; }
else
	error "Neither curl nor wget is available. Please install one of them."
	exit 1
fi

info "Docker found: $(docker --version)"
info "Compose found: $($COMPOSE version | head -n 1)"

# --- 2. Prepare install directory -------------------------------------------

info "Installing into $BIGSTATE_INSTALL_DIR"
mkdir -p "$BIGSTATE_INSTALL_DIR"
cd "$BIGSTATE_INSTALL_DIR"

# --- 3. Download files -------------------------------------------------------

for f in $BIGSTATE_FILES; do
	info "Downloading $f from $BIGSTATE_BASE_URL"
	download "$f" "$BIGSTATE_BASE_URL/$f"
done

if [ ! -f docker-compose.yml ] || [ ! -f .docker.env ]; then
	error "Failed to download docker-compose.yml and .docker.env"
	exit 1
fi

# --- 4. Save edge keys into env file -------------------------------------------

info "Saving edge keys to .docker.env"
sed -i "s|^EDGE_PUBLIC_KEY=.*|EDGE_PUBLIC_KEY=$EDGE_PUBLIC_KEY|" .docker.env
sed -i "s|^EDGE_PRIVATE_KEY=.*|EDGE_PRIVATE_KEY=$EDGE_PRIVATE_KEY|" .docker.env

# --- 5. Create data/log directories from env ---------------------------------

# shellcheck disable=SC1091
. ./.docker.env
mkdir -p "${API_LOG_PATH:-$BIGSTATE_INSTALL_DIR/logs/api}" \
		 "${DELIVERY_WS_LOG_PATH:-$BIGSTATE_INSTALL_DIR/logs/delivery.ws}" \
		 "${API_VALUE_PATH:-$BIGSTATE_INSTALL_DIR/data/values}"

# --- 6. Pull public images and start -----------------------------------------

info "Pulling public images (tag: ${BUILD_VERSION:-latest})"
$COMPOSE --env-file .docker.env pull

info "Starting BigState"
$COMPOSE --env-file .docker.env up -d

info "BigState installed and running. API: http://localhost:17080, Delivery WS: http://localhost:17090"
