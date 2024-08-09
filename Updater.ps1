
# Function to write colored text
function Write-Color {
    param (
        [string]$Text,
        [ConsoleColor]$Color,
        [bool]$Log = $false  # Default value is false, meaning no logging unless specified
    )

    # Write the text to the console with the specified color
    Write-Host $Text -ForegroundColor $Color

    # If the Log parameter is true, save the text to the log file
    if ($Log) {
        UpdateLog -Message $Text
    }
}

# Function to validate URL format
function Test-UrlFormat {
    param (
        [string]$url
    )
    
    return $url -match '^https?:\/\/([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}(:[0-9]{1,5})?(\/.*)?$'
}

# Function to check URL accessibility and content
function CheckUrlAccessibilityAndContent {
    param (
        [string]$url
    )
    
    try {
        $response = Invoke-WebRequest -Uri $url -ErrorAction Stop -TimeoutSec 10
        $statusCode = $response.StatusCode
        $contentType = $response.Headers.'Content-Type'
        $content = $response.Content

        Write-Color "Status code: $statusCode" -Color DarkBlue
        Write-Color "Content type: $contentType" -Color DarkBlue

        # Try to parse content as JSON regardless of Content-Type
        try {
            $jsonContent = $content | ConvertFrom-Json -ErrorAction Stop
            if ($jsonContent.error) {
                Write-Color "Error found in response: $($jsonContent.error)" -Color Red
                return $false
            } else {
                Write-Color "Content is valid JSON." -Color Green
                return $true
            }
        } catch {
            Write-Color "Content is not valid JSON or could not be parsed. Response content: $content" -Color DarkRed
            return $false
        }
    } catch {
        Write-Color "Exception occurred: $($_.Exception.Message)" -Color Red
        return $false
    }
}

# Function to execute a command and capture output and errors
function ExecuteSingBoxCommand {
    param (
        [string]$filePath,
        [string]$arguments
    )
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $filePath
    $process.StartInfo.Arguments = $arguments
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true

    $process.Start() | Out-Null
    $output = $process.StandardOutput.ReadToEnd()
    $error2 = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    return [PSCustomObject]@{
        ExitCode = $process.ExitCode
        Output   = $output
        Error    = $error2
    }
}

# Function to update the config file
function Update-ConfigFile {
    $startTime = Get-Date

    do {
        # Prompt user for URL
        $url = Read-Host "Enter the URL to download"

        # Check if URL is empty
        if ([string]::IsNullOrWhiteSpace($url)) {
            Write-Color "Please provide a valid URL." -Color Red
            continue
        }

        # Validate the URL format
        Write-Color "Validating URL format: $url..." -Color Blue
        if (-not (Test-UrlFormat -url $url)) {
            Write-Color "The URL format is invalid. Please provide a valid URL." -Color Red 
            continue
        }

        # Check URL accessibility and content
        Write-Color "Checking URL accessibility and content: $url..." -Color Blue
        if (-not (CheckUrlAccessibilityAndContent -url $url)) {
            continue
        }

        # Define the output file
        $outputFile = "temp.json"

        # Use PowerShell to download the file
        Write-Color "Downloading from $url..." -Color Cyan
        try {
            Invoke-WebRequest -Uri $url -OutFile $outputFile -ErrorAction Stop
            if (Test-Path $outputFile) {
                Write-Color "Download successful. File saved as $outputFile." -Color Green
            } else {
                Write-Color "Failed to download file. Please check the URL and try again." -Color Red
                continue
            }
        } catch {
            Write-Color "Failed to download file. Please check the URL and try again." -Color Red
            continue
        }

        # Run the check command on the downloaded file
        Write-Color "Running check command on $outputFile" -Color Cyan 
        $checkResult = ExecuteSingBoxCommand -filePath ".\sing-box.exe" -arguments "check -c $outputFile"
        
        if ($checkResult.ExitCode -eq 0) {
            Write-Color "Check command executed successfully." -Color Green

            # Run the format command if check command succeeds
            Write-Color "Running format command..." -Color Cyan
            $formatResult = ExecuteSingBoxCommand -filePath ".\sing-box.exe" -arguments "format -c $outputFile -w"
            
            if ($formatResult.ExitCode -eq 0) {
                Write-Color "Format command executed successfully." -Color Green

                # Copy temp.json to config.json
                Write-Color "Copying temp.json to config.json..." -Color Cyan
                Copy-Item -Path $outputFile -Destination "config.json" -Force

                # Delete temp.json
                Write-Color "Deleting temp.json..." -Color Cyan
                Remove-Item -Path $outputFile -Force

                # Calculate time consumed
                $endTime = Get-Date
                $elapsedTime = $endTime - $startTime
                $formattedTime = "{0:D2}:{1:D2}" -f $elapsedTime.Minutes, $elapsedTime.Seconds

                # Print success message
                Write-Color "The operation was a success." -Color Green
                Write-Color "The link you provided is: $url" -Color Green
                Write-Color "The time consumed: $formattedTime" -Color Green
                break
            } else {
                Write-Color "Format command failed with exit code $($formatResult.ExitCode)." -Color Red -Log $true
                Write-Color "Error output: $($formatResult.Error)" -Color Red -Log $true
                Write-Color "Command output: $($formatResult.Output)" -Color Yellow -Log $true
            }
        } else {
            Write-Color "Check command failed with exit code $($checkResult.ExitCode)." -Color Red -Log $true
            Write-Color "Error output: $($checkResult.Error)" -Color Red -Log $true
            Write-Color "Command output: $($checkResult.Output)" -Color Yellow -Log $true
        }
    } while ($true)
}

# Function to get the latest Sing-Box version 
function Get-LatestSingBoxVersionInfo {
    $versionInfoUrl = "https://api.github.com/repos/SagerNet/sing-box/releases/latest"
    
    try {
        $response = Invoke-WebRequest -Uri $versionInfoUrl -ErrorAction Stop -Headers @{ "Accept" = "application/vnd.github.v3+json" }
        $releaseInfo = $response.Content | ConvertFrom-Json

        # Extract version and architecture info
        $latestVersion = $releaseInfo.tag_name.TrimStart('v')  # Example: "1.9.3"

        # Initialize architecture info
        $architectureInfo = @{
            "64bit" = $null
            "32bit" = $null
            "arm64" = $null
        }

        # Populate architecture info with URL and extract directory
        foreach ($asset in $releaseInfo.assets) {
            if ($asset.name -match "sing-box-$latestVersion-windows-amd64\.zip$") {
                $architectureInfo["64bit"] = @{
                    url = $asset.browser_download_url
                    extract_dir = "sing-box-$latestVersion-windows-amd64"
                }
            } elseif ($asset.name -match "sing-box-$latestVersion-windows-386\.zip$") {
                $architectureInfo["32bit"] = @{
                    url = $asset.browser_download_url
                    extract_dir = "sing-box-$latestVersion-windows-386"
                }
            } elseif ($asset.name -match "sing-box-$latestVersion-windows-arm64\.zip$") {
                $architectureInfo["arm64"] = @{
                    url = $asset.browser_download_url
                    extract_dir = "sing-box-$latestVersion-windows-arm64"
                }
            }
        }

        return @{
            Version = $latestVersion
            Architectures = $architectureInfo
        }
    } catch {
        Write-Color "Failed to get the latest release version info." -Color Red -Log $true
        Write-Color "Exception: $($_.Exception.Message)" -Color Red -Log $true
        return $null
    }
}

function Update-SingBoxCore {
    $exePath = ".\sing-box.exe"
    $singBoxExists = Test-Path $exePath

    if ($singBoxExists) {
        Write-Color "Running version check for Sing-Box..." -Color White
        $versionResult = ExecuteSingBoxCommand -filePath $exePath -arguments "version"

        if ($versionResult.ExitCode -eq 0) {
            # Extract version number from the output
            if ($versionResult.Output -match 'sing-box version (\d+\.\d+\.\d+)') {
                $currentVersion = $matches[1]
                Write-Color "The current version is: $currentVersion" -Color Green 

                
            } else {
                Write-Color "Failed to extract version from the output." -Color Red -Log $true
                Write-Color "Full output: $($versionResult.Output)" -Color Yellow -Log $true

                return
            }
        } else {
            Write-Color "Failed to get Sing-Box version." -Color Red -Log $true
            Write-Color "Error output: $($versionResult.Error)" -Color Red -Log $true
            Write-Color "Command output: $($versionResult.Output)" -Color Yellow -Log $true

            return
        }
    } else {
        Write-Color "Sing-Box executable not found at $exePath." -Color Red -Log $true

        $currentVersion = $null
    }

    # Get and print system architecture
    $systemInfo = Get-ComputerInfo
    $architecture = $systemInfo.OSArchitecture
    Write-Color "System architecture: $architecture" -Color Green 

    # Define a function to get the latest version info
    $latestInfo = Get-LatestSingBoxVersionInfo
    if ($latestInfo) {
        $latestVersion = $latestInfo.Version
        Write-Color "Latest Sing-Box Version: $latestVersion" -Color Blue 

        # Check if the version is up-to-date
        if ($singBoxExists -and $currentVersion -eq $latestVersion) {
            Write-Color "You are using the latest version." -Color Green 

        } else {
            Write-Color "Updating Sing-Box to the latest version..." -Color Cyan -Log $true


            # Map architecture to the expected key
            $architectureKey = switch ($architecture) {
                "64-bit" { "64bit" }
                "32-bit" { "32bit" }
                "ARM64"  { "arm64" }
                default { Write-Color "Unknown architecture: $architecture" -Color Red -Log $true ; $null }
            }

            if ($architectureKey) {
                # Debugging output to check the structure of $latestInfo
                Write-Color "Latest info structure: $($latestInfo | ConvertTo-Json -Depth 3)" -Color Cyan -Log $true

                if ($latestInfo.Architectures) {
                    $downloadInfo = $latestInfo.Architectures[$architectureKey]

                    if ($downloadInfo) {
                        $downloadUrl = $downloadInfo.url
                        $extractDir = $downloadInfo.extract_dir

                        # Verify the URL before attempting to download
                        try {
                            $response = Invoke-WebRequest -Uri $downloadUrl -Method Head -ErrorAction Stop
                            if ($response.StatusCode -eq 200) {
                                $zipFilePath = "sing-box-latest.zip"
                                $scriptDirectory = Get-Location
                                $extractedFolderPath = Join-Path -Path $scriptDirectory -ChildPath "sing-box-latest"

                                # Download the latest version
                                Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath -ErrorAction Stop
                                Write-Color "Downloaded latest Sing-Box version." -Color Green -Log $true

                                # Create the extraction directory if it does not exist
                                if (-not (Test-Path $extractedFolderPath)) {
                                    New-Item -Path $extractedFolderPath -ItemType Directory | Out-Null
                                }

                                # Extract the ZIP file to the temporary directory
                                Write-Color "Extracting the ZIP file..." -Color Cyan -Log $true
                                Expand-Archive -Path $zipFilePath -DestinationPath $extractedFolderPath -Force
                                Write-Color "Extraction complete." -Color Green -Log $true

                                # Move the extracted files to the original directory
                                $extractedExePath = Join-Path -Path $extractedFolderPath -ChildPath $extractDir
                                $extractedExeFile = Join-Path -Path $extractedExePath -ChildPath "sing-box.exe"

                                if (Test-Path $extractedExeFile) {
                                    Move-Item -Path $extractedExeFile -Destination $exePath -Force
                                    Write-Color "Moved sing-box.exe to the target directory." -Color Green

                                    # Clean up
                                    Remove-Item -Path $zipFilePath -Force
                                    Remove-Item -Path $extractedFolderPath -Recurse -Force
                                    Write-Color "Updated Sing-Box to version $latestVersion." -Color Green -Log $true

                                } else {
                                    Write-Color "sing-box.exe not found in the extracted files." -Color Red -Log $true

                                }
                            } else {
                                Write-Color "The download URL returned status code $($response.StatusCode)." -Color Red -Log $true

                            }
                        } catch {
                            Write-Color "Failed to download or extract the latest version." -Color Red -Log $true
                            Write-Color "Exception: $($_.Exception.Message)" -Color Red -Log $true

                        }
                    } else {
                        Write-Color "No download information found for the architecture key: $architectureKey" -Color Red -Log $true

                    }
                } else {
                    Write-Color "Architectures section in latest info is missing or null." -Color Red -Log $true

                }
            } else {
                Write-Color "Invalid architecture key: $architecture" -Color Red -Log $true


            }
        }
    } else {
        Write-Color "Failed to get the latest release version info." -Color Red -Log $true

    }
}

function Start-SingBoxCore {
    param (
        [string]$ScriptPath = $MyInvocation.MyCommand.Path
    )

    # Check if the script is running with elevated privileges
    function Test-Admin {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    # Request elevation if not running as admin
    if (-not (Test-Admin)) {
        $arguments = "& { Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"' -Verb RunAs }"
        # Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
        Start-Process -FilePath ".\sing-box.exe" -ArgumentList "run" -NoNewWindow -Wait
        UpdateLog -Message "The Core Started Successfully"
        return
    }

    # Switch to script directory
    Set-Location (Split-Path -Parent $ScriptPath)

    # Start sing-box.exe in a new cmd window 
    Start-Process -FilePath ".\sing-box.exe" -ArgumentList "run " -NoNewWindow -Wait



    # Pause to allow the user to read messages
    Read-Host -Prompt "The Core Stopped ..."
}

function Open-GitHubLink {
$answer = Read-Host "Would you like to open the URL in your default browser? (y/n)"
if ($answer -eq 'y') 
    {
    $url = "https://github.com/PashaGH8101/sing-box-batch"
    Start-Process $url
    }

}
# Function to create and update log files for debugging and other purposes
function UpdateLog {
    param (
        [string]$Message
    )

    # Define the log file path
    $LogFilePath = "log.txt"

    # Get the current date and time
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Create the log entry
    $logEntry = "$timestamp - $Message"

    # Append the log entry to the log file
    Add-Content -Path $LogFilePath -Value $logEntry
}

# Function to read the log and search for a specific query
function ReadLog {
    param (
        [string]$SearchTerm
    )

    # Define the log file path
    $LogFilePath = "log.txt"

    # Check if the log file exists
    if (-Not (Test-Path -Path $LogFilePath)) {
        Write-Output "Log file not found."
        return
    }

    # Read the log file and search for the term
    $logEntries = Get-Content -Path $LogFilePath
    $matchingEntries = $logEntries | Select-String -Pattern $SearchTerm

    # Output the matching entries
    if ($matchingEntries) {
        $matchingEntries
    } else {
        Write-Output "No matching entries found for '$SearchTerm'."
    }
}



# Main menu logic
do {
    $asciiArt = @"

    ______            _            
    | ___ \          | |           
    | |_/ /__ _  ___ | |__    __ _ 
    |  __// _` |/ __|| '_ \  / _` |
    | |  | (_| |\__ \| | | || (_| |
    \_|   \__,_||___/|_| |_| \__,_|
                                                          
"@

$summary = @"
******************************************************
*                                                    *
*    I create this tool for easier usage of          *
*    sing-box core inside Windows. With just a few   *
*    clicks, you can use this absolutely             *
*    anti-censorship core.                           *
*                                                    *
******************************************************
"@
    
    Write-Host $asciiArt -ForegroundColor Green
    Write-Host $summary -ForegroundColor Green
    Write-Host "https://github.com/PashaGH8101/sing-box-batch" -ForegroundColor Magenta 
    Write-Color "1. Install or Update the Sing-Box core" -Color Yellow 
    Write-Color "2. Update the config file (Fetch the latest from a URL)" -Color Yellow
    Write-Color "3. Start the Sing-box Core" -Color Yellow
    Write-Color "4. Link to My Github For latest Information and Updates" -Color Yellow
    Write-Color "0. Exit" -Color Yellow
    $choice = Read-Host "Select an option"

    switch ($choice) {
        '1' {
            Update-SingBoxCore
            
        }
        '2' {
            Update-ConfigFile
        }
        '3' {
            Start-SingBoxCore
        }
        '4' {
            Open-GitHubLink
        }
        '0' {
            Write-Color "Exiting..." -Color Cyan
            break
        }
        default {
            Write-Color "Invalid option. Please select a valid option." -Color Red
        }
    }
} while ($choice -ne '0')
