-- End-to-end tests for "update-nodejs-nvm".
-- Run: "osascript applescript/update-nodejs-nvm/test.applescript".

------------------------------------------------------------------
-- Helper: assertContains
------------------------------------------------------------------
on assertContains(haystack, needle, label)
  if haystack does not contain needle then
    error "FAIL: " & label & " missing: " & needle
  end if
end assertContains

------------------------------------------------------------------
-- Helper: trimLeadingWhitespace
------------------------------------------------------------------
on trimLeadingWhitespace(textValue)
  set trimmedText to textValue

  repeat while trimmedText is not ""
    if trimmedText begins with " " then
      set trimmedText to text 2 thru -1 of trimmedText
    else if trimmedText begins with tab then
      set trimmedText to text 2 thru -1 of trimmedText
    else if trimmedText begins with return then
      set trimmedText to text 2 thru -1 of trimmedText
    else if trimmedText begins with linefeed then
      set trimmedText to text 2 thru -1 of trimmedText
    else
      exit repeat
    end if
  end repeat

  return trimmedText
end trimLeadingWhitespace

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
-- Core: dry-run test
------------------------------------------------------------------
set tmpDir to do shell script "mktemp -d"
set testPath to POSIX path of (path to me)
set scriptDir to do shell script "dirname " & quoted form of testPath
set sutPath to scriptDir & "/script.applescript"
set sourcePath to tmpDir & "/test-source.sh"

set npmPath to "/opt/homebrew/bin/npm"
set nvmPath to "nvm"
set currentDefault to "v20.0.0"
set majorVersions to "v18 v20"
set otherVersions to "v18 v20"

log "SCRIPT: " & sutPath
log "SOURCE: " & sourcePath

do shell script "touch " & quoted form of sourcePath

set commandText to "osascript " & quoted form of sutPath & " -- --dry-run --no-notify --source " & quoted form of sourcePath & " --npm-path " & quoted form of npmPath & " --nvm-path " & quoted form of nvmPath & " --current-default " & quoted form of currentDefault & " --major-versions " & quoted form of majorVersions & " --other-versions " & quoted form of otherVersions & " 2>&1"
log "COMMAND: " & commandText

set outputText to do shell script commandText
set resultText to my trimLeadingWhitespace(my normalizeLineEndings(outputText))

log "RESULT:\n" & resultText

my assertContains(resultText, "Would run:", "dry-run output")
my assertContains(resultText, quoted form of npmPath & " -g update", "npm update command")
my assertContains(resultText, "nvm install v18", "nvm install command")
my assertContains(resultText, "nvm alias default " & currentDefault, "nvm alias command")
my assertContains(resultText, "nvm use v18 && nvm reinstall-packages " & currentDefault, "nvm reinstall command")

do shell script "rm -rf " & quoted form of tmpDir

log "OK: tests passed"
