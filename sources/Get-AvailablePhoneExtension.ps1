<#
    .Synopsis
        Searches for available phone extensions

    .Notes
        Author: Paulo Schwab
        Date: 30-Dec-2021
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Location
)

$Rootpath = split-path -parent $PSScriptRoot

$allPhoneExtensions = Import-Csv "$Rootpath\resources\PhoneExtensions.csv" -Delimiter ";"
$phoneExtensions = $allPhoneExtensions | Where-Object {$_.Location -eq $Location}

$percentage = 15
Write-Progress -Activity "Searching fixed phone extensions" -PercentComplete $percentage

foreach ($phoneExtension in $phoneExtensions){
    $percentage++
    Write-Progress -Activity "Searching fixed phone extensions" -PercentComplete $percentage
    $extension = ($phoneExtension.Extensions).Trim()

    if (!(Get-ADUser -Filter {ipPhone -eq $extension})){
        $fixedPhoneNumber = $phoneExtension.Extensions
        break
    }
}

Write-Progress -Activity "Searching fixed phone extensions" -Status "Ready" -Completed

return $fixedPhoneNumber
