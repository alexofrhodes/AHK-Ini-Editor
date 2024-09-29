#Requires AutoHotkey v2.0

; Sample INI file path
global IniFile := "sample.ini"

; Create a sample INI file with test data
content := 
(
  "
[General]
Username=JohnDoe
; Type: DropDown

[Settings]
EnableFeature=true
; Type: Checkbox

[Paths]
FilePath=C:\Some\Path\To\File.txt
; Type: File
"
)

try FileDelete IniFile
FileAppend(content, IniFile)

IniSettingsEditor(IniFile)

IniSettingsEditor(IniFile) {
  ; Create the main GUI
  mygui := Gui("+Resize")
  mygui.Title := "INI Settings Editor"
  mygui.SetFont("s10", "Verdana")
  
  ; Create TreeView and Edit controls
  global treeView := mygui.Add("TreeView", "x16 y16 w200 h300")
  global valueControl := mygui.Add("Edit", "x230 y16 w340 h20")

  ; Read the INI file and populate the TreeView
  iniContents := FileRead(IniFile)
  section := ""

  For line in StrSplit(iniContents, "`n") {
    currLine := Trim(line)
    if (currLine = "") or (InStr(currLine, ";") = 1) ; Skip empty lines and comments
      continue

    ; Detect section
    if (InStr(currLine, "[") && InStr(currLine, "]")) {
      section := StrReplace(StrReplace(currLine, "[", ""), "]", "")
      sectionID := treeView.Add(section)
    } 
    ; Detect key-value pairs
    else if InStr(currLine, "=") {
      pos := InStr(currLine, "=")
      key := Trim(SubStr(currLine, 1, pos - 1))
      
      ; Add key under section in TreeView
      treeView.Add(key, sectionID)
    }
  }

  ; Event: When selecting an item in TreeView
  treeView.OnEvent("ItemSelect", tv_ItemSelect)

  ; Event: When changing the Edit control's content
  valueControl.OnEvent("Change", tv_ValueChanged)

  ; Show the GUI
  mygui.Show("w660 h360")

  ; Select the first child of the TreeView (assuming there are items)
  
  count := 0
  try count :=treeView.GetCount(treeview.GetSelection()) 
  if count  {
    treeView.Select(treeView.getChild())
  }  
}

; Function to handle TreeView selection change
tv_ItemSelect(GuiCtrlObj, Item, *) {
  if (Item) {
    ; Get the current section and key
    section := treeView.GetParent(Item) ; Get the parent section
    if !section
        return
    key := treeview.GetText(item)

    ; Read the current value from the INI file
    value := IniRead(IniFile, treeView.GetText(section), key)
    valueControl.Value := value ; Display the selected key's value
  } else {
    valueControl.Value := "" ; Clear if nothing is selected
  }
}

; Function to handle value change in the Edit control
tv_ValueChanged(*) {
  ItemID := treeView.GetSelection()
  if !ItemID
    return
  selectedKey := treeView.GetText(ItemID) ; Get the selected key
  section := treeView.GetParent(ItemID) ; Get the parent section

  ; Write the new value back to the INI file
  newValue := valueControl.value
  IniWrite(newValue, iniFile, treeview.GetText(section), selectedKey)
}