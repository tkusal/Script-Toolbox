function Get-InstalledSoftware {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, HelpMessage='Search for product name (You can use wildcards like "*ProductName*")')]
        [String]$Search,

        [Parameter(Position=1, HelpMessage='ComputerName or IPv4-Address of the remote computer')]
        [String]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Position=2, HelpMessage='Credentials to authenticate against a remote computer')]
        [System.Management.Automation.PSCredential]$Credential
    )

    Begin {
        $LocalAddress = @("127.0.0.1", "localhost", ".", "$($env:COMPUTERNAME)")

        $ScriptBlock = {
            # Location where all entries for installed software should be stored
            $paths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            )

            $results = foreach ($path in $paths) {
                Get-ChildItem -Path $path -ErrorAction SilentlyContinue | 
                Get-ItemProperty | 
                Select-Object DisplayName, Publisher, UninstallString, InstallLocation, InstallDate
            }

            return $results
        }
    }

    Process {
        if ($LocalAddress -contains $ComputerName) {
            Write-Verbose "Running on local computer."
            $Results = Invoke-Command -ScriptBlock $ScriptBlock
        } else {
            if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet) {
                Write-Verbose "Connecting to remote computer: $ComputerName"
                try {
                    $Results = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
                } catch {
                    Write-Error "Failed to execute command on remote computer. Error: $_"
                    return
                }
            } else {
                Write-Error "$ComputerName is not reachable via ICMP!"
                return
            }
        }

        foreach ($Result in $Results) {
            if (-not [string]::IsNullOrEmpty($Result.DisplayName) -and -not [string]::IsNullOrEmpty($Result.UninstallString)) {
                if (-not $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Search') -or ($Result.DisplayName -like $Search)) {
                    [pscustomobject]@{
                        DisplayName = $Result.DisplayName
                        Publisher = $Result.Publisher
                        UninstallString = $Result.UninstallString
                        InstallLocation = $Result.InstallLocation
                        InstallDate = $Result.InstallDate
                    }
                }
            }
        }
    }

    End {
        # End block can be used for cleanup or final messages if needed
    }
}