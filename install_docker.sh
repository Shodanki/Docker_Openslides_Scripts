#!/bin/bash

# Exit script on any error
set -e

# Function to handle errors
error_handler() {
    echo "An error occurred. Do you want to proceed anyway? (yes/no)"
    read -r choice
    if [[ "$choice" != "yes" ]]; then
        echo "Exiting..."
        exit 1
    fi
}

trap error_handler ERR

# Debug mode
DEBUG=false
while getopts "d" opt; do
    case $opt in
        d) DEBUG=true ;;
        *) echo "Usage: $0 [-d]"; exit 1 ;;
    esac
done

# Debug logging function
debug_log() {
    if $DEBUG; then
        echo "DEBUG: $1"
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Exiting..."
    exit 1
fi

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    echo "Updating package index and installing prerequisites..."
    apt-get update -y
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    debug_log "Checking if Docker's repository is already added."
    if grep -q "https://download.docker.com/linux/debian" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        echo "Docker repository already exists. Skipping repository setup."
    else
        echo "Adding Docker's official GPG key and repository..."
        mkdir -m 0755 -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
            $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    fi

    apt-get update -y
    echo "Installing Docker Engine..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    echo "Verifying Docker installation..."
    docker --version

    echo "Installing Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K[^"]+')
        curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

    echo "Verifying Docker Compose installation..."
    docker-compose --version
}

# Function to install Portainer
install_portainer() {
    local custom_port=$1
    if docker ps | grep -q "portainer/portainer-ce"; then
        echo "Portainer is already running. Skipping installation."
    else
        echo "Installing Portainer on port $custom_port..."
        docker volume create portainer_data
        docker run -d \
            -p $custom_port:9000 \
            -p 8000:8000 \
            --name=portainer \
            --restart=always \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v portainer_data:/data \
            portainer/portainer-ce

        if docker ps | grep -q "portainer/portainer-ce"; then
            echo "Portainer has been installed successfully on port $custom_port."
        else
            echo "Failed to install Portainer."
        fi
    fi
}

# Function to install other UI management tools
install_other_ui() {
    echo "Installing other Docker UI management tools..."
    echo "Option 1: LazyDocker"
    echo "Option 2: Yacht"
    echo "Option 3: DockStation"
    read -p "Choose a tool to install (1/2/3): " choice
    case $choice in
        1)
            echo "Installing LazyDocker..."
            curl -Lo /usr/local/bin/lazydocker https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_$(uname -s)_$(uname -m)
            chmod +x /usr/local/bin/lazydocker
            lazydocker --version
            ;;
        2)
            echo "Installing Yacht..."
            docker run -d \
                -p 8001:8000 \
                --name=yacht \
                --restart=always \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v yacht_data:/config \
                selfhostedpro/yacht
            ;;
        3)
            echo "Installing DockStation..."
            echo "DockStation requires manual installation. Please visit https://dockstation.io."
            ;;
        *)
            echo "Invalid choice. Skipping other UI installation."
            ;;
    esac
}

# Function to uninstall other UI management tools
uninstall_other_ui() {
    echo "Uninstalling other Docker UI management tools..."
    echo "Option 1: LazyDocker"
    echo "Option 2: Yacht"
    echo "Option 3: DockStation"
    read -p "Choose a tool to uninstall (1/2/3): " choice
    case $choice in
        1)
            echo "Uninstalling LazyDocker..."
            rm -f /usr/local/bin/lazydocker
            echo "LazyDocker uninstalled successfully."
            ;;
        2)
            echo "Uninstalling Yacht..."
            docker stop yacht || true
            docker rm yacht || true
            docker volume rm yacht_data || true
            echo "Yacht uninstalled successfully."
            ;;
        3)
            echo "Uninstalling DockStation..."
            echo "If DockStation was installed manually, please remove it manually."
            ;;
        *)
            echo "Invalid choice. Skipping uninstallation."
            ;;
    esac
}

# Uninstallation functions
uninstall_docker() {
    echo "Uninstalling Docker and associated containers..."
    docker stop $(docker ps -q) || true
    docker rm $(docker ps -a -q) || true
    apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    apt-get autoremove -y
    rm -rf /var/lib/docker
    rm -rf /etc/apt/keyrings/docker.gpg
    echo "Docker uninstalled successfully."
}

uninstall_portainer() {
    echo "Uninstalling Portainer..."
    docker stop portainer || true
    docker rm portainer || true
    docker volume rm portainer_data || true
    echo "Portainer uninstalled successfully."
}

# Health check function
health_check() {
    echo "Running health check for Docker..."
    if docker info &>/dev/null; then
        echo "Docker is running properly."
    else
        echo "Docker is not running. Please check the service."
    fi
    echo "Checking active containers..."
    docker ps
}

# Main menu
while true; do
    echo "Main Menu:
    1) Install Docker
    2) Install Portainer
    3) Install other UI tools
    4) Uninstall Docker
    5) Uninstall Portainer
    6) Uninstall other UI tools
    7) Health Check
    8) Exit"
    read -p "Choose an option: " main_choice
    case $main_choice in
        1)
            install_docker
            ;;
        2)
            read -p "Enter custom port for Portainer (default 9000): " port
            port=${port:-9000}
            install_portainer $port
            ;;
        3)
            install_other_ui
            ;;
        4)
            uninstall_docker
            ;;
        5)
            uninstall_portainer
            ;;
        6)
            uninstall_other_ui
            ;;
        7)
            health_check
            ;;
        8)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done

exit 0
