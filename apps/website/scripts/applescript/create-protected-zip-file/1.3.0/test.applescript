-- End-to-end tests for "create-protected-zip-file".
-- Run: "osascript applescript/create-protected-zip-file/test.applescript".

------------------------------------------------------------------
-- Helper: assertEqual
------------------------------------------------------------------
on assertEqual(actual, expected, label)
  if actual is not equal to expected then
    error "FAIL: " & label & " expected: " & expected & " got: " & actual
  end if
end assertEqual

------------------------------------------------------------------
-- Helper: assertContains
------------------------------------------------------------------
on assertContains(haystack, needle, label)
  if haystack does not contain needle then
    error "FAIL: " & label & " missing: " & needle
  end if
end assertContains

------------------------------------------------------------------
-- Helper: commandFails
------------------------------------------------------------------
on commandFails(cmd)
  try
    do shell script cmd
    return false
  on error
    return true
  end try
end commandFails

------------------------------------------------------------------
-- Helper: normalizeDebugOutput
------------------------------------------------------------------
on normalizeDebugOutput(rawText)
  set normalizedText to my normalizeLineEndings(rawText)
  set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "DEBUG ->"}
  set textItems to text items of normalizedText
  set AppleScript's text item delimiters to (linefeed & "DEBUG ->")
  set normalizedText to textItems as text
  set AppleScript's text item delimiters to oldTID

  if normalizedText starts with linefeed then
    set normalizedText to text 2 thru -1 of normalizedText
  end if

  return my collapseLinefeeds(normalizedText)
end normalizeDebugOutput

------------------------------------------------------------------
-- Helper: normalizeLineEndings
------------------------------------------------------------------
on normalizeLineEndings(textValue)
  set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, return}
  set textItems to text items of textValue
  set AppleScript's text item delimiters to linefeed
  set normalizedText to textItems as text
  set AppleScript's text item delimiters to oldTID

  return normalizedText
end normalizeLineEndings

------------------------------------------------------------------
-- Helper: collapseLinefeeds
------------------------------------------------------------------
on collapseLinefeeds(textValue)
  set normalizedText to textValue

  repeat while normalizedText contains (linefeed & linefeed)
    set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, linefeed & linefeed}
    set textItems to text items of normalizedText
    set AppleScript's text item delimiters to linefeed
    set normalizedText to textItems as text
    set AppleScript's text item delimiters to oldTID
  end repeat

  return normalizedText
end collapseLinefeeds

------------------------------------------------------------------
-- Core: files test
------------------------------------------------------------------
on runFilesTest(tmpDir, sutPath, zipPassword)
  set filesDir to tmpDir & "/files"
  do shell script "mkdir -p " & quoted form of filesDir
  set fileA to filesDir & "/a.txt"
  set fileB to filesDir & "/b.txt"
  do shell script "printf 'hello' > " & quoted form of fileA
  do shell script "printf 'world' > " & quoted form of fileB

  log "FILES: created " & fileA & " and " & fileB

  set zipFilesPath to tmpDir & "/files.zip"
  set filesCommand to "osascript " & quoted form of sutPath & " -- --files --zip " & quoted form of zipFilesPath & " --password " & quoted form of zipPassword & " " & quoted form of fileA & " " & quoted form of fileB & " 2>&1"

  log "FILES: running zip command"

  set filesOutput to do shell script filesCommand

  log "FILES: script output:\n" & my normalizeLineEndings(my normalizeDebugOutput(filesOutput))

  log "FILES: zip created at " & zipFilesPath

  set filesList to do shell script "unzip -P " & quoted form of zipPassword & " -l " & quoted form of zipFilesPath

  log "FILES: zip listing:\n" & my normalizeLineEndings(filesList)

  my assertContains(filesList, "a.txt", "files zip contains a.txt")
  my assertContains(filesList, "b.txt", "files zip contains b.txt")

  log "FILES: contents verified"

  my assertEqual(my commandFails("unzip -P wrong -t " & quoted form of zipFilesPath), true, "files zip fails with wrong password")

  log "FILES: wrong password rejected"
end runFilesTest

------------------------------------------------------------------
-- Core: folders test
------------------------------------------------------------------
on runFoldersTest(tmpDir, sutPath, zipPassword)
  set foldersDir to tmpDir & "/folders"
  set folderAlpha to foldersDir & "/alpha/"
  set folderBeta to foldersDir & "/beta/"
  do shell script "mkdir -p " & quoted form of folderAlpha & " " & quoted form of folderBeta
  set alphaFile to folderAlpha & "one.txt"
  set betaFile to folderBeta & "two.txt"
  do shell script "printf 'alpha' > " & quoted form of alphaFile
  do shell script "printf 'beta' > " & quoted form of betaFile

  log "FOLDERS: created " & folderAlpha & " and " & folderBeta

  set zipFoldersPath to tmpDir & "/folders.zip"
  set foldersCommand to "osascript " & quoted form of sutPath & " -- --folders --zip " & quoted form of zipFoldersPath & " --password " & quoted form of zipPassword & " " & quoted form of folderAlpha & " " & quoted form of folderBeta & " 2>&1"

  log "FOLDERS: running zip command"

  set foldersOutput to do shell script foldersCommand

  log "FOLDERS: script output:\n" & my normalizeLineEndings(my normalizeDebugOutput(foldersOutput))

  log "FOLDERS: zip created at " & zipFoldersPath

  set foldersList to do shell script "unzip -P " & quoted form of zipPassword & " -l " & quoted form of zipFoldersPath

  log "FOLDERS: zip listing:\n" & my normalizeLineEndings(foldersList)

  my assertContains(foldersList, "alpha/one.txt", "folders zip contains alpha/one.txt")
  my assertContains(foldersList, "beta/two.txt", "folders zip contains beta/two.txt")

  log "FOLDERS: contents verified"

  my assertEqual(my commandFails("unzip -P wrong -t " & quoted form of zipFoldersPath), true, "folders zip fails with wrong password")

  log "FOLDERS: wrong password rejected"
end runFoldersTest

------------------------------------------------------------------
-- Entry: test run
------------------------------------------------------------------
set tmpDir to do shell script "mktemp -d"
log "TEMP DIRECTORY: " & tmpDir

try
  set testPath to POSIX path of (path to me)
  set scriptDir to do shell script "dirname " & quoted form of testPath
  set sutPath to scriptDir & "/script.applescript"

  log "SCRIPT: " & sutPath

  -- ASCII character 34 is double quote, 92 is backslash, 96 is backtick.
  set zipPassword to "Aa0 !@#$%^&*()_+-=[]{}|;:',.<>/?~" & (ASCII character 96) & (ASCII character 34) & (ASCII character 92)

  log "PASSWORD: " & zipPassword

  my runFilesTest(tmpDir, sutPath, zipPassword)
  my runFoldersTest(tmpDir, sutPath, zipPassword)

  log "OK: tests passed"

on error errMsg number errNum
  do shell script "rm -rf " & quoted form of tmpDir
  error errMsg number errNum
end try

do shell script "rm -rf " & quoted form of tmpDir
