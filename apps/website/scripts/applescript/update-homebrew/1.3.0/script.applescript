use framework "Foundation"
use scripting additions

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
-- Helper: trimTrailingLineEndings
------------------------------------------------------------------
on trimTrailingLineEndings(theText)
	set trimmedText to theText as text
	repeat while trimmedText ends with linefeed or trimmedText ends with return
		if (count of trimmedText) is 1 then
			set trimmedText to ""
		else
			set trimmedText to text 1 thru -2 of trimmedText
		end if
	end repeat
	return trimmedText
end trimTrailingLineEndings

------------------------------------------------------------------
-- Helper: readUtf8File
------------------------------------------------------------------
on readUtf8File(filePath)
	set fileData to current application's NSData's dataWithContentsOfFile:filePath
	if fileData is missing value then return ""
	set fileText to current application's NSString's alloc()'s initWithData:fileData encoding:(current application's NSUTF8StringEncoding)
	if fileText is missing value then error "Shell command returned output that is not valid UTF-8."
	return fileText as text
end readUtf8File

------------------------------------------------------------------
-- Helper: removeTemporaryFile
------------------------------------------------------------------
on removeTemporaryFile(filePath)
	if filePath is missing value then return
	current application's NSFileManager's defaultManager()'s removeItemAtPath:filePath |error|:(missing value)
end removeTemporaryFile

------------------------------------------------------------------
-- Helper: yieldForUi
------------------------------------------------------------------
on yieldForUi(secondsValue)
	current application's NSRunLoop's currentRunLoop()'s runUntilDate:(current application's NSDate's dateWithTimeIntervalSinceNow:secondsValue)
end yieldForUi

------------------------------------------------------------------
-- Helper: doShell
--
-- Runs the shell command while pumping the UI run loop. Returns
-- stdout on success and raises stderr with the shell exit status
-- when the command fails.
------------------------------------------------------------------
on doShell(commandText)
	set uniqueId to current application's NSUUID's UUID()'s UUIDString() as text
	set tempDirectory to current application's NSTemporaryDirectory() as text
	set stdoutPath to tempDirectory & "applescript-shell-" & uniqueId & ".stdout"
	set stderrPath to tempDirectory & "applescript-shell-" & uniqueId & ".stderr"
	set stdoutHandle to missing value
	set stderrHandle to missing value
	set shellTask to missing value

	try
		set fileManager to current application's NSFileManager's defaultManager()
		set secureFileAttributes to current application's NSDictionary's dictionaryWithObject:384 forKey:(current application's NSFilePosixPermissions)
		set createdStdout to fileManager's createFileAtPath:stdoutPath |contents|:(missing value) attributes:secureFileAttributes
		set createdStderr to fileManager's createFileAtPath:stderrPath |contents|:(missing value) attributes:secureFileAttributes
		if not (createdStdout as boolean) or not (createdStderr as boolean) then error "Could not create temporary shell output files."
		set stdoutHandle to current application's NSFileHandle's fileHandleForWritingAtPath:stdoutPath
		set stderrHandle to current application's NSFileHandle's fileHandleForWritingAtPath:stderrPath
		if stdoutHandle is missing value or stderrHandle is missing value then error "Could not open temporary shell output files."

		set shellTask to current application's NSTask's alloc()'s init()
		shellTask's setLaunchPath:"/bin/zsh"
		shellTask's setArguments:{"-c", commandText}
		shellTask's setStandardInput:(current application's NSFileHandle's fileHandleWithNullDevice())
		shellTask's setStandardOutput:stdoutHandle
		shellTask's setStandardError:stderrHandle
		shellTask's |launch|()

		repeat while (shellTask's isRunning() as boolean)
			current application's NSRunLoop's currentRunLoop()'s runUntilDate:(current application's NSDate's dateWithTimeIntervalSinceNow:0.05)
		end repeat
		shellTask's waitUntilExit()
		stdoutHandle's closeFile()
		stderrHandle's closeFile()
		set stdoutHandle to missing value
		set stderrHandle to missing value

		set stdoutText to my trimTrailingLineEndings(my readUtf8File(stdoutPath))
		set stderrText to my trimTrailingLineEndings(my readUtf8File(stderrPath))
		set exitStatus to shellTask's terminationStatus() as integer
		my removeTemporaryFile(stdoutPath)
		my removeTemporaryFile(stderrPath)

		if exitStatus is not 0 then
			if stderrText is not "" then error stderrText number exitStatus
			if stdoutText is not "" then error stdoutText number exitStatus
			error "Shell command failed with exit status " & exitStatus & "." number exitStatus
		end if

		return stdoutText
	on error errMsg number errNum
		try
			if shellTask is not missing value and (shellTask's isRunning() as boolean) then
				shellTask's terminate()
				set terminationDeadline to current application's NSDate's dateWithTimeIntervalSinceNow:1
				repeat while (shellTask's isRunning() as boolean) and ((terminationDeadline's timeIntervalSinceNow()) as real) > 0
					current application's NSRunLoop's currentRunLoop()'s runUntilDate:(current application's NSDate's dateWithTimeIntervalSinceNow:0.05)
				end repeat
				if shellTask's isRunning() as boolean then
					shellTask's interrupt()
					set interruptDeadline to current application's NSDate's dateWithTimeIntervalSinceNow:1
					repeat while (shellTask's isRunning() as boolean) and ((interruptDeadline's timeIntervalSinceNow()) as real) > 0
						current application's NSRunLoop's currentRunLoop()'s runUntilDate:(current application's NSDate's dateWithTimeIntervalSinceNow:0.05)
					end repeat
					if shellTask's isRunning() as boolean then
						set killTask to current application's NSTask's launchedTaskWithLaunchPath:"/bin/kill" arguments:{"-KILL", (shellTask's processIdentifier() as text)}
						killTask's waitUntilExit()
						shellTask's waitUntilExit()
					end if
				end if
			end if
		end try
		try
			if stdoutHandle is not missing value then stdoutHandle's closeFile()
		end try
		try
			if stderrHandle is not missing value then stderrHandle's closeFile()
		end try
		my removeTemporaryFile(stdoutPath)
		my removeTemporaryFile(stderrPath)
		error errMsg number errNum
	end try
end doShell

------------------------------------------------------------------
-- Helper: resolveCommandPath
------------------------------------------------------------------
on resolveCommandPath(sourcePath, commandName)
	log "DEBUG -> resolveCommandPath: " & commandName & " using " & sourcePath
	set zshScript to "source " & quoted form of sourcePath & " >/dev/null 2>&1; command -v " & quoted form of commandName & "; exit 0;"
	set commandPath to my doShell(zshScript)
	log "DEBUG -> resolveCommandPath: " & commandName & " -> " & commandPath
	return commandPath
end resolveCommandPath

------------------------------------------------------------------
-- Core: runUpdate
------------------------------------------------------------------
on runUpdate(sourcePath, brewPath)
	log "DEBUG -> runUpdate: start"
	set brewPrefix to "source " & quoted form of sourcePath & " >/dev/null && " & quoted form of brewPath

	-- Step 1: Update formulae definitions
	log "DEBUG -> runUpdate: updating formulae definitions"
	display notification "Updating Homebrew formulae definitions ..." with title notificationTitle
	my doShell(brewPrefix & " update")
	log "DEBUG -> runUpdate: update completed"

	-- Step 2: Upgrade all outdated formulae and cask apps
	log "DEBUG -> runUpdate: upgrading outdated packages"
	display notification "Upgrading outdated packages ..." with title notificationTitle
	my doShell(brewPrefix & " upgrade --greedy")
	log "DEBUG -> runUpdate: upgrade completed"

	-- Step 3: Clean up old versions and cache
	log "DEBUG -> runUpdate: cleaning up old versions"
	display notification "Cleaning up old versions ..." with title notificationTitle
	my doShell(brewPrefix & " cleanup")
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
