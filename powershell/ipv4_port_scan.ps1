function Update-ListFromIANA {
    param (
        [string]$IANA_PortList_WebUri,
        [string]$XML_PortList_Path,
        [string]$XML_PortList_BackupPath
    )

    try {
        Write-Output "Creating backup of the IANA Service Name and Transport Protocol Port Number Registry..."
        
        # Backup file before downloading a new version
        if (Test-Path -Path $XML_PortList_Path -PathType Leaf) {
            Rename-Item -Path $XML_PortList_Path -NewName $XML_PortList_BackupPath
        }

        Write-Output "Updating Service Name and Transport Protocol Port Number Registry from IANA.org..."
        
        # Download XML file from IANA and save it
        $New_XML_PortList = Invoke-WebRequest -Uri $IANA_PortList_WebUri -ErrorAction Stop
        [xml]$New_XML_PortList = $New_XML_PortList.Content
        $New_XML_PortList.Save($XML_PortList_Path)

        # Remove backup if no error
        if (Test-Path -Path $XML_PortList_BackupPath -PathType Leaf) {
            Remove-Item -Path $XML_PortList_BackupPath
        }
    } catch {
        Write-Error "Error updating the port list: $_"
        
        # Restore backup on error
        if (Test-Path -Path $XML_PortList_BackupPath -PathType Leaf) {
            Rename-Item -Path $XML_PortList_BackupPath -NewName $XML_PortList_Path
        }
    }
}

function Invoke-IPv4PortScan {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, HelpMessage='ComputerName or IPv4-Address of the device which you want to scan')]
        [string]$ComputerName,

        [Parameter(Position=1, HelpMessage='First port which should be scanned (Default=1)')]
        [ValidateRange(1,65535)]
        [int]$StartPort = 1,

        [Parameter(Position=2, HelpMessage='Last port which should be scanned (Default=65535)')]
        [ValidateRange(1,65535)]
        [ValidateScript({
            if ($_ -lt $StartPort) {
                throw "Invalid Port-Range!"
            }
            return $true
        })]
        [int]$EndPort = 65535,

        [Parameter(Position=3, HelpMessage='Maximum number of threads at the same time (Default=500)')]
        [int]$Threads = 500,

        [Parameter(Position=4, HelpMessage='Execute script without user interaction')]
        [switch]$Force,

        [Parameter(Position=5, HelpMessage='Update Service Name and Transport Protocol Port Number Registry from IANA.org')]
        [switch]$UpdateList
    )

    Begin {
        Write-Output "Script started at $(Get-Date)"

        # Define paths for port list
        $IANA_PortList_WebUri = "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml"
        $XML_PortList_Path = "$PSScriptRoot\Resources\IANA_ServiceName_and_TransportProtocolPortNumber_Registry.xml"
        $XML_PortList_BackupPath = "$PSScriptRoot\Resources\IANA_ServiceName_and_TransportProtocolPortNumber_Registry.xml.bak"

        # Import XML Port List if it exists
        if (Test-Path -Path $XML_PortList_Path -PathType Leaf) {
            $XML_PortList = [xml](Get-Content -Path $XML_PortList_Path)
        } else {
            $XML_PortList = $null
        }
    }

    Process {
        # Update port list if requested
        if ($UpdateList) {
            Update-ListFromIANA -IANA_PortList_WebUri $IANA_PortList_WebUri -XML_PortList_Path $XML_PortList_Path -XML_PortList_BackupPath $XML_PortList_BackupPath
        } elseif (-not $XML_PortList) {
            Write-Warning "No XML file found for port services. Use '-UpdateList' to download the latest version from IANA.org."
        }

        # Check if the computer is reachable
        Write-Output "Checking if host is reachable..."
        if (-not (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)) {
            Write-Warning "$ComputerName is not reachable!"

            if (-not $Force) {
                $choice = $host.UI.PromptForChoice("Continue", "Would you like to continue? (perhaps only ICMP is blocked)", @("&Yes", "&No"), 0)
                if ($choice -eq 1) { return }
            }
        }

        $IPv4Address = if ([IPAddress]::TryParse($ComputerName, [ref]$null)) { $ComputerName } else {
            try {
                [System.Net.Dns]::GetHostEntry($ComputerName).AddressList |
                Where-Object { $_.AddressFamily -eq 'InterNetwork' } |
                Select-Object -First 1 -ExpandProperty IPAddressToString
            } catch {
                throw "Could not get IPv4-Address for $ComputerName. Try using an IPv4-Address instead of the hostname."
            }
        }

        # Create and configure RunspacePool
        Write-Output "Setting up RunspacePool with max $Threads threads..."
        $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $Threads)
        $RunspacePool.Open()
        [System.Collections.ArrayList]$Jobs = @()

        # Define the scriptblock for port scanning
        $ScriptBlock = {
            param ($IPv4Address, $Port)
            try {
                $Socket = New-Object System.Net.Sockets.TcpClient($IPv4Address, $Port)
                $Status = if ($Socket.Connected) { "Open" } else { "Closed" }
                $Socket.Close()
            } catch {
                $Status = "Closed"
            }
            [pscustomobject] @{
                Port = $Port
                Protocol = "tcp"
                Status = $Status
            }
        }

        # Set up and run jobs
        foreach ($Port in $StartPort..$EndPort) {
            $Params = @{ IPv4Address = $IPv4Address; Port = $Port }
            $Job = [powershell]::Create().AddScript($ScriptBlock).AddArguments($Params)
            $Job.RunspacePool = $RunspacePool
            $Jobs.Add([pscustomobject]@{ Pipe = $Job; Result = $Job.BeginInvoke() })
        }

        # Process results
        Write-Output "Waiting for jobs to complete..."
        while ($Jobs.Count -gt 0) {
            $CompletedJobs = $Jobs | Where-Object { $_.Result.IsCompleted }
            $Jobs = $Jobs | Where-Object { -not $_.Result.IsCompleted }

            foreach ($Job in $CompletedJobs) {
                $Result = $Job.Pipe.EndInvoke($Job.Result)
                $Job.Pipe.Dispose()
                if ($Result.Status -eq "Open" -and $XML_PortList) {
                    AssignServiceWithPort -Result $Result
                } else {
                    $Result
                }
            }

            Start-Sleep -Milliseconds 500
        }

        # Clean up
        $RunspacePool.Close()
        $RunspacePool.Dispose()

        Write-Output "Script finished at $(Get-Date)"
    }
}
