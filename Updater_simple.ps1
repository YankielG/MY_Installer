Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$sciezkaBazowa = [System.AppDomain]::CurrentDomain.BaseDirectory
if ([string]::IsNullOrWhiteSpace($sciezkaBazowa)) { $sciezkaBazowa = $PSScriptRoot }

# ==============================================================================
# 1. FUNKCJE POMOCNICZE DO PARSOWANIA WYJSCIA WINGET (PO POZYCJACH NAGLOWKA)
# ==============================================================================
function Parse-WingetTable {
    param([string[]]$Lines)

    $wyniki = @()
    $headerIdx = -1

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $l = $Lines[$i]
        if (($l -match "Id" -and $l -match "Version") -or ($l -match "Id" -and $l -match "Wersja")) {
            $headerIdx = $i
            break
        }
    }

    if ($headerIdx -lt 0) { return $wyniki }

    $header = $Lines[$headerIdx]

    $posName = 0
    $posId = $header.IndexOf("Id")
    $posVer = $header.IndexOf("Version")
    if ($posVer -lt 0) { $posVer = $header.IndexOf("Wersja") }

    $posAvail = $header.IndexOf("Available")
    if ($posAvail -lt 0) { $posAvail = $header.IndexOf("Dostępna") }
    if ($posAvail -lt 0) { $posAvail = $header.IndexOf("Dostepna") }

    $posSource = $header.IndexOf("Source")
    if ($posSource -lt 0) { $posSource = $header.IndexOf("Źródło") }
    if ($posSource -lt 0) { $posSource = $header.IndexOf("Zrodlo") }

    $posPin = $header.IndexOf("Pin type")
    if ($posPin -lt 0) { $posPin = $header.IndexOf("Typ przypięcia") }
    if ($posPin -lt 0) { $posPin = $header.IndexOf("Typ przypiecia") }

    for ($i = $headerIdx + 2; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match "^\d+\s+(upgrades|aktualizac)") { continue }
        if ($line.Length -le $posId) { continue }

        $safeSub = {
            param([string]$str, [int]$start, [int]$end)
            if ($start -lt 0 -or $start -ge $str.Length) { return "" }
            if ($end -lt 0 -or $end -gt $str.Length) { $end = $str.Length }
            if ($end -le $start) { return "" }
            return $str.Substring($start, $end - $start).Trim()
        }

        $name = & $safeSub $line $posName $posId

        $endId = if ($posVer -gt $posId) { $posVer } else { $line.Length }
        $id = & $safeSub $line $posId $endId

        $endVer = $line.Length
        if ($posAvail -gt $posVer) { $endVer = $posAvail }
        elseif ($posSource -gt $posVer) { $endVer = $posSource }
        elseif ($posPin -gt $posVer) { $endVer = $posPin }
        $ver = if ($posVer -ge 0) { & $safeSub $line $posVer $endVer } else { "" }

        $avail = ""
        if ($posAvail -ge 0) {
            $endAvail = if ($posSource -gt $posAvail) { $posSource } elseif ($posPin -gt $posAvail) { $posPin } else { $line.Length }
            $avail = & $safeSub $line $posAvail $endAvail
        }

        $source = "winget"
        if ($posSource -ge 0) {
            $endSource = if ($posPin -gt $posSource) { $posPin } else { $line.Length }
            $sVal = & $safeSub $line $posSource $endSource
            if (-not [string]::IsNullOrWhiteSpace($sVal)) { $source = $sVal }
        }

        $pinType = ""
        if ($posPin -ge 0) {
            $pinType = & $safeSub $line $posPin $line.Length
        }

        if (-not [string]::IsNullOrWhiteSpace($id)) {
            $wyniki += [PSCustomObject]@{
                Nazwa     = $name
                ID        = $id
                Wersja    = $ver
                Dostepna  = $avail
                Zrodlo    = $source
                PinType   = $pinType
            }
        }
    }

    return $wyniki
}

# ==============================================================================
# 2. SKANOWANIE AKTUALIZACJI I PRZYPIETYCH PAKIETOW (WINGET PIN)
# ==============================================================================
$script:logDiagnostyczny = ""

function Pobierz-Aktualizacje {
    Write-Host "Aktualizowanie bazy pakietow winget..." -ForegroundColor Yellow
    cmd /c "chcp 65001 >nul && winget source update" | Out-Null

    Write-Host "Sprawdzanie listy przypietych pakietow (winget pin list)..." -ForegroundColor Yellow
    $rawPin = cmd /c "chcp 65001 >nul && winget pin list --accept-source-agreements"
    $parsowanePin = Parse-WingetTable -Lines $rawPin

    $mapaPin = @{}
    foreach ($pinItem in $parsowanePin) {
        $typPinTekst = if ([string]::IsNullOrWhiteSpace($pinItem.PinType)) { "Pinning" } else { $pinItem.PinType }
        $mapaPin[$pinItem.ID.ToLower()] = [PSCustomObject]@{
            Nazwa   = $pinItem.Nazwa
            ID      = $pinItem.ID
            Wersja  = $pinItem.Wersja
            Zrodlo  = $pinItem.Zrodlo
            PinType = $typPinTekst
        }
    }

    Write-Host "Skanowanie dostepnych aktualizacji (w tym przypietych)..." -ForegroundColor Yellow
    $rawUpgrade = cmd /c "chcp 65001 >nul && winget upgrade --include-pinned --accept-source-agreements"
    $parsowaneUpgrade = Parse-WingetTable -Lines $rawUpgrade

    $script:logDiagnostyczny = "=== WINGET PIN LIST ===`r`n" + ($rawPin -join "`r`n") + "`r`n`r`n=== WINGET UPGRADE --INCLUDE-PINNED ===`r`n" + ($rawUpgrade -join "`r`n")

    $lista = @()
    $dodaneID = @()

    foreach ($u in $parsowaneUpgrade) {
        $klucz = $u.ID.ToLower()
        $czyPin = $mapaPin.ContainsKey($klucz)
        $statusPin = if ($czyPin) { $mapaPin[$klucz].PinType } else { "-" }

        $lista += [PSCustomObject]@{
            Zaznaczony = (-not $czyPin)
            Nazwa      = $u.Nazwa
            ID         = $u.ID
            Wersja     = $u.Wersja
            Dostepna   = $u.Dostepna
            Zrodlo     = $u.Zrodlo
            Pin        = $statusPin
            Przypiety  = $czyPin
            Tryb       = "Cichy"
        }
        $dodaneID += $klucz
    }

    # Jesli jakis pakiet z winget pin list nie byl na liscie upgrade (np. blokada Blocking lub brak nowszej wersji)
    foreach ($klucz in $mapaPin.Keys) {
        if ($dodaneID -notcontains $klucz) {
            $pObj = $mapaPin[$klucz]
            $lista += [PSCustomObject]@{
                Zaznaczony = $false
                Nazwa      = $pObj.Nazwa
                ID         = $pObj.ID
                Wersja     = $pObj.Wersja
                Dostepna   = "(zablokowana)"
                Zrodlo     = $pObj.Zrodlo
                Pin        = $pObj.PinType
                Przypiety  = $true
                Tryb       = "Cichy"
            }
        }
    }

    return $lista
}

$script:aktualizacje = @(Pobierz-Aktualizacje)

# ==============================================================================
# 3. INTERFEJS GRAFICZNY (OKNO, FILTRY ZRODLA I PIN, TABELA)
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "My Updater PRO - GJ mean"
$form.Size = New-Object System.Drawing.Size(1040, 640)
$form.MinimumSize = New-Object System.Drawing.Size(920, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "Sizable"
$form.MaximizeBox = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

$sciezkaIkony = Join-Path $sciezkaBazowa "ikona.ico"
if (Test-Path $sciezkaIkony) {
    $form.Icon = New-Object System.Drawing.Icon($sciezkaIkony)
} else {
    $form.Icon = [System.Drawing.SystemIcons]::Shield
}

$przesuniecieX = 15
$sciezkaLogo = Join-Path $sciezkaBazowa "logo.jpg"
if (-not (Test-Path $sciezkaLogo)) { $sciezkaLogo = Join-Path $sciezkaBazowa "logo.png" }

if (Test-Path $sciezkaLogo) {
    $picLogo = New-Object System.Windows.Forms.PictureBox
    $picLogo.Image = [System.Drawing.Image]::FromFile($sciezkaLogo)
    $picLogo.SizeMode = "Zoom"
    $picLogo.Location = New-Object System.Drawing.Point(15, 10)
    $picLogo.Size = New-Object System.Drawing.Size(60, 60)
    $form.Controls.Add($picLogo)
    $przesuniecieX = 85
}

$lblTytul = New-Object System.Windows.Forms.Label
$lblTytul.Text = "My Updater PRO"
$lblTytul.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTytul.Location = New-Object System.Drawing.Point($przesuniecieX, 12)
$lblTytul.AutoSize = $true
$form.Controls.Add($lblTytul)

$lblOpis = New-Object System.Windows.Forms.Label
$lblOpis.Text = "Zaznacz programy do aktualizacji. Pozycje przypiete (Pin) sa wyroznione na zolto i domyslnie odznaczone."
$lblOpis.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblOpis.ForeColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$lblOpis.Location = New-Object System.Drawing.Point($przesuniecieX, 45)
$lblOpis.AutoSize = $true
$form.Controls.Add($lblOpis)

# --- GORA: PRZYCISKI ODSWIEZANIA I DIAGNOSTYKI ---
$btnOdswiez = New-Object System.Windows.Forms.Button
$btnOdswiez.Text = "Odswiez liste"
$btnOdswiez.Location = New-Object System.Drawing.Point(770, 22)
$btnOdswiez.Size = New-Object System.Drawing.Size(110, 30)
$btnOdswiez.Anchor = "Top, Right"
$btnOdswiez.Add_Click({
    $btnOdswiez.Enabled = $false
    $btnOdswiez.Text = "Skanowanie..."
    $form.Refresh()
    $script:aktualizacje = @(Pobierz-Aktualizacje)
    & $odswiezTabele
    $btnOdswiez.Text = "Odswiez liste"
    $btnOdswiez.Enabled = $true
})
$form.Controls.Add($btnOdswiez)

$btnLog = New-Object System.Windows.Forms.Button
$btnLog.Text = "Podglad logu"
$btnLog.Location = New-Object System.Drawing.Point(886, 22)
$btnLog.Size = New-Object System.Drawing.Size(120, 30)
$btnLog.Anchor = "Top, Right"
$btnLog.Add_Click({
    $logForm = New-Object System.Windows.Forms.Form
    $logForm.Text = "Surowy wynik winget"
    $logForm.Size = New-Object System.Drawing.Size(780, 500)
    $logForm.StartPosition = "CenterParent"
    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Multiline = $true
    $txtLog.ScrollBars = "Both"
    $txtLog.WordWrap = $false
    $txtLog.Font = New-Object System.Drawing.Font("Consolas", 9.5)
    $txtLog.Dock = "Fill"
    $txtLog.Text = $script:logDiagnostyczny
    $logForm.Controls.Add($txtLog)
    [void]$logForm.ShowDialog()
})
$form.Controls.Add($btnLog)

# --- FILTRY: SZUKAJ, ZRODLO, PIN ---
$lblSzukaj = New-Object System.Windows.Forms.Label
$lblSzukaj.Text = "Szukaj:"
$lblSzukaj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSzukaj.Location = New-Object System.Drawing.Point(15, 88)
$lblSzukaj.AutoSize = $true
$form.Controls.Add($lblSzukaj)

$txtSzukaj = New-Object System.Windows.Forms.TextBox
$txtSzukaj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$txtSzukaj.Location = New-Object System.Drawing.Point(68, 85)
$txtSzukaj.Size = New-Object System.Drawing.Size(440, 24)
$txtSzukaj.Anchor = "Top, Left, Right"
$form.Controls.Add($txtSzukaj)

$lblZrodlo = New-Object System.Windows.Forms.Label
$lblZrodlo.Text = "Zrodlo:"
$lblZrodlo.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblZrodlo.Location = New-Object System.Drawing.Point(525, 88)
$lblZrodlo.AutoSize = $true
$lblZrodlo.Anchor = "Top, Right"
$form.Controls.Add($lblZrodlo)

$cmbZrodlo = New-Object System.Windows.Forms.ComboBox
$cmbZrodlo.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$cmbZrodlo.Location = New-Object System.Drawing.Point(578, 85)
$cmbZrodlo.Size = New-Object System.Drawing.Size(145, 24)
$cmbZrodlo.DropDownStyle = "DropDownList"
$cmbZrodlo.Anchor = "Top, Right"
$cmbZrodlo.Items.AddRange(@("Wszystkie", "winget", "msstore"))
$cmbZrodlo.SelectedIndex = 0
$form.Controls.Add($cmbZrodlo)

$lblPinFiltr = New-Object System.Windows.Forms.Label
$lblPinFiltr.Text = "Status Pin:"
$lblPinFiltr.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblPinFiltr.Location = New-Object System.Drawing.Point(738, 88)
$lblPinFiltr.AutoSize = $true
$lblPinFiltr.Anchor = "Top, Right"
$form.Controls.Add($lblPinFiltr)

$cmbPinFiltr = New-Object System.Windows.Forms.ComboBox
$cmbPinFiltr.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$cmbPinFiltr.Location = New-Object System.Drawing.Point(810, 85)
$cmbPinFiltr.Size = New-Object System.Drawing.Size(196, 24)
$cmbPinFiltr.DropDownStyle = "DropDownList"
$cmbPinFiltr.Anchor = "Top, Right"
$cmbPinFiltr.Items.AddRange(@("Wszystkie", "Bez Pin (-)", "Tylko przypiete (Pin)"))
$cmbPinFiltr.SelectedIndex = 0
$form.Controls.Add($cmbPinFiltr)

# --- TABELA ---
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(15, 120)
$grid.Size = New-Object System.Drawing.Size(991, 415)
$grid.Anchor = "Top, Bottom, Left, Right"
$grid.BackgroundColor = [System.Drawing.Color]::White
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.AllowUserToResizeRows = $false
$grid.RowHeadersVisible = $false
$grid.SelectionMode = "FullRowSelect"
$grid.AutoSizeColumnsMode = "Fill"
$grid.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)

$colZaznacz = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$colZaznacz.Name = "Zaznacz"
$colZaznacz.HeaderText = "Zaznacz"
$colZaznacz.FillWeight = 8
$grid.Columns.Add($colZaznacz) | Out-Null

$colNazwa = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colNazwa.Name = "Nazwa"
$colNazwa.HeaderText = "Nazwa aplikacji"
$colNazwa.ReadOnly = $true
$colNazwa.FillWeight = 25
$grid.Columns.Add($colNazwa) | Out-Null

$colID = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colID.Name = "ID"
$colID.HeaderText = "ID pakietu"
$colID.ReadOnly = $true
$colID.FillWeight = 22
$grid.Columns.Add($colID) | Out-Null

$colWersja = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colWersja.Name = "Wersja"
$colWersja.HeaderText = "Obecna wersja"
$colWersja.ReadOnly = $true
$colWersja.FillWeight = 11
$grid.Columns.Add($colWersja) | Out-Null

$colDostepna = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colDostepna.Name = "Dostepna"
$colDostepna.HeaderText = "Nowa wersja"
$colDostepna.ReadOnly = $true
$colDostepna.FillWeight = 11
$grid.Columns.Add($colDostepna) | Out-Null

$colZrodlo = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colZrodlo.Name = "Zrodlo"
$colZrodlo.HeaderText = "Zrodlo"
$colZrodlo.ReadOnly = $true
$colZrodlo.FillWeight = 8
$grid.Columns.Add($colZrodlo) | Out-Null

$colPin = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colPin.Name = "Pin"
$colPin.HeaderText = "Pin"
$colPin.ReadOnly = $true
$colPin.FillWeight = 9
$grid.Columns.Add($colPin) | Out-Null

$colTryb = New-Object System.Windows.Forms.DataGridViewComboBoxColumn
$colTryb.Name = "Tryb"
$colTryb.HeaderText = "Tryb"
$colTryb.Items.AddRange("Cichy", "Interaktywny")
$colTryb.FillWeight = 11
$colTryb.DisplayStyle = "DropDownButton"
$grid.Columns.Add($colTryb) | Out-Null

$form.Controls.Add($grid)

$lblLicznik = New-Object System.Windows.Forms.Label
$lblLicznik.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblLicznik.ForeColor = [System.Drawing.Color]::FromArgb(0, 103, 192)
$lblLicznik.Location = New-Object System.Drawing.Point(685, 550)
$lblLicznik.Size = New-Object System.Drawing.Size(155, 25)
$lblLicznik.TextAlign = "MiddleRight"
$lblLicznik.Anchor = "Bottom, Right"
$form.Controls.Add($lblLicznik)

$aktualizujLicznik = {
    $ile = ($script:aktualizacje | Where-Object { $_.Zaznaczony -eq $true }).Count
    $razem = $script:aktualizacje.Count
    $lblLicznik.Text = "Wybrano: $ile / $razem"
}

$grid.Add_CurrentCellDirtyStateChanged({
    if ($grid.IsCurrentCellDirty) {
        $grid.CommitEdit([System.Windows.Forms.DataGridViewDataErrorContexts]::Commit)
    }
})

$grid.Add_CellValueChanged({
    param($sender, $e)
    if ($e.RowIndex -ge 0) {
        $item = $grid.Rows[$e.RowIndex].Tag
        if ($e.ColumnIndex -eq 0) {
            $item.Zaznaczony = [bool]$grid.Rows[$e.RowIndex].Cells[0].Value
            & $aktualizujLicznik
        }
        if ($e.ColumnIndex -eq 7) {
            $item.Tryb = $grid.Rows[$e.RowIndex].Cells[7].Value.ToString()
        }
    }
})

$odswiezTabele = {
    $grid.Rows.Clear()
    $szukaj = $txtSzukaj.Text.ToLower()
    $wybraneZrodlo = $cmbZrodlo.SelectedItem.ToString()
    $wybranyPin = $cmbPinFiltr.SelectedItem.ToString()

    foreach ($p in $script:aktualizacje) {
        $pasujeTekst = ($p.Nazwa.ToLower().Contains($szukaj)) -or ($p.ID.ToLower().Contains($szukaj))
        $pasujeZrodlo = ($wybraneZrodlo -eq "Wszystkie") -or ($p.Zrodlo -eq $wybraneZrodlo)

        $pasujePin = $true
        if ($wybranyPin -eq "Bez Pin (-)") { $pasujePin = (-not $p.Przypiety) }
        elseif ($wybranyPin -eq "Tylko przypiete (Pin)") { $pasujePin = $p.Przypiety }

        if ($pasujeTekst -and $pasujeZrodlo -and $pasujePin) {
            $idx = $grid.Rows.Add($p.Zaznaczony, $p.Nazwa, $p.ID, $p.Wersja, $p.Dostepna, $p.Zrodlo, $p.Pin, $p.Tryb)
            $grid.Rows[$idx].Tag = $p

            if ($p.Przypiety) {
                $grid.Rows[$idx].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(255, 250, 220)
                $grid.Rows[$idx].Cells[6].Style.ForeColor = [System.Drawing.Color]::DarkGoldenrod
                $grid.Rows[$idx].Cells[6].Style.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
            } elseif ($p.Zrodlo -eq "msstore") {
                $grid.Rows[$idx].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(238, 246, 255)
            }
        }
    }
    & $aktualizujLicznik
}

$txtSzukaj.Add_TextChanged($odswiezTabele)
$cmbZrodlo.Add_SelectedIndexChanged($odswiezTabele)
$cmbPinFiltr.Add_SelectedIndexChanged($odswiezTabele)
& $odswiezTabele

# --- DOLNE PRZYCISKI ---
$btnZaznaczWszystkie = New-Object System.Windows.Forms.Button
$btnZaznaczWszystkie.Text = "Zaznacz widoczne"
$btnZaznaczWszystkie.Location = New-Object System.Drawing.Point(15, 545)
$btnZaznaczWszystkie.Size = New-Object System.Drawing.Size(120, 32)
$btnZaznaczWszystkie.Anchor = "Bottom, Left"
$btnZaznaczWszystkie.Add_Click({
    foreach ($row in $grid.Rows) { $row.Cells[0].Value = $true }
})
$form.Controls.Add($btnZaznaczWszystkie)

$btnZaznaczBezPin = New-Object System.Windows.Forms.Button
$btnZaznaczBezPin.Text = "Zaznacz bez Pin"
$btnZaznaczBezPin.Location = New-Object System.Drawing.Point(140, 545)
$btnZaznaczBezPin.Size = New-Object System.Drawing.Size(115, 32)
$btnZaznaczBezPin.Anchor = "Bottom, Left"
$btnZaznaczBezPin.Add_Click({
    foreach ($p in $script:aktualizacje) { $p.Zaznaczony = (-not $p.Przypiety) }
    & $odswiezTabele
})
$form.Controls.Add($btnZaznaczBezPin)

$btnOdznaczWszystkie = New-Object System.Windows.Forms.Button
$btnOdznaczWszystkie.Text = "Odznacz wszystkie"
$btnOdznaczWszystkie.Location = New-Object System.Drawing.Point(260, 545)
$btnOdznaczWszystkie.Size = New-Object System.Drawing.Size(125, 32)
$btnOdznaczWszystkie.Anchor = "Bottom, Left"
$btnOdznaczWszystkie.Add_Click({
    foreach ($p in $script:aktualizacje) { $p.Zaznaczony = $false }
    & $odswiezTabele
})
$form.Controls.Add($btnOdznaczWszystkie)

$btnTrybCichy = New-Object System.Windows.Forms.Button
$btnTrybCichy.Text = "Wszystkie: Cichy"
$btnTrybCichy.Location = New-Object System.Drawing.Point(395, 545)
$btnTrybCichy.Size = New-Object System.Drawing.Size(115, 32)
$btnTrybCichy.Anchor = "Bottom, Left"
$btnTrybCichy.Add_Click({
    foreach ($row in $grid.Rows) {
        $row.Cells[7].Value = "Cichy"
        $row.Tag.Tryb = "Cichy"
    }
})
$form.Controls.Add($btnTrybCichy)

$btnTrybInteraktywny = New-Object System.Windows.Forms.Button
$btnTrybInteraktywny.Text = "Wszystkie: Interaktywny"
$btnTrybInteraktywny.Location = New-Object System.Drawing.Point(515, 545)
$btnTrybInteraktywny.Size = New-Object System.Drawing.Size(145, 32)
$btnTrybInteraktywny.Anchor = "Bottom, Left"
$btnTrybInteraktywny.Add_Click({
    foreach ($row in $grid.Rows) {
        $row.Cells[7].Value = "Interaktywny"
        $row.Tag.Tryb = "Interaktywny"
    }
})
$form.Controls.Add($btnTrybInteraktywny)

$script:startAktualizacji = $false
$btnAktualizuj = New-Object System.Windows.Forms.Button
$btnAktualizuj.Text = "Aktualizuj wybrane"
$btnAktualizuj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$btnAktualizuj.BackColor = [System.Drawing.Color]::FromArgb(0, 103, 192)
$btnAktualizuj.ForeColor = [System.Drawing.Color]::White
$btnAktualizuj.FlatStyle = "Flat"
$btnAktualizuj.Location = New-Object System.Drawing.Point(846, 545)
$btnAktualizuj.Size = New-Object System.Drawing.Size(160, 32)
$btnAktualizuj.Anchor = "Bottom, Right"
$btnAktualizuj.Add_Click({
    $script:startAktualizacji = $true
    $form.Close()
})
$form.Controls.Add($btnAktualizuj)

[void]$form.ShowDialog()

# ==============================================================================
# 4. WYKONANIE AKTUALIZACJI PO ZAMKNIECIU OKNA
# ==============================================================================
if ($script:startAktualizacji) {
    $wybrane = $script:aktualizacje | Where-Object { $_.Zaznaczony -eq $true }

    if ($wybrane.Count -eq 0) {
        Write-Host "Nie wybrano zadnych programow do aktualizacji." -ForegroundColor Yellow
        Pause
        exit
    }

    foreach ($p in $wybrane) {
        Write-Host "`n==========================================" -ForegroundColor DarkGray
        Write-Host "Aktualizowanie: $($p.Nazwa) ($($p.Wersja) -> $($p.Dostepna)) [Zrodlo: $($p.Zrodlo) | Pin: $($p.Pin)]" -ForegroundColor Cyan

        $argumenty = @("upgrade", "--id", $p.ID, "-e", "--source", $p.Zrodlo, "--accept-package-agreements", "--accept-source-agreements")

        if ($p.Przypiety) {
            $argumenty += "--include-pinned"
        }

        if ($p.Tryb -eq "Cichy") {
            $argumenty += "--silent"
        } else {
            Write-Host "Przeklikaj kreator aktualizacji, aby przejsc dalej..." -ForegroundColor Yellow
            $argumenty += "--interactive"
        }

        & winget @argumenty
    }

    Write-Host "`nWszystkie wybrane aktualizacje zostaly zakonczone!" -ForegroundColor Green
    Pause
}
