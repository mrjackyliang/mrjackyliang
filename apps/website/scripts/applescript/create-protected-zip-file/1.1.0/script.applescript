set posixChosenFiles to {}

try
	-- Prompt the user to choose multiple files.
	set chosenFiles to choose file with prompt "Select the files you want to include in the protected ZIP file:" with multiple selections allowed
	
	-- Convert file aliases to POSIX paths.
	repeat with chosenFile in chosenFiles
		set end of posixChosenFiles to POSIX path of chosenFile
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
		set filesToZip to my joinListWithQuotes(posixChosenFiles, " ")
		
		-- Create the ZIP file.
		do shell script "zip -P " & zipPassword & " -rj " & posixZipFilePath & " " & filesToZip
		
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

-- Join list with quotes function.
on joinListWithQuotes(theList, delimiter)
	set theResult to ""
	
	repeat with i from 1 to count of theList
		set theResult to theResult & "\"" & item i of theList & "\""
		if i is not equal to (count of theList) then
			set theResult to theResult & delimiter
		end if
	end repeat
	
	display dialog theResult
	
	return theResult
end joinListWithQuotes