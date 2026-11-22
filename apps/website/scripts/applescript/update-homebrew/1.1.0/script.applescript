------------------------------------------------------------------
-- Data: default settings
------------------------------------------------------------------
property sourceCandidates : {"~/.bashrc", "~/.bash_profile", "~/.zshrc", "~/.zprofile", "~/.profile"}
property notificationTitle : "Update Homebrew"
property notificationSound : "Blow"

------------------------------------------------------------------
-- Helper: expandHomePath
------------------------------------------------------------------
on expandHomePath(pathText)
  if pathText starts with "~/" then
    return (POSIX path of (path to home folder)) & text 3 thru -1 of pathText
  end if

  return pathText
end expandHomePath

------------------------------------------------------------------
-- Helper: fileExists
------------------------------------------------------------------
on fileExists(pathText)
  return (do shell script "[ -e " & quoted form of pathText & " ] && echo 'true' || echo 'false'") is equal to "true"
end fileExists

------------------------------------------------------------------
-- Helper: findFirstSourceFile
------------------------------------------------------------------
on findFirstSourceFile(candidateList)
  repeat with sourcePath in candidateList
    set fullSourcePath to my expandHomePath(contents of sourcePath)
    log "DEBUG -> checking source: " & fullSourcePath
    if my fileExists(fullSourcePath) then
      log "DEBUG -> selected source: " & fullSourcePath
      return fullSourcePath
    end if
  end repeat

  log "DEBUG -> no source file found"
  return ""
end findFirstSourceFile

------------------------------------------------------------------
-- Helper: resolveBrewLocation
------------------------------------------------------------------
on resolveBrewLocation(sourcePath)
  log "DEBUG -> resolving brew location using: " & sourcePath
  set brewLocation to do shell script "source " & quoted form of sourcePath & " >/dev/null 2>&1; command -v brew; exit 0;"
  log "DEBUG -> brew location: " & brewLocation
  return brewLocation
end resolveBrewLocation

------------------------------------------------------------------
-- Helper: runBrewCommand
------------------------------------------------------------------
on runBrewCommand(sourcePath, brewLocation, brewArgs)
  log "DEBUG -> running brew command: " & brewArgs
  do shell script "source " & quoted form of sourcePath & " && " & quoted form of brewLocation & " " & brewArgs
end runBrewCommand

------------------------------------------------------------------
-- Helper: parseArgs
------------------------------------------------------------------
on parseArgs(argv)
  log "DEBUG -> parseArgs: argv count=" & (count of argv)
  set dryRun to false
  set noNotify to false
  set sourceOverride to ""
  set brewPathOverride to ""

  set i to 1
  repeat while i ≤ (count of argv)
    set arg to item i of argv

    if arg is "--" then
      -- Ignore end-of-options marker.
    else if arg is "--dry-run" then
      set dryRun to true
      log "DEBUG -> parseArgs: dryRun=true"
    else if arg is "--no-notify" then
      set noNotify to true
      log "DEBUG -> parseArgs: noNotify=true"
    else if arg is "--source" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --source."
      end if
      set sourceOverride to item i of argv
      log "DEBUG -> parseArgs: sourceOverride=" & sourceOverride
    else if arg is "--brew-path" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --brew-path."
      end if
      set brewPathOverride to item i of argv
      log "DEBUG -> parseArgs: brewPathOverride=" & brewPathOverride
    else
      error "Unknown argument: " & arg
    end if

    set i to i + 1
  end repeat

  log "DEBUG -> parseArgs result: dryRun=" & dryRun
  log "DEBUG -> parseArgs result: noNotify=" & noNotify
  return {dryRun, noNotify, sourceOverride, brewPathOverride}
end parseArgs

------------------------------------------------------------------
-- Core: buildDryRunMessage
------------------------------------------------------------------
on buildDryRunMessage(sourcePath, brewLocation)
  set resultMessage to "Would run:" & return
  set resultMessage to resultMessage & brewLocation & " update" & return
  set resultMessage to resultMessage & brewLocation & " upgrade"

  return resultMessage
end buildDryRunMessage

------------------------------------------------------------------
-- Core: runUpdateFlow
------------------------------------------------------------------
on runUpdateFlow(sourcePath, brewLocation, dryRun, noNotify)
  log "DEBUG -> runUpdateFlow: sourcePath=" & sourcePath
  log "DEBUG -> runUpdateFlow: brewLocation=" & brewLocation
  log "DEBUG -> runUpdateFlow: dryRun=" & dryRun
  log "DEBUG -> runUpdateFlow: noNotify=" & noNotify
  if brewLocation is "" then
    error "Homebrew is not installed. Please install Homebrew and run this script again."
  end if

  if dryRun then
    log "DEBUG -> runUpdateFlow: dry run mode"
    return my buildDryRunMessage(sourcePath, brewLocation)
  end if

  if noNotify is false then
    log "DEBUG -> runUpdateFlow: showing start notification"
    display notification "Now updating Homebrew and the installed packages ..." with title notificationTitle
  end if

  my runBrewCommand(sourcePath, brewLocation, "update")
  my runBrewCommand(sourcePath, brewLocation, "upgrade")

  if noNotify is false then
    log "DEBUG -> runUpdateFlow: showing completion notification"
    display notification "Homebrew and the installed packages have been successfully updated!" with title notificationTitle sound name notificationSound
  end if

  log "DEBUG -> runUpdateFlow: completed"
  return "Update completed."
end runUpdateFlow

------------------------------------------------------------------
-- Entry: runWithArgs
------------------------------------------------------------------
on runWithArgs(argv)
  log "DEBUG -> runWithArgs: start"
  set {dryRun, noNotify, sourceOverride, brewPathOverride} to my parseArgs(argv)

  if sourceOverride is "" then
    set sourcePath to my findFirstSourceFile(sourceCandidates)
  else
    set sourcePath to my expandHomePath(sourceOverride)
  end if

  if sourcePath is "" then
    error "Unable to determine if Homebrew is installed. The source file (e.g. \"~/.zshrc\") cannot be located."
  end if

  if my fileExists(sourcePath) is false then
    error "Source file not found: " & sourcePath
  end if

  if brewPathOverride is not "" then
    set brewLocation to brewPathOverride
    log "DEBUG -> runWithArgs: brewPathOverride=" & brewLocation
    if (dryRun is false) and (my fileExists(brewLocation) is false) then
      error "Brew path not found: " & brewLocation
    end if
  else
    set brewLocation to my resolveBrewLocation(sourcePath)
  end if

  return my runUpdateFlow(sourcePath, brewLocation, dryRun, noNotify)
end runWithArgs

------------------------------------------------------------------
-- Entry: runInteractive
------------------------------------------------------------------
on runInteractive()
  log "DEBUG -> runInteractive: start"
  set sourcePath to my findFirstSourceFile(sourceCandidates)

  if sourcePath is "" then
    display dialog "Unable to determine if Homebrew is installed. The source file (e.g. \"~/.zshrc\") cannot be located." with icon stop buttons {"OK"} default button "OK"
    return
  end if

  set brewLocation to my resolveBrewLocation(sourcePath)

  if brewLocation is "" then
    display dialog "Homebrew is not installed. Please install Homebrew and run this script again." with icon stop buttons {"OK"} default button "OK"
    return
  end if

  my runUpdateFlow(sourcePath, brewLocation, false, false)
  log "DEBUG -> runInteractive: done"
end runInteractive

------------------------------------------------------------------
-- Entry: run
------------------------------------------------------------------
on run argv
  log "DEBUG -> run: argv count=" & (count of argv)
  if (count of argv) > 0 then
    return my runWithArgs(argv)
  end if

  my runInteractive()
end run
