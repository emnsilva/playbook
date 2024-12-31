# ========================================================
# CONFIGURAÇÃO INICIAL
# ========================================================

# Caminho para o arquivo JSON contendo as credenciais e configurações
$jsonPath = "credentials_ad.json"

# Função para carregar credenciais e nome da VM do arquivo JSON
function Get-CredentialAndVMFromJson {
    param ([string]$jsonPath)

    $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    $securePassword = ConvertTo-SecureString $jsonContent.AdminPassword -AsPlainText -Force

    return @{
        Credential = New-Object -TypeName PSCredential -ArgumentList $jsonContent.domainAdminUsername, $securePassword
        VMName = $jsonContent.VMName
    }
}

# Carregar configurações do arquivo JSON
$config = Get-CredentialAndVMFromJson -jsonPath $jsonPath
$credential = $config.Credential
$vmName = $config.VMName

# ========================================================
# INSTALAÇÃO DOS MÓDULOS E FUNCIONALIDADES
# ========================================================

# Criar uma sessão remota para a VM
$session = New-PSSession -ComputerName $vmName -Credential $credential

# Script para instalar os módulos DSC e o provedor NuGet
$installDSCModulesScript = {
    $nugetUrl = "https://onegetcdn.azureedge.net/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"
    $nugetPath = "$env:TEMP\Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"

    Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetPath
    Import-PackageProvider -Name $nugetPath -Force

    Install-Module -Name 'xActiveDirectory' -Force -AllowClobber
    Install-Module -Name 'xPSDesiredStateConfiguration' -Force -AllowClobber
    Install-WindowsFeature -Name "RSAT-AD-Tools" -IncludeManagementTools
}

# Executar o script de instalação na sessão remota
Invoke-Command -Session $session -ScriptBlock $installDSCModulesScript

# Fechar a sessão remota
Remove-PSSession -Session $session

Write-Host "Instalação dos módulos DSC e NuGet concluída na VM $vmName."

# ========================================================
# CONFIGURAÇÃO DO DOMÍNIO AD
# ========================================================

# Importar o módulo necessário
Import-Module xActiveDirectory

# Dados de configuração para o novo domínio (PARANAUE.COM)
$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = $vmName
            Role = 'Primary DC'
            DomainName = 'paranaue.com'
            Forest = 'PARANAUE'
            PsDscAllowPlainTextPassword = $true  # Remover para produção (risco de segurança)
        }
    )
}

# Configuração para criar o domínio AD
Configuration NewADDomain {
    param (
        [PSCredential]$safemodeAdministratorPassword,
        [PSCredential]$domainAdministratorCredential,
        [String]$DomainName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory

    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.NodeName {
        File NTDSDirectory {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\NTDS'
        }

        WindowsFeature ADDS {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
        }

        xADDomain FirstDC {
            DomainName = $DomainName
            DomainAdministratorCredential = $domainAdministratorCredential
            SafemodeAdministratorPassword = $safemodeAdministratorPassword
            DatabasePath = 'C:\NTDS'
            LogPath = 'C:\NTDS'
            DependsOn = '[File]NTDSDirectory', '[WindowsFeature]ADDS'
        }
    }
}

# Gerar o arquivo MOF
NewADDomain -ConfigurationData $ConfigData `
             -safemodeAdministratorPassword $credential `
             -domainAdministratorCredential $credential `
             -DomainName $ConfigData.AllNodes[0].DomainName `
             -OutputPath ".\NewDomain"

# Aplicar a configuração DSC
Start-DscConfiguration -Path ".\NewDomain" -Credential $credential -Wait -Force -Verbose

# Limpar arquivos temporários (opcional)
Remove-Item -Recurse -Force ".\NewDomain"  # Descomentar se necessário

# ========================================================
# REINICIALIZAÇÃO DA VM
# ========================================================

# Reiniciar a VM remotamente
Invoke-Command -ComputerName $vmName -Credential $credential -ScriptBlock { Restart-Computer -Force }

Write-Host "Reinicialização da VM $vmName iniciada."
