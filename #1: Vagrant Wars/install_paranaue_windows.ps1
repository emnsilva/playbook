# Instala o Hyper-V
Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -All -Online -NoRestart

# Instala o Chocolatey e os pacotes necessários
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y vscode git python vagrant

# Muda a pasta de configuração global do Vagrant. Substitua o STORAGE_LOCATION pelo local onde a pasta deve ficar.
setx VAGRANT_HOME “E:/.vagrant.d/”

# Reinicia o sistema
Restart-Computer -Force
