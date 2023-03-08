Function Get-AzureSignInLogs {

# Set date/time to one day prior.
$range = "{0:yyyy-MM-dd}" -f (get-date).AddDays(-1)

# State to Filter out of results.
$state = "Florida"

# Top Level Domain Name
$TLDname = "consoto.com"

# Get Sign-in logs for the previous day.
$result = Get-AzureADAuditSignInLogs -Filter "createdDateTime gt $range" | Where-Object {$_.Location.State -ne $state}

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
<p class="MsoNormal"><strong><span class="SpellE">Below is the daily summary of non-%state% based login attempts for AzureAD accounts at %TLD%. %totals% records found in the last 24 hours.</span></strong></p>
<p style="font-weight: 400;"><span style="color: #999999;">Full reports can be found on Azure Active Directory - Sign-In Logs</span><br /></p>
<p style="font-weight: 400;"><span style="color: #999999;"></span><br /></p>
"@


# Replaces the string %totals% in body HTML with the value of the report count.
IF ($total.Count -eq 0) {$reportnumber = "No"} ELSE {$reportnumber = $total.Count}
$body = ($body | ForEach-Object {
    $_ -replace '%totals%',$reportnumber
})

# Replaces the string %state% in body HTML with the value of $state variable.
$body = ($body | ForEach-Object {
    $_ -replace '%state%',$state
})

# Replaces the string %TLD% in body HTML with the value of $TLDname variable.
$body = ($body | ForEach-Object {
    $_ -replace '%TLD%',$TLDname
})

# Replace FailureReason with more sensible and short explanatations. Fits the table in the email better.
switch($result){
    {$_.status.errorcode -eq "50053"}{$_.Status.Failurereason = "Too many Logon attempts"}
    {$_.status.errorcode -eq "50126"}{$_.status.failurereason = "Invalid credentials"}
    {$_.status.errorcode -eq "50072"}{$_.status.failurereason = "you must enroll in multi-factor.."}
    {$_.status.errorcode -eq "53003"}{$_.status.failurereason = "Blocked by CA Policies"}
    {$_.status.errorcode -eq "50074"}{$_.status.failurereason = "MFA step incomplete"}
    {$_.status.errorcode -eq "0"}{$_.status.failurereason = "Successful"}
}

# Fix date/time format.
$result | ForEach-Object {$_.CreatedDateTime = (Get-Date($_.CreatedDateTime) -Format g)}

# Output Results to HTML Variable
Write-Output ($result | select userPrincipalName, CreatedDateTime, SignInAuditLogObject, Location, IpAddress, Status, UserDisplayName, AppDisplayName | ConvertTo-Html -Property @{Label="User"; Expression={$_.UserDisplayName}}, @{Label="TimeStamp"; Expression={$_.CreatedDateTime}}, @{Label="Country"; Expression={$_.Location.CountryOrRegion}}, @{Label="City"; Expression={$_.Location.City}}, @{Label="IPAddress"; Expression={$_.IpAddress}}, @{Label="Application"; Expression={$_.AppDisplayName}}, @{Label="Error Code"; Expression={$_.Status.ErrorCode}}, @{Label="Error"; Expression={$_.Status.FailureReason}} -Head $header -Body $body )

}

Import-module AzureAdPreview

Sleep 1

Connect-AzureAD -TenantId "<id>" -ApplicationId  "<appid>" -CertificateThumbprint "<thumbprint>"

Sleep 2

$html = Get-AzureSignInLogs

Sleep 2

Disconnect-AzureAD

# --- Prepare to send email.

# Establigh credentials and email body
$emailusername = "reporting@domain.com"
$encrypted = Get-Content "C:\folder\key.txt" | ConvertTo-SecureString
$SMTPServer = "smtp.office365.com"
# $html = Get-Content -Path " " -Raw

# Prepare message components
$message = New-Object System.Net.Mail.MailMessage
$message.From = "reporting@domain.com"
$message.To.Add("admin@domain.com")
$message.Subject = "AzureAD: Suspicious Sign-Ins for", (Get-Date -Format MM/dd/yyyy)
$message.IsBodyHTML = $true
$message.Body = $html
# $message.Attachments.Add($file1) --If you need to include attachments!
# $message.Attachments.Add($file2) --If you need to include attachments!

# Send Message
$smtp = New-Object System.Net.Mail.SmtpClient($SmtpServer, 587)
$smtp.EnableSsl = $true
$credential = New-Object System.Net.NetworkCredential($emailuserName, $encrypted)
$smtp.Credentials = $credential
$smtp.Send($message)
