try
	display dialog "Do you want to select files or folders to include in the protected ZIP file?" buttons {"Files", "Folders", "Cancel"} default button "Cancel"
	set filesOrFolders to button returned of the result
	
	if filesOrFolders is "Files" then
		-- Prompt the user to choose one or more files.
		set chosenPaths to choose file with prompt "Select the files you want to include in the protected ZIP file:" with multiple selections allowed
	else if filesOrFolders is "Folders" then
		-- Prompt the user to choose one or more folders.
		set chosenPaths to choose folder with prompt "Select the folders you want to include in the protected ZIP file:" with multiple selections allowed
	else
		error "User canceled."
	end if
	
	set posixChosenPaths to {}
	
	-- Convert paths to POSIX-compliant.
	repeat with chosenPath in chosenPaths
		set end of posixChosenPaths to POSIX path of chosenPath
	end repeat
	
	-- Define the destination ZIP file path.
	set zipFilePath to choose file name with prompt "Choose a name and location for the protected ZIP file:" default name "Archive.zip"
	
	-- Convert the ZIP file path to a POSIX path.
	set posixZipFilePath to POSIX path of zipFilePath
	
	-- Prompt the user to enter a password.
	display dialog "Enter a password for the protected ZIP file:" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer
	set zipPassword to text returned of the result
	
	-- Only runs if ZIP password is defined.
	if zipPassword is not equal to "" then
		if filesOrFolders is "Folders" then
			set baseDirectory to my findCommonDirectoryPath(posixChosenPaths)
			set pathsToZip to my replaceText(joinListWithQuotes(posixChosenPaths, " "), baseDirectory, "")
			
			-- Create the ZIP file from one or more folders.
			log (do shell script "cd \"" & baseDirectory & "\" && zip -P " & zipPassword & " -ry \"" & posixZipFilePath & "\" " & pathsToZip)
		else
			set pathsToZip to my joinListWithQuotes(posixChosenPaths, " ")
			
			-- Create the ZIP file from one or more files.
			log (do shell script "zip -P " & zipPassword & " -rjy " & posixZipFilePath & " " & pathsToZip)
		end if
		
		-- Wait for the ZIP file to successfully save.
		delay 2
		
		-- Check if the ZIP file was created successfully.
		if (do shell script "[ -e " & quoted form of posixZipFilePath & " ] && echo 'true' || echo 'false'") is equal to "true" then
			display notification "Protected ZIP file created successfully!" with title "Create Protected ZIP" sound name "Blow"
		else
			display dialog "Error creating protected ZIP file. ZIP file not found in selected path." with icon stop buttons {"OK"} default button "OK"
		end if
	else
		display dialog "Error creating protected ZIP file. Password is required." with icon stop buttons {"OK"} default button "OK"
	end if
	
on error errMsg
	if errMsg does not contain "User canceled." then
		display dialog errMsg buttons {"OK"} with icon stop default button "OK"
	end if
end try

-- Function to join a list with quotes.
on joinListWithQuotes(posixChosenPaths, delimiter)
	set theResult to ""
	
	repeat with i from 1 to count of posixChosenPaths
		set theResult to theResult & "\"" & item i of posixChosenPaths & "\""
		
		if i is not equal to (count of posixChosenPaths) then
			set theResult to theResult & delimiter
		end if
	end repeat
	
	return theResult
end joinListWithQuotes

-- Function to replace text.
on replaceText(originalString, searchString, replacementString)
	set AppleScript's text item delimiters to searchString
	set textItems to text items of originalString
	set AppleScript's text item delimiters to replacementString
	set modifiedString to textItems as text
	set AppleScript's text item delimiters to ""
	
	return modifiedString
end replaceText

-- Function to find the common directory path.
on findCommonDirectoryPath(posixChosenPaths)
	set path1 to posixChosenPaths's beginning
	set path1Components to path1's text items
	set maxComponents to (count path1Components)
	
	repeat with nextPath in (posixChosenPaths's rest)
		if (maxComponents = 0) then
			exit repeat
		end if
		
		set theseComponents to nextPath's text items
		set componentCount to (count theseComponents)
		
		if (componentCount < maxComponents) then
			set maxComponents to componentCount
		end if
		
		repeat with c from 1 to maxComponents
			if (theseComponents's item c ­ path1Components's item c) then
				set maxComponents to c - 1
				exit repeat
			end if
		end repeat
	end repeat
	
	if (maxComponents > 0) then
		set commonPath to path1's text 1 thru text item maxComponents
	else
		set commonPath to ""
	end if
	
	if (count of posixChosenPaths) = 1 then
		return removeLastDirectory(commonPath)
	end if
	
	return commonPath
end findCommonDirectoryPath

-- Function to remove the last directory.
on removeLastDirectory(filePath)
	set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "/"}
	set myArray to text items of filePath
	set concatenatedString to ""
	
	repeat with i from 1 to (count myArray) - 2
		set concatenatedString to concatenatedString & item i of myArray
		if i < (count myArray) then
			set concatenatedString to concatenatedString & "/"
		end if
	end repeat
	
	set AppleScript's text item delimiters to oldTID
	
	return concatenatedString
end removeLastDirectory