### Repository ###
* Link: https://github.com/YankielG/My_Installer

### Information ###
* Version: 1.0
* Author: Grzegorz Jankowicz
* Date: Aug 05, 2026
* Contact: GJ mean, Poland

### Configuration ###
* Using the requirements.txt file to install the necessary dependencies
* Command: pip install -r requirements.txt

### Creating a PIP configuration ###
* pip freeze > requirements.txt

### Description ###
Update verification database

### Instructions ###
Automatic Install and Update

### System requirements ###
* Windows 7/8/10/11

### Generate exe ###
Invoke-PS2EXE -InputFile "D:\NAUKA\Moje_Apk\MY_installer\Installer_advance.ps1" -OutputFile "D:\NAUKA\Moje_Apk\MY_installer\My_Install.exe" -IconFile "D:\NAUKA\Moje_Apk\MY_installer\ikona.ico" -NoConsole -RequireAdmin -Title "My Install" -Version "1.0.0.0"

Invoke-PS2EXE -InputFile "D:\NAUKA\Moje_Apk\MY_installer\Updater_advance.ps1" -OutputFile "D:\NAUKA\Moje_Apk\MY_installer\My_Updater.exe" -IconFile "D:\NAUKA\Moje_Apk\MY_installer\ikona.ico" -NoConsole -RequireAdmin -Title "My Updater" -Version "1.0.0.0"