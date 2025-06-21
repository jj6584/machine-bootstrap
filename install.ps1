# Machine Bootstrap - Windows One-liner
# Usage: irm https://raw.githubusercontent.com/YOUR_USERNAME/machine-bootstrap/main/install.ps1 | iex

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("basic", "remote", "dev", "all")]
    [string]$PackageSet = $null
)

# GitHub repository info
$GitHubUser = "jj6584"  # Your GitHub username
$RepoName = "machine-bootstrap"
$Branch = "main"  # or "master" depending on your default branch
$BaseUrl = "https://raw.githubusercontent.com/$GitHubUser/$RepoName/$Branch"

Write-Host "🚀 Machine Bootstrap - Windows One-liner Installer" -ForegroundColor Cyan
Write-Host "Repository: https://github.com/$GitHubUser/$RepoName" -ForegroundColor Blue
Write-Host ""

try {
    Write-Host "📥 Downloading Windows installer..." -ForegroundColor Blue
    
    # Download and execute the main PowerShell script
    $scriptUrl = "$BaseUrl/windows/install-app.ps1"
    $scriptContent = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    
    Write-Host "✅ Downloaded installer script" -ForegroundColor Green
    Write-Host "🚀 Executing installer..." -ForegroundColor Cyan
    
    # Create a temporary file and execute
    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $scriptContent | Out-File -FilePath $tempFile -Encoding UTF8
    
    if ($PackageSet) {
        & $tempFile -PackageSet $PackageSet
    } else {
        & $tempFile
    }
    
    # Cleanup
    Remove-Item $tempFile -Force
    
    Write-Host ""
    Write-Host "✅ Bootstrap complete!" -ForegroundColor Green
    Write-Host "⭐ If this helped you, please star the repo: https://github.com/$GitHubUser/$RepoName" -ForegroundColor Yellow
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your internet connection and repository URL" -ForegroundColor Yellow
    Write-Host "Manual installation: https://github.com/$GitHubUser/$RepoName" -ForegroundColor Blue
}
