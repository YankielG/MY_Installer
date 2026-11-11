Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $script:sciezkaBazowa = [System.AppDomain]::CurrentDomain.BaseDirectory
} else {
    $script:sciezkaBazowa = $PSScriptRoot
}
$script:sciezkaBazowa = [System.IO.Path]::GetFullPath($script:sciezkaBazowa)

# ==============================================================================
# 1. KONFIGURACJA PROGRAMOW, PLIKOW LOKALNYCH I OPTYMALIZACJI (TWEAKS)
# ==============================================================================
# Typ: "Winget" (pobiera z internetu), "Lokalny" (uruchamia plik .exe / .msi z folderu Instalki\), "Tweak" (zmiana w systemie)
# Tryb: "Interaktywny" (otwiera kreator), "Cichy" (instaluje w tle bez klikania)
# Profile: wpisz nazwy profili po przecinku (np. "Domowy, Programista"), lista w oknie wygeneruje sie sama!

$programy = @(
    # --- PROGRAMY Z WINGET ---
    # Przegladarki i Biuro
    [PSCustomObject]@{ Nazwa = "Google Chrome"; ID = "Google.Chrome"; Kategoria = "Wspolne"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Domowy, Programista, Biuro" },
    [PSCustomObject]@{ Nazwa = "Mozilla Firefox"; ID = "Mozilla.Firefox"; Kategoria = "Wspolne"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "Opera Developer"; ID = "Opera.Opera.Dev"; Kategoria = "Wspolne"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Adobe Acrobat Reader (64-bit)"; ID = "Adobe.Acrobat.Reader.64-bit"; Kategoria = "Biuro"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Domowy, Biuro" },
    [PSCustomObject]@{ Nazwa = "WinRAR"; ID = "RARLab.WinRAR"; Kategoria = "Wspolne"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },

    # Bezpieczenstwo i Narzedzia
    [PSCustomObject]@{ Nazwa = "ESET Security"; ID = "ESET.Security"; Kategoria = "Bezpieczenstwo"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Domowy, Biuro" },
    [PSCustomObject]@{ Nazwa = "VirtualCloneDrive"; ID = "ElaborateBytes.VirtualCloneDrive"; Kategoria = "Narzedzia"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "Raspberry Pi Imager"; ID = "RaspberryPiFoundation.RaspberryPiImager"; Kategoria = "Narzedzia"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Stream Dock (Microsoft Store)"; ID = "XP8LXNJ7R5G8XJ"; Kategoria = "Sprzet"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Programista" },

    # Multimedia i Grafika 3D
    [PSCustomObject]@{ Nazwa = "IrfanView (64-bit)"; ID = "IrfanSkiljan.IrfanView"; Kategoria = "Multimedia"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Biuro" },
    [PSCustomObject]@{ Nazwa = "K-Lite Codec Pack Full"; ID = "CodecGuide.K-LiteCodecPack.Full"; Kategoria = "Multimedia"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Domowy" },
    [PSCustomObject]@{ Nazwa = "VLC Media Player"; ID = "VideoLAN.VLC"; Kategoria = "Multimedia"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Domowy" },
    [PSCustomObject]@{ Nazwa = "STL-Thumb (Miniatury 3D)"; ID = "UnlimitedBacon.STL-Thumb"; Kategoria = "Druk 3D"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "3Dconnexion 3DxWare 10"; ID = "3Dconnexion.3DxWare.10"; Kategoria = "Sprzet"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Dell Display and Peripheral Manager"; ID = "Dell.DisplayAndPeripheralManager"; Kategoria = "Sprzet"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Biuro, Programista" },

    # Programowanie i Srodowiska Uruchomieniowe
    [PSCustomObject]@{ Nazwa = "Git"; ID = "Git.Git"; Kategoria = "Programowanie"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Java SE Development Kit 17"; ID = "Oracle.JDK.17"; Kategoria = "Programowanie"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Python 3.11 (Starsze projekty)"; ID = "Python.Python.3.11"; Kategoria = "Programowanie"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Python (Najnowszy + Manager)"; ID = "9NQ7512CXL7T"; Kategoria = "Programowanie"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Microsoft Visual C++ v14 (x64)"; ID = "Microsoft.VCRedist.2015+.x64"; Kategoria = "Biblioteki"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },
    [PSCustomObject]@{ Nazwa = "Microsoft Visual C++ v14 (x86)"; ID = "Microsoft.VCRedist.2015+.x86"; Kategoria = "Biblioteki"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },
    [PSCustomObject]@{ Nazwa = "Microsoft .NET Desktop Runtime 10"; ID = "Microsoft.DotNet.DesktopRuntime.10"; Kategoria = "Biblioteki"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },
    [PSCustomObject]@{ Nazwa = "Visual Studio Code"; ID = "Microsoft.VisualStudioCode"; Kategoria = "Programowanie"; Typ = "Winget"; Tryb = "Interaktywny"; Profile = "Programista" },

    # --- AUTOMATYCZNE POBIERANIE Z SIECI (SKRYPTY) ---
    [PSCustomObject]@{ Nazwa = "NVIDIA Najnowszy Sterownik (Auto-Download)"; ID = "AUTO_NVIDIA_DRIVER"; Kategoria = "Sprzet"; Typ = "Skrypt"; Tryb = "Interaktywny"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "Microsoft Office LTSC 2024 PL (Auto-Install)"; ID = "AUTO_OFFICE_2024"; Kategoria = "Biuro"; Typ = "Skrypt"; Tryb = "Cichy"; Profile = "Domowy, Biuro" },

    # --- LOKALNE INSTALATORY Z PENDRIVE (folder "Instalki" obok programu) ---
    [PSCustomObject]@{ Nazwa = "Moj Program (.exe)"; ID = "Instalki\setup.exe"; Kategoria = "Lokalne"; Typ = "Lokalny"; Tryb = "Interaktywny"; Profile = "" },
    [PSCustomObject]@{ Nazwa = "Moja Paczka (.msi)"; ID = "Instalki\setup.msi"; Kategoria = "Lokalne"; Typ = "Lokalny"; Tryb = "Cichy"; Profile = "" },

    # --- OPTYMALIZACJE SYSTEMU WINDOWS (TWEAKS) ---
    [PSCustomObject]@{ Nazwa = "Pokaz rozszerzenia znanych plikow"; ID = "TWEAK_EXTENSIONS"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },
    [PSCustomObject]@{ Nazwa = "Klasyczne menu kontekstowe Win 11"; ID = "TWEAK_CLASSIC_MENU"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Pokaz ukryte pliki i foldery"; ID = "TWEAK_HIDDEN_FILES"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Programista" },
    [PSCustomObject]@{ Nazwa = "Tryb ciemny systemu i aplikacji"; ID = "TWEAK_DARK_MODE"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "Oczysc pasek zadan (ukryj Widzety, Czat i Copilot)"; ID = "TWEAK_CLEAN_TASKBAR"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },

    [PSCustomObject]@{ Nazwa = "Wylacz reklamy, sugestie i promowane aplikacje"; ID = "TWEAK_DISABLE_ADS"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },
    [PSCustomObject]@{ Nazwa = "Ogranicz telemetrie Windows do minimum"; ID = "TWEAK_TELEMETRY"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },
    [PSCustomObject]@{ Nazwa = "Usun bloatware (Xbox, Clipchamp, Pogoda, Nowosci, Bing)"; ID = "TWEAK_DEBLOAT_APPS"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Programista, Biuro" },

    [PSCustomObject]@{ Nazwa = "Wylacz aplikacje w tle (oszczednosc RAM i CPU)"; ID = "TWEAK_BG_APPS"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista, Biuro" },
    [PSCustomObject]@{ Nazwa = "Wylacz hibernacje (odzyskaj kilkanascie GB na SSD)"; ID = "TWEAK_DISABLE_HIBERNATE"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "Plan zasilania: Najwyzsza wydajnosc (Ultimate Performance)"; ID = "TWEAK_ULTIMATE_POWER"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "Wylacz przyspieszenie myszy (1:1 dla graczy i pracy)"; ID = "TWEAK_MOUSE_ACCEL"; Kategoria = "Tweakery"; Typ = "Tweak"; Tryb = "Cichy"; Profile = "Domowy, Programista" },

    # --- Sterowniki ---
    [PSCustomObject]@{ Nazwa = "Corsair iCUE 5"; ID = "Corsair.iCUE.5"; Kategoria = "Sprzet"; Typ = "Winget"; Tryb = "Cichy"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "Stream Dock (Auto-Download MSI)"; ID = "AUTO_STREAM_DOCK"; Kategoria = "Sprzet"; Typ = "Skrypt"; Tryb = "Cichy"; Profile = "Domowy, Programista" },
    [PSCustomObject]@{ Nazwa = "Sterowniki MSI MAG Z790 Tomahawk WiFi"; ID = "AUTO_MSI_Z790_TOMAHAWK"; Kategoria = "Sprzet"; Typ = "Skrypt"; Tryb = "Interaktywny"; Profile = "Domowy, Programista" }
)


# Automatyczne utworzenie folderu "Instalki" obok programu, jesli jeszcze nie istnieje
$folderInstalki = Join-Path $script:sciezkaBazowa "Instalki"
if (-not (Test-Path $folderInstalki)) {
    New-Item -ItemType Directory -Path $folderInstalki -Force | Out-Null
}

# Automatyczne wykrycie nowych plikow .exe i .msi wrzuconych do folderu "Instalki", ktorych nie ma jeszcze na liscie
$znaneSciezki = $programy | Where-Object { $_.Typ -eq "Lokalny" } | ForEach-Object { $_.ID.ToLower() }
$plikiLokalne = Get-ChildItem -Path $folderInstalki -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".exe", ".msi" }
foreach ($plik in $plikiLokalne) {
    $wzglednaSciezka = "Instalki\$($plik.Name)"
    if ($znaneSciezki -notcontains $wzglednaSciezka.ToLower()) {
        $programy += [PSCustomObject]@{
            Nazwa = "$($plik.BaseName) (auto-wykryty)"
            ID = $wzglednaSciezka
            Kategoria = "Lokalne"
            Typ = "Lokalny"
            Tryb = "Interaktywny"
            Profile = ""
        }
    }
}

# Domyslnie zaznaczamy profil "Domowy" na start
foreach ($p in $programy) {
    $listaProf = $p.Profile -split "," | ForEach-Object { $_.Trim() }
    $domyslnie = $listaProf -contains "Domowy"
    $p | Add-Member -MemberType NoteProperty -Name "Zaznaczony" -Value $domyslnie
}

# ==============================================================================
# 2. INTERFEJS GRAFICZNY (OKNO, LOGO, IKONA, LISTA PROFILI, TABELA)
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "My Installer PRO - GJ mean"
$form.Size = New-Object System.Drawing.Size(960, 630)
$form.MinimumSize = New-Object System.Drawing.Size(860, 480)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "Sizable"
$form.MaximizeBox = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

# Ikona okna
$sciezkaIkony = Join-Path $script:sciezkaBazowa "ikona.ico"
if (Test-Path $sciezkaIkony) {
    $form.Icon = New-Object System.Drawing.Icon($sciezkaIkony)
} else {
    $form.Icon = [System.Drawing.SystemIcons]::Shield
}

# Logo obok tytulu
$przesuniecieX = 15
$sciezkaLogo = Join-Path $script:sciezkaBazowa "logo.jpg"
if (-not (Test-Path $sciezkaLogo)) { $sciezkaLogo = Join-Path $script:sciezkaBazowa "logo.png" }

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
$lblTytul.Text = "My Installer PRO"
$lblTytul.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTytul.Location = New-Object System.Drawing.Point($przesuniecieX, 12)
$lblTytul.AutoSize = $true
$form.Controls.Add($lblTytul)

$lblOpis = New-Object System.Windows.Forms.Label
$lblOpis.Text = "Wybierz gotowy profil lub zaznacz pozycje recznie. Wlasne pliki .exe/.msi wrzuc do folderu Instalki obok programu."
$lblOpis.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblOpis.ForeColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$lblOpis.Location = New-Object System.Drawing.Point($przesuniecieX, 45)
$lblOpis.AutoSize = $true
$form.Controls.Add($lblOpis)

# --- ROZWIJANA LISTA PROFILI (PRESETOW) ---
$lblProfile = New-Object System.Windows.Forms.Label
$lblProfile.Text = "Profil:"
$lblProfile.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblProfile.Location = New-Object System.Drawing.Point(15, 83)
$lblProfile.AutoSize = $true
$form.Controls.Add($lblProfile)

$cmbProfil = New-Object System.Windows.Forms.ComboBox
$cmbProfil.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$cmbProfil.Location = New-Object System.Drawing.Point(115, 80)
$cmbProfil.Size = New-Object System.Drawing.Size(220, 24)
$cmbProfil.DropDownStyle = "DropDownList"
$cmbProfil.Items.Add("-- Wybierz profil (lub recznie) --") | Out-Null

$unikalneProfile = @()
foreach ($p in $programy) {
    if (-not [string]::IsNullOrWhiteSpace($p.Profile)) {
        $czesci = $p.Profile -split "," | ForEach-Object { $_.Trim() }
        foreach ($c in $czesci) {
            if ($c -ne "" -and ($unikalneProfile -notcontains $c)) {
                $unikalneProfile += $c
            }
        }
    }
}
foreach ($prof in $unikalneProfile) {
    $cmbProfil.Items.Add($prof) | Out-Null
}

if ($cmbProfil.Items.Contains("Domowy")) {
    $cmbProfil.SelectedItem = "Domowy"
} else {
    $cmbProfil.SelectedIndex = 0
}
$form.Controls.Add($cmbProfil)

# Przycisk otwierajacy folder Instalki
$btnFolderInstalki = New-Object System.Windows.Forms.Button
$btnFolderInstalki.Text = "Folder Instalki"
$btnFolderInstalki.Location = New-Object System.Drawing.Point(618, 79)
$btnFolderInstalki.Size = New-Object System.Drawing.Size(105, 27)
$btnFolderInstalki.Anchor = "Top, Right"
$btnFolderInstalki.Add_Click({
    Start-Process "explorer.exe" -ArgumentList $folderInstalki
})
$form.Controls.Add($btnFolderInstalki)

# Przyciski Zapisz / Wczytaj wybor (JSON)
$btnZapisz = New-Object System.Windows.Forms.Button
$btnZapisz.Text = "Zapisz wybor"
$btnZapisz.Location = New-Object System.Drawing.Point(728, 79)
$btnZapisz.Size = New-Object System.Drawing.Size(98, 27)
$btnZapisz.Anchor = "Top, Right"
$btnZapisz.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "Plik konfiguracji (*.json)|*.json"
    $sfd.InitialDirectory = $script:sciezkaBazowa
    $sfd.FileName = "moj_zestaw.json"
    if ($sfd.ShowDialog() -eq "OK") {
        $doZapisu = $programy | Select-Object ID, Zaznaczony, Tryb
        $doZapisu | ConvertTo-Json | Out-File -FilePath $sfd.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Zapisano konfiguracje!", "Sukces", "OK", "Information")
    }
})
$form.Controls.Add($btnZapisz)

$btnWczytaj = New-Object System.Windows.Forms.Button
$btnWczytaj.Text = "Wczytaj wybor"
$btnWczytaj.Location = New-Object System.Drawing.Point(830, 79)
$btnWczytaj.Size = New-Object System.Drawing.Size(98, 27)
$btnWczytaj.Anchor = "Top, Right"
$btnWczytaj.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Plik konfiguracji (*.json)|*.json"
    $ofd.InitialDirectory = $script:sciezkaBazowa
    if ($ofd.ShowDialog() -eq "OK") {
        $wczytane = Get-Content -Path $ofd.FileName -Raw | ConvertFrom-Json
        foreach ($p in $programy) {
            $dopasowanie = $wczytane | Where-Object { $_.ID -eq $p.ID }
            if ($dopasowanie) {
                $p.Zaznaczony = [bool]$dopasowanie.Zaznaczony
                $p.Tryb = $dopasowanie.Tryb
            } else {
                $p.Zaznaczony = $false
            }
        }
        $cmbProfil.SelectedIndex = 0
        & $odswiezTabele
    }
})
$form.Controls.Add($btnWczytaj)

# --- FILTRY ---
$lblSzukaj = New-Object System.Windows.Forms.Label
$lblSzukaj.Text = "Szukaj:"
$lblSzukaj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSzukaj.Location = New-Object System.Drawing.Point(15, 119)
$lblSzukaj.AutoSize = $true
$form.Controls.Add($lblSzukaj)

$txtSzukaj = New-Object System.Windows.Forms.TextBox
$txtSzukaj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$txtSzukaj.Location = New-Object System.Drawing.Point(65, 116)
$txtSzukaj.Size = New-Object System.Drawing.Size(570, 24)
$txtSzukaj.Anchor = "Top, Left, Right"
$form.Controls.Add($txtSzukaj)

$lblKat = New-Object System.Windows.Forms.Label
$lblKat.Text = "Kategoria:"
$lblKat.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblKat.Location = New-Object System.Drawing.Point(650, 119)
$lblKat.AutoSize = $true
$lblKat.Anchor = "Top, Right"
$form.Controls.Add($lblKat)

$cmbKategoria = New-Object System.Windows.Forms.ComboBox
$cmbKategoria.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$cmbKategoria.Location = New-Object System.Drawing.Point(720, 116)
$cmbKategoria.Size = New-Object System.Drawing.Size(208, 24)
$cmbKategoria.DropDownStyle = "DropDownList"
$cmbKategoria.Anchor = "Top, Right"
$cmbKategoria.Items.Add("Wszystkie") | Out-Null
$cmbKategoria.Items.Add("Tweakery") | Out-Null
$cmbKategoria.Items.Add("Programy") | Out-Null

$kategorie = $programy | Where-Object { $_.Typ -ne "Tweak" } | Select-Object -ExpandProperty Kategoria -Unique
foreach ($k in $kategorie) {
    if ($cmbKategoria.Items -notcontains $k) { $cmbKategoria.Items.Add($k) | Out-Null }
}
$cmbKategoria.SelectedItem = "Programy"
$form.Controls.Add($cmbKategoria)

# --- TABELA ---
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(15, 150)
$grid.Size = New-Object System.Drawing.Size(913, 375)
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
$colZaznacz.FillWeight = 9
$grid.Columns.Add($colZaznacz) | Out-Null

$colNazwa = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colNazwa.Name = "Nazwa"
$colNazwa.HeaderText = "Nazwa pozycji"
$colNazwa.ReadOnly = $true
$colNazwa.FillWeight = 27
$grid.Columns.Add($colNazwa) | Out-Null

$colKat = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colKat.Name = "Kategoria"
$colKat.HeaderText = "Kategoria"
$colKat.ReadOnly = $true
$colKat.FillWeight = 16
$grid.Columns.Add($colKat) | Out-Null

$colTyp = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colTyp.Name = "Typ"
$colTyp.HeaderText = "Zrodlo"
$colTyp.ReadOnly = $true
$colTyp.FillWeight = 11
$grid.Columns.Add($colTyp) | Out-Null

$colTryb = New-Object System.Windows.Forms.DataGridViewComboBoxColumn
$colTryb.Name = "Tryb"
$colTryb.HeaderText = "Tryb (kliknij)"
$colTryb.Items.AddRange("Interaktywny", "Cichy")
$colTryb.FillWeight = 15
$colTryb.DisplayStyle = "DropDownButton"
$grid.Columns.Add($colTryb) | Out-Null

$colID = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colID.Name = "ID"
$colID.HeaderText = "ID / Sciezka pliku"
$colID.ReadOnly = $true
$colID.FillWeight = 22
$grid.Columns.Add($colID) | Out-Null

$form.Controls.Add($grid)

# Etykieta licznika zaznaczonych na dole
$lblLicznik = New-Object System.Windows.Forms.Label
$lblLicznik.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblLicznik.ForeColor = [System.Drawing.Color]::FromArgb(0, 103, 192)
$lblLicznik.Location = New-Object System.Drawing.Point(650, 545)
$lblLicznik.Size = New-Object System.Drawing.Size(110, 25)
$lblLicznik.TextAlign = "MiddleRight"
$lblLicznik.Anchor = "Bottom, Right"
$form.Controls.Add($lblLicznik)

$aktualizujLicznik = {
    $ile = ($programy | Where-Object { $_.Zaznaczony -eq $true }).Count
    $lblLicznik.Text = "Wybrano: $ile"
}

$grid.Add_CurrentCellDirtyStateChanged({
    if ($grid.IsCurrentCellDirty) {
        $grid.CommitEdit([System.Windows.Forms.DataGridViewDataErrorContexts]::Commit)
    }
})

$grid.Add_CellValueChanged({
    param($sender, $e)
    if ($e.RowIndex -ge 0) {
        $prog = $grid.Rows[$e.RowIndex].Tag
        if ($e.ColumnIndex -eq 0) {
            $prog.Zaznaczony = [bool]$grid.Rows[$e.RowIndex].Cells[0].Value
            & $aktualizujLicznik
        }
        if ($e.ColumnIndex -eq 4) {
            $prog.Tryb = $grid.Rows[$e.RowIndex].Cells[4].Value.ToString()
        }
    }
})

$odswiezTabele = {
    $grid.Rows.Clear()
    $szukanyTekst = $txtSzukaj.Text.ToLower()
    $wybranaKat = $cmbKategoria.SelectedItem.ToString()

    foreach ($p in $programy) {
        $pasujeTekst = ($p.Nazwa.ToLower().Contains($szukanyTekst)) -or ($p.ID.ToLower().Contains($szukanyTekst))
        $pasujeKat = switch ($wybranaKat) {
            "Wszystkie" { $true }
            "Programy" { $p.Typ -ne "Tweak" }
            "Tweakery" { $p.Typ -eq "Tweak" }
            default { $p.Kategoria -eq $wybranaKat }
        }

        if ($pasujeTekst -and $pasujeKat) {
            $idx = $grid.Rows.Add($p.Zaznaczony, $p.Nazwa, $p.Kategoria, $p.Typ, $p.Tryb, $p.ID)
            $grid.Rows[$idx].Tag = $p

            # Podswietlenie na lekko zielono/szaro jesli lokalny plik fizycznie istnieje/nie istnieje
            if ($p.Typ -eq "Lokalny") {
                $pelnaSciezka = Join-Path $script:sciezkaBazowa $p.ID
                if (Test-Path $pelnaSciezka) {
                    $grid.Rows[$idx].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(238, 250, 238)
                } else {
                    $grid.Rows[$idx].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gray
                }
            }
        }
    }
    & $aktualizujLicznik
}

# Reakcja na zmiane profilu z listy
$cmbProfil.Add_SelectedIndexChanged({
    if ($cmbProfil.SelectedIndex -gt 0) {
        $wybranyProf = $cmbProfil.SelectedItem.ToString()
        foreach ($p in $programy) {
            $listaProf = $p.Profile -split "," | ForEach-Object { $_.Trim() }
            $p.Zaznaczony = ($listaProf -contains $wybranyProf)
        }
        & $odswiezTabele
    }
})

$txtSzukaj.Add_TextChanged($odswiezTabele)
$cmbKategoria.Add_SelectedIndexChanged($odswiezTabele)
& $odswiezTabele

# --- PRZYCISKI DOLNE (ZAZNACZANIE I MASOWA ZMIANA TRYBU) ---
$btnWszystkie = New-Object System.Windows.Forms.Button
$btnWszystkie.Text = "Zaznacz widoczne"
$btnWszystkie.Location = New-Object System.Drawing.Point(15, 540)
$btnWszystkie.Size = New-Object System.Drawing.Size(115, 32)
$btnWszystkie.Anchor = "Bottom, Left"
$btnWszystkie.Add_Click({
    foreach ($row in $grid.Rows) { $row.Cells[0].Value = $true }
})
$form.Controls.Add($btnWszystkie)

$btnWyczysc = New-Object System.Windows.Forms.Button
$btnWyczysc.Text = "Odznacz widoczne"
$btnWyczysc.Location = New-Object System.Drawing.Point(135, 540)
$btnWyczysc.Size = New-Object System.Drawing.Size(118, 32)
$btnWyczysc.Anchor = "Bottom, Left"
$btnWyczysc.Add_Click({
    foreach ($row in $grid.Rows) { $row.Cells[0].Value = $false }
})
$form.Controls.Add($btnWyczysc)

$btnOdznaczWszystko = New-Object System.Windows.Forms.Button
$btnOdznaczWszystko.Text = "Wyczysc wszystko"
$btnOdznaczWszystko.Location = New-Object System.Drawing.Point(258, 540)
$btnOdznaczWszystko.Size = New-Object System.Drawing.Size(115, 32)
$btnOdznaczWszystko.Anchor = "Bottom, Left"
$btnOdznaczWszystko.Add_Click({
    foreach ($p in $programy) { $p.Zaznaczony = $false }
    $cmbProfil.SelectedIndex = 0
    & $odswiezTabele
})
$form.Controls.Add($btnOdznaczWszystko)

# Masowa zmiana trybu na Cichy (dla widocznych wierszy)
$btnTrybCichy = New-Object System.Windows.Forms.Button
$btnTrybCichy.Text = "Wszystkie: Cichy"
$btnTrybCichy.Location = New-Object System.Drawing.Point(385, 540)
$btnTrybCichy.Size = New-Object System.Drawing.Size(110, 32)
$btnTrybCichy.Anchor = "Bottom, Left"
$btnTrybCichy.Add_Click({
    foreach ($row in $grid.Rows) {
        $row.Cells[4].Value = "Cichy"
        $row.Tag.Tryb = "Cichy"
    }
})
$form.Controls.Add($btnTrybCichy)

# Masowa zmiana trybu na Interaktywny (dla widocznych wierszy)
$btnTrybInteraktywny = New-Object System.Windows.Forms.Button
$btnTrybInteraktywny.Text = "Wszystkie: Interaktywny"
$btnTrybInteraktywny.Location = New-Object System.Drawing.Point(500, 540)
$btnTrybInteraktywny.Size = New-Object System.Drawing.Size(140, 32)
$btnTrybInteraktywny.Anchor = "Bottom, Left"
$btnTrybInteraktywny.Add_Click({
    foreach ($row in $grid.Rows) {
        $row.Cells[4].Value = "Interaktywny"
        $row.Tag.Tryb = "Interaktywny"
    }
})
$form.Controls.Add($btnTrybInteraktywny)

# 3. INSTALACJA Z PASKIEM POSTEPU I LOGIEM W OKNIE
$panelPostepu = New-Object System.Windows.Forms.Panel
$panelPostepu.Location = New-Object System.Drawing.Point(15, 150)
$panelPostepu.Size = New-Object System.Drawing.Size(913, 422)
$panelPostepu.Anchor = "Top, Bottom, Left, Right"
$panelPostepu.Visible = $false

$lblStatusInstalacji = New-Object System.Windows.Forms.Label
$lblStatusInstalacji.Text = "Przygotowanie..."
$lblStatusInstalacji.Location = New-Object System.Drawing.Point(0, 0)
$lblStatusInstalacji.Size = New-Object System.Drawing.Size(913, 24)
$lblStatusInstalacji.Anchor = "Top, Left, Right"
$panelPostepu.Controls.Add($lblStatusInstalacji)

$pasekPostepu = New-Object System.Windows.Forms.ProgressBar
$pasekPostepu.Location = New-Object System.Drawing.Point(0, 28)
$pasekPostepu.Size = New-Object System.Drawing.Size(913, 22)
$pasekPostepu.Anchor = "Top, Left, Right"
$pasekPostepu.Minimum = 0
$panelPostepu.Controls.Add($pasekPostepu)

$txtLogInstalacji = New-Object System.Windows.Forms.TextBox
$txtLogInstalacji.Location = New-Object System.Drawing.Point(0, 58)
$txtLogInstalacji.Size = New-Object System.Drawing.Size(913, 364)
$txtLogInstalacji.Anchor = "Top, Bottom, Left, Right"
$txtLogInstalacji.Multiline = $true
$txtLogInstalacji.ReadOnly = $true
$txtLogInstalacji.ScrollBars = "Vertical"
$txtLogInstalacji.WordWrap = $false
$txtLogInstalacji.Font = New-Object System.Drawing.Font("Consolas", 9)
$panelPostepu.Controls.Add($txtLogInstalacji)
$form.Controls.Add($panelPostepu)

$btnInstaluj = New-Object System.Windows.Forms.Button
$btnInstaluj.Text = "Zainstaluj wybrane"
$btnInstaluj.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$btnInstaluj.BackColor = [System.Drawing.Color]::FromArgb(0, 103, 192)
$btnInstaluj.ForeColor = [System.Drawing.Color]::White
$btnInstaluj.FlatStyle = "Flat"
$btnInstaluj.Location = New-Object System.Drawing.Point(778, 540)
$btnInstaluj.Size = New-Object System.Drawing.Size(150, 32)
$btnInstaluj.Anchor = "Bottom, Right"
$btnInstaluj.Add_Click({
    if ($script:instalacjaZakonczona) {
        $form.Close()
        return
    }

    $script:wybraneDoInstalacji = @($programy | Where-Object { $_.Zaznaczony -eq $true })
    if ($script:wybraneDoInstalacji.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Zaznacz co najmniej jedna pozycje.", "Brak wyboru", "OK", "Warning") | Out-Null
        return
    }

    $przyciskiWyboru = @(
        $btnFolderInstalki, $btnZapisz, $btnWczytaj, $btnWszystkie, $btnWyczysc,
        $btnOdznaczWszystko, $btnTrybCichy, $btnTrybInteraktywny, $btnInstaluj
    )
    foreach ($kontrolka in $przyciskiWyboru) { $kontrolka.Enabled = $false }
    $cmbProfil.Enabled = $false
    $txtSzukaj.Enabled = $false
    $cmbKategoria.Enabled = $false
    $grid.Visible = $false
    $lblLicznik.Visible = $false
    $panelPostepu.Visible = $true
    $panelPostepu.BringToFront()

    $script:pozycjaInstalacji = 0
    $script:restartExplorera = $false
    $script:bladInstalacji = $false
    $script:zadaniaInstalacji = @()
    if (@($script:wybraneDoInstalacji | Where-Object { $_.Typ -eq "Winget" }).Count -gt 0) {
        $script:zadaniaInstalacji += [PSCustomObject]@{ Typ = "WingetSource"; Program = $null }
    }
    foreach ($wybranyProgram in $script:wybraneDoInstalacji) {
        $script:zadaniaInstalacji += [PSCustomObject]@{ Typ = $wybranyProgram.Typ; Program = $wybranyProgram }
    }

    $pasekPostepu.Maximum = $script:zadaniaInstalacji.Count
    $pasekPostepu.Value = 0
    $txtLogInstalacji.Clear()
    $script:procesInstalacji = $null
    $script:odczytStdout = $null
    $script:odczytStderr = $null
    $script:aktualneZadanie = $null
    $timerInstalacji.Start()
})
$form.Controls.Add($btnInstaluj)

$timerInstalacji = New-Object System.Windows.Forms.Timer
$timerInstalacji.Interval = 100

$dodajLog = {
    param([string]$wiadomosc)
    if (-not [string]::IsNullOrWhiteSpace($wiadomosc)) {
        $txtLogInstalacji.AppendText($wiadomosc + [Environment]::NewLine)
    }
}

$uruchomProcesInstalacji = {
    param([string]$plik, [string]$argumenty)

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $plik
    $startInfo.Arguments = $argumenty
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $proces = New-Object System.Diagnostics.Process
    $proces.StartInfo = $startInfo
    if (-not $proces.Start()) {
        throw "Nie udalo sie uruchomic procesu: $plik"
    }

    $script:procesInstalacji = $proces
    $script:odczytStdout = $proces.StandardOutput.ReadLineAsync()
    $script:odczytStderr = $proces.StandardError.ReadLineAsync()
}

$zakonczZadanie = {
    if ($script:procesInstalacji) {
        $kodWyjscia = $script:procesInstalacji.ExitCode
        if ($kodWyjscia -eq 0) {
            & $dodajLog "Zakonczono powodzeniem (kod 0)."
        } else {
            & $dodajLog "BLAD: proces zakonczyl sie kodem $kodWyjscia."
            $script:bladInstalacji = $true
        }
        $script:procesInstalacji.Dispose()
        $script:procesInstalacji = $null
    }

    $script:pozycjaInstalacji++
    $pasekPostepu.Value = [Math]::Min($script:pozycjaInstalacji, $pasekPostepu.Maximum)
    $script:aktualneZadanie = $null
}

$timerInstalacji.Add_Tick({
    if ($script:procesInstalacji) {
        foreach ($nazwaStrumienia in @("odczytStdout", "odczytStderr")) {
            $odczyt = Get-Variable -Name $nazwaStrumienia -Scope Script
            if ($odczyt.Value -and $odczyt.Value.IsCompleted) {
                $wiadomosc = $odczyt.Value.Result
                if ($null -eq $wiadomosc) {
                    $odczyt.Value = $null
                } else {
                    & $dodajLog $wiadomosc
                    if ($nazwaStrumienia -eq "odczytStdout") {
                        $script:odczytStdout = $script:procesInstalacji.StandardOutput.ReadLineAsync()
                    } else {
                        $script:odczytStderr = $script:procesInstalacji.StandardError.ReadLineAsync()
                    }
                }
            }
        }

        if ($script:procesInstalacji.HasExited -and -not $script:odczytStdout -and -not $script:odczytStderr) {
            & $zakonczZadanie
        }
        return
    }

    if ($script:pozycjaInstalacji -ge $script:zadaniaInstalacji.Count) {
        $timerInstalacji.Stop()
        if ($script:restartExplorera) {
            & $dodajLog "Restartowanie Eksploratora Windows..."
            Stop-Process -Name explorer -Force
        }
        $pasekPostepu.Value = $pasekPostepu.Maximum
        if ($script:bladInstalacji) {
            $lblStatusInstalacji.Text = "Zakonczono z bledami. Szczegoly znajduja sie w logu."
        } else {
            $lblStatusInstalacji.Text = "Wszystkie wybrane operacje zostaly zakonczone."
        }
        $script:instalacjaZakonczona = $true
        $btnInstaluj.Enabled = $true
        $btnInstaluj.Text = "Zamknij"
        return
    }

    $zadanie = $script:zadaniaInstalacji[$script:pozycjaInstalacji]
    $script:aktualneZadanie = $zadanie
    $pasekPostepu.Value = [Math]::Min($script:pozycjaInstalacji, $pasekPostepu.Maximum)

    try {
        if ($zadanie.Typ -eq "WingetSource") {
            $lblStatusInstalacji.Text = "Aktualizowanie zrodel winget..."
            & $dodajLog "Aktualizowanie zrodel winget..."
            & $uruchomProcesInstalacji "winget.exe" "source update"
            return
        }

        $p = $zadanie.Program
        $lblStatusInstalacji.Text = "Przetwarzanie: $($p.Nazwa)"
        & $dodajLog ""
        & $dodajLog "Przetwarzanie: $($p.Nazwa) [$($p.Typ) | $($p.Tryb)]"

        if ($p.Typ -eq "Winget") {
            if ($p.Tryb -eq "Cichy") {
                $argumenty = "install --id `"$($p.ID)`" -e --silent --accept-package-agreements --accept-source-agreements"
            } else {
                $argumenty = "install --id `"$($p.ID)`" -e --interactive --accept-package-agreements --accept-source-agreements"
            }
            & $uruchomProcesInstalacji "winget.exe" $argumenty
            return
        }

        if ($p.Typ -eq "Lokalny") {
            $pelnaSciezka = Join-Path $script:sciezkaBazowa $p.ID
            if (-not (Test-Path $pelnaSciezka)) {
                throw "Nie znaleziono pliku: $pelnaSciezka"
            }

            $rozszerzenie = [System.IO.Path]::GetExtension($pelnaSciezka).ToLower()
            if ($rozszerzenie -eq ".msi") {
                if ($p.Tryb -eq "Cichy") {
                    $argumenty = "/i `"$pelnaSciezka`" /qn /norestart"
                } else {
                    $argumenty = "/i `"$pelnaSciezka`""
                }
                & $uruchomProcesInstalacji "msiexec.exe" $argumenty
            } else {
                if ($p.Tryb -eq "Cichy") {
                    $argumenty = "/S /silent /quiet /verysilent"
                } else {
                    $argumenty = ""
                }
                & $uruchomProcesInstalacji $pelnaSciezka $argumenty
            }
            return
        }

        if ($p.Typ -eq "Tweak") {
            switch ($p.ID) {
                "TWEAK_EXTENSIONS" {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -ErrorAction Stop
                    & $dodajLog "Wlaczono pokazywanie rozszerzen plikow."
                    $script:restartExplorera = $true
                }
                "TWEAK_CLASSIC_MENU" {
                    $sciezkaMenu = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
                    New-Item -Path $sciezkaMenu -Force -ErrorAction Stop | Out-Null
                    Set-ItemProperty -Path $sciezkaMenu -Name "(Default)" -Value "" -ErrorAction Stop
                    & $dodajLog "Przywrocono klasyczne menu kontekstowe Windows 11."
                    $script:restartExplorera = $true
                }
                "TWEAK_HIDDEN_FILES" {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -ErrorAction Stop
                    & $dodajLog "Wlaczono pokazywanie ukrytych plikow."
                    $script:restartExplorera = $true
                }
                default {
                    throw "Nieznany tweak: $($p.ID)"
                }
            }
            & $zakonczZadanie
            return
        }

        throw "Nieznany typ pozycji: $($p.Typ)"
    } catch {
        & $dodajLog "BLAD: $($_.Exception.Message)"
        $script:bladInstalacji = $true
        & $zakonczZadanie
    }
})

[void]$form.ShowDialog()
if ($script:procesInstalacji) {
    $script:procesInstalacji.Dispose()
}
