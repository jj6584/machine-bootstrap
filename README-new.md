# Machine Bootstrap

A cross-platform, one-liner installer that automatically detects your OS and sets up essential development tools, applications, and GPU drivers.

## 🚀 Quick Start

**Linux/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.ps1 | iex
```

## 📦 What Gets Installed

| Category | Windows | Linux | macOS |
|----------|---------|-------|-------|
| **Basic** | 7zip, VLC, Firefox, VS Code, Discord, Steam | Essential tools, Firefox, VLC, VS Code, Discord, Steam | Homebrew, Firefox, VLC, VS Code, Discord |
| **Dev** | Git, Node.js, Python, Docker, VS Code | Git, Node.js, Python, Docker, build tools | Git, Node.js, Python, Docker, dev tools |
| **GPU/Gaming** | NVIDIA/AMD drivers, Steam, Epic Games | GPU drivers, Steam, Lutris, Wine, GameMode | Steam, gaming tools |

## ⚡ Quick Commands

```bash
# Install everything
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s all

# Install just development tools
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s dev

# Install with GPU drivers auto-detection
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --auto-gpu dev

# Preview what would be installed (dry run)
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --dry-run all

# Gaming setup with GPU optimization
curl -fsSL https://raw.githubusercontent.com/jj6584/machine-bootstrap/main/install.sh | bash -s -- --config gaming.yml
```

## 🔧 Key Features

- ✅ **Cross-platform** - Windows, macOS, Linux (Ubuntu, Debian, Fedora, Arch)
- ✅ **GPU Support** - Auto-detect and install NVIDIA, AMD, Intel drivers
- ✅ **Gaming Ready** - Steam, Lutris, Wine, GameMode optimization
- ✅ **Developer Tools** - Complete dev environment setup
- ✅ **Security** - Built-in verification and security checks
- ✅ **Customizable** - YAML configuration support

## 📖 Documentation

For complete documentation, commands, and advanced usage, see **[DOCS.md](DOCS.md)**

## 🤝 Contributing

Feel free to submit issues and enhancement requests!
