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
# --------------------------------------------------------------

# Installing chocolatey from https://chocolatey.org/install
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))



# --------------------- Script start ---------------------------
Write-Host "`n ---Installing Windows PACKAGES --- " -ForegroundColor black -BackgroundColor white

$Break = $False
Do{
    switch (Read-Host "Which apps should be installed? Enter 'A' for Basic apps, 'B' for Remote work apps. If you want both, then run the
script two times."){
    
    a { $packToInstall = $packagesBasic; $Break = $True}
    b { $packToInstall = $packagesRemote; $Break = $True}
    e { exit }

    default {  Write-Host "Wrong input. Plase provide the character 'A' or 'B'. Select 'E' for exit." -ForegroundColor red  }
    }
} While ($Break -eq $False)


ForEach($key in $packToInstall.Keys){
    if ($packToInstall[$key]) {
        choco install $key -y $packToInstall[$key]   
    } 
    else {
        # Default installer
        choco install $key -y  
    }
}