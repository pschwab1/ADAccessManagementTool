<#
    .Synopsis
        This script creates the AD account in the Huisman network.

    .Notes
    Author: Paulo Schwab
    Date: 05-Jan-2022

    Changes:


#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$SamAccountName,
    [Parameter(Mandatory=$true)]
    [string]$EmailAddress,
    [Parameter(Mandatory=$true)]
    [string]$UserPWD,
    [Parameter(Mandatory=$false)]
    [string]$GivenName,
    [Parameter(Mandatory=$false)]
    [string]$SurName,
    [Parameter(Mandatory=$false)]
    [string]$DisplayName,
    [Parameter(Mandatory=$true)]
    [string]$Location,
    [Parameter(Mandatory=$false)]
    [string]$Department,
    [Parameter(Mandatory=$false)]
    [string]$JobTitle,
    [Parameter(Mandatory=$false)]
    [string]$Manager="",
    [Parameter(Mandatory=$false)]
    [string]$Trigram="",
    [Parameter(Mandatory=$false)]
    [string]$EmployeeNumber="",
    [Parameter(Mandatory=$false)]
    [string]$MobilePhone="",
    [Parameter(Mandatory=$false)]
    [string]$Extension="",
    [Parameter(Mandatory=$false)]
    [string]$HomePhone="",
    [Parameter(Mandatory=$false)]
    [string]$SIMNumber="",
    [Parameter(Mandatory=$false)]
    [string]$EndDate,
    [Parameter(Mandatory=$false)]
    [string[]]$SecurityGroups
)

begin {

    # Needs to be executed in NL server in order to synchronize in time with Exchange servers
    $DomainController = "scriptdc.hsle.local"

   
}

# New-AdUser -Server $DC -GivenName "$SAFirstName" -SurName "$SALastName" 
# -Displayname "$SADisplayName" -SamAccountName $SASamName -Name "$SADisplayName" 
# -employeeNumber $SAPersnum -userPrincipalName "$SASamname@$domain" 
# -Description "User account" -Department "$SADepartment" 
# -Office "$SAOffice" -Street "$SALocStreet" -POBox "$SAPOBox" 
# -City "$SAlocation" -State "$SAState" -PostalCode "$SAPostal" 
# -Country "$SACountry" -officephone $SADeskPhoneInt 
# -homephone "$SADeskPhoneExt" -mobilephone "$SAMobileNr" 
# -manager "$SAManager" -path "$SAPath" 
# -Accountpassword (convertto-securestring -asplaintext $SAPassword -force) 
# -changepasswordatlogon 1 
# -Enabled 1 
# -OtherAttributes @{'title'="$SAFunction"; 'CountryCode'="$SACountryCode"; 'co'="$SACO"} -Company "$SACompany" 
# -AccountExpirationDate $SAEndDate; sleep 5; Set-AdUser $SASamName -Server $DC -add @{ipPhone=$SADeskPhoneInt};sleep 5; 

# Set-ADUser $SASamName -Server $DC -HomeDirectory "$SALocHomeServ\$SASamName" -HomeDrive "U:"
    
process {
    <#
    # Create the user
    #New-ADUser -Server $DomainController -SamAccountName $SamAccountName -AccountPassword (ConvertTo-SecureString -AsPlainText $UserPWD -Force) -Path $Path
    #Start-Sleep 5

    # Edit the user
    Set-ADUser -Server $DomainController -Identity $SamAccountName `
    -Description "User Account" `
    -GivenName $GivenName `
    -Surname $SurName `
    -DisplayName $DisplayName `
    -Name $DisplayName `
    -EmailAddress $EmailAddress `
    -UserPrincipalName $EmailAddress `
    -Department $Department `
    -EmployeeNumber $EmployeeNumber `
    -Office $Office `
    -StreetAddress $StreetAddress `
    -POBox $POBox `
    -City $City `
    -Company $Company `
    -Country $Country `
    -HomeDirectory "$($HomeDirectory)\$SamAccountName" `
    -HomeDrive "U:" `
    -Manager $Manager `
    -PostalCode $PostalCode `
    -State $State `
    -Title $JobTitle `
    -Add @{'CountryCode'=$CountryCode;'co'=$CO;'extensionAttribute14'=$EmployeeNumber;'extensionAttribute15'=$Trigram;`
    'ipPhone'=$Extension; 'mobile'=$MobilePhone;'mobilePhone'=$MobilePhone; 'HomePhone'=$HomePhone
}

    if ($EndDate){
        Set-ADUser -Identity $SamAccountName -AccountExpirationDate $EndDate
    }
    #>

    $message = "
    User will be created with the following attributes: `n
    `nIdentity: $SamAccountName
    `nDescription: User Account
    `nGivenName: $GivenName
    `nSurname: $SurName
    `nDisplayName: $DisplayName
    `nName: $DisplayName
    `nEmailAddress: $EmailAddress
    `nUserPrincipalName: $EmailAddress
    `nDepartment: $Department
    `nEmployeeNumber: $EmployeeNumber
    `nOffice: $Office
    `nStreetAddress: $StreetAddress
    `nPOBox: $POBox
    `nCity: $City
    `nCompany: $Company
    `nCountry: $Country
    `nHomeDirectory: $($HomeDirectory)\$SamAccountName
    `nHomeDrive: U:
    `nManager: $Manager
    `nPostalCode: $PostalCode
    `nState: $State
    `nTitle: $JobTitle
    `nCountryCode: $CountryCode
    `nco: $CO
    `nextensionAttribute14: $EmployeeNumber
    `nextensionAttribute15: $Trigram
    `nipPhone: $Extension
    `nmobile: $MobilePhone
    `nmobilePhone: $MobilePhone
    `nHomePhone: $HomePhone
    `nSecurityGroups: $SecurityGroups
"
    $okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($MainWindow,"This is a test only",$message,$okAndCancel)

    # Create mailbox

    
    

    #[System.Windows.Forms.MessageBox]::Show($SecurityGroups)

}

end {
    
}
