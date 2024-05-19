# Verifica se o script está sendo executado como administrador
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Você deve executar este script como administrador."
    Exit
}

# Caminho temporário para o arquivo de configuração da política de segurança
$secpolFile = "C:\secpol.cfg"

# Exporta a política de segurança atual
secedit /export /cfg $secpolFile

# Substitui a configuração de complexidade de senha
(Get-Content $secpolFile).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Set-Content $secpolFile

# Aplica a nova configuração de segurança
secedit /configure /db C:\Windows\security\local.sdb /cfg $secpolFile /areas SECURITYPOLICY

# Verifica a nova configuração de segurança
secedit /analyze /db C:\Windows\security\local.sdb /cfg $secpolFile /areas SECURITYPOLICY

# Remove o arquivo temporário de configuração
Remove-Item $secpolFile

Write-Host "Complexidade de senha desabilitada com sucesso."

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