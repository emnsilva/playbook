# Função para ler credenciais e nome da VM do arquivo JSON
function Get-CredentialAndVMFromJson {
    param (
        [string]$jsonPath
    )
    $jsonContent = Get-Content -Path $jsonPath | ConvertFrom-Json
    $securePassword = ConvertTo-SecureString $jsonContent.password -AsPlainText -Force
    $credential = New-Object -TypeName PSCredential -ArgumentList $jsonContent.username, $securePassword
    return @{
        Credential = $credential
        VMName = $jsonContent.VMName
    }
}

# Caminho para o arquivo JSON
$jsonPath = "password.json"

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

# Import Required Module
Import-Module xActiveDirectory

# Read credentials from JSON file
$credentialFilePath = ".\password.json"
$config = Get-CredentialAndVMFromJson -jsonPath $credentialFilePath
$credentials = $config.Credential
$vmName = $config.VMName

# Configuration Data for New Domain (PARANAUE.COM)
$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = $vmName
            Role = 'Primary DC'
            DomainName = 'paranaue.com'
            Forest = 'PARANAUE'
            PsDscAllowPlainTextPassword = $true  # Remove for production (security risk)
        }
    )
}

# Create PSCredential objects
$remoteCred = $credentials
$safemodeCred = $credentials
$domainAdminCred = $credentials

# Configuration to Set Up AD Domain
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

# Generate MOF File
NewADDomain -ConfigurationData $ConfigData -safemodeAdministratorPassword $safemodeCred -domainAdministratorCredential $domainAdminCred -DomainName $ConfigData.AllNodes[0].DomainName -OutputPath ".\NewDomain"

# Apply Configuration
Start-DscConfiguration -Path ".\NewDomain" -Credential $remoteCred -Wait -Force -Verbose

# Clean Up Local Configuration (Optional)
Remove-Item -Recurse -Force ".\NewDomain"  # Uncomment if desired

# Reiniciar a VM remotamente
Invoke-Command -ComputerName $vmName -Credential $credential -ScriptBlock { Restart-Computer -Force }

Write-Host "Reinicialização da VM $vmName iniciada."