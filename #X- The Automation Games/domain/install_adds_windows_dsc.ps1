# Caminho para o arquivo JSON contendo as credenciais e configurações
$jsonPath = "credentials_ad.json"

# Função para carregar credenciais e nome da VM do arquivo JSON
function Get-CredentialAndVMFromJson {
    param ([string]$jsonPath)

    # Carregar e converter o JSON
    $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    $securePassword = ConvertTo-SecureString $jsonContent.AdminPassword -AsPlainText -Force

    # Retornar credenciais e informações da VM
    return @{
        Credential = New-Object -TypeName PSCredential -ArgumentList $jsonContent.AdminUsername, $securePassword
        DomainCredential = New-Object -TypeName PSCredential -ArgumentList $jsonContent.domainAdminUsername, $securePassword
        VMName = $jsonContent.VMName
        DomainName = $jsonContent.realm
        ForestName = $jsonContent.domain
    }
}

# Carregar configurações do arquivo JSON
$config = Get-CredentialAndVMFromJson -jsonPath $jsonPath
$credential = $config.Credential
$domainCredential = $config.DomainCredential
$vmName = $config.VMName
$domainName = $config.DomainName
$forestName = $config.ForestName

# Criar uma sessão remota para a VM
$session = New-PSSession -ComputerName $vmName -Credential $credential

# Script para instalar os módulos DSC e o provedor NuGet
$installDSCModulesScript = {
    $nugetUrl = "https://onegetcdn.azureedge.net/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"
    $nugetPath = "$env:TEMP\Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"

    # Baixar e importar o provedor NuGet
    Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetPath
    Import-PackageProvider -Name $nugetPath -Force

    # Instalar módulos e funcionalidades necessárias
    Install-Module -Name 'xActiveDirectory' -Force -AllowClobber
    Install-Module -Name 'xPSDesiredStateConfiguration' -Force -AllowClobber
    Install-WindowsFeature -Name "RSAT-AD-Tools" -IncludeManagementTools
}

# Executar o script de instalação na sessão remota
Invoke-Command -Session $session -ScriptBlock $installDSCModulesScript

# Fechar a sessão remota
Remove-PSSession -Session $session

Write-Host "Instalação dos módulos DSC e NuGet concluída na VM $vmName."

# Importar o módulo necessário
Import-Module xActiveDirectory

# Dados de configuração para o novo domínio
$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = $vmName
            Role = 'Primary DC'
            DomainName = $domainName
            Forest = $forestName
            PsDscAllowPlainTextPassword = $true  # Remover para produção (risco de segurança)
        }
    )
}

# Configuração para criar o domínio AD
Configuration NewADDomain {
    param (
        [PSCredential]$SafeModeAdminPassword,
        [PSCredential]$DomainAdminCredential,
        [String]$DomainName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory

    Node $AllNodes.NodeName {
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
            DomainAdministratorCredential = $DomainAdminCredential
            SafemodeAdministratorPassword = $SafeModeAdminPassword
            DatabasePath = 'C:\NTDS'
            LogPath = 'C:\NTDS'
            DependsOn = '[File]NTDSDirectory', '[WindowsFeature]ADDS'
        }
    }
}

# Gerar o arquivo MOF
NewADDomain -ConfigurationData $ConfigData `
             -SafeModeAdminPassword $credential `
             -DomainAdminCredential $domainCredential `
             -DomainName $domainName `
             -OutputPath ".\NewDomain"

# Aplicar a configuração DSC
Start-DscConfiguration -Path ".\NewDomain" -Credential $credential -Wait -Force -Verbose

# Limpar arquivos temporários (opcional)
Remove-Item -Recurse -Force ".\NewDomain"  # Descomentar se necessário

# Reiniciar a VM remotamente
Invoke-Command -ComputerName $vmName -Credential $credential -ScriptBlock { Restart-Computer -Force }

Write-Host "Reinicialização da VM $vmName iniciada."
