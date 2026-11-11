# Aktualizacja bazy pakietow winget przed wyswietleniem listy
Write-Host "Aktualizowanie listy pakietow winget..." -ForegroundColor Yellow
winget source update

# Lista programow (mozesz dowolnie dopisywac kolejne)
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

    # --- LOKALNE INSTALATORY Z PENDRIVE (folder "Instalki" obok skryptu) ---
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

# Okno wyboru (przytrzymaj CTRL, aby zaznaczyc kilka pozycji)
$wybrane = $programy | Out-GridView -Title "Wybierz programy (CTRL + klikniecie wybiera wiele). Kliknij OK, aby uruchomic instalatory." -PassThru

# Uruchamianie instalatorow jeden po drugim
foreach ($p in $wybrane) {
    Write-Host "`n==========================================" -ForegroundColor DarkGray
    Write-Host "Pobieranie i uruchamianie: $($p.Nazwa)..." -ForegroundColor Cyan
    Write-Host "Przeklikaj kreator instalacji, aby przejsc do nastepnego programu." -ForegroundColor Yellow
    
    winget install --id $p.ID -e --interactive --accept-package-agreements --accept-source-agreements
}

Write-Host "`nWszystkie wybrane instalatory zostaly zakonczone!" -ForegroundColor Green
Pause
