Function Get-AzureSignInLogs {

# Set date/time to one day prior.
$range = "{0:yyyy-MM-dd}" -f (get-date).AddDays(-1)

# Get Sign-in logs for the previous day.
$result = Get-AzureADAuditSignInLogs -Filter "createdDateTime gt $range" | Where-Object {$_.Location.State -ne "Florida"}

# Get count of records found.
$total = ($result | Measure-Object | Select Count)

# HTML Header information.
$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

# HTML body information.
$body = @"
<p class="MsoNormal"><strong><span style="font-size: 12.0pt; line-height: 107%; color: #0070c0;"><span class="SpellE">AzureAD Daily Outside Access Summary:</span></strong></br>
<p class="MsoNormal"><strong><span class="SpellE">Below is the daily summary of non-florida based login attempts for AzureAD accounts at CONSOTO.com. %totals% records found in the last 24 hours.</span></strong></p>
<p style="font-weight: 400;"><span style="color: #999999;">Full reports can be found on Azure Active Directory - Sign-In Logs</span><br /></p>
<p style="font-weight: 400;"><span style="color: #999999;"></span><br /></p>
"@

# Replace %total% string in $body html with the $total count value.
IF ($total.Count -eq 0) {$reportnumber = "No"} ELSE {$reportnumber = $total.Count}

# Replaces the string %totals% in body HTML with the value of the report count.
$body = ($body | ForEach-Object {
    $_ -replace '%totals%',$reportnumber 
})

# Adjust descriptions of failure reasons.
$result | ForEach-Object {IF ($_.Status.ErrorCode -eq "50053") {$_.Status.FailureReason = "Too many Logon attempts."}}
$result | ForEach-Object {IF ($_.Status.ErrorCode -eq "50126") {$_.Status.FailureReason = "Invalid credentials."}}
$result | ForEach-Object {IF ($_.Status.ErrorCode -eq "50072") {$_.Status.FailureReason = "you must enroll in multi-factor.."}}
$result | ForEach-Object {IF ($_.Status.ErrorCode -eq "53003") {$_.Status.FailureReason = "Blocked by CA Policies."}}
$result | ForEach-Object {IF ($_.Status.ErrorCode -eq "0") {$_.Status.FailureReason = "Successful"}}


# Fix date/time format.
$result | ForEach-Object {$_.CreatedDateTime = (Get-Date($_.CreatedDateTime) -Format g)}

# Output Results to HTML Variable
Write-Output ($result | select userPrincipalName, CreatedDateTime, SignInAuditLogObject, Location, IpAddress, Status, UserDisplayName, AppDisplayName | ConvertTo-Html -Property @{Label="User"; Expression={$_.UserDisplayName}}, @{Label="TimeStamp"; Expression={$_.CreatedDateTime}}, @{Label="Country"; Expression={$_.Location.CountryOrRegion}}, @{Label="City"; Expression={$_.Location.City}}, @{Label="IPAddress"; Expression={$_.IpAddress}}, @{Label="Application"; Expression={$_.AppDisplayName}}, @{Label="Error Code"; Expression={$_.Status.ErrorCode}}, @{Label="Error"; Expression={$_.Status.FailureReason}} -Head $header -Body $body )

}

Import-module AzureAdPreview

Sleep 1

# Connecting to AzureAD using Service Principal
Connect-AzureAD -TenantId "<id>" -ApplicationId  "<appid>" -CertificateThumbprint "<thuumbprint>"

Sleep 2

$html = Get-AzureSignInLogs

Sleep 2

Disconnect-AzureAD

# --- Prepare to send email.

# Establigh credentials and email body
$emailusername = "reporting@consoto.com"
$encrypted = Get-Content "C:\temp\key.txt" | ConvertTo-SecureString
$SMTPServer = "smtp.office365.com"
# $html = Get-Content -Path " " -Raw

# Prepare message components
$message = New-Object System.Net.Mail.MailMessage
$message.From = "reporting@consoto.com"
$message.To.Add("sysadmin@consoto.com")
$message.Subject = "AzureAD: Suspicious Sign-Ins for", (Get-Date -Format MM/dd/yyyy)
$message.IsBodyHTML = $true
$message.Body = $html

# Send Message
$smtp = New-Object System.Net.Mail.SmtpClient($SmtpServer, 587)
$smtp.EnableSsl = $true
$credential = New-Object System.Net.NetworkCredential($emailuserName, $encrypted)
$smtp.Credentials = $credential
$smtp.Send($message)


# Parse out Successful from Unsuccessful logins (Error Code 0 vs ####)

# https://learn.microsoft.com/en-us/powershell/azure/active-directory/signing-in-service-principal?view=azureadps-2.0
# https://jannikreinhard.com/2022/06/24/get-an-daily-device-report-via-email-or-teams-with-logic-apps-step-by-step-guide/
