set sources to {"~/.bashrc", "~/.bash_profile", "~/.zshrc", "~/.zprofile", "~/.profile"}
set selectedSource to ""

-- Find the source file to use.
repeat with source in sources
	-- Find the full path of the source file.
	set fullSourcePath to POSIX path of (path to home folder as text) & text 3 thru -1 of source
	
	log "Attempting to locate the \"" & fullSourcePath & "\" source file ..."
	
	-- If the source file exists, set it to the current source.
	if (do shell script "[ -e '" & fullSourcePath & "' ] && echo 'true' || echo 'false'") is equal to "true" then
		log "Found the \"" & fullSourcePath & "\" source file. Using this as the base to run commands from ..."
		
		set selectedSource to fullSourcePath
		exit repeat
	end if
end repeat

-- A source file is required to continue.
if selectedSource is equal to "" then
	display dialog "Unable to determine if Node.js or NVM is installed. The source file (e.g. \"~/.zshrc\") cannot be located." with icon stop buttons {"OK"} default button "OK"
	quit
end if

-- Update all packages via NPM.
set npmLocation to do shell script "source " & selectedSource & " && command -v npm; exit 0;"

if npmLocation ends with "npm" then
	display notification "Updating NPM packages ..." with title "Update Node.js / NVM Packages"
	
	log "Updating NPM packages ..."
	
	-- Fix for NPM ".DS_Store" error.
	do shell script "source " & selectedSource & " && find `npm list -g | head -1` -name '.DS_Store' -type f -delete"
	
	-- Update all packages for current NPM install.
	do shell script "source " & selectedSource & " && " & npmLocation & " -g update"
end if

-- Update all major Node.js versions to its latest versions (via nvm).
set nvmLocation to do shell script "source " & selectedSource & " && command -v nvm; exit 0;"

if nvmLocation ends with "nvm" then
	set currentNodeVersion to do shell script "source " & selectedSource & " && nvm version default"
	set majorNodeVersions to words of (do shell script "source " & selectedSource & " && nvm ls | grep -B9999999 'default' | grep -Eo 'v[0-9]+' | sort -u | tr '\\n' ' '")
	
	-- Install the latest major Node versions (e.g. if v20 and v22 is detected, the latest versions of those will be installed).
	repeat with majorNodeVersion in majorNodeVersions
		display notification "Installing the latest Node.js version for " & majorNodeVersion & " ..." with title "Update Node.js / NVM Packages" subtitle "Running command"
		
		log "Installing the latest Node.js major version for " & majorNodeVersion & " ..."
		
		-- Install the latest version for
		do shell script "source " & selectedSource & " && " & nvmLocation & " install " & majorNodeVersion
	end repeat
	
	-- Set the Node.js version (saved before update) back to the previous version.
	do shell script "source " & selectedSource & " && nvm alias default " & currentNodeVersion
end if

-- Re-install all packages from the current Node.js version.
set currentNodeVersion to do shell script "source " & selectedSource & " && nvm version default"
set otherNodeVersions to words of (do shell script "source " & selectedSource & " && nvm ls --no-colors | grep -v '\\->' | awk '{printf \"%s \", $1}'")

repeat with otherNodeVersion in otherNodeVersions
	display notification "Reinstalling packages for Node.js " & otherNodeVersion & " from " & currentNodeVersion & " ..." with title "Update Node.js / NVM Packages" subtitle "Running command"
	
	log "Reinstalling packages for Node.js " & otherNodeVersion & " from " & currentNodeVersion & " ..."
	
	-- Install the latest version for
	do shell script "source " & selectedSource & " && " & nvmLocation & " use " & otherNodeVersion & " && " & nvmLocation & " reinstall-packages " & currentNodeVersion
end repeat

-- Show the completed notification.
display notification "All Node.js versions and NPM packages have been successfully updated!" with title "Update Node.js / NVM Packages" sound name "Blow"