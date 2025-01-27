#!/bin/bash

# Docker utility functions for OpenSlides

# Log directory and file location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/docker_utils.log"

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

# Function to fix the docker-compose.yml version error
fix_docker_compose_version() {
  local compose_file="/opt/openslides/docker-compose.yml"
  if [ ! -f "$compose_file" ]; then
    log "ERROR" "Docker Compose file not found at $compose_file."
    exit 1
  fi

  log "INFO" "Fixing docker-compose.yml version error..."
  sed -i '/^version:/d' "$compose_file" || {
    log "ERROR" "Failed to remove version attribute from $compose_file."
    exit 1
  }
  log "INFO" "docker-compose.yml version error fixed successfully."
}

# Function to check if Docker is installed and running
verify_docker() {
  if ! command -v docker &>/dev/null; then
    log "ERROR" "Docker is not installed. Please install Docker and try again."
    exit 1
  fi

  if ! systemctl is-active --quiet docker; then
    log "INFO" "Starting Docker service..."
    systemctl start docker || {
      log "ERROR" "Failed to start Docker service."
      exit 1
    }
  fi

  log "INFO" "Docker is installed and running."
}

# Function to check Docker Compose installation and version
verify_docker_compose() {
  if ! command -v docker-compose &>/dev/null; then
    log "INFO" "Docker Compose is not installed. Installing..."
    if command -v apt-get &>/dev/null; then
      apt-get update && apt-get install -y docker-compose-plugin || {
        log "ERROR" "Failed to install Docker Compose."
        exit 1
      }
    else
      log "ERROR" "Package manager not supported. Please install Docker Compose manually."
      exit 1
    fi
  fi

  local required_version="2.13"
  local installed_version
  installed_version=$(docker compose version --short 2>/dev/null || echo "0.0.0")
  if [[ $(printf '%s\n' "$required_version" "$installed_version" | sort -V | head -n1) != "$required_version" ]]; then
    log "ERROR" "Docker Compose version $installed_version is lower than required version $required_version. Please upgrade."
    exit 1
  fi

  log "INFO" "Docker Compose is installed and meets version requirements."
}

# Function to pull Docker images
pull_docker_images() {
  local compose_file="$1"
  log "INFO" "Pulling Docker images using $compose_file..."
  docker compose -f "$compose_file" pull || {
    log "ERROR" "Failed to pull Docker images."
    exit 1
  }
  log "INFO" "Docker images pulled successfully."
}

# Function to start Docker services
start_docker_services() {
  local compose_file="$1"
  log "INFO" "Starting Docker services using $compose_file..."
  docker compose -f "$compose_file" up --detach || {
    log "ERROR" "Failed to start Docker services."
    exit 1
  }
  log "INFO" "Docker services started successfully."
}

# Function to stop Docker services
stop_docker_services() {
  local compose_file="$1"
  log "INFO" "Stopping Docker services using $compose_file..."
  docker compose -f "$compose_file" down || {
    log "ERROR" "Failed to stop Docker services."
    exit 1
  }
  log "INFO" "Docker services stopped successfully."
}

# Function to recreate Docker services
recreate_docker_services() {
  local compose_file="$1"
  log "INFO" "Recreating Docker services using $compose_file..."
  stop_docker_services "$compose_file"
  start_docker_services "$compose_file"
  log "INFO" "Docker services recreated successfully."
}

# Function to validate the Docker Compose configuration
validate_compose_file() {
  local compose_file="$1"
  log "INFO" "Validating Docker Compose configuration in $compose_file..."
  docker compose -f "$compose_file" config || {
    log "ERROR" "Docker Compose configuration is invalid."
    exit 1
  }
  log "INFO" "Docker Compose configuration is valid."
}

# Function to check the status of running Docker containers
check_docker_status() {
  log "INFO" "Checking Docker container status..."
  docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}" || {
    log "ERROR" "Failed to retrieve Docker container status."
    exit 1
  }
  log "INFO" "Docker container status retrieved successfully."
}