#Requires AutoHotkey v2.0

global Ini := ""
global sectionID := ""
global Key := ""
global Value := ""

global myType := ""
global Options := ""   ; Declare global variables

IniSettingsEditor(inifile) {
    global ini := inifile
    global mygui := Gui("+Resize")
    mygui.Title := "INI Settings Editor"
    mygui.SetFont("s12", "Consolas")
    mygui.Title := "Editing: " ini
    
    ; Declare GUI components as global and initialize them
    

    listboxLabel := mygui.Add("Text","x16","Sections")
    global ListBox := mygui.Add("ListBox", "x16 w200 h360", [])

    editLabel := mygui.Add("Text","ys","Edit value")

    global dropdown := mygui.Add("DropDownList", "x230 y34 w340 h20 r50")
    dropdown.Visible := false
    dropdown.OnEvent("Change", lv_ValueChanged)

    global checkbox := mygui.Add("Checkbox", "x230 y34 w340 h20", "Enable")
    checkbox.Visible := false
    checkbox.OnEvent("Click", lv_ValueChanged)

    global hotkeyControl := mygui.Add("Hotkey", "x230 y34 w340 h20")
    hotkeyControl.Visible := false
    hotkeyControl.OnEvent("Change", lv_ValueChanged)

    global editControl := mygui.Add("Edit", "x230 y34 w440 h20")
    editControl.Visible := false
    editControl.OnEvent("Change", lv_ValueChanged)

    global dateButton := mygui.Add("Button", "x230 y62 w120 h20", "Pick Date")
    dateButton.OnEvent("Click", SetDate)
    dateButton.Visible := false

    global fileButton := mygui.Add("Button", "x230 y62 w120 h20", "Select File")
    fileButton.Visible := false
    fileButton.OnEvent("Click", SelectFile)

    global folderButton := mygui.Add("Button", "x230 y62 w120 h20", "Select Folder")
    folderButton.Visible := false
    folderButton.OnEvent("Click", SelectFolder)

    global listView := mygui.Add("ListView", "x230 y92 w440 h300", ["Type", "Key", "Value"])
    
    ; Load the contents of the INI file
    iniContents := FileRead(ini)
    
    ; Parse the INI file contents and populate sections in the ListBox
    currentSection := ""
    for line in StrSplit(iniContents, "`n") {
        currLine := Trim(line)
        if (currLine = "") || (InStr(currLine, ";") = 1)
            continue

        if (InStr(currLine, "[") && InStr(currLine, "]")) {
            currentSection := StrReplace(StrReplace(currLine, "[", ""), "]", "")
            if (currentSection != "") {
                ListBox.Add([currentSection])  ; Add section names to the ListBox
            }
        }
    }

    ; Attach the event handlers to relevant components
    ListBox.OnEvent("Change", LoadSectionKeys)
    listView.OnEvent("ItemSelect", lv_ItemClick)

    listBoxFirstChoice()

    mygui.OnEvent("Size",Gui_Size)
    mygui.Show("w700 h400")
}

Gui_Size(GuiObj, MinMax, Width, Height){
global
MyGui.GetClientPos(,, &Width, &Height)

listView.GetPos(&X,&Y,&W,&H)
listview.move(,,width - X - 15)

editControl.GetPos(&X,&Y,&W,&H)
editControl.move(,,width - X - 15)
}

listBoxFirstChoice(*){
    global
    listbox.Choose(1)
    LoadSectionKeys()
}
listViewFirstChoice(*){
    global
    listView.Modify(1,"select focus")
    lv_ItemClick()
    listView.Focus
}

LoadSectionKeys(*) {
    global 
    listView.delete()  ; Clear previous keys
    selectedSection := ListBox.text

    iniContents := FileRead(ini)  ; Read the INI file again
    currentSection := ""
    for line in StrSplit(iniContents, "`n") {
        currLine := Trim(line)
        if (currLine = "") || (InStr(currLine, ";") = 1)
            continue

        if (InStr(currLine, "[") && InStr(currLine, "]")) {
            currentSection := StrReplace(StrReplace(currLine, "[", ""), "]", "")
        } 
        else if InStr(currLine, "=") {
            pos := InStr(currLine, "=")
            key := Trim(SubStr(currLine, 1, pos - 1))
            value := Trim(SubStr(currLine, pos + 1))
            if (currentSection == selectedSection) {  ; Only add keys from the selected section
                mytype := DetectType(selectedSection, key)
                listView.Add(, mytype, key, value)  ; Add type, key, value
            }
        }
    }
    listview.ModifyCol(1,"autohdr")
    listview.ModifyCol(2,"autohdr")
    listview.ModifyCol(3,"autohdr")
    listViewFirstChoice()
    mygui.show("AutoSize")
    
}
DetectType(section, key) {
    ; Read the key comments to determine the type
    keyComment := GetKeyComments(ini, section, key)  ; Get the comment after the key
    
    ; Use regex to extract the "Type" from the comment
    if (RegExMatch(keyComment, "Type\s*:\s*(\w+)", &typeMatch)) {
        return typeMatch[1]
    }
    return ""  ; Return empty if no type is found
}



lv_ItemClick(*) {
    global 
    RowNumber := 0
    RowNumber := listView.GetNext(RowNumber)
    if !RowNumber
        return
    Key := listView.gettext(RowNumber,2)
    if Key {
        section := ListBox.text  ; Get the current section
        keyComment := GetKeyComments(ini, section, key)
        ShowEditControl(key, section, keyComment)
    }
}

ShowEditControl(key, section, keyComment) {
    global 
    HideAllControls()
    value := IniRead(ini,section,key)
    if (RegExMatch(keyComment, "Type\s*:\s*(\w+)", &typeMatch)) {
        controlType := typeMatch[1]

        if (controlType = "DropDown") {
            dropdown.Visible := true
            dropdown.Delete()  ; Clear existing items
            if (RegExMatch(keyComment, "Options\s*:\s*(.+)", &optionsMatch)) {
                Options := optionsMatch[1]
                dropdown.Add(StrSplit(Options, "|"))
            }
            dropdown.Text := IniRead(ini,section,key)
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
            fileButton.Visible := true
        } 
        else if (controlType = "Folder") {
            editControl.Visible := true
            editControl.Value := value
            folderButton.Visible := true
        } 
        else if (controlType = "Date") {
            editControl.Visible := true
            editControl.Value := value
            dateButton.Visible := true
        }
    } else {
    editControl.Visible := true
    editControl.Value := value
    }
}

lv_ValueChanged(*) {
    global 
    RowNumber := 0
    RowNumber := listView.GetNext(RowNumber)
    if !RowNumber
        return
    Key := listView.gettext(RowNumber,2)
 
    section := ListBox.text  ; Get the current section

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

    IniWrite(newValue, ini, section, key)
    listView.Modify(RowNumber,"col3",newValue)
}

HideAllControls() {
    global dropdown, checkbox, hotkeyControl, editControl, dateButton, fileButton, folderButton
    dropdown.Visible := false
    checkbox.Visible := false
    hotkeyControl.Visible := false
    editControl.Visible := false
    dateButton.Visible := false
    fileButton.Visible := false
    folderButton.Visible := false
}

SetDate(*) { 
    editControl.Value := DateStamp()
    lv_ValueChanged()
}

DateStamp() {
    DateStampGui := Gui("ToolWindow", "Get Date Stamp")
    DateStampGui.Add("Text", "", "Now: " FormatTime(A_Now, "dddd dd MMMM yyyy, HH:mm"))
    DateTimeCtrl := DateStampGui.Add("DateTime", '', "yyyy-MM-dd")
    DateStampGui.OnEvent('Escape', DateStampGui.Hide)
    DateStampGui.Show()
    WinWaitClose(DateStampGui)
    originalValue := DateTimeCtrl.Value
    year := SubStr(originalValue, 1, 4)
    month := SubStr(originalValue, 5, 2)
    day := SubStr(originalValue, 7, 2)
    myChoice := year . "-" . month . "-" . day
    return myChoice
}

SelectFile(*) {
    global editControl
    selectedFile := FileSelect(, , "Select a file")
    if (selectedFile) {
        editControl.Value := selectedFile
    }
}

SelectFolder(*) {
    global editControl
    selectedFolder := FileSelect("D", , "Select a folder")
    if (selectedFolder) {
        editControl.Value := selectedFolder
    }
}

; Function to retrieve comments for a given key
GetKeyComments(iniFile, section, key) {
    contents := FileRead(iniFile)
    lines := StrSplit(contents, ["`n", "`r"])  ; Split the contents into lines
    isKeyFound := false
    comments := ""

    ; Reset Type and Options
    myType := ""
    Options := ""

    for index, line in lines {
        line := Trim(line)  ; Trim whitespace

        ; Check for the section
        if (line = "[" section "]") {
            isKeyFound := false  ; Reset key found flag when section changes
        }

        ; Check for the key with either "=" or ":" and ensure it's in the right section
        if (!isKeyFound && (InStr(line, key "=") || InStr(line, key ":"))) {
            ; Extract and trim the value part after the delimiter
            pos := InStr(line, "=") ? InStr(line, "=") : InStr(line, ":")
            foundKey := Trim(SubStr(line, 1, pos - 1))  ; Trim the key
            value := Trim(SubStr(line, pos + 1))        ; Trim the value
            
            if (foundKey = key) {  ; Ensure the key matches exactly
                isKeyFound := true  ; The key has been found
                continue
            }
        }

        ; If the line is a comment, collect it
        if (isKeyFound && (line ~= "^;")) {
            commentLine := SubStr(line, 2)  ; Remove the leading semicolon
            comments .= commentLine . "`n"  ; Collect comments
        } else if (isKeyFound && line = "") {
            break  ; Stop collecting when reaching an empty line after key
        }
    }

    return Trim(comments)
}


; Function to determine the type of the key based on its comments
GetKeyType(comment) {
    if InStr(comment, "Type: DropDown")
        return "DropDown"
    else if InStr(comment, "Type: Checkbox")
        return "Checkbox"
    else if InStr(comment, "Type: Hotkey")
        return "Hotkey"
    else if InStr(comment, "Type: File")
        return "File"
    else if InStr(comment, "Type: Folder")
        return "Folder"
    else if InStr(comment, "Type: Date")
        return "Date"
    return "Text"
}
