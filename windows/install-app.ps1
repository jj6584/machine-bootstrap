param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("basic", "remote", "dev", "all")]
    [string]$PackageSet = $null
)

# Package definitions
$packagesBasic = @{
    peazip='';
    vlc=''; 
    adobereader='--params="/UpdateMode:4"';
    firefox='';
    discord='';
    vscode='--params="/NoDesktopIcon /NoQuicklaunchIcon"';
    'steam-client'='';
    'microsoft-windows-terminal'='';
} 

$packagesRemote = @{
    zoom='';    
    'microsoft-teams'='';
    teamviewer='';
    adobereader='--params="/UpdateMode:4"';
    googlechrome='';
    peazip='';
    vlc='';
    dropbox='';
}

$packagesDev = @{
    git='';
    nodejs='';
    python='';
    'docker-desktop'='';
    postman='';
    'visual-studio-code'='';
    'windows-terminal'='';
    'powershell-core'='';
    'jetbrains-toolbox'='';
}
# Function to install Chocolatey
function Install-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "🍫 Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "✅ Chocolatey already installed" -ForegroundColor Green
    }
}

# Function to install packages
function Install-Packages {
    param($packages, $setName)
    
    Write-Host "`n🚀 Installing $setName packages..." -ForegroundColor Cyan
    
    $total = $packages.Count
    $current = 0
    
    ForEach($key in $packages.Keys) {
        $current++
        Write-Host "[$current/$total] Installing $key..." -ForegroundColor Yellow
        
        if ($packages[$key]) {
            choco install $key -y $packages[$key]
        } else {
            choco install $key -y
        }
    }
}

# Function to show menu
function Show-Menu {
    Write-Host "`n📦 Package Installation Options:" -ForegroundColor Cyan
    Write-Host "A - Basic apps (Media, browsers, etc.)" -ForegroundColor White
    Write-Host "B - Remote work apps (Teams, Zoom, etc.)" -ForegroundColor White  
    Write-Host "C - Developer apps (Git, Docker, etc.)" -ForegroundColor White
    Write-Host "D - All packages" -ForegroundColor White
    Write-Host "E - Exit" -ForegroundColor Red
}



# Main script execution
Write-Host "🪟 Windows Package Installer" -ForegroundColor Black -BackgroundColor White

# Install Chocolatey first
Install-Chocolatey

# Handle command line parameter for automation
if ($PackageSet) {
    switch ($PackageSet.ToLower()) {
        "basic" { Install-Packages $packagesBasic "Basic" }
        "remote" { Install-Packages $packagesRemote "Remote Work" }
        "dev" { Install-Packages $packagesDev "Developer" }
        "all" { 
            Install-Packages $packagesBasic "Basic"
            Install-Packages $packagesRemote "Remote Work" 
            Install-Packages $packagesDev "Developer"
        }
    }
    Write-Host "`n✅ Installation complete!" -ForegroundColor Green
    exit
}

# Interactive menu mode
$Break = $False
Do {
    Show-Menu
    switch (Read-Host "`nEnter your choice") {
        {$_ -in 'A','a'} { Install-Packages $packagesBasic "Basic"; $Break = $True }
        {$_ -in 'B','b'} { Install-Packages $packagesRemote "Remote Work"; $Break = $True }
        {$_ -in 'C','c'} { Install-Packages $packagesDev "Developer"; $Break = $True }
        {$_ -in 'D','d'} { 
            Install-Packages $packagesBasic "Basic"
            Install-Packages $packagesRemote "Remote Work"
            Install-Packages $packagesDev "Developer"
            $Break = $True 
        }
        {$_ -in 'E','e'} { exit }
        default { Write-Host "❌ Invalid input. Please select A, B, C, D, or E." -ForegroundColor Red }
    }
} While ($Break -eq $False)

Write-Host "`n✅ Installation complete!" -ForegroundColor Green