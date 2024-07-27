Function Test-Credential {
    [OutputType([Bool])]
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [String]
        [ValidatePattern('^([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*)$')]
        $Domain
    )

    Begin {
        try {
            # Load assembly for Active Directory
            [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") | Out-Null

            # Create a PrincipalContext for the specified domain
            $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
                [System.DirectoryServices.AccountManagement.ContextType]::Domain, $Domain
            )
        }
        catch {
            Write-Error -Message "Failed to initialize PrincipalContext: $_"
            return $false
        }
    }

    Process {
        try {
            # Validate credentials against the domain
            $networkCredential = $Credential.GetNetworkCredential()
            $isValid = $principalContext.ValidateCredentials($networkCredential.UserName, $networkCredential.Password)
            Write-Output -InputObject $isValid
        }
        catch {
            Write-Error -Message "Credential validation failed: $_"
            return $false
        }
    }

    End {
        # Dispose the PrincipalContext
        if ($null -ne $principalContext) {
            $principalContext.Dispose()
        }
    }
}
