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

    switch ($Location)
    {
        "Brasil" {
            $Path = "OU=Navegantes,OU=Brasil,OU=Internal,OU=Users,OU=Huisman Global,DC=HSLE,DC=local"
            $domain = "huisman-br.com"
            $Office = "Huisman Navegantes"
            $StreetAddress = "Rua Prefeito Manoel Evaldo Muller, 4373,`r`n Volta Grande, Navegantes - Santa Catarina"
            $POBox = ""
            $City = "Navegantes"
            $State = "Santa Catarina"
            $PostalCode = "88371-390"
            $Country = "BR"
            $CountryCode = 76
            $CO = "Brazil"
            $Company = "Huisman Ltda"
            $HomeDirectory = "\\BR-NAV01-home01\nHome01$"

            continue
        }
    
        "China" {
            $Path = "OU=Zhangzhou,OU=China,OU=Internal,OU=Users,OU=Huisman Global,DC=HSLE,DC=local"
            $domain = "huisman-cn.com"
            $Office = "Huisman China"
            $StreetAddress = "China Merchants Zhangzhou Development Zone, China Merchants Avenue NO. 48"
            $POBox = ""
            $City = "Zhangzhou"
            $State = "Fujian Province"
            $PostalCode = "363105"
            $Country = "CN"
            $CountryCode = 157
            $CO = "China"
            $Company = "Huisman (China) Co., Ltd."
            $HomeDirectory = "\\CN-ZHA01-home01\nHome01$"

            continue
        }
    
        "Czech" {
            $Path = "OU=Sviadnov,OU=Czech,OU=Internal,OU=Users,OU=Huisman Global,DC=HSLE,DC=local"
            $domain = "huisman-cz.com"
            $Office = "Huisman Czech"
            $StreetAddress = "Nadrazni 289"
            $POBox = ""
            $City = "Sviadnov"
            $State = ""
            $PostalCode = "739 25"
            $Country = "CZ"
            $CountryCode = 0
            $CO = "Czech Republic"
            $Company = "Huisman-Konstrukce s.r.o."
            $HomeDirectory = "\\CZ-SVI01-home01\nHome01$"

            continue
        }

        "Netherlands" {
            $Path = "OU=Schiedam,OU=Netherlands,OU=Internal,OU=Users,OU=Huisman Global,DC=HSLE,DC=local"
            $domain = "huisman-nl.com"
            $Office = "Huisman Schiedam"
            $StreetAddress = "Admiraal Trompstraat 2"
            $POBox = "P.O. Box 150 3100 AD Schiedam"
            $City = "Schiedam"
            $State = "Zuid Holland"
            $PostalCode = "3115 HH"
            $Country = "NL"
            $CountryCode = 528
            $CO = "Netherlands"
            $Company = "Huisman Equipment B.V."
            $HomeDirectory = "\\NL-SCH01-cifs03\nHome01$"

            continue
        }

        "Norway" {
            $Path = "OU=Bergen,OU=Norway,OU=Internal,OU=Users,OU=Huisman Global,DC=HSLE,DC=local"
            $domain = "huisman-no.com"
            $Office = "Huisman Norway"
            $StreetAddress = "Trollhaugmyra 15"
            $POBox = ""
            $City = "Straume"
            $State = ""
            $PostalCode = "5353"
            $Country = "NO"
            $CountryCode = 578
            $CO = "Norway"
            $Company = "Huisman Equipment B.V."
            $HomeDirectory = "\\NL-SCH01-cifs03\nHome01$"

            continue
        }

        "United States" {
            $Path = "OU=Rosenberg,OU=United States,OU=Internal,OU=Users,OU=Huisman Global,DC=HSLE,DC=local"
            $domain = "huisman-na.com"
            $Office = "Huisman Rosenberg"
            $StreetAddress = "2502 Wehring Road"
            $POBox = ""
            $City = "Rosenberg"
            $State = "Texas"
            $PostalCode = "TX 77471"
            $Country = "US"
            $CountryCode = 840
            $CO = "United States"
            $Company = "Huisman Equipment B.V."
            $HomeDirectory = "\\US-HOU01-home01\nHome01$"

            continue
        }

        "Singapore" {
            $Path = "OU=Singapore,OU=Singapore,OU=Internal,OU=Users,OU=Huisman Global,DC=HSLE,DC=local"
            $domain = "huisman-sg.com"
            $Office = "Huisman Singapore"
            $StreetAddress = "36 TUAS view Place Link Point Place"
            $POBox = ""
            $City = "Singapore"
            $State = ""
            $PostalCode = "637882"
            $Country = "US"
            $CountryCode = 702
            $CO = "Singapore"
            $Company = "Huisman Far East Services Pte Ltd"
            $HomeDirectory = "\\SG-SIN01-home01\nHome01$"

            continue
        }
    }
    
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
