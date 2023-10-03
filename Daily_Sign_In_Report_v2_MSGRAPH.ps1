# Daily Sign-in Log EMAIL Report Script. v1.01 (Updated 2023/10/03)

<#

Requires the presence of a folder on the C drive. 'C:\DailyReports'  Modify folder paths to meet your needs.
    Will save attachments to a folder as well as output a transcript for debugging.

Note, When updating the certificate annually, create a self-signed cert on the PC that will be running the task:
    Example:
        $certname = "Entra2023"
        $cert = New-SelfSignedCertificate -Subject "CN=$certname" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
        Export-Certificate -Cert $cert -FilePath "C:\certs\new\$certname.cer"

Script requires Graph and Graph Beta modules
    Install-Module Microsoft.Graph -AllowClobber
    Install-Module Microsoft.Graph.Beta -AllowClobber

Will need to register an App Registration/ID with the proper permissions (this list may be somewhat excessive but will be needed depending on how you modify this script for your needs.):
    AuditLog.Read.All
    Chat.ReadWrite.All
    Directory.Read.All
    Group.Read.All
    Mail.Read.All
    Mail.ReadWrite
    Mail.Send (see below for setting restrictions.)
    People.Read.All
    Site.Manage.All
    User.Read.All
    User.ReadWrite.All

Be sure to restrict outgoing mail capability of app to a specified account for security reasons. (See below)

    $restrictedGroup = New-DistributionGroup -Name "Reporting Accounts" -Type "Security" -Members @("reportingmailbox@consoto.com")
    $params = @{
        AccessRight        = "RestrictAccess"
        AppId              = "<APPID>" # The appid of the App account.
        PolicyScopeGroupId = $restrictedGroup.PrimarySmtpAddress
        Description        = "Restrict app permissions to only allow access to service account"
    }
    New-ApplicationAccessPolicy @params

#>

# Sent from and Sent to Variables.
$SendMailFrom = "reportingmail@consoto.com"
$SendMailTo = "o365admin@consoto.com"
$OperatingState = "Texas"
$Domain = "CONSOTO.com"

# Establish the Date the log is for.
$logdate = "{0:yyyy-MM-dd}" -f (get-date)

# -------------- TenantID for Graph App
$tenant = "<Tenant ID>"

# -------------- ClientID for Graph App
$client = "<ClientID/APPID>"

# -------------- Thumbprint for Graph App
$thumb = "<thumbprint>"

# ---- Folder to place CSV and HTML files (for email attachement and archive.)
$exportfolder = "C:\DailyReports\"

# ---- Filename for the archives
$exportfile = "Sign-Ins"

# Start Log Transcript
Start-Transcript -Path "C:\DailyReports\Logs\DailyLogs-$logdate.log"

Function Get-EntraSignInLogs {

    # Parameters. Full path (with backslashes) and filename (without file extension)
    param(
        [parameter(position=1)]
        $FileName,
        [parameter(position=2)]
        $Path,
        [parameter(position=3)]
        $state,
        [parameter(position=4)]
        $TLDname)

    # Set date/time to one day prior.
    $range = "{0:yyyy-MM-dd}" -f (get-date).AddDays(-1)

    # Set variable for output csv
    $global:csvpath = $Path+$FileName+"_"+$range+".csv"
    $global:htmlpath = $Path+$FileName+".html"
    $global:htmlpath2 = $Path+$FileName+"_NI.html"

# HTML Header information.

$Head = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

# HTML body information.
$body = @"
<p class="MsoNormal"><strong><span style="font-size: 12.0pt; line-height: 107%; color: #0070c0;"><span class="SpellE">Entra ID Daily Outside Access Summary:</span></strong></br>
<p class="MsoNormal"><strong><span style="font-size: 12.0pt; line-height: 107%; color: #000000;"><span class="SpellE">Below is the daily summary of non-%state% based login attempts for Entra ID accounts at %TLD%. %totals% records found in the last 24 hours. %totals2% non-interactive records found.</span></strong></p>
<p style="font-weight: 400;"><span style="color: #999999;">Full Reports included in attachment.</span></p>
"@

# HTML template for Table Headers
$bulletin = @"
<p class="MsoNormal"><strong><span style="font-size: 12.0pt; line-height: 107%; color: #0070c0;"><span class="SpellE">%text%</span></strong></br>
"@

    # Get Sign-in logs for the previous day.
    $archive = Get-MgAuditLogSignIn -Filter "createdDateTime gt $range"
    
    # (Using Beta Cmdlets) Graph reports contain a different timestamp. Adjustments are made for the time to ensure accurate local time window.
    $nointeract = (Get-MgBetaAuditLogSignIn -Filter "CreatedDateTime lt $([datetime]::UtcNow.Addhours(-8).ToString("s"))Z AND CreatedDateTime gt $([datetime]::UtcNow.Addhours(-32).ToString("s"))Z AND (signInEventTypes/any(t: t eq 'noninteractiveUser'))")
    
    # Filter out logs for the state specified in $state
    $result = $archive | Where-Object {$_.Location.State -ne $state}
    $nointeract = $nointeract | Where-Object {$_.Location.State -ne $state}
    
    # Check remaining results against ipinfo.io to ensure any false positives are cleaned out.
    # Takes all the non-state results and re-verifies the IPs against an internet database. If new results dont match original results, State/City are updated with new results.
    # Without an account, ipinfo.io will allow 1000 queries a day from a single IP. (Keep this in mind with larger datasets.)
    $nointeract | Foreach-Object {
        $checkIP = $_.Ipaddress
        $altIP = (irm ipinfo.io/$checkIP)
        IF ($_.Location.State -ne $altIP.region) {
            $_.Location.State = $altIP.region
            $_.Location.City = $altIP.City}
        }

    $result | Foreach-Object {
        $checkIP = $_.Ipaddress
        $altIP = (irm ipinfo.io/$checkIP)
        IF ($_.Location.State -ne $altIP.region) {
            $_.Location.State = $altIP.region
            $_.Location.City = $altIP.City}
        }

    # Get count of records found.
    $total1 = ($result | Measure-Object | Select Count)
    $total2 = ($nointeract | Measure-Object | Select Count)

    # Replace %total% string in $body html with the $total count value.
    IF ($total1.Count -eq 0) {$reportnumber = "No"} ELSE {$reportnumber = $total1.Count}
    IF ($total2.Count -eq 0) {$reportnumber2 = "No"} ELSE {$reportnumber2 = $total2.Count}

    # Replaces the string %totals% in body HTML with the value of the report count.
    $body = ($body | ForEach-Object {
        $_ -replace '%totals%',$reportnumber
    })

    # Replaces the string %totals2% in body HTML with the value of the report count.
    $body = ($body | ForEach-Object {
        $_ -replace '%totals2%',$reportnumber2
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

    # Add lines to this as you discover additional common errors.
    switch($result){
        {$_.status.errorcode -eq "50053"}{$_.Status.Failurereason = "Too many Logon attempts"}
        {$_.status.errorcode -eq "50126"}{$_.status.failurereason = "Invalid credentials"}
        {$_.status.errorcode -eq "50072"}{$_.status.failurereason = "you must enroll in multi-factor.."}
        {$_.status.errorcode -eq "53003"}{$_.status.failurereason = "Blocked by CA Policies"}
        {$_.status.errorcode -eq "50074"}{$_.status.failurereason = "MFA step incomplete"}
        {$_.status.errorcode -eq "50140"}{$_.status.failurereason = "-RememberMe-' Interrupted"}
        {$_.status.errorcode -eq "50011"}{$_.status.failurereason = "Sign-In URL Mismatch"}
        {$_.status.errorcode -eq "0"}{$_.status.failurereason = "Successful"}
    }
    # Replace FailureReason with more sensible and short explanatations. Fits the table in the email better.
    switch($nointeract){
        {$_.status.errorcode -eq "50078"}{$_.Status.Failurereason = "MFA Expired"}
        {$_.status.errorcode -eq "50076"}{$_.status.failurereason = "MFA Re-Required"}
        {$_.status.errorcode -eq "50079"}{$_.status.failurereason = "MFA Re-Required"}
        {$_.status.errorcode -eq "500133"}{$_.status.failurereason = "Token Expired!!"}
        {$_.status.errorcode -eq "500011"}{$_.status.failurereason = "Application Missing"}
        {$_.status.errorcode -eq "0"}{$_.status.failurereason = "Successful"}
    }

    # ----- Not Compelte. Any UserDisplayName that appears as an ObjectID to be converted to their displayname instead.
    # $result | ForEach-Object {IF ([string]($_.UserDisplayName).Contains("-")) {Write-Host $_.UserDisplayName.DisplayName = ((Get-AzureADUser -ObjectId $_UserDisplayName).DisplayName)}}

    # Fix date/time format.
    $result | ForEach-Object {$_.CreatedDateTime = (Get-Date($_.CreatedDateTime) -Format g)}
    $archive | ForEach-Object {$_.CreatedDateTime = (Get-Date($_.CreatedDateTime) -Format g)}
    
    # Fix Date/Time for Non-Interactive Logins. Adjusted for clock differences (PST in this case.)
    $nointeract | ForEach-Object {$_.CreatedDateTime = (Get-Date($_.CreatedDateTime).AddHours(-7) -Format g)}
        
    # Output CSV report, raw data.
    $archive | Select userPrincipalName, CreatedDateTime, SignInAuditLogObject, Location, IpAddress, Status, UserDisplayName, AppDisplayName | ConvertTo-CSV | Out-File $global:csvpath
    
    sleep 1
    
    # output HTML reports the specified Path. Report is parsed and formatted first.
    $archive | select userPrincipalName, CreatedDateTime, SignInAuditLogObject, Location, IpAddress, Status, UserDisplayName, AppDisplayName | ConvertTo-Html -Property @{Label="User"; Expression={$_.UserDisplayName}}, @{Label="TimeStamp"; Expression={$_.CreatedDateTime}}, @{Label="Country"; Expression={$_.Location.CountryOrRegion}}, @{Label="State"; Expression={$_.Location.State}}, @{Label="City"; Expression={$_.Location.City}}, @{Label="IPAddress"; Expression={$_.IpAddress}}, @{Label="Application"; Expression={$_.AppDisplayName}}, @{Label="Error Code"; Expression={$_.Status.ErrorCode}}, @{Label="Error"; Expression={$_.Status.FailureReason}} -Head $header | Out-File $global:htmlpath

    # output HTML reports (Non-interactive) to the specified Path. Report is parsed and formatted first, Includes Event ID.
    $nointeract | select UserDisplayName, CreatedDateTime, Location, IpAddress, Status, AppDisplayName, Id | ConvertTo-Html -Property @{Label="User"; Expression={$_.UserDisplayName}}, @{Label="TimeStamp"; Expression={$_.CreatedDateTime}}, @{Label="Country"; Expression={$_.Location.CountryOrRegion}}, @{Label="City"; Expression={$_.Location.City}}, @{Label="IPAddress"; Expression={$_.IpAddress}}, @{Label="Application"; Expression={$_.AppDisplayName}}, @{Label="Error Code"; Expression={$_.Status.ErrorCode}}, @{Label="Error"; Expression={$_.Status.FailureReason}}, @{Label="Event ID"; Expression={$_.Id}}-Head $header | Out-File $global:htmlpath2
    
    Sleep 1

    # Format Final Results into tables, convert to HTML for appending to email.
    IF ($result -eq $null) {
    $Interactive = $bulletin -replace '%text%','No Interactive Sign In Attempts Found'}
    ELSE {
    $act = $bulletin -replace '%text%','Interactive Logins'
    $interactive = ($result | Select @{Label="User"; Expression={$_.UserDisplayName}}, @{Label="TimeStamp"; Expression={$_.CreatedDateTime}}, @{Label="Country"; Expression={$_.Location.CountryOrRegion}}, @{Label="City"; Expression={$_.Location.City}}, @{Label="IPAddress"; Expression={$_.IpAddress}}, @{Label="Application"; Expression={$_.AppDisplayName}}, @{Label="Error Code"; Expression={$_.Status.ErrorCode}}, @{Label="Error"; Expression={$_.Status.FailureReason}} | ConvertTo-Html -Fragment -PreContent $act | Out-String)}

    # Format results for non-interactive sign-ins
    IF ($nointeract -eq $null) {
    $noninteractive = $bulletin -replace '%text%'.'No non-interactive logins found outside $state.'}
    ELSE {
    $nonact = $bulletin -replace '%text%','Non-Interactive Logins'
    $noninteractive = ($nointeract | Select @{Label="User"; Expression={$_.UserDisplayName}}, @{Label="TimeStamp"; Expression={$_.CreatedDateTime}}, @{Label="Country"; Expression={$_.Location.CountryOrRegion}}, @{Label="City"; Expression={$_.Location.City}}, @{Label="IPAddress"; Expression={$_.IpAddress}}, @{Label="Application"; Expression={$_.AppDisplayName}}, @{Label="Error Code"; Expression={$_.Status.ErrorCode}}, @{Label="Error"; Expression={$_.Status.FailureReason}} | ConvertTo-Html -Fragment -PreContent $nonact | Out-String)}
    
    # Output Final HTML report as output for the function. Output captured to $html (below)
    Write-Output (ConvertTo-HTML -head $head -Body $body -PostContent $interactive,$noninteractive)
}

# Import the Proper Module
Import-Module Microsoft.Graph.Reports
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users.Actions
Import-Module Microsoft.Graph.Mail
Import-Module Microsoft.Graph.Beta.Reports

Sleep 2

# Connect to Office 365 Azure Active Directory - Error Handling try/catch
try {
    Connect-MgGraph -TenantId $tenant -ClientId  $client -CertificateThumbprint $thumb
    }
catch {
    # Create error message for email, set flag for success/failure.
    $errormessage = "UNABLE TO CONNECT TO AZURE."
    [bool] $global:success = $false
}
finally {
    IF ($global:success -ne $false) {[bool] $global:success = $true}
    }

Sleep 1

# Full Reports for Email HTML, if error during connection, HTML is formatted with a simple error message for the recipient.

IF ($global:success -eq $true) {
    $html = Get-EntraSignInLogs -FileName $exportfile -Path $exportfolder -State $OperatingState -TLDname $Domain}
ELSE {
    $html = ($errormessage | ConvertTo-Html -Property @{ l='ERROR:'; e={ $_ }})
}

Sleep 2

# Create Archive file of results if connection was successful.
IF ($global:success -eq $true) {
    # Create ZIP of full reports from HTML and CSV files created
    $yesterday = ((Get-Date).AddDays(-1)).ToString("yyyy-MM-dd")
    $archivefile = $exportfolder+"Archive\AzureSignIns_"+$yesterday+".zip"
    $compress = @{
        Path = $global:csvpath, $global:htmlpath, $global:htmlpath2
        CompressionLevel = "Fastest"
        DestinationPath = $archivefile
        }
    Compress-Archive @compress
}

# --- Prepare to send email.

# If Attachments are over ~3MB: https://docs.microsoft.com/en-us/graph/outlook-large-attachments?tabs=http
# $AttachmentPath = $archivefile

$mailsubject = "Entra ID: Suspicious Sign-Ins for "+(Get-Date -Format MM/dd/yyyy)

# Establish properties for the message that will be sent.
$MessageDetails = @{
    Message = @{
        Subject = $mailsubject
        Body = @{
            ContentType = "html"
            Content = $html | Out-String
        }
		ToRecipients = @(
			@{
				EmailAddress = @{
					Address = $SendMailTo
				}
            }
        )
        Attachments = @(
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                "name" = ($archivefile -split '\\')[-1]
                "contentBytes" = [convert]::ToBase64String((Get-Content $archivefile -Encoding byte))
            }
        )
    }         
	SaveToSentItems = "false"
} 

# Send the message
Send-MgUserMail -UserId $SendMailFrom -BodyParameter $MessageDetails

Sleep 1

# Disconnect from Graph when complete.
Disconnect-MgGraph

# Sometimes folders take a moment or two to release open handles
Sleep 10

Remove-Item -Path $exportfolder"*.*"

Stop-Transcript