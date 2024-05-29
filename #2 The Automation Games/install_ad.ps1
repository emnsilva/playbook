# Caminho para o arquivo JSON
$jsonFilePath = "C:\password.json"

# Ler o conteúdo do arquivo JSON
$jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

# Extrair a senha do JSON e convertê-la para SecureString
$safeModeAdminPassword = $jsonContent.SafeModeAdministratorPassword | ConvertTo-SecureString -AsPlainText -Force

# Executar o script com a senha do JSON
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature RSAT-AD-PowerShell
Install-WindowsFeature RSAT-ADDS
Import-Module ADDSDeployment

Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "WinThreshold" -DomainName "paranaue.com" -DomainNetbiosName "PARANAUE" -ForestMode "WinThreshold" -SafeModeAdministratorPassword $safeModeAdminPassword -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true