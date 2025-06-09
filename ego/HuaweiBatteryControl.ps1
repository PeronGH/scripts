#Requires -RunAsAdministrator

# Credit to:
# https://github.com/AceDroidX/HuaweiBatteryControl
# This script is a PowerShell port of the original C++ code

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$UpperLimit,
    
    [Parameter(Position = 1)]
    [string]$LowerLimit,
    
    [Parameter()]
    [switch]$New,
    
    [Parameter()]
    [switch]$Help
)

function Show-Help {
    @"
Usage:

HuaweiBatteryControl.ps1 <upper limit> <lower limit> [-New]
    -New     Using new methods, new devices or BIOS may require this option

HuaweiBatteryControl.ps1 <raw data in decimal>
    Raw data explain:
    0x<upper limit><lower limit>1003
    0x<upper limit><lower limit>48011503 (for new devices or BIOS)
    Then convert hex to decimal

Examples:
    .\HuaweiBatteryControl.ps1 80 60
    .\HuaweiBatteryControl.ps1 80 60 -New
    .\HuaweiBatteryControl.ps1 1174537219
"@
}

function Get-BatteryData {
    param($UpperLimit, $LowerLimit, $New, $ArgCount)
    
    # Default data
    $data = [uint64]0x46281003
    
    switch ($ArgCount) {
        1 { 
            $data = [uint64]$UpperLimit 
        }
        2 { 
            $upper = [uint64]$UpperLimit
            $lower = [uint64]$LowerLimit
            $data = $upper * 0x1000000 -bor $lower * 0x10000 -bor 0x1003
        }
        3 { 
            if ($New) {
                $upper = [uint64]$UpperLimit
                $lower = [uint64]$LowerLimit
                $data = $upper * 0x10000000000 -bor $lower * 0x100000000 -bor 0x48011503
            } else {
                throw "Unknown option. Use -Help for more information"
            }
        }
        default {
            # Use default data
        }
    }
    
    return $data
}

function Invoke-HuaweiBatteryControl {
    try {
        # Count non-empty arguments
        $argCount = 0
        if ($UpperLimit) { $argCount++ }
        if ($LowerLimit) { $argCount++ }
        if ($New) { $argCount++ }
        
        if ($Help -or ($argCount -eq 0)) {
            Show-Help
            return
        }
        
        $data = Get-BatteryData -UpperLimit $UpperLimit -LowerLimit $LowerLimit -New $New -ArgCount $argCount
        
        Write-Host "Command-line arguments:" -ForegroundColor Green
        if ($UpperLimit) { Write-Host "  UpperLimit: $UpperLimit" }
        if ($LowerLimit) { Write-Host "  LowerLimit: $LowerLimit" }
        if ($New) { Write-Host "  New: True" }
        
        # Compatible hex formatting
        $hexValue = "0x{0:X}" -f $data
        Write-Host "data: $data($hexValue)" -ForegroundColor Yellow
        
        # Create input data as byte array
        $inputArray = New-Object byte[] 64
        $dataBytes = [BitConverter]::GetBytes($data)
        
        # Copy data to input array (first 8 bytes for the uint64)
        $copyLength = [Math]::Min($dataBytes.Length, 8)
        for ($i = 0; $i -lt $copyLength; $i++) {
            $inputArray[$i] = $dataBytes[$i]
        }
        
        Write-Host "Connected to ROOT\WMI WMI namespace" -ForegroundColor Cyan
        
        # Get WMI instance directly
        $wmiInstance = Get-WmiObject -Namespace "ROOT\WMI" -Class "OemWMIMethod" -Filter "InstanceName='ACPI\\PNP0C14\\HWMI_0'"
        
        if (-not $wmiInstance) {
            throw "Could not find Huawei WMI instance. This may not be a supported Huawei device."
        }
        
        # Execute the method - the key fix is here
        $result = $wmiInstance.OemWMIfun($inputArray)
        
        # Check if we got a result object
        if ($result) {
            # Check for u8Output property
            if ($result.u8Output) {
                # Convert first 8 bytes of output to uint64 for display (like the C++ version)
                if ($result.u8Output.Length -ge 8) {
                    $outputBytes = $result.u8Output[0..7]
                    $outputValue = [BitConverter]::ToUInt64($outputBytes, 0)
                    Write-Host "u8Output:$outputValue" -ForegroundColor Green
                } else {
                    # If less than 8 bytes, just show the first value
                    Write-Host "u8Output:$($result.u8Output[0])" -ForegroundColor Green
                }
            } else {
                Write-Host "u8Output: No output data returned"
            }
            
            # Check return value if it exists
            if ($null -ne $result.ReturnValue) {
                if ($result.ReturnValue -eq 0) {
                    Write-Host "Battery control command executed successfully!" -ForegroundColor Green
                } else {
                    Write-Warning "Method returned non-zero code: $($result.ReturnValue)"
                }
            } else {
                Write-Host "Battery control command executed successfully!" -ForegroundColor Green
            }
        } else {
            Write-Warning "No result returned from WMI method"
        }
        
    }
    catch [System.Management.ManagementException] {
        Write-Error "WMI Error: $($_.Exception.Message)"
        Write-Host "This may indicate:" -ForegroundColor Yellow
        Write-Host "  - This is not a Huawei device" -ForegroundColor Yellow
        Write-Host "  - The required WMI interface is not available" -ForegroundColor Yellow
        Write-Host "  - Administrator privileges are required" -ForegroundColor Yellow
        Write-Host "  - The device driver is not properly installed" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Unexpected error: $($_.Exception.Message)"
        Write-Host "Stack trace:" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
}

# Main execution
Invoke-HuaweiBatteryControl
