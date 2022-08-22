<#
    .SYNOPSIS
        This script creates a Shared Mailbox in the Huisman Environment.

        Workinstruction location:


    .NOTES
        Author: Paulo Schwab
        Date: 04-Dec-2020

        Revision:
            29-Jan-2021 - pschwab
            Adjusted to receive Credentials via parameters and convert it to login to Exchange Online
            05-Feb-2021 - PSchwab
            Added SendAs permissions
            24-Mar-2021 - pschwab
            Fixed Hide From Address list for Groups
            28-Apr-2021 - Paulo Schwab
            Adjusted Credentials funtion to enable script to be executed directly.
            Removed SendAs cmdlet from the On-Premises Exchange as it is not supported for Remote Mailbox.
#>

Param
(
    [Parameter(Mandatory=$true)]
    [string]$MailboxName,

    [Parameter(Mandatory=$true)]
    [string]$GroupName,

    [Parameter(Mandatory=$false)]
    [string]$Owner,

    [Parameter(Mandatory=$false)]
    [array]$Members,

    [Parameter(Mandatory=$false)]
    [string]$TicketNumber,

    [Parameter(Mandatory=$true)]
    [string]$domainName,

    [Parameter(Mandatory=$false)]
    [PSCredential]$Credentials,
    
    [Parameter(Mandatory=$false)]
    [PSCredential]$LogFile
)
$message = "
The Shared mailbox will be created with the following info:`n

`nMailboxName: $MailboxName
`nGroupName: $GroupName
`nOwner: $Owner
`nMembers: $Members
`nTicketNumber: $TicketNumber
`nDomainName: $domainName
"

$okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
$result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($MainWindow,"This is a test only",$message,$okAndCancel)


<#
Begin{


    Function Write-Log
	{
        param(
            [Parameter(Mandatory=$False)]
            [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
            [String]$MessageType = "INFO",
            [Parameter(Mandatory=$True)]
            [string]$Message
        )
		
		$MyDate = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)		
		Add-Content $LogFile  "$MyDate - $MessageType : $Message"			
		Write-Output  "$MyDate - $MessageType : $Message"		
    }

    if (!($Credentials)) {
        #$searcher = [adsisearcher]"(samaccountname=$env:USERNAME)"
        #$UserMail = $searcher.FindOne().Properties.mail
        
        #$credentials = Get-Credential -UserName "HSLE\$env:USERNAME" -Message "Insert your HSLE credentials"
    }

}

process{
    Write-Output "Connecting to Exchange On-Prem"

    #$PSSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://nl-sch01-ex50.hsle.local/PowerShell/ -Credential $Credentials
    #Import-PSSession $PSSession -AllowClobber

    try{
        if (!($TicketNumber)){
            $TicketNumber = ""
        }
        New-DistributionGroup -Name $GroupName -Alias $GroupName -DisplayName $GroupName -Type Security -OrganizationalUnit "HSLE.LOCAL/Huisman Global/Groups/Mail" -Notes $TicketNumber -ErrorAction Stop
        Set-DistributionGroup -Identity $GroupName -HiddenFromAddressListsEnabled $true

        if ($Members) {
            Write-Output "Adding Members"
            $Members | Add-DistributionGroupMember -Identity $GroupName -ErrorAction Stop
        }

        if ($Owner){
            Write-Output "Adding Owner"
            Set-DistributionGroup -Identity $GroupName -ManagedBy $Owner -BypassSecurityGroupManagerCheck
        }

        Write-Output "Converting to Remote Mailbox"
        New-RemoteMailbox -Shared -Name $MailboxName -DisplayName $MailboxName -Alias $MailboxName -OnPremisesOrganizationalUnit "HSLE.LOCAL/Management/Mailbox Accounts/Shared" -PrimarySmtpAddress $MailboxName$domainName -Archive -ErrorAction Stop
        Write-Output "Hiding from Address List"
        Set-RemoteMailbox $MailboxName -HiddenFromAddressListsEnabled:$True -ErrorAction Stop

    } catch [exception]{
        Write-Error $Error[0].Exception.Message
    }

    if (!(Test-Path C:\Temp)){
        New-Item -ItemType Directory -Force -Path "C:\Temp"
    }

    Write-Output "Created the Shared Mailbox $MailboxName"

    "Created the Shared Mailbox $MailboxName. Please wait up to 2 hours to synchronization.

    Group Name: $GroupName
    Owner: $Owner
    Members: $Members" | Out-File C:\Temp\shared_mailbox_text.txt -Force

    notepad.exe C:\Temp\shared_mailbox_text.txt

    # connect to Exchange Online
    $EXOUser=(Get-ADUser $Credentials.UserName.split('\')[1]).UserPrincipalName
    $EXOPassword=$Credentials.password

    [pscredential]$EXOCred = New-Object System.Management.Automation.PSCredential ($EXOUser, $EXOPassword)

    Write-Output "Connecting to Exchange Online"
    Connect-ExchangeOnline -Credential $EXOCred
    #Connect-ExchangeOnline -ShowProgress

    # Executes only if connected to O365 session
    if ((Get-PSSession).computername -like "outlook.office365.com"){

        # This functions keeps trying to find if the mailbox is present in the Exchange Online environment.
        # Since the replication can take up to 1 hour, it loops until it finds the mailbox in EOX. Gives up after 3600 seconds.
        Write-Output "Connected to Exchange Online"
        $cont = 240
        [bool]$mbxFound = $false
        do{
            try{
                Get-Mailbox $MailboxName -ErrorAction stop
                $mbxFound = $true
            } catch [System.Management.Automation.RemoteException]{
                $cont--
                Write-Output $Error[0].Exception
                Write-Output "Waiting 30 seconds before trying again... Attempting $cont more times before exiting script."
                Start-Sleep 30
                if ($cont -eq 0){
                    Write-Output "Could not find the mailbox $MailboxName on the Exchange Online environment. Finishing script. Please verify manually."
                    break
                }
            } catch {
                Write-Output "An error has occurred... retrying..."
            }
        } while ($mbxFound -eq $false)

        # Sets the permissions when the mailbox has been migrated to EOX
        if($mbxFound -eq $true){
            Add-MailboxPermission -Identity $MailboxName -User $groupName -AccessRights FullAccess -InheritanceType All
            Add-RecipientPermission -Identity $MailboxName -AccessRights Sendas -Trustee $groupName -Confirm:$false
        }

    }
}

end {
    Get-PSSession | Remove-PSSession
}
#>

