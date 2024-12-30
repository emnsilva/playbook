# Função para ler credenciais e nome da VM do arquivo JSON
function Get-CredentialAndVMFromJson {
    param ([string]$jsonPath)

    $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    $securePassword = ConvertTo-SecureString $jsonContent.AdminPassword -AsPlainText -Force

    return @{
        Credential = New-Object -TypeName PSCredential -ArgumentList $jsonContent.domainAdminUsername, $securePassword
        VMName = $jsonContent.VMName
    }
}

# Caminho para o arquivo JSON
$jsonPath = "credentials_ad.json"

# Obter as credenciais e o nome da VM do arquivo JSON
$config = Get-CredentialAndVMFromJson -jsonPath $jsonPath
$credential = $config.Credential
$vmName = $config.VMName

# Criar uma sessão remota para a VM
$session = New-PSSession -ComputerName $vmName -Credential $credential

# Comando para instalar os módulos DSC e o provedor NuGet
$installDSCModulesScript = {
    $nugetUrl = "https://onegetcdn.azureedge.net/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"
    $nugetPath = "$env:TEMP\Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"

    Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetPath
    Import-PackageProvider -Name $nugetPath -Force

    Install-Module -Name 'xActiveDirectory' -Force -AllowClobber
    Install-Module -Name 'xPSDesiredStateConfiguration' -Force -AllowClobber
}

# Executar o comando de instalação na sessão remota
Invoke-Command -Session $session -ScriptBlock $installDSCModulesScript

# Fechar a sessão remota
Remove-PSSession -Session $session

Write-Host "Instalação dos módulos DSC e NuGet concluída na VM $vmName."

# Importar o módulo necessário
Import-Module xActiveDirectory

# Ler as credenciais novamente do arquivo JSON para a configuração do domínio
$config = Get-CredentialAndVMFromJson -jsonPath $jsonPath
$credentials = $config.Credential
$vmName = $config.VMName

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

# Credenciais para a configuração do domínio
$remoteCred = $credentials
$safemodeCred = $credentials
$domainAdminCred = $credentials

# Configuração para configurar o domínio AD
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
NewADDomain -ConfigurationData $ConfigData -safemodeAdministratorPassword $safemodeCred -domainAdministratorCredential $domainAdminCred -DomainName $ConfigData.AllNodes[0].DomainName -OutputPath ".\NewDomain"

# Aplicar a configuração
Start-DscConfiguration -Path ".\NewDomain" -Credential $remoteCred -Wait -Force -Verbose

# Limpar a configuração local (opcional)
Remove-Item -Recurse -Force ".\NewDomain"  # Descomentar se necessário

# Reiniciar a VM remotamente
Invoke-Command -ComputerName $vmName -Credential $credentials -ScriptBlock { Restart-Computer -Force }

Write-Host "Reinicialização da VM $vmName iniciada."
