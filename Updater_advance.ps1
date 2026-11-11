Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $script:sciezkaBazowa = [System.AppDomain]::CurrentDomain.BaseDirectory
} else {
    $script:sciezkaBazowa = $PSScriptRoot
}
$script:sciezkaBazowa = [System.IO.Path]::GetFullPath($script:sciezkaBazowa)


# ==============================================================================
# 1. POBIERANIE LISTY AKTUALIZACJI Z WINGET (WINGET + MSSTORE)
# ==============================================================================
function Parse-WingetTable {
    param([string[]]$Lines)

    $wyniki = @()
    $headerIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if (($Lines[$i] -match "Id" -and $Lines[$i] -match "Version") -or
            ($Lines[$i] -match "Id" -and $Lines[$i] -match "Wersja")) {
            $headerIdx = $i
            break
        }
    }

    if ($headerIdx -lt 0) { return $wyniki }

    $naglowek = $Lines[$headerIdx]
    $posId = $naglowek.IndexOf("Id")
    if ($posId -lt 0) { $posId = $naglowek.IndexOf("Identyfikator") }
    $posVer = $naglowek.IndexOf("Version")
    if ($posVer -lt 0) { $posVer = $naglowek.IndexOf("Wersja") }
    $posAvail = $naglowek.IndexOf("Available")
    if ($posAvail -lt 0) { $posAvail = $naglowek.IndexOf("Dostępna") }
    if ($posAvail -lt 0) { $posAvail = $naglowek.IndexOf("Dostepna") }
    $posSource = $naglowek.IndexOf("Source")
    if ($posSource -lt 0) { $posSource = $naglowek.IndexOf("Źródło") }
    if ($posSource -lt 0) { $posSource = $naglowek.IndexOf("Zrodlo") }
    $posPin = $naglowek.IndexOf("Pin type")
    if ($posPin -lt 0) { $posPin = $naglowek.IndexOf("Typ przypięcia") }
    if ($posPin -lt 0) { $posPin = $naglowek.IndexOf("Typ przypiecia") }

    if ($posId -lt 0 -or $posVer -le $posId) { return $wyniki }

    $safeSub = {
        param([string]$str, [int]$start, [int]$end)
        if ($start -lt 0 -or $start -ge $str.Length) { return "" }
        if ($end -lt 0 -or $end -gt $str.Length) { $end = $str.Length }
        if ($end -le $start) { return "" }
        $str.Substring($start, $end - $start).Trim()
    }

    for ($i = $headerIdx + 2; $i -lt $Lines.Count; $i++) {
        $linia = $Lines[$i]
        if ([string]::IsNullOrWhiteSpace($linia) -or $linia.Length -le $posId) { continue }
        if ($linia -match "^\d+\s+(upgrades|aktualizac)") { continue }

        $nazwa = & $safeSub $linia 0 $posId
        $id = & $safeSub $linia $posId $posVer
        $endVer = $linia.Length
        foreach ($pozycja in @($posAvail, $posSource, $posPin)) {
            if ($pozycja -gt $posVer -and $pozycja -lt $endVer) { $endVer = $pozycja }
        }
        $obecnaWersja = & $safeSub $linia $posVer $endVer

        $nowaWersja = ""
        if ($posAvail -gt $posVer) {
            $endAvail = $linia.Length
            foreach ($pozycja in @($posSource, $posPin)) {
                if ($pozycja -gt $posAvail -and $pozycja -lt $endAvail) { $endAvail = $pozycja }
            }
            $nowaWersja = & $safeSub $linia $posAvail $endAvail
        }

        $zrodlo = "winget"
        if ($posSource -ge 0) {
            $endSource = if ($posPin -gt $posSource) { $posPin } else { $linia.Length }
            $odczytaneZrodlo = & $safeSub $linia $posSource $endSource
            if (-not [string]::IsNullOrWhiteSpace($odczytaneZrodlo)) {
                if ($odczytaneZrodlo -match "msstore") { $zrodlo = "msstore" }
                elseif ($odczytaneZrodlo -match "winget") { $zrodlo = "winget" }
                else { $zrodlo = $odczytaneZrodlo }
            }
        }

        $pinType = ""
        if ($posPin -ge 0) { $pinType = & $safeSub $linia $posPin $linia.Length }
        $nazwa = $nazwa -replace "^[^\p{L}\p{N}\(\[]+", ""
        if ([string]::IsNullOrWhiteSpace($nazwa)) { $nazwa = $id }

        if (-not [string]::IsNullOrWhiteSpace($id)) {
            $wyniki += [PSCustomObject]@{
                Nazwa = $nazwa
                ID = $id
                Wersja = $obecnaWersja
                Dostepna = $nowaWersja
                Zrodlo = $zrodlo
                PinType = $pinType
            }
        }
    }

    return $wyniki
}

Write-Host "Aktualizowanie bazy zrodel winget..." -ForegroundColor Yellow
winget source update | Out-Null

Write-Host "Sprawdzanie przypietych pakietow (winget pin list)..." -ForegroundColor Yellow
$rawPin = @(winget pin list --accept-source-agreements 2>&1 | ForEach-Object { "$_" })
$parsowanePin = @(Parse-WingetTable -Lines $rawPin)
$mapaPin = @{}
foreach ($pinItem in $parsowanePin) {
    $typPin = if ([string]::IsNullOrWhiteSpace($pinItem.PinType)) { "Pinning" } else { $pinItem.PinType }
    $mapaPin[$pinItem.ID.ToLowerInvariant()] = [PSCustomObject]@{
        Nazwa = $pinItem.Nazwa
        ID = $pinItem.ID
        Wersja = $pinItem.Wersja
        Zrodlo = $pinItem.Zrodlo
        PinType = $typPin
    }
}

Write-Host "Skanowanie dostepnych aktualizacji (winget / msstore, w tym przypietych)..." -ForegroundColor Cyan
$rawOutput = @(winget upgrade --include-unknown --include-pinned --accept-source-agreements 2>&1 | ForEach-Object { "$_" })
$parsowaneAktualizacje = @(Parse-WingetTable -Lines $rawOutput)
$aktualizacje = @()
$dodaneID = @{}

foreach ($pakiet in $parsowaneAktualizacje) {
    $klucz = $pakiet.ID.ToLowerInvariant()
    $czyPrzypiety = $mapaPin.ContainsKey($klucz)
    $aktualizacje += [PSCustomObject]@{
        Zaznaczony = (-not $czyPrzypiety)
        Nazwa = $pakiet.Nazwa
        ID = $pakiet.ID
        ObecnaWersja = $pakiet.Wersja
        NowaWersja = $pakiet.Dostepna
        Zrodlo = $pakiet.Zrodlo
        Pin = if ($czyPrzypiety) { $mapaPin[$klucz].PinType } else { "-" }
        Przypiety = $czyPrzypiety
        Tryb = "Cichy"
    }
    $dodaneID[$klucz] = $true
}

foreach ($klucz in $mapaPin.Keys) {
    if (-not $dodaneID.ContainsKey($klucz)) {
        $pakiet = $mapaPin[$klucz]
        $aktualizacje += [PSCustomObject]@{
            Zaznaczony = $false
            Nazwa = $pakiet.Nazwa
            ID = $pakiet.ID
            ObecnaWersja = $pakiet.Wersja
            NowaWersja = "(brak aktualizacji)"
            Zrodlo = $pakiet.Zrodlo
            Pin = $pakiet.PinType
            Przypiety = $true
            Tryb = "Cichy"
        }
    }
}

# ==============================================================================
# 2. INTERFEJS GRAFICZNY (OKNO, FILTR ZRODLA, TABELA AKTUALIZACJI)
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "My Updater PRO - GJ mean"
$form.Size = New-Object System.Drawing.Size(1020, 630)
$form.MinimumSize = New-Object System.Drawing.Size(900, 480)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "Sizable"
$form.MaximizeBox = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

# Ikona okna
$sciezkaIkony = Join-Path $sciezkaBazowa "ikona.ico"
if (Test-Path $sciezkaIkony) {
    $form.Icon = New-Object System.Drawing.Icon($sciezkaIkony)
} else {
    $form.Icon = [System.Drawing.SystemIcons]::Shield
}

# Logo obok tytulu
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
$lblOpis.Text = "Zaznacz programy do aktualizacji. Przypiete pakiety sa pokazane na zolto i domyslnie odznaczone."
$lblOpis.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblOpis.ForeColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$lblOpis.Location = New-Object System.Drawing.Point($przesuniecieX, 45)
$lblOpis.AutoSize = $true
$form.Controls.Add($lblOpis)

# --- FILTRY: WYSZUKIWARKA + KATEGORIA ZRODLO (winget / msstore) ---
$lblSzukaj = New-Object System.Windows.Forms.Label
$lblSzukaj.Text = "Szukaj:"
$lblSzukaj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSzukaj.Location = New-Object System.Drawing.Point(15, 88)
$lblSzukaj.AutoSize = $true
$form.Controls.Add($lblSzukaj)

$txtSzukaj = New-Object System.Windows.Forms.TextBox
$txtSzukaj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$txtSzukaj.Location = New-Object System.Drawing.Point(65, 85)
$txtSzukaj.Size = New-Object System.Drawing.Size(410, 24)
$txtSzukaj.Anchor = "Top, Left, Right"
$form.Controls.Add($txtSzukaj)

$lblZrodlo = New-Object System.Windows.Forms.Label
$lblZrodlo.Text = "Zrodlo:"
$lblZrodlo.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblZrodlo.Location = New-Object System.Drawing.Point(490, 88)
$lblZrodlo.AutoSize = $true
$lblZrodlo.Anchor = "Top, Right"
$form.Controls.Add($lblZrodlo)

$cmbZrodlo = New-Object System.Windows.Forms.ComboBox
$cmbZrodlo.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$cmbZrodlo.Location = New-Object System.Drawing.Point(545, 85)
$cmbZrodlo.Size = New-Object System.Drawing.Size(145, 24)
$cmbZrodlo.DropDownStyle = "DropDownList"
$cmbZrodlo.Anchor = "Top, Right"
$cmbZrodlo.Items.AddRange(@("Wszystkie", "winget", "msstore"))
$cmbZrodlo.SelectedIndex = 0
$form.Controls.Add($cmbZrodlo)

$lblPinFiltr = New-Object System.Windows.Forms.Label
$lblPinFiltr.Text = "Status Pin:"
$lblPinFiltr.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblPinFiltr.Location = New-Object System.Drawing.Point(705, 88)
$lblPinFiltr.AutoSize = $true
$lblPinFiltr.Anchor = "Top, Right"
$form.Controls.Add($lblPinFiltr)

$cmbPinFiltr = New-Object System.Windows.Forms.ComboBox
$cmbPinFiltr.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$cmbPinFiltr.Location = New-Object System.Drawing.Point(777, 85)
$cmbPinFiltr.Size = New-Object System.Drawing.Size(211, 24)
$cmbPinFiltr.DropDownStyle = "DropDownList"
$cmbPinFiltr.Anchor = "Top, Right"
$cmbPinFiltr.Items.AddRange(@("Wszystkie", "Bez Pin (-)", "Tylko przypiete (Pin)"))
$cmbPinFiltr.SelectedIndex = 0
$form.Controls.Add($cmbPinFiltr)

# --- TABELA ---
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(15, 122)
$grid.Size = New-Object System.Drawing.Size(973, 403)
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
$colZaznacz.HeaderText = "Aktualizuj"
$colZaznacz.FillWeight = 8
$grid.Columns.Add($colZaznacz) | Out-Null

$colNazwa = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colNazwa.Name = "Nazwa"
$colNazwa.HeaderText = "Nazwa programu"
$colNazwa.ReadOnly = $true
$colNazwa.FillWeight = 26
$grid.Columns.Add($colNazwa) | Out-Null

$colZrodlo = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colZrodlo.Name = "Zrodlo"
$colZrodlo.HeaderText = "Zrodlo"
$colZrodlo.ReadOnly = $true
$colZrodlo.FillWeight = 10
$grid.Columns.Add($colZrodlo) | Out-Null

$colObecna = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colObecna.Name = "ObecnaWersja"
$colObecna.HeaderText = "Obecna wersja"
$colObecna.ReadOnly = $true
$colObecna.FillWeight = 13
$grid.Columns.Add($colObecna) | Out-Null

$colNowa = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colNowa.Name = "NowaWersja"
$colNowa.HeaderText = "Dostepna wersja"
$colNowa.ReadOnly = $true
$colNowa.FillWeight = 13
$grid.Columns.Add($colNowa) | Out-Null

$colPin = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colPin.Name = "Pin"
$colPin.HeaderText = "Pin"
$colPin.ReadOnly = $true
$colPin.FillWeight = 10
$grid.Columns.Add($colPin) | Out-Null

$colTryb = New-Object System.Windows.Forms.DataGridViewComboBoxColumn
$colTryb.Name = "Tryb"
$colTryb.HeaderText = "Tryb (kliknij)"
$colTryb.Items.AddRange("Cichy", "Interaktywny")
$colTryb.FillWeight = 12
$colTryb.DisplayStyle = "DropDownButton"
$grid.Columns.Add($colTryb) | Out-Null

$colID = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colID.Name = "ID"
$colID.HeaderText = "ID pakietu"
$colID.ReadOnly = $true
$colID.FillWeight = 16
$grid.Columns.Add($colID) | Out-Null

$form.Controls.Add($grid)

# Etykieta licznika zaznaczonych na dole
$lblLicznik = New-Object System.Windows.Forms.Label
$lblLicznik.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblLicznik.ForeColor = [System.Drawing.Color]::FromArgb(0, 103, 192)
$lblLicznik.Location = New-Object System.Drawing.Point(650, 545)
$lblLicznik.Size = New-Object System.Drawing.Size(170, 25)
$lblLicznik.TextAlign = "MiddleRight"
$lblLicznik.Anchor = "Bottom, Right"
$form.Controls.Add($lblLicznik)

$aktualizujLicznik = {
    $ile = ($aktualizacje | Where-Object { $_.Zaznaczony -eq $true }).Count
    $lblLicznik.Text = "Do aktualizacji: $ile / $($aktualizacje.Count)"
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
        if ($e.ColumnIndex -eq 6) {
            $item.Tryb = $grid.Rows[$e.RowIndex].Cells[6].Value.ToString()
        }
    }
})

$odswiezTabele = {
    $grid.Rows.Clear()
    $szukanyTekst = $txtSzukaj.Text.ToLower()
    $wybraneZrodlo = $cmbZrodlo.SelectedItem.ToString()
    $wybranyPin = $cmbPinFiltr.SelectedItem.ToString()

    foreach ($a in $aktualizacje) {
        $pasujeTekst = ($a.Nazwa.ToLower().Contains($szukanyTekst)) -or ($a.ID.ToLower().Contains($szukanyTekst))
        $pasujeZrodlo = ($wybraneZrodlo -eq "Wszystkie") -or ($a.Zrodlo -eq $wybraneZrodlo)
        $pasujePin = $true
        if ($wybranyPin -eq "Bez Pin (-)") { $pasujePin = (-not $a.Przypiety) }
        elseif ($wybranyPin -eq "Tylko przypiete (Pin)") { $pasujePin = $a.Przypiety }

        if ($pasujeTekst -and $pasujeZrodlo -and $pasujePin) {
            $idx = $grid.Rows.Add($a.Zaznaczony, $a.Nazwa, $a.Zrodlo, $a.ObecnaWersja, $a.NowaWersja, $a.Pin, $a.Tryb, $a.ID)
            $grid.Rows[$idx].Tag = $a

            if ($a.Przypiety) {
                $grid.Rows[$idx].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(255, 250, 220)
                $grid.Rows[$idx].Cells[5].Style.ForeColor = [System.Drawing.Color]::DarkGoldenrod
                $grid.Rows[$idx].Cells[5].Style.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
            } elseif ($a.Zrodlo -eq "msstore") {
                $grid.Rows[$idx].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(242, 247, 255)
            }
        }
    }
    & $aktualizujLicznik
}

$txtSzukaj.Add_TextChanged($odswiezTabele)
$cmbZrodlo.Add_SelectedIndexChanged($odswiezTabele)
$cmbPinFiltr.Add_SelectedIndexChanged($odswiezTabele)
& $odswiezTabele

# --- PRZYCISKI DOLNE ---
$btnWszystkie = New-Object System.Windows.Forms.Button
$btnWszystkie.Text = "Zaznacz widoczne"
$btnWszystkie.Location = New-Object System.Drawing.Point(15, 540)
$btnWszystkie.Size = New-Object System.Drawing.Size(118, 32)
$btnWszystkie.Anchor = "Bottom, Left"
$btnWszystkie.Add_Click({
    foreach ($row in $grid.Rows) { $row.Cells[0].Value = $true }
})
$form.Controls.Add($btnWszystkie)

$btnWyczysc = New-Object System.Windows.Forms.Button
$btnWyczysc.Text = "Odznacz widoczne"
$btnWyczysc.Location = New-Object System.Drawing.Point(138, 540)
$btnWyczysc.Size = New-Object System.Drawing.Size(120, 32)
$btnWyczysc.Anchor = "Bottom, Left"
$btnWyczysc.Add_Click({
    foreach ($row in $grid.Rows) { $row.Cells[0].Value = $false }
})
$form.Controls.Add($btnWyczysc)

$btnTrybCichy = New-Object System.Windows.Forms.Button
$btnTrybCichy.Text = "Wszystkie: Cichy"
$btnTrybCichy.Location = New-Object System.Drawing.Point(270, 540)
$btnTrybCichy.Size = New-Object System.Drawing.Size(115, 32)
$btnTrybCichy.Anchor = "Bottom, Left"
$btnTrybCichy.Add_Click({
    foreach ($row in $grid.Rows) {
        $row.Cells[6].Value = "Cichy"
        $row.Tag.Tryb = "Cichy"
    }
})
$form.Controls.Add($btnTrybCichy)

$btnTrybInteraktywny = New-Object System.Windows.Forms.Button
$btnTrybInteraktywny.Text = "Wszystkie: Interaktywny"
$btnTrybInteraktywny.Location = New-Object System.Drawing.Point(390, 540)
$btnTrybInteraktywny.Size = New-Object System.Drawing.Size(145, 32)
$btnTrybInteraktywny.Anchor = "Bottom, Left"
$btnTrybInteraktywny.Add_Click({
    foreach ($row in $grid.Rows) {
        $row.Cells[6].Value = "Interaktywny"
        $row.Tag.Tryb = "Interaktywny"
    }
})
$form.Controls.Add($btnTrybInteraktywny)

$btnZaznaczBezPin = New-Object System.Windows.Forms.Button
$btnZaznaczBezPin.Text = "Zaznacz bez Pin"
$btnZaznaczBezPin.Location = New-Object System.Drawing.Point(540, 540)
$btnZaznaczBezPin.Size = New-Object System.Drawing.Size(105, 32)
$btnZaznaczBezPin.Anchor = "Bottom, Left"
$btnZaznaczBezPin.Add_Click({
    foreach ($a in $aktualizacje) { $a.Zaznaczony = (-not $a.Przypiety) }
    & $odswiezTabele
})
$form.Controls.Add($btnZaznaczBezPin)

# --- PANEL POSTEPU I LOGOW AKTUALIZACJI ---
$panelPostepu = New-Object System.Windows.Forms.Panel
$panelPostepu.Location = New-Object System.Drawing.Point(15, 122)
$panelPostepu.Size = New-Object System.Drawing.Size(973, 403)
$panelPostepu.Anchor = "Top, Bottom, Left, Right"
$panelPostepu.Visible = $false

$lblStatusAktualizacji = New-Object System.Windows.Forms.Label
$lblStatusAktualizacji.Text = "Przygotowanie..."
$lblStatusAktualizacji.Location = New-Object System.Drawing.Point(0, 0)
$lblStatusAktualizacji.Size = New-Object System.Drawing.Size(973, 24)
$lblStatusAktualizacji.Anchor = "Top, Left, Right"
$panelPostepu.Controls.Add($lblStatusAktualizacji)

$pasekPostepu = New-Object System.Windows.Forms.ProgressBar
$pasekPostepu.Location = New-Object System.Drawing.Point(0, 28)
$pasekPostepu.Size = New-Object System.Drawing.Size(973, 22)
$pasekPostepu.Anchor = "Top, Left, Right"
$pasekPostepu.Minimum = 0
$panelPostepu.Controls.Add($pasekPostepu)

$txtLogAktualizacji = New-Object System.Windows.Forms.TextBox
$txtLogAktualizacji.Location = New-Object System.Drawing.Point(0, 58)
$txtLogAktualizacji.Size = New-Object System.Drawing.Size(973, 345)
$txtLogAktualizacji.Anchor = "Top, Bottom, Left, Right"
$txtLogAktualizacji.Multiline = $true
$txtLogAktualizacji.ReadOnly = $true
$txtLogAktualizacji.ScrollBars = "Vertical"
$txtLogAktualizacji.WordWrap = $false
$txtLogAktualizacji.Font = New-Object System.Drawing.Font("Consolas", 9)
$panelPostepu.Controls.Add($txtLogAktualizacji)
$form.Controls.Add($panelPostepu)

$script:aktualizacjaZakonczona = $false
$script:wybraneDoAktualizacji = @()
$script:pozycjaAktualizacji = 0
$script:bladAktualizacji = $false
$script:procesAktualizacji = $null
$script:odczytStdout = $null
$script:odczytStderr = $null

$btnAktualizuj = New-Object System.Windows.Forms.Button
$btnAktualizuj.Text = "Aktualizuj wybrane"
$btnAktualizuj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$btnAktualizuj.BackColor = [System.Drawing.Color]::FromArgb(0, 103, 192)
$btnAktualizuj.ForeColor = [System.Drawing.Color]::White
$btnAktualizuj.FlatStyle = "Flat"
$btnAktualizuj.Location = New-Object System.Drawing.Point(828, 540)
$btnAktualizuj.Size = New-Object System.Drawing.Size(160, 32)
$btnAktualizuj.Anchor = "Bottom, Right"
$btnAktualizuj.Add_Click({
    if ($script:aktualizacjaZakonczona) {
        $form.Close()
        return
    }

    $script:wybraneDoAktualizacji = @($aktualizacje | Where-Object { $_.Zaznaczony -eq $true })
    if ($script:wybraneDoAktualizacji.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Zaznacz co najmniej jeden program.", "Brak wyboru", "OK", "Warning") | Out-Null
        return
    }

    foreach ($kontrolka in @($txtSzukaj, $cmbZrodlo, $cmbPinFiltr, $grid, $btnWszystkie, $btnWyczysc, $btnTrybCichy, $btnTrybInteraktywny, $btnZaznaczBezPin)) {
        $kontrolka.Enabled = $false
    }
    $grid.Visible = $false
    $lblLicznik.Visible = $false
    $panelPostepu.Visible = $true
    $panelPostepu.BringToFront()

    $script:pozycjaAktualizacji = 0
    $script:bladAktualizacji = $false
    $pasekPostepu.Maximum = $script:wybraneDoAktualizacji.Count
    $pasekPostepu.Value = 0
    $txtLogAktualizacji.Clear()
    $btnAktualizuj.Enabled = $false
    $timerAktualizacji.Start()
})
$form.Controls.Add($btnAktualizuj)

$timerAktualizacji = New-Object System.Windows.Forms.Timer
$timerAktualizacji.Interval = 100

$dodajLog = {
    param([string]$wiadomosc)
    if (-not [string]::IsNullOrWhiteSpace($wiadomosc)) {
        $txtLogAktualizacji.AppendText($wiadomosc + [Environment]::NewLine)
    }
}

$uruchomProcesAktualizacji = {
    param([string]$argumenty)

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "winget.exe"
    $startInfo.Arguments = $argumenty
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $proces = New-Object System.Diagnostics.Process
    $proces.StartInfo = $startInfo
    if (-not $proces.Start()) {
        throw "Nie udalo sie uruchomic winget.exe."
    }

    $script:procesAktualizacji = $proces
    $script:odczytStdout = $proces.StandardOutput.ReadLineAsync()
    $script:odczytStderr = $proces.StandardError.ReadLineAsync()
}

$zakonczAktualizacjePakietu = {
    if ($script:procesAktualizacji) {
        $kodWyjscia = $script:procesAktualizacji.ExitCode
        if ($kodWyjscia -eq 0) {
            & $dodajLog "Zakonczono powodzeniem (kod 0)."
        } else {
            & $dodajLog "BLAD: winget zakonczyl sie kodem $kodWyjscia."
            $script:bladAktualizacji = $true
        }
        $script:procesAktualizacji.Dispose()
        $script:procesAktualizacji = $null
    }

    $script:pozycjaAktualizacji++
    $pasekPostepu.Value = [Math]::Min($script:pozycjaAktualizacji, $pasekPostepu.Maximum)
}

$timerAktualizacji.Add_Tick({
    if ($script:procesAktualizacji) {
        foreach ($nazwaStrumienia in @("odczytStdout", "odczytStderr")) {
            $odczyt = Get-Variable -Name $nazwaStrumienia -Scope Script
            if ($odczyt.Value -and $odczyt.Value.IsCompleted) {
                $wiadomosc = $odczyt.Value.Result
                if ($null -eq $wiadomosc) {
                    $odczyt.Value = $null
                } else {
                    & $dodajLog $wiadomosc
                    if ($nazwaStrumienia -eq "odczytStdout") {
                        $script:odczytStdout = $script:procesAktualizacji.StandardOutput.ReadLineAsync()
                    } else {
                        $script:odczytStderr = $script:procesAktualizacji.StandardError.ReadLineAsync()
                    }
                }
            }
        }

        if ($script:procesAktualizacji.HasExited -and -not $script:odczytStdout -and -not $script:odczytStderr) {
            & $zakonczAktualizacjePakietu
        }
        return
    }

    if ($script:pozycjaAktualizacji -ge $script:wybraneDoAktualizacji.Count) {
        $timerAktualizacji.Stop()
        $pasekPostepu.Value = $pasekPostepu.Maximum
        if ($script:bladAktualizacji) {
            $lblStatusAktualizacji.Text = "Zakonczono z bledami. Szczegoly znajduja sie w logu."
        } else {
            $lblStatusAktualizacji.Text = "Wszystkie wybrane aktualizacje zostaly zakonczone."
        }
        $script:aktualizacjaZakonczona = $true
        $btnAktualizuj.Enabled = $true
        $btnAktualizuj.Text = "Zamknij"
        return
    }

    $pakiet = $script:wybraneDoAktualizacji[$script:pozycjaAktualizacji]
    $lblStatusAktualizacji.Text = "Aktualizowanie: $($pakiet.Nazwa)"
    & $dodajLog ""
    & $dodajLog "Aktualizowanie: $($pakiet.Nazwa) ($($pakiet.ObecnaWersja) -> $($pakiet.NowaWersja)) [Zrodlo: $($pakiet.Zrodlo) | Tryb: $($pakiet.Tryb)]"

    try {
        if ($pakiet.Tryb -eq "Cichy") {
            $argumenty = "upgrade --id `"$($pakiet.ID)`" --source `"$($pakiet.Zrodlo)`" -e --silent --accept-package-agreements --accept-source-agreements"
        } else {
            $argumenty = "upgrade --id `"$($pakiet.ID)`" --source `"$($pakiet.Zrodlo)`" -e --interactive --accept-package-agreements --accept-source-agreements"
        }
        if ($pakiet.Przypiety) {
            $argumenty += " --include-pinned"
        }
        & $uruchomProcesAktualizacji $argumenty
    } catch {
        & $dodajLog "BLAD: $($_.Exception.Message)"
        $script:bladAktualizacji = $true
        $script:pozycjaAktualizacji++
        $pasekPostepu.Value = [Math]::Min($script:pozycjaAktualizacji, $pasekPostepu.Maximum)
    }
})

if ($aktualizacje.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("Wszystkie programy sa aktualne lub nie znaleziono dostepnych aktualizacji.", "Informacja", "OK", "Information")
}

[void]$form.ShowDialog()
