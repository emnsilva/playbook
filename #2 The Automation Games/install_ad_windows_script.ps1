# Caminhos para os arquivos JSON
$vmInfoPath = "vm_info.json"
$domainCredPath = "domain_password.json"

# Ler o conteúdo dos arquivos JSON
$vmInfo = Get-Content -Path $vmInfoPath -Raw | ConvertFrom-Json
$domainCred = Get-Content -Path $domainCredPath -Raw | ConvertFrom-Json

# Verificar se os dados foram carregados corretamente
if (-not $vmInfo) { Write-Error "Falha ao carregar o arquivo $vmInfoPath"; exit 1 }
if (-not $domainCred) { Write-Error "Falha ao carregar o arquivo $domainCredPath"; exit 1 }

# Extrair as informações da VM
$vmIp = $vmInfo.vmIp
$vmUser = $vmInfo.vmUser
$vmPassword = $vmInfo.vmPassword

# Verificar se as informações da VM estão corretas
if (-not $vmIp) { Write-Error "vmIp não está definido no arquivo $vmInfoPath"; exit 1 }
if (-not $vmUser) { Write-Error "vmUser não está definido no arquivo $vmInfoPath"; exit 1 }
if (-not $vmPassword) { Write-Error "vmPassword não está definido no arquivo $vmInfoPath"; exit 1 }

# Extrair as credenciais do domínio
$safeModeAdminPassword = $domainCred.safemodeAdminPassword
$domainAdminUser = $domainCred.domainAdminUsername
$domainAdminPassword = $domainCred.domainAdminPassword

# Verificar se as credenciais do domínio estão corretas
if (-not $safeModeAdminPassword) { Write-Error "SafeModeAdministratorPassword não está definido no arquivo $domainCredPath"; exit 1 }
if (-not $domainAdminUser) { Write-Error "DomainAdminUser não está definido no arquivo $domainCredPath"; exit 1 }
if (-not $domainAdminPassword) { Write-Error "DomainAdminPassword não está definido no arquivo $domainCredPath"; exit 1 }

# Converter as senhas para SecureString
$safeModeAdminPassword = $safeModeAdminPassword | ConvertTo-SecureString -AsPlainText -Force
$domainAdminPassword = $domainAdminPassword | ConvertTo-SecureString -AsPlainText -Force
$vmPasswordSecure = $vmPassword | ConvertTo-SecureString -AsPlainText -Force

# Criar credenciais para a VM e o domínio
$vmCred = New-Object System.Management.Automation.PSCredential ($vmUser, $vmPasswordSecure)
$domainCred = New-Object System.Management.Automation.PSCredential ($domainAdminUser, $domainAdminPassword)

# Adicionar a VM à lista TrustedHosts
$currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
if ($currentTrustedHosts -notcontains $vmIp) {
    $newTrustedHosts = if ($currentTrustedHosts) { "$currentTrustedHosts,$vmIp" } else { $vmIp }
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $newTrustedHosts -Force
}

# Comando a ser executado na VM
$scriptBlock = {
    param ($safeModeAdminPassword, $domainCred)
    
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    Install-WindowsFeature RSAT-AD-PowerShell
    Install-WindowsFeature RSAT-ADDS
    Import-Module ADDSDeployment

    Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" `
        -DomainMode "WinThreshold" -DomainName "paranaue.com" `
        -DomainNetbiosName "PARANAUE" -ForestMode "WinThreshold" `
        -SafeModeAdministratorPassword $safeModeAdminPassword -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true

}

# Executar o comando remotamente
Invoke-Command -ComputerName $vmIp -Credential $vmCred -ScriptBlock $scriptBlock -ArgumentList $safeModeAdminPassword, $domainCred