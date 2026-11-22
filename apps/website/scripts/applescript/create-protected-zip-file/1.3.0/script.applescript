------------------------------------------------------------------
-- Helper: joinListWithQuotes
------------------------------------------------------------------
on joinListWithQuotes(posixChosenPaths, delimiter)
  log "DEBUG -> joinListWithQuotes: count=" & (count of posixChosenPaths) & " delimiter=" & delimiter
  set theResult to ""

  repeat with i from 1 to count of posixChosenPaths
    set theResult to theResult & "\"" & item i of posixChosenPaths & "\""

    if i is not equal to (count of posixChosenPaths) then
      set theResult to theResult & delimiter
    end if
  end repeat

  log "DEBUG -> joinListWithQuotes result: " & theResult
  return theResult
end joinListWithQuotes

------------------------------------------------------------------
-- Helper: replaceText
------------------------------------------------------------------
on replaceText(originalString, searchString, replacementString)
  log "DEBUG -> replaceText: search=" & searchString & " replacement=" & replacementString
  log "DEBUG -> replaceText: original=" & originalString
  set AppleScript's text item delimiters to searchString
  set textItems to text items of originalString
  set AppleScript's text item delimiters to replacementString
  set modifiedString to textItems as text
  set AppleScript's text item delimiters to ""

  log "DEBUG -> replaceText result: " & modifiedString
  return modifiedString
end replaceText

------------------------------------------------------------------
-- Helper: findCommonDirectoryPath
------------------------------------------------------------------
on findCommonDirectoryPath(posixChosenPaths)
  log "DEBUG -> findCommonDirectoryPath: count=" & (count of posixChosenPaths)
  if (count of posixChosenPaths) = 0 then
    log "DEBUG -> findCommonDirectoryPath: empty list"
    return ""
  end if

  set path1 to item 1 of posixChosenPaths
  set path1Components to path1's text items
  set maxComponents to (count path1Components)
  log "DEBUG -> findCommonDirectoryPath: base=" & path1

  repeat with pathIndex from 2 to (count of posixChosenPaths)
    set nextPath to item pathIndex of posixChosenPaths
    if (maxComponents = 0) then
      exit repeat
    end if

    set theseComponents to nextPath's text items
    set componentCount to (count theseComponents)

    if (componentCount < maxComponents) then
      set maxComponents to componentCount
    end if

    repeat with c from 1 to maxComponents
      if (theseComponents's item c is not equal to path1Components's item c) then
        set maxComponents to c - 1
        exit repeat
      end if
    end repeat
  end repeat

  if (maxComponents > 0) then
    set commonPath to path1's text 1 thru text item maxComponents
  else
    set commonPath to ""
  end if

  if (count of posixChosenPaths) = 1 then
    set commonPath to removeLastDirectory(commonPath)
    log "DEBUG -> findCommonDirectoryPath: single path result=" & commonPath
    return commonPath
  end if

  log "DEBUG -> findCommonDirectoryPath: result=" & commonPath
  return commonPath
end findCommonDirectoryPath

------------------------------------------------------------------
-- Helper: removeLastDirectory
------------------------------------------------------------------
on removeLastDirectory(filePath)
  log "DEBUG -> removeLastDirectory: input=" & filePath
  set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "/"}
  set myArray to text items of filePath
  set concatenatedString to ""

  repeat with i from 1 to (count myArray) - 2
    set concatenatedString to concatenatedString & item i of myArray
    if i < (count myArray) then
      set concatenatedString to concatenatedString & "/"
    end if
  end repeat

  set AppleScript's text item delimiters to oldTID

  log "DEBUG -> removeLastDirectory: result=" & concatenatedString
  return concatenatedString
end removeLastDirectory

------------------------------------------------------------------
-- CLI: normalizeMode
------------------------------------------------------------------
on normalizeMode(modeValue)
  log "DEBUG -> normalizeMode: input=" & modeValue
  if modeValue is "files" or modeValue is "Files" then
    log "DEBUG -> normalizeMode: output=Files"
    return "Files"
  end if

  if modeValue is "folders" or modeValue is "Folders" then
    log "DEBUG -> normalizeMode: output=Folders"
    return "Folders"
  end if

  error "Invalid --mode value. Use files or folders."
end normalizeMode

------------------------------------------------------------------
-- CLI: parseArgs
------------------------------------------------------------------
on parseArgs(argv)
  log "DEBUG -> parseArgs: argv count=" & (count of argv)
  set filesOrFolders to ""
  set posixZipFilePath to ""
  set zipPassword to ""
  set posixChosenPaths to {}
  set i to 1

  repeat while i <= (count of argv)
    set arg to item i of argv
    log "DEBUG -> parseArgs arg[" & i & "]: " & arg

    if arg is "--" then
    -- Ignore end-of-options marker if passed through.
    else if arg is "--files" then
      set filesOrFolders to "Files"
      log "DEBUG -> parseArgs: mode=Files"
    else if arg is "--folders" then
      set filesOrFolders to "Folders"
      log "DEBUG -> parseArgs: mode=Folders"
    else if arg is "--mode" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --mode."
      end if
      set filesOrFolders to my normalizeMode(item i of argv)
      log "DEBUG -> parseArgs: mode=" & filesOrFolders
    else if arg is "--zip" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --zip."
      end if
      set posixZipFilePath to item i of argv
      log "DEBUG -> parseArgs: zip=" & posixZipFilePath
    else if arg is "--password" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --password."
      end if
      set zipPassword to item i of argv
      log "DEBUG -> parseArgs: password=" & zipPassword
    else
      set end of posixChosenPaths to arg
      log "DEBUG -> parseArgs: path=" & arg
    end if

    set i to i + 1
  end repeat

  if filesOrFolders is "" then
    error "Missing --files or --folders."
  end if

  if posixZipFilePath is "" then
    error "Missing --zip <path>."
  end if

  if zipPassword is "" then
    error "Missing --password <value>."
  end if

  if (count of posixChosenPaths) = 0 then
    error "Missing paths to zip."
  end if

  log "DEBUG -> parseArgs result: mode=" & filesOrFolders
  log "DEBUG -> parseArgs result: zip=" & posixZipFilePath
  log "DEBUG -> parseArgs result: password=" & zipPassword
  log "DEBUG -> parseArgs result: paths=" & (count of posixChosenPaths)
  return {filesOrFolders, posixZipFilePath, zipPassword, posixChosenPaths}
end parseArgs

------------------------------------------------------------------
-- Core: createProtectedZip
------------------------------------------------------------------
on createProtectedZip(posixChosenPaths, posixZipFilePath, zipPassword, filesOrFolders)
  log "DEBUG -> createProtectedZip: start"
  log "DEBUG -> mode: " & filesOrFolders
  log "DEBUG -> items: " & (count of posixChosenPaths)
  log "DEBUG -> output: " & posixZipFilePath

  if zipPassword is not equal to "" then
    log "DEBUG -> password: " & zipPassword
    if filesOrFolders is "Folders" then
      set baseDirectory to my findCommonDirectoryPath(posixChosenPaths)
      if baseDirectory is "" then
        error "Error creating protected ZIP file. Unable to determine base directory."
      end if

      set pathsToZip to my replaceText(joinListWithQuotes(posixChosenPaths, " "), baseDirectory, "")
      log "DEBUG -> baseDirectory: " & baseDirectory
      log "DEBUG -> pathsToZip: " & pathsToZip

      -- Create the ZIP file from one or more folders.
      log "DEBUG -> zip command: folders"
      set zipOutput to do shell script "cd " & quoted form of baseDirectory & " && zip -P " & quoted form of zipPassword & " -ry " & quoted form of posixZipFilePath & " " & pathsToZip
      log "DEBUG -> zip output:" & return & zipOutput
    else if filesOrFolders is "Files" then
      set pathsToZip to my joinListWithQuotes(posixChosenPaths, " ")
      log "DEBUG -> pathsToZip: " & pathsToZip

      -- Create the ZIP file from one or more files.
      log "DEBUG -> zip command: files"
      set zipOutput to do shell script "zip -P " & quoted form of zipPassword & " -rjy " & quoted form of posixZipFilePath & " " & pathsToZip
      log "DEBUG -> zip output:" & return & zipOutput
    else
      error "Error creating protected ZIP file. Invalid selection."
    end if

    -- Wait for the ZIP file to successfully save.
    delay 2

    -- Check if the ZIP file was created successfully.
    if (do shell script "[ -e " & quoted form of posixZipFilePath & " ] && echo 'true' || echo 'false'") is not equal to "true" then
      error "Error creating protected ZIP file. ZIP file not found in selected path."
    end if
    log "DEBUG -> zip created"
  else
    error "Error creating protected ZIP file. Password is required."
  end if

  log "DEBUG -> createProtectedZip: done"
  return true
end createProtectedZip

------------------------------------------------------------------
-- Entry: runWithArgs
------------------------------------------------------------------
on runWithArgs(argv)
  log "DEBUG -> runWithArgs: start"
  log "DEBUG -> runWithArgs: argv count=" & (count of argv)
  set {filesOrFolders, posixZipFilePath, zipPassword, posixChosenPaths} to my parseArgs(argv)
  my createProtectedZip(posixChosenPaths, posixZipFilePath, zipPassword, filesOrFolders)
  log "DEBUG -> runWithArgs: done"
end runWithArgs

------------------------------------------------------------------
-- Entry: runInteractive
------------------------------------------------------------------
on runInteractive()
  log "DEBUG -> runInteractive: start"
  try
    display dialog "Do you want to select files or folders to include in the protected ZIP file?" buttons {"Files", "Folders", "Cancel"} default button "Cancel"
    set filesOrFolders to button returned of the result
    log "DEBUG -> selection: " & filesOrFolders

    if filesOrFolders is "Files" then
    -- Prompt the user to choose one or more files.
      set chosenPaths to choose file with prompt "Select the files you want to include in the protected ZIP file:" with multiple selections allowed
    else if filesOrFolders is "Folders" then
    -- Prompt the user to choose one or more folders.
      set chosenPaths to choose folder with prompt "Select the folders you want to include in the protected ZIP file:" with multiple selections allowed
    else
      error "User canceled."
    end if

    set posixChosenPaths to {}

    -- Convert paths to POSIX-compliant.
    repeat with chosenPath in chosenPaths
      set end of posixChosenPaths to POSIX path of chosenPath
    end repeat
    log "DEBUG -> selected paths: " & (count of posixChosenPaths)

    -- Define the destination ZIP file path.
    set zipFilePath to choose file name with prompt "Choose a name and location for the protected ZIP file:" default name "Archive.zip"

    -- Convert the ZIP file path to a POSIX path.
    set posixZipFilePath to POSIX path of zipFilePath
    log "DEBUG -> output: " & posixZipFilePath

    -- Prompt the user to enter a password.
    display dialog "Enter a password for the protected ZIP file:" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer
    set zipPassword to text returned of the result
    log "DEBUG -> password: " & zipPassword

    my createProtectedZip(posixChosenPaths, posixZipFilePath, zipPassword, filesOrFolders)

    display notification "Protected ZIP file created successfully!" with title "Create Protected ZIP" sound name "Blow"

  on error errMsg
    if errMsg does not contain "User canceled." then
      display dialog errMsg buttons {"OK"} with icon stop default button "OK"
    end if
  end try
  log "DEBUG -> runInteractive: done"
end runInteractive

------------------------------------------------------------------
-- Entry: run
------------------------------------------------------------------
on run argv
  log "DEBUG -> run: argv count=" & (count of argv)
  if (count of argv) > 0 then
    my runWithArgs(argv)
  else
    my runInteractive()
  end if
  log "DEBUG -> run: done"
end run
