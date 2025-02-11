#!/bin/bash

# Configuration functions for OpenSlides

INSTALL_DIR=${INSTALL_DIR:-/opt/openslides}

# Log directory and file location
LOG_DIR="$INSTALL_DIR/logs"
LOG_FILE="$LOG_DIR/configuration_utils.log"

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

# Function to configure external access
configure_external_access() {
  log "INFO" "Configuring external access..."
  local compose_file="$INSTALL_DIR/docker-compose.yml"
  if [ ! -f "$compose_file" ]; then
    log "ERROR" "Docker Compose file not found at $compose_file."
    exit 1
  fi

  sed -i 's/127.0.0.1/0.0.0.0/g' "$compose_file" || {
    log "ERROR" "Failed to configure external access in $compose_file."
    exit 1
  }

  log "INFO" "External access configured successfully."
}

# Function to configure HTTPS
configure_https() {
  log "INFO" "Configuring HTTPS..."
  local compose_file="$INSTALL_DIR/docker-compose.yml"
  if [ ! -f "$compose_file" ]; then
    log "ERROR" "Docker Compose file not found at $compose_file."
    exit 1
  fi

  read -p "Enable HTTPS? (yes/no): " enable_https
  if [[ "$enable_https" == "yes" ]]; then
    sed -i 's/ENABLE_HTTPS=false/ENABLE_HTTPS=true/g' "$compose_file" || {
      log "ERROR" "Failed to enable HTTPS."
      exit 1
    }
    log "INFO" "HTTPS enabled successfully."
  else
    sed -i 's/ENABLE_HTTPS=true/ENABLE_HTTPS=false/g' "$compose_file" || {
      log "ERROR" "Failed to disable HTTPS."
      exit 1
    }
    log "INFO" "HTTPS disabled successfully."
  fi
}

# Function to configure email
configure_email() {
  log "INFO" "Configuring email settings..."
  local compose_file="$INSTALL_DIR/docker-compose.yml"
  if [ ! -f "$compose_file" ]; then
    log "ERROR" "Docker Compose file not found at $compose_file."
    exit 1
  fi

  read -p "Enter EMAIL_HOST: " email_host
  read -p "Enter EMAIL_PORT: " email_port
  read -p "Enter EMAIL_HOST_USER: " email_user
  read -s -p "Enter EMAIL_HOST_PASSWORD: " email_password
  echo
  read -p "Enter EMAIL_CONNECTION_SECURITY (SSL/TLS/NONE/STARTTLS): " email_security
  read -p "Enter EMAIL_TIMEOUT: " email_timeout
  read -p "Accept self-signed certificates? (true/false): " email_self_signed
  read -p "Enter DEFAULT_FROM_EMAIL: " email_from

  sed -i "s/EMAIL_HOST=.*/EMAIL_HOST=$email_host/g" "$compose_file"
  sed -i "s/EMAIL_PORT=.*/EMAIL_PORT=$email_port/g" "$compose_file"
  sed -i "s/EMAIL_HOST_USER=.*/EMAIL_HOST_USER=$email_user/g" "$compose_file"
  sed -i "s/EMAIL_HOST_PASSWORD=.*/EMAIL_HOST_PASSWORD=$email_password/g" "$compose_file"
  sed -i "s/EMAIL_CONNECTION_SECURITY=.*/EMAIL_CONNECTION_SECURITY=$email_security/g" "$compose_file"
  sed -i "s/EMAIL_TIMEOUT=.*/EMAIL_TIMEOUT=$email_timeout/g" "$compose_file"
  sed -i "s/EMAIL_ACCEPT_SELF_SIGNED_CERTIFICATE=.*/EMAIL_ACCEPT_SELF_SIGNED_CERTIFICATE=$email_self_signed/g" "$compose_file"
  sed -i "s/DEFAULT_FROM_EMAIL=.*/DEFAULT_FROM_EMAIL=$email_from/g" "$compose_file"

  log "INFO" "Email settings configured successfully."
}