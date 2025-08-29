# ==========================
# Password Manager Tool
# ==========================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- CONFIGURATION ---
$exeDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent ([System.Reflection.Assembly]::GetEntryAssembly().Location) }
$dataFile = Join-Path $exeDir "passwords.txt"
$iconFile = Join-Path $exeDir "WPM.ico"  # Place WPM.ico in same folder
$adminPassword = "Waji@Moc"              # Change this
$key = @(21, 12, 34, 56, 78, 90, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)

# --- HELPER: SET ICON ---
function Set-CustomIcon($form) {
    if (Test-Path $iconFile) {
        try {
            $form.Icon = New-Object System.Drawing.Icon($iconFile)
        } catch {
            Write-Warning "Invalid icon file format. Please use a valid .ico file."
        }
    }
}

# --- ENCRYPTION ---
function Encrypt-String($string, $key) {
    $secureString = ConvertTo-SecureString $string -AsPlainText -Force
    return ConvertFrom-SecureString $secureString -Key $key
}
function Decrypt-String($encryptedString, $key) {
    $secureString = ConvertTo-SecureString $encryptedString -Key $key
    return [System.Net.NetworkCredential]::new("", $secureString).Password
}

# --- LOGIN SCREEN ---
function Show-Login($callback) {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Admin Login"
    $form.Size = '300,150'
    $form.StartPosition = 'CenterScreen'
    Set-CustomIcon $form

    $label = New-Object Windows.Forms.Label
    $label.Text = "Enter Admin Password:"
    $label.AutoSize = $true
    $label.Location = '10,20'
    $form.Controls.Add($label)

    $textbox = New-Object Windows.Forms.TextBox
    $textbox.Location = '10,50'
    $textbox.Width = 260
    $textbox.UseSystemPasswordChar = $true
    $form.Controls.Add($textbox)

    $button = New-Object Windows.Forms.Button
    $button.Text = "Login"
    $button.Location = '100,80'
    $button.Add_Click({
        if ($textbox.Text -eq $adminPassword) {
            $form.Close()
            $form.Dispose()
            & $callback
        } else {
            [System.Windows.Forms.MessageBox]::Show("Incorrect password", "Error", "OK", "Error")
        }
    })
    $form.Controls.Add($button)
    $form.AcceptButton = $button
    $form.ShowDialog()
}

# --- MAIN MENU ---
function Show-MainMenu {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Password Manager"
    $form.Size = '300,250'
    $form.StartPosition = 'CenterScreen'
    Set-CustomIcon $form

    $label = New-Object Windows.Forms.Label
    $label.Text = "Select an option:"
    $label.Location = '90,20'
    $form.Controls.Add($label)

    $genButton = New-Object Windows.Forms.Button
    $genButton.Text = "Generate Password"
    $genButton.Size = '200,30'
    $genButton.Location = '40,60'
    $genButton.Add_Click({
        $form.Close()
        $form.Dispose()
        Show-PasswordGeneratorForm
    })
    $form.Controls.Add($genButton)

    $saveButton = New-Object Windows.Forms.Button
    $saveButton.Text = "Save Password"
    $saveButton.Size = '200,30'
    $saveButton.Location = '40,100'
    $saveButton.Add_Click({
        $form.Close()
        $form.Dispose()
        Show-Generator
    })
    $form.Controls.Add($saveButton)

    $viewButton = New-Object Windows.Forms.Button
    $viewButton.Text = "View Passwords"
    $viewButton.Size = '200,30'
    $viewButton.Location = '40,140'
    $viewButton.Add_Click({
        $form.Close()
        $form.Dispose()
        Show-Viewer
    })
    $form.Controls.Add($viewButton)

    $form.ShowDialog()
}


# --- SIMPLE PASSWORD GENERATOR ---
function Show-PasswordGeneratorForm {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Generate Password"
    $form.Size = '450,300'
    $form.StartPosition = 'CenterScreen'
    Set-CustomIcon $form

    $lengthLabel = New-Object Windows.Forms.Label
    $lengthLabel.Text = "Password Length:"
    $lengthLabel.Location = '20,20'
    $form.Controls.Add($lengthLabel)

    $lengthBox = New-Object Windows.Forms.TextBox
    $lengthBox.Text = "16"
    $lengthBox.Location = '150,20'
    $lengthBox.Width = 50
    $form.Controls.Add($lengthBox)

    $chkSpecial = New-Object Windows.Forms.CheckBox
    $chkSpecial.Text = "Include Special Characters"
    $chkSpecial.Location = '20,60'
    $form.Controls.Add($chkSpecial)

    $chkNumbers = New-Object Windows.Forms.CheckBox
    $chkNumbers.Text = "Include Numbers"
    $chkNumbers.Location = '20,90'
    $form.Controls.Add($chkNumbers)

    $chkAlphaOnly = New-Object Windows.Forms.CheckBox
    $chkAlphaOnly.Text = "Only Alphabets"
    $chkAlphaOnly.Location = '20,120'
    $form.Controls.Add($chkAlphaOnly)

    # Checkbox exclusivity
    $chkAlphaOnly.Add_CheckedChanged({
        if ($chkAlphaOnly.Checked) {
            $chkSpecial.Checked = $false
            $chkNumbers.Checked = $false
        }
    })
    $chkSpecial.Add_CheckedChanged({ if ($chkSpecial.Checked) { $chkAlphaOnly.Checked = $false } })
    $chkNumbers.Add_CheckedChanged({ if ($chkNumbers.Checked) { $chkAlphaOnly.Checked = $false } })

    $resultLabel = New-Object Windows.Forms.Label
    $resultLabel.Text = "Generated Password:"
    $resultLabel.Location = '20,160'
    $form.Controls.Add($resultLabel)

    $resultBox = New-Object Windows.Forms.TextBox
    $resultBox.Location = '150,160'
    $resultBox.Width = 250
    $form.Controls.Add($resultBox)

    $generateButton = New-Object Windows.Forms.Button
    $generateButton.Text = "Generate"
    $generateButton.Location = '150,200'
    $generateButton.Add_Click({
        $length = [int]$lengthBox.Text
        $includeSpecial = $chkSpecial.Checked
        $includeNumbers = $chkNumbers.Checked
        $onlyAlpha = $chkAlphaOnly.Checked

        $chars = @()
        if ($onlyAlpha) {
            $chars += [char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
        } else {
            $chars += [char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
            if ($includeNumbers) { $chars += [char[]]'0123456789' }
            if ($includeSpecial) { $chars += [char[]]'!@#$%^&*()-_=+[]{};:,.<>?' }
        }

        if ($chars.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one character type.", "Error")
            return
        }

        $rand = New-Object System.Random
        $password = -join (1..$length | ForEach-Object { $chars[$rand.Next(0, $chars.Count)] })
        $resultBox.Text = $password
    })
    $form.Controls.Add($generateButton)

    $copyButton = New-Object Windows.Forms.Button
    $copyButton.Text = "Copy"
    $copyButton.Location = '250,200'
    $copyButton.Add_Click({
        Set-Clipboard -Value $resultBox.Text
        [System.Windows.Forms.MessageBox]::Show("Password copied to clipboard.", "Copied")
    })
    $form.Controls.Add($copyButton)

    $backButton = New-Object Windows.Forms.Button
    $backButton.Text = "Back"
    $backButton.Location = '350,230'
    $backButton.Add_Click({
        $form.Close()
        $form.Dispose()
        Show-MainMenu
    })
    $form.Controls.Add($backButton)

    $form.ShowDialog()
}

# --- SAVE PASSWORD FORM ---
function Show-Generator {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Save Password"
    $form.Size = '450,260'
    $form.StartPosition = 'CenterScreen'
    Set-CustomIcon $form

    $typeLabel = New-Object Windows.Forms.Label
    $typeLabel.Text = "Type (e.g. Telegram, Gmail):"
    $typeLabel.Location = '20,20'
    $form.Controls.Add($typeLabel)

    $typeBox = New-Object Windows.Forms.TextBox
    $typeBox.Location = '180,20'
    $typeBox.Width = 230
    $form.Controls.Add($typeBox)

    $emailLabel = New-Object Windows.Forms.Label
    $emailLabel.Text = "Email:"
    $emailLabel.Location = '20,60'
    $form.Controls.Add($emailLabel)

    $emailBox = New-Object Windows.Forms.TextBox
    $emailBox.Location = '180,60'
    $emailBox.Width = 230
    $form.Controls.Add($emailBox)

    $passLabel = New-Object Windows.Forms.Label
    $passLabel.Text = "Password:"
    $passLabel.Location = '20,100'
    $form.Controls.Add($passLabel)

    $passBox = New-Object Windows.Forms.TextBox
    $passBox.Location = '180,100'
    $passBox.Width = 230
    $passBox.UseSystemPasswordChar = $true
    $form.Controls.Add($passBox)

    $confirmLabel = New-Object Windows.Forms.Label
    $confirmLabel.Text = "Confirm Password:"
    $confirmLabel.Location = '20,140'
    $form.Controls.Add($confirmLabel)

    $confirmBox = New-Object Windows.Forms.TextBox
    $confirmBox.Location = '180,140'
    $confirmBox.Width = 230
    $confirmBox.UseSystemPasswordChar = $true
    $form.Controls.Add($confirmBox)

    $saveButton = New-Object Windows.Forms.Button
    $saveButton.Text = "Save"
    $saveButton.Location = '180,180'
    $saveButton.Add_Click({
        if ($typeBox.Text -and $emailBox.Text -and $passBox.Text -and $confirmBox.Text) {
            if ($passBox.Text -eq $confirmBox.Text) {
                $enc = Encrypt-String $passBox.Text $key
                "$($typeBox.Text)|$($emailBox.Text)|$enc" | Out-File -Append -Encoding UTF8 $dataFile
                [System.Windows.Forms.MessageBox]::Show("Saved successfully.", "Success")
                $typeBox.Text = ""; $emailBox.Text = ""; $passBox.Text = ""; $confirmBox.Text = ""
            } else {
                [System.Windows.Forms.MessageBox]::Show("Passwords do not match.", "Error")
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("All fields are required.", "Error")
        }
    })
    $form.Controls.Add($saveButton)

    $backButton = New-Object Windows.Forms.Button
    $backButton.Text = "Back"
    $backButton.Location = '280,180'
    $backButton.Add_Click({
        $form.Close()
        $form.Dispose()
        Show-MainMenu
    })
    $form.Controls.Add($backButton)

    $form.ShowDialog()
}

# --- VIEW PASSWORDS ---
function Show-Viewer {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Stored Passwords"
    $form.Size = '600,400'
    $form.StartPosition = 'CenterScreen'
    Set-CustomIcon $form

    $listView = New-Object Windows.Forms.ListView
    $listView.View = 'Details'
    $listView.FullRowSelect = $true
    $listView.Columns.Add("Type", 100)
    $listView.Columns.Add("Email", 300)
    $listView.Location = '10,10'
    $listView.Size = '560,280'
    $form.Controls.Add($listView)

    function Refresh-List {
        $listView.Items.Clear()
        if (Test-Path $dataFile) {
            $lines = Get-Content $dataFile
            foreach ($line in $lines) {
                $parts = $line -split '\|'
                if ($parts.Length -eq 3) {
                    $item = New-Object Windows.Forms.ListViewItem($parts[0])
                    $item.SubItems.Add($parts[1])
                    $listView.Items.Add($item)
                }
            }
        }
    }

    Refresh-List

    $copyEmail = New-Object Windows.Forms.Button
    $copyEmail.Text = "Copy Email"
    $copyEmail.Location = '50,300'
    $copyEmail.Add_Click({
        if ($listView.SelectedItems.Count -gt 0) {
            Set-Clipboard -Value $listView.SelectedItems[0].SubItems[1].Text
        }
    })
    $form.Controls.Add($copyEmail)

    $copyPass = New-Object Windows.Forms.Button
    $copyPass.Text = "Copy Password"
    $copyPass.Location = '170,300'
    $copyPass.Add_Click({
        if ($listView.SelectedItems.Count -gt 0) {
            $email = $listView.SelectedItems[0].SubItems[1].Text
            $line = (Get-Content $dataFile | Where-Object { $_ -like "*|$email|*" })
            $enc = ($line -split '\|')[2]
            $plain = Decrypt-String $enc $key
            Set-Clipboard -Value $plain
        }
    })
    $form.Controls.Add($copyPass)

    $deleteButton = New-Object Windows.Forms.Button
    $deleteButton.Text = "Delete"
    $deleteButton.Location = '310,300'
    $deleteButton.Add_Click({
        if ($listView.SelectedItems.Count -gt 0) {
            $email = $listView.SelectedItems[0].SubItems[1].Text
            $type  = $listView.SelectedItems[0].SubItems[0].Text
            $lines = Get-Content $dataFile
            $newLines = $lines | Where-Object { ($_ -split '\|')[0] -ne $type -or ($_ -split '\|')[1] -ne $email }
            $newLines | Out-File -Encoding UTF8 $dataFile
            [System.Windows.Forms.MessageBox]::Show("Record deleted.", "Deleted")
            Refresh-List
        }
    })
    $form.Controls.Add($deleteButton)

    $backButton = New-Object Windows.Forms.Button
    $backButton.Text = "Back"
    $backButton.Location = '430,300'
    $backButton.Add_Click({
        $form.Close()
        $form.Dispose()
        Show-MainMenu
    })
    $form.Controls.Add($backButton)

    $form.ShowDialog()
}

# --- START SCRIPT ---
Show-Login -callback Show-MainMenu
