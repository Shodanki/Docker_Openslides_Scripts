#!/bin/bash

# Script to fix the docker-compose.yml file

# Log directory and file location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/yml_fix.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" || {
  echo "[ERROR] Failed to create log directory: $LOG_DIR"
  exit 1
}

# Function to log messages
log() {
  local level=$1
  local message=$2
  echo "[$level] $message" | tee -a "$LOG_FILE"
}

# Function to fix the docker-compose.yml file
fix_docker_compose_yml() {
  local compose_file="/opt/openslides/docker-compose.yml"
  if [ ! -f "$compose_file" ]; then
    log "ERROR" "Docker Compose file not found at $compose_file."
    return 1
  fi

  log "INFO" "Fixing docker-compose.yml file..."

  # Ensure the /opt/openslides/secrets directory exists
  mkdir -p /opt/openslides/secrets || {
    log "ERROR" "Failed to create /opt/openslides/secrets directory."
    return 1
  }

  # Update the secrets paths in the docker-compose.yml file
  sed -i 's|file: ./secrets/|file: /opt/openslides/secrets/|g' "$compose_file" || {
    log "ERROR" "Failed to update secrets paths in $compose_file."
    return 1
  }

  # Remove the obsolete 'version' attribute
  sed -i '/^version:/d' "$compose_file" || {
    log "ERROR" "Failed to remove 'version' attribute from $compose_file."
    return 1
  }

  # Validate the docker-compose.yml file
  docker compose -f "$compose_file" config >/dev/null 2>&1 || {
    log "ERROR" "Failed to validate docker-compose.yml file after fixing."
    return 1
  }

  log "INFO" "docker-compose.yml file fixed and validated successfully."
}

# Main logic
main() {
  fix_docker_compose_yml
}

main