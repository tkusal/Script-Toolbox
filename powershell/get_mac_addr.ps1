function Get-MACAddress {
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='ComputerName or IPv4-Address of the device which you want to scan')]
        [String[]]$ComputerName
    )

    Begin {
        $LocalAddress = @("127.0.0.1", "localhost", ".")
    }

    Process {
        foreach ($ComputerName2 in $ComputerName) {
            if ($LocalAddress -contains $ComputerName2) {
                $ComputerName2 = $env:COMPUTERNAME
            }

            if (-not (Test-Connection -ComputerName $ComputerName2 -Count 2 -Quiet)) {
                Write-Warning "Device '$ComputerName2' is not reachable via ICMP. ARP cache might not be updated."
            }

            $IPv4Address = [String]::Empty
            if ([bool]($ComputerName2 -as [System.Net.IPAddress])) {
                $IPv4Address = $ComputerName2
            } else {
                try {
                    $AddressList = [System.Net.Dns]::GetHostEntry($ComputerName2).AddressList
                    $IPv4Address = $AddressList | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1 -ExpandProperty IPAddressToString
                } catch {
                    Write-Error "Could not resolve IPv4 address for '$ComputerName2'. MAC address retrieval skipped."
                    continue
                }
            }

            $MAC = [String]::Empty
            if (-not [String]::IsNullOrEmpty($IPv4Address)) {
                $ArpResult = arp -a | ForEach-Object { $_.ToUpper() }
                $MAC = $ArpResult | Where-Object { $_.TrimStart().StartsWith($IPv4Address) } | ForEach-Object {
                    [Regex]::Matches($_, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])").Value
                }
            }

            if ([String]::IsNullOrEmpty($MAC) -and -not [String]::IsNullOrEmpty($IPv4Address)) {
                try {
                    $NbtstatResult = nbtstat -A $IPv4Address | Select-String "MAC"
                    $MAC = [Regex]::Matches($NbtstatResult, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])").Value
                } catch {
                    Write-Error "Could not resolve MAC address for '$ComputerName2' ($IPv4Address). Ensure the device is reachable and in the same subnet."
                    continue
                }
            }

            $Vendor = (Get-MACVendor -MACAddress $MAC | Select-Object -First 1).Vendor

            [pscustomobject]@{
                ComputerName = $ComputerName2
                IPv4Address = $IPv4Address
                MACAddress = $MAC
                Vendor = $Vendor
            }
        }
    }

    End {
    }
}
