<#
    .Synopsis
        This script starts the GUI for the Access Management Tool.
        It organizes the content and calls secondary scripts with the parameters that were informed.

        
    .Notes
    Created by Paulo Schwab Rocha
    Date: 13-Sep-2021

    Change history:
    Date || Responsible || Change Description
#>

# Import all libraries in the Assembly folder
$AssemblyLocation = "$PSScriptRoot\assembly"
foreach ($Assembly in (Get-ChildItem $AssemblyLocation -Filter *.dll)) {
    [System.Reflection.Assembly]::LoadFrom($Assembly.fullName) | Out-Null
}

# Load extra libraries
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.ComponentModel') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Data')           | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')        | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')      | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsBase')           | Out-Null

Add-Type -AssemblyName 'System.Web'

# Load the XAML file
[xml]$XAML = Get-Content "$PSScriptRoot\xaml\ADAccessManagementTool\HSLE_AccessManagementToolWPF\MainWindow.xaml"
$XAML.MetroWindow.RemoveAttribute('x:Class')
$XAML.MetroWindow.RemoveAttribute('mc:Ignorable')
$XAMLReader = New-Object System.Xml.XmlNodeReader $XAML
$MainWindow = [Windows.Markup.XamlReader]::Load($XAMLReader)

$XAML.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object { 
    New-Variable -Name $_.Name -Value $MainWindow.FindName($_.Name) -Force 
}

# Version
$version = "1.0.0"
$MainWindow.Title = "HSLE Access Management Tool v$($version)"

$userData = Import-Csv "$PSScriptRoot\resources\allusers.csv"
$userData = $userData.displayname
$tempData = New-Object 'Collections.Generic.List[string]'

$JSONconfig = Get-Content .\resources\config.json -Raw | ConvertFrom-Json

foreach ($item in $userData) {
    if ($item -match $usr_combo_manager.Text){
        $tempData.Add($item)
    }
}

$usr_combo_manager.ItemsSource = $tempData
$flyout_combobox_parentUser.ItemsSource = $tempData
$mbx_combo_owner.ItemsSource = $tempData

# Add Locations in ComboBox
$JSONconfig.Location.Name | ForEach-Object {$usr_combo_location.Items.Add($_);$mbx_combo_location.Items.Add($_)} | Out-Null

#region Control's Events

# Main Window - Buttons
$main_bt_git.Add_Click({Start-Process "https://github.com/pschwab1/ADAccessManagementTool"})
$main_bt_reset.Add_Click({Clear-Fields})

# User Tab - Checkboxes
$usr_cb_endDate.Add_Checked( { $usr_calendar.isEnabled = $true })
$usr_cb_endDate.Add_unChecked( { $usr_calendar.isEnabled = $false })

$usr_cb_Phone.Add_Checked({$usr_gb_Telephony.isEnabled = $true})
$usr_cb_Phone.Add_unChecked({$usr_gb_Telephony.isEnabled = $false})

$flyout_cb_defaultGroups.Add_Checked({
    foreach ($defaultADGroup in $JSONconfig.DefaultADGroups.Default) {
        $flyout_txtbox_assignedGroups.Text += $defaultADGroup + [System.Environment]::NewLine
    }
})
$flyout_cb_defaultGroups.Add_unChecked({$flyout_txtbox_assignedGroups.Text = $null})

$flyout_cb_CSEngineers.Add_Checked({
    foreach ($DefaultCSEngineersGroup in $JSONconfig.DefaultADGroups.CSEngineer) {
        $flyout_txtbox_assignedGroups.Text += $DefaultCSEngineersGroup + [System.Environment]::NewLine
    }
})
$flyout_cb_CSEngineers.Add_unChecked({$flyout_txtbox_assignedGroups.Text = $null})


# User Tab - Buttons
$usr_bt_searchFixedPhone.Add_Click({
    
    if ($usr_combo_location.SelectedItem){
        $fixedPhoneNumber = & ".\Sources\Get-AvailablePhoneExtension.ps1" -Location $usr_combo_location.SelectedItem
    } else {
        [System.Windows.Forms.MessageBox]::Show("Select a location first")
    }
    $usr_txtbox_fixedPhone.Text = $fixedPhoneNumber

    $usr_txtbox_externalPhone.Text = "$(Get-HSLELocation -Location $usr_combo_location.SelectedItem -Phone) $($fixedPhoneNumber.Substring(2))"

})

$usr_bt_newPassword.Add_Click({
    $usr_txtbox_password.Text = New-RandomPassword
})

$usr_tile_createUser.Add_Click({
    if ($usr_label_UserNameAvailability.Content -eq "Existing"){
        $MessageBoxTitle = "Create user"
        $MessageBoxButton = [System.Windows.Forms.MessageBoxButtons]::OK
        $MessageBoxIcon = [System.Windows.Forms.MessageBoxIcon]::Error
        [System.Windows.Forms.MessageBox]::Show("The username $($usr_txtbox_username.text.ToUpper()) is in use, choose another.","Username unavailable",$MessageBoxButton,$MessageBoxIcon)
    } else {
        # Searches for empty Textboxes
        $emptyStrings = (Get-Variable -Name "*usr_txtbox*" -ValueOnly | Where-Object {$_.Text -eq "" -and $_.isEnabled -eq $true} | Select-Object Name, Text).Name
        if ($emptyStrings.Count -ge 1){
            $MessageBoxText = "The following fields are empty, proceed anyway?`n`n$([string]::Join([System.Environment]::NewLine,$emptyStrings))"
            $MessageBoxTitle = "Create user"
            $MessageBoxButton = [System.Windows.Forms.MessageBoxButtons]::OKCancel
            $MessageBoxIcon = [System.Windows.Forms.MessageBoxIcon]::Information
        
            $result=[System.Windows.Forms.MessageBox]::Show($MessageBoxText,$MessageBoxTitle,$MessageBoxButton,$MessageBoxIcon)

        }

        if ($emptyStrings.count -eq 0 -or $result -eq 'OK'){
            Write-Host "Creating Account" -ForegroundColor Yellow
            & ".\sources\New-HSLEADUser.ps1" -SamAccountName $usr_txtbox_username.Text `
            -EmailAddress $usr_txtbox_email.Text `
            -UserPWD $usr_txtbox_password.Text `
            -GivenName $usr_txtbox_firstName.Text `
            -SurName $usr_txtbox_lastName.Text `
            -DisplayName $usr_txtbox_displayName.Text `
            -Location $usr_combo_location.SelectedItem `
            -Department $usr_txtbox_department.Text `
            -JobTitle $usr_txtbox_jobTitle.Text `
            -Manager $usr_combo_manager.Text `
            -Trigram $usr_txtbox_trigram.Text `
            -EmployeeNumber $usr_txtbox_personnelNumber.Text `
            -MobilePhone $usr_txtbox_mobilePhone.Text `
            -Extension $usr_txtbox_fixedPhone.Text `
            -HomePhone $usr_txtbox_externalPhone.Text `
            -SIMNumber $usr_txtbox_SIMNumber.Text `
            -EndDate $usr_calendar.SelectedDate `
            -SecurityGroups $flyout_txtbox_assignedGroups.Text
        }
    }

    # working SimpleChildWindow
    #$CW_ConfirmUserCreation.ShowCloseButton = $true
    #$CW_ConfirmUserCreation.IsOpen = $True

    <#not working in this version of MahApps
    #$okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
    #$result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($MainWindow,"Title","Your message. ",$okAndCancel),
    #>
    
    <# Working Solution with DialogManager
    $Dialog = [SimpleDialogs.Controls.MessageDialog]::new()
    $Dialog.Title = "Confirmation"
    $Dialog.Message = "`r`nDo you want to create the user?"
    $Dialog.Width = 600
    $Dialog.ShowFirstButton  = $True
    $Dialog.ShowSecondButton = $True

    [SimpleDialogs.DialogManager]::ShowDialogAsync($MainWindow, $Dialog)
     
    $Dialog.Add_ButtonClicked({
     $Button_Args  = [SimpleDialogs.Controls.DialogButtonClickedEventArgs]$args[1] 
     $Button_Value = $Button_Args.Button
     if($Button_Value -eq "FirstButton")
      {
       [System.Windows.Forms.MessageBox]::Show("OK")    
      }
     elseif($Button_Value -eq "SecondButton")
      {
       [System.Windows.Forms.MessageBox]::Show("Cancel")    
      }    
    })   
    #>
})

# User Tab - Textbox
$usr_txtbox_firstName.Add_LostFocus({$usr_txtbox_displayName.Text = $usr_txtbox_lastName.Text + ", " + $usr_txtbox_firstName.Text})
$usr_txtbox_lastName.Add_LostFocus({
    $usr_txtbox_displayName.Text = $usr_txtbox_lastName.Text + ", " + $usr_txtbox_firstName.Text
    Set-UserName -FirstName $usr_txtbox_firstName.Text -LastName $usr_txtbox_lastName.Text
    Get-UserNameAvailability -Username $usr_txtbox_username.Text
})

$usr_txtbox_username.Add_LostFocus({
    Get-UserNameAvailability -Username $usr_txtbox_username.Text
})

$usr_txtbox_username.Add_TextChanged({
    if ($usr_combo_location.SelectedItem) {
        #$mailDomain = Get-HSLELocation -Location $usr_combo_location.SelectedItem -Domain
        $mailDomain = $JSONconfig.Location | Where-Object {$_.Name -eq $usr_combo_location.SelectedItem} | Select-Object -ExpandProperty Domain
        $usr_txtbox_email.Text = $usr_txtbox_username.text + $mailDomain
    }
    else {
        $usr_txtbox_email.Text = $usr_txtbox_username.Text    
    }
})

#User Tab - Combo Box
$usr_combo_manager.Add_GotFocus({$usr_combo_manager.IsDropDownOpen = $true})
$usr_combo_manager.Add_KeyDown({
    
    $tempData.Clear()

    foreach ($item in $userData) {
        if ($item -match $usr_combo_manager.Text){
            $tempData.Add($item)
        }
    }
    $usr_combo_manager.ItemsSource = $tempData
    $usr_combo_manager.Items.Refresh()
    $usr_combo_manager.SelectedIndex = -1

    $usr_combo_manager.Padding = 5

})

$usr_combo_location.Add_SelectionChanged({
    $mailDomain = Get-HSLELocation -Location $usr_combo_location.SelectedItem -Domain
    $usr_txtbox_email.Text = $usr_txtbox_username.text + $mailDomain
})

# User Tab - Flyout
$usr_bt_showFlyout.Add_Click({ $FlyOut.IsOpen = $true })

$flyout_bt_searchUser.Add_Click({
    $parentUser = $flyout_combobox_parentUser.text
    $parentUserGroups = (Get-ADUser -Filter {Name -like $parentUser -or SamaccountName -eq $parentUser} | Get-ADPrincipalGroupMembership).Name
    foreach ($item in $parentUserGroups) {
        $flyout_txtbox_assignedGroups.Text += $item + [System.Environment]::NewLine
    }
    $flyout_txtbox_assignedGroups.Text = $flyout_txtbox_assignedGroups.Text.Trim()

    # Splits content into an array for the groups textbox
    $parentUserGroups = $flyout_txtbox_assignedGroups.Text.Split("`n")
})

$flyout_combobox_parentUser.Add_GotFocus({$flyout_combobox_parentUser.IsDropDownOpen = $true})
$flyout_combobox_parentUser.Add_KeyUp({
    
    $tempData.Clear()
    foreach ($item in $userData) {
        if ($item -match $flyout_combobox_parentUser.Text){
            $tempData.Add($item)
        }
    }
    $flyout_combobox_parentUser.IsDropDownOpen = $true
    $flyout_combobox_parentUser.ItemsSource = $tempData
    $flyout_combobox_parentUser.SelectedIndex = -1
    $flyout_combobox_parentUser.Items.Refresh()
    $flyout_combobox_parentUser.Padding = 5
})

# Shared Mailbox Tab - ComboBox
$mbx_combo_owner.Add_GotFocus({$mbx_combo_owner.IsDropDownOpen = $true})
$mbx_combo_owner.Add_KeyUp({

    $tempData.Clear()
    foreach ($item in $userData) {
        if ($item -match $mbx_combo_owner.Text){
            $tempData.Add($item)
        }
    }
    $mbx_combo_owner.IsDropDownOpen = $true
    $mbx_combo_owner.ItemsSource = $tempData
    $mbx_combo_owner.SelectedIndex = -1
    $mbx_combo_owner.Items.Refresh()
    $mbx_combo_owner.Padding = 5
})

$mbx_tile_createMbx.Add_Click({

    & ".\Sources\New-SharedMBX.ps1" `
    -MailboxName $mbx_txtbox_mbxName.Text `
    -GroupName $mbx_txtbox_mbxGroupName.Text `
    -Owner $mbx_combo_owner.SelectedValue `
    -Members $mbx_txtbox_mbxMembers.Text `
    -TicketNumber $mbx_txtbox_ticketnr.Text `
    -domainName (Get-HSLELocation -Location $mbx_combo_location.SelectedItem -Domain)
})

# Folder Access - Buttons
$folder_bt_checkACL.Add_Click({
    $DataSource = & ".\Sources\Get-FolderACL.ps1" -folderPath $folder_txtbox_folderPath.Text
    $folder_datagrid_acls.ItemsSource = $DataSource.DefaultView

})

$folder_bt_searchUser.Add_Click({

    try {
        Get-ADUser $folder_txtbox_user.Text -ErrorAction Stop
        $folder_txtbox_user.Foreground = "Blue"
        $folder_label_user.Foreground = "Black"
        $folder_label_user.Content = "User found"
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
        $folder_label_user.Content = "User not found"
        $folder_label_user.Foreground = "Red"
        $folder_txtbox_user.Foreground = "Red"
    }
})

$folder_tile_assignGroup.Add_Click({
    $okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
    foreach ($row in $folder_datagrid_acls.Items){
        if ($row.Select -eq $true){
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($MainWindow,"This is a test only",$row.Groups,$okAndCancel)
        }
    }
})

#endregion Control's Events

#region Functions
# Generates a New-RandomPassword
function New-RandomPassword{
    $newPassword = [System.Web.Security.Membership]::GeneratePassword(10, 3)
    $pattern="[^a-k-mzA-H-J-N-P-Z0-9!@#$%&*+_=]"
    $newPassword=[regex]::Replace($newPassword,$pattern, (Get-Random -Minimum 1 -Maximum 9).ToString())

    return $newPassword
}

# Get information based on location. Reads from the .resources/config.json file
function Get-HSLELocation(){
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]$Location,
        [Parameter(Mandatory=$false, ParameterSetName='OU')] [switch]$OU,
        [Parameter(Mandatory=$false, ParameterSetName='Domain')] [switch]$Domain,
        [Parameter(Mandatory=$false, ParameterSetName='Phone')] [switch]$Phone,
        [Parameter(Mandatory=$false, ParameterSetName='ADGroups')] [switch]$ADGroups
    )

    switch($PsCmdlet.ParameterSetName){
        'OU'        {return ($JSONconfig.Location | Where-Object {$_.Name -eq $Location} | Select-Object -ExpandProperty OUPath)}
        'Domain'    {return ($JSONconfig.Location | Where-Object {$_.Name -eq $Location} | Select-Object -ExpandProperty Domain)}
        'Phone'     {return ($JSONconfig.Location | Where-Object {$_.Name -eq $Location} | Select-Object -ExpandProperty ExternalPhoneNumber)}
        'ADGroups'  {return ($JSONconfig.Location | Where-Object {$_.Name -eq $Location} | Select-Object -ExpandProperty ADGroups)}
        
    }
}

function Set-UserName($FirstName,$LastName){
    # Last name transformation, for when user has multiple last names
    $LastName = $LastName.split(" ")
    if($LastName.count -gt 1){
        $LastName = $Lastname[-2].Substring(0,1)+$Lastname[-1]
    }

    $usr_txtbox_username.Text = ($FirstName[0]+$LastName).ToLower()
}

function Get-UserNameAvailability($Username){
    $usr_label_UserNameAvailability.Visibility = "Visible"

    if($usr_txtbox_username.Text -ne ""){
        if (Get-ADUser -Filter {SamAccountName -eq $usr_txtbox_username.Text}){
            $usr_label_UserNameAvailability.Content = "Existing"
            $usr_label_UserNameAvailability.Foreground = "Red"
        } else {
            $usr_label_UserNameAvailability.Content = "Available"
            $usr_label_UserNameAvailability.Foreground = "Green"
        }
    }
}

function Clear-Fields {
    #$AllFields = ((Get-Variable -Name "*txtbox*" -ValueOnly | Where-Object {$_.Text -eq "" -and $_.isEnabled -eq $true} | Select-Object Name, Text).Name) -join "`n"
    $AllFields = Get-Variable | Where-Object {$_.Value -like "System.Windows.Controls*"}

    foreach ($field in $AllFields) {
        if ($field.Value.ToString() -like "System.Windows.Controls.TextBox*" -or $field.Value.ToString() -like "System.Windows.Controls.ComboBox*"){
            $field.Value.Text = ""
        }

        if ($field.Value.ToString() -like "System.Windows.Controls.CheckBox*"){
            $field.Value.isChecked = $false
        }
    }

    $usr_txtbox_password.Text = New-RandomPassword

}
#endregion Functions

#Functions to execute at the start of the GUI
$usr_txtbox_password.Text = New-RandomPassword
$flyout_cb_defaultGroups.IsChecked = $true


# Loads the SplashScreen
#& ".\sources\Start-SplashScreen.ps1"

# Loads Main Form
#$app = [Windows.Application]::new()
#$app.Run($MainWindow)
$MainWindow.ShowDialog() | Out-Null