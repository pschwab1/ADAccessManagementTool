<#
    .Synopsis
        This script searches for the ACLs permissions of a folder, and returns it as a DataTable

    .Notes
        Author: Paulo Schwab Rocha
        Date: 14-Oct-2021

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$folderPath
)

$folderACL = Get-Item -LiteralPath $folderPath
$ACLs = $folderACL.GetAccessControl()

$DataTable = New-Object System.Data.Datatable

[void]$DataTable.Columns.Add("Select",[bool])
[void]$DataTable.Columns.Add("Groups",[string])
[void]$DataTable.Columns.Add("Permissions",[string])
[void]$DataTable.Columns.Add("Scope",[string])

#$DataTable.Columns.AddRange($DataGrid.Columns.Header)

function Get-GroupScope($Group, [string]$Permission){
    $groupMembers = Get-ADGroupMember $group | Where-Object {$_.ObjectClass -eq "Group"}

    foreach ($groupMember in $groupMembers) {
        $groupScope = (Get-ADGroup $groupMember).GroupScope
        if ($groupScope -eq "DomainLocal") {
            Get-GroupScope($groupMember,$permission)
        }
        elseif ($groupScope -eq "Global") {

            $group = $group.Replace("HSLE\","")
            $row = $DataTable.NewRow()
            $row.Select = $false
            $row.Groups = $groupMember.Name
            $row.Permissions = $permission
            $row.Scope = $groupScope
        
            return $row
        }
        else{
            return $null
        }
    }
}

foreach ($item in $ACLs.GetAccessRules($true,$true,[System.Security.Principal.NTAccount])){
    $group = $item.IdentityReference.Value

    if (!$group.Contains("HSLE"))
    {
        continue;
    }
    $group = $group.Replace("HSLE\","")
    $permission = $item.FileSystemRights.ToString()
    $groupScope = (Get-ADGroup $group).GroupScope

    $row = $DataTable.NewRow()
    $row.Select = $false
    $row.Groups = $group
    $row.Permissions = $permission
    $row.Scope = $groupScope
    
    $DataTable.Rows.Add($row)

    if ($groupScope -eq "DomainLocal") {
        $memberGroup=Get-GroupScope -Group $group -Permission $permission
        if ($null -ne $memberGroup) {
            $DataTable.Rows.Add($memberGroup)    
        }
    }
}

return ,$DataTable