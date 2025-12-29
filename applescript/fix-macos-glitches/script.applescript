------------------------------------------------------------------
-- Data: process groups
------------------------------------------------------------------
property processGroups : {{"iPhone Sync Processes", {"AMPDeviceDiscoveryAgent", "AMPLibraryAgent", "MDCrashReportTool", "MobileDeviceUpdater"}}, {"macOS UI Processes", {"ControlCenter", "Dock", "NotificationCenter", "SystemUIServer"}}}
property dependentAppBundleIDs : {"com.surteesstudios.Bartender"}

------------------------------------------------------------------
-- Helper: joinList
------------------------------------------------------------------
on joinList(theList, theDelimiter)
  set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, theDelimiter}
  set joinedText to theList as string
  set AppleScript's text item delimiters to oldDelims

  return joinedText
end joinList

------------------------------------------------------------------
-- Helper: listContains
------------------------------------------------------------------
on listContains(theList, targetValue)
  repeat with listItem in theList
    if (contents of listItem) is targetValue then
      return true
    end if
  end repeat

  return false
end listContains

------------------------------------------------------------------
-- Helper: buildProcessGroupNames
------------------------------------------------------------------
on buildProcessGroupNames(processGroups)
  set processGroupNames to {}

  repeat with processGroup in processGroups
    set end of processGroupNames to item 1 of processGroup
  end repeat

  return processGroupNames
end buildProcessGroupNames

------------------------------------------------------------------
-- Helper: collectTargetProcesses
------------------------------------------------------------------
on collectTargetProcesses(processGroups, selectedProcessGroupNames)
  set targetProcessNames to {}

  repeat with selectedProcessGroupName in selectedProcessGroupNames
    repeat with processGroup in processGroups
      if item 1 of processGroup is (contents of selectedProcessGroupName) then
        set targetProcessNames to targetProcessNames & item 2 of processGroup
      end if
    end repeat
  end repeat

  return targetProcessNames
end collectTargetProcesses

------------------------------------------------------------------
-- Helper: parseArgs
------------------------------------------------------------------
on parseArgs(argv)
  set dryRun to false
  set selectedProcessGroupNames to {}

  repeat with arg in argv
    if (contents of arg) is "--dry-run" then
      set dryRun to true
    else
      set end of selectedProcessGroupNames to (contents of arg)
    end if
  end repeat

  if selectedProcessGroupNames is {} then
    set availableGroups to my buildProcessGroupNames(processGroups)
    error "Missing group names. Available groups: " & my joinList(availableGroups, ", ")
  end if

  return {dryRun, selectedProcessGroupNames}
end parseArgs

------------------------------------------------------------------
-- Core: buildResultMessage
------------------------------------------------------------------
on buildResultMessage(dryRun, terminatedProcessNames, wouldTerminateProcessNames, notRunningProcessNames)
  set resultMessage to ""
  set hasEntries to false

  if dryRun then
    if wouldTerminateProcessNames is not {} then
      set hasEntries to true
      set resultMessage to resultMessage & "These processes would be terminated:" & return

      repeat with processName in wouldTerminateProcessNames
        set resultMessage to resultMessage & " - " & processName & return
      end repeat
    end if
  else
    if terminatedProcessNames is not {} then
      set hasEntries to true
      set resultMessage to resultMessage & "These processes were terminated:" & return

      repeat with processName in terminatedProcessNames
        set resultMessage to resultMessage & " - " & processName & return
      end repeat
    end if
  end if

  if notRunningProcessNames is not {} then
    set hasEntries to true

    if resultMessage is not "" then
      set resultMessage to resultMessage & return
    end if

    set resultMessage to resultMessage & "These processes were not running:" & return

    repeat with processName in notRunningProcessNames
      set resultMessage to resultMessage & " - " & processName & return
    end repeat
  end if

  if hasEntries is false then
    set resultMessage to "No selected processes were running."
  end if

  if resultMessage ends with return then
    set resultMessage to text 1 thru -2 of resultMessage
  end if

  return resultMessage
end buildResultMessage

------------------------------------------------------------------
-- Core: runWithSelection
------------------------------------------------------------------
on runWithSelection(processGroups, dependentAppBundleIDs, selectedProcessGroupNames, dryRun)
  set processGroupNames to my buildProcessGroupNames(processGroups)
  log "DEBUG -> processGroupNames: " & my joinList(processGroupNames, ", ")
  log "DEBUG -> selectedProcessGroupNames: " & my joinList(selectedProcessGroupNames, ", ")

  set targetProcessNames to my collectTargetProcesses(processGroups, selectedProcessGroupNames)

  if targetProcessNames is {} then
    error "No matching process groups selected."
  end if

  log "DEBUG -> targetProcessNames: " & my joinList(targetProcessNames, ", ")
  log "DEBUG -> dryRun: " & dryRun

  set terminatedProcessNames to {}
  set wouldTerminateProcessNames to {}
  set notRunningProcessNames to {}

  -- Detect whether this run targets SystemUIServer.
  set willTerminateSystemUIServer to my listContains(targetProcessNames, "SystemUIServer")
  log "DEBUG -> willTerminateSystemUIServer: " & willTerminateSystemUIServer

  -- Track which dependent apps were actually running so we only relaunch those.
  set dependentBundleIDsToRelaunch to {}
  log "DEBUG -> dependentAppBundleIDs: " & my joinList(dependentAppBundleIDs, ", ")

  if willTerminateSystemUIServer then
    log "DEBUG -> SystemUIServer selected. Preparing dependent apps."

    repeat with bundleID in dependentAppBundleIDs
      set idText to (contents of bundleID)
      log "DEBUG -> Checking dependent app running state (bundle ID): " & idText

      set appWasRunning to false
      try
        set appWasRunning to (application id idText is running)
        log "DEBUG -> App is running: " & appWasRunning
      on error errorMessage number errorNumber
        log "DEBUG -> App running-check error for " & idText & " - " & errorMessage
      end try

      if appWasRunning then
        set end of dependentBundleIDsToRelaunch to idText
        log "DEBUG -> Will relaunch later: " & idText

        if dryRun then
          log "DEBUG -> DRY RUN: would quit dependent app " & idText
        else
          try
            log "DEBUG -> Quitting dependent app: " & idText
            tell application id idText to quit
          on error errorMessage number errorNumber
            log "DEBUG -> Failed to quit dependent app " & idText & " - " & errorMessage
          end try
        end if
      else
        log "DEBUG -> Dependent app not running; will not relaunch: " & idText
      end if
    end repeat

    log "DEBUG -> dependentBundleIDsToRelaunch: " & my joinList(dependentBundleIDsToRelaunch, ", ")

    if dryRun then
      log "DEBUG -> DRY RUN: skipping dependent app quit delay."
    else
      delay 1
    end if
  else
    log "DEBUG -> SystemUIServer not selected. No dependent-app pre-quit needed."
  end if

  -- Main kill loop.
  repeat with processName in targetProcessNames
    set processNameText to (contents of processName)
    log "DEBUG -> Checking process: " & processNameText

    set isRunningInteger to (do shell script "pgrep -x " & quoted form of processNameText & " >/dev/null; echo $?") as integer
    log "DEBUG -> pgrep exit code for " & processNameText & ": " & isRunningInteger

    if isRunningInteger is 0 then
      if dryRun then
        set end of wouldTerminateProcessNames to processNameText
        log "DEBUG -> DRY RUN: would terminate " & processNameText
      else
        try
          log "DEBUG -> killall starting: " & processNameText
          do shell script "killall " & quoted form of processNameText with administrator privileges
          set end of terminatedProcessNames to processNameText
          log "DEBUG -> Terminated process: " & processNameText
        on error errorMessage number errorNumber
          log "DEBUG -> Failed to terminate " & processNameText & " - " & errorMessage
        end try
      end if
    else
      set end of notRunningProcessNames to processNameText
      log "DEBUG -> Process not running: " & processNameText
    end if
  end repeat

  if willTerminateSystemUIServer then
    if dryRun then
      log "DEBUG -> DRY RUN: skipping dependent-app relaunch."
    else
      log "DEBUG -> SystemUIServer termination path complete. Waiting before relaunching dependent apps."
      delay 2

      repeat with bundleID in dependentBundleIDsToRelaunch
        set idText to (contents of bundleID)
        try
          log "DEBUG -> Relaunching dependent app: " & idText
          do shell script "open -b " & quoted form of idText
        on error errorMessage number errorNumber
          log "DEBUG -> Failed to relaunch dependent app " & idText & " - " & errorMessage
        end try
      end repeat

      log "DEBUG -> Dependent app relaunch loop finished."
    end if
  else
    log "DEBUG -> No dependent-app relaunch needed."
  end if

  log "DEBUG -> terminatedProcessNames: " & my joinList(terminatedProcessNames, ", ")
  log "DEBUG -> wouldTerminateProcessNames: " & my joinList(wouldTerminateProcessNames, ", ")
  log "DEBUG -> notRunningProcessNames: " & my joinList(notRunningProcessNames, ", ")

  return my buildResultMessage(dryRun, terminatedProcessNames, wouldTerminateProcessNames, notRunningProcessNames)
end runWithSelection

------------------------------------------------------------------
-- Entry: runWithArgs
------------------------------------------------------------------
on runWithArgs(argv)
  set {dryRun, selectedProcessGroupNames} to my parseArgs(argv)
  set resultMessage to my runWithSelection(processGroups, dependentAppBundleIDs, selectedProcessGroupNames, dryRun)
  return "RESULT ->" & return & resultMessage
end runWithArgs

------------------------------------------------------------------
-- Entry: runInteractive
------------------------------------------------------------------
on runInteractive()
  set processGroupNames to my buildProcessGroupNames(processGroups)

  repeat with processGroup in processGroups
    set groupName to item 1 of processGroup
    set groupProcessList to my joinList(item 2 of processGroup, ", ")
    log "DEBUG -> processGroup: " & groupName & " - " & groupProcessList
  end repeat

  set selectedProcessGroupNames to (choose from list processGroupNames with prompt "Select the group(s) whose processes you want to terminate:" with multiple selections allowed without empty selection allowed)

  if selectedProcessGroupNames is false then
    return
  end if

  set resultMessage to my runWithSelection(processGroups, dependentAppBundleIDs, selectedProcessGroupNames, false)
  display dialog resultMessage buttons {"OK"} default button "OK"
end runInteractive

------------------------------------------------------------------
-- Entry: run
------------------------------------------------------------------
on run argv
  if (count of argv) > 0 then
    return my runWithArgs(argv)
  end if

  my runInteractive()
end run
