-- ===========================================================================
-- Create Protected ZIP File
--
-- Creates a password-protected ZIP file from user-selected files or folders.
--
-- Notes:
-- * Uses the macOS built-in "zip" and "expect" commands
-- * This script is interactive only
--
-- Accepted Risks:
-- * Uses legacy ZIP encryption (not AES-256); weak against offline cracking
-- * Password is briefly stored in a temp file during zip creation
-- ===========================================================================

------------------------------------------------------------------
-- Properties
------------------------------------------------------------------
property notificationTitle : "Create Protected ZIP File"
property notificationSound : "Blow"

------------------------------------------------------------------
-- Helper: findCommonDirectoryPath
------------------------------------------------------------------
on findCommonDirectoryPath(posixPaths)
	log "DEBUG -> findCommonDirectoryPath: count=" & (count of posixPaths)
	if (count of posixPaths) = 0 then
		log "DEBUG -> findCommonDirectoryPath: empty list"
		return ""
	end if

	set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "/"}

	try
		set path1Components to text items of item 1 of posixPaths

		if (count of posixPaths) = 1 then
			-- Single path: return its parent directory
			if (count of path1Components) < 3 then
				set commonPath to "/"
			else
				set parentComponents to items 1 thru -3 of path1Components
				set commonPath to (parentComponents as text) & "/"
			end if
			set AppleScript's text item delimiters to oldTID
			log "DEBUG -> findCommonDirectoryPath: single path result=" & commonPath
			return commonPath
		end if

		set maxComponents to count of path1Components

		repeat with pathIndex from 2 to (count of posixPaths)
			set nextComponents to text items of item pathIndex of posixPaths
			set componentCount to count of nextComponents

			if componentCount < maxComponents then
				set maxComponents to componentCount
			end if

			repeat with c from 1 to maxComponents
				if item c of nextComponents is not equal to item c of path1Components then
					set maxComponents to c - 1
					exit repeat
				end if
			end repeat
		end repeat

		if maxComponents > 0 then
			set commonComponents to items 1 thru maxComponents of path1Components
			set commonPath to (commonComponents as text)
			if commonPath does not end with "/" then
				set commonPath to commonPath & "/"
			end if
		else
			set commonPath to ""
		end if

		set AppleScript's text item delimiters to oldTID
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldTID
		error errMsg number errNum
	end try

	log "DEBUG -> findCommonDirectoryPath: result=" & commonPath
	return commonPath
end findCommonDirectoryPath

------------------------------------------------------------------
-- Helper: expectZip
------------------------------------------------------------------
on expectZip(zipFlags, posixZipFilePath, zipPassword, quotedPaths, cdPrefix)
	log "DEBUG -> expectZip: flags=" & zipFlags

	-- Write password to temp file (keeps it off the command line)
	set passwordPath to do shell script "mktemp"
	-- Write expect script to temp file
	set expectPath to do shell script "mktemp"

	try
		set passFile to open for access POSIX file passwordPath with write permission
		try
			write zipPassword to passFile
		on error errMsg2 number errNum2
			close access passFile
			error errMsg2 number errNum2
		end try
		close access passFile

		set expectFile to open for access POSIX file expectPath with write permission
		try
			write ("set timeout 30" & linefeed & ¬
				"set passfile [lindex $argv 0]" & linefeed & ¬
				"set zipfile [lindex $argv 1]" & linefeed & ¬
				"set paths [lrange $argv 2 end]" & linefeed & ¬
				"set f [open $passfile r]" & linefeed & ¬
				"set pass [read -nonewline $f]" & linefeed & ¬
				"close $f" & linefeed & ¬
				"spawn zip " & zipFlags & " $zipfile -- {*}$paths" & linefeed & ¬
				"expect {" & linefeed & ¬
				"  -glob \"*assword*\" { send \"$pass\\r\" }" & linefeed & ¬
				"  timeout { puts stderr \"Timed out waiting for password prompt\"; exit 1 }" & linefeed & ¬
				"}" & linefeed & ¬
				"expect {" & linefeed & ¬
				"  -glob \"*assword*\" { send \"$pass\\r\" }" & linefeed & ¬
				"  timeout { puts stderr \"Timed out waiting for verify prompt\"; exit 1 }" & linefeed & ¬
				"}" & linefeed & ¬
				"set timeout -1" & linefeed & ¬
				"expect eof" & linefeed & ¬
				"lassign [wait] pid spawnid os_error exit_status" & linefeed & ¬
				"exit $exit_status") to expectFile
		on error errMsg2 number errNum2
			close access expectFile
			error errMsg2 number errNum2
		end try
		close access expectFile

		set zipOutput to do shell script cdPrefix & "expect " & quoted form of expectPath & " " & quoted form of passwordPath & " " & quoted form of posixZipFilePath & quotedPaths
		do shell script "rm -f " & quoted form of expectPath & " " & quoted form of passwordPath
	on error errMsg number errNum
		do shell script "rm -f " & quoted form of expectPath & " " & quoted form of passwordPath
		error errMsg number errNum
	end try

	return zipOutput
end expectZip

------------------------------------------------------------------
-- Core: createProtectedZip
------------------------------------------------------------------
on createProtectedZip(posixChosenPaths, posixZipFilePath, zipPassword, filesOrFolders)
	log "DEBUG -> createProtectedZip: start"
	log "DEBUG -> mode: " & filesOrFolders
	log "DEBUG -> items: " & (count of posixChosenPaths)
	log "DEBUG -> output: " & posixZipFilePath

	if filesOrFolders is "Folders" then
		-- Guard against saving ZIP inside a selected source folder (recursive self-inclusion)
		-- Resolve real paths to handle symlinks
		repeat with posixPath in posixChosenPaths
			set resolvedSource to do shell script "cd " & quoted form of (contents of posixPath) & " 2>/dev/null && pwd -P || echo " & quoted form of (contents of posixPath)
			if resolvedSource does not end with "/" then set resolvedSource to resolvedSource & "/"
			set zipParent to do shell script "dirname " & quoted form of posixZipFilePath
			set resolvedZipParent to do shell script "cd " & quoted form of zipParent & " 2>/dev/null && pwd -P || echo " & quoted form of zipParent
			if (resolvedZipParent & "/") starts with resolvedSource then
				error "ZIP file cannot be saved inside a selected source folder. Choose a different save location."
			end if
		end repeat

		set baseDirectory to my findCommonDirectoryPath(posixChosenPaths)
		if baseDirectory is "" then
			error "Error creating protected ZIP file. Unable to determine base directory."
		end if
		log "DEBUG -> baseDirectory: " & baseDirectory

		-- Build quoted relative paths
		set quotedRelativePaths to ""
		set baseLen to length of baseDirectory
		repeat with posixPath in posixChosenPaths
			set relativePath to text (baseLen + 1) thru -1 of posixPath
			-- Strip trailing slash if present
			if relativePath ends with "/" then
				set relativePath to text 1 thru -2 of relativePath
			end if
			log "DEBUG -> relativePath: " & relativePath
			set quotedRelativePaths to quotedRelativePaths & " " & quoted form of relativePath
		end repeat

		-- Remove existing file to prevent in-place update (stale entries could persist)
		do shell script "rm -f " & quoted form of posixZipFilePath

		log "DEBUG -> zip command: folders"
		set zipOutput to my expectZip("-ery", posixZipFilePath, zipPassword, quotedRelativePaths, "cd " & quoted form of baseDirectory & " && ")
		log "DEBUG -> zip completed"

	else if filesOrFolders is "Files" then
		-- Check for duplicate basenames (zip -j flattens paths, causing collisions)
		set basenames to {}
		set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "/"}
		repeat with posixPath in posixChosenPaths
			set pathComponents to text items of (contents of posixPath)
			set basename to last item of pathComponents
			if basenames contains basename then
				set AppleScript's text item delimiters to oldTID
				error "Multiple files named \"" & basename & "\" were selected. Flat ZIP mode would cause one to overwrite the other."
			end if
			set end of basenames to basename
		end repeat
		set AppleScript's text item delimiters to oldTID

		-- Quote each absolute path individually
		set quotedPaths to ""
		repeat with posixPath in posixChosenPaths
			set quotedPaths to quotedPaths & " " & quoted form of posixPath
		end repeat

		-- Remove existing file to prevent in-place update (stale entries could persist)
		do shell script "rm -f " & quoted form of posixZipFilePath

		log "DEBUG -> zip command: files"
		set zipOutput to my expectZip("-erjy", posixZipFilePath, zipPassword, quotedPaths, "")
		log "DEBUG -> zip completed"
	else
		error "Error creating protected ZIP file. Invalid selection."
	end if

	-- Wait for the ZIP file to be fully written
	delay 2

	-- Verify the ZIP file was created
	if (do shell script "[ -e " & quoted form of posixZipFilePath & " ] && echo 'true' || echo 'false'") is not equal to "true" then
		error "Error creating protected ZIP file. ZIP file not found in selected path."
	end if
	log "DEBUG -> zip created successfully"

	log "DEBUG -> createProtectedZip: done"
	return true
end createProtectedZip

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

		-- Ask whether to zip files or folders
		display dialog "Do you want to select files or folders to include in the protected ZIP file?" buttons {"Cancel", "Files", "Folders"} cancel button "Cancel"
		set filesOrFolders to button returned of the result
		log "DEBUG -> selection: " & filesOrFolders

		if filesOrFolders is "Files" then
			set chosenPaths to choose file with prompt "Select the files you want to include in the protected ZIP file:" with multiple selections allowed
		else
			set chosenPaths to choose folder with prompt "Select the folders you want to include in the protected ZIP file:" with multiple selections allowed
		end if

		-- Convert alias paths to POSIX paths
		set posixChosenPaths to {}
		repeat with chosenPath in chosenPaths
			set end of posixChosenPaths to POSIX path of chosenPath
		end repeat
		log "DEBUG -> selected paths: " & (count of posixChosenPaths)

		-- Choose save location for the ZIP file
		set zipFilePath to choose file name with prompt "Choose a name and location for the protected ZIP file:" default name "Archive.zip"
		set posixZipFilePath to POSIX path of zipFilePath
		log "DEBUG -> output: " & posixZipFilePath

		-- Prompt for password
		repeat
			display dialog "Enter a password for the protected ZIP file:" default answer "" buttons {"Cancel", "OK"} cancel button "Cancel" default button "OK" with hidden answer
			set zipPassword to text returned of the result
			if zipPassword is not "" then exit repeat
			display dialog "Password cannot be empty." with icon stop buttons {"OK"} default button "OK"
		end repeat

		my createProtectedZip(posixChosenPaths, posixZipFilePath, zipPassword, filesOrFolders)

		display notification "Protected ZIP file created successfully!" with title notificationTitle sound name notificationSound

		log "DEBUG -> run: done"
	on error errMsg number errNum
		if errMsg contains "User canceled" or errNum is equal to -128 then
			return
		end if
		display dialog errMsg buttons {"OK"} with icon stop default button "OK"
	end try
end run
