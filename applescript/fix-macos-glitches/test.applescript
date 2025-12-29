-- End-to-end tests for "fix-macos-glitches".
-- Run: "osascript applescript/fix-macos-glitches/test.applescript".

------------------------------------------------------------------
-- Helper: assertContains
------------------------------------------------------------------
on assertContains(haystack, needle, label)
  if haystack does not contain needle then
    error "FAIL: " & label & " missing: " & needle
  end if
end assertContains

------------------------------------------------------------------
-- Helper: assertContainsAny
------------------------------------------------------------------
on assertContainsAny(haystack, needleA, needleB, label)
  if (haystack does not contain needleA) and (haystack does not contain needleB) then
    error "FAIL: " & label & " missing: " & needleA & " or " & needleB
  end if
end assertContainsAny

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
-- Helper: extractResult
------------------------------------------------------------------
on extractResult(rawText)
  set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "RESULT ->"}
  set textItems to text items of rawText
  set AppleScript's text item delimiters to oldTID

  if (count of textItems) = 1 then
    return rawText
  end if

  set resultText to item -1 of textItems
  return my trimLeadingWhitespace(resultText)
end extractResult

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
set testPath to POSIX path of (path to me)
set scriptDir to do shell script "dirname " & quoted form of testPath
set sutPath to scriptDir & "/script.applescript"

log "SCRIPT: " & sutPath

set selectedGroupName to "macOS UI Processes"
set commandText to "osascript " & quoted form of sutPath & " -- --dry-run " & quoted form of selectedGroupName & " 2>&1"

log "COMMAND: " & commandText

set outputText to do shell script commandText
set resultText to my extractResult(outputText)
set resultDisplayText to my normalizeLineEndings(resultText)

log "RESULT:\n" & resultDisplayText

my assertContainsAny(resultText, "These processes would be terminated:", "No selected processes were running.", "result summary")

log "OK: tests passed"
