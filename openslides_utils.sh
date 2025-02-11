#!/bin/bash

# OpenSlides utility functions

INSTALL_DIR=${INSTALL_DIR:-/opt/openslides}

# Log directory and file location
LOG_DIR="$INSTALL_DIR/logs"
LOG_FILE="$LOG_DIR/openslides_utils.log"

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

# Function to install OpenSlides
install_openslides() {
  log "INFO" "Starting OpenSlides installation..."
  setup_openslides
  initialize_openslides
  pull_docker_images "$INSTALL_DIR/docker-compose.yml"
  start_docker_services "$INSTALL_DIR/docker-compose.yml"
  check_openslides_server
  create_initial_data
  log "INFO" "OpenSlides installation completed successfully."
}

# Function to diagnose OpenSlides installation
diagnose_openslides() {
  log "INFO" "Diagnosing OpenSlides installation..."
  check_docker_status
  check_openslides_server
  log "INFO" "Diagnosis completed successfully."
}

# Function to back up OpenSlides data
backup_openslides_data() {
  log "INFO" "Backing up OpenSlides data..."
  local backup_dir="$INSTALL_DIR/backup_$(date +%Y%m%d%H%M%S)"
  mkdir -p "$backup_dir" || {
    log "ERROR" "Failed to create backup directory."
    exit 1
  }

  cp -r "$INSTALL_DIR/*" "$backup_dir" || {
    log "ERROR" "Failed to back up OpenSlides data."
    exit 1
  }

  log "INFO" "Backup completed successfully. Files stored in $backup_dir."
}

# Function to upgrade OpenSlides
upgrade_openslides() {
  log "INFO" "Upgrading OpenSlides..."
  pull_docker_images "$INSTALL_DIR/docker-compose.yml"
  recreate_docker_services "$INSTALL_DIR/docker-compose.yml"
  log "INFO" "OpenSlides upgraded successfully."
}

# Function to remove OpenSlides
remove_openslides() {
  log "INFO" "Removing OpenSlides..."
  stop_docker_services "$INSTALL_DIR/docker-compose.yml"
  rm -rf "$INSTALL_DIR" || {
    log "ERROR" "Failed to remove OpenSlides files."
    exit 1
  }
  log "INFO" "OpenSlides removed successfully."
}

# Function to recreate OpenSlides instances
recreate_instances() {
  log "INFO" "Recreating OpenSlides instances..."
  recreate_docker_services "$INSTALL_DIR/docker-compose.yml"
  log "INFO" "OpenSlides instances recreated successfully."
}