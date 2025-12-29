------------------------------------------------------------------
-- Data: default settings
------------------------------------------------------------------
property sourceCandidates : {"~/.bashrc", "~/.bash_profile", "~/.zshrc", "~/.zprofile", "~/.profile"}
property notificationTitle : "Update Node.js / NVM Packages"
property notificationSound : "Blow"

------------------------------------------------------------------
-- Helper: expandHomePath
------------------------------------------------------------------
on expandHomePath(pathText)
  if pathText starts with "~/" then
    set homePath to POSIX path of (path to home folder)
    return homePath & text 3 thru -1 of pathText
  end if

  return pathText
end expandHomePath

------------------------------------------------------------------
-- Helper: fileExists
------------------------------------------------------------------
on fileExists(pathText)
  set commandText to "[ -e " & quoted form of pathText & " ] && echo 'true' || echo 'false'"
  return (do shell script commandText) is equal to "true"
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
-- Helper: resolveCommandPath
------------------------------------------------------------------
on resolveCommandPath(sourcePath, commandName)
  log "DEBUG -> resolveCommandPath: " & commandName & " using " & sourcePath
  set commandText to "source " & quoted form of sourcePath & " >/dev/null 2>&1; command -v " & commandName & "; exit 0;"
  set commandPath to do shell script commandText
  log "DEBUG -> resolveCommandPath: " & commandName & " -> " & commandPath
  return commandPath
end resolveCommandPath

------------------------------------------------------------------
-- Helper: splitWords
------------------------------------------------------------------
on splitWords(textValue)
  if textValue is "" then
    return {}
  end if

  set parsedItems to {}
  set currentItem to ""

  repeat with i from 1 to (length of textValue)
    set currentChar to character i of textValue
    if currentChar is " " or currentChar is tab or currentChar is return or currentChar is linefeed then
      if currentItem is not "" then
        set parsedItems to parsedItems & {currentItem}
        set currentItem to ""
      end if
    else
      set currentItem to currentItem & currentChar
    end if
  end repeat

  if currentItem is not "" then
    set parsedItems to parsedItems & {currentItem}
  end if

  return parsedItems
end splitWords

------------------------------------------------------------------
-- Helper: parseArgs
------------------------------------------------------------------
on parseArgs(argv)
  log "DEBUG -> parseArgs: argv count=" & (count of argv)
  set dryRun to false
  set noNotify to false
  set sourceOverride to ""
  set npmPathOverride to ""
  set nvmPathOverride to ""
  set currentDefaultOverride to ""
  set majorVersionsOverride to {}
  set otherVersionsOverride to {}

  set i to 1
  repeat while i <= (count of argv)
    set arg to item i of argv

    if arg is "--" then
      set noop to true
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
    else if arg is "--npm-path" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --npm-path."
      end if
      set npmPathOverride to item i of argv
      log "DEBUG -> parseArgs: npmPathOverride=" & npmPathOverride
    else if arg is "--nvm-path" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --nvm-path."
      end if
      set nvmPathOverride to item i of argv
      log "DEBUG -> parseArgs: nvmPathOverride=" & nvmPathOverride
    else if arg is "--current-default" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --current-default."
      end if
      set currentDefaultOverride to item i of argv
      log "DEBUG -> parseArgs: currentDefaultOverride=" & currentDefaultOverride
    else if arg is "--major-versions" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --major-versions."
      end if
      set majorVersionsOverride to my splitWords(item i of argv)
      log "DEBUG -> parseArgs: majorVersionsOverride=" & (item i of argv)
    else if arg is "--other-versions" then
      set i to i + 1
      if i > (count of argv) then
        error "Missing value for --other-versions."
      end if
      set otherVersionsOverride to my splitWords(item i of argv)
      log "DEBUG -> parseArgs: otherVersionsOverride=" & (item i of argv)
    else
      error "Unknown argument: " & arg
    end if

    set i to i + 1
  end repeat

  log "DEBUG -> parseArgs result: dryRun=" & dryRun
  log "DEBUG -> parseArgs result: noNotify=" & noNotify
  return {dryRun, noNotify, sourceOverride, npmPathOverride, nvmPathOverride, currentDefaultOverride, majorVersionsOverride, otherVersionsOverride}
end parseArgs

------------------------------------------------------------------
-- Core: buildDryRunMessage
------------------------------------------------------------------
on buildDryRunMessage(sourcePath, npmLocation, nvmLocation, currentDefault, majorVersions, otherVersions)
  log "DEBUG -> buildDryRunMessage: sourcePath=" & sourcePath
  log "DEBUG -> buildDryRunMessage: npmLocation=" & npmLocation
  log "DEBUG -> buildDryRunMessage: nvmLocation=" & nvmLocation
  set resultMessage to "Would run:" & return
  set commandPrefix to "source " & quoted form of sourcePath & " && "

  if npmLocation ends with "npm" then
    set resultMessage to resultMessage & commandPrefix & "find `npm list -g | head -1` -name '.DS_Store' -type f -delete" & return
    set resultMessage to resultMessage & commandPrefix & quoted form of npmLocation & " -g update" & return
  else
    set resultMessage to resultMessage & "NPM not found; skipping npm update." & return
  end if

  if nvmLocation ends with "nvm" then
    if majorVersions is not {} then
      repeat with majorVersion in majorVersions
        set resultMessage to resultMessage & commandPrefix & nvmLocation & " install " & (contents of majorVersion) & return
      end repeat
    end if

    if currentDefault is not "" then
      set resultMessage to resultMessage & commandPrefix & nvmLocation & " alias default " & currentDefault & return
    end if

    if otherVersions is not {} and currentDefault is not "" then
      repeat with otherVersion in otherVersions
        set resultMessage to resultMessage & commandPrefix & nvmLocation & " use " & (contents of otherVersion) & " && " & nvmLocation & " reinstall-packages " & currentDefault & return
      end repeat
    end if
  else
    set resultMessage to resultMessage & "NVM not found; skipping nvm update." & return
  end if

  if resultMessage ends with return then
    set resultMessage to text 1 thru -2 of resultMessage
  end if

  return resultMessage
end buildDryRunMessage

------------------------------------------------------------------
-- Core: runNpmUpdate
------------------------------------------------------------------
on runNpmUpdate(sourcePath, npmLocation, dryRun, noNotify)
  log "DEBUG -> runNpmUpdate: npmLocation=" & npmLocation
  log "DEBUG -> runNpmUpdate: dryRun=" & dryRun
  log "DEBUG -> runNpmUpdate: noNotify=" & noNotify
  if (npmLocation ends with "npm") is false then
    log "DEBUG -> runNpmUpdate: npm not found"
    return "NPM not found."
  end if

  if dryRun then
    log "DEBUG -> runNpmUpdate: dry run mode"
    return "NPM dry run."
  end if

  if noNotify is false then
    log "DEBUG -> runNpmUpdate: showing start notification"
    display notification "Updating NPM packages ..." with title notificationTitle
  end if

  log "DEBUG -> runNpmUpdate: running .DS_Store cleanup"
  do shell script "source " & quoted form of sourcePath & " && find `npm list -g | head -1` -name '.DS_Store' -type f -delete"
  log "DEBUG -> runNpmUpdate: running npm update"
  do shell script "source " & quoted form of sourcePath & " && " & quoted form of npmLocation & " -g update"

  log "DEBUG -> runNpmUpdate: completed"
  return "NPM updated."
end runNpmUpdate

------------------------------------------------------------------
-- Core: runNvmUpdate
------------------------------------------------------------------
on runNvmUpdate(sourcePath, nvmLocation, dryRun, noNotify, currentDefaultOverride, majorVersionsOverride, otherVersionsOverride)
  log "DEBUG -> runNvmUpdate: nvmLocation=" & nvmLocation
  log "DEBUG -> runNvmUpdate: dryRun=" & dryRun
  log "DEBUG -> runNvmUpdate: noNotify=" & noNotify
  if (nvmLocation ends with "nvm") is false then
    log "DEBUG -> runNvmUpdate: nvm not found"
    return "NVM not found."
  end if

  set currentNodeVersion to ""
  set majorNodeVersions to {}
  set otherNodeVersions to {}
  set otherOverrideProvided to (otherVersionsOverride is not {})

  if currentDefaultOverride is not "" then
    log "DEBUG -> runNvmUpdate: using currentDefaultOverride=" & currentDefaultOverride
    set currentNodeVersion to currentDefaultOverride
  else
    set currentNodeVersion to do shell script "source " & quoted form of sourcePath & " && " & nvmLocation & " version default"
  end if

  if majorVersionsOverride is not {} then
    log "DEBUG -> runNvmUpdate: using majorVersionsOverride"
    set majorNodeVersions to majorVersionsOverride
  else
    set majorNodeVersions to my splitWords(do shell script "source " & quoted form of sourcePath & " && " & nvmLocation & " ls | grep -B9999999 'default' | grep -Eo 'v[0-9]+' | sort -u | tr '\\n' ' '")
  end if

  if otherVersionsOverride is not {} then
    log "DEBUG -> runNvmUpdate: using otherVersionsOverride"
    set otherNodeVersions to otherVersionsOverride
  else
    set otherNodeVersions to my splitWords(do shell script "source " & quoted form of sourcePath & " && " & nvmLocation & " ls --no-colors | grep -v '\\->' | awk '{printf \"%s \", $1}'")
  end if

  log "DEBUG -> runNvmUpdate: currentNodeVersion=" & currentNodeVersion
  log "DEBUG -> runNvmUpdate: majorNodeVersions count=" & (count of majorNodeVersions)
  log "DEBUG -> runNvmUpdate: otherNodeVersions count=" & (count of otherNodeVersions)

  if dryRun then
    log "DEBUG -> runNvmUpdate: dry run mode"
    return "NVM dry run."
  end if

  if majorNodeVersions is not {} then
    repeat with majorNodeVersion in majorNodeVersions
      log "DEBUG -> runNvmUpdate: install " & (contents of majorNodeVersion)
      if noNotify is false then
        display notification "Installing the latest Node.js version for " & majorNodeVersion & " ..." with title notificationTitle subtitle "Running command"
      end if
      do shell script "source " & quoted form of sourcePath & " && " & nvmLocation & " install " & (contents of majorNodeVersion)
    end repeat
  end if

  if currentNodeVersion is not "" then
    log "DEBUG -> runNvmUpdate: alias default " & currentNodeVersion
    do shell script "source " & quoted form of sourcePath & " && " & nvmLocation & " alias default " & currentNodeVersion
  end if

  if otherOverrideProvided is false then
    set otherNodeVersions to my splitWords(do shell script "source " & quoted form of sourcePath & " && " & nvmLocation & " ls --no-colors | grep -v '\\->' | awk '{printf \"%s \", $1}'")
    log "DEBUG -> runNvmUpdate: refreshed otherNodeVersions count=" & (count of otherNodeVersions)
  end if

  if otherNodeVersions is not {} then
    repeat with otherNodeVersion in otherNodeVersions
      log "DEBUG -> runNvmUpdate: reinstall packages for " & (contents of otherNodeVersion)
      if noNotify is false then
        display notification "Reinstalling packages for Node.js " & otherNodeVersion & " from " & currentNodeVersion & " ..." with title notificationTitle subtitle "Running command"
      end if
      do shell script "source " & quoted form of sourcePath & " && " & nvmLocation & " use " & (contents of otherNodeVersion) & " && " & nvmLocation & " reinstall-packages " & currentNodeVersion
    end repeat
  end if

  log "DEBUG -> runNvmUpdate: completed"
  return "NVM updated."
end runNvmUpdate

------------------------------------------------------------------
-- Core: runUpdateFlow
------------------------------------------------------------------
on runUpdateFlow(sourcePath, npmLocation, nvmLocation, dryRun, noNotify, currentDefaultOverride, majorVersionsOverride, otherVersionsOverride)
  log "DEBUG -> runUpdateFlow: sourcePath=" & sourcePath
  log "DEBUG -> runUpdateFlow: npmLocation=" & npmLocation
  log "DEBUG -> runUpdateFlow: nvmLocation=" & nvmLocation
  log "DEBUG -> runUpdateFlow: dryRun=" & dryRun
  log "DEBUG -> runUpdateFlow: noNotify=" & noNotify
  if dryRun then
    log "DEBUG -> runUpdateFlow: dry run mode"
    return my buildDryRunMessage(sourcePath, npmLocation, nvmLocation, currentDefaultOverride, majorVersionsOverride, otherVersionsOverride)
  end if

  my runNpmUpdate(sourcePath, npmLocation, dryRun, noNotify)
  my runNvmUpdate(sourcePath, nvmLocation, dryRun, noNotify, currentDefaultOverride, majorVersionsOverride, otherVersionsOverride)

  if noNotify is false then
    log "DEBUG -> runUpdateFlow: showing completion notification"
    display notification "All Node.js versions and NPM packages have been successfully updated!" with title notificationTitle sound name notificationSound
  end if

  log "DEBUG -> runUpdateFlow: completed"
  return "Update completed."
end runUpdateFlow

------------------------------------------------------------------
-- Entry: runWithArgs
------------------------------------------------------------------
on runWithArgs(argv)
  log "DEBUG -> runWithArgs: start"
  set {dryRun, noNotify, sourceOverride, npmPathOverride, nvmPathOverride, currentDefaultOverride, majorVersionsOverride, otherVersionsOverride} to my parseArgs(argv)

  if sourceOverride is "" then
    set sourcePath to my findFirstSourceFile(sourceCandidates)
  else
    set sourcePath to my expandHomePath(sourceOverride)
    log "DEBUG -> runWithArgs: sourceOverride=" & sourcePath
  end if

  if sourcePath is "" then
    error "Unable to determine if Node.js or NVM is installed. The source file (e.g. \"~/.zshrc\") cannot be located."
  end if

  if my fileExists(sourcePath) is false then
    error "Source file not found: " & sourcePath
  end if

  if npmPathOverride is not "" then
    set npmLocation to npmPathOverride
    log "DEBUG -> runWithArgs: npmPathOverride=" & npmLocation
  else
    set npmLocation to my resolveCommandPath(sourcePath, "npm")
  end if

  if nvmPathOverride is not "" then
    set nvmLocation to nvmPathOverride
    log "DEBUG -> runWithArgs: nvmPathOverride=" & nvmLocation
  else
    set nvmLocation to my resolveCommandPath(sourcePath, "nvm")
  end if

  log "DEBUG -> runWithArgs: currentDefaultOverride=" & currentDefaultOverride
  log "DEBUG -> runWithArgs: majorVersionsOverride count=" & (count of majorVersionsOverride)
  log "DEBUG -> runWithArgs: otherVersionsOverride count=" & (count of otherVersionsOverride)
  return my runUpdateFlow(sourcePath, npmLocation, nvmLocation, dryRun, noNotify, currentDefaultOverride, majorVersionsOverride, otherVersionsOverride)
end runWithArgs

------------------------------------------------------------------
-- Entry: runInteractive
------------------------------------------------------------------
on runInteractive()
  log "DEBUG -> runInteractive: start"
  set sourcePath to my findFirstSourceFile(sourceCandidates)

  if sourcePath is "" then
    display dialog "Unable to determine if Node.js or NVM is installed. The source file (e.g. \"~/.zshrc\") cannot be located." with icon stop buttons {"OK"} default button "OK"
    return
  end if

  set npmLocation to my resolveCommandPath(sourcePath, "npm")
  set nvmLocation to my resolveCommandPath(sourcePath, "nvm")

  my runUpdateFlow(sourcePath, npmLocation, nvmLocation, false, false, "", {}, {})
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
