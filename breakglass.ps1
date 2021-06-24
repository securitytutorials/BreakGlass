#install-module msolservice
#install-module ExchangeOnlineManagment

$acctName = read-host "Enter O365 Username"
#$Credential = Get-Credential -username $acctName -Message " Type the Accounts Password"
#Azure Active Directory
Connect-MsolService
#Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName $acctName -ShowProgress $true
#Security & Compliance Center
Connect-IPPSSession -UserPrincipalName $acctName

function Get-RandomCharacters($length, $characters) { 
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs="" 
    return [String]$characters[$random]
}

$CharSet1 = "abcdefghiklmnoprstuvwxyzABCDEFGHKLMNOPRSTUVWXYZ1234567890."
$CharSet2 = "abcdefghiklmnoprstuvwxyzABCDEFGHKLMNOPRSTUVWXYZ1234567890!§$%&/()=?}][{@#*+"

$username = Get-RandomCharacters -length 20 -characters $CharSet1


$Password = Get-RandomCharacters -length 20 -characters $CharSet2

#Finds *.OnMicrosoft.com tenant domain and saves to a variable
$OnMicrosoftDomain = get-AcceptedDomain -Identity *.Onmicrosoft.com | select-object -ExpandProperty name

$UPN = $username+ "@"+ $OnMicrosoftDomain

try
{
#Create BreakGlass User
    New-MsolUser -userPrincipalName $UPN -DisplayName "BreakGlass" -firstName "Break" -LastName "Glass" -Password $Password -ErrorAction stop
    Add-MsolRoleMember -RoleName "Company administrator" -RoleMemberEmailAddress $UPN
}
catch { 
Write-host $_
$Password = Get-RandomCharacters -length 20 -characters $CharSet2
New-MsolUser -userPrincipalName $UPN -DisplayName "BreakGlass" -firstName "Break" -LastName "Glass" -Password $Password -ErrorAction stop
Add-MsolRoleMember -RoleName "Company administrator" -RoleMemberEmailAddress $UPN

}
#enable Auditing on the Office 365 Tenant
$Audit = Get-AdminAuditLogConfig | Select-Object -ExpandProperty AdminAuditLogEnabled

if ($Audit -eq "True"){
    write-host "Auditing is Enabled in this tenant" -ForegroundColor Blue

}

else { 
    write-host "Auditing is not enabled in this tenant Will now Configure" -ForegroundColor Red
    Set-AdminAuditLogConfig -AdminAuditLogEnabled $true
}

#Setup Notification for when BreakGlass user logs on.

$Notify = read-host "Enter Email Address to notify when BreakGlass Account is logged into:"
    New-ActivityAlert -Name "BreakGlass Logon Alert" -Operation userloggedin -UserId $UPN -Description "Alert on Login of the BreakGlass Account" -NotifyUser $Notify -Severity High -Type Custom

Disconnect-ExchangeOnline -confirm:$false