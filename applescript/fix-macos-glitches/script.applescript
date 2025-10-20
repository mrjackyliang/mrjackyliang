------------------------------------------------------------------
-- Helper: turn any flat list into a comma-separated string
------------------------------------------------------------------
on joinList(theList, theDelimiter)
	set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, theDelimiter}
	set joinedText to theList as string
	set AppleScript's text item delimiters to oldDelims
	
	return joinedText
end joinList

------------------------------------------------------------------
-- 1.  Define the process-group collection
------------------------------------------------------------------
set processGroups to {{"iPhone Sync Processes", {"AMPDeviceDiscoveryAgent", "AMPLibraryAgent", "MDCrashReportTool", "MobileDeviceUpdater"}}, {"macOS UI Processes", {"ControlCenter", "Dock", "NotificationCenter", "SystemUIServer"}}}

repeat with processGroup in processGroups
	set groupName to item 1 of processGroup
	set groupProcessList to joinList(item 2 of processGroup, ", ")
	
	log "DEBUG -> processGroup: " & groupName & " — " & groupProcessList
end repeat

------------------------------------------------------------------
-- 2.  Build the list of group names for the menu
------------------------------------------------------------------
set processGroupNames to {}

repeat with processGroup in processGroups
	set end of processGroupNames to item 1 of processGroup
end repeat

log "DEBUG -> processGroupNames: " & joinList(processGroupNames, ", ")

------------------------------------------------------------------
-- 3.  Ask the user which group(s) to terminate
------------------------------------------------------------------
set selectedProcessGroupNames to (choose from list processGroupNames with prompt "Select the group(s) whose processes you want to terminate:" with multiple selections allowed without empty selection allowed)

if selectedProcessGroupNames is false then
	return
end if

log "DEBUG -> selectedProcessGroupNames: " & joinList(selectedProcessGroupNames, ", ")

------------------------------------------------------------------
-- 4.  Gather every process name from the chosen groups
------------------------------------------------------------------
set targetProcessNames to {}

repeat with selectedProcessGroupName in selectedProcessGroupNames
	repeat with processGroup in processGroups
		if item 1 of processGroup is (contents of selectedProcessGroupName) then
			set targetProcessNames to targetProcessNames & item 2 of processGroup
		end if
	end repeat
end repeat

log "DEBUG -> targetProcessNames: " & joinList(targetProcessNames, ", ")

------------------------------------------------------------------
-- 5.  Test each process; terminate if running
------------------------------------------------------------------
set terminatedProcessNames to {}
set notRunningProcessNames to {}

repeat with processName in targetProcessNames
	log "DEBUG -> Checking process: " & processName
	
	set isRunningInteger to (do shell script "pgrep -x " & quoted form of processName & " >/dev/null; echo $?") as integer
	
	if isRunningInteger is 0 then
		try
			do shell script "killall -9 " & quoted form of processName with administrator privileges
			
			set end of terminatedProcessNames to (contents of processName)
			
			log "DEBUG -> Terminated process: " & processName
		on error errorMessage number errorNumber
			log "DEBUG -> Failed to terminate " & processName & " — " & errorMessage
		end try
	else
		set end of notRunningProcessNames to (contents of processName)
		log "DEBUG -> Process not running: " & processName
	end if
end repeat

log "DEBUG -> terminatedProcessNames: " & joinList(terminatedProcessNames, ", ")
log "DEBUG -> notRunningProcessNames: " & joinList(notRunningProcessNames, ", ")

------------------------------------------------------------------
-- 6.  Build and display the result dialog
------------------------------------------------------------------
set resultMessage to ""

if terminatedProcessNames ≠ {} then
	set resultMessage to resultMessage & "These processes were terminated:" & return
	
	repeat with processName in terminatedProcessNames
		set resultMessage to resultMessage & " - " & processName & return
	end repeat
end if

if notRunningProcessNames ≠ {} then
	if resultMessage ≠ "" then set resultMessage to resultMessage & return
	
	set resultMessage to resultMessage & "These processes were not running:" & return
	
	repeat with processName in notRunningProcessNames
		set resultMessage to resultMessage & " - " & processName & return
	end repeat
end if

if resultMessage is "" then
	set resultMessage to "No selected processes were running."
end if

if resultMessage ends with return then
	set resultMessage to text 1 thru -2 of resultMessage
end if

display dialog resultMessage buttons {"OK"} default button "OK"