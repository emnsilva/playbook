# Carregar credenciais a partir de um arquivo JSON
$passwords = Get-Content -Raw -Path "password.json" | ConvertFrom-Json

$safemodeAdministratorCred = New-Object -TypeName PSCredential -ArgumentList $passwords.safemodeAdminUsername, (ConvertTo-SecureString $passwords.safemodeAdminPassword -AsPlainText -Force)
$domainAdminCred = New-Object -TypeName PSCredential -ArgumentList $passwords.domainAdminUsername, (ConvertTo-SecureString $passwords.domainAdminPassword -AsPlainText -Force)

configuration NewDomain {
    param (
        [Parameter(Mandatory)]
        [pscredential]$safemodeAdministratorCred,

        [Parameter(Mandatory)]
        [pscredential]$domainAdminCred
    )

    Import-DscResource -ModuleName xActiveDirectory

    Node $AllNodes.Where{ $_.Role -eq "Primary DC" }.Nodename {
        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        File ADFiles {
            DestinationPath = 'C:\NTDS'
            Type = 'Directory'
            Ensure = 'Present'
        }

        WindowsFeature ADDSInstall {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        WindowsFeature ADDSTools {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }

        xADDomain FirstDS {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainAdminCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DatabasePath = 'C:\NTDS'
            LogPath = 'C:\NTDS'
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles"
        }
    }
}

# Configuration Data for AD
$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = "localhost"
            Role = "Primary DC"
            DomainName = "paranaue.com"
            RetryCount = 20
            RetryIntervalSec = 30
            PsDscAllowPlainTextPassword = $true
        }
    )
}

NewDomain -ConfigurationData $ConfigData `
    -safemodeAdministratorCred $safemodeAdministratorCred `
    -domainAdminCred $domainAdminCred

# Make sure that LCM is set to continue configuration after reboot
Set-DSCLocalConfigurationManager -Path .\NewDomain -Verbose

# Build the domain
Start-DscConfiguration -Wait -Force -Path .\NewDomain -Verbose