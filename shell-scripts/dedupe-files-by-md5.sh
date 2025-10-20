#!/bin/bash

# Variables.
SOURCE_DIR="/replace/with/source/directory"   # Specify the source directory to copy files from.
TARGET_DIR="/replace/with/target/directory"   # Specify the target directory to copy files to.
CHECKSUM_FILE="/some/path/organize-files.txt" # Specify the location to store information on copied files.
FILE_EXTENSIONS=("txt" "jpg" "pdf")           # Specify the file extensions you would like to select.

# Check if the script is running on macOS.
if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: This script is only supported on macOS."
  exit 1
fi

# Check if the source directory exists.
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERROR: Source directory does not exist."
  exit 1
fi

# Check if the target directory exists.
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ERROR: Target directory does not exist."
  exit 1
fi

# Function to generate timestamp from file creation date in 24-hour format.
generate_timestamp() {
  local file="$1"
  local creation_date

  # Format is "YYYY.MM.DD - 00.00.00".
  creation_date=$(mdls -name kMDItemContentCreationDate -raw "$file")
  date -jf "%Y-%m-%d %H:%M:%S %z" "$creation_date" "+%Y.%m.%d - %H.%M.%S"
}

# Function to generate a unique filename by appending a suffix if needed.
generate_unique_filename() {
  local base_name="$1"
  local extension="$2"
  local target_dir="$3"
  local counter=1
  local unique_name

  while true; do
    unique_name="${base_name} #$counter.$extension"

    if [[ ! -e "$target_dir/$unique_name" ]]; then
      break
    fi

    counter=$((counter + 1))
  done

  echo "$unique_name"
}

# Start constructing the find command.
find_command=""

# Loop through file extensions.
for ext in "${FILE_EXTENSIONS[@]}"; do
  if [ -z "$find_command" ]; then
    # First extension, no leading "-o".
    find_command="-iname *.${ext}"
  else
    # Subsequent extensions, prepend with "-o".
    find_command="$find_command -o -iname *.${ext}"
  fi
done

# Find and process files.
find "$SOURCE_DIR" -type f "${find_command[@]/#/}" | while read -r file; do
  # Skip files that start with "._".
  if [[ "$(basename "$file")" =~ ^\._ ]]; then
    continue
  fi

  # Calculate the MD5 checksum of the file.
  CHECKSUM=$(md5 -q "$file")

  # If the checksum file does not exist, create it.
  if [ ! -e "$CHECKSUM_FILE" ]; then
      touch "$CHECKSUM_FILE"
  fi

  # Check if the checksum is already in the checksum file.
  if grep -q "$CHECKSUM" "$CHECKSUM_FILE"; then
    echo "Skipping duplicated file: $file ..."
    continue
  fi

  # Add the checksum to the checksum file.
  echo "$CHECKSUM" >> "$CHECKSUM_FILE"

  # Generate the new filename based on the file's creation date (24-hour format).
  TIMESTAMP=$(generate_timestamp "$file")
  BASENAME=$(basename "$file")
  EXT="${BASENAME##*.}"

  # Generate a unique filename.
  UNIQUE_NAME=$(generate_unique_filename "$TIMESTAMP" "$EXT" "$TARGET_DIR")

  # Use rsync to copy the file to the target directory with the new name, preserving the original timestamp.
  rsync -a --timeout=300 "$file" "$TARGET_DIR/$UNIQUE_NAME"

  # Increment the counter for copied files.
  copied_count=$((copied_count + 1))

  echo "[Operation #$copied_count] Copied $file to $TARGET_DIR/$UNIQUE_NAME ..."
done

# Mention that files have completed processing.
echo "Processing files complete."
