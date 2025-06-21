# Machine Bootstrap Documentation

Complete guide for using and customizing the Machine Bootstrap installer.

## Table of Contents

- [Installation](#installation)
- [Command Reference](#command-reference)
- [Configuration](#configuration)
- [GPU & Gaming Setup](#gpu--gaming-setup)
- [Package Categories](#package-categories)
- [Advanced Features](#advanced-features)
- [Development](#development)
- [Troubleshooting](#troubleshooting)

## Installation

### One-Liner Installation

**Linux/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.ps1 | iex
```

### Package Categories

| Category | Description | Platforms |
|----------|-------------|-----------|
| `basic` | Essential applications (browsers, media players, text editors) | All |
| `dev` | Development tools (Git, Docker, IDEs, databases) | All |
| `remote` | Remote work tools (Zoom, Teams, VPN clients) | All |
| `all` | Everything above | All |

### Category-Specific Installation

```bash
# Install specific categories
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s basic
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s dev
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s remote
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s all
```

## Command Reference

### Basic Options

| Option | Description | Example |
|--------|-------------|---------|
| `-h, --help` | Show help message | `bash install.sh --help` |
| `-v, --version` | Show version | `bash install.sh --version` |
| `-c, --config FILE` | Use custom config | `bash install.sh --config myconfig.yml` |
| `-d, --dry-run` | Preview installation | `bash install.sh --dry-run dev` |
| `-q, --quiet` | Minimal output | `bash install.sh --quiet basic` |
| `-f, --force` | Force reinstall | `bash install.sh --force dev` |

### System Options

| Option | Description | Example |
|--------|-------------|---------|
| `--system-check` | Check system requirements | `bash install.sh --system-check` |
| `--security-check` | Run security audit | `bash install.sh --security-check` |
| `--skip-checks` | Skip all checks | `bash install.sh --skip-checks dev` |
| `--backup` | Create backup | `bash install.sh --backup --force all` |

### Advanced Options

| Option | Description | Example |
|--------|-------------|---------|
| `--parallel` | Parallel installation | `bash install.sh --parallel dev` |
| `--timeout SECONDS` | Set timeout | `bash install.sh --timeout 600 all` |
| `--log-level LEVEL` | Set log level | `bash install.sh --log-level debug dev` |
| `--gui` | Use GUI interface | `bash install.sh --gui dev` |
| `--no-snap` | Skip snap packages | `bash install.sh --no-snap basic` |
| `--no-flatpak` | Skip flatpak packages | `bash install.sh --no-flatpak basic` |

### GPU & Gaming Options

| Option | Description | Example |
|--------|-------------|---------|
| `--gpu` | Interactive GPU setup | `bash install.sh --gpu dev` |
| `--auto-gpu` | Auto-detect GPU drivers | `bash install.sh --auto-gpu all` |

### Feature Options

| Option | Description | Example |
|--------|-------------|---------|
| `--docker` | Include Docker setup | `bash install.sh --docker dev` |
| `--cloud` | Cloud tools (AWS, Azure, GCP) | `bash install.sh --cloud dev` |
| `--plugins` | Enable plugin system | `bash install.sh --plugins dev` |
| `--analytics` | Enable usage analytics | `bash install.sh --analytics dev` |

### Complete Examples

```bash
# Full development setup with all features
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- \
  --gpu --docker --cloud --plugins --backup --parallel dev

# Gaming setup with GPU auto-detection
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- \
  --auto-gpu --config gaming.yml all

# Preview enterprise setup
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- \
  --dry-run --docker --cloud --security-check dev
```

## Configuration

### Configuration File Locations

1. `~/.config/machine-bootstrap/config.yml` (user-specific)
2. `./config.yml` (project directory)
3. Custom file with `--config` option

### Default Configuration

Download the example configuration:
```bash
mkdir -p ~/.config/machine-bootstrap
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/config.yml.example \
  -o ~/.config/machine-bootstrap/config.yml
```

### Configuration Structure

```yaml
# Global settings
settings:
  auto_update: true
  create_backup: true
  skip_existing: true
  parallel_install: false
  log_level: "info"
  max_retries: 3
  timeout: 300

# Default categories to install
default_categories:
  - basic
  - dev

# System requirements
requirements:
  min_disk_space_gb: 2
  min_ram_gb: 1

# Custom package lists (override defaults)
packages:
  windows:
    basic:
      chocolatey:
        - "firefox"
        - "vscode"
  linux:
    basic:
      apt:
        - "firefox"
        - "code"

# Environment variables
environment:
  EDITOR: "vim"
  GIT_EDITOR: "vim"

# Post-installation scripts
post_install:
  - name: "Configure Git"
    script: "scripts/configure_git.sh"
    condition: "command -v git"
```

### Gaming Configuration

Use the pre-configured gaming setup:
```bash
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- \
  --config gaming.yml all
```

## GPU & Gaming Setup

### Auto-Detection

```bash
# Automatically detect and install GPU drivers
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --auto-gpu
```

### Manual GPU Setup

```bash
# Interactive GPU driver selection
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --gpu
```

### GPU Diagnostics

```bash
# Run GPU diagnostics directly
./lib/gpu-support.sh

# Or download and run
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/lib/gpu-support.sh | bash
```

### Supported GPU Types

| GPU Type | Linux | Windows | macOS |
|----------|-------|---------|-------|
| **NVIDIA** | ✅ NVIDIA drivers, CUDA | ✅ Auto-download link | ✅ System managed |
| **AMD** | ✅ AMDGPU, ROCm | ✅ Auto-download link | ✅ System managed |
| **Intel** | ✅ Mesa, VA-API | ✅ System managed | ✅ System managed |

### Gaming Environment

The gaming setup includes:

- **Steam** - Game platform and launcher
- **Lutris** - Open gaming platform (Linux)
- **Wine** - Windows compatibility layer (Linux/macOS)
- **GameMode** - Gaming optimizations (Linux)
- **32-bit libraries** - Legacy game support
- **Vulkan/OpenGL** - Graphics API support

## Package Categories

### Basic Packages

**Windows:**
- 7zip, VLC, Adobe Reader, Firefox, Discord, VS Code, Steam, Windows Terminal

**Linux:**
- curl, wget, git, vim, firefox, vlc, discord, code, steam

**macOS:**
- Homebrew, firefox, vlc, discord, visual-studio-code, steam

### Developer Packages

**Windows:**
- Git, Node.js, Python, Docker Desktop, Postman, PowerShell Core, Windows Terminal

**Linux:**
- nodejs, npm, python3, docker, mysql-server, postgresql, redis, build-essential

**macOS:**
- git, node, python, docker, mysql, postgresql, redis, jetbrains-toolbox

### Remote Work Packages

**Windows:**
- Zoom, Microsoft Teams, TeamViewer, Chrome, Dropbox, Slack

**Linux:**
- remmina, teams-for-linux, zoom, thunderbird, filezilla, slack

**macOS:**
- zoom, microsoft-teams, teamviewer, google-chrome, dropbox, slack

## Advanced Features

### Docker Support

Enable Docker and containerization tools:
```bash
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --docker dev
```

Includes:
- Docker Engine/Desktop
- Docker Compose
- Development containers
- Container orchestration tools

### Cloud Integration

Install cloud provider tools:
```bash
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --cloud dev
```

Supported providers:
- **AWS** - CLI, CDK, SAM
- **Azure** - CLI, Functions Core Tools
- **Google Cloud** - CLI, SDK
- **Terraform** - Infrastructure as Code
- **Kubernetes** - kubectl, helm

### Plugin System

Enable extensible plugin architecture:
```bash
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --plugins dev
```

Manage plugins:
```bash
# List available plugins
bash <(curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/lib/plugin-system.sh) list

# Install a plugin
bash <(curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/lib/plugin-system.sh) install <plugin-name>
```

### GUI Interface

Use a graphical interface (requires zenity or dialog):
```bash
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --gui
```

### Analytics

Enable anonymous usage analytics:
```bash
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --analytics dev
```

## Development

### Project Structure

```
machine-bootstrap/
├── install.sh                 # Main installer
├── install.ps1               # Windows PowerShell installer
├── bootstrap.sh              # Local launcher
├── config.yml.example        # Configuration template
├── gaming.yml                # Gaming configuration
├── DOCS.md                   # Complete documentation
├── lib/                      # Core modules
│   ├── system-check.sh       # System verification
│   ├── security.sh           # Security checks
│   ├── update-manager.sh     # Updates and maintenance
│   ├── gui-interface.sh      # GUI functionality
│   ├── docker-support.sh     # Docker integration
│   ├── cloud-integration.sh  # Cloud tools
│   ├── analytics.sh          # Usage analytics
│   ├── plugin-system.sh      # Plugin management
│   └── gpu-support.sh        # GPU and gaming
├── tests/                    # Test suite
│   ├── run-tests.sh          # Comprehensive tests
│   ├── dev-test.sh           # Quick development tests
│   ├── test-gpu.sh           # GPU functionality tests
│   └── test-system-check.sh  # Unit tests
├── windows/                  # Windows-specific installers
├── linux/                   # Linux distribution installers
├── macos/                    # macOS installer
├── examples/                 # Usage examples
└── .github/workflows/        # CI/CD pipeline
```

### Testing

#### Quick Development Tests
```bash
./tests/dev-test.sh
```

#### Comprehensive Test Suite
```bash
./tests/run-tests.sh
```

#### GPU-Specific Tests
```bash
./tests/test-gpu.sh
```

#### Unit Tests
```bash
./tests/test-system-check.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Ensure scripts are executable
chmod +x install.sh
chmod +x tests/run-tests.sh
```

#### Package Manager Not Found
The script auto-detects package managers. If detection fails:
```bash
# Install package manager manually:
# Ubuntu/Debian: sudo apt update
# Fedora: sudo dnf check-update
# macOS: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Windows: Install Chocolatey from chocolatey.org
```

#### GPU Drivers Not Installing
```bash
# Run GPU diagnostics
./lib/gpu-support.sh

# Check system compatibility
bash install.sh --system-check

# Try manual installation
bash install.sh --gpu
```

#### Network Issues
```bash
# Test connectivity
bash install.sh --system-check

# Use longer timeout
bash install.sh --timeout 600 dev

# Skip network-dependent checks
bash install.sh --skip-checks dev
```

### Debug Mode

Enable detailed logging:
```bash
bash install.sh --log-level debug dev
```

### Getting Help

1. **Check the logs** - Look in `/tmp/machine-bootstrap.log`
2. **Run diagnostics** - Use `--system-check` and `--security-check`
3. **Try dry run** - Use `--dry-run` to see what would be installed
4. **GPU issues** - Run `./lib/gpu-support.sh` for diagnostics
5. **Submit an issue** - Include system info and error logs

### System Requirements

**Minimum:**
- 2GB free disk space
- 1GB RAM
- Internet connection
- Sudo/admin access

**Recommended:**
- 5GB free disk space
- 4GB RAM
- Stable internet connection

### Supported Operating Systems

| OS | Version | Package Manager | Status |
|----|---------|----------------|--------|
| **Ubuntu** | 18.04+ | APT + Snap | ✅ Fully Supported |
| **Debian** | 10+ | APT | ✅ Fully Supported |
| **Fedora** | 35+ | DNF + Flatpak | ✅ Fully Supported |
| **CentOS/RHEL** | 8+ | DNF | ✅ Supported |
| **Arch Linux** | Latest | Pacman + AUR | ✅ Supported |
| **macOS** | 10.15+ | Homebrew | ✅ Fully Supported |
| **Windows** | 10/11 | Chocolatey | ✅ Fully Supported |

---

*For more information, visit the [GitHub repository](https://github.com/jj6584/machine-bootstrap)*
