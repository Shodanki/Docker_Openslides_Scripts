#!/bin/bash

# Helper functions for OpenSlides

# Log directory and file location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/helpers.log"

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

# Function to check if a command exists
check_command() {
  local cmd=$1
  if ! command -v "$cmd" &>/dev/null; then
    log "ERROR" "Command '$cmd' is not available. Please install it and try again."
    exit 1
  fi
  log "INFO" "Command '$cmd' is available."
}

# Function to ensure required dependencies are installed
ensure_dependencies() {
  local dependencies=("curl" "wget" "gpg" "docker" "docker-compose")
  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      log "INFO" "Installing missing dependency: $dep"
      if command -v apt-get &>/dev/null; then
        apt-get update && apt-get install -y "$dep" || {
          log "ERROR" "Failed to install $dep."
          exit 1
        }
      else
        log "ERROR" "Unsupported package manager. Please install $dep manually."
        exit 1
      fi
    else
      log "INFO" "Dependency '$dep' is already installed."
    fi
  done
}

# Function to check if the script is running as root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    log "ERROR" "This script must be run as root."
    exit 1
  fi
  log "INFO" "Script is running as root."
}

# Function to verify if Docker service is running
verify_docker_running() {
  if ! systemctl is-active --quiet docker; then
    log "INFO" "Starting Docker service..."
    systemctl start docker || {
      log "ERROR" "Failed to start Docker service."
      exit 1
    }
  fi
  log "INFO" "Docker service is running."
}

# Function to verify Docker Compose version
verify_docker_compose_version() {
  local required_version="2.13.0"
  local installed_version
  installed_version=$(docker compose version --short 2>/dev/null || echo "0.0.0")
  if [[ $(printf '%s\n' "$required_version" "$installed_version" | sort -V | head -n1) != "$required_version" ]]; then
    log "ERROR" "Docker Compose version $installed_version is lower than required version $required_version. Please upgrade."
    exit 1
  fi
  log "INFO" "Docker Compose version $installed_version meets the requirements."
}

# Function to verify all dependencies
verify_all_dependencies() {
  log "INFO" "Verifying all required dependencies..."
  check_command "curl"
  check_command "wget"
  check_command "gpg"
  check_command "docker"
  check_command "docker-compose"
  verify_docker_running
  verify_docker_compose_version
  log "INFO" "All dependencies verified successfully."
}