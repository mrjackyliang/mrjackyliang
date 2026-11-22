-- ======================================================================================================================
-- Update Homebrew
--
-- Updates Homebrew formulae definitions, upgrades all outdated packages (including cask applications), and cleans up
-- old versions.
--
-- Notes:
-- * Requires Homebrew (https://brew.sh)
-- * This script is interactive only
--
-- Good to know:
-- * Upgrades all outdated packages without per-package confirmation
-- * "brew cleanup" removes old versions, preventing rollback to those versions
--
-- Accepted Risks:
-- * Sources your shell profile (e.g. "~/.zshrc") to locate Homebrew; a compromised profile affects all shell operations
-- ======================================================================================================================

------------------------------------------------------------------
-- Properties
------------------------------------------------------------------
property sourceCandidates : {"~/.zshrc", "~/.zprofile", "~/.bashrc", "~/.bash_profile", "~/.profile"}
property notificationTitle : "Update Homebrew"
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
-- Helper: findSourceForCommand
------------------------------------------------------------------
on findSourceForCommand(candidateList, commandName)
	set anyProfileFound to false
	repeat with sourcePath in candidateList
		set fullSourcePath to my expandHomePath(contents of sourcePath)
		log "DEBUG -> checking source: " & fullSourcePath
		if my fileExists(fullSourcePath) then
			set anyProfileFound to true
			set cmdPath to my resolveCommandPath(fullSourcePath, commandName)
			if cmdPath is not "" then
				log "DEBUG -> found " & commandName & " via " & fullSourcePath
				return {sourcePath:fullSourcePath, commandPath:cmdPath, profileFound:true}
			end if
			log "DEBUG -> " & commandName & " not found via " & fullSourcePath
		end if
	end repeat

	-- Fallback: try without any profile source (command may be in default PATH)
	log "DEBUG -> trying bare command lookup for " & commandName
	try
		set cmdPath to do shell script "command -v " & quoted form of commandName & " 2>/dev/null"
		if cmdPath is not "" then
			log "DEBUG -> found " & commandName & " in default PATH: " & cmdPath
			return {sourcePath:"/dev/null", commandPath:cmdPath, profileFound:anyProfileFound}
		end if
	end try

	log "DEBUG -> no source file found for " & commandName
	return {sourcePath:"", commandPath:"", profileFound:anyProfileFound}
end findSourceForCommand

------------------------------------------------------------------
-- Helper: resolveCommandPath
------------------------------------------------------------------
on resolveCommandPath(sourcePath, commandName)
	log "DEBUG -> resolveCommandPath: " & commandName & " using " & sourcePath
	set commandText to "source " & quoted form of sourcePath & " >/dev/null 2>&1; command -v " & quoted form of commandName & "; exit 0;"
	set commandPath to do shell script commandText
	log "DEBUG -> resolveCommandPath: " & commandName & " -> " & commandPath
	return commandPath
end resolveCommandPath

------------------------------------------------------------------
-- Core: runUpdate
------------------------------------------------------------------
on runUpdate(sourcePath, brewPath)
	log "DEBUG -> runUpdate: start"
	set brewPrefix to "source " & quoted form of sourcePath & " >/dev/null 2>&1 && " & quoted form of brewPath

	-- Step 1: Update formulae definitions
	log "DEBUG -> runUpdate: updating formulae definitions"
	display notification "Updating Homebrew formulae definitions ..." with title notificationTitle
	do shell script brewPrefix & " update"
	log "DEBUG -> runUpdate: update completed"

	-- Step 2: Upgrade all outdated formulae and cask apps
	log "DEBUG -> runUpdate: upgrading outdated packages"
	display notification "Upgrading outdated packages ..." with title notificationTitle
	do shell script brewPrefix & " upgrade --greedy"
	log "DEBUG -> runUpdate: upgrade completed"

	-- Step 3: Clean up old versions and cache
	log "DEBUG -> runUpdate: cleaning up old versions"
	display notification "Cleaning up old versions ..." with title notificationTitle
	do shell script brewPrefix & " cleanup"
	log "DEBUG -> runUpdate: cleanup completed"

	-- Done
	log "DEBUG -> runUpdate: showing completion notification"
	display notification "Homebrew has been successfully updated!" with title notificationTitle sound name notificationSound

	log "DEBUG -> runUpdate: completed"
end runUpdate

------------------------------------------------------------------
-- Entry: run
------------------------------------------------------------------
on run argv
	if (count of argv) > 0 then
		display dialog "This script must be run interactively. Command-line arguments are not supported." buttons {"OK"} with icon stop default button "OK"
		return
	end if

	try
		log "DEBUG -> run: start"
		set searchResult to my findSourceForCommand(sourceCandidates, "brew")

		if (commandPath of searchResult) is "" and not (profileFound of searchResult) then
			display dialog "Unable to locate a shell profile (e.g. \"~/.zshrc\"). Cannot determine if Homebrew is installed." with icon stop buttons {"OK"} default button "OK"
			return
		end if

		set sourcePath to sourcePath of searchResult
		set brewPath to commandPath of searchResult

		if brewPath is "" then
			display dialog "Homebrew is not installed or could not be found. Please install it from https://brew.sh and try again." buttons {"OK"} with icon stop default button "OK"
			return
		end if

		my runUpdate(sourcePath, brewPath)
		log "DEBUG -> run: done"
	on error errMsg number errNum
		if errMsg contains "User canceled" or errNum is equal to -128 then
			return
		end if
		display dialog errMsg buttons {"OK"} with icon stop default button "OK"
	end try
end run
