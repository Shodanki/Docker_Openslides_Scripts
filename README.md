
# OpenSlides Script Suite

This suite automates the installation, configuration, and management of OpenSlides.

## Prerequisites

- A Linux-based OS with `sudo` access.
- `curl`, `wget`, `gpg`, `docker`, and `docker-compose` installed or installable through package managers.
- Root or sudo privileges for running the scripts.

## Installation

1. Clone this repository or download the scripts as a package.
2. Make the scripts executable:
   ```bash
   chmod +x *.sh
   ```
3. Run the main installation script:
   ```bash
   sudo ./install_openslides.sh
   ```

## Usage

- `install_openslides.sh`: Main script for installation and management.
- `helpers.sh`: Utility functions for dependency checks and logging.
- `docker_utils.sh`: Docker-related operations (start, stop, recreate, etc.).
- `openslides_setup.sh`: Handles the setup and initialization of OpenSlides.
- `configuration_utils.sh`: Configures email, HTTPS, and external access.
- `maintenance_utils.sh`: Diagnoses, upgrades, backs up, and removes OpenSlides.

## Debugging

Enable debug mode in the main script by passing the `-d` flag:
```bash
sudo ./install_openslides.sh -d
```
