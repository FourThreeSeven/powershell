Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

Import-Module ActiveDirectory

# Gets list of AD computers and servers, sorts them alphabetically by name
$computers = (Get-ADComputer -Filter * | Sort-Object -Property @{Expression = "name"; Ascending = $true} | select name)
$computers2 = (Get-ADComputer -Filter * -Properties description | Where-Object {$null -ne $_.description} | Sort-Object -Property @{Expression = "Description"; Ascending = $true} | select name, description)

# Get-ADComputer -Filter * -Properties description | Where-Object {$null -ne $_.description} | Sort-Object -Property @{Expression = "Description"; Ascending = $true} | select name, description

$CenterScreen = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Define Dialog Box Size
$SetupTool                      = New-Object system.Windows.Forms.Form
$SetupTool.ClientSize           = '300,400'
$SetupTool.text                 = ("WENT Remote Support Tool")
#$SetupTool.BackColor            = "#d1d7e4"
$SetupTool.TopMost              = $false
$SetupTool.StartPosition         = $CenterScreen

# Group Box for forms.
$ComputerSelectionBox = New-Object System.Windows.Forms.GroupBox -Property @{
    Location = '27,24'
    BackColor = "Transparent"
    size = '250,180'
    text = "Select Computer for Support"
    ForeColor = "#23207a"
    Font = 'Cascadia Mono,10,style=bold'
    }

# ---------------------------------------------------------
# ----------- Define Contents of Box-----------------------

# Dropdown List for computer descriptions
$DropDownBox2 = New-Object System.Windows.Forms.ComboBox -Property @{
    Location = New-Object System.Drawing.Size(20,62)
    Size = New-Object System.Drawing.Size(210,25)
    Font = 'Cascadia Mono,10,style=bold'
    DropDownHeight = 200
    }

# Dropdown List for Computer Names
$DropDownBox = New-Object System.Windows.Forms.ComboBox -Property @{
    Location = New-Object System.Drawing.Size(20,123)
    Size = New-Object System.Drawing.Size(210,25)
    Font = 'Cascadia Mono,10,style=bold'
    Enabled = $false
    DropDownHeight = 200
    }
           
# Define Array for dropdown list
$pclist=$computers.name
$pclist2=$computers2.Description
    
# Populate drop down menu for Computer Names
    foreach ($pc in $pclist) {
        $DropDownBox.Items.Add($pc) | Out-Null
    }

# Populate drop down menu for computer descriptions
    foreach ($pc in $pclist2) {
        $DropDownBox2.Items.Add($pc) | Out-Null
    }

# Default Choice for dropdown list
$DropDownBox.SelectedIndex = 0
$DropDownBox2.SelectedIndex = 0

$MachineDes = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = '30,30'
    size = '200,40'
    Checked = $true
    Text = "Computer Description"
    }

$MachineName = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = '30,100'
    size = '130,20'
    Checked = $false
    Text = "Computer Name"
    }

# ---------------------------------------------------------
# ---------------------------------------------------------

# Support Button
$StartSupport                       = New-Object system.Windows.Forms.Button
$StartSupport.BackColor             = "#c9c9c9"
$StartSupport.text                  = "Start Session(s)"
$StartSupport.width                 = 180
$StartSupport.height                = 25
$StartSupport.location              = New-Object System.Drawing.Point(65,350)
$StartSupport.Font                  = 'Cascadia Mono,10,style=bold'

# Generate Label for the checkboxes

# Default Share Checkbox Label
$Decription = New-Object System.Windows.Forms.Label -Property @{
        text           = "Open Default Share"
        AutoSize       = $true
        location       = New-Object System.Drawing.Point(73,285)
        Font           = 'Cascadia Mono,10,style=bold'
        BackColor      = "Transparent"
        }

# Open PS Session Checkbox Label
$Decription2 = New-Object System.Windows.Forms.Label -Property @{
        text           = "Start Powershell Session"
        AutoSize       = $true
        location       = New-Object System.Drawing.Point(73,305)
        Font           = 'Cascadia Mono,10,style=bold'
        BackColor      = "Transparent"
        }

# Remote Assistance Checkbox Label
$Decription3 = New-Object System.Windows.Forms.Label -Property @{
        text           = "Remote Assistance"
        AutoSize       = $true
        location       = New-Object System.Drawing.Point(73,230)
        Font           = 'Cascadia Mono,10,style=bold'
        BackColor      = "Transparent"
        }

# Remote Desktop Checkbox Label
$Decription4 = New-Object System.Windows.Forms.Label -Property @{
        text           = "Remote Desktop"
        AutoSize       = $true
        location       = New-Object System.Drawing.Point(73,250)
        Font           = 'Cascadia Mono,10,style=bold'
        BackColor      = "Transparent"
        }

# Default Share Check Box
$CheckBox1 = new-object System.Windows.Forms.checkbox
$CheckBox1.Location = new-object System.Drawing.Size(53,283)
$CheckBox1.Size  = new-object System.Drawing.Size(20,20)
$CheckBox1.Checked = $false

# PSSession Checkbox
$CheckBox2 = new-object System.Windows.Forms.checkbox
$CheckBox2.Location = new-object System.Drawing.Size(53,303)
$CheckBox2.Size  = new-object System.Drawing.Size(20,20)
$CheckBox2.Checked = $false

# Remote Assistance Checkbox
$CheckBox3 = new-object System.Windows.Forms.checkbox
$CheckBox3.Location = new-object System.Drawing.Size(53,228)
$CheckBox3.Size  = new-object System.Drawing.Size(20,20)
$CheckBox3.Checked = $true

# Remote Desktop Checkbox
$CheckBox4 = new-object System.Windows.Forms.checkbox
$CheckBox4.Location = new-object System.Drawing.Size(53,248)
$CheckBox4.Size  = new-object System.Drawing.Size(20,20)
$CheckBox4.Checked = $false

# Define contents of group box.
$ComputerSelectionBox.Controls.AddRange(@($DropDownBox,$DropDownBox2,$MachineName,$MachineDes))

# Apply dropdown list box and buttons to the Dialog box
$SetupTool.controls.AddRange(@($ComputerSelectionBox,$StartSupport,$CheckBox1,$CheckBox2,$CheckBox3,$CheckBox4,$Decription,$Decription2,$Decription3,$Decription4))

# Change selected computer description based on computer name selected.
$DropDownBox.add_SelectedIndexChanged({
        $name = $DropDownBox.Text
        $description = (Get-ADComputer -Identity $name -Properties Description).Description
        $DropDownBox2.text = $description
})

# Change selected computer name based on description selected.
$DropDownBox2.add_SelectedIndexChanged({
        $description = $DropDownBox2.Text
        $name = (Get-ADComputer -filter {Description -eq $description} -Properties Name).Name
        $DropDownBox.text = $name
})

$MachineDes.Add_MouseClick({
    $MachineDes.Checked = $true
    $DropDownBox2.Enabled = $true
    $MachineName.Checked = $false
    $DropDownBox.Enabled = $false
    
})

$MachineName.Add_MouseClick({
    $MachineDes.Checked = $false
    $DropDownBox2.Enabled = $false
    $MachineName.Checked = $true
    $DropDownBox.Enabled = $true
})


$Decription.Add_MouseClick({
    IF ($CheckBox1.Checked -eq $true) {
        $CheckBox1.Checked = $false}
        ELSE {
        $CheckBox1.Checked = $true}
})

$Decription2.Add_MouseClick({
    IF ($CheckBox2.Checked -eq $true) {
        $CheckBox2.Checked = $false}
        ELSE {
        $CheckBox2.Checked = $true}
})

$Checkbox3.Add_MouseClick({
    IF ($CheckBox3.Checked -eq $true) {
        $CheckBox4.Checked = $false}
})

$Checkbox4.Add_MouseClick({
    IF ($CheckBox4.Checked -eq $true) {
        $CheckBox3.Checked = $false}
})

$Decription3.Add_MouseClick({
    $CheckBox3.Checked = $true
    $CheckBox4.Checked = $false
})

$Decription4.Add_MouseClick({
    $CheckBox4.Checked = $true
    $CheckBox3.Checked = $false
})

# define actions for the button
$StartSupport.Add_MouseClick({

    # If machine name is checked, set to the target variable as the machine name (from the name in the dropdown box)
    IF ($MachineName.Checked) {
        $target = $DropDownBox.SelectedItem.ToString()
        }
    else {
        # Otherwise, use the description to find an AD machine name that contains that description. Apply it as the target.
        $description = $DropDownBox2.SelectedItem.ToString()
        $computername = (Get-ADComputer -Filter 'description -like $description' | select name)
        $target = $computername.name
    }


    IF ($Checkbox3.Checked) {
        # Start remote assistance using the specified target.
        Start-Process msra.exe -ArgumentList "/offerra $target"
    }

    IF ($Checkbox4.Checked) {
        # Start remote assistance using the specified target.
        Start-Process mstsc.exe -ArgumentList "/v:$target /w:1440 /h:900"
    }

    # Open the default share if available (when box is checked.)
    If ($Checkbox1.Checked -eq $true) {
        Invoke-Item "\\$target\c$"
    }

    # Start a remote powershell session if the box is checked.
    If ($Checkbox2.Checked -eq $true) {
        $arguments = ('-NoExit -command "Enter-PSSession -ComputerName "' + $target)
        start-process powershell.exe -argumentlist $arguments
    }

})

[void]$SetupTool.ShowDialog()