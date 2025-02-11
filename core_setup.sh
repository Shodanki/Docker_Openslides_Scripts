#!/bin/bash

# Core setup functions for OpenSlides

INSTALL_DIR=${INSTALL_DIR:-/opt/openslides}

# Log directory and file location
LOG_DIR="$INSTALL_DIR/logs"
LOG_FILE="$LOG_DIR/core_setup.log"

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

# Function to set up OpenSlides
setup_openslides() {
  log "INFO" "Setting up OpenSlides..."
  if [ ! -f "$INSTALL_DIR/openslides" ]; then
    mkdir -p "$INSTALL_DIR" || {
      log "ERROR" "Failed to create $INSTALL_DIR directory."
      exit 1
    }
    wget -q https://github.com/OpenSlides/openslides-manage-service/releases/download/latest/openslides -O "$INSTALL_DIR/openslides" || {
      log "ERROR" "Failed to download OpenSlides manage tool."
      exit 1
    }
    chmod +x "$INSTALL_DIR/openslides" || {
      log "ERROR" "Failed to make OpenSlides manage tool executable."
      exit 1
    }
    log "INFO" "OpenSlides manage tool downloaded and set up successfully."
  else
    log "INFO" "OpenSlides manage tool already exists. Skipping download."
  fi
}

# Function to initialize OpenSlides
initialize_openslides() {
  log "INFO" "Initializing OpenSlides..."
  "$INSTALL_DIR/openslides" setup "$INSTALL_DIR" || {
    log "ERROR" "Failed to initialize OpenSlides."
    exit 1
  }
  log "INFO" "OpenSlides initialized successfully."
}

# Function to check OpenSlides server
check_openslides_server() {
  log "INFO" "Checking OpenSlides server..."
  "$INSTALL_DIR/openslides" check-server || {
    log "ERROR" "OpenSlides server check failed."
    exit 1
  }
  log "INFO" "OpenSlides server is running and healthy."
}

# Function to create initial OpenSlides data
create_initial_data() {
  log "INFO" "Creating initial OpenSlides data..."
  "$INSTALL_DIR/openslides" initial-data || {
    log "ERROR" "Failed to create initial OpenSlides data."
    exit 1
  }
  log "INFO" "Initial OpenSlides data created successfully."
}