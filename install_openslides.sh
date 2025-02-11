#!/bin/bash

# Main installation script for OpenSlides

# Enable debug mode if -d is passed as an argument
DEBUG=false
FORCE_DEPENDENCY_CHECK=false
while getopts ":df" opt; do
  case $opt in
    d)
      DEBUG=true
      ;;
    f)
      FORCE_DEPENDENCY_CHECK=true
      ;;
    *)
      echo "Usage: $0 [-d] [-f]" >&2
      exit 1
      ;;
  esac
done

# Level 1: Installation Directory Selection
echo "Choose installation directory:"
echo "1) Default (/opt/openslides)"
echo "2) Custom directory"
echo "3) Script execution directory appended with /openslides"
read -rp "Enter your choice (1-3): " dir_choice
case $dir_choice in
    1)
        INSTALL_DIR="/opt/openslides"
        ;;
    2)
        read -rp "Enter custom installation directory: " custom_dir
        INSTALL_DIR="$custom_dir"
        ;;
    3)
        SCRIPT_EXEC_DIR=$(dirname "$(realpath "$0")")
        INSTALL_DIR="$SCRIPT_EXEC_DIR/openslides"
        ;;
    *)
        echo "Invalid choice. Using default (/opt/openslides)."
        INSTALL_DIR="/opt/openslides"
        ;;
esac
export INSTALL_DIR
echo "Installation directory set to: $INSTALL_DIR"

# Log directory and file location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/install_openslides.log"

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

# Source helper scripts
source "$SCRIPT_DIR/helpers.sh"
source "$SCRIPT_DIR/docker_utils.sh"
source "$SCRIPT_DIR/core_setup.sh"
source "$SCRIPT_DIR/configuration_utils.sh"
source "$SCRIPT_DIR/health_check.sh"
source "$SCRIPT_DIR/openslides_utils.sh" 
source "$SCRIPT_DIR/yml_fix.sh"  # Source the new yml_fix.sh script

# Check required functions
REQUIRED_FUNCTIONS=(
  "install_openslides"
  "diagnose_openslides"
  "backup_openslides_data"
  "upgrade_openslides"
  "remove_openslides"
  "configure_external_access"
  "configure_email"
  "configure_https"
  "recreate_instances"
  "setup_openslides"
  "initialize_openslides"
  "check_openslides_server"
  "create_initial_data"
  "ensure_dependencies"
  "check_openslides_health"
  "check_common_problems"
  "fix_common_problems"
  "fix_docker_compose_yml"  # Add the new function
)
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! declare -f "$func" &>/dev/null; then
    log "ERROR" "Required function '$func' is missing. Ensure all scripts are sourced correctly."
    exit 1
  fi
done

# Force dependency check if option is set
if [ "$FORCE_DEPENDENCY_CHECK" = true ]; then
  log "INFO" "Forcing dependency check..."
  ensure_dependencies
fi

# Menu options
show_menu() {
  echo "Choose an option:"
  echo "1) Install OpenSlides"
  echo "2) Diagnose issues with existing installation"
  echo "3) Backup OpenSlides data"
  echo "4) Upgrade OpenSlides"
  echo "5) Remove OpenSlides"
  echo "6) Configure OpenSlides for external access"
  echo "7) Configure HTTPS in docker-compose.yml"
  echo "8) Configure Email in docker-compose.yml"
  echo "9) Force check all dependencies"
  echo "10) Check OpenSlides health"
  echo "11) Fix common problems"
  echo "12) Fix docker-compose.yml file"  # Add the new menu option
  read -rp "Enter your choice (1-12): " choice
}

# Main logic
main() {
  if $DEBUG; then
    log "DEBUG" "Debug mode enabled"
    set -x
  fi

  show_menu

  case $choice in
    1)
      install_openslides
      ;;
    2)
      diagnose_openslides
      ;;
    3)
      backup_openslides_data
      ;;
    4)
      upgrade_openslides
      ;;
    5)
      remove_openslides
      ;;
    6)
      configure_external_access
      ;;
    7)
      configure_https
      ;;
    8)
      configure_email
      ;;
    9)
      ensure_dependencies
      ;;
    10)
      check_openslides_health
      ;;
    11)
      fix_common_problems
      ;;
    12)
      fix_docker_compose_yml  # Call the new function
      ;;
    *)
      log "ERROR" "Invalid choice. Exiting."
      exit 1
      ;;
  esac

  if $DEBUG; then
    set +x
  fi
}

main