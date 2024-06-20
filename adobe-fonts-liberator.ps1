# Get the current script directory
$currentDirectory = $PSScriptRoot

# Construct the destination folder path
$destinationFolder = Join-Path -Path $currentDirectory -ChildPath 'Adobe Fonts'

# Load the XML file
[xml]$xmlData = Get-Content -Path "C:\Users\$env:USERNAME\AppData\Roaming\Adobe\CoreSync\plugins\livetype\c\entitlements.xml"

# Function to determine font type based on file contents
function Get-FontTypeFromBytes {
    param (
        [byte[]]$fileBytes
    )

    # Recognize based on common font file signatures
    if ($fileBytes[0] -eq 0x4F -and $fileBytes[1] -eq 0x54 -and $fileBytes[2] -eq 0x54 -and $fileBytes[3] -eq 0x4F) {
        return "OpenType"
    }
    elseif ($fileBytes[0] -eq 0x00 -and $fileBytes[1] -eq 0x01 -and $fileBytes[2] -eq 0x00 -and $fileBytes[3] -eq 0x00) {
        return "TrueType"
    }
    elseif ($fileBytes[0] -eq 0x80 -and $fileBytes[1] -eq 0x01 -and $fileBytes[2] -eq 0x00 -and $fileBytes[3] -eq 0x00) {
        return "TrueType"
    }
    elseif ($fileBytes[0] -eq 0x01 -and $fileBytes[1] -eq 0x00 -and $fileBytes[2] -eq 0x00 -and $fileBytes[3] -eq 0x00) {
        return "CFF"
    }
    elseif ($fileBytes[0] -eq 0x80 -and $fileBytes[1] -eq 0x02 -and $fileBytes[2] -eq 0x00 -and $fileBytes[3] -eq 0x00) {
        return "CFF"
    }
    else {
        return "Unknown"
    }
}

# Map font types to file extensions
$fontTypeExtensions = @{
    "OpenType" = "otf"
    "TrueType" = "ttf"
    "CFF" = "cff"
    # Add more mappings as needed
}

# Extract font information
$fonts = $xmlData.typekitSyncState.fonts.font

foreach ($font in $fonts) {
    $fontId = $font.id
    $fullName = $font.properties.fullName
    $sourceFilePath = "C:\Users\$env:USERNAME\AppData\Roaming\Adobe\CoreSync\plugins\livetype\r\$fontId"
    
    # Read the font file as bytes
    $fileBytes = [System.IO.File]::ReadAllBytes($sourceFilePath)
    
    # Determine the font type based on file content
    $fontType = Get-FontTypeFromBytes -fileBytes $fileBytes
    
    # Get the file extension based on font type
    if ($fontTypeExtensions.ContainsKey($fontType)) {
        $fileExtension = $fontTypeExtensions[$fontType]
    } else {
        $fileExtension = "font"  # Default extension if type is unknown
    }
    
    # Adjust destination file path based on detected font type and extension
    $destinationFilePath = Join-Path -Path $destinationFolder -ChildPath ("$fullName.$fileExtension")
    
    # Copy the file to the destination
    Copy-Item -Path $sourceFilePath -Destination $destinationFilePath
    
    Write-Output "Copied $sourceFilePath to $destinationFilePath"
    Write-Output "Font Type: $fontType"
}

Write-Output "Operation completed."
