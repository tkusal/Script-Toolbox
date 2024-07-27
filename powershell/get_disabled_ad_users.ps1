#Requires -Version 5.1

function Get-DisabledUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UsersFilePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Email', 'FullName', 'UserID')]
        [string]$ListType = 'Email',
        
        [Parameter(Mandatory = $false)]
        [string]$SearchBase = 'OU=Users,DC=company,DC=LOCAL',
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFilePath
    )
    
    begin {
        if (-not (Test-Path $UsersFilePath)) {
            throw "The file specified in UsersFilePath does not exist."
        }

        Import-Module ActiveDirectory -ErrorAction Stop

        $Users = Get-Content -Path $UsersFilePath -ErrorAction Stop
        
        if ($Users.Count -eq 0) {
            throw "The user list is empty."
        }

        Write-Verbose -Message "Retrieving users from Active Directory..."
        $ADUsers = Get-ADUser -SearchBase $SearchBase -Filter * -Properties Enabled, UserPrincipalName, Name, SamAccountName
        
        $Results = @()
    }
    
    process {
        foreach ($User in $Users) {
            switch ($ListType) {
                'Email' { $SearchProperty = 'UserPrincipalName' }
                'FullName' { $SearchProperty = 'Name' }
                'UserID' { $SearchProperty = 'SamAccountName' }
            }
            
            $FoundUser = $ADUsers | Where-Object { $_.$SearchProperty -eq $User }

            if ($FoundUser) {
                $Results += [pscustomobject]@{
                    SearchProperty = $User
                    UserPrincipalName = $FoundUser.UserPrincipalName
                    Name = $FoundUser.Name
                    SamAccountName = $FoundUser.SamAccountName
                    Enabled = $FoundUser.Enabled
                }
            } else {
                $Results += [pscustomobject]@{
                    SearchProperty = $User
                    UserPrincipalName = 'Not Found'
                    Name = 'Not Found'
                    SamAccountName = 'Not Found'
                    Enabled = 'Not Found'
                }
            }
        }
    }
    
    end {
        $Results = $Results | Sort-Object Enabled
        
        $Results | Format-Table -AutoSize
        
        if ($OutputFilePath) {
            Write-Verbose -Message "Exporting results to $OutputFilePath..."
            $Results | Export-Csv -Path $OutputFilePath -NoTypeInformation -Force
        }
    }
}

Get-DisabledUser -UsersFilePath 'C:\TestUsers.txt' -ListType Email -SearchBase 'OU=Users,DC=company,DC=LOCAL' -OutputFilePath 'C:\Results.csv'
