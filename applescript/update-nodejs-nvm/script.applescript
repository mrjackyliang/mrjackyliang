set sources to {"~/.bashrc", "~/.bash_profile", "~/.zshrc", "~/.zprofile", "~/.profile"}
set selectedSource to ""

set commands to {"npm", "nvm"}
set commandsToRun to {}

-- Find the source file to use.
repeat with source in sources
	-- Find the full path of the source file.
	set fullSourcePath to POSIX path of (path to home folder as text) & text 3 thru -1 of source
	
	-- If the source file exists, set it to the current source.
	if (do shell script "[ -e '" & fullSourcePath & "' ] && echo 'true' || echo 'false'") is equal to "true" then
		set selectedSource to fullSourcePath
		exit repeat
	end if
end repeat

-- A source file is required to continue.
if selectedSource is equal to "" then
	display dialog "Unable to determine if Node.js or NVM is installed. The source file (e.g. \"~/.zshrc\") cannot be located." with icon stop buttons {"OK"} default button "OK"
	quit
end if

-- Determine what available commands to run.
repeat with command in commands
	-- This will never crash. If it is empty string, command does not exist.
	set commandLocation to do shell script "source " & selectedSource & " && command -v " & command & "; exit 0;"
	
	-- If this is not empty string, it means the command exists.
	if commandLocation is not equal to "" then
		-- Check if command is Node Package Manager.
		if commandLocation ends with "npm" then
			-- Set the Node Package Manager commands to the "commandsToRun" list.
			set end of commandsToRun to commandLocation & " -g update"
		end if
		
		-- Check if command is Node Version Manager.
		if commandLocation ends with "nvm" then
			set currentNodeVersion to do shell script "source " & selectedSource & " && nvm version default"
			set majorNodeVersions to words of (do shell script "source " & selectedSource & " && nvm ls | grep -B9999999 'default' | grep -Eo 'v[0-9]+' | sort -u | tr '\\n' ' '")
			set otherNodeVersions to words of (do shell script "source " & selectedSource & " && nvm ls --no-colors | grep -v '\\->' | awk '{printf \"%s \", $1}'")
			
			-- Install the latest major Node versions.
			repeat with majorNodeVersion in majorNodeVersions
				-- Set the Node Package Manager commands to the "commandsToRun" list.
				set end of commandsToRun to commandLocation & " install " & majorNodeVersion
			end repeat
			
			-- Store the entire command string for reinstalling all packages.
			set nvmRunCommand to ""
			
			-- Build a command to reinstall all packages from current Node version to other Node versions.
			repeat with otherNodeVersion in otherNodeVersions
				set nvmRunCommand to nvmRunCommand & commandLocation & " use " & otherNodeVersion & " && " & commandLocation & " reinstall-packages " & currentNodeVersion & " && npm -g update && "
			end repeat
			
			-- End the command by setting the newest Node version back to the current Node version (clean up).
			set nvmRunCommand to nvmRunCommand & "nvm use " & currentNodeVersion
			
			-- Set the Node Version Manager commands to the "commandsToRun" list.
			set end of commandsToRun to nvmRunCommand
		end if
	end if
end repeat

-- Run the commands.
repeat with commandToRun in commandsToRun
	-- Show the current task notification.
	display notification commandToRun with title "Update Node.js / NVM Packages" subtitle "Running command"
	
	-- This will never crash. If it is empty string, command does not exist.
	do shell script "source " & selectedSource & " && " & commandToRun
	
	-- Give the computer a break.
	delay 3
end repeat

-- Show the completed notification.
display notification "All packages have been successfully updated!" with title "Update Node.js / NVM Packages" sound name "Blow"