#!/bin/bash

# Health check and common problem fixes for OpenSlides

INSTALL_DIR=${INSTALL_DIR:-/opt/openslides}

# Log directory and file location
LOG_DIR="$INSTALL_DIR/logs"
LOG_FILE="$LOG_DIR/health_check.log"

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

# Function to check OpenSlides server health
check_openslides_health() {
  log "INFO" "Checking OpenSlides server health..."
  "$INSTALL_DIR/openslides" check-server || {
    log "ERROR" "OpenSlides server check failed."
    return 1
  }
  log "INFO" "OpenSlides server is running and healthy."
}

# Function to check for common problems
check_common_problems() {
  log "INFO" "Checking for common problems..."

  # Check if secrets/manage_auth_password exists
  if [ ! -f "$INSTALL_DIR/secrets/manage_auth_password" ]; then
    log "WARN" "secrets/manage_auth_password file is missing. Creating it..."
    mkdir -p "$INSTALL_DIR/secrets" || {
      log "ERROR" "Failed to create secrets directory."
      return 1
    }
    openssl rand -base64 32 > "$INSTALL_DIR/secrets/manage_auth_password" || {
      log "ERROR" "Failed to create manage_auth_password file."
      return 1
    }
    chmod 600 "$INSTALL_DIR/secrets/manage_auth_password" || {
      log "ERROR" "Failed to set permissions for manage_auth_password file."
      return 1
    }
    log "INFO" "manage_auth_password file created successfully."
  fi

  # Check Docker Compose version
  local required_version="2.13"
  local installed_version
  installed_version=$(docker compose version --short 2>/dev/null || echo "0.0.0")
  if [[ $(printf '%s\n' "$required_version" "$installed_version" | sort -V | head -n1) != "$required_version" ]]; then
    log "WARN" "Docker Compose version $installed_version is lower than required version $required_version. Please upgrade."
  else
    log "INFO" "Docker Compose version $installed_version meets the requirements."
  fi

  # Check Docker service status
  if ! systemctl is-active --quiet docker; then
    log "WARN" "Docker service is not running. Starting Docker service..."
    systemctl start docker || {
      log "ERROR" "Failed to start Docker service."
      return 1
    }
    log "INFO" "Docker service started successfully."
  else
    log "INFO" "Docker service is running."
  fi

  log "INFO" "Common problems checked successfully."
}

# Function to fix common problems
fix_common_problems() {
  log "INFO" "Fixing common problems..."

  # Fix missing secrets/manage_auth_password
  if [ ! -f "$INSTALL_DIR/secrets/manage_auth_password" ]; then
    log "INFO" "Creating manage_auth_password file..."
    mkdir -p "$INSTALL_DIR/secrets" || {
      log "ERROR" "Failed to create secrets directory."
      return 1
    }
    openssl rand -base64 32 > "$INSTALL_DIR/secrets/manage_auth_password" || {
      log "ERROR" "Failed to create manage_auth_password file."
      return 1
    }
    chmod 600 "$INSTALL_DIR/secrets/manage_auth_password" || {
      log "ERROR" "Failed to set permissions for manage_auth_password file."
      return 1
    }
    log "INFO" "manage_auth_password file created successfully."
  fi

  # Fix Docker Compose version
  local required_version="2.13"
  local installed_version
  installed_version=$(docker compose version --short 2>/dev/null || echo "0.0.0")
  if [[ $(printf '%s\n' "$required_version" "$installed_version" | sort -V | head -n1) != "$required_version" ]]; then
    log "INFO" "Upgrading Docker Compose..."
    if command -v apt-get &>/dev/null; then
      apt-get update && apt-get install -y docker-compose-plugin || {
        log "ERROR" "Failed to upgrade Docker Compose."
        return 1
      }
    else
      log "ERROR" "Package manager not supported. Please upgrade Docker Compose manually."
      return 1
    fi
    log "INFO" "Docker Compose upgraded successfully."
  else
    log "INFO" "Docker Compose version $installed_version meets the requirements."
  fi

  # Fix Docker service status
  if ! systemctl is-active --quiet docker; then
    log "INFO" "Starting Docker service..."
    systemctl start docker || {
      log "ERROR" "Failed to start Docker service."
      return 1
    }
    log "INFO" "Docker service started successfully."
  else
    log "INFO" "Docker service is running."
  fi

  log "INFO" "Common problems fixed successfully."
}