-- =================================================================================================================
-- Wake on LAN via pfSense Actions
--
-- Sends Wake-on-LAN requests through a "pfSense Actions" API to power on remote PCs, waits for them to boot, and
-- launches a remote desktop application of your choice. Supports multiple PCs with a management UI.
--
-- PC configuration is stored at:
--   ~/.config/pfsense-actions-wol/config.plist
--
-- Notes:
-- * Requires a "pfSense Actions" API endpoint for WoL and ping
-- * This script is interactive only
-- * Per-PC API keys are stored in macOS Keychain (service: "Wake on LAN via pfSense Actions")
--
-- Good to know:
-- * Deleting a PC also permanently removes its API key from Keychain
--
-- Accepted Risks:
-- * API keys are briefly written to a curl config file during API calls (cleaned up afterward)
-- * If a PC rename fails mid-save, an orphaned Keychain entry may remain; the old config and key are still intact
-- * API keys appear briefly in process arguments during Keychain operations (inherent to the macOS "security" CLI)
-- =================================================================================================================

------------------------------------------------------------------
-- Properties
------------------------------------------------------------------
property notificationTitle : "Wake on LAN via pfSense Actions"
property notificationSound : "Blow"
property candidateApps : {{"Moonlight", "com.moonlight-stream.Moonlight"}, {"Parsec", "tv.parsec.www"}, {"Windows App", "com.microsoft.rdc.macos"}}
property managePcsLabel : "Manage PCs..."

------------------------------------------------------------------
-- Helper: getConfigPath
------------------------------------------------------------------
on getConfigPath()
	set configDir to do shell script "echo ~/.config/pfsense-actions-wol"
	set configPath to configDir & "/config.plist"
	log "DEBUG -> getConfigPath: " & configPath

	-- Create directory if needed (owner-only permissions)
	do shell script "mkdir -p " & quoted form of configDir & " && chmod 700 " & quoted form of configDir

	-- Initialize empty plist if missing (owner-only permissions)
	try
		do shell script "[ -f " & quoted form of configPath & " ]"
	on error
		log "DEBUG -> getConfigPath: creating new config plist"
		do shell script "/usr/libexec/PlistBuddy -c " & quoted form of "Add :PCs array" & " " & quoted form of configPath
		do shell script "chmod 600 " & quoted form of configPath
	end try

	return configPath
end getConfigPath

------------------------------------------------------------------
-- Helper: getPcCount
------------------------------------------------------------------
on getPcCount()
	set configPath to my getConfigPath()
	set arrayCount to 0
	repeat
		try
			do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Print :PCs:" & arrayCount) & " " & quoted form of configPath & " >/dev/null 2>&1"
			set arrayCount to arrayCount + 1
		on error
			exit repeat
		end try
	end repeat
	return arrayCount
end getPcCount

------------------------------------------------------------------
-- Helper: loadPcNames
------------------------------------------------------------------
on loadPcNames()
	set configPath to my getConfigPath()
	set pcNames to {}

	set pcCount to my getPcCount()
	log "DEBUG -> loadPcNames: array has " & pcCount & " entries"

	repeat with idx from 0 to (pcCount - 1)
		try
			set pcName to do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Print :PCs:" & idx & ":computerName") & " " & quoted form of configPath
			set end of pcNames to pcName
		on error
			log "DEBUG -> loadPcNames: skipping corrupted entry at index " & idx
		end try
	end repeat

	log "DEBUG -> loadPcNames: found " & (count of pcNames) & " PCs"
	return pcNames
end loadPcNames

------------------------------------------------------------------
-- Helper: findPcIndex
------------------------------------------------------------------
on findPcIndex(targetName)
	set configPath to my getConfigPath()

	set pcCount to my getPcCount()

	repeat with idx from 0 to (pcCount - 1)
		try
			set pcName to do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Print :PCs:" & idx & ":computerName") & " " & quoted form of configPath
			if pcName is targetName then
				return idx
			end if
		on error
			log "DEBUG -> findPcIndex: skipping corrupted entry at index " & idx
		end try
	end repeat

	return -1
end findPcIndex

------------------------------------------------------------------
-- Helper: loadPc
------------------------------------------------------------------
on loadPc(targetName)
	set idx to my findPcIndex(targetName)
	if idx is -1 then
		error "PC not found: " & targetName
	end if

	set configPath to my getConfigPath()
	set prefix to ":PCs:" & idx

	set pcComputerName to do shell script "/usr/libexec/PlistBuddy" & ¬
		" -c " & quoted form of ("Print " & prefix & ":computerName") & ¬
		" -c " & quoted form of ("Print " & prefix & ":pfsenseActionsUrl") & ¬
		" -c " & quoted form of ("Print " & prefix & ":broadcastAddress") & ¬
		" -c " & quoted form of ("Print " & prefix & ":ipAddress") & ¬
		" -c " & quoted form of ("Print " & prefix & ":macAddress") & ¬
		" -c " & quoted form of ("Print " & prefix & ":pingCount") & ¬
		" " & quoted form of configPath

	set fieldLines to paragraphs of pcComputerName
	log "DEBUG -> loadPc: loaded " & (item 1 of fieldLines)

	set pcRecord to {computerName:item 1 of fieldLines, pfsenseActionsUrl:item 2 of fieldLines, broadcastAddress:item 3 of fieldLines, ipAddress:item 4 of fieldLines, macAddress:item 5 of fieldLines, pingCount:item 6 of fieldLines}
	my validatePcRecord(pcRecord)
	return pcRecord
end loadPc

------------------------------------------------------------------
-- Helper: addPcToConfig
------------------------------------------------------------------
on addPcToConfig(pcRecord)
	set configPath to my getConfigPath()

	set entryCount to my getPcCount()

	set prefix to ":PCs:" & entryCount
	log "DEBUG -> addPcToConfig: adding at index " & entryCount

	do shell script "/usr/libexec/PlistBuddy" & ¬
		" -c " & quoted form of ("Add " & prefix & " dict") & ¬
		" -c " & quoted form of ("Add " & prefix & ":computerName string " & computerName of pcRecord) & ¬
		" -c " & quoted form of ("Add " & prefix & ":pfsenseActionsUrl string " & pfsenseActionsUrl of pcRecord) & ¬
		" -c " & quoted form of ("Add " & prefix & ":broadcastAddress string " & broadcastAddress of pcRecord) & ¬
		" -c " & quoted form of ("Add " & prefix & ":ipAddress string " & ipAddress of pcRecord) & ¬
		" -c " & quoted form of ("Add " & prefix & ":macAddress string " & macAddress of pcRecord) & ¬
		" -c " & quoted form of ("Add " & prefix & ":pingCount string " & pingCount of pcRecord) & ¬
		" " & quoted form of configPath

	log "DEBUG -> addPcToConfig: saved " & computerName of pcRecord
end addPcToConfig

------------------------------------------------------------------
-- Helper: updatePcInConfig
------------------------------------------------------------------
on updatePcInConfig(originalName, pcRecord)
	set idx to my findPcIndex(originalName)
	if idx is -1 then
		error "PC not found: " & originalName
	end if

	set configPath to my getConfigPath()
	set prefix to ":PCs:" & idx
	log "DEBUG -> updatePcInConfig: updating index " & idx

	do shell script "/usr/libexec/PlistBuddy" & ¬
		" -c " & quoted form of ("Set " & prefix & ":computerName " & computerName of pcRecord) & ¬
		" -c " & quoted form of ("Set " & prefix & ":pfsenseActionsUrl " & pfsenseActionsUrl of pcRecord) & ¬
		" -c " & quoted form of ("Set " & prefix & ":broadcastAddress " & broadcastAddress of pcRecord) & ¬
		" -c " & quoted form of ("Set " & prefix & ":ipAddress " & ipAddress of pcRecord) & ¬
		" -c " & quoted form of ("Set " & prefix & ":macAddress " & macAddress of pcRecord) & ¬
		" -c " & quoted form of ("Set " & prefix & ":pingCount " & pingCount of pcRecord) & ¬
		" " & quoted form of configPath

	log "DEBUG -> updatePcInConfig: saved " & computerName of pcRecord
end updatePcInConfig

------------------------------------------------------------------
-- Helper: deletePcFromConfig
------------------------------------------------------------------
on deletePcFromConfig(targetName)
	set idx to my findPcIndex(targetName)
	if idx is -1 then
		error "PC not found: " & targetName
	end if

	set configPath to my getConfigPath()
	log "DEBUG -> deletePcFromConfig: deleting index " & idx

	do shell script "/usr/libexec/PlistBuddy -c " & quoted form of ("Delete :PCs:" & idx) & " " & quoted form of configPath

	log "DEBUG -> deletePcFromConfig: deleted " & targetName
end deletePcFromConfig

------------------------------------------------------------------
-- Helper: getApiKey
------------------------------------------------------------------
on getApiKey(pcName)
	set keychainService to "Wake on LAN via pfSense Actions"
	log "DEBUG -> getApiKey: looking up Keychain (service=" & keychainService & ", account=" & pcName & ")"

	-- Try to read the key from Keychain
	try
		set theApiKey to do shell script "security find-generic-password -s " & quoted form of keychainService & " -a " & quoted form of pcName & " -w"
		log "DEBUG -> getApiKey: found key in Keychain"
		return theApiKey
	on error
		log "DEBUG -> getApiKey: key not found in Keychain, prompting user"
	end try

	-- Prompt the user to enter the key
	set userResponse to display dialog "Enter the pfSense Actions API key for " & pcName & ":" & return & return & "The key will be saved to your macOS Keychain." default answer "" with title notificationTitle buttons {"Cancel", "Save to Keychain"} default button "Save to Keychain" with hidden answer
	set theApiKey to text returned of userResponse

	if theApiKey is "" then
		display dialog "API key cannot be empty." with icon stop buttons {"OK"} default button "OK"
		error number -128
	end if
	if not my matchesPattern(theApiKey, "^[^\"\\\\[:cntrl:]]+$") then
		display dialog "API key cannot contain quotes, backslashes, or control characters." with icon stop buttons {"OK"} default button "OK"
		error number -128
	end if

	-- Save the key to Keychain
	my setApiKey(pcName, theApiKey)

	return theApiKey
end getApiKey

------------------------------------------------------------------
-- Helper: setApiKey
------------------------------------------------------------------
on setApiKey(pcName, theKey)
	set keychainService to "Wake on LAN via pfSense Actions"
	log "DEBUG -> setApiKey: saving key to Keychain for " & pcName

	do shell script "security add-generic-password -U -s " & quoted form of keychainService & " -a " & quoted form of pcName & " -w " & quoted form of theKey

	log "DEBUG -> setApiKey: key saved successfully"
end setApiKey

------------------------------------------------------------------
-- Helper: deleteApiKey
------------------------------------------------------------------
on deleteApiKey(pcName)
	set keychainService to "Wake on LAN via pfSense Actions"
	log "DEBUG -> deleteApiKey: deleting key from Keychain for " & pcName

	try
		do shell script "security delete-generic-password -s " & quoted form of keychainService & " -a " & quoted form of pcName
		log "DEBUG -> deleteApiKey: key deleted"
	on error
		log "DEBUG -> deleteApiKey: key not found (already removed)"
	end try
end deleteApiKey

------------------------------------------------------------------
-- Helper: matchesPattern
------------------------------------------------------------------
on matchesPattern(theText, thePattern)
	try
		do shell script "printf '%s' " & quoted form of theText & " | grep -qE " & quoted form of thePattern
		return true
	on error
		return false
	end try
end matchesPattern

------------------------------------------------------------------
-- Helper: validatePcRecord
------------------------------------------------------------------
on validatePcRecord(pcRecord)
	set pcName to computerName of pcRecord

	if not my matchesPattern(pfsenseActionsUrl of pcRecord, "^https://[A-Za-z0-9._-]+(:[0-9]+)?(/[^[:space:]\"\\\\[:cntrl:]]*)?$") then
		error "Configuration for \"" & pcName & "\" has an invalid URL. It must be a valid HTTPS URL (e.g. https://host.example.com) with no spaces or special characters. Please edit this PC to fix it."
	end if
	if not my matchesPattern(broadcastAddress of pcRecord, "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") then
		error "Configuration for \"" & pcName & "\" has an invalid broadcast address. Please edit this PC to fix it."
	end if
	if not my matchesPattern(ipAddress of pcRecord, "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") then
		error "Configuration for \"" & pcName & "\" has an invalid IP address. Please edit this PC to fix it."
	end if
	if not my matchesPattern(macAddress of pcRecord, "^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$") then
		error "Configuration for \"" & pcName & "\" has an invalid MAC address. Please edit this PC to fix it."
	end if
	if not my matchesPattern(pingCount of pcRecord, "^[1-9][0-9]*$") then
		error "Configuration for \"" & pcName & "\" has an invalid ping count. Please edit this PC to fix it."
	end if
	if (pingCount of pcRecord as integer) > 600 then
		error "Configuration for \"" & pcName & "\" has a ping count exceeding 600. Please edit this PC to fix it."
	end if
end validatePcRecord

------------------------------------------------------------------
-- Helper: getInstalledApps
------------------------------------------------------------------
on getInstalledApps(candidates)
	log "DEBUG -> getInstalledApps: checking " & (count of candidates) & " candidates"
	set appNames to {}
	set appBundleIDs to {}

	repeat with pair in candidates
		set appName to item 1 of pair
		set appBundleID to item 2 of pair

		try
			tell application "Finder" to get application file id appBundleID
			log "DEBUG -> getInstalledApps: found " & appName
			set end of appNames to appName
			set end of appBundleIDs to appBundleID
		end try
	end repeat

	log "DEBUG -> getInstalledApps: " & (count of appNames) & " installed"
	return {appNames:appNames, appBundleIDs:appBundleIDs}
end getInstalledApps

------------------------------------------------------------------
-- Helper: authenticatedPost
------------------------------------------------------------------
on authenticatedPost(endpoint, requestBody, theApiKey, theBaseUrl, maxTime)
	log "DEBUG -> authenticatedPost: " & endpoint
	set connectionErrorMessage to "Could not connect to " & theBaseUrl & "." & return & return & "Please check the URL and your network connection."
	set authConfigPath to do shell script "mktemp"
	try
		-- Defense-in-depth: reject keys that could break curl config parsing
		if not my matchesPattern(theApiKey, "^[^\"\\\\[:cntrl:]]+$") then
			do shell script "rm -f " & quoted form of authConfigPath
			error "API key contains characters unsafe for curl config file."
		end if
		set authFile to open for access POSIX file authConfigPath with write permission
		try
			write ("header = \"Authorization: Bearer " & theApiKey & "\"") to authFile
		on error errMsg2 number errNum2
			close access authFile
			error errMsg2 number errNum2
		end try
		close access authFile

		set curlResult to do shell script "curl --connect-timeout 10 --max-time " & maxTime & " --config " & quoted form of authConfigPath & " -s -w '\\n%{http_code}' -X POST " & quoted form of (theBaseUrl & endpoint) & " -H 'Content-Type: application/json' -d " & quoted form of requestBody
		do shell script "rm -f " & quoted form of authConfigPath
	on error errMsg number errNum
		do shell script "rm -f " & quoted form of authConfigPath
		if errNum is -128 then error errMsg number errNum
		display dialog connectionErrorMessage with icon stop buttons {"OK"} default button "OK"
		error number -128
	end try

	-- Parse response
	set resultParagraphs to paragraphs of curlResult
	set httpStatus to last item of resultParagraphs
	if (count of resultParagraphs) > 1 then
		set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, linefeed}
		set responseBody to (items 1 thru -2 of resultParagraphs) as text
		set AppleScript's text item delimiters to oldTID
	else
		set responseBody to ""
	end if

	if httpStatus is "000" then
		display dialog connectionErrorMessage with icon stop buttons {"OK"} default button "OK"
		error number -128
	end if

	return {httpStatus:httpStatus, responseBody:responseBody}
end authenticatedPost

------------------------------------------------------------------
-- Core: sendWakeOnLan
------------------------------------------------------------------
on sendWakeOnLan(pcRecord, theApiKey)
	set pcName to computerName of pcRecord
	log "DEBUG -> sendWakeOnLan: sending WoL request for " & pcName
	display notification "Attempting to power on " & pcName & " ..." with title notificationTitle

	set requestBody to "{\"broadcastAddress\": \"" & broadcastAddress of pcRecord & "\", \"macAddress\": \"" & macAddress of pcRecord & "\"}"
	set response to my authenticatedPost("/wol", requestBody, theApiKey, pfsenseActionsUrl of pcRecord, 30)
	log "DEBUG -> sendWakeOnLan: httpStatus=" & httpStatus of response

	if httpStatus of response is not "200" then
		display dialog "Failed to power on " & pcName & " via Wake-on-LAN." & return & return & "HTTP " & (httpStatus of response) & ": " & (responseBody of response) with icon stop buttons {"OK"} default button "OK"
		error number -128
	end if

	log "DEBUG -> sendWakeOnLan: success"
end sendWakeOnLan

------------------------------------------------------------------
-- Core: waitForBoot
------------------------------------------------------------------
on waitForBoot(pcRecord, theApiKey)
	set pcName to computerName of pcRecord
	log "DEBUG -> waitForBoot: waiting for " & pcName & " to boot"
	display notification "Waiting for " & pcName & " to complete booting ..." with title notificationTitle

	set requestBody to "{\"count\": " & pingCount of pcRecord & ", \"ipAddress\": \"" & ipAddress of pcRecord & "\", \"strict\": true}"
	set pingMaxTime to ((pingCount of pcRecord) as integer) + 30
	set response to my authenticatedPost("/ping", requestBody, theApiKey, pfsenseActionsUrl of pcRecord, pingMaxTime)
	log "DEBUG -> waitForBoot: httpStatus=" & httpStatus of response

	if httpStatus of response is not "200" then
		display dialog "Could not determine if " & pcName & " has woken up via Wake-on-LAN." & return & return & "HTTP " & (httpStatus of response) & ": " & (responseBody of response) with icon stop buttons {"OK"} default button "OK"
		error number -128
	end if

	log "DEBUG -> waitForBoot: boot confirmed"
end waitForBoot

------------------------------------------------------------------
-- Core: chooseAndLaunchApp
------------------------------------------------------------------
on chooseAndLaunchApp(pcName)
	log "DEBUG -> chooseAndLaunchApp: detecting installed apps"
	set installedApps to my getInstalledApps(candidateApps)
	set appNames to appNames of installedApps
	set appBundleIDs to appBundleIDs of installedApps

	if (count of appNames) is 0 then
		display dialog "No supported remote desktop applications are installed." with icon stop buttons {"OK"} default button "OK"
		error number -128
	end if

	display notification pcName & " has successfully booted! Choose an app to launch ..." with title notificationTitle

	set chosenApp to choose from list appNames with title notificationTitle with prompt "Select an application to open:" default items {item 1 of appNames}
	if chosenApp is false then
		error number -128
	end if

	set chosenAppName to item 1 of chosenApp
	log "DEBUG -> chooseAndLaunchApp: user chose " & chosenAppName

	-- Find the matching bundle ID
	set chosenBundleID to missing value
	repeat with i from 1 to count of appNames
		if item i of appNames is chosenAppName then
			set chosenBundleID to item i of appBundleIDs
			exit repeat
		end if
	end repeat

	log "DEBUG -> chooseAndLaunchApp: launching " & chosenAppName & " (" & chosenBundleID & ")"
	tell application id chosenBundleID to activate

	return chosenAppName
end chooseAndLaunchApp

------------------------------------------------------------------
-- Core: runPowerOn
------------------------------------------------------------------
on runPowerOn(pcRecord)
	set pcName to computerName of pcRecord
	log "DEBUG -> runPowerOn: start for " & pcName

	set theApiKey to my getApiKey(pcName)
	my sendWakeOnLan(pcRecord, theApiKey)
	my waitForBoot(pcRecord, theApiKey)
	set chosenAppName to my chooseAndLaunchApp(pcName)

	log "DEBUG -> runPowerOn: showing completion notification"
	display notification chosenAppName & " has been launched." with title notificationTitle sound name notificationSound

	log "DEBUG -> runPowerOn: completed"
end runPowerOn

------------------------------------------------------------------
-- Core: promptForPcFields
------------------------------------------------------------------
on promptForPcFields(defaults)
	-- Name
	set nameDefault to computerName of defaults
	repeat
		set userResponse to display dialog "Enter the PC name:" default answer nameDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
		if button returned of userResponse is not "OK" then error number -128
		set pcName to text returned of userResponse
		if pcName is "" then
			display dialog "PC name cannot be empty." with icon stop buttons {"OK"} default button "OK"
		else if not my matchesPattern(pcName, "^[^\"\\\\[:cntrl:]]+$") then
			display dialog "PC name cannot contain quotes, backslashes, or control characters." with icon stop buttons {"OK"} default button "OK"
		else if pcName is managePcsLabel then
			display dialog "The name \"" & managePcsLabel & "\" is reserved. Please choose a different name." with icon stop buttons {"OK"} default button "OK"
		else if my findPcIndex(pcName) is not -1 then
			display dialog "A PC named \"" & pcName & "\" already exists." with icon stop buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
		set nameDefault to pcName
	end repeat

	-- pfSense Actions URL
	set urlDefault to pfsenseActionsUrl of defaults
	repeat
		set userResponse to display dialog "Enter the pfSense Actions URL for " & pcName & ":" & return & "(e.g. https://pfsense-actions.example.com)" default answer urlDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
		if button returned of userResponse is not "OK" then error number -128
		set theUrl to text returned of userResponse
		if theUrl is "" then
			display dialog "URL cannot be empty." with icon stop buttons {"OK"} default button "OK"
		else if not my matchesPattern(theUrl, "^https://[A-Za-z0-9._-]+(:[0-9]+)?(/[^[:space:]\"\\\\[:cntrl:]]*)?$") then
			display dialog "URL must be a valid HTTPS URL (e.g. https://host.example.com/path) with no spaces or special characters." with icon stop buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
		set urlDefault to theUrl
	end repeat

	-- API key
	set apiKeyDefault to apiKey of defaults
	repeat
		set userResponse to display dialog "Enter the pfSense Actions API key for " & pcName & ":" default answer apiKeyDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK" with hidden answer
		if button returned of userResponse is not "OK" then error number -128
		set theApiKey to text returned of userResponse
		if theApiKey is "" then
			display dialog "API key cannot be empty." with icon stop buttons {"OK"} default button "OK"
		else if not my matchesPattern(theApiKey, "^[^\"\\\\[:cntrl:]]+$") then
			display dialog "API key cannot contain quotes, backslashes, or control characters." with icon stop buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
		set apiKeyDefault to theApiKey
	end repeat

	-- Broadcast address
	set broadcastDefault to broadcastAddress of defaults
	repeat
		set userResponse to display dialog "Enter the broadcast address for " & pcName & ":" & return & "(e.g. 192.168.1.255)" default answer broadcastDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
		if button returned of userResponse is not "OK" then error number -128
		set theBroadcast to text returned of userResponse
		if theBroadcast is "" then
			display dialog "Broadcast address cannot be empty." with icon stop buttons {"OK"} default button "OK"
		else if not my matchesPattern(theBroadcast, "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") then
			display dialog "Invalid broadcast address format (expected: e.g. 192.168.1.255)." with icon stop buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
		set broadcastDefault to theBroadcast
	end repeat

	-- IP address
	set ipDefault to ipAddress of defaults
	repeat
		set userResponse to display dialog "Enter the IP address for " & pcName & ":" & return & "(e.g. 192.168.1.100)" default answer ipDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
		if button returned of userResponse is not "OK" then error number -128
		set theIp to text returned of userResponse
		if theIp is "" then
			display dialog "IP address cannot be empty." with icon stop buttons {"OK"} default button "OK"
		else if not my matchesPattern(theIp, "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") then
			display dialog "Invalid IP address format (expected: e.g. 192.168.1.100)." with icon stop buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
		set ipDefault to theIp
	end repeat

	-- MAC address
	set macDefault to macAddress of defaults
	repeat
		set userResponse to display dialog "Enter the MAC address for " & pcName & ":" & return & "(e.g. aa:bb:cc:dd:ee:ff)" default answer macDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
		if button returned of userResponse is not "OK" then error number -128
		set theMac to text returned of userResponse
		if theMac is "" then
			display dialog "MAC address cannot be empty." with icon stop buttons {"OK"} default button "OK"
		else if not my matchesPattern(theMac, "^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$") then
			display dialog "Invalid MAC address format (expected: e.g. aa:bb:cc:dd:ee:ff)." with icon stop buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
		set macDefault to theMac
	end repeat

	-- Ping count
	set pingDefault to pingCount of defaults
	repeat
		set userResponse to display dialog "Enter the ping count (boot timeout) for " & pcName & ":" & return & "(number of ping attempts to wait for boot, max 600)" default answer pingDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
		if button returned of userResponse is not "OK" then error number -128
		set thePingCount to text returned of userResponse
		if thePingCount is "" then
			display dialog "Ping count cannot be empty." with icon stop buttons {"OK"} default button "OK"
		else if not my matchesPattern(thePingCount, "^[1-9][0-9]*$") then
			display dialog "Ping count must be a positive number." with icon stop buttons {"OK"} default button "OK"
		else if (thePingCount as integer) > 600 then
			display dialog "Ping count cannot exceed 600 (10 minutes)." with icon stop buttons {"OK"} default button "OK"
		else
			exit repeat
		end if
		set pingDefault to thePingCount
	end repeat

	set pcRecord to {computerName:pcName, pfsenseActionsUrl:theUrl, broadcastAddress:theBroadcast, ipAddress:theIp, macAddress:theMac, pingCount:thePingCount}

	return {pcRecord:pcRecord, apiKey:theApiKey}
end promptForPcFields

------------------------------------------------------------------
-- Core: runAddPc
------------------------------------------------------------------
on runAddPc()
	log "DEBUG -> runAddPc: start"

	set emptyDefaults to {computerName:"", pfsenseActionsUrl:"", apiKey:"", broadcastAddress:"", ipAddress:"", macAddress:"", pingCount:"60"}
	set promptResult to my promptForPcFields(emptyDefaults)
	set pcRecord to pcRecord of promptResult
	set theApiKey to apiKey of promptResult
	set pcName to computerName of pcRecord

	-- Save to Keychain first (a dangling key is safer than a keyless config entry)
	my setApiKey(pcName, theApiKey)
	try
		my addPcToConfig(pcRecord)
	on error errMsg number errNum
		my deleteApiKey(pcName)
		error errMsg number errNum
	end try

	display notification "Added \"" & pcName & "\" to configuration." with title notificationTitle
	log "DEBUG -> runAddPc: completed"
end runAddPc

------------------------------------------------------------------
-- Core: runEditPc
------------------------------------------------------------------
on runEditPc()
	log "DEBUG -> runEditPc: start"

	repeat
	set pcNames to my loadPcNames()
	if (count of pcNames) is 0 then
		display dialog "No PCs configured to edit." with icon stop buttons {"OK"} default button "OK"
		return
	end if

	set chosenPc to choose from list pcNames with title notificationTitle with prompt "Select a PC to edit:" default items {item 1 of pcNames}
	if chosenPc is false then exit repeat
	set targetName to item 1 of chosenPc

	set pcRecord to my loadPc(targetName)
	set originalName to computerName of pcRecord
	set pendingApiKey to ""

	-- Field picker loop
	set fieldChoices to {"Name", "URL", "API Key", "Broadcast Address", "IP Address", "MAC Address", "Ping Count", "Done"}
	set editCancelled to false

	repeat
		set chosenField to choose from list fieldChoices with title notificationTitle with prompt "Editing \"" & (computerName of pcRecord) & "\". Select a field to edit:" default items {"Done"}
		if chosenField is false then
			set editCancelled to true
			exit repeat
		end if
		set fieldName to item 1 of chosenField

		if fieldName is "Done" then
			exit repeat
		else if fieldName is "Name" then
			set editDefault to computerName of pcRecord
			repeat
				set userResponse to display dialog "Enter the new PC name:" default answer editDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
				if button returned of userResponse is not "OK" then exit repeat
				set newValue to text returned of userResponse
				if newValue is "" then
					exit repeat
				else if not my matchesPattern(newValue, "^[^\"\\\\[:cntrl:]]+$") then
					display dialog "PC name cannot contain quotes, backslashes, or control characters." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else if newValue is managePcsLabel then
					display dialog "The name \"" & managePcsLabel & "\" is reserved. Please choose a different name." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else if newValue is not (computerName of pcRecord) and my findPcIndex(newValue) is not -1 then
					display dialog "A PC named \"" & newValue & "\" already exists." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else
					set computerName of pcRecord to newValue
					exit repeat
				end if
			end repeat
		else if fieldName is "URL" then
			set editDefault to pfsenseActionsUrl of pcRecord
			repeat
				set userResponse to display dialog "Enter the new pfSense Actions URL:" default answer editDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
				if button returned of userResponse is not "OK" then exit repeat
				set newValue to text returned of userResponse
				if newValue is "" then
					exit repeat
				else if not my matchesPattern(newValue, "^https://[A-Za-z0-9._-]+(:[0-9]+)?(/[^[:space:]\"\\\\[:cntrl:]]*)?$") then
					display dialog "URL must be a valid HTTPS URL (e.g. https://host.example.com/path) with no spaces or special characters." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else
					set pfsenseActionsUrl of pcRecord to newValue
					exit repeat
				end if
			end repeat
		else if fieldName is "API Key" then
			set editDefault to ""
			repeat
				set userResponse to display dialog "Enter the new API key:" default answer editDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK" with hidden answer
				if button returned of userResponse is not "OK" then exit repeat
				set newValue to text returned of userResponse
				if newValue is "" then
					exit repeat
				else if not my matchesPattern(newValue, "^[^\"\\\\[:cntrl:]]+$") then
					display dialog "API key cannot contain quotes, backslashes, or control characters." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else
					set pendingApiKey to newValue
					exit repeat
				end if
			end repeat
		else if fieldName is "Broadcast Address" then
			set editDefault to broadcastAddress of pcRecord
			repeat
				set userResponse to display dialog "Enter the new broadcast address:" default answer editDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
				if button returned of userResponse is not "OK" then exit repeat
				set newValue to text returned of userResponse
				if newValue is "" then
					exit repeat
				else if not my matchesPattern(newValue, "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") then
					display dialog "Invalid broadcast address format (expected: e.g. 192.168.1.255)." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else
					set broadcastAddress of pcRecord to newValue
					exit repeat
				end if
			end repeat
		else if fieldName is "IP Address" then
			set editDefault to ipAddress of pcRecord
			repeat
				set userResponse to display dialog "Enter the new IP address:" default answer editDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
				if button returned of userResponse is not "OK" then exit repeat
				set newValue to text returned of userResponse
				if newValue is "" then
					exit repeat
				else if not my matchesPattern(newValue, "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") then
					display dialog "Invalid IP address format (expected: e.g. 192.168.1.100)." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else
					set ipAddress of pcRecord to newValue
					exit repeat
				end if
			end repeat
		else if fieldName is "MAC Address" then
			set editDefault to macAddress of pcRecord
			repeat
				set userResponse to display dialog "Enter the new MAC address:" default answer editDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
				if button returned of userResponse is not "OK" then exit repeat
				set newValue to text returned of userResponse
				if newValue is "" then
					exit repeat
				else if not my matchesPattern(newValue, "^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$") then
					display dialog "Invalid MAC address format (expected: e.g. aa:bb:cc:dd:ee:ff)." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else
					set macAddress of pcRecord to newValue
					exit repeat
				end if
			end repeat
		else if fieldName is "Ping Count" then
			set editDefault to pingCount of pcRecord
			repeat
				set userResponse to display dialog "Enter the new ping count:" default answer editDefault with title notificationTitle buttons {"Cancel", "OK"} default button "OK"
				if button returned of userResponse is not "OK" then exit repeat
				set newValue to text returned of userResponse
				if newValue is "" then
					exit repeat
				else if not my matchesPattern(newValue, "^[1-9][0-9]*$") then
					display dialog "Ping count must be a positive number." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else if (newValue as integer) > 600 then
					display dialog "Ping count cannot exceed 600 (10 minutes)." with icon stop buttons {"OK"} default button "OK"
					set editDefault to newValue
				else
					set pingCount of pcRecord to newValue
					exit repeat
				end if
			end repeat
		end if
	end repeat

	if editCancelled then
		-- Discard changes, loop back to PC selector
	else

	-- Handle Keychain updates before config (a dangling key is safer than a keyless config entry)
	set newName to computerName of pcRecord
	if newName is not originalName then
		if pendingApiKey is not "" then
			-- New key provided + rename: save under new name first
			log "DEBUG -> runEditPc: name changed + new API key; saving under " & newName
			my setApiKey(newName, pendingApiKey)
		else
			-- Rename only: copy existing key to new name first
			log "DEBUG -> runEditPc: name changed; migrating key from " & originalName & " to " & newName
			try
				set keychainService to "Wake on LAN via pfSense Actions"
				set existingKey to do shell script "security find-generic-password -s " & quoted form of keychainService & " -a " & quoted form of originalName & " -w"
				my setApiKey(newName, existingKey)
			on error
				log "DEBUG -> runEditPc: no existing key to migrate"
			end try
		end if
	else if pendingApiKey is not "" then
		-- Name unchanged, but API key was edited
		log "DEBUG -> runEditPc: saving new API key for " & newName
		my setApiKey(newName, pendingApiKey)
	end if

	-- Save changes to config
	my updatePcInConfig(originalName, pcRecord)

	-- Clean up old Keychain entry after successful config update
	if newName is not originalName then
		my deleteApiKey(originalName)
	end if

	display notification "Updated \"" & newName & "\" configuration." with title notificationTitle
	log "DEBUG -> runEditPc: completed"
	return
	end if
	end repeat

	log "DEBUG -> runEditPc: done"
end runEditPc

------------------------------------------------------------------
-- Core: runDeletePc
------------------------------------------------------------------
on runDeletePc()
	log "DEBUG -> runDeletePc: start"

	repeat
	set pcNames to my loadPcNames()
	if (count of pcNames) is 0 then
		display dialog "No PCs configured to delete." with icon stop buttons {"OK"} default button "OK"
		return
	end if

	set chosenPc to choose from list pcNames with title notificationTitle with prompt "Select a PC to delete:" default items {item 1 of pcNames}
	if chosenPc is false then exit repeat
	set targetName to item 1 of chosenPc

	-- Show details before confirming
	set pcRecord to my loadPc(targetName)
	set detailText to "Name: " & computerName of pcRecord & return & ¬
		"URL: " & pfsenseActionsUrl of pcRecord & return & ¬
		"Broadcast: " & broadcastAddress of pcRecord & return & ¬
		"IP: " & ipAddress of pcRecord & return & ¬
		"MAC: " & macAddress of pcRecord & return & ¬
		"Ping Count: " & pingCount of pcRecord

	try
		display dialog "Delete this PC?" & return & return & detailText & return & return & "This will also remove its API key from Keychain." with title notificationTitle buttons {"Cancel", "Delete"} cancel button "Cancel" default button "Cancel" with icon stop
		-- If we get here, user clicked Delete

		my deletePcFromConfig(targetName)
		my deleteApiKey(targetName)

		display notification "Deleted \"" & targetName & "\" from configuration." with title notificationTitle
		log "DEBUG -> runDeletePc: completed"
	on error errMsg number errNum
		if errMsg contains "User canceled" or errNum is equal to -128 then
			-- Cancel at confirmation: loop back to PC selector
		else
			error errMsg number errNum
		end if
	end try
	end repeat

	log "DEBUG -> runDeletePc: done"
end runDeletePc

------------------------------------------------------------------
-- Core: runManagePcs
------------------------------------------------------------------
on runManagePcs()
	log "DEBUG -> runManagePcs: start"

	set manageChoices to {"Add PC", "Edit PC", "Delete PC"}

	repeat
		set chosenAction to choose from list manageChoices with title notificationTitle with prompt "Manage PCs:" default items {"Add PC"}
		if chosenAction is false then exit repeat
		set actionName to item 1 of chosenAction

		try
			if actionName is "Add PC" then
				my runAddPc()
			else if actionName is "Edit PC" then
				my runEditPc()
			else if actionName is "Delete PC" then
				my runDeletePc()
			end if
		on error errMsg number errNum
			if errMsg contains "User canceled" or errNum is equal to -128 then
				-- Cancel within sub-flow: return to manage menu
			else
				error errMsg number errNum
			end if
		end try
	end repeat

	log "DEBUG -> runManagePcs: done"
end runManagePcs

------------------------------------------------------------------
-- Core: runMain
------------------------------------------------------------------
on runMain()
	log "DEBUG -> runMain: start"

	repeat
		set pcNames to my loadPcNames()

		if (count of pcNames) is 0 then
			-- Cancel here exits the script (nothing to go back to)
			display dialog "No PCs configured yet. Would you like to add one?" with title notificationTitle buttons {"Cancel", "Add PC"} cancel button "Cancel" default button "Add PC"
			try
				my runAddPc()
			on error errMsg number errNum
				if errMsg contains "User canceled" or errNum is equal to -128 then
					-- Cancel within Add flow: loop back
				else
					error errMsg number errNum
				end if
			end try
		else
			-- Build menu with PC names + manage option
			set menuItems to pcNames & {managePcsLabel}

			set chosenItem to choose from list menuItems with title notificationTitle with prompt "Select a PC to wake, or manage your PCs:" default items {item 1 of menuItems}
			if chosenItem is false then
				exit repeat
			end if
			set selectedItem to item 1 of chosenItem

			if selectedItem is managePcsLabel then
				my runManagePcs()
			else
				try
					set pcRecord to my loadPc(selectedItem)
					my runPowerOn(pcRecord)
					exit repeat
				on error errMsg number errNum
					if errMsg contains "User canceled" or errNum is equal to -128 then
						-- Cancel from power-on flow: return to main menu
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
		display dialog "This script must be run interactively. Command-line arguments are not supported." buttons {"OK"} with icon stop default button "OK"
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
