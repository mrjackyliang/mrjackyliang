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

------------------------------------------------------------------
-- Properties
------------------------------------------------------------------
property processGroups : {{"iPhone Sync Processes", {"AMPDeviceDiscoveryAgent", "AMPLibraryAgent", "MDCrashReportTool", "MobileDeviceUpdater"}}, {"macOS UI Processes", {"ControlCenter", "Dock", "NotificationCenter", "SystemUIServer"}}}
property dependentAppBundleIDs : {"com.surteesstudios.Bartender"}
property notificationTitle : "Fix macOS Glitches"

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
					tell application id idText to quit
				on error errorMessage number errorNumber
					log "DEBUG -> Failed to quit dependent app " & idText & " - " & errorMessage
				end try
			else
				log "DEBUG -> Dependent app not running; will not relaunch: " & idText
			end if
		end repeat

		log "DEBUG -> dependentBundleIDsToRelaunch: " & my joinList(dependentBundleIDsToRelaunch, ", ")

		delay 1
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
			try
				log "DEBUG -> killall starting: " & processNameText
				do shell script "killall " & quoted form of processNameText
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
			set launchdLabel to do shell script "launchctl list | grep -F " & quoted form of processNameText & " | awk '{print $3}' | head -1"
			if launchdLabel is not "" then
				log "DEBUG -> Restarting via launchctl: " & processNameText & " (" & launchdLabel & ")"
				do shell script "launchctl kickstart gui/$(id -u)/" & quoted form of launchdLabel
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
		delay 1
		try
			do shell script "killall Finder"
		end try
	end if

	-- Relaunch dependent apps after SystemUIServer restarts.
	if willTerminateSystemUIServer then
		log "DEBUG -> Waiting for SystemUIServer to restart."

		repeat 20 times
			try
				do shell script "pgrep -x " & quoted form of "SystemUIServer"
				exit repeat
			end try
			delay 0.5
		end repeat
		delay 2 -- stabilization delay for SystemUIServer to fully initialize

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

		set resultMessage to my fixGlitches(selectedProcessGroupNames)
		display dialog resultMessage with title notificationTitle buttons {"OK"} default button "OK"
	on error errMsg number errNum
		if errMsg is "User canceled." or errNum is -128 then
			return
		end if

		display dialog errMsg buttons {"OK"} with icon stop default button "OK"
	end try
end run
