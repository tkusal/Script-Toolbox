# ===========================================================
#    Export all groups respective members on Microsoft 365
#                Written By Thiago Kusal
#                     Version 1.0
# ===========================================================
# This tool is furnished "AS IS". NO warranty is expressed or Implied.

# Configurar a política de execução para permitir a execução do script
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Verificar se o PowerShell é 5.1 ou superior
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
    Write-Host "Este script requer o PowerShell 5.1 ou superior. Versão atual: $psVersion" -ForegroundColor Red
    exit 1
}

# Instalar o módulo Microsoft.Graph, se ainda não estiver instalado
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
}

# Importar o módulo Microsoft.Graph
Import-Module Microsoft.Graph

# Conectar ao Microsoft 365
Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All"

# Obter todos os grupos
$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -Select Id,DisplayName

# Inicializar uma lista para armazenar os resultados
$userGroupData = @()

# Iterar por cada grupo
foreach ($group in $groups) {
    $groupId = $group.Id
    $groupName = $group.DisplayName

    # Obter os membros do grupo
    $members = Get-MgGroupMember -GroupId $groupId -All
    
    foreach ($member in $members) {
        $userGroupData += [PSCustomObject]@{
            UserPrincipalName = $member.UserPrincipalName
            UserDisplayName = $member.DisplayName
            GroupName = $groupName
        }
    }
}

# Exportar os dados para um arquivo CSV
$userGroupData | Export-Csv -Path "C:\UsersGroups.csv" -NoTypeInformation

# Mensagem de conclusão
Write-Host "Exportação concluída. Dados salvos em C:\UsersGroups.csv"