#!/bin/bash

# Docker and containerization support module
# Provides Docker, container tools, and development environment containerization

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Docker installation functions
install_docker_linux() {
    local os_type=$1
    
    echo -e "${CYAN}Installing Docker for Linux ($os_type)${NC}"
    
    case $os_type in
        "debian"|"ubuntu")
            # Remove old versions
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Update package index
            sudo apt-get update
            
            # Install prerequisites
            sudo apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Add Docker repository
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
            
        "fedora"|"rhel"|"centos")
            # Remove old versions
            sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
            
            # Install prerequisites
            sudo dnf install -y dnf-plugins-core
            
            # Add Docker repository
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            
            # Install Docker
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
            
        "arch")
            # Install Docker from official repositories
            sudo pacman -S --noconfirm docker docker-compose
            ;;
    esac
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}✅ Docker installed successfully${NC}"
    echo -e "${YELLOW}Note: You may need to log out and back in for group changes to take effect${NC}"
}

install_docker_macos() {
    echo -e "${CYAN}Installing Docker Desktop for macOS${NC}"
    
    if command -v brew &> /dev/null; then
        brew install --cask docker
    else
        echo -e "${YELLOW}Homebrew not found. Please install Docker Desktop manually from:${NC}"
        echo "https://docs.docker.com/desktop/mac/install/"
        return 1
    fi
    
    echo -e "${GREEN}✅ Docker Desktop installed${NC}"
    echo -e "${YELLOW}Please start Docker Desktop from Applications folder${NC}"
}

install_docker_windows() {
    echo -e "${CYAN}Installing Docker Desktop for Windows${NC}"
    
    # This would typically be called from PowerShell
    echo "Docker Desktop installation on Windows requires:"
    echo "1. Windows 10/11 Pro, Enterprise, or Education"
    echo "2. WSL 2 enabled"
    echo "3. Virtualization enabled in BIOS"
    echo ""
    echo "Download from: https://docs.docker.com/desktop/windows/install/"
    
    return 0
}

# Container development tools
install_container_tools() {
    local os_type=$1
    
    echo -e "${CYAN}Installing container development tools${NC}"
    
    case $os_type in
        "debian"|"ubuntu")
            sudo apt-get install -y \
                podman \
                buildah \
                skopeo \
                ctop \
                dive
            ;;
            
        "fedora"|"rhel"|"centos")
            sudo dnf install -y \
                podman \
                buildah \
                skopeo \
                ctop
            # Install dive manually
            install_dive_manual
            ;;
            
        "arch")
            sudo pacman -S --noconfirm \
                podman \
                buildah \
                skopeo
            # Install ctop and dive from AUR
            if command -v yay &> /dev/null; then
                yay -S --noconfirm ctop-bin dive
            fi
            ;;
            
        "macos")
            if command -v brew &> /dev/null; then
                brew install \
                    podman \
                    buildah \
                    skopeo \
                    ctop \
                    dive
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ Container tools installed${NC}"
}

install_dive_manual() {
    local dive_version="0.10.0"
    local arch
    local os
    arch=$(uname -m)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case $arch in
        "x86_64") arch="amd64" ;;
        "aarch64") arch="arm64" ;;
    esac
    
    local download_url="https://github.com/wagoodman/dive/releases/download/v${dive_version}/dive_${dive_version}_${os}_${arch}.tar.gz"
    local temp_dir=$(mktemp -d)
    
    echo -e "${BLUE}Installing dive ${dive_version}${NC}"
    
    curl -L "$download_url" | tar -xz -C "$temp_dir"
    sudo mv "$temp_dir/dive" /usr/local/bin/
    sudo chmod +x /usr/local/bin/dive
    
    rm -rf "$temp_dir"
    echo -e "${GREEN}✅ dive installed${NC}"
}

# Kubernetes tools
install_kubernetes_tools() {
    local os_type=$1
    
    echo -e "${CYAN}Installing Kubernetes tools${NC}"
    
    # Install kubectl
    case $os_type in
        "debian"|"ubuntu")
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
            
        "fedora"|"rhel"|"centos")
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
            
        "arch")
            sudo pacman -S --noconfirm kubectl
            ;;
            
        "macos")
            if command -v brew &> /dev/null; then
                brew install kubectl
            fi
            ;;
    esac
    
    # Install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Install kind (Kubernetes in Docker)
    case $os_type in
        "linux")
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
            sudo mv ./kind /usr/local/bin/kind
            sudo chmod +x /usr/local/bin/kind
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install kind
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ Kubernetes tools installed${NC}"
}

# Development environment containers
create_dev_containers() {
    echo -e "${CYAN}Creating development environment containers${NC}"
    
    # Create a dev-containers directory
    mkdir -p "$HOME/dev-containers"
    
    # Node.js development container
    cat > "$HOME/dev-containers/Dockerfile.nodejs" << 'EOF'
FROM node:18-bullseye

# Install development tools
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g \
    typescript \
    @types/node \
    nodemon \
    pm2 \
    eslint \
    prettier

# Create workspace
WORKDIR /workspace
VOLUME ["/workspace"]

# Default command
CMD ["bash"]
EOF

    # Python development container
    cat > "$HOME/dev-containers/Dockerfile.python" << 'EOF'
FROM python:3.11-bullseye

# Install development tools
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install \
    jupyter \
    pandas \
    numpy \
    requests \
    flask \
    fastapi \
    pytest \
    black \
    flake8

# Create workspace
WORKDIR /workspace
VOLUME ["/workspace"]

# Default command
CMD ["bash"]
EOF

    # Go development container
    cat > "$HOME/dev-containers/Dockerfile.golang" << 'EOF'
FROM golang:1.19-bullseye

# Install development tools
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Go tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest

# Create workspace
WORKDIR /workspace
VOLUME ["/workspace"]

# Default command
CMD ["bash"]
EOF

    # Create docker-compose for development environments
    cat > "$HOME/dev-containers/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  nodejs:
    build:
      context: .
      dockerfile: Dockerfile.nodejs
    volumes:
      - ./workspace:/workspace
    ports:
      - "3000:3000"
      - "8080:8080"
    working_dir: /workspace
    command: tail -f /dev/null

  python:
    build:
      context: .
      dockerfile: Dockerfile.python
    volumes:
      - ./workspace:/workspace
    ports:
      - "8000:8000"
      - "5000:5000"
      - "8888:8888"
    working_dir: /workspace
    command: tail -f /dev/null

  golang:
    build:
      context: .
      dockerfile: Dockerfile.golang
    volumes:
      - ./workspace:/workspace
    ports:
      - "8090:8090"
    working_dir: /workspace
    command: tail -f /dev/null

  database:
    image: postgres:15
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: developer
      POSTGRES_PASSWORD: devpass123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
EOF

    # Create helper scripts
    cat > "$HOME/dev-containers/start-dev.sh" << 'EOF'
#!/bin/bash

# Development environment starter script

echo "🐳 Starting development containers..."

# Create workspace directory
mkdir -p workspace

# Start all services
docker-compose up -d

echo "✅ Development environment is ready!"
echo ""
echo "Available services:"
echo "  - Node.js:    docker-compose exec nodejs bash"
echo "  - Python:     docker-compose exec python bash"
echo "  - Go:         docker-compose exec golang bash"
echo "  - PostgreSQL: localhost:5432 (user: developer, pass: devpass123)"
echo "  - Redis:      localhost:6379"
echo ""
echo "To stop: docker-compose down"
EOF

    chmod +x "$HOME/dev-containers/start-dev.sh"
    
    echo -e "${GREEN}✅ Development containers created at ~/dev-containers${NC}"
    echo -e "${BLUE}Usage: cd ~/dev-containers && ./start-dev.sh${NC}"
}

# Verify Docker installation
verify_docker() {
    echo -e "${CYAN}Verifying Docker installation${NC}"
    
    if command -v docker &> /dev/null; then
        if docker --version &> /dev/null; then
            echo -e "${GREEN}✅ Docker is installed and working${NC}"
            
            # Test with hello-world if not in dry-run mode
            if [ "${DRY_RUN:-false}" = "false" ]; then
                echo -e "${BLUE}Testing with hello-world container...${NC}"
                if docker run --rm hello-world &> /dev/null; then
                    echo -e "${GREEN}✅ Docker test successful${NC}"
                else
                    echo -e "${YELLOW}⚠️  Docker test failed - you may need to start Docker service or restart your session${NC}"
                fi
            fi
            
            return 0
        else
            echo -e "${RED}❌ Docker is installed but not working${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Docker is not installed${NC}"
        return 1
    fi
}

# Main Docker setup function
setup_docker() {
    local os_type=$1
    local install_tools=${2:-true}
    local install_k8s=${3:-false}
    local create_dev_env=${4:-true}
    
    echo -e "${CYAN}🐳 Setting up Docker and containerization tools${NC}"
    
    # Install Docker based on OS
    case $os_type in
        "debian"|"ubuntu"|"fedora"|"rhel"|"centos"|"arch")
            install_docker_linux "$os_type"
            ;;
        "macos")
            install_docker_macos
            ;;
        "windows")
            install_docker_windows
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS for Docker installation: $os_type${NC}"
            return 1
            ;;
    esac
    
    # Install additional container tools
    if [ "$install_tools" = "true" ]; then
        install_container_tools "$os_type"
    fi
    
    # Install Kubernetes tools
    if [ "$install_k8s" = "true" ]; then
        install_kubernetes_tools "$os_type"
    fi
    
    # Create development containers
    if [ "$create_dev_env" = "true" ]; then
        create_dev_containers
    fi
    
    # Verify installation
    verify_docker
    
    echo -e "${GREEN}🎉 Docker setup complete!${NC}"
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. If on Linux, log out and back in for group changes"
    echo "  2. Start Docker Desktop (macOS/Windows)"
    echo "  3. Try: cd ~/dev-containers && ./start-dev.sh"
}

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being run directly
    OS_TYPE="${1:-}"
    if [ -z "$OS_TYPE" ]; then
        echo "Usage: $0 <os_type> [install_tools] [install_k8s] [create_dev_env]"
        echo "Example: $0 debian true false true"
        exit 1
    fi
    
    setup_docker "$@"
fi
