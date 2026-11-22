set sources to {"~/.bashrc", "~/.bash_profile", "~/.zshrc", "~/.zprofile", "~/.profile"}
set selectedSource to ""

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
	display dialog "Unable to determine if Homebrew is installed. The source file (e.g. \"~/.zshrc\") cannot be located." with icon stop buttons {"OK"} default button "OK"
	quit
end if

-- This will never crash. If it is empty string, command does not exist.
set brewLocation to do shell script "source " & selectedSource & " && command -v brew; exit 0;"

-- Check if the command exists.
if brewLocation is equal to "" then
	display dialog "Homebrew is not installed. Please install Homebrew and run this script again." with icon stop buttons {"OK"} default button "OK"
	quit
end if

-- Show the current task notification.
display notification "Now updating Homebrew and the installed packages ..." with title "Update Homebrew"

-- Run the update and upgrade commands.
do shell script "source " & selectedSource & " && " & brewLocation & " update"
do shell script "source " & selectedSource & " && " & brewLocation & " upgrade"

-- Show the completed notification.
display notification "Homebrew and the installed packages have been successfully updated!" with title "Update Homebrew" sound name "Blow"
