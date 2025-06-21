#!/bin/bash

# Example: Using Machine Bootstrap with all low-priority features
# This demonstrates the complete feature set including GUI, Docker, analytics, plugins, and cloud

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 Machine Bootstrap - Complete Feature Demo${NC}"
echo ""

# Demo 1: GUI Installation
echo -e "${BLUE}Demo 1: GUI Installation${NC}"
echo "Install with graphical interface:"
echo "curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --gui dev"
echo ""

# Demo 2: Docker Development Environment
echo -e "${BLUE}Demo 2: Docker Development Environment${NC}"
echo "Install with Docker containerization support:"
echo "curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --docker dev"
echo ""
echo "After installation, start development containers:"
echo "cd ~/dev-containers && ./start-dev.sh"
echo ""

# Demo 3: Cloud Integration
echo -e "${BLUE}Demo 3: Cloud Integration${NC}"
echo "Install with cloud provider tools:"
echo "curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --cloud dev"
echo ""
echo "This installs:"
echo "  ✓ AWS CLI and SAM CLI"
echo "  ✓ Azure CLI"
echo "  ✓ Google Cloud CLI"
echo "  ✓ Terraform and Ansible"
echo "  ✓ Deployment templates"
echo ""

# Demo 4: Plugin System
echo -e "${BLUE}Demo 4: Plugin System${NC}"
echo "Install with plugin support:"
echo "curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --plugins dev"
echo ""
echo "Manage plugins:"
echo "  # List available plugins"
echo "  bash lib/plugin-system.sh list"
echo ""
echo "  # Create custom plugin"
echo "  bash lib/plugin-system.sh create my-company-tools"
echo ""
echo "  # Enable plugin"
echo "  bash lib/plugin-system.sh enable my-company-tools"
echo ""

# Demo 5: Analytics
echo -e "${BLUE}Demo 5: Anonymous Analytics${NC}"
echo "Install with usage analytics:"
echo "curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --analytics dev"
echo ""
echo "Check analytics status:"
echo "bash lib/analytics.sh status"
echo ""

# Demo 6: Complete Installation
echo -e "${BLUE}Demo 6: All Features Combined${NC}"
echo "Install everything with all low-priority features:"
echo "curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --gui --docker --cloud --plugins --analytics all"
echo ""

# Demo 7: Dry Run with Features
echo -e "${BLUE}Demo 7: Preview Installation${NC}"
echo "Preview what would be installed:"
echo "curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --dry-run --docker --cloud dev"
echo ""

# Demo 8: Enterprise Setup
echo -e "${BLUE}Demo 8: Enterprise/Team Setup${NC}"
echo "Complete setup for enterprise development:"
echo "curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- \\"
echo "  --backup \\"
echo "  --parallel \\"
echo "  --docker \\"
echo "  --cloud \\"
echo "  --plugins \\"
echo "  --analytics \\"
echo "  --system-check \\"
echo "  --security-check \\"
echo "  all"
echo ""

echo -e "${GREEN}📋 Feature Summary${NC}"
echo ""
echo -e "${YELLOW}High Priority (Implemented):${NC}"
echo "  ✅ Cross-platform one-liner installation"
echo "  ✅ Configuration management (YAML)"
echo "  ✅ System requirements checking"
echo "  ✅ Security verification and scanning"
echo "  ✅ Update and maintenance system"
echo "  ✅ Advanced CLI with comprehensive options"
echo "  ✅ Error handling and rollback"
echo "  ✅ Progress tracking and logging"
echo ""
echo -e "${YELLOW}Low Priority (Now Implemented):${NC}"
echo "  ✅ GUI interface integration"
echo "  ✅ Docker containerization support"
echo "  ✅ Anonymous usage analytics"
echo "  ✅ Plugin system for extensibility"
echo "  ✅ Cloud integration (AWS, Azure, GCP)"
echo "  ✅ Development container templates"
echo "  ✅ Infrastructure as Code templates"
echo "  ✅ Monitoring tools integration"
echo ""

echo -e "${CYAN}🎉 Machine Bootstrap is now feature-complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Try the examples above"
echo "2. Create custom configurations in ~/.config/machine-bootstrap/"
echo "3. Develop custom plugins for your organization"
echo "4. Use the cloud templates for deployment"
echo "5. Enable analytics to help improve the tool"
