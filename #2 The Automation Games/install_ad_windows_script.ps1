# Caminho para o arquivo JSON
$credentialsPath = "credentials.json"

# Ler o conteúdo do arquivo JSON e verificar se foi carregado corretamente
$credentials = Get-Content -Path $credentialsPath -Raw | ConvertFrom-Json
if (-not $credentials) { Write-Error "Falha ao carregar o arquivo $credentialsPath"; exit 1 }

# Extrair e validar as informações da VM e credenciais do domínio
function Get-ValidatedValue($value, $name, $filePath) {
    if (-not $value) { Write-Error "$name não está definido no arquivo $filePath"; exit 1 }
    return $value
}

$vmIp = Get-ValidatedValue $credentials.vmIp "vmIp" $credentialsPath
$vmUser = Get-ValidatedValue $credentials.AdminUsername "AdminUsername" $credentialsPath
$vmPassword = Get-ValidatedValue $credentials.AdminPassword "AdminPassword" $credentialsPath
$domainAdminUser = Get-ValidatedValue $credentials.domainAdminUsername "DomainAdminUser" $credentialsPath
$domainAdminPassword = Get-ValidatedValue $credentials.AdminPassword "DomainAdminPassword" $credentialsPath

# Converter as senhas para SecureString e criar as credenciais
$vmPasswordSecure = $vmPassword | ConvertTo-SecureString -AsPlainText -Force
$domainAdminPasswordSecure = $domainAdminPassword | ConvertTo-SecureString -AsPlainText -Force
$vmCred = New-Object System.Management.Automation.PSCredential ($vmUser, $vmPasswordSecure)
$domainCred = New-Object System.Management.Automation.PSCredential ($domainAdminUser, $domainAdminPasswordSecure)

# Adicionar a VM à lista TrustedHosts, se necessário
$currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
if ($currentTrustedHosts -notcontains $vmIp) {
    $newTrustedHosts = if ($currentTrustedHosts) { "$currentTrustedHosts,$vmIp" } else { $vmIp }
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $newTrustedHosts -Force
}

# Script de instalação a ser executado na VM
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

# Executar o script remotamente e remover a sessão
Invoke-Command -ComputerName $vmIp -Credential $vmCred -ScriptBlock $scriptBlock -ArgumentList $domainAdminPasswordSecure, $domainCred