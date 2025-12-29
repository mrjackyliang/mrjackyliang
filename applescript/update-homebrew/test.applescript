-- End-to-end tests for "update-homebrew".
-- Run: "osascript applescript/update-homebrew/test.applescript".

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
set brewPath to "/opt/homebrew/bin/brew"

log "SCRIPT: " & sutPath
log "SOURCE: " & sourcePath

do shell script "touch " & quoted form of sourcePath

set commandText to "osascript " & quoted form of sutPath & " -- --dry-run --no-notify --source " & quoted form of sourcePath & " --brew-path " & quoted form of brewPath & " 2>&1"
log "COMMAND: " & commandText

set outputText to do shell script commandText
set resultText to my trimLeadingWhitespace(my normalizeLineEndings(outputText))

log "RESULT:\n" & resultText

my assertContains(resultText, "Would run:", "dry-run output")
my assertContains(resultText, brewPath & " update", "update command")
my assertContains(resultText, brewPath & " upgrade", "upgrade command")

do shell script "rm -rf " & quoted form of tmpDir

log "OK: tests passed"
