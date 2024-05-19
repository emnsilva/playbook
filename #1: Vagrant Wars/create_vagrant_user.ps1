# Verifica se o script está sendo executado como administrador
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Você deve executar este script como administrador."
    Exit
}

# Define o nome de usuário e a senha
$username = "vagrant"
$password = "vagrant"

# Cria uma senha segura
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# Cria o usuário
New-LocalUser $username -Password $securePassword -FullName "vagrant" -Description "User created for Vagrant environment"

# Adiciona o usuário ao grupo de administradores
Add-LocalGroupMember -Group "Administrators" -Member $username

Write-Host "Usuário 'vagrant' criado e adicionado ao grupo de administradores com sucesso."