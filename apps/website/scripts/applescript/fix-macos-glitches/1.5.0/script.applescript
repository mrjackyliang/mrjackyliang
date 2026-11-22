-- ======================================================================================
-- Fix macOS Glitches
--
-- Restarts system UI processes and iPhone sync processes to fix common macOS
-- glitches (frozen Dock, broken menu bar, stuck sync, etc.).
--
-- Notes:
-- * Killed processes are restarted via "launchctl kickstart"
-- * This script is interactive only
--
-- Good to know:
-- * Killing system UI processes causes temporary visual disruption
-- * Restarting iPhone sync processes also restarts Finder to refresh the device sidebar
-- ======================================================================================

use framework "Foundation"
use framework "AppKit"
use scripting additions

------------------------------------------------------------------
-- Properties
------------------------------------------------------------------
property processGroups : {{"iPhone Sync Processes", {"AMPDeviceDiscoveryAgent", "AMPLibraryAgent", "MDCrashReportTool", "MobileDeviceUpdater"}}, {"macOS UI Processes", {"ControlCenter", "Dock", "NotificationCenter", "SystemUIServer"}}}
property dependentAppBundleIDs : {"com.surteesstudios.Bartender"}
property notificationTitle : "Fix macOS Glitches"

------------------------------------------------------------------
-- Helpers: responsive shell execution
------------------------------------------------------------------
on yieldForUi(waitSeconds)
	set deadlineDate to current application's NSDate's dateWithTimeIntervalSinceNow:waitSeconds
	repeat while (deadlineDate's timeIntervalSinceNow() as real) > 0
		current application's NSRunLoop's currentRunLoop()'s runUntilDate:(current application's NSDate's dateWithTimeIntervalSinceNow:0.05)
	end repeat
end yieldForUi

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

on readUtf8File(filePath)
	set fileData to current application's NSData's dataWithContentsOfFile:filePath
	if fileData is missing value then return ""
	set fileText to current application's NSString's alloc()'s initWithData:fileData encoding:(current application's NSUTF8StringEncoding)
	if fileText is missing value then error "Shell command returned output that is not valid UTF-8."
	return fileText as text
end readUtf8File

on removeTemporaryFile(filePath)
	if filePath is missing value then return
	current application's NSFileManager's defaultManager()'s removeItemAtPath:filePath |error|:(missing value)
end removeTemporaryFile

on doShellResponsive(commandText)
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
end doShellResponsive

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
-- Core: buildResultMessage
------------------------------------------------------------------
on buildResultMessage(terminatedProcessNames, notRunningProcessNames, failedTerminationNames)
	set resultMessage to ""
	set hasEntries to false

	if terminatedProcessNames is not {} then
		set hasEntries to true
		set resultMessage to resultMessage & "These processes were restarted:" & return

		repeat with processName in terminatedProcessNames
			set resultMessage to resultMessage & " - " & processName & return
		end repeat
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

	if failedTerminationNames is not {} then
		set hasEntries to true

		if resultMessage is not "" then
			set resultMessage to resultMessage & return
		end if

		set resultMessage to resultMessage & "These processes could not be restarted:" & return

		repeat with processName in failedTerminationNames
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
-- Core: fixGlitches
------------------------------------------------------------------
on fixGlitches(selectedProcessGroupNames)
	set processGroupNames to my buildProcessGroupNames(processGroups)
	log "DEBUG -> processGroupNames: " & my joinList(processGroupNames, ", ")
	log "DEBUG -> selectedProcessGroupNames: " & my joinList(selectedProcessGroupNames, ", ")

	set targetProcessNames to my collectTargetProcesses(processGroups, selectedProcessGroupNames)

	if targetProcessNames is {} then
		error "No matching process groups selected."
	end if

	log "DEBUG -> targetProcessNames: " & my joinList(targetProcessNames, ", ")

	set terminatedProcessNames to {}
	set notRunningProcessNames to {}
	set failedTerminationNames to {}

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

				try
					log "DEBUG -> Quitting dependent app: " & idText
					set runningApps to current application's NSRunningApplication's runningApplicationsWithBundleIdentifier:idText
					set requestedTermination to true
					repeat with runningApp in runningApps
						if not (runningApp's terminate() as boolean) then set requestedTermination to false
					end repeat
					if not requestedTermination then log "DEBUG -> Dependent app declined termination request: " & idText
				on error errorMessage number errorNumber
					log "DEBUG -> Failed to quit dependent app " & idText & " - " & errorMessage
				end try
			else
				log "DEBUG -> Dependent app not running; will not relaunch: " & idText
			end if
		end repeat

		log "DEBUG -> dependentBundleIDsToRelaunch: " & my joinList(dependentBundleIDsToRelaunch, ", ")

		my yieldForUi(1)
	else
		log "DEBUG -> SystemUIServer not selected. No dependent-app pre-quit needed."
	end if

	-- Main kill loop.
	repeat with processName in targetProcessNames
		set processNameText to (contents of processName)
		log "DEBUG -> Checking process: " & processNameText

		set isRunningInteger to (my doShellResponsive("pgrep -x " & quoted form of processNameText & " >/dev/null; echo $?")) as integer
		log "DEBUG -> pgrep exit code for " & processNameText & ": " & isRunningInteger

		if isRunningInteger is 0 then
			try
				log "DEBUG -> killall starting: " & processNameText
				my doShellResponsive("killall " & quoted form of processNameText)
				set end of terminatedProcessNames to processNameText
				log "DEBUG -> Terminated process: " & processNameText
			on error errorMessage number errorNumber
				log "DEBUG -> Failed to terminate " & processNameText & " - " & errorMessage
				set end of failedTerminationNames to processNameText
			end try
		else
			set end of notRunningProcessNames to processNameText
			log "DEBUG -> Process not running: " & processNameText
		end if
	end repeat

	-- Restart killed processes via launchctl (on-demand processes don't auto-respawn)
	repeat with processName in terminatedProcessNames
		set processNameText to (contents of processName)
		try
			set launchdLabel to my doShellResponsive("launchctl list | grep -F " & quoted form of processNameText & " | awk '{print $3}' | head -1")
			if launchdLabel is not "" then
				log "DEBUG -> Restarting via launchctl: " & processNameText & " (" & launchdLabel & ")"
				my doShellResponsive("launchctl kickstart gui/$(id -u)/" & quoted form of launchdLabel)
				log "DEBUG -> Restarted: " & processNameText
			else
				log "DEBUG -> No launchctl label found for " & processNameText & "; relying on auto-respawn"
			end if
		on error errorMessage
			log "DEBUG -> launchctl restart skipped for " & processNameText & ": " & errorMessage
		end try
	end repeat

	-- Restart Finder if any iPhone sync processes were restarted (so Finder detects connected devices)
	set iPhoneSyncProcesses to my collectTargetProcesses(processGroups, {"iPhone Sync Processes"})
	set needsFinderRestart to false
	repeat with processName in terminatedProcessNames
		if my listContains(iPhoneSyncProcesses, contents of processName) then
			set needsFinderRestart to true
			exit repeat
		end if
	end repeat
	if needsFinderRestart then
		log "DEBUG -> Restarting Finder to refresh device sidebar"
		my yieldForUi(1)
		try
			my doShellResponsive("killall Finder")
		end try
	end if

	-- Relaunch dependent apps after SystemUIServer restarts.
	if willTerminateSystemUIServer then
		log "DEBUG -> Waiting for SystemUIServer to restart."

		repeat 20 times
			try
				my doShellResponsive("pgrep -x " & quoted form of "SystemUIServer")
				exit repeat
			end try
			my yieldForUi(0.5)
		end repeat
		my yieldForUi(2) -- stabilization delay for SystemUIServer to fully initialize

		repeat with bundleID in dependentBundleIDsToRelaunch
			set idText to (contents of bundleID)
			try
				log "DEBUG -> Relaunching dependent app: " & idText
				my doShellResponsive("open -b " & quoted form of idText)
			on error errorMessage number errorNumber
				log "DEBUG -> Failed to relaunch dependent app " & idText & " - " & errorMessage
			end try
		end repeat

		log "DEBUG -> Dependent app relaunch loop finished."
	else
		log "DEBUG -> No dependent-app relaunch needed."
	end if

	log "DEBUG -> terminatedProcessNames: " & my joinList(terminatedProcessNames, ", ")
	log "DEBUG -> notRunningProcessNames: " & my joinList(notRunningProcessNames, ", ")

	return my buildResultMessage(terminatedProcessNames, notRunningProcessNames, failedTerminationNames)
end fixGlitches

------------------------------------------------------------------
-- Entry: run
------------------------------------------------------------------
on run argv
	if (count of argv) > 0 then
		display dialog "This script must be run interactively. Command-line arguments are not supported." buttons {"OK"} with icon stop default button "OK"
		return
	end if

	try
		set processGroupNames to my buildProcessGroupNames(processGroups)

		repeat with processGroup in processGroups
			set groupName to item 1 of processGroup
			set groupProcessList to my joinList(item 2 of processGroup, ", ")
			log "DEBUG -> processGroup: " & groupName & " - " & groupProcessList
		end repeat

		set selectedProcessGroupNames to (choose from list processGroupNames with title notificationTitle with prompt "Select the process groups you want to restart:" with multiple selections allowed without empty selection allowed)

		if selectedProcessGroupNames is false then
			error number -128
		end if
		my yieldForUi(0.2)

		set resultMessage to my fixGlitches(selectedProcessGroupNames)
		display dialog resultMessage with title notificationTitle buttons {"OK"} default button "OK"
	on error errMsg number errNum
		if errNum is -128 then
			return
		end if

		display dialog errMsg buttons {"OK"} with icon stop default button "OK"
	end try
end run
