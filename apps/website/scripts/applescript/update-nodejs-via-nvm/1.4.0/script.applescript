-- =================================================================================================================
-- Update Node.js via NVM
--
-- Installs current LTS Node.js versions (per the official release schedule), sets the latest as default, migrates
-- global packages, and removes non-LTS versions.
--
-- Notes:
-- * Requires NVM and a shell profile that sources "nvm.sh"
-- * Requires "jq" for JSON parsing (will offer to install via Homebrew)
-- * This script is interactive only
--
-- Good to know:
-- * Removes non-LTS Node.js versions, which could break projects pinned to those versions
--
-- Accepted Risks:
-- * Fetches remote JSON from GitHub and trusts it to determine which versions to install
-- * Sources your shell profile (e.g. "~/.zshrc") to locate NVM; a compromised profile affects all shell operations
-- * Previously linked packages (npm link) are re-linked without confirmation; npm link runs lifecycle scripts
-- =================================================================================================================

------------------------------------------------------------------
-- Properties
------------------------------------------------------------------
property sourceCandidates : {"~/.bashrc", "~/.bash_profile", "~/.zshrc", "~/.zprofile", "~/.profile"}
property notificationTitle : "Update Node.js via NVM"
property notificationSound : "Blow"
property scheduleUrl : "https://raw.githubusercontent.com/nodejs/Release/main/schedule.json"

------------------------------------------------------------------
-- Helper: expandHomePath
------------------------------------------------------------------
on expandHomePath(pathText)
	if pathText starts with "~/" then
		set homePath to POSIX path of (path to home folder)
		return homePath & text 3 thru -1 of pathText
	end if
	
	return pathText
end expandHomePath

------------------------------------------------------------------
-- Helper: fileExists
------------------------------------------------------------------
on fileExists(pathText)
	set commandText to "[ -e " & quoted form of pathText & " ] && echo 'true' || echo 'false'"
	return (do shell script commandText) is equal to "true"
end fileExists

------------------------------------------------------------------
-- Helper: findSourceForCommand
------------------------------------------------------------------
on findSourceForCommand(candidateList, commandName)
	set anyProfileFound to false
	repeat with sourcePath in candidateList
		set fullSourcePath to my expandHomePath(contents of sourcePath)
		log "DEBUG -> checking source: " & fullSourcePath
		if my fileExists(fullSourcePath) then
			set anyProfileFound to true
			set cmdPath to my resolveCommandPath(fullSourcePath, commandName)
			if cmdPath is not "" then
				log "DEBUG -> found " & commandName & " via " & fullSourcePath
				return {sourcePath:fullSourcePath, commandPath:cmdPath, profileFound:true}
			end if
			log "DEBUG -> " & commandName & " not found via " & fullSourcePath
		end if
	end repeat

	-- Fallback: try without any profile source (command may be in default PATH)
	log "DEBUG -> trying bare command lookup for " & commandName
	try
		set cmdPath to do shell script "command -v " & quoted form of commandName & " 2>/dev/null"
		if cmdPath is not "" then
			log "DEBUG -> found " & commandName & " in default PATH: " & cmdPath
			return {sourcePath:"/dev/null", commandPath:cmdPath, profileFound:anyProfileFound}
		end if
	end try

	log "DEBUG -> no source file found for " & commandName
	return {sourcePath:"", commandPath:"", profileFound:anyProfileFound}
end findSourceForCommand

------------------------------------------------------------------
-- Helper: resolveCommandPath
------------------------------------------------------------------
on resolveCommandPath(sourcePath, commandName)
	log "DEBUG -> resolveCommandPath: " & commandName & " using " & sourcePath
	set commandText to "source " & quoted form of sourcePath & " >/dev/null 2>&1; command -v " & quoted form of commandName & "; exit 0;"
	set commandPath to do shell script commandText
	log "DEBUG -> resolveCommandPath: " & commandName & " -> " & commandPath
	return commandPath
end resolveCommandPath

------------------------------------------------------------------
-- Helper: splitWords
------------------------------------------------------------------
on splitWords(textValue)
	if textValue is "" then
		return {}
	end if
	
	set parsedItems to {}
	set currentItem to ""
	
	repeat with i from 1 to (length of textValue)
		set currentChar to character i of textValue
		if currentChar is " " or currentChar is tab or currentChar is return or currentChar is linefeed then
			if currentItem is not "" then
				set parsedItems to parsedItems & {currentItem}
				set currentItem to ""
			end if
		else
			set currentItem to currentItem & currentChar
		end if
	end repeat
	
	if currentItem is not "" then
		set parsedItems to parsedItems & {currentItem}
	end if
	
	return parsedItems
end splitWords

------------------------------------------------------------------
-- Helper: joinList
------------------------------------------------------------------
on joinList(theList, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set joinedText to theList as text
	set AppleScript's text item delimiters to oldDelimiters
	return joinedText
end joinList

------------------------------------------------------------------
-- Helper: getMajorVersion
------------------------------------------------------------------
on getMajorVersion(fullVersion)
	set versionText to fullVersion as text
	if versionText starts with "v" then
		set versionText to text 2 thru -1 of versionText
	end if
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "."
	set majorVersion to text item 1 of versionText
	set AppleScript's text item delimiters to oldDelimiters
	return majorVersion
end getMajorVersion

------------------------------------------------------------------
-- Helper: isDigitsOnly
------------------------------------------------------------------
on isDigitsOnly(textValue)
	if textValue is "" then return false
	repeat with i from 1 to length of textValue
		set c to character i of textValue
		if c is not in {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"} then
			return false
		end if
	end repeat
	return true
end isDigitsOnly

------------------------------------------------------------------
-- Helper: listContains
------------------------------------------------------------------
on listContains(theList, targetValue)
	repeat with listItem in theList
		if (contents of listItem) is equal to targetValue then
			return true
		end if
	end repeat
	return false
end listContains

------------------------------------------------------------------
-- Helper: ensureJqAvailable
------------------------------------------------------------------
on ensureJqAvailable(sourcePath)
	log "DEBUG -> ensureJqAvailable: checking for jq"
	set jqPath to my resolveCommandPath(sourcePath, "jq")
	if jqPath is not "" then
		log "DEBUG -> ensureJqAvailable: found jq at " & jqPath
		return jqPath
	end if
	
	log "DEBUG -> ensureJqAvailable: jq not found, checking for Homebrew"
	set brewPath to my resolveCommandPath(sourcePath, "brew")
	if brewPath is "" then
		display dialog "This script requires jq for JSON parsing, but it was not found." & return & return & "Please install Homebrew from https://brew.sh and then run this script again." buttons {"OK"} with icon stop default button "OK"
		error number -128
	end if
	
	display dialog "This script requires jq for JSON parsing. Install it now using Homebrew?" buttons {"Cancel", "Install jq"} default button "Install jq" cancel button "Cancel" with icon caution
	
	log "DEBUG -> ensureJqAvailable: installing jq via Homebrew"
	display notification "Installing jq via Homebrew ..." with title notificationTitle
	do shell script "source " & quoted form of sourcePath & " >/dev/null 2>&1 && " & quoted form of brewPath & " install jq"
	
	set jqPath to my resolveCommandPath(sourcePath, "jq")
	if jqPath is "" then
		display dialog "Failed to install jq. Please install it manually and try again." buttons {"OK"} with icon stop default button "OK"
		error number -128
	end if
	
	log "DEBUG -> ensureJqAvailable: jq installed at " & jqPath
	return jqPath
end ensureJqAvailable

------------------------------------------------------------------
-- Core: fetchCurrentLtsVersions
------------------------------------------------------------------
on fetchCurrentLtsVersions(sourcePath, jqPath)
	log "DEBUG -> fetchCurrentLtsVersions: fetching schedule from " & scheduleUrl
	display notification "Fetching Node.js release schedule ..." with title notificationTitle
	
	set shellCmd to "source " & quoted form of sourcePath & " >/dev/null 2>&1 && curl -sf --connect-timeout 10 --max-time 30 " & quoted form of scheduleUrl & " | " & quoted form of jqPath & " -r --arg today \"$(date +%Y-%m-%d)\" 'to_entries[] | select(.value.lts | type == \"string\") | select(.value.lts <= $today) | select(.value.end >= $today) | .key | ltrimstr(\"v\")' | sort -n | tr '\\n' ' '"
	
	log "DEBUG -> fetchCurrentLtsVersions: running shell command"
	set ltsOutput to do shell script shellCmd
	log "DEBUG -> fetchCurrentLtsVersions: raw output=" & ltsOutput
	
	set ltsVersions to my splitWords(ltsOutput)

	if (count of ltsVersions) is 0 then
		display dialog "No current LTS versions found. The Node.js release schedule may have changed or the network request failed." buttons {"OK"} with icon stop default button "OK"
		error number -128
	end if

	-- Validate that every value is a bare integer (e.g. "20", "22"). Rejects tampered data.
	repeat with ltsVersion in ltsVersions
		if not my isDigitsOnly(contents of ltsVersion) then
			log "DEBUG -> fetchCurrentLtsVersions: rejected invalid value: " & (contents of ltsVersion)
			display dialog "The Node.js release schedule returned an unexpected value: \"" & (contents of ltsVersion) & "\". Aborting for safety." buttons {"OK"} with icon stop default button "OK"
			error number -128
		end if
	end repeat

	log "DEBUG -> fetchCurrentLtsVersions: found LTS versions: " & ltsOutput
	return ltsVersions
end fetchCurrentLtsVersions

------------------------------------------------------------------
-- Core: getInstalledVersions
------------------------------------------------------------------
on getInstalledVersions(sourcePath, nvmLocation)
	log "DEBUG -> getInstalledVersions: listing installed versions"
	set nvmPrefix to "source " & quoted form of sourcePath & " >/dev/null 2>&1 && " & quoted form of nvmLocation
	-- Filter out "N/A" lines to exclude uninstalled LTS aliases (e.g. lts/argon -> v4.9.1 (-> N/A)).
	-- Sort numerically by major.minor.patch so versions appear in ascending order.
	set installedOutput to do shell script nvmPrefix & " ls --no-colors | grep -v 'N/A' | grep -Eo 'v[0-9]+\\.[0-9]+\\.[0-9]+' | sort -u -t. -k1.2,1n -k2,2n -k3,3n | tr '\\n' ' '"
	log "DEBUG -> getInstalledVersions: raw output=" & installedOutput
	return my splitWords(installedOutput)
end getInstalledVersions

------------------------------------------------------------------
-- Core: collectGlobalPackages
------------------------------------------------------------------
on collectGlobalPackages(sourcePath, nvmLocation, jqPath, versionList)
	log "DEBUG -> collectGlobalPackages: collecting from " & (count of versionList) & " versions"
	
	set versionArgs to ""
	repeat with ver in versionList
		set versionArgs to versionArgs & " " & quoted form of (contents of ver)
	end repeat
	
	-- Two-pass approach per version:
	-- Pass 1 (jq): extract regular (non-linked) packages as PKG<tab>name<tab>version<tab>fromVersion
	-- Pass 2 (jq + shell): extract linked package names, then resolve the actual path
	--   via "cd <symlink> && pwd -P" instead of trusting the relative file: path.
	-- npm and corepack are skipped (managed by Node itself).
	-- Keys starting with "." are excluded (e.g. .DS_Store in global node_modules on macOS).
	set regularFilter to ".dependencies // {} | to_entries[] | select(.key != \"npm\" and .key != \"corepack\" and (.key | startswith(\".\") | not)) | select((.value.resolved // \"\" | startswith(\"file:\") or startswith(\"git+\") or startswith(\"git://\") or startswith(\"github:\")) | not) | \"PKG\\t\" + .key + \"\\t\" + (.value.version // \"latest\") + \"\\t\" + $from"

	set linkedFilter to ".dependencies // {} | to_entries[] | select(.key != \"npm\" and .key != \"corepack\" and (.key | startswith(\".\") | not)) | select(.value.resolved // \"\" | startswith(\"file:\")) | .key"

	set nonRegistryFilter to ".dependencies // {} | to_entries[] | select(.key != \"npm\" and .key != \"corepack\" and (.key | startswith(\".\") | not)) | select(.value.resolved // \"\" | startswith(\"git+\") or startswith(\"git://\") or startswith(\"github:\")) | \"NONREG\\t\" + .key + \"\\t\" + (.value.version // \"unknown\") + \"\\t\" + (.value.resolved // \"unknown\")"
	
	set shellCmd to "source " & quoted form of sourcePath & " >/dev/null 2>&1; for ver in" & versionArgs & "; do nvm use \"$ver\" >/dev/null 2>&1 || continue; globaldir=\"$(npm root -g)\"; json=$(npm list -g --depth=0 --json 2>/dev/null); if [ -z \"$json\" ]; then printf \"SKIP\\t%s\\n\" \"$ver\"; continue; fi; echo \"$json\" | " & quoted form of jqPath & " -r --arg from \"$ver\" '" & regularFilter & "' 2>/dev/null || { printf \"SKIP\\t%s\\n\" \"$ver\"; continue; }; echo \"$json\" | " & quoted form of jqPath & " -r '" & linkedFilter & "' 2>/dev/null | while read -r name; do realpath=$(cd \"$globaldir/$name\" 2>/dev/null && pwd -P); if [ -n \"$realpath\" ]; then printf \"LINKED\\t%s\\t%s\\n\" \"$name\" \"$realpath\"; fi; done; echo \"$json\" | " & quoted form of jqPath & " -r '" & nonRegistryFilter & "' 2>/dev/null; done"
	
	log "DEBUG -> collectGlobalPackages: running collection command"
	set rawOutput to ""
	set collectionFailed to false
	try
		set rawOutput to do shell script shellCmd
	on error errMsg
		log "DEBUG -> collectGlobalPackages: shell error: " & errMsg
		set collectionFailed to true
	end try
	log "DEBUG -> collectGlobalPackages: raw output length=" & (length of rawOutput)

	set regularPackages to {}
	set linkedPackages to {}
	set nonRegistryPackages to {}

	if rawOutput is "" then
		return {regularPackages:regularPackages, linkedPackages:linkedPackages, nonRegistryPackages:nonRegistryPackages, collectionFailed:collectionFailed}
	end if
	
	set outputLines to paragraphs of rawOutput
	repeat with outputLine in outputLines
		set lineText to contents of outputLine
		if lineText is "" then
			-- skip empty lines
		else if lineText starts with "SKIP" then
			set collectionFailed to true
		else if lineText starts with "PKG" then
			set end of regularPackages to lineText
		else if lineText starts with "NONREG" then
			-- Deduplicate non-registry packages by name across versions
			set {oldTID2, AppleScript's text item delimiters} to {AppleScript's text item delimiters, tab}
			set nonRegParts to text items of lineText
			set AppleScript's text item delimiters to oldTID2
			set nonRegName to item 2 of nonRegParts
			set nameAlreadyTracked to false
			repeat with existingNonReg in nonRegistryPackages
				set {oldTID3, AppleScript's text item delimiters} to {AppleScript's text item delimiters, tab}
				set existingParts to text items of (contents of existingNonReg)
				set AppleScript's text item delimiters to oldTID3
				if (item 2 of existingParts) is equal to nonRegName then
					set nameAlreadyTracked to true
					exit repeat
				end if
			end repeat
			if not nameAlreadyTracked then
				set end of nonRegistryPackages to lineText
			end if
		else if lineText starts with "LINKED" then
			-- Deduplicate linked packages (same name+path across versions)
			set alreadyTracked to false
			repeat with existingLinked in linkedPackages
				if (contents of existingLinked) is equal to lineText then
					set alreadyTracked to true
					exit repeat
				end if
			end repeat
			if not alreadyTracked then
				set end of linkedPackages to lineText
			end if
		end if
	end repeat
	
	log "DEBUG -> collectGlobalPackages: regularPackages=" & (count of regularPackages) & " linkedPackages=" & (count of linkedPackages) & " nonRegistryPackages=" & (count of nonRegistryPackages)
	return {regularPackages:regularPackages, linkedPackages:linkedPackages, nonRegistryPackages:nonRegistryPackages, collectionFailed:collectionFailed}
end collectGlobalPackages

------------------------------------------------------------------
-- Core: resolvePackageConflicts
------------------------------------------------------------------
on resolvePackageConflicts(packageRecords)
	log "DEBUG -> resolvePackageConflicts: processing " & (count of packageRecords) & " records"
	
	-- Build a unique list of package names
	set packageNames to {}
	repeat with pkgRecord in packageRecords
		set oldDelimiters to AppleScript's text item delimiters
		set AppleScript's text item delimiters to tab
		set parts to text items of (contents of pkgRecord)
		set AppleScript's text item delimiters to oldDelimiters
		set pkgName to item 2 of parts
		if not my listContains(packageNames, pkgName) then
			set end of packageNames to pkgName
		end if
	end repeat
	
	-- For each unique package, check for version conflicts
	set resolvedPackages to {}
	repeat with pkgName in packageNames
		set nameText to contents of pkgName
		
		-- Collect all distinct versions for this package
		set versions to {}
		set fromVersions to {}
		repeat with pkgRecord in packageRecords
			set oldDelimiters to AppleScript's text item delimiters
			set AppleScript's text item delimiters to tab
			set parts to text items of (contents of pkgRecord)
			set AppleScript's text item delimiters to oldDelimiters
			
			if (item 2 of parts) is equal to nameText then
				set pkgVersion to item 3 of parts
				set pkgFrom to item 4 of parts
				if not my listContains(versions, pkgVersion) then
					set end of versions to pkgVersion
					set end of fromVersions to pkgFrom
				end if
			end if
		end repeat
		
		if (count of versions) is 1 then
			-- No conflict
			set end of resolvedPackages to (nameText & tab & item 1 of versions)
		else
			-- Version conflict -- ask the user
			log "DEBUG -> resolvePackageConflicts: conflict for " & nameText & " (" & (count of versions) & " versions)"
			
			set versionOptions to {}
			repeat with i from 1 to (count of versions)
				set end of versionOptions to (item i of versions) & " (from " & (item i of fromVersions) & ")"
			end repeat

			-- Default to the highest package version (not necessarily from the newest Node)
			set versionLines to my joinList(versions, linefeed)
			set highestVersion to do shell script "echo " & quoted form of versionLines & " | sort -V | tail -1"
			set defaultOption to item 1 of versionOptions
			repeat with i from 1 to (count of versions)
				if item i of versions is highestVersion then
					set defaultOption to item i of versionOptions
					exit repeat
				end if
			end repeat

			set userChoice to choose from list versionOptions with title notificationTitle with prompt ("\"" & nameText & "\" has different versions installed. Which version would you like to keep?") default items {defaultOption}
			if userChoice is false then
				error number -128
			end if
			
			-- Brief delay to let the dialog dismiss before heavy work continues
			delay 0.5
			
			-- Extract version from "5.5.4 (from v22.6.0)"
			set chosenText to item 1 of userChoice
			set oldDelimiters to AppleScript's text item delimiters
			set AppleScript's text item delimiters to " (from "
			set chosenVersion to text item 1 of chosenText
			set AppleScript's text item delimiters to oldDelimiters
			set end of resolvedPackages to (nameText & tab & chosenVersion)
		end if
	end repeat
	
	log "DEBUG -> resolvePackageConflicts: resolved to " & (count of resolvedPackages) & " packages"
	return resolvedPackages
end resolvePackageConflicts

------------------------------------------------------------------
-- Core: installGlobalPackages
------------------------------------------------------------------
on installGlobalPackages(sourcePath, nvmLocation, targetVersion, packages, linkedPackages)
	log "DEBUG -> installGlobalPackages: version=" & targetVersion & " packages=" & (count of packages) & " linked=" & (count of linkedPackages)
	set nvmPrefix to "source " & quoted form of sourcePath & " >/dev/null 2>&1 && " & quoted form of nvmLocation

	-- Install regular packages in batch
	if (count of packages) > 0 then
		set packageSpecs to {}
		repeat with pkg in packages
			-- Format: "name<tab>version"
			set oldDelimiters to AppleScript's text item delimiters
			set AppleScript's text item delimiters to tab
			set parts to text items of (contents of pkg)
			set AppleScript's text item delimiters to oldDelimiters
			set end of packageSpecs to quoted form of ((item 1 of parts) & "@" & (item 2 of parts))
		end repeat

		set packageString to my joinList(packageSpecs, " ")
		log "DEBUG -> installGlobalPackages: installing " & packageString & " on " & targetVersion
		display notification "Installing global packages on Node.js " & targetVersion & " ..." with title notificationTitle

		do shell script nvmPrefix & " use " & quoted form of targetVersion & " && npm install -g " & packageString
	end if

	-- Re-link local dev packages
	if (count of linkedPackages) > 0 then
		repeat with linkedPkg in linkedPackages
			-- Format: "LINKED<tab>name<tab>path"
			set oldDelimiters to AppleScript's text item delimiters
			set AppleScript's text item delimiters to tab
			set parts to text items of (contents of linkedPkg)
			set AppleScript's text item delimiters to oldDelimiters
			set pkgName to item 2 of parts
			set pkgPath to item 3 of parts

			log "DEBUG -> installGlobalPackages: linking " & pkgName & " from " & pkgPath
			display notification "Linking " & pkgName & " on Node.js " & targetVersion & " ..." with title notificationTitle
			do shell script nvmPrefix & " use " & quoted form of targetVersion & " && cd " & quoted form of pkgPath & " && npm link"
		end repeat
	end if
	
	log "DEBUG -> installGlobalPackages: completed for " & targetVersion
end installGlobalPackages

------------------------------------------------------------------
-- Core: runNvmUpdate
------------------------------------------------------------------
on runNvmUpdate(sourcePath, nvmLocation, jqPath)
	log "DEBUG -> runNvmUpdate: start"
	set nvmPrefix to "source " & quoted form of sourcePath & " >/dev/null 2>&1 && " & quoted form of nvmLocation

	-- Fetch current LTS versions from the official release schedule
	set ltsVersions to my fetchCurrentLtsVersions(sourcePath, jqPath)
	log "DEBUG -> runNvmUpdate: LTS versions=" & my joinList(ltsVersions, ", ")

	-- Get all installed versions and identify non-LTS
	set installedVersions to my getInstalledVersions(sourcePath, nvmLocation)
	log "DEBUG -> runNvmUpdate: installed versions=" & my joinList(installedVersions, ", ")

	set nonLtsVersions to {}
	repeat with installedVersion in installedVersions
		set majorVer to my getMajorVersion(contents of installedVersion)
		if not my listContains(ltsVersions, majorVer) then
			set end of nonLtsVersions to contents of installedVersion
		end if
	end repeat
	log "DEBUG -> runNvmUpdate: non-LTS versions=" & my joinList(nonLtsVersions, ", ")

	-- Ask user about removing non-LTS versions BEFORE any work
	set removeNonLts to false
	if (count of nonLtsVersions) > 0 then
		set versionListText to my joinList(nonLtsVersions, ", ")
		display dialog "These installed versions are not current LTS and will be removed:" & return & return & versionListText & return & return & "Continue?" buttons {"Cancel", "Keep All", "Remove"} default button "Remove" cancel button "Cancel"
		if button returned of result is "Remove" then
			set removeNonLts to true
		end if
	end if

	-- Collect global packages from ALL installed versions (including ones to be removed)
	display notification "Collecting global packages ..." with title notificationTitle
	set packageData to my collectGlobalPackages(sourcePath, nvmLocation, jqPath, installedVersions)
	set regularPkgs to regularPackages of packageData
	set linkedPkgs to linkedPackages of packageData
	set nonRegPkgs to nonRegistryPackages of packageData
	log "DEBUG -> runNvmUpdate: collected " & (count of regularPkgs) & " regular, " & (count of linkedPkgs) & " linked, " & (count of nonRegPkgs) & " non-registry"

	set skipRemoval to false
	if collectionFailed of packageData then
		display dialog "Warning: Failed to collect some global packages. Package migration may be incomplete." & return & return & "Continue with installation? (Version removal will be skipped to protect packages)" buttons {"Cancel", "Continue"} cancel button "Cancel" default button "Continue" with icon caution
		set skipRemoval to true
	end if

	-- Warn about non-registry packages that cannot be automatically migrated
	if (count of nonRegPkgs) > 0 then
		set nonRegNames to {}
		repeat with nonRegPkg in nonRegPkgs
			set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, tab}
			set nonRegParts to text items of (contents of nonRegPkg)
			set AppleScript's text item delimiters to oldTID
			set end of nonRegNames to (item 2 of nonRegParts) & " (from " & (item 4 of nonRegParts) & ")"
		end repeat
		set nonRegText to my joinList(nonRegNames, return)
		display dialog "The following packages were installed from non-registry sources and will be skipped during migration:" & return & return & nonRegText & return & return & "You will need to reinstall these manually." buttons {"Cancel", "Continue"} cancel button "Cancel" default button "Continue" with icon caution
	end if

	-- Resolve package version conflicts
	set resolvedPkgs to {}
	if (count of regularPkgs) > 0 then
		set resolvedPkgs to my resolvePackageConflicts(regularPkgs)
	end if

	-- Install each LTS major version
	repeat with ltsVersion in ltsVersions
		log "DEBUG -> runNvmUpdate: installing LTS " & (contents of ltsVersion)
		display notification "Installing Node.js " & (contents of ltsVersion) & " (LTS) ..." with title notificationTitle
		do shell script nvmPrefix & " install " & quoted form of (contents of ltsVersion)
	end repeat

	-- Set highest LTS as default
	set highestLts to item -1 of ltsVersions
	log "DEBUG -> runNvmUpdate: setting default to " & highestLts
	do shell script nvmPrefix & " alias default " & quoted form of highestLts

	-- Get the actual installed version for each LTS major
	set targetVersions to {}
	repeat with ltsVersion in ltsVersions
		set fullVer to do shell script nvmPrefix & " version " & quoted form of (contents of ltsVersion)
		log "DEBUG -> runNvmUpdate: LTS " & (contents of ltsVersion) & " resolved to " & fullVer
		set end of targetVersions to fullVer
	end repeat

	-- Install packages and re-link on each LTS version
	if (count of resolvedPkgs) > 0 or (count of linkedPkgs) > 0 then
		display notification "Migrating global packages ..." with title notificationTitle
		repeat with targetVersion in targetVersions
			my installGlobalPackages(sourcePath, nvmLocation, contents of targetVersion, resolvedPkgs, linkedPkgs)
		end repeat
	end if

	-- Offer to update all global packages to latest
	if (count of resolvedPkgs) > 0 then
		display dialog "Would you like to update all global packages to their latest versions?" & return & return & "(Locally linked packages will not be affected)" buttons {"Skip", "Update"} default button "Update"
		if button returned of result is "Update" then
			-- Build a space-separated list of package names (without versions) for targeted update.
			-- Using "npm update -g <names>" instead of bare "npm update -g" avoids .DS_Store errors.
			set pkgNames to {}
			repeat with pkg in resolvedPkgs
				set oldDelimiters to AppleScript's text item delimiters
				set AppleScript's text item delimiters to tab
				set parts to text items of (contents of pkg)
				set AppleScript's text item delimiters to oldDelimiters
				set end of pkgNames to quoted form of (item 1 of parts)
			end repeat
			set pkgNameString to my joinList(pkgNames, " ")

			repeat with targetVersion in targetVersions
				log "DEBUG -> runNvmUpdate: updating packages on " & (contents of targetVersion)
				display notification "Updating global packages on Node.js " & (contents of targetVersion) & " ..." with title notificationTitle
				do shell script nvmPrefix & " use " & quoted form of (contents of targetVersion) & " && npm update -g " & pkgNameString
			end repeat
		end if
	end if

	-- Uninstall non-LTS versions the user confirmed for removal
	if removeNonLts and not skipRemoval then
		repeat with nonLtsVersion in nonLtsVersions
			log "DEBUG -> runNvmUpdate: uninstalling " & (contents of nonLtsVersion)
			display notification "Removing Node.js " & (contents of nonLtsVersion) & " ..." with title notificationTitle
			do shell script nvmPrefix & " uninstall " & quoted form of (contents of nonLtsVersion)
		end repeat
	end if

	-- Clean up older patch versions within each LTS major line.
	-- After "nvm install 20" adds v20.19.0, the old v20.17.0 is still installed.
	-- Keep only the latest (targetVersions) and remove the rest.
	-- Skipped if package collection failed (to protect packages on old versions).
	if not skipRemoval then
		set refreshedVersions to my getInstalledVersions(sourcePath, nvmLocation)
		set oldPatchVersions to {}
		repeat with refreshedVersion in refreshedVersions
			if not my listContains(targetVersions, contents of refreshedVersion) then
				set majorVer to my getMajorVersion(contents of refreshedVersion)
				if my listContains(ltsVersions, majorVer) then
					set end of oldPatchVersions to contents of refreshedVersion
				end if
			end if
		end repeat

		if (count of oldPatchVersions) > 0 then
			set patchListText to my joinList(oldPatchVersions, ", ")
			display dialog "These older LTS patch versions can be removed:" & return & return & patchListText & return & return & "The latest patch for each LTS line has already been installed." buttons {"Keep All", "Remove"} default button "Remove"
			if button returned of result is "Remove" then
				repeat with oldPatch in oldPatchVersions
					log "DEBUG -> runNvmUpdate: removing old patch version " & (contents of oldPatch)
					display notification "Removing old Node.js " & (contents of oldPatch) & " ..." with title notificationTitle
					do shell script nvmPrefix & " uninstall " & quoted form of (contents of oldPatch)
				end repeat
			end if
		end if
	end if

	log "DEBUG -> runNvmUpdate: completed"
end runNvmUpdate

------------------------------------------------------------------
-- Core: runUpdateFlow
------------------------------------------------------------------
on runUpdateFlow(sourcePath, nvmLocation, jqPath)
	log "DEBUG -> runUpdateFlow: start"
	
	my runNvmUpdate(sourcePath, nvmLocation, jqPath)
	
	log "DEBUG -> runUpdateFlow: showing completion notification"
	display notification "All Node.js versions and packages have been successfully updated!" with title notificationTitle sound name notificationSound
	
	log "DEBUG -> runUpdateFlow: completed"
end runUpdateFlow

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
		set searchResult to my findSourceForCommand(sourceCandidates, "nvm")

		if (commandPath of searchResult) is "" and not (profileFound of searchResult) then
			display dialog "Unable to determine if Node.js or NVM is installed. No shell profile (e.g. \"~/.zshrc\") could be located." with icon stop buttons {"OK"} default button "OK"
			return
		end if

		set sourcePath to sourcePath of searchResult
		set nvmLocation to commandPath of searchResult

		if nvmLocation is "" or (nvmLocation ends with "nvm") is false then
			display dialog "NVM is not installed or could not be found. Please install NVM and try again." buttons {"OK"} with icon stop default button "OK"
			return
		end if

		set jqPath to my ensureJqAvailable(sourcePath)
		my runUpdateFlow(sourcePath, nvmLocation, jqPath)
		log "DEBUG -> run: done"
	on error errMsg number errNum
		if errMsg contains "User canceled" or errNum is equal to -128 then
			return
		end if
		display dialog errMsg buttons {"OK"} with icon stop default button "OK"
	end try
end run
