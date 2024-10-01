#Requires AutoHotkey v2.0

#Include ini-editor_LV_v2.ahk

IniFile := "sample.ini"

IniSettingsEditor(IniFile)

; CreateSampleIni()

CreateSampleIni(){
  try FileDelete IniFile
  
    content := 
    (
    "
    [Normal]
    item=value
    [DropDown]
    Username=JohnDoe
    ; Type: DropDown
    ; Options: JohnDoe|John Smith

    [Checkbox]
    EnableFeature=true
    ; Type: Checkbox

    [Paths]
    FilePath=C:\Some\Path\To\File.txt
    ; Type: File
    FolderPath=C:\Some\Path\To\File
    ; Type: Folder

    [Dates]
    Arrival=01-01-2024
    ; Type: Date

    [Hotkeys]
    thisHotkey=^!K
    ; Type: Hotkey
    "
    )
    FileAppend(content, IniFile)

}