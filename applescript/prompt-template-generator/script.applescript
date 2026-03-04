-- =================================================================================================================
-- Prompt Template Manager
--
-- A prompt copy/paste tool with per-run variable substitution. Manage a library of reusable prompt templates,
-- fill in variables at copy time, and paste the result from your clipboard.
--
-- Template configuration is stored at:
--   ~/.config/prompt-template-manager/config.plist
--   ~/.config/prompt-template-manager/templates/  (one .txt file per prompt)
--
-- Notes:
-- * Variables use {{variable_name}} syntax in templates
-- * Variables are auto-detected from template text when adding or editing
-- * This script is interactive only
--
-- Good to know:
-- * Metadata (names, variables) is stored in a plist via PlistBuddy
-- * Template bodies are stored as separate text files to preserve multiline content
-- =================================================================================================================

------------------------------------------------------------------
-- Properties
------------------------------------------------------------------
property notificationTitle : "Prompt Template Manager"
property notificationSound : "Blow"
property managePromptsLabel : "Manage Prompts..."

------------------------------------------------------------------
-- Helper: getConfigDir
------------------------------------------------------------------
on getConfigDir()
	set configDir to do shell script "echo ~/.config/prompt-template-manager"
	log "DEBUG -> getConfigDir: " & configDir

	-- Create directories if needed (owner-only permissions)
	do shell script "mkdir -p " & quoted form of (configDir & "/templates") & " && chmod 700 " & quoted form of configDir

	return configDir
end getConfigDir

------------------------------------------------------------------
-- Helper: getConfigPath
------------------------------------------------------------------
on getConfigPath()
	set configDir to my getConfigDir()
	set configPath to configDir & "/config.plist"
	log "DEBUG -> getConfigPath: " & configPath

	-- Initialize empty plist if missing (owner-only permissions)
	try
		do shell script "[ -f " & quoted form of configPath & " ]"
	on error
		log "DEBUG -> getConfigPath: creating new config plist"
		do shell script "/usr/libexec/PlistBuddy -c " & quoted form of "Add :Prompts array" & " " & quoted form of configPath
		do shell script "chmod 600 " & quoted form of configPath
	end try

	return configPath
end getConfigPath

------------------------------------------------------------------
-- Helper: getPromptCount
------------------------------------------------------------------
on getPromptCount()
	set configPath to my getConfigPath()
	set arrayCount to 0
	repeat
		try
			do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Print :Prompts:" & arrayCount) & " " & quoted form of configPath & " >/dev/null 2>&1"
			set arrayCount to arrayCount + 1
		on error
			exit repeat
		end try
	end repeat
	log "DEBUG -> getPromptCount: " & arrayCount
	return arrayCount
end getPromptCount

------------------------------------------------------------------
-- Helper: loadPromptNames
------------------------------------------------------------------
on loadPromptNames()
	set configPath to my getConfigPath()
	set promptNames to {}

	set promptCount to my getPromptCount()
	log "DEBUG -> loadPromptNames: array has " & promptCount & " entries"

	repeat with idx from 0 to (promptCount - 1)
		try
			set promptName to do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Print :Prompts:" & idx & ":promptName") & " " & quoted form of configPath
			set end of promptNames to promptName
		on error
			log "DEBUG -> loadPromptNames: skipping corrupted entry at index " & idx
		end try
	end repeat

	log "DEBUG -> loadPromptNames: found " & (count of promptNames) & " prompts"
	return promptNames
end loadPromptNames

------------------------------------------------------------------
-- Helper: findPromptIndex
------------------------------------------------------------------
on findPromptIndex(targetName)
	set configPath to my getConfigPath()

	set promptCount to my getPromptCount()

	repeat with idx from 0 to (promptCount - 1)
		try
			set promptName to do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Print :Prompts:" & idx & ":promptName") & " " & quoted form of configPath
			if promptName is targetName then
				log "DEBUG -> findPromptIndex: found " & targetName & " at index " & idx
				return idx
			end if
		on error
			log "DEBUG -> findPromptIndex: skipping corrupted entry at index " & idx
		end try
	end repeat

	log "DEBUG -> findPromptIndex: not found " & targetName
	return -1
end findPromptIndex

------------------------------------------------------------------
-- Helper: getTemplatePath
------------------------------------------------------------------
on getTemplatePath(idx)
	set configDir to my getConfigDir()
	return configDir & "/templates/" & idx & ".txt"
end getTemplatePath

------------------------------------------------------------------
-- Helper: loadPrompt
------------------------------------------------------------------
on loadPrompt(idx)
	set configPath to my getConfigPath()
	log "DEBUG -> loadPrompt: index=" & idx

	set prefix to ":Prompts:" & idx

	set promptName to do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Print " & prefix & ":promptName") & " " & quoted form of configPath

	-- Variables are stored as a comma-separated string
	set variablesStr to ""
	try
		set variablesStr to do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Print " & prefix & ":variables") & " " & quoted form of configPath
	end try

	-- Template body is stored as a separate text file
	set templatePath to my getTemplatePath(idx)
	set templateBody to ""
	try
		set templateBody to do shell script "cat " & quoted form of templatePath
	end try

	log "DEBUG -> loadPrompt: loaded " & promptName
	return {promptName:promptName, templateBody:templateBody, templateVars:variablesStr}
end loadPrompt

------------------------------------------------------------------
-- Helper: addPromptToConfig
------------------------------------------------------------------
on addPromptToConfig(promptName, templateBody, variablesStr)
	set configPath to my getConfigPath()

	set entryCount to my getPromptCount()
	set prefix to ":Prompts:" & entryCount
	log "DEBUG -> addPromptToConfig: adding at index " & entryCount

	do shell script "/usr/libexec/PlistBuddy" & ¬
		" -c " & quoted form of ("Add " & prefix & " dict") & ¬
		" -c " & quoted form of ("Add " & prefix & ":promptName string " & promptName) & ¬
		" -c " & quoted form of ("Add " & prefix & ":variables string " & variablesStr) & ¬
		" " & quoted form of configPath

	-- Write template body to text file
	set templatePath to my getTemplatePath(entryCount)
	my writeTextFile(templatePath, templateBody)

	log "DEBUG -> addPromptToConfig: saved " & promptName
end addPromptToConfig

------------------------------------------------------------------
-- Helper: updatePromptInConfig
------------------------------------------------------------------
on updatePromptInConfig(idx, promptName, templateBody, variablesStr)
	set configPath to my getConfigPath()
	set prefix to ":Prompts:" & idx
	log "DEBUG -> updatePromptInConfig: updating index " & idx

	do shell script "/usr/libexec/PlistBuddy" & ¬
		" -c " & quoted form of ("Set " & prefix & ":promptName " & promptName) & ¬
		" -c " & quoted form of ("Set " & prefix & ":variables " & variablesStr) & ¬
		" " & quoted form of configPath

	-- Overwrite template body text file
	set templatePath to my getTemplatePath(idx)
	my writeTextFile(templatePath, templateBody)

	log "DEBUG -> updatePromptInConfig: saved " & promptName
end updatePromptInConfig

------------------------------------------------------------------
-- Helper: deletePromptFromConfig
------------------------------------------------------------------
on deletePromptFromConfig(idx)
	set configPath to my getConfigPath()
	set configDir to my getConfigDir()
	log "DEBUG -> deletePromptFromConfig: deleting index " & idx

	-- Get total count before deletion
	set promptCount to my getPromptCount()

	-- Delete plist entry
	do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Delete :Prompts:" & idx) & " " & quoted form of configPath

	-- Delete the template text file
	set templatePath to my getTemplatePath(idx)
	do shell script "rm -f " & quoted form of templatePath

	-- Rename subsequent template files to close the gap
	repeat with i from (idx + 1) to (promptCount - 1)
		set oldPath to my getTemplatePath(i)
		set newPath to my getTemplatePath(i - 1)
		try
			do shell script "mv " & quoted form of oldPath & " " & quoted form of newPath
		end try
	end repeat

	log "DEBUG -> deletePromptFromConfig: deleted index " & idx
end deletePromptFromConfig

------------------------------------------------------------------
-- Helper: writeTextFile
------------------------------------------------------------------
on writeTextFile(filePath, fileContent)
	set fileRef to open for access POSIX file filePath with write permission
	try
		set eof of fileRef to 0
		write fileContent to fileRef as «class utf8»
	on error errMsg number errNum
		close access fileRef
		error errMsg number errNum
	end try
	close access fileRef
end writeTextFile

------------------------------------------------------------------
-- Helper: editInTextEdit
------------------------------------------------------------------
on editInTextEdit(initialContent, instructionText)
	-- Write content to a temp file in a TextEdit-accessible location
	set tempDir to POSIX path of (path to temporary items from user domain)
	set tempPath to do shell script "mktemp " & quoted form of (tempDir & "prompt_template_XXXXXX")
	-- Rename with .txt extension so TextEdit opens it as plain text
	set txtPath to tempPath & ".txt"
	do shell script "mv " & quoted form of tempPath & " " & quoted form of txtPath
	set tempPath to txtPath
	log "DEBUG -> editInTextEdit: tempPath=" & tempPath

	my writeTextFile(tempPath, initialContent)
	do shell script "chmod 644 " & quoted form of tempPath

	do shell script "open -a TextEdit " & quoted form of tempPath

	display dialog instructionText & return & return & "Save your changes in TextEdit (⌘S), then click OK to continue." with title notificationTitle buttons {"Cancel", "OK"} default button "OK" with icon note
	if button returned of the result is not "OK" then
		do shell script "rm -f " & quoted form of tempPath
		error number -128
	end if

	-- Read back what the user saved to disk
	set editedContent to do shell script "cat " & quoted form of tempPath

	-- Close the document in TextEdit without saving again (user already saved)
	tell application "TextEdit"
		repeat with doc in documents
			if (path of doc) is tempPath then
				close doc saving no
				exit repeat
			end if
		end repeat
	end tell

	do shell script "rm -f " & quoted form of tempPath
	log "DEBUG -> editInTextEdit: read back " & (count of editedContent) & " characters"
	return editedContent
end editInTextEdit

------------------------------------------------------------------
-- Helper: extractVariables
------------------------------------------------------------------
on extractVariables(templateText)
	log "DEBUG -> extractVariables: scanning template"

	-- Use grep to find all {{...}} patterns, then deduplicate (preserving first-occurrence order)
	set varResult to ""
	try
		set varResult to do shell script "echo " & quoted form of templateText & " | grep -oE '\\{\\{[^}]+\\}\\}' | sed 's/^{{//;s/}}$//' | cat -n | sort -k2 -u | sort -n | cut -f2- | paste -sd ',' -"
	end try

	log "DEBUG -> extractVariables: found " & varResult
	return varResult
end extractVariables

------------------------------------------------------------------
-- Helper: replaceText
------------------------------------------------------------------
on replaceText(sourceText, searchStr, replaceStr)
	set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, searchStr}
	set theItems to every text item of sourceText
	set AppleScript's text item delimiters to replaceStr
	set resultText to theItems as text
	set AppleScript's text item delimiters to oldTID
	return resultText
end replaceText

------------------------------------------------------------------
-- Helper: splitString
------------------------------------------------------------------
on splitString(theString, theDelimiter)
	set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, theDelimiter}
	set theItems to every text item of theString
	set AppleScript's text item delimiters to oldTID
	return theItems
end splitString

------------------------------------------------------------------
-- Helper: joinList
------------------------------------------------------------------
on joinList(theList, theDelimiter)
	set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, theDelimiter}
	set joinedText to theList as string
	set AppleScript's text item delimiters to oldTID
	return joinedText
end joinList

------------------------------------------------------------------
-- Helper: trimString
------------------------------------------------------------------
on trimString(theString)
	-- Strip leading and trailing whitespace
	set trimmed to do shell script "echo " & quoted form of theString & " | xargs"
	return trimmed
end trimString


------------------------------------------------------------------
-- Core: runUsePrompt
------------------------------------------------------------------
on runUsePrompt(targetIndex)
	set promptRecord to my loadPrompt(targetIndex)
	set templateBody to templateBody of promptRecord
	set promptName to promptName of promptRecord
	log "DEBUG -> runUsePrompt: " & promptName

	-- Always extract variables fresh from the template body
	set variablesStr to my extractVariables(templateBody)
	log "DEBUG -> runUsePrompt: detected variables=" & variablesStr

	set filledBody to templateBody

	-- Prompt for each variable value
	if variablesStr is not "" then
		set varsList to my splitString(variablesStr, ",")

		repeat with varName in varsList
			set varNameText to my trimString(contents of varName)
			if varNameText is "" then
				-- Skip empty entries
			else
				log "DEBUG -> runUsePrompt: prompting for variable " & varNameText

				set userResponse to display dialog "Enter a value for \"" & varNameText & "\":" with title "Fill In Variables — " & promptName default answer "" buttons {"Cancel", "OK"} default button "OK" with icon note
				if button returned of userResponse is not "OK" then error number -128
				set userValue to text returned of userResponse
				set filledBody to my replaceText(filledBody, "{{" & varNameText & "}}", userValue)
			end if
		end repeat
	end if

	-- Copy to clipboard
	set the clipboard to filledBody
	log "DEBUG -> runUsePrompt: copied to clipboard"

	-- Show confirmation with truncated preview
	if (count of filledBody) > 200 then
		set previewText to text 1 thru 200 of filledBody & "…"
	else
		set previewText to filledBody
	end if

	display notification "\"" & promptName & "\" copied to clipboard." with title notificationTitle sound name notificationSound
	display dialog "Copied to clipboard:" & return & return & previewText with title promptName buttons {"Done"} default button "Done" giving up after 5 with icon note

	log "DEBUG -> runUsePrompt: done"
end runUsePrompt

------------------------------------------------------------------
-- Core: runAddPrompt
------------------------------------------------------------------
on runAddPrompt()
	log "DEBUG -> runAddPrompt: start"

	-- Prompt name
	set nameDefault to ""
	repeat
		set userResponse to display dialog "Enter a name for the new prompt:" default answer nameDefault with title notificationTitle buttons {"Cancel", "Save"} default button "Save" with icon note
		if button returned of userResponse is not "Save" then error number -128
		set newName to text returned of userResponse
		if newName is "" then
			display dialog "Prompt name cannot be empty." with icon caution buttons {"OK"} default button "OK"
		else if newName is managePromptsLabel then
			display dialog "The name \"" & managePromptsLabel & "\" is reserved. Please choose a different name." with icon caution buttons {"OK"} default button "OK"
			set nameDefault to newName
		else if my findPromptIndex(newName) is not -1 then
			display dialog "A prompt named \"" & newName & "\" already exists." with icon caution buttons {"OK"} default button "OK"
			set nameDefault to newName
		else
			exit repeat
		end if
	end repeat

	-- Template body (edit in TextEdit)
	repeat
		set newBody to my editInTextEdit("", "Write your prompt template in TextEdit." & return & return & "Use {{Variable Name}} syntax for fill-in-the-blank variables." & return & return & "Example: Summarize {{Topic}} in {{Style}} style.")
		if newBody is "" then
			display dialog "Template body cannot be empty." with icon caution buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
	end repeat

	-- Auto-detect variables from template
	set detectedVars to my extractVariables(newBody)
	my addPromptToConfig(newName, newBody, detectedVars)

	display notification "Added \"" & newName & "\" to your library." with title notificationTitle sound name notificationSound
	log "DEBUG -> runAddPrompt: done"
end runAddPrompt

------------------------------------------------------------------
-- Core: runEditPrompt
------------------------------------------------------------------
on runEditPrompt()
	log "DEBUG -> runEditPrompt: start"

	set promptNames to my loadPromptNames()
	if (count of promptNames) is 0 then
		display dialog "No prompts to edit." with icon caution buttons {"OK"} default button "OK"
		return
	end if

	set selectedNames to choose from list promptNames with title notificationTitle with prompt "Select a prompt to edit:" without multiple selections allowed without empty selection allowed
	if selectedNames is false then error number -128
	set selectedName to item 1 of selectedNames

	set targetIndex to my findPromptIndex(selectedName)
	if targetIndex is -1 then
		error "Prompt not found: " & selectedName
	end if

	set promptRecord to my loadPrompt(targetIndex)

	-- Prompt name
	set nameDefault to promptName of promptRecord
	repeat
		set userResponse to display dialog "Rename the prompt, or leave as-is:" default answer nameDefault with title notificationTitle buttons {"Cancel", "Save"} default button "Save" with icon note
		if button returned of userResponse is not "Save" then error number -128
		set newName to text returned of userResponse
		if newName is "" then
			display dialog "Prompt name cannot be empty." with icon caution buttons {"OK"} default button "OK"
		else if newName is managePromptsLabel then
			display dialog "The name \"" & managePromptsLabel & "\" is reserved. Please choose a different name." with icon caution buttons {"OK"} default button "OK"
			set nameDefault to newName
		else if newName is not selectedName and my findPromptIndex(newName) is not -1 then
			display dialog "A prompt named \"" & newName & "\" already exists." with icon caution buttons {"OK"} default button "OK"
			set nameDefault to newName
		else
			exit repeat
		end if
	end repeat

	-- Template body (edit in TextEdit)
	repeat
		set newBody to my editInTextEdit(templateBody of promptRecord, "Edit the prompt template in TextEdit." & return & return & "Use {{Variable Name}} syntax for fill-in-the-blank variables." & return & return & "Example: Summarize {{Topic}} in {{Style}} style.")
		if newBody is "" then
			display dialog "Template body cannot be empty." with icon caution buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
	end repeat

	-- Auto-detect variables from template
	set detectedVars to my extractVariables(newBody)
	my updatePromptInConfig(targetIndex, newName, newBody, detectedVars)

	display notification "Updated \"" & newName & "\" in your library." with title notificationTitle sound name notificationSound
	log "DEBUG -> runEditPrompt: done"
end runEditPrompt

------------------------------------------------------------------
-- Core: runDeletePrompt
------------------------------------------------------------------
on runDeletePrompt()
	log "DEBUG -> runDeletePrompt: start"

	set promptNames to my loadPromptNames()
	if (count of promptNames) is 0 then
		display dialog "No prompts to delete." with icon caution buttons {"OK"} default button "OK"
		return
	end if

	set selectedNames to choose from list promptNames with title notificationTitle with prompt "Select a prompt to delete:" without multiple selections allowed without empty selection allowed
	if selectedNames is false then error number -128
	set selectedName to item 1 of selectedNames

	set targetIndex to my findPromptIndex(selectedName)
	if targetIndex is -1 then
		error "Prompt not found: " & selectedName
	end if

	display dialog "Delete \"" & selectedName & "\"?" & return & return & "This will permanently remove the prompt and its template." with title notificationTitle buttons {"Cancel", "Delete"} cancel button "Cancel" default button "Cancel" with icon stop
	if button returned of the result is not "Delete" then return

	my deletePromptFromConfig(targetIndex)

	display notification "Deleted \"" & selectedName & "\" from your library." with title notificationTitle sound name notificationSound
	log "DEBUG -> runDeletePrompt: done"
end runDeletePrompt

------------------------------------------------------------------
-- Core: runManagePrompts
------------------------------------------------------------------
on runManagePrompts()
	log "DEBUG -> runManagePrompts: start"

	set manageChoices to {"Add New Prompt", "Edit Existing Prompt", "Delete Existing Prompt"}

	repeat
		set chosenAction to choose from list manageChoices with title notificationTitle with prompt "What would you like to do?" default items {"Add New Prompt"}
		if chosenAction is false then exit repeat
		set actionName to item 1 of chosenAction

		try
			if actionName is "Add New Prompt" then
				my runAddPrompt()
			else if actionName is "Edit Existing Prompt" then
				my runEditPrompt()
			else if actionName is "Delete Existing Prompt" then
				my runDeletePrompt()
			end if
		on error errMsg number errNum
			if errMsg contains "User canceled" or errNum is equal to -128 then
				-- Cancel within sub-flow: return to manage menu
			else
				error errMsg number errNum
			end if
		end try
	end repeat

	log "DEBUG -> runManagePrompts: done"
end runManagePrompts

------------------------------------------------------------------
-- Core: runMain
------------------------------------------------------------------
on runMain()
	log "DEBUG -> runMain: start"

	repeat
		set promptNames to my loadPromptNames()

		if (count of promptNames) is 0 then
			-- Cancel here exits the script (nothing to go back to)
			display dialog "Your prompt library is empty." & return & return & "Would you like to create your first prompt?" with title notificationTitle buttons {"Cancel", "Add Prompt"} cancel button "Cancel" default button "Add Prompt" with icon note
			try
				my runAddPrompt()
			on error errMsg number errNum
				if errMsg contains "User canceled" or errNum is equal to -128 then
					-- Cancel within Add flow: loop back
				else
					error errMsg number errNum
				end if
			end try
		else
			-- Build menu with prompt names + manage option
			set menuItems to promptNames & {managePromptsLabel}

			set chosenItem to choose from list menuItems with title notificationTitle with prompt "Choose a prompt to use, or manage your library:" default items {item 1 of menuItems}
			if chosenItem is false then
				exit repeat
			end if
			set selectedItem to item 1 of chosenItem

			if selectedItem is managePromptsLabel then
				my runManagePrompts()
			else
				try
					set targetIndex to my findPromptIndex(selectedItem)
					my runUsePrompt(targetIndex)
					exit repeat
				on error errMsg number errNum
					if errMsg contains "User canceled" or errNum is equal to -128 then
						-- Cancel from use-prompt flow: return to main menu
					else
						error errMsg number errNum
					end if
				end try
			end if
		end if
	end repeat

	log "DEBUG -> runMain: done"
end runMain

------------------------------------------------------------------
-- Entry: run
------------------------------------------------------------------
on run argv
	if (count of argv) > 0 then
		display dialog "This script must be run interactively." & return & "Command-line arguments are not supported." buttons {"OK"} with icon stop default button "OK"
		return
	end if

	try
		log "DEBUG -> run: start"
		my runMain()
		log "DEBUG -> run: done"
	on error errMsg number errNum
		if errMsg contains "User canceled" or errNum is equal to -128 then
			return
		end if
		display dialog errMsg buttons {"OK"} with icon stop default button "OK"
	end try
end run
