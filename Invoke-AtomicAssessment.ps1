Set-ExecutionPolicy Bypass -Force

function Test-Administrator  
{  
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
    }
}

function Get-ProceduresFromJsonFiles($path) {
    $jsonFiles = Get-ChildItem -Path $path -Recurse -Filter *.json
    $proceduresList = @()
    
    foreach ($file in $jsonFiles) {
        try {
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            if ($jsonContent.procedures) {
                foreach ($procedure in $jsonContent.procedures) {
                    foreach ($step in $procedure.steps) {
                        # Remove specific fields from each step
                        $step.PSObject.Properties.Remove('process-id')
                        $step.PSObject.Properties.Remove('exit-code')
                        $step.PSObject.Properties.Remove('is-timeout')
                    }
                    $proceduresList += $procedure
                }
            }
        } catch {
            Write-Host "Error reading file: $($file.FullName)"
        }
    }
        
    return $proceduresList
}

function Get-UserInfo {
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    return $user
}

function Get-HostInfo {
    $hostname = $env:COMPUTERNAME
    return $hostname
}

function Get-IPInfo {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq "Ethernet0" }).IPAddress
    return $ip
}

function Generate-ExecutionID {
    return [guid]::NewGuid().ToString()
}

function Invoke-AtomicAssessment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Adversary
    )

    $outputPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $outputPath | Out-Null

    if (-not (Test-Administrator)) {
        Write-Error "This script must be executed as Administrator."
        exit 1
    }

    if (Test-Path "C:\AtomicRedTeam\") {
        Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
    } else {
        IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1'); Install-AtomicRedTeam -getAtomics -Force
        Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
    }

    $start_time = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    $Adversary = $Adversary.ToLower()

    $json = ""

    if (Test-Path ".\profiles\$Adversary.json") {
        $json = Get-Content -Path ".\profiles\$Adversary.json" -Raw | ConvertFrom-Json
    } else {
        Write-Host "Adversary '$Adversary' not found. Available adversaries:"
        Get-ChildItem -Path .\profiles\ -Filter *.json | ForEach-Object {
            Write-Host "- $($_.BaseName)"
        }
        return
    }

    Write-Output "Simulate $($json.name)"
    Write-Output ""

    foreach ($test in $json.AtomicTests) {
        Write-Output "Test Number: $($test.TestNumber)"
        Write-Output "Description: $($test.Description)"
       
        if ($test.Commands) {
            foreach ($command in $test.Commands) {
                if ($command -like "*Invoke-AtomicTest*") {
                    $timestamp = Get-Date -Format "yyyyMMddHHmmssfff"
                    $logPath = "$outputPath\timestamp_$timestamp.json"
                    iex "$command -LoggingModule 'Attire-ExecutionLogger' -ExecutionLogPath $logPath"
                    Start-Sleep -Seconds 2.5
                } else {
                    iex "$command"
                }
            }
        }
        
        if ($test.Command) {
            if ($test.Command -like "*Invoke-AtomicTest*") {
                $timestamp = Get-Date -Format "yyyyMMddHHmmssfff"
                $logPath = "$outputPath\timestamp_$timestamp.json"
                iex "$($test.Command) -LoggingModule 'Attire-ExecutionLogger' -ExecutionLogPath $logPath"
                Start-Sleep -Seconds 2.5
            } else {
                iex "$($test.Command)"
            }
        }
        
        Write-Output ""
    }

    # Get procedures from all JSON files in the specified folder
    $allProcedures = Get-ProceduresFromJsonFiles -path $outputPath

    # Sequentially number the "order" fields
    $order = 1
    foreach ($procedure in $allProcedures) {
        $procedure.order = $order
        $order++
    }

    # Get dynamic information
    $username = Get-UserInfo
    $hostname = Get-HostInfo
    $ip_address = Get-IPInfo
    $executionID = Generate-ExecutionID

    # Create the final JSON object with the additional parameters
    $finalResult = @{
        "attire-version" = "1.1"
        "execution-data" = @{
            "execution-source" = $json.name
            "execution-id" = $executionID
            "execution-category" = @{
                "name" = "Atomic Red Team"
                "abbreviation" = "ART"
            }
            "execution-command" = "Invoke-AtomicAssessment"
            "target" = @{
                "user" = $username
                "host" = $hostname
                "ip" = $ip_address
            }
            "time-generated" = $start_time
        }
        "procedures" = $allProcedures
    }

    # Define output directory and filename
    $outputDir = ".\output"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $outputFileName = "$outputDir\$Adversary`_result_$hostname`_$timestamp.json"

    # Output the final JSON object, in UTF-8
    $jsonContent = $finalResult | ConvertTo-Json -Depth 10
    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($outputFileName, $jsonContent, $utf8NoBomEncoding)

    # Delete the temporary folder
    Remove-Item -Recurse -Force -Path $outputPath  
    
    # Return the output file name
    return $outputFileName
}
