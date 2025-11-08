# Final optimized torch control for PowerShell 5.1
Add-Type -AssemblyName System.Runtime.WindowsRuntime

$null = [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
$null = [Windows.Media.Capture.MediaCapture,Windows.Media.Capture,ContentType=WindowsRuntime]
$null = [Windows.Devices.Enumeration.DeviceInformation,Windows.Devices.Enumeration,ContentType=WindowsRuntime]

try {
    # Find camera with torch support
    $videoDeviceSelector = [Windows.Devices.Enumeration.DeviceClass]::VideoCapture
    $findOperation = [Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($videoDeviceSelector)
    
    $asTaskMethod = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]
    
    $asTaskGeneric = $asTaskMethod.MakeGenericMethod([Windows.Devices.Enumeration.DeviceInformationCollection])
    $devices = $asTaskGeneric.Invoke($null, @($findOperation)).GetAwaiter().GetResult()
    
    $asTaskActionMethod = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction'
    })[0]
    
    $mediaCapture = $null
    foreach ($device in $devices) {
        $mc = New-Object Windows.Media.Capture.MediaCapture
        $settings = New-Object Windows.Media.Capture.MediaCaptureInitializationSettings
        $settings.VideoDeviceId = $device.Id
        
        try {
            $asTaskActionMethod.Invoke($null, @($mc.InitializeAsync($settings))).Wait()
            
            if ($mc.VideoDeviceController.TorchControl.Supported) {
                Write-Host "Using: $($device.Name)" -ForegroundColor Green
                $mediaCapture = $mc
                break
            }
            $mc.Dispose()
        } catch {
            if ($mc) { $mc.Dispose() }
        }
    }
    
    if (!$mediaCapture) {
        Write-Error "No camera with torch support found."
        return
    }
    
    Write-Host "Turning torch ON..." -ForegroundColor Yellow
    
    # Start minimal recording (required for hardware torch activation)
    $stream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
    $profile = [Windows.Media.MediaProperties.MediaEncodingProfile]::CreateMp4([Windows.Media.MediaProperties.VideoEncodingQuality]::Qvga)
    $asTaskActionMethod.Invoke($null, @($mediaCapture.StartRecordToStreamAsync($profile, $stream))).Wait()
    
    $mediaCapture.VideoDeviceController.TorchControl.Enabled = $true
    Write-Host "Torch ON (Press Enter to turn off)" -ForegroundColor Green
    
    Read-Host
    
    # Turn off
    $mediaCapture.VideoDeviceController.TorchControl.Enabled = $false
    $asTaskActionMethod.Invoke($null, @($mediaCapture.StopRecordAsync())).Wait()
    $stream.Dispose()
    Write-Host "Torch OFF" -ForegroundColor Green
    
} catch {
    Write-Error $_.Exception.Message
} finally {
    if ($mediaCapture) { $mediaCapture.Dispose() }
}
