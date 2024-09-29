#Requires AutoHotkey v2.0

global IniFile := "sample.ini"
global Section := ""
global sectionID := ""
global Key := ""
global Value := ""

global myType := ""
global Options := ""   ; Declare global variables

content := 
(
  "
[General]
Username=JohnDoe
; Type: DropDown
; Options: JohnDoe|John Smith

[Settings]
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

try FileDelete IniFile
FileAppend(content, IniFile)

IniSettingsEditor(IniFile)

IniSettingsEditor(IniFile) {
    mygui := Gui("+Resize")
    mygui.Title := "INI Settings Editor"
    mygui.SetFont("s10", "Consolas")
    
    global treeView := mygui.Add("TreeView", "x16 y16 w200 h300")
    
    ; Create controls for each type but keep them hidden initially
    global dropdown := mygui.Add("DropDownList", "x230 y16 w340 h20 r50")
    dropdown.Visible := false
    dropdown.OnEvent("Change", tv_ValueChanged)

    global checkbox := mygui.Add("Checkbox", "x230 y16 w340 h20", "Enable")
    checkbox.Visible := false
    checkbox.OnEvent("Click", tv_ValueChanged)

    global hotkeyControl := mygui.Add("Hotkey", "x230 y16 w340 h20")
    hotkeyControl.Visible := false
    hotkeyControl.OnEvent("Change", tv_ValueChanged)

    global editControl := mygui.Add("Edit", "x230 y16 w340 h20")
    editControl.Visible := false
    editControl.OnEvent("Change", tv_ValueChanged)


    global dateButton := mygui.add("button", "x580 y16 w60 h20", "Pick Date")
    dateButton.OnEvent("Click", SetDate)
    dateButton.Visible := false

    global fileButton := mygui.Add("Button", "x580 y16 w60 h20", "Select File")
    fileButton.Visible := false
    fileButton.OnEvent("Click", SelectFile)

    global folderButton := mygui.Add("Button", "x580 y40 w60 h20", "Select Folder")
    folderButton.Visible := false
    folderButton.OnEvent("Click", SelectFolder)

    iniContents := FileRead(IniFile)
    
    For line in StrSplit(iniContents, "`n") {
        currLine := Trim(line)
        if (currLine = "") or (InStr(currLine, ";") = 1)
            continue

        if (InStr(currLine, "[") && InStr(currLine, "]")) {
            section := StrReplace(StrReplace(currLine, "[", ""), "]", "")
            sectionID := treeView.Add(section)
        } 
        else if InStr(currLine, "=") {
            pos := InStr(currLine, "=")
            key := Trim(SubStr(currLine, 1, pos - 1))
            treeView.Add(key, sectionID)
        }
    }
    
    treeView.OnEvent("ItemSelect", tv_ItemSelect)
    
    mygui.Show("w660 h360")
}

tv_ItemSelect(GuiCtrlObj, ItemID, *) {
  global
  if (ItemID) {
      sectionID := treeView.GetParent(ItemID)
      if !sectionID {
          dropdown.Visible := false
          checkbox.Visible := false
          hotkeyControl.Visible := false
          editControl.Visible := false
          dateButton.Visible := false
          fileButton.Visible := false
          folderButton.Visible := false
          return
      }
      
      section := treeView.GetText(sectionID)
      key := treeView.GetText(ItemID)
      value := IniRead(IniFile, section, key)
      
      keyComment := GetKeyComments(IniFile, section, key)
      
      if (RegExMatch(keyComment, "Type\s*:\s*(\w+)", &typeMatch)) {
          controlType := typeMatch[1]
          dropdown.Visible := false
          checkbox.Visible := false
          hotkeyControl.Visible := false
          editControl.Visible := false
          dateButton.Visible := false
          fileButton.Visible := false
          folderButton.Visible := false
          
          if (controlType = "DropDown") {
              dropdown.Visible := true
              dropdown.Delete()  ; Deletes the first item (index 0) repeatedly
              if (RegExMatch(keyComment, "Options\s*:\s*(.+)", &optionsMatch)) {
                  options := optionsMatch[1]
                  dropdown.Add(StrSplit(options, "|"))
              }
              dropdown.text := value
          } 
          else if (controlType = "Checkbox") {
              checkbox.Visible := true
              checkbox.Value := (value = "true") ? 1 : 0
          } 
          else if (controlType = "Hotkey") {
              hotkeyControl.Visible := true
              hotkeyControl.Value := value
          } 
          else if (controlType = "File") {
              editControl.Visible := true
              editControl.Value := value
              editControl.Text := "Select File"
              fileButton.Visible := true
          } 
          else if (controlType = "Folder") {
              editControl.Visible := true
              editControl.Value := value
              editControl.Text := "Select Folder"
              folderButton.Visible := true
          } 
          else if (controlType = "Date") {
              editControl.Visible := true
              editControl.Value := value
              dateButton.Visible := true
            
          } 
          else {
              editControl.Visible := true
              editControl.Value := value
          }
      }
  } else {
      dropdown.Visible := false
      checkbox.Visible := false
      hotkeyControl.Visible := false
      editControl.Visible := false
      dateButton.Visible := false
      fileButton.Visible := false
      folderButton.Visible := false
  }
}

SetDate(*){ 
  editcontrol.value := DateStamp()
  tv_ValueChanged()
}

DateStamp() 
{
	DateStampGui := Gui("ToolWindow" , "Get Date Stamp")
	DateStampGui.Add("Text", "" , "Now: " FormatTime(A_Now , "dddd dd MMMM yyyy, HH:mm"))
	DateTimeCtrl := DateStampGui.Add("DateTime" , '' , "yyyy-MM-dd")
	DateStampGui.OnEvent('Escape', DateStampGui.Hide)
	DateStampGui.Show()
	WinWaitClose(DateStampGui)
  originalValue :=  DateTimeCtrl.Value
  year:=SubStr(originalValue, 1, 4)
  month:=SubStr(originalValue, 5, 2)
  day:=SubStr(originalValue, 7, 2)
  myChoice := year . "-" . month . "-" . day
	Return myChoice
}

tv_ValueChanged(*) {
    ItemID := treeView.GetSelection()
    if !ItemID
        return
    Key := treeView.GetText(ItemID)
    sectionID := treeView.GetParent(ItemID)
    section := treeView.GetText(sectionID)

    if dropdown.Visible {
        newValue := dropdown.Text ; Get the selected text
    } else if checkbox.Visible {
        newValue := checkbox.Value ? "true" : "false"
    } else if hotkeyControl.Visible {
        newValue := hotkeyControl.Value
    } else if dateButton.Visible {
        newValue := editControl.Value ; Get the date
    } else {
        newValue := editControl.Value
    }

    IniWrite(newValue, IniFile, section, Key)
}

SelectFile(*) {
    global editControl
    selectedFile := FileSelect( , , "Select a file")
    if (selectedFile) {
        editControl.Value := selectedFile
    }
}

SelectFolder(*) {
    global editControl
    selectedFolder:= FileSelect("D", , "Select a folder")
    if (selectedFolder) {
        editControl.Value := selectedFolder
    }
}

; Function to retrieve comments for a given key in the INI file
GetKeyComments(iniFile, section, key) {
    contents := FileRead(iniFile)
    lines := StrSplit(contents, ["`n","`r"])  ; Split the contents into lines
    isComment := false
    comments := ""

    ; Reset Type and Options
    myType := ""
    Options := ""

    ; Flag to start collecting comments
    for index, line in lines {
        line := Trim(line)  ; Trim whitespace

        ; Check for the section
        if (line = "[" section "]") {
            isComment := false  ; Reset comment flag
            continue
        }

        ; Check for the key
        if (isComment && InStr(line, key "=") > 0) {
            isComment := true  ; Start collecting comments
            continue
        }

        ; Collect comments after the key
        if (InStr(line, key "=")) {
            isComment := true  ; The key has been found
            continue
        }

        ; If the line is a comment and we are in the right section
        if (isComment && InStr(line, ";") = 1) {
            commentLine := SubStr(line, 2)  ; Get comment without the semicolon
            comments .= commentLine . "`n"  ; Append comment

            ; Extract Type and Options from comment lines
            if (RegExMatch(commentLine, "Type\s*:\s*(\w+)", &typeMatch)) {
                myType := typeMatch[1]  ; Set Type variable
            }
            if (RegExMatch(commentLine, "Options\s*:\s*(.+)", &optionsMatch)) {
                Options := optionsMatch[1]  ; Set Options variable
            }
        } else {
            ; Stop if a non-comment line is encountered
            if comments
              break
        }
    }

    return Trim(comments)  ; Return collected comments
}
 
