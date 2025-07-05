# Instala o Hyper-V no Windows 10/11
# Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -All -Online -NoRestart

# Instala o Hyper-V no Windows Server
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

# Instala o Chocolatey e os pacotes necessários
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y vscode git python vagrant

# Reinicia o sistema
Restart-Computer -Force
