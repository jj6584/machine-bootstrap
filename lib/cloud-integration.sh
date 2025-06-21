#!/bin/bash

# Cloud integration module
# Provides cloud provider tools and deployment utilities

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Cloud providers configuration
declare -A CLOUD_PROVIDERS
CLOUD_PROVIDERS[aws]="Amazon Web Services"
CLOUD_PROVIDERS[azure]="Microsoft Azure"
CLOUD_PROVIDERS[gcp]="Google Cloud Platform"
CLOUD_PROVIDERS[do]="DigitalOcean"
CLOUD_PROVIDERS[linode]="Linode"
CLOUD_PROVIDERS[vultr]="Vultr"

# Install AWS CLI
install_aws_cli() {
    local os_type="$1"
    
    echo -e "${CYAN}Installing AWS CLI v2${NC}"
    
    case "$os_type" in
        "debian"|"ubuntu"|"linux")
            # Download and install AWS CLI v2
            local temp_dir=$(mktemp -d)
            cd "$temp_dir"
            
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip -q awscliv2.zip
            sudo ./aws/install
            
            cd - > /dev/null
            rm -rf "$temp_dir"
            ;;
            
        "macos")
            if command -v brew &> /dev/null; then
                brew install awscli
            else
                # Download and install AWS CLI v2 for macOS
                local temp_dir=$(mktemp -d)
                cd "$temp_dir"
                
                curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
                sudo installer -pkg AWSCLIV2.pkg -target /
                
                cd - > /dev/null
                rm -rf "$temp_dir"
            fi
            ;;
            
        "arch")
            sudo pacman -S --noconfirm aws-cli
            ;;
            
        "fedora"|"rhel"|"centos")
            sudo dnf install -y awscli
            ;;
    esac
    
    # Install additional AWS tools
    echo -e "${BLUE}Installing additional AWS tools${NC}"
    
    # Install AWS SAM CLI
    case "$os_type" in
        "debian"|"ubuntu"|"linux")
            pip3 install --user aws-sam-cli 2>/dev/null || echo "SAM CLI installation skipped"
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install aws-sam-cli
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ AWS CLI installed${NC}"
}

# Install Azure CLI
install_azure_cli() {
    local os_type="$1"
    
    echo -e "${CYAN}Installing Azure CLI${NC}"
    
    case "$os_type" in
        "debian"|"ubuntu")
            # Microsoft's official installation method
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            ;;
            
        "fedora"|"rhel"|"centos")
            # Import Microsoft repository key
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            
            # Add Microsoft repository
            echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
            
            # Install
            sudo dnf install -y azure-cli
            ;;
            
        "arch")
            if command -v yay &> /dev/null; then
                yay -S --noconfirm azure-cli
            else
                echo -e "${YELLOW}AUR helper (yay) not found. Please install azure-cli manually.${NC}"
            fi
            ;;
            
        "macos")
            if command -v brew &> /dev/null; then
                brew install azure-cli
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ Azure CLI installed${NC}"
}

# Install Google Cloud CLI
install_gcp_cli() {
    local os_type="$1"
    
    echo -e "${CYAN}Installing Google Cloud CLI${NC}"
    
    case "$os_type" in
        "debian"|"ubuntu")
            # Add Google Cloud repository
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            
            # Import Google Cloud public key
            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
            
            # Install
            sudo apt-get update
            sudo apt-get install -y google-cloud-cli
            ;;
            
        "fedora"|"rhel"|"centos")
            # Add Google Cloud repository
            sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << 'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
            
            # Install
            sudo dnf install -y google-cloud-cli
            ;;
            
        "arch")
            if command -v yay &> /dev/null; then
                yay -S --noconfirm google-cloud-cli
            else
                echo -e "${YELLOW}AUR helper (yay) not found. Please install google-cloud-cli manually.${NC}"
            fi
            ;;
            
        "macos")
            if command -v brew &> /dev/null; then
                brew install google-cloud-sdk
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ Google Cloud CLI installed${NC}"
}

# Install DigitalOcean CLI
install_do_cli() {
    local os_type="$1"
    
    echo -e "${CYAN}Installing DigitalOcean CLI (doctl)${NC}"
    
    local doctl_version="1.94.0"
    local arch
    arch=$(uname -m)
    local os_name
    
    case "$os_type" in
        "linux"|"debian"|"ubuntu"|"fedora"|"rhel"|"centos"|"arch")
            os_name="linux"
            ;;
        "macos")
            os_name="darwin"
            ;;
        *)
            echo -e "${RED}Unsupported OS for doctl: $os_type${NC}"
            return 1
            ;;
    esac
    
    case "$arch" in
        "x86_64") arch="amd64" ;;
        "aarch64") arch="arm64" ;;
    esac
    
    local download_url="https://github.com/digitalocean/doctl/releases/download/v${doctl_version}/doctl-${doctl_version}-${os_name}-${arch}.tar.gz"
    local temp_dir=$(mktemp -d)
    
    cd "$temp_dir"
    curl -L "$download_url" | tar -xz
    sudo mv doctl /usr/local/bin/
    sudo chmod +x /usr/local/bin/doctl
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✅ DigitalOcean CLI installed${NC}"
}

# Install Linode CLI
install_linode_cli() {
    local os_type="$1"
    
    echo -e "${CYAN}Installing Linode CLI${NC}"
    
    # Linode CLI is Python-based
    if command -v pip3 &> /dev/null; then
        pip3 install --user linode-cli
    elif command -v pip &> /dev/null; then
        pip install --user linode-cli
    else
        echo -e "${RED}❌ Python pip not found. Please install Python first.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Linode CLI installed${NC}"
}

# Install Terraform
install_terraform() {
    local os_type="$1"
    
    echo -e "${CYAN}Installing Terraform${NC}"
    
    case "$os_type" in
        "debian"|"ubuntu")
            # Add HashiCorp repository
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
            sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
            sudo apt-get update
            sudo apt-get install -y terraform
            ;;
            
        "fedora"|"rhel"|"centos")
            # Add HashiCorp repository
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
            sudo dnf install -y terraform
            ;;
            
        "arch")
            sudo pacman -S --noconfirm terraform
            ;;
            
        "macos")
            if command -v brew &> /dev/null; then
                brew install terraform
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ Terraform installed${NC}"
}

# Install Ansible
install_ansible() {
    local os_type="$1"
    
    echo -e "${CYAN}Installing Ansible${NC}"
    
    case "$os_type" in
        "debian"|"ubuntu")
            sudo apt-get update
            sudo apt-get install -y ansible
            ;;
            
        "fedora"|"rhel"|"centos")
            sudo dnf install -y ansible
            ;;
            
        "arch")
            sudo pacman -S --noconfirm ansible
            ;;
            
        "macos")
            if command -v brew &> /dev/null; then
                brew install ansible
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ Ansible installed${NC}"
}

# Install cloud monitoring tools
install_monitoring_tools() {
    local os_type="$1"
    
    echo -e "${CYAN}Installing cloud monitoring tools${NC}"
    
    # Install Prometheus node exporter
    case "$os_type" in
        "debian"|"ubuntu")
            sudo apt-get install -y prometheus-node-exporter
            ;;
        "fedora"|"rhel"|"centos")
            sudo dnf install -y golang-github-prometheus-node-exporter
            ;;
        "arch")
            sudo pacman -S --noconfirm prometheus-node-exporter
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install node_exporter
            fi
            ;;
    esac
    
    # Install other monitoring tools via packages
    if command -v pip3 &> /dev/null; then
        pip3 install --user \
            awslogs \
            azure-monitor-query \
            google-cloud-monitoring
    fi
    
    echo -e "${GREEN}✅ Monitoring tools installed${NC}"
}

# Create cloud deployment templates
create_deployment_templates() {
    local templates_dir="$HOME/.config/machine-bootstrap/cloud-templates"
    
    echo -e "${CYAN}Creating cloud deployment templates${NC}"
    
    mkdir -p "$templates_dir"
    
    # AWS CloudFormation template
    cat > "$templates_dir/aws-instance.yaml" << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Basic EC2 instance with machine-bootstrap'

Parameters:
  InstanceType:
    Type: String
    Default: t3.micro
    Description: EC2 instance type
  
  KeyName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: EC2 Key Pair for SSH access

Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      KeyName: !Ref KeyName
      ImageId: ami-0c02fb55956c7d316  # Amazon Linux 2
      SecurityGroups:
        - !Ref InstanceSecurityGroup
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s dev

  InstanceSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Enable SSH access
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0

Outputs:
  InstanceId:
    Description: Instance ID
    Value: !Ref EC2Instance
  PublicIP:
    Description: Public IP address
    Value: !GetAtt EC2Instance.PublicIp
EOF

    # Terraform AWS template
    cat > "$templates_dir/aws-terraform.tf" << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair name"
  type        = string
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "machine_bootstrap" {
  name_prefix = "machine-bootstrap-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "machine_bootstrap" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.machine_bootstrap.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s dev
              EOF

  tags = {
    Name = "machine-bootstrap-instance"
  }
}

output "instance_id" {
  value = aws_instance.machine_bootstrap.id
}

output "public_ip" {
  value = aws_instance.machine_bootstrap.public_ip
}

output "ssh_command" {
  value = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.machine_bootstrap.public_ip}"
}
EOF

    # Docker Compose for cloud deployment
    cat > "$templates_dir/docker-compose-cloud.yml" << 'EOF'
version: '3.8'

services:
  app:
    build: .
    ports:
      - "80:3000"
    environment:
      - NODE_ENV=production
    volumes:
      - app_data:/app/data
    restart: unless-stopped

  database:
    image: postgres:15
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  app_data:
  postgres_data:
  redis_data:
EOF

    # Ansible playbook
    cat > "$templates_dir/ansible-setup.yml" << 'EOF'
---
- name: Setup development environment with machine-bootstrap
  hosts: all
  become: yes
  
  vars:
    bootstrap_category: dev
    
  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"
      
    - name: Install curl
      package:
        name: curl
        state: present
        
    - name: Download and run machine-bootstrap
      shell: |
        curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s {{ bootstrap_category }}
      become_user: "{{ ansible_user }}"
      
    - name: Verify installation
      command: docker --version
      register: docker_version
      
    - name: Display Docker version
      debug:
        msg: "Docker installed: {{ docker_version.stdout }}"
EOF

    # Create deployment script
    cat > "$templates_dir/deploy.sh" << 'EOF'
#!/bin/bash

# Cloud deployment helper script

set -euo pipefail

CLOUD_PROVIDER=""
TEMPLATE_TYPE=""

show_help() {
    echo "Cloud Deployment Helper"
    echo ""
    echo "Usage: $0 <provider> <template> [options]"
    echo ""
    echo "Providers:"
    echo "  aws      - Amazon Web Services"
    echo "  azure    - Microsoft Azure"
    echo "  gcp      - Google Cloud Platform"
    echo "  do       - DigitalOcean"
    echo ""
    echo "Templates:"
    echo "  terraform    - Terraform configuration"
    echo "  cloudform    - AWS CloudFormation"
    echo "  ansible      - Ansible playbook"
    echo "  docker       - Docker Compose"
    echo ""
    echo "Examples:"
    echo "  $0 aws terraform"
    echo "  $0 azure ansible"
    echo "  $0 do docker"
}

deploy_aws_terraform() {
    echo "Deploying to AWS with Terraform..."
    
    if [ ! -f "terraform.tfvars" ]; then
        echo "Creating terraform.tfvars..."
        cat > terraform.tfvars << TFVARS_EOF
aws_region = "us-west-2"
instance_type = "t3.micro"
key_name = "my-key-pair"
TFVARS_EOF
        echo "Please edit terraform.tfvars with your settings"
        return 1
    fi
    
    terraform init
    terraform plan
    terraform apply
}

deploy_ansible() {
    echo "Deploying with Ansible..."
    
    if [ ! -f "inventory.ini" ]; then
        echo "Creating sample inventory.ini..."
        cat > inventory.ini << INVENTORY_EOF
[servers]
server1 ansible_host=YOUR_SERVER_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
INVENTORY_EOF
        echo "Please edit inventory.ini with your server details"
        return 1
    fi
    
    ansible-playbook -i inventory.ini ansible-setup.yml
}

case "${1:-help}" in
    "aws")
        CLOUD_PROVIDER="aws"
        TEMPLATE_TYPE="${2:-terraform}"
        
        case "$TEMPLATE_TYPE" in
            "terraform")
                cp aws-terraform.tf main.tf
                deploy_aws_terraform
                ;;
            "cloudform")
                echo "Deploy with: aws cloudformation create-stack --stack-name machine-bootstrap --template-body file://aws-instance.yaml --parameters ParameterKey=KeyName,ParameterValue=YOUR_KEY_NAME"
                ;;
            *)
                echo "Unknown template type: $TEMPLATE_TYPE"
                exit 1
                ;;
        esac
        ;;
    "ansible")
        deploy_ansible
        ;;
    "docker")
        echo "Starting Docker Compose deployment..."
        docker-compose -f docker-compose-cloud.yml up -d
        ;;
    *)
        show_help
        ;;
esac
EOF

    chmod +x "$templates_dir/deploy.sh"
    
    echo -e "${GREEN}✅ Cloud templates created at: $templates_dir${NC}"
}

# Main cloud setup function
setup_cloud_tools() {
    local providers="$1"
    local os_type="$2"
    local include_terraform="${3:-true}"
    local include_ansible="${4:-true}"
    local create_templates="${5:-true}"
    
    echo -e "${CYAN}☁️  Setting up cloud integration tools${NC}"
    
    # Install cloud provider CLIs
    IFS=',' read -ra PROVIDER_LIST <<< "$providers"
    for provider in "${PROVIDER_LIST[@]}"; do
        case "$provider" in
            "aws")
                install_aws_cli "$os_type"
                ;;
            "azure")
                install_azure_cli "$os_type"
                ;;
            "gcp")
                install_gcp_cli "$os_type"
                ;;
            "do")
                install_do_cli "$os_type"
                ;;
            "linode")
                install_linode_cli "$os_type"
                ;;
            *)
                echo -e "${YELLOW}⚠️  Unknown cloud provider: $provider${NC}"
                ;;
        esac
    done
    
    # Install Infrastructure as Code tools
    if [ "$include_terraform" = "true" ]; then
        install_terraform "$os_type"
    fi
    
    if [ "$include_ansible" = "true" ]; then
        install_ansible "$os_type"
    fi
    
    # Install monitoring tools
    install_monitoring_tools "$os_type"
    
    # Create deployment templates
    if [ "$create_templates" = "true" ]; then
        create_deployment_templates
    fi
    
    echo -e "${GREEN}🎉 Cloud tools setup complete!${NC}"
    echo -e "${BLUE}Available providers: ${providers}${NC}"
    echo -e "${BLUE}Templates location: ~/.config/machine-bootstrap/cloud-templates${NC}"
}

# List available cloud tools
list_cloud_tools() {
    echo -e "${CYAN}☁️  Installed Cloud Tools${NC}"
    
    echo -e "${BLUE}Cloud Provider CLIs:${NC}"
    command -v aws &>/dev/null && echo "  ✅ AWS CLI: $(aws --version 2>&1 | head -1)"
    command -v az &>/dev/null && echo "  ✅ Azure CLI: $(az --version | head -1)"
    command -v gcloud &>/dev/null && echo "  ✅ Google Cloud CLI: $(gcloud --version | head -1)"
    command -v doctl &>/dev/null && echo "  ✅ DigitalOcean CLI: $(doctl version)"
    command -v linode-cli &>/dev/null && echo "  ✅ Linode CLI: $(linode-cli --version)"
    
    echo -e "${BLUE}Infrastructure Tools:${NC}"
    command -v terraform &>/dev/null && echo "  ✅ Terraform: $(terraform --version | head -1)"
    command -v ansible &>/dev/null && echo "  ✅ Ansible: $(ansible --version | head -1)"
    
    echo -e "${BLUE}Monitoring:${NC}"
    command -v node_exporter &>/dev/null && echo "  ✅ Prometheus Node Exporter"
    
    if [ ! -x "$(command -v aws)" ] && [ ! -x "$(command -v az)" ] && [ ! -x "$(command -v gcloud)" ]; then
        echo -e "${YELLOW}No cloud tools installed. Run with --cloud to install.${NC}"
    fi
}

# Export functions for use in main script
export -f setup_cloud_tools list_cloud_tools

# Handle direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-help}" in
        "setup")
            providers="${2:-aws,azure,gcp}"
            os_type="${3:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
            setup_cloud_tools "$providers" "$os_type"
            ;;
        "list")
            list_cloud_tools
            ;;
        *)
            echo "Usage: $0 {setup|list}"
            echo ""
            echo "Commands:"
            echo "  setup <providers> <os>  - Setup cloud tools"
            echo "  list                    - List installed tools"
            echo ""
            echo "Example:"
            echo "  $0 setup aws,azure,gcp linux"
            ;;
    esac
fi
