function Set-DataFile
{

    $createxml = {}

    $createxml = @{
        "Box1" = "Folder_1"
        "Box2" = "Folder_2"
        "Box3" = "Folder_3"
        "Box4" = "Folder_4"
        "Box5" = "Folder_5"
        "Box6" = "Folder_6"
        "Box7" = "Folder_7"
        "Box8" = "Folder_8"
        "Box9" = "Folder_9"
        "Box10" = "Folder_10"
        "Box11" = "Folder_11"
        "Box12" = "Folder_12"
        "Box13" = "Folder_13"
        "Box1Path" = "Please_Configure"
        "Box2Path" = "Please_Configure"
        "Box3Path" = "Please_Configure"
        "Box4Path" = "Please_Configure"
        "Box5Path" = "Please_Configure"
        "Box6Path" = "Please_Configure"
        "Box7Path" = "Please_Configure"
        "Box8Path" = "Please_Configure"
        "Box9Path" = "Please_Configure"
        "Box10Path" = "Please_Configure"
        "Box11Path" = "Please_Configure"
        "Box12Path" = "Please_Configure"
        "Box13Path" = "Please_Configure"
        "Verify" = "Disabled."
        }
   
   $createxml | Export-Clixml -Depth 5 ($global:GUISettings+"\Backup_Settings.xml")

}

function Start-BackupToolJob
{
    param(
        [parameter(position=1)]
        $Name,
        [parameter(position=2)]
        $Source )

    # Set Drive Letter from dropdown box
    $driv = $global:DropDownBox.SelectedItem.ToString()
    
    # Set log location/name
    $log = ($driv+"\Log_"+$name+".log")

    # Set destination folder with date stamp
    $dest = ($driv+"\"+$name+"_"+$(get-date -f yyyy-MM-dd))

    # If destination folder is not present, create it.
    If (!(Test-Path $dest)) {
        md "$dest" }
    
    # Writes output to the console box

    Append-ColoredLine $global:OutputBox Black ("Backing up "+$name+" to $driv") $global:boldtext
    Append-ColoredLine $global:OutputBox Gray "   robocopy $source $dest /E /ZB /DCOPY:T /COPYALL /R:1 /W:10 /V" $global:commandcode
    Append-ColoredLine $global:OutputBox Black "   Please wait..."

    #run backup process
    robocopy $Source $dest /E /ZB /DCOPY:T /COPYALL /R:1 /W:10 /V

}


# Function for generating Settings Form

function Set-NewVariables
{
    #Arrays for Text Boxes, Labels, Global Variables
    
    # Array for all text boxes containing desctiptions
    $DescrBox = (@($textbox1a.Text,$textbox2a.Text,$textbox3a.Text,$textbox4a.Text,$textbox5a.Text,$textbox6a.Text,$textbox7a.Text,$textbox8a.Text,$textbox9a.Text,$textbox10a.Text,$textbox11a.Text,$textbox12a.Text,$textbox13a.Text))
    
    # Array for all text boxes containing paths
    $PathBox = (@($textbox1b.Text,$textbox2b.Text,$textbox3b.Text,$textbox4b.Text,$textbox5b.Text,$textbox6b.Text,$textbox7b.Text,$textbox8b.Text,$textbox9b.Text,$textbox10b.Text,$textbox11b.Text,$textbox12b.Text,$textbox13b.Text))
    
    # Array for all descrition label box tags
    $BoxNum = @("Lbl1","Lbl2","Lbl3","Lbl4","Lbl5","Lbl6","Lbl7","Lbl8","Lbl9","Lbl10","Lbl11","Lbl12","Lbl13")
    
    # Array for all global variable destination paths.
    $DestBox = @("Box1Path","Box2Path","Box3Path","Box4Path","Box5Path","Box6Path","Box7Path","Box8Path","Box9Path","Box10Path","Box11Path","Box12Path","Box13Path")
    
    # Array for all global variable description names.
    $SysBox = @("Box1","Box2","Box3","Box4","Box5","Box6","Box7","Box8","Box9","Box10","Box11","Box12","Box13")
    $pos = 0
    
    foreach ($description in $DescrBox) {
        $global:SysSetting.($SysBox[$pos]) = $description
        $global:SysSetting.($DestBox[$pos]) = $PathBox[$pos]
        $UI_BoxLabel.($BoxNum[$pos]).Text = $description
        
        $pos = $pos + 1 }

    If ($VerifyCheck.Checked -eq $true) {
            $global:SysSetting.Verify = "Enabled."
            $VerifiStatus.text = "Enabled."
            $global:VerifiStatus.font = 'Microsoft New Tai Lue,10,style=bold'
    } ELSE {
            $VerifiStatus.text = "Disabled."
            $global:SysSetting.Verify = "Disabled."
            $VerifiStatus.font = 'Microsoft New Tai Lue,10'
    }


}

function Select-FolderPath
{
    param(
        [parameter(position=1)]
        $Position )
    
    $folderselection = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    CheckFileExists = 0
    ValidateNames = 0
    FileName = "Choose Folder"
    }
    $folderselection.ShowDialog()
    
    switch ( $Position ) {
        1 {$textbox1b.text = (Split-Path -Parent $folderselection.FileName)}
        2 {$textbox2b.text = (Split-Path -Parent $folderselection.FileName)}
        3 {$textbox3b.text = (Split-Path -Parent $folderselection.FileName)}
        4 {$textbox4b.text = (Split-Path -Parent $folderselection.FileName)}
        5 {$textbox5b.text = (Split-Path -Parent $folderselection.FileName)}
        6 {$textbox6b.text = (Split-Path -Parent $folderselection.FileName)}
        7 {$textbox7b.text = (Split-Path -Parent $folderselection.FileName)}
        8 {$textbox8b.text = (Split-Path -Parent $folderselection.FileName)}
        9 {$textbox9b.text = (Split-Path -Parent $folderselection.FileName)}
        10 {$textbox10b.text = (Split-Path -Parent $folderselection.FileName)}
        11 {$textbox11b.text = (Split-Path -Parent $folderselection.FileName)}
        12 {$textbox12b.text = (Split-Path -Parent $folderselection.FileName)}
        13 {$textbox13b.text = (Split-Path -Parent $folderselection.FileName)}
        }
}

function Open-BUScriptSettings
{

    # Collects and sets new variables for the settings window (when used.)
    # Define Child Form Size & Colors
    $SettingsTool                      = New-Object system.Windows.Forms.Form
    $SettingsTool.ClientSize           = '700,420'
    $SettingsTool.text                 = ("Backup Utility Settings")
    $SettingsTool.BackColor            = "#d1d7e4"
    $SettingsTool.TopMost              = $false

    $Decription = New-Object System.Windows.Forms.Label -Property @{
        text           = "Name"
        AutoSize       = $true
        location       = New-Object System.Drawing.Point(40,10)
        Font           = $global:GUI_Font
        BackColor      = "Transparent"
        ForeColor      = $global:GUI_FontColor
        }

    $PathLabel = New-Object System.Windows.Forms.Label -Property @{
        text           = "Source Folder Path"
        AutoSize       = $true
        location       = New-Object System.Drawing.Point(200,10)
        Font           = $global:GUI_Font
        BackColor      = "Transparent"
        ForeColor      = $global:GUI_FontColor
        }

    $ApplySettings = New-Object system.Windows.Forms.Button -Property @{
        BackColor      = "#c9c9c9"
        text           = "Apply Only"
        width          = 110
        height         = 25
        location       = New-Object System.Drawing.Point(330,367)
        Font           = 'Microsoft New Tai Lue,10'
        DialogResult = [System.Windows.Forms.DialogResult]::OK
        }

    $ApplySave = New-Object system.Windows.Forms.Button -Property @{
        BackColor      = "#c9c9c9"
        text           = "Save Changes"
        width          = 110
        height         = 25
        location       = New-Object System.Drawing.Point(445,367)
        Font           = 'Microsoft New Tai Lue,10'
        DialogResult = [System.Windows.Forms.DialogResult]::OK
        }

    $VerifyLabel = New-Object System.Windows.Forms.Label -Property @{
        text           = "Enable File Verification"
        AutoSize       = $true
        location       = New-Object System.Drawing.Point(62,369)
        Font           = 'Microsoft New Tai Lue,10'
        BackColor      = "Transparent"
        ForeColor      = '#000000'
        }

    $VerifyCheck                     = new-object System.Windows.Forms.checkbox
    $VerifyCheck.Location            = new-object System.Drawing.Size(40,365)
    $VerifyCheck.Size                = new-object System.Drawing.Size(25,25)
    # IF ($global:VerifiStatus.text -eq "Enabled.") {
    IF ($global:SysSetting.Verify -eq "Enabled.") {
        $VerifyCheck.Checked = $true
        }


    # -----------------------------------------------
    # Procedurally Generate Text Descriptions, Path Fields and path selection buttons.

    $objectarray = 'textbox1','textbox2','textbox3','textbox4','textbox5','textbox6','textbox7','textbox8','textbox9','textbox10','textbox11','textbox12','textbox13'
    $vert_loc = 35
    $seq_number = 1

    foreach ($object in $objectarray) {
    
        $boxnumber = ("Box" + $seq_number)
        $boxpath = ("Box" + $seq_number + "Path")

        $tboxA = New-Object System.Windows.Forms.TextBox
        $tboxA.Location = New-Object System.Drawing.Point(40,$vert_loc)
        $tboxA.Text = $global:SysSetting.$boxnumber

        $tboxB = New-Object System.Windows.Forms.TextBox
        $tboxB.Location = New-Object System.Drawing.Point(200,$vert_loc)
        $tboxB.Width = 350
        $tboxB.ReadOnly = $true
        $tboxB.Text = $global:SysSetting.$boxpath

        $smallbutton = New-Object System.Windows.Forms.Button -Property @{
            BackColor      = "#c9c9c9"
            text           = "..."
            width          = 40
            height         = 22
            Location       = New-Object System.Drawing.Point(555,($vert_loc -1))
            Font           = 'Microsoft New Tai Lue,10'
            DialogResult = [System.Windows.Forms.DialogResult]::None
            }

        New-Variable -Name "$($object + "a")" -Value $tboxA -Force
        New-Variable -Name "$($object + "b")" -Value $tboxB -Force
        New-Variable -Name "$("choosepath" + $seq_number)" -Value $smallbutton
    
        $vert_loc = ($vert_loc + 25)
        $seq_number = ($seq_number + 1)

    }

    # Applies fields to the Form.
    $SettingsTool.Controls.AddRange(@($Decription,$PathLabel,$textbox1a,$textbox1b,$textbox2a,$textbox2b,$textbox3a,$textbox3b,$textbox4a,$textbox4b,$textbox5a,$textbox5b,$textbox6a,$textbox6b,$textbox7a,$textbox7b,$textbox8a,$textbox8b,$textbox9a,$textbox9b,$textbox10a,$textbox10b,$textbox11a,$textbox11b,$textbox12a,$textbox12b,$textbox13a,$textbox13b,$VerifyCheck,$VerifyLabel,$ApplySettings,$ApplySave))
    $SettingsTool.Controls.AddRange(@($choosepath1,$choosepath2,$choosepath3,$choosepath4,$choosepath5,$choosepath6,$choosepath7,$choosepath8,$choosepath9,$choosepath10,$choosepath11,$choosepath12,$choosepath13))

    # Applies Settings to current session. Does not Save them for future use.
    $ApplySettings.Add_MouseClick({
        Set-NewVariables
    })

    # Applies Settings to current session and saves changes to XML.
    $ApplySave.Add_MouseClick({
        Set-NewVariables
        
        #needs additional code
        $msgBoxInput =  [System.Windows.MessageBox]::Show('Confirm to Save','Save Changes Permanently?','YesNo','Error')

        $global:SysSetting | Export-CliXml $GUISettings
    
    })

# Folder Selection Buttons

    $choosepath1.Add_MouseClick({
        Select-FolderPath -Position 1
        })

    $choosepath2.Add_MouseClick({
        Select-FolderPath -Position 2
        })

    $choosepath3.Add_MouseClick({
        Select-FolderPath -Position 3
        })

    $choosepath4.Add_MouseClick({
        Select-FolderPath -Position 4
        })

    $choosepath5.Add_MouseClick({
        Select-FolderPath -Position 5
        })

    $choosepath6.Add_MouseClick({
        Select-FolderPath -Position 6
        })

    $choosepath7.Add_MouseClick({
        Select-FolderPath -Position 7
        })

    $choosepath8.Add_MouseClick({
        Select-FolderPath -Position 8
        })

    $choosepath9.Add_MouseClick({
        Select-FolderPath -Position 9
        })

    $choosepath10.Add_MouseClick({
        Select-FolderPath -Position 10
        })

    $choosepath11.Add_MouseClick({
        Select-FolderPath -Position 11
        })

    $choosepath12.Add_MouseClick({
        Select-FolderPath -Position 12
        })

    $choosepath13.Add_MouseClick({
        Select-FolderPath -Position 13
        })


    $SettingsTool.ShowDialog()

}

# ------------- End of functins, start of script ---------------

# Auto Elevates to Admin.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Sets up window and buttons.

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

[System.Windows.Forms.Application]::EnableVisualStyles()

# Define file paths for module and settings.
$global:GUISettings = Split-Path $script:MyInvocation.MyCommand.Path
## $GUIFunctions = $global:GUISettings + "\Backup_Functions_v2.psm1"

#Import Functions
## Import-Module -Name $GUIFunctions

#Check for Data File, if missing create a new one.
IF (!(Test-Path ($global:GUISettings+"\Backup_Settings.xml"))) {
    Set-DataFile }

$global:GUISettings += "\Backup_Settings.xml"

# Load Settings
$global:SysSetting = Import-CliXml $GUISettings

# Define standard font & font color for interfaces
$global:GUI_FontColor = '#000000'
$global:GUI_Font = 'Microsoft New Tai Lue,11,style=Bold'
# $global:GUI_FontColor = 'Calibri,11,style=Bold'

# -----------------------------------
# Adding Colored Lines to a Rich Textbox
$global:interactive = "Yes"
$global:commandcode = 'OCR A Extended,8'
$global:boldtext = 'Microsoft New Tai Lue,10,style=Bold'

function Append-ColoredLine {
    param( 
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Windows.Forms.RichTextBox]$box,
        [Parameter(Mandatory = $true, Position = 1)]
        [System.Drawing.Color]$color,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$text,
        [Parameter(Position = 4)]
        [string]$fonts
    )
    
    IF (!$fonts) {$fonts = 'Microsoft New Tai Lue,10'}
    
    IF ($global:interactive = "Yes") {
        $box.SelectionStart = $box.TextLength
        $box.SelectionLength = 0
        $box.SelectionFont = $fonts
        $box.SelectionColor = $color
        $box.AppendText($text)
        $box.AppendText([Environment]::NewLine)
        $box.ScrollToCaret()
        }
# Example: Append-ColoredLine $global:OutputBox Black "Select a drive letter and select shares to backup." 'Microsoft New Tai Lue,10,style=Bold'

}
# -----------------------------------

# Specify Properties for Rich Text Box--------------
$global:OutputBox = New-Object System.Windows.Forms.RichTextBox -Property @{
    Location      = New-Object System.Drawing.Size(225,30)
    Size          = New-Object System.Drawing.Size(550,315) 
    ReadOnly      = $true
    Font          = 'Microsoft Sans Serif,9,style=Bold'
    BackColor     = "#a7bac1"
    MultiLine     = $True 
    ScrollBars    = "Vertical"
    }

# ----------------------------------------------

# Define size of main interface window
$SetupTool                      = New-Object system.Windows.Forms.Form
$SetupTool.ClientSize           = '800,420'
$SetupTool.text                 = ("WENT Cold Backup Control")
$SetupTool.BackColor            = "#d1d7e4"
$SetupTool.TopMost              = $false

# Build Fields in GUI

$UI_Select = @{}
$UI_BoxLabel = @{}
$Boxes = @("Box1","Box2","Box3","Box4","Box5","Box6","Box7","Box8","Box9","Box10","Box11","Box12","Box13")
$pos = 1
$v_pos = 30
$v_pos2 = 32

foreach ($box in $boxes) {
    
    $label = ("Lbl"+$pos)

    $UI_Select.$box                        = new-object System.Windows.Forms.checkbox
    $UI_Select.$box.Location               = new-object System.Drawing.Size(30,$v_pos)
    $UI_Select.$box.Size                   = new-object System.Drawing.Size(25,25)
    $UI_Select.$box.Checked = $false

    $UI_BoxLabel.$label = New-Object System.Windows.Forms.Label 
    $UI_BoxLabel.$label.text = $global:SysSetting.$box
    $UI_BoxLabel.$label.AutoSize = $true
    $UI_BoxLabel.$label.Font = $global:GUI_Font
    $UI_BoxLabel.$label.Location = New-Object System.Drawing.Point(55,$v_pos2)
    $UI_BoxLabel.$label.ForeColor = $global:GUI_FontColor
    $UI_BoxLabel.$label.BackColor = "Transparent"

    $pos = $pos + 1
    $v_pos = $v_pos + 23
    $v_pos2 = $v_pos2 + 23
    }

$Drop_boxLabel = New-Object System.Windows.Forms.Label -Property @{
    text           = "Destination Drive"
    AutoSize       = $true
    location       = New-Object System.Drawing.Point(390,370)
    Font           = $global:GUI_Font
    ForeColor      = $global:GUI_FontColor
    BackColor      = "Transparent"
    }

# Dropdown box for drive selection
$global:DropDownBox = New-Object System.Windows.Forms.ComboBox -Property @{
    Location = New-Object System.Drawing.Size(525,367) 
    Size = New-Object System.Drawing.Size(40,25)
    Font = $global:GUI_Font 
    DropDownHeight = 200
    }
           
# Establish list of options in drop down menu
$global:drivelist=@("D:","E:","F:","G:","H:","I:","J:","K:","L:")
    
# Populate drop down menu
    foreach ($drive in $global:drivelist) {
                      $global:DropDownBox.Items.Add($drive)
                              } #end foreach

# Default Selection in dropdown box
$global:DropDownBox.SelectedIndex = 1

# ----------------------------------------------

$Selected                       = New-Object system.Windows.Forms.Button
$Selected.BackColor             = "#c9c9c9"
$Selected.text                  = "Backup Selected Shares"
$Selected.width                 = 180
$Selected.height                = 25
$Selected.location              = New-Object System.Drawing.Point(595,367)
$Selected.Font                  = $global:GUI_FontColor

$Verifi = New-Object System.Windows.Forms.Label -Property @{
    AutoSize       = $true
    text           = "File Verification is"
    location       = New-Object System.Drawing.Point(55,370)
    Font           = 'Microsoft New Tai Lue,10'
    BackColor      = "Transparent"
    ForeColor      = '#000000'
    }

#Default Setting for Verification Label. Can be changed in Settings child form. (Open-BUScriptSettings Function)
$global:VerifiStatus = New-Object System.Windows.Forms.Label -Property @{
    AutoSize       = $true
    location       = New-Object System.Drawing.Point(163,370)
    Font           = 'Microsoft New Tai Lue,10'
    BackColor      = "Transparent"
    ForeColor      = '#000000'
    }
$global:VerifiStatus.text = $global:SysSetting.Verify

If ($global:SysSetting.Verify -eq "Enabled.") {
   $global:VerifiStatus.font = 'Microsoft New Tai Lue,10,style=bold' }

$SetingsBtn = New-Object System.Windows.Forms.Label -Property @{
    text           = "Settings"
    AutoSize       = $true
    location       = New-Object System.Drawing.Point(735,400)
    Font           = 'Microsoft New Tai Lue,8'
    ForeColor      = $global:GUI_FontColor
    BackColor      = "Transparent"
    }

# Radio Buttons
$SetupTool.controls.AddRange(@($UI_Select.Box1,$UI_Select.Box2,$UI_Select.Box3,$UI_Select.Box4,$UI_Select.Box5,$UI_Select.Box6,$UI_Select.Box7,$UI_Select.Box8,$UI_Select.Box9,$UI_Select.Box10,$UI_Select.Box11,$UI_Select.Box12,$UI_Select.Box13,$Selected))
# Interface Buttons (Action Buttons)
$SetupTool.controls.AddRange(@($Selected,$SetingsBtn))
# Radio button labels
$SetupTool.controls.AddRange(@($UI_BoxLabel.Lbl1,$UI_BoxLabel.Lbl2,$UI_BoxLabel.Lbl3,$UI_BoxLabel.Lbl4,$UI_BoxLabel.Lbl5,$UI_BoxLabel.Lbl6,$UI_BoxLabel.Lbl7,$UI_BoxLabel.Lbl8,$UI_BoxLabel.Lbl9,$UI_BoxLabel.Lbl10,$UI_BoxLabel.Lbl11,$UI_BoxLabel.Lbl12,$UI_BoxLabel.Lbl13))
# Other Interface Elements
$SetupTool.controls.AddRange(@($global:OutputBox,$Drop_boxLabel,$global:DropDownBox,$Verifi,$global:VerifiStatus))
# Save this for later
# $SD_box.Add_CheckStateChanged({$SharedData.Enable = $SD_box.Checked})

IF ($global:SysSetting.Box1Path -eq "Please_Configure") {
    Append-ColoredLine $global:OutputBox Black "Folder Paths may still need to be configured." }
    ELSE {
        Append-ColoredLine $global:OutputBox Black "Select a drive letter and select shares to backup." }

$SetingsBtn.Add_MouseClick({
Open-BUScriptSettings
})

$Selected.Add_MouseClick({
    
    Write-Host " "
    
    IF (Test-Path $global:DropDownBox.SelectedItem.ToString()) {

    $msgBoxInput =  [System.Windows.MessageBox]::Show('Start Backup','Proceed with backup job?','YesNo','Error')
        switch  ($msgBoxInput) {
            'Yes' {
                $Boxes = @("Box1","Box2","Box3","Box4","Box5","Box6","Box7","Box8","Box9","Box10","Box11","Box12","Box13")
                $boxnumber = 1
                foreach ($box in $boxes) {
                    $path = ("Box"+$boxnumber+"Path")
                    IF (!($global:SysSetting.$path -eq "Please_Configure")) {

                        If ($UI_Select.$box.Checked -eq $true) {
                            Start-BackupToolJob -Name $global:SysSetting.$box -Source $global:SysSetting.$path
                            $UI_Select.$box.Checked = $False
                            $UI_Select.$box.Enabled = $False
                            }
                        ELSE {
                            $driv = $global:DropDownBox.SelectedItem.ToString()
                            Write-Host ($global:SysSetting.$box + " NOT Checked.") -ForegroundColor Red
                            Write-Host ("Data will not be written to "+$driv+"\"+$global:SysSetting.$box+"_"+$(get-date -f yyyy-MM-dd)) -ForegroundColor Red}

                    $boxnumber = $boxnumber + 1
                    
                    }
                    
                    }
                #end of argument for 'Yes' result
                }
            'No' {
                Append-ColoredLine $global:OutputBox Black "Operation Cancelled."
                }
        
        #end of argument for swtich        
        }
    
    #end of argument for test-path
    } ELSE{
    $errorbutton =  [System.Windows.MessageBox]::Show('Selected Drive Letter Not Found','Error','OK','Error')
    }

    # ? $SD_box.Add_CheckStateChanged
    
})

[void]$SetupTool.ShowDialog()