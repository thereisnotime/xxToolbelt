#!/bin/bash
# shellcheck disable=2139
# shellcheck disable=2140
# shellcheck disable=2034
# shellcheck disable=1090
# shellcheck disable=2120
# shellcheck disable=2181
# shellcheck disable=SC2001
# shellcheck disable=SC2002
# TODO: Remove WET code.
# TODO: Add indication for private scripts when listing.
# TODO: Add option to import script module from url.
# TODO: Add option to open scripts from the menu.
# TODO: Add a field for description of the scripts.
# TODO: Fix placement of info log to be under the menu, not above.
# TODO: Add mechanism to prevent same naming of scripts in different languages.
# TODO: Remove eval's as they are not safe.
# TODO: Add option to export scripts to URLs.
# TODO: Replace all import/exports mechanisms with JSON objects.
# TODO: Fix hack for dirty exit loops.
# TODO: Add nice search mechanism.
# TODO: Add fzf for faster selection of scripts when exporting.
_SCRIPT_VERSION="2.2.0"
_SCRIPT_NAME="xxTB"

#####################################
#### Configuration
#####################################
# NOTE: Editor used by 'xxtb -o' to open scripts folder.
XXTOOLBELT_SCRIPTS_EDITOR="code"
# NOTE The folder where the scripts are located.
XXTOOLBELT_SCRIPTS_FOLDER="$HOME/.xxtoolbelt/scripts"
# NOTE: The depth of the scanning for scripts in the scripts folder.
XXTOOLBELT_SCANNING_DEPTH="3"
# NOTE: Add the extensions of the scripts you want to load.
XXTOOLBELT_SCRIPTS_WHITELIST=( "py" "sh" "erl" "hrl" "exs" "java" "rs" "ps1" "pwsh" "rb" "lua" "cpp" "c" "pl" "groovy" "d" "go" "js" "php" "r" "cs" "ts" "janet" "zig" "v" )
# NOTE: The time format can be "short" or "long".
XXTOOLBELT_TIME_FORMAT="short"
# NOTE: The folder where external toolbelts (belts) are cloned.
XXTOOLBELT_BELTS_FOLDER="$HOME/.xxtoolbelt/belts"
# NOTE: The file where belt registrations are stored.
XXTOOLBELT_BELTS_FILE="$HOME/.xxtoolbelt/.belts"

#####################################
#### Constants
#####################################
XXTOOLBELT_DEBUG_FLAG=$(basename "$0/XXTOOLBELT_DEBUG_MODE")
XXTOOLBELT_DEBUG_MODE=$(if [[ -f  $XXTOOLBELT_DEBUG_FLAG ]]; then echo 1; else echo 0; fi)
XXTOOLBELT_PRIVATE_KEYWORD=".private"
XXTOOLBELT_MAIN_FILE="$XXTOOLBELT_SCRIPTS_FOLDER/../xxtoolbelt.sh"
XXTOOLBELT_LOADED_SCRIPTS=0

#####################################
#### Helpers
#####################################
fblack='\e[0;30m'        # Black
fred='\e[0;31m'          # Red
fgreen='\e[0;32m'        # Green
fyellow='\e[0;33m'       # Yellow
fblue='\e[0;34m'         # Blue
fpurple='\e[0;35m'       # Purple
fcyan='\e[0;36m'         # Cyan
fwhite='\e[0;37m'        # White
bblack='\e[1;30m'       # Black
bred='\e[1;31m'         # Red
bgreen='\e[1;32m'       # Green
byellow='\e[1;33m'      # Yellow
bblue='\e[1;34m'        # Blue
bpurple='\e[1;35m'      # Purple
bcyan='\e[1;36m'        # Cyan
bwhite='\e[1;37m'       # White
nc="\e[m"               # Color Reset
function log() {
    local _message="$1"
    local _level="$2"
    local _nl="\n"
	local _timestamp
	# check format
	if [ "$XXTOOLBELT_TIME_FORMAT" == "short" ]; then
		_timestamp=$(date +%H:%M:%S)
	else
		_timestamp=$(date +%d.%m.%Y-%d:%H:%M:%S-%Z)
	fi
    case $(echo "$_level" | tr '[:upper:]' '[:lower:]') in
    "info" | "information")
        echo -ne "${bwhite}[INFO][${_SCRIPT_NAME} ${_SCRIPT_VERSION}][${_timestamp}]: ${_message}${nc}${_nl}"
        ;;
    "warn" | "warning")
        echo -ne "${byellow}[WARN][${_SCRIPT_NAME} ${_SCRIPT_VERSION}][${_timestamp}]: ${_message}${nc}${_nl}"
        ;;
    "err" | "error")
        echo -ne "${bred}[ERR][${_SCRIPT_NAME} ${_SCRIPT_VERSION}][${_timestamp}]: ${_message}${nc}${_nl}"
        ;;
	"dbg" | "debug")
		if [ "$XXTOOLBELT_DEBUG_MODE" -eq 1 ]; then
			echo -ne "${bcyan}[DEBUG][${_SCRIPT_NAME} ${_SCRIPT_VERSION}][${_timestamp}]: ${_message}${nc}${_nl}"
		fi
		;;
    *)
        echo -ne "${bblue}[UNKNOWN][${_SCRIPT_NAME} ${_SCRIPT_VERSION}][${_timestamp}]: ${_message}${nc}${_nl}"
        ;;
    esac
}
function failure() {
    local _lineno="$2"
    local _fn="$3"
    local _exitstatus="$4"
    local _msg="$5"
    local _lineno_fns="${1% 0}"
    if [[ "$_lineno_fns" != "0" ]]; then _lineno="${_lineno} ${_lineno_fns}"; fi
    log "Error in ${BASH_SOURCE[1]}:${_fn}[${_lineno}] Failed with status ${_exitstatus}: ${_msg}" "ERROR"
}

function xxtb_print_logo () {
	echo -ne "\n${bcyan}
            _____           _ _          _ _   
__  ____  _|_   _|__   ___ | | |__   ___| | |_ 
\ \/ /\ \/ / | |/ _ \ / _ \| | '_ \ / _ \ | __|
 >  <  >  <  | | (_) | (_) | | |_) |  __/ | |_ 
/_/\_\/_/\_\ |_|\___/ \___/|_|_.__/ \___|_|\__|
${nc}\n"
}
function xxtb_print_menu () {
	echo -ne "${bcyan}======= version $_SCRIPT_VERSION =======${nc}
${bwhite}
1) Open scripts folder
2) List synced scripts ($XXTOOLBELT_LOADED_SCRIPTS)
3) Export script (from command)
4) Import script
5) Show CLI options
6) Sync scripts (symlinks)
7) Toggle DEBUG mode (dbg:$XXTOOLBELT_DEBUG_MODE)
8) Update xxToolbelt
9) Manage belts
0) Exit
${nc}
${bcyan}===============================${nc}"
}
function xxtb_print_belts_menu () {
	echo -ne "${bcyan}======= Belts Management =======${nc}
${bwhite}
1) List belts
2) Add belt (git)
3) Add belt (local)
4) Enable belt
5) Disable belt
6) Remove belt
0) Back
${nc}
${bcyan}===============================${nc}"
}
function xxtb-belts-menu () {
	clear
	xxtb_print_belts_menu
	echo -ne "\nYour choice: "
	read -r b
	case $b in
		1) clear ; xxtb-list-belts ; xxtb_back_belts_menu ;;
		2) clear ; xxtb-add-belt-interactive git ; xxtb-belts-menu ;;
		3) clear ; xxtb-add-belt-interactive local ; xxtb-belts-menu ;;
		4) clear ; xxtb-toggle-belt-interactive enable ; xxtb-belts-menu ;;
		5) clear ; xxtb-toggle-belt-interactive disable ; xxtb-belts-menu ;;
		6) clear ; xxtb-remove-belt-interactive ; xxtb-belts-menu ;;
		0) clear ; xxtb ;;
		*) clear ; log "No such option." "ERROR" ; xxtb-belts-menu ;;
	esac
}
function xxtb_back_belts_menu () {
	tput civis
	log "\n\n${fwhite}<--- Press ENTER to go back.${nc}" "INFO"
	read -r -s
	xxtb-belts-menu
}
function xxtb-add-belt-interactive () {
	local type="$1"
	echo -ne "\nEnter belt name: "
	read -r belt_name
	if [[ -z "$belt_name" ]]; then
		log "Belt name cannot be empty." "ERROR"
		return 1
	fi
	if [[ "$type" == "git" ]]; then
		echo -ne "Enter git URL: "
		read -r belt_source
	else
		echo -ne "Enter local path: "
		read -r belt_source
	fi
	if [[ -z "$belt_source" ]]; then
		log "Source cannot be empty." "ERROR"
		return 1
	fi
	xxtb-add-belt "$belt_name" "$belt_source"
}
function xxtb-toggle-belt-interactive () {
	local action="$1"
	xxtb-list-belts
	echo -ne "\nEnter belt name to $action: "
	read -r belt_name
	if [[ -z "$belt_name" ]]; then
		log "Belt name cannot be empty." "ERROR"
		return 1
	fi
	if [[ "$action" == "enable" ]]; then
		xxtb-enable-belt "$belt_name"
	else
		xxtb-disable-belt "$belt_name"
	fi
}
function xxtb-remove-belt-interactive () {
	xxtb-list-belts
	echo -ne "\nEnter belt name to remove: "
	read -r belt_name
	if [[ -z "$belt_name" ]]; then
		log "Belt name cannot be empty." "ERROR"
		return 1
	fi
	echo -ne "Are you sure you want to remove '$belt_name'? (y/N): "
	read -r confirm
	if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
		xxtb-remove-belt "$belt_name"
	else
		log "Cancelled." "INFO"
	fi
}
function xxtb_back_menu () {
	tput civis
	log "\n\n${fwhite}<--- Press ENTER to go back to the menu.${nc}" "INFO"
	read -r -s
	clear
	xxtb
}
function xxtb () {
	while test $# -gt 0; do
	# TODO: Add second argument for exporting for new function name.
		case "$1" in
			-h|--help)
				echo -ne "${bcyan}==== xxToolbelt v$_SCRIPT_VERSION commands:${nc}\n\n"
				echo -ne "xxtb ${bred}[options]${nc} ${bblue}[arguments]${nc}\n\n"
				echo -ne "${bcyan}options:${nc}\n"
				echo -ne "-${bred}h${nc}, --${bred}help${nc}                        show command help\n"
				echo -ne "-${bred}e${nc} ${bblue}COMMAND${nc}, --${bred}export${nc}=${bblue}COMMAND${nc}      specify a command to export\n"
				echo -ne "-${bred}s${nc}, --${bred}sync${nc}                        sync scripts to ~/.local/bin (create/update/clean symlinks)\n"
				echo -ne "-${bred}ls${nc}, --${bred}list${nc}                       list all loaded scripts\n"
				echo -ne "-${bred}d${nc}, --${bred}debug${nc}                       toggle debug mode\n"
				echo -ne "-${bred}o${nc}, --${bred}open${nc}                        open scripts folder\n"
				echo -ne "-${bred}u${nc}, --${bred}update${nc}                      update xxToolbelt and all belts\n"
				echo -ne "\n${bcyan}belts:${nc}\n"
				echo -ne "-${bred}a${nc} ${bblue}NAME URL${nc}, --${bred}add-belt${nc}            add external toolbelt (git url or local path)\n"
				echo -ne "-${bred}r${nc}, --${bred}belts${nc}                       list registered belts\n"
				echo -ne "--${bred}remove-belt${nc} ${bblue}NAME${nc}               remove a belt\n"
				echo -ne "--${bred}disable-belt${nc} ${bblue}NAME${nc}              disable a belt (keeps registration)\n"
				echo -ne "--${bred}enable-belt${nc} ${bblue}NAME${nc}               enable a disabled belt\n"
				return 0
				;;
			-v|--version)
				echo "xxToolbelt $_SCRIPT_VERSION"
				return 0
				;;
			-u|--update)
				xxtb-update
				return 0
				;;
			-o|--open)
				xxtb-open-folder
				return 0
				;;
			-d|--debug)
				xxtb-toggle-debug
				return 0
				;;
			-ls|--list)
				xxtb-list-scripts
				return 0
				;;
			-s|--sync)
				xxtb-sync
				return 0
				;;
			-a|--add-belt)
				xxtb-add-belt "$2" "$3"
				return $?
				;;
			-r|--belts)
				xxtb-list-belts
				return 0
				;;
			--remove-belt)
				xxtb-remove-belt "$2"
				return $?
				;;
			--disable-belt)
				xxtb-disable-belt "$2"
				return $?
				;;
			--enable-belt)
				xxtb-enable-belt "$2"
				return $?
				;;
			-e)
				xxtb-export "$2"
				return 0
				;;
			--export=*)
				xxtb-export "$( echo "$1" | cut -d "=" -f2)"
				return 0
				;;
			*)
				log "No such option. Try help with xxtb --help" "ERROR"
				return 1
		esac
	done

	tput cnorm
	xxtb_print_logo
	xxtb_print_menu
			echo -ne "\nYour choice: "
			read -r a
			case $a in
				1) xxtb-open-folder ; clear; xxtb ;;
				2) clear ; xxtb-list-scripts ; xxtb_back_menu ;;
				3) clear ; xxtb-show-command-export-menu ; xxtb ;;
				4) xxtb-show-import-script-menu ; xxtb ;;
				5) clear ; xxtb -h ; xxtb_back_menu ; xxtb ;;
				6) clear ; xxtb-sync ; xxtb_back_menu ;;
				7) clear ; xxtb-toggle-debug ; xxtb ;;
				8) clear ; xxtb-update ;;
				9) xxtb-belts-menu ;;
			0) kill $$ ;;
			*) clear; log "No such option." "ERROR"; xxtb
			esac
}
function xxtb-reload () {
	log "xxToolbelt v$_SCRIPT_VERSION" "INFO"
	source "$XXTOOLBELT_MAIN_FILE"
}
function b-show-import-script-menu () {
	clear
	echo -ne "\nPaste command: "
	read -r EXPORTED
	if ! [[ $EXPORTED == *"XXTBIMPORT"* ]]; then
		log "This does not seem like an import command." "ERROR"
		return 1
	fi
	# TODO: Fix this quick hack.
	import_command=$(echo "$EXPORTED" | grep -m 1 -o -P '(?<=XXTBIMPORT=).*(?=; mkdir)' )
	eval "$EXPORTED"
	if [ $? -eq 0 ]; then
		log "Import successfull. Give it a try: $import_command" "INFO"
	else
		log "Error while importing." "ERROR"
	fi
}
function xxtb-update () {
	# Update xxToolbelt core
	log "Updating xxToolbelt core..." "INFO"
	update_url="https://raw.githubusercontent.com/thereisnotime/xxToolbelt/main/xxtoolbelt.sh"
	if [ -x "$(command -v curl)" ]; then
		curl -o "$XXTOOLBELT_MAIN_FILE" "$update_url"
	else
		if [ -x "$(command -v wget)" ]; then
			wget "$update_url" -O "$XXTOOLBELT_MAIN_FILE"
		else
			log "You need curl or wget for this." "ERROR"
			return 1
		fi
	fi

	# Update all registered belts
	xxtb-update-belts

	# Reload and sync
	xxtb-reload
	xxtb-sync
}
function xxtb-open-folder () {
	xdg-open "$XXTOOLBELT_SCRIPTS_FOLDER" 
}
function xxtb-export () {
	script_name="$1"
	file_path=$(find -L "$XXTOOLBELT_SCRIPTS_FOLDER" -mindepth 2 -maxdepth "$XXTOOLBELT_SCANNING_DEPTH" -type f -name "$script_name.*")
	if ! [ -f "$file_path" ]; then
		log "No such script was found: $script_name" "ERROR"
		return 1
	fi 
	file_name=$(basename -- "$file_path")
	file_extension="${file_name##*.}"
	file_name="${file_name%.*}"
	file_content=$(cat "$file_path" | base64)
	file_folder=${file_path//$XXTOOLBELT_SCRIPTS_FOLDER}
	file_folder=${file_folder//$file_name.$file_extension}
	file_command=${file_name//$XXTOOLBELT_PRIVATE_KEYWORD}
	log "To import the script paste in terminal or in the xxTB import menu the following:\n" "INFO"
	export_command=XXTBIMPORT="$file_command; mkdir -p \"\$XXTOOLBELT_SCRIPTS_FOLDER$file_folder\" || true; if [[ -f \"\$XXTOOLBELT_SCRIPTS_FOLDER$file_folder$file_name.$file_extension\" ]]; then echo \"ERROR: File already exists.\"; fi; echo \"$file_content\" | base64 --decode >> \"\$XXTOOLBELT_SCRIPTS_FOLDER$file_folder$file_name.$file_extension\"; xxtb-sync;"
	export_command=$(echo "$export_command" | tr -d '\n')
	echo -ne "${bblue}$export_command${nc}\n"
}
function xxtb-show-command-export-menu () {
	# TODO: Fine tune the find command.
	xxtb-list-scripts
	echo -ne "\nEnter command of the script: "
	read -r SCRIPTNAME
	clear
	# TODO: Improve file/folder management.
	xxtb-export "$SCRIPTNAME"
	xxtb_back_menu
}
function xxtb-toggle-debug () {
	if [[ "$XXTOOLBELT_DEBUG_MODE" == 1 ]]; then
		XXTOOLBELT_DEBUG_MODE=0
		rm -f "$XXTOOLBELT_DEBUG_FLAG" &> /dev/null
		log "Debug mode set to OFF" "INFO"
	else
		XXTOOLBELT_DEBUG_MODE=1
		touch "$XXTOOLBELT_DEBUG_FLAG" &> /dev/null
		log "Debug mode set to ON" "INFO"
	fi
}
function xxtb-list-scripts () {
	# TODO: Chante the list to be a real listing instead of loading.
	XXTOOLBELT_LOADED_SCRIPTS=0
	while IFS= read -r -d '' file; do
		filename=$(basename -- "$file")
		extension="${filename##*.}"
		filename="${filename%.*}"
		if [[ " ${XXTOOLBELT_SCRIPTS_WHITELIST[*]} " =~  ${extension}  ]]; then
			filename=$(echo "$filename" | sed "s@$XXTOOLBELT_PRIVATE_KEYWORD@@")
			log "Script $XXTOOLBELT_LOADED_SCRIPTS | Command: ${bred}$filename${nc}${fgreen} | Source: ${bwhite}$file${nc}" "INFO"
			((XXTOOLBELT_LOADED_SCRIPTS+=1))
		fi
	done < <(find -L "$XXTOOLBELT_SCRIPTS_FOLDER" -mindepth 2 -maxdepth "$XXTOOLBELT_SCANNING_DEPTH" -type f -print0)
	log "Total: $XXTOOLBELT_LOADED_SCRIPTS scripts." "INFO"
}
function xxtb-sync () {
	# Symlink-based script loading - works in all contexts (interactive shell, AI tools, scripts)
	XXTOOLBELT_BIN_FOLDER="$HOME/.local/bin"
	mkdir -p "$XXTOOLBELT_BIN_FOLDER"

	# Phase 1: Clean up stale symlinks (pointing to deleted scripts)
	local _cleaned=0
	for link in "$XXTOOLBELT_BIN_FOLDER"/*; do
		[[ -L "$link" ]] || continue
		local target
		target=$(readlink "$link")
		# Only clean symlinks that point into our scripts folder
		if [[ "$target" == "$XXTOOLBELT_SCRIPTS_FOLDER"* ]] && [[ ! -e "$link" ]]; then
			rm -f "$link"
			if [ "$XXTOOLBELT_DEBUG_MODE" -eq 1 ]; then
				log "Removed stale symlink: $(basename "$link")" "DEBUG"
			fi
			((_cleaned+=1))
		fi
	done

	# Phase 2: Create/update symlinks for current scripts (core only, skip belt symlinks)
	XXTOOLBELT_LOADED_SCRIPTS=0
	for dir in "$XXTOOLBELT_SCRIPTS_FOLDER"/*/; do
		[[ -d "$dir" ]] || continue
		# Skip symlinked directories (those are belt directories)
		[[ -L "${dir%/}" ]] && continue
		while IFS= read -r -d '' file; do
			filename=$(basename -- "$file")
			extension="${filename##*.}"
			filename="${filename%.*}"
			if [[ " ${XXTOOLBELT_SCRIPTS_WHITELIST[*]} " =~  ${extension}  ]]; then
				# Skip library files (starting with _)
				if [[ "$filename" == _* ]]; then
					continue
				fi
				if ! [[ -x "$file" ]]; then chmod +x "$file"; fi
				filename=$(echo "$filename" | sed "s@$XXTOOLBELT_PRIVATE_KEYWORD@@")
				ln -sf "$file" "$XXTOOLBELT_BIN_FOLDER/$filename"
				if [ "$XXTOOLBELT_DEBUG_MODE" -eq 1 ]; then
					log "Synced: $filename(.$extension) -> $file" "DEBUG"
				fi
				((XXTOOLBELT_LOADED_SCRIPTS+=1))
			fi
		done < <(find -L "$dir" -maxdepth "$((XXTOOLBELT_SCANNING_DEPTH - 1))" -type f -print0)
	done

	# Phase 3: Sync belt scripts
	local _belt_result _belt_count _belt_scripts
	_belt_result=$(xxtb-sync-belts)
	_belt_count=$(echo "$_belt_result" | cut -d' ' -f1)
	_belt_scripts=$(echo "$_belt_result" | cut -d' ' -f2)

	if [[ "$_belt_count" -gt 0 ]]; then
		log "Synced $XXTOOLBELT_LOADED_SCRIPTS core + $_belt_scripts scripts from $_belt_count belt(s), cleaned $_cleaned stale links." "INFO"
	else
		log "Synced $XXTOOLBELT_LOADED_SCRIPTS scripts, cleaned $_cleaned stale links." "INFO"
	fi
}

# Legacy alias for backwards compatibility
function xxtb-load () {
	log "xxtb-load is deprecated, use xxtb-sync instead." "WARN"
	xxtb-sync
}

#####################################
#### Belts Management
#####################################
function xxtb-add-belt () {
	local name="$1"
	local source="$2"

	if [[ -z "$name" ]] || [[ -z "$source" ]]; then
		log "Usage: xxtb -a <name> <git-url|local-path>" "ERROR"
		return 1
	fi

	# Check if belt already exists
	if [[ -f "$XXTOOLBELT_BELTS_FILE" ]] && grep -q "^${name}|" "$XXTOOLBELT_BELTS_FILE"; then
		log "Belt '$name' already exists. Remove it first with: xxtb --remove-belt $name" "ERROR"
		return 1
	fi

	# Determine if source is local path or git URL
	if [[ "$source" == /* ]] || [[ "$source" == ~* ]]; then
		# Local path - expand tilde if present
		source="${source/#\~/$HOME}"
		if [[ ! -d "$source" ]]; then
			log "Local path does not exist: $source" "ERROR"
			return 1
		fi
		log "Registering local belt '$name' from $source" "INFO"
	else
		# Git URL - clone to belts folder
		mkdir -p "$XXTOOLBELT_BELTS_FOLDER"
		local target_dir="$XXTOOLBELT_BELTS_FOLDER/$name"
		if [[ -d "$target_dir" ]]; then
			log "Directory already exists: $target_dir" "ERROR"
			return 1
		fi
		log "Cloning belt '$name' from $source..." "INFO"
		if ! git clone "$source" "$target_dir"; then
			log "Failed to clone repository" "ERROR"
			return 1
		fi
	fi

	# Register the belt
	echo "${name}|${source}" >> "$XXTOOLBELT_BELTS_FILE"
	log "Belt '$name' added successfully." "INFO"

	# Sync to create symlinks
	xxtb-sync
}

function xxtb-list-belts () {
	if [[ ! -f "$XXTOOLBELT_BELTS_FILE" ]] || [[ ! -s "$XXTOOLBELT_BELTS_FILE" ]]; then
		log "No belts registered. Add one with: xxtb -a <name> <git-url|local-path>" "INFO"
		return 0
	fi

	log "Registered belts:" "INFO"
	while IFS='|' read -r name source; do
		[[ -z "$name" ]] && continue
		# Check if disabled (starts with #)
		local disabled=0
		if [[ "$name" == \#* ]]; then
			disabled=1
			name="${name#\#}"
		fi
		# Determine belt location
		local location
		if [[ "$source" == /* ]] || [[ "$source" == ~* ]]; then
			location="${source/#\~/$HOME}"
			if [[ "$disabled" -eq 1 ]]; then
				echo -e "  ${fred}$name${nc} (local, disabled) -> $location"
			else
				echo -e "  ${bgreen}$name${nc} (local) -> $location"
			fi
		else
			location="$XXTOOLBELT_BELTS_FOLDER/$name"
			if [[ "$disabled" -eq 1 ]]; then
				echo -e "  ${fred}$name${nc} (git, disabled) -> $source"
			else
				echo -e "  ${bcyan}$name${nc} (git) -> $source"
			fi
		fi
		# List folders in the belt (skip if disabled)
		if [[ "$disabled" -eq 0 ]] && [[ -d "$location" ]]; then
			for folder in "$location"/*/; do
				[[ -d "$folder" ]] || continue
				local basename
				basename=$(basename "$folder")
				# Skip hidden folders and .git
				[[ "$basename" == .* ]] && continue
				echo -e "    └─ ${name}-${basename}"
			done
		fi
	done < "$XXTOOLBELT_BELTS_FILE"
}

function xxtb-remove-belt () {
	local name="$1"

	if [[ -z "$name" ]]; then
		log "Usage: xxtb --remove-belt <name>" "ERROR"
		return 1
	fi

	if [[ ! -f "$XXTOOLBELT_BELTS_FILE" ]] || ! grep -q "^${name}|" "$XXTOOLBELT_BELTS_FILE"; then
		log "Belt '$name' not found." "ERROR"
		return 1
	fi

	# Get the source to determine if it's a git belt
	local source
	source=$(grep "^${name}|" "$XXTOOLBELT_BELTS_FILE" | cut -d'|' -f2)

	# Remove symlinks for this belt
	local belt_location
	if [[ "$source" == /* ]] || [[ "$source" == ~* ]]; then
		belt_location="${source/#\~/$HOME}"
	else
		belt_location="$XXTOOLBELT_BELTS_FOLDER/$name"
	fi

	# Remove symlinks pointing to this belt's scripts
	XXTOOLBELT_BIN_FOLDER="$HOME/.local/bin"
	for link in "$XXTOOLBELT_BIN_FOLDER"/*; do
		[[ -L "$link" ]] || continue
		local target
		target=$(readlink "$link")
		if [[ "$target" == "$belt_location"* ]]; then
			rm -f "$link"
			log "Removed symlink: $(basename "$link")" "DEBUG"
		fi
	done

	# Remove cloned directory if it's a git belt
	if [[ ! "$source" == /* ]] && [[ ! "$source" == ~* ]]; then
		if [[ -n "$name" ]] && [[ -d "${XXTOOLBELT_BELTS_FOLDER:?}/${name:?}" ]]; then
			rm -rf "${XXTOOLBELT_BELTS_FOLDER:?}/${name:?}"
			log "Removed cloned directory: $XXTOOLBELT_BELTS_FOLDER/$name" "INFO"
		fi
	fi

	# Remove from belts file
	grep -v "^${name}|" "$XXTOOLBELT_BELTS_FILE" > "$XXTOOLBELT_BELTS_FILE.tmp"
	mv "$XXTOOLBELT_BELTS_FILE.tmp" "$XXTOOLBELT_BELTS_FILE"

	log "Belt '$name' removed successfully." "INFO"
}

function xxtb-disable-belt () {
	local name="$1"

	if [[ -z "$name" ]]; then
		log "Usage: xxtb --disable-belt <name>" "ERROR"
		return 1
	fi

	if [[ ! -f "$XXTOOLBELT_BELTS_FILE" ]]; then
		log "No belts registered." "ERROR"
		return 1
	fi

	# Check if belt exists and is enabled
	if grep -q "^${name}|" "$XXTOOLBELT_BELTS_FILE"; then
		sed -i "s/^${name}|/#${name}|/" "$XXTOOLBELT_BELTS_FILE"
		log "Belt '$name' disabled." "INFO"
		xxtb-sync
	elif grep -q "^#${name}|" "$XXTOOLBELT_BELTS_FILE"; then
		log "Belt '$name' is already disabled." "WARN"
	else
		log "Belt '$name' not found." "ERROR"
		return 1
	fi
}

function xxtb-enable-belt () {
	local name="$1"

	if [[ -z "$name" ]]; then
		log "Usage: xxtb --enable-belt <name>" "ERROR"
		return 1
	fi

	if [[ ! -f "$XXTOOLBELT_BELTS_FILE" ]]; then
		log "No belts registered." "ERROR"
		return 1
	fi

	# Check if belt exists and is disabled
	if grep -q "^#${name}|" "$XXTOOLBELT_BELTS_FILE"; then
		sed -i "s/^#${name}|/${name}|/" "$XXTOOLBELT_BELTS_FILE"
		log "Belt '$name' enabled." "INFO"
		xxtb-sync
	elif grep -q "^${name}|" "$XXTOOLBELT_BELTS_FILE"; then
		log "Belt '$name' is already enabled." "WARN"
	else
		log "Belt '$name' not found." "ERROR"
		return 1
	fi
}

function xxtb-sync-belts () {
	# Sync scripts from all registered belts
	# Returns: "<belt_count> <script_count>"
	[[ ! -f "$XXTOOLBELT_BELTS_FILE" ]] && echo "0 0" && return 0

	local _belt_count=0
	local _belt_scripts=0
	XXTOOLBELT_BIN_FOLDER="$HOME/.local/bin"

	while IFS='|' read -r name source; do
		[[ -z "$name" ]] && continue
		# Skip disabled belts (lines starting with #)
		[[ "$name" == \#* ]] && continue

		# Determine belt location
		local location
		if [[ "$source" == /* ]] || [[ "$source" == ~* ]]; then
			location="${source/#\~/$HOME}"
		else
			location="$XXTOOLBELT_BELTS_FOLDER/$name"
		fi

		[[ ! -d "$location" ]] && continue
		((_belt_count+=1))

		# Symlink each folder as scripts/<name>-<folder>
		for folder in "$location"/*/; do
			[[ -d "$folder" ]] || continue
			local basename
			basename=$(basename "$folder")
			# Skip hidden folders
			[[ "$basename" == .* ]] && continue

			# Create symlink in scripts folder
			local symlink_name="${name}-${basename}"
			ln -sfn "$folder" "$XXTOOLBELT_SCRIPTS_FOLDER/$symlink_name"

			if [ "$XXTOOLBELT_DEBUG_MODE" -eq 1 ]; then
				log "Belt symlink: $symlink_name -> $folder" "DEBUG"
			fi

			# Scan folder for scripts and symlink to bin
			while IFS= read -r -d '' file; do
				local filename
				filename=$(basename -- "$file")
				local extension="${filename##*.}"
				filename="${filename%.*}"
				if [[ " ${XXTOOLBELT_SCRIPTS_WHITELIST[*]} " =~  ${extension}  ]]; then
					# Skip library files (starting with _)
					[[ "$filename" == _* ]] && continue
					[[ ! -x "$file" ]] && chmod +x "$file"
					filename=$(echo "$filename" | sed "s@$XXTOOLBELT_PRIVATE_KEYWORD@@")
					ln -sf "$file" "$XXTOOLBELT_BIN_FOLDER/$filename"
					if [ "$XXTOOLBELT_DEBUG_MODE" -eq 1 ]; then
						log "Belt script: $filename -> $file" "DEBUG"
					fi
					((_belt_scripts+=1))
				fi
			done < <(find -L "$folder" -maxdepth 2 -type f -print0 2>/dev/null)
		done
	done < "$XXTOOLBELT_BELTS_FILE"

	echo "$_belt_count $_belt_scripts"
}

function xxtb-update-belts () {
	# Update all git-based belts
	[[ ! -f "$XXTOOLBELT_BELTS_FILE" ]] && return 0

	while IFS='|' read -r name source; do
		[[ -z "$name" ]] && continue
		# Skip disabled belts (lines starting with #)
		[[ "$name" == \#* ]] && continue

		# Skip local paths
		if [[ "$source" == /* ]] || [[ "$source" == ~* ]]; then
			log "Skipping local belt '$name'" "DEBUG"
			continue
		fi

		local belt_dir="$XXTOOLBELT_BELTS_FOLDER/$name"
		if [[ -d "$belt_dir/.git" ]]; then
			log "Updating belt '$name'..." "INFO"
			(cd "$belt_dir" && git pull)
		fi
	done < "$XXTOOLBELT_BELTS_FILE"
}

#####################################
#### Main
#####################################
# NOTE: No auto-load on shell startup. Run 'xxtb -s' to sync scripts to ~/.local/bin
# This keeps shell startup fast and makes scripts available to all tools (AI CLIs, scripts, etc.)

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
	export PATH="$HOME/.local/bin:$PATH"
fi
