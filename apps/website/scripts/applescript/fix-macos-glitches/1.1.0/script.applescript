set processes to {"AMPDeviceDiscoveryAgent", "AMPLibraryAgent", "MDCrashReportTool", "MobileDeviceUpdater"}
set killedProcesses to {}

-- Loop through all the suspected processes.
repeat with process in processes
	-- If "pgrep" returns a process number, this will return zero (assuming no errors).
	set isRunning to (do shell script "pgrep " & process & " > /dev/null; echo $?") as integer
	
	-- Check if the current process is running.	
	if isRunning = 0 then
		-- Kill the process.
		do shell script "killall -9 " & process
		
		-- Record that the process has been killed.
		set end of killedProcesses to process as string
	end if
end repeat

-- Convert the lists into a displayable list for dialog.
set killedProcessesString to ""

-- Set the killed processes into a string.
repeat with killedProcess in killedProcesses
	set killedProcessesString to killedProcessesString & return & "- " & killedProcess
end repeat

if killedProcessesString = "" then
	display dialog "There doesn't seem to be any stuck processes affecting your iPhone syncing." buttons {"OK"} default button "OK"
else
	display dialog "iPhone syncing should now be unstuck. Here are a list of processes that are terminated:" & return & killedProcessesString as string buttons {"OK"} default button "OK"
end if
