# Caminho para o arquivo JSON
$credentialsPath = "credentials_ad.json"

# Função para carregar e validar o JSON
function Load-Credentials {
    param ([string]$filePath)
    try {
        $content = Get-Content -Path $filePath -Raw | ConvertFrom-Json
        if (-not $content) { throw "O arquivo está vazio ou inválido." }
        return $content
    } catch {
        Write-Error ("Falha ao carregar ou interpretar o arquivo {0}: {1}" -f $filePath, $_.Exception.Message)
        exit 1
    }
}

# Função para validar valores obrigatórios
function Get-ValidatedValue {
    param (
        [string]$value,
        [string]$name
    )
    if (-not $value) {
        Write-Error "$name não está definido no arquivo $credentialsPath"
        exit 1
    }
    return $value
}

# Carregar credenciais do arquivo
$credentials = Load-Credentials -filePath $credentialsPath

# Extrair e validar as informações
$vmIp = Get-ValidatedValue $credentials.vmIp "vmIp"
$vmUser = Get-ValidatedValue $credentials.AdminUsername "AdminUsername"
$vmPassword = Get-ValidatedValue $credentials.AdminPassword "AdminPassword"
$domainAdminUser = Get-ValidatedValue $credentials.domainAdminUsername "DomainAdminUsername"

# Criar credenciais de acesso (SecureString e PSCredential)
function Create-Credential {
    param ([string]$username, [string]$password)
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential ($username, $securePassword)
}

$vmCred = Create-Credential -username $vmUser -password $vmPassword
$domainCred = Create-Credential -username $domainAdminUser -password $vmPassword

# Configurar TrustedHosts
function Update-TrustedHosts {
    param ([string]$hostIp)
    $currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
    if ($currentTrustedHosts -notcontains $hostIp) {
        $newTrustedHosts = if ($currentTrustedHosts) { "$currentTrustedHosts,$hostIp" } else { $hostIp }
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value $newTrustedHosts -Force
    }
}

Update-TrustedHosts -hostIp $vmIp

# Script de instalação do Active Directory
$scriptBlock = {
    param (
        [Parameter(Mandatory=$true)][SecureString]$safeModeAdminPassword,
        [Parameter(Mandatory=$true)][PSCredential]$domainCred
    )

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

# Executar o script remotamente
try {
    Invoke-Command -ComputerName $vmIp -Credential $vmCred -ScriptBlock $scriptBlock -ArgumentList ($vmPassword | ConvertTo-SecureString -AsPlainText -Force), $domainCred
} catch {
    Write-Error ("Erro ao executar o script remotamente na VM {0}: {1}" -f $vmIp, $_.Exception.Message)
    exit 1
}
