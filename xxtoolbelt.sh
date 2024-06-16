#!/bin/bash
# shellcheck disable=2139
# shellcheck disable=2140
# shellcheck disable=2034
# shellcheck disable=1090
# shellcheck disable=2120
# shellcheck disable=2181
# TODO: Remove WET code.
# TODO: Add indication for private scripts when listing.
# TODO: Add option to import script module from url.
# TODO: Add option to open scripts from the menu.
# TODO: Fix placement of info log to be under the menu, not above.
# TODO: Add mechanism to prevent same naming of scripts in different languages.
# TODO: Remove eval's.
# TODO: Replace all import/exports mechanisms with JSON objects.
# TODO: Fix hack for dirty exit loops.
# TODO: Add nice search mechanism.
#####################################
#### Configuration
#####################################
XXTOOLBELT_SCRIPTS_FOLDER="$HOME/.xxtoolbelt/scripts"
XXTOOLBELT_VERSION="1.9.3"
XXTOOLBELT_SCRIPTS_EDITOR="code"
XXTOOLBELT_SCANNING_DEPTH="3"
XXTOOLBELT_DEBUG_FLAG=$(basename "$0/XXTOOLBELT_DEBUG_MODE")
XXTOOLBELT_DEBUG_MODE=$(if [[ -f  $XXTOOLBELT_DEBUG_FLAG ]]; then echo 1; else echo 0; fi)
XXTOOLBELT_PRIVATE_KEYWORD=".private"
XXTOOLBELT_SCRIPTS_WHITELIST=( "py" "sh" "erl" "hrl" "exs" "java" "rs" "ps1" "pwsh" "rb" "lua" "cpp" "c" "pl" "groovy" "d" "go" "js" "php" "r" "cs" "ts" "janet" )
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
function xxtb_log () {
	prefix="[XXTB]"
	case $2 in
		"ERROR") 
			echo -en "${fred}$prefix""[ERROR]: $1${nc}\n"
			;;
		"INFO") 
			echo -en "${fgreen}$prefix""[INFO]: $1${nc}\n"
			;;
		"WARNING") 
			echo -en "${fyellow}$prefix""[WARNING]: $1${nc}\n"
			;;
		"DEBUG") 
			echo -en "${fblue}$prefix""[DEBUG]: $1${nc}\n"
			;;
		*)
			echo -en "${fpurple}$prefix""[UNKNOWN]: $1${nc}\n"
	esac
}
xxtb_print_logo () {
	echo -ne "\n${bcyan}
            _____           _ _          _ _   
__  ____  _|_   _|__   ___ | | |__   ___| | |_ 
\ \/ /\ \/ / | |/ _ \ / _ \| | '_ \ / _ \ | __|
 >  <  >  <  | | (_) | (_) | | |_) |  __/ | |_ 
/_/\_\/_/\_\ |_|\___/ \___/|_|_.__/ \___|_|\__|
${nc}\n"
}
function xxtb_print_menu () {
	echo -ne "${bcyan}======= version $XXTOOLBELT_VERSION =======${nc}
${bwhite}
1) Open scripts folder
2) List loaded scripts ($XXTOOLBELT_LOADED_SCRIPTS)
3) Export script (from command)
4) Import script
5) Show CLI options
6) Reload xxToolbelt
7) Toggle DEBUG mode (dbg:$XXTOOLBELT_DEBUG_MODE)
8) Update xxToolbelt
0) Exit
${nc}
${bcyan}===============================${nc}"
}
function xxtb_back_menu () {
	tput civis
	xxtb_log "\n\n${fwhite}<--- Press ENTER to go back to the menu.${nc}" "INFO"
	read -r -s
	clear
	xxtb
}

#####################################
#### Main
#####################################
function xxtb () {
	while test $# -gt 0; do
	# TODO: Add second argument for exporting for new function name.
		case "$1" in
			-h|--help)
				echo -ne "${bcyan}==== xxToolbelt v$XXTOOLBELT_VERSION commands:${nc}\n\n"
				echo -ne "xxtb ${bred}[options]${nc} ${bblue}[arguments]${nc}\n\n"
				echo -ne "${bcyan}options:${nc}\n"
				echo -ne "-${bred}h${nc}, --${bred}help${nc}                        show command help\n"
				echo -ne "-${bred}e${nc} ${bblue}COMMAND${nc}, --${bred}export${nc}=${bblue}COMMAND${nc}      specify a command to export\n"
				echo -ne "-${bred}r${nc}, --${bred}reload${nc}                      reload xxToolbelt\n"
				echo -ne "-${bred}ls${nc}, --${bred}list${nc}                       list all loaded scripts\n"
				echo -ne "-${bred}d${nc}, --${bred}debug${nc}                       toggle debug mode\n"
				echo -ne "-${bred}s${nc}, --${bred}scripts${nc}                     open scripts folder\n"
				echo -ne "-${bred}u${nc}, --${bred}update${nc}                      update xxToolbelt\n"
				return 0
				;;
			-v|--version)
				echo "xxToolbelt $XXTOOLBELT_VERSION"
				return 0
				;;
			-u|--update)
				xxtb-update
				return 0
				;;
			-s|--scripts)
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
			-r|--reload)
				xxtb-reload
				return 0
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
				xxtb_log "No such option. Try help with xxtb --help" "ERROR"
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
				6) clear ; xxtb-reload ; xxtb ;;
				7) clear ; xxtb-toggle-debug ; xxtb ;;
				8) clear ; xxtb-update ;;
			0) kill $$ ;;
			*) clear; xxtb_log "No such option." "ERROR"; xxtb
			esac
}
function xxtb-reload () {
	xxtb_log "xxToolbox v$XXTOOLBELT_VERSION" "INFO"
	source "$XXTOOLBELT_MAIN_FILE"
}
function b-show-import-script-menu () {
	clear
	echo -ne "\nPaste command: "
	read -r EXPORTED
	if ! [[ $EXPORTED == *"XXTBIMPORT"* ]]; then
		xxtb_log "This does not seem like an import command." "ERROR"
		return 1
	fi
	# TODO: Fix this quick hack.
	import_command=$(echo "$EXPORTED" | grep -m 1 -o -P '(?<=XXTBIMPORT=).*(?=; mkdir)' )
	eval "$EXPORTED"
	if [ $? -eq 0 ]; then
		xxtb_log "Import successfull. Give it a try: $import_command" "INFO"
	else
		xxtb_log "Error while importing." "ERROR"
	fi
}
function xxtb-update () {
	update_url="https://raw.githubusercontent.com/thereisnotime/xxToolbelt/main/xxtoolbelt.sh"
	if [ -x "$(command -v curl)" ]; then
		curl -o "$XXTOOLBELT_MAIN_FILE" "$update_url" 
	else
		if [ -x "$(command -v wget)" ]; then
			wget "$update_url" -O "$XXTOOLBELT_MAIN_FILE"
		else
			xxtb_log "You need curl or wget for this." "ERROR"
			return 1
		fi
	fi
	xxtb-reload
}
function xxtb-open-folder () {
	xdg-open "$XXTOOLBELT_SCRIPTS_FOLDER" 
}
function xxtb-export () {
	script_name="$1"
	file_path=$(find "$XXTOOLBELT_SCRIPTS_FOLDER" -mindepth 2 -maxdepth "$XXTOOLBELT_SCANNING_DEPTH" -type f -name "$script_name.*")
	if ! [ -f "$file_path" ]; then
		xxtb_log "No such script was found: $script_name" "ERROR"
		return 1
	fi 
	file_name=$(basename -- "$file_path")
	file_extension="${file_name##*.}"
	file_name="${file_name%.*}"
	file_content=$(cat "$file_path" | base64)
	file_folder=${file_path//$XXTOOLBELT_SCRIPTS_FOLDER}
	file_folder=${file_folder//$file_name.$file_extension}
	file_command=${file_name//$XXTOOLBELT_PRIVATE_KEYWORD}
	xxtb_log "To import the script use (paste in terminal or in the Import menu): \n\nXXTBIMPORT=$file_command; mkdir -r \"\$XXTOOLBELT_SCRIPTS_FOLDER$file_folder\" &>/dev/null; if [[ -f \"\$XXTOOLBELT_SCRIPTS_FOLDER$file_folder$file_name.$file_extension\" ]]; then echo \"ERROR. File already exists.\"; fi; echo \"$file_content\" | base64 --decode >> \"\$XXTOOLBELT_SCRIPTS_FOLDER$file_folder$file_name.$file_extension\"; xxtb-load;" "INFO"
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
		xxtb_log "Debug mode set to OFF" "INFO"
	else
		XXTOOLBELT_DEBUG_MODE=1
		touch "$XXTOOLBELT_DEBUG_FLAG" &> /dev/null
		xxtb_log "Debug mode set to ON" "INFO"
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
			xxtb_log "Script $XXTOOLBELT_LOADED_SCRIPTS | Command: ${bred}$filename${nc}${fgreen} | Edit: ${bwhite}xxtbedit-$filename${nc}${fgreen} | Source: ${bwhite}$file${nc}" "INFO"
			((XXTOOLBELT_LOADED_SCRIPTS+=1))
		fi
	done < <(find "$XXTOOLBELT_SCRIPTS_FOLDER" -mindepth 2 -maxdepth "$XXTOOLBELT_SCANNING_DEPTH" -type f -print0)
	xxtb_log "Total: $XXTOOLBELT_LOADED_SCRIPTS scripts." "INFO"
}
function xxtb-load () {
	# TODO: Add different color for different extensions.
	XXTOOLBELT_LOADED_SCRIPTS=0
	while IFS= read -r -d '' file; do
		filename=$(basename -- "$file")
		extension="${filename##*.}"
		filename="${filename%.*}"
		if [[ " ${XXTOOLBELT_SCRIPTS_WHITELIST[*]} " =~  ${extension}  ]]; then
			if ! [[ -x "$file" ]]; then chmod +x "$file"; fi
			filename=$(echo "$filename" | sed "s@$XXTOOLBELT_PRIVATE_KEYWORD@@")
			alias "$filename"="$file"
			alias "xxtbedit-$filename"="$XXTOOLBELT_SCRIPTS_EDITOR $file"
			if [ "$XXTOOLBELT_DEBUG_MODE" -eq 1 ]; then 
				xxtb_log "Script added: $filename(.$extension) to $file" "DEBUG"
			fi
			((XXTOOLBELT_LOADED_SCRIPTS+=1))
		fi
	done < <(find "$XXTOOLBELT_SCRIPTS_FOLDER" -mindepth 2 -maxdepth "$XXTOOLBELT_SCANNING_DEPTH" -type f -print0)
	if [ "$XXTOOLBELT_DEBUG_MODE" -eq 1 ]; then xxtb_log "Loaded $XXTOOLBELT_LOADED_SCRIPTS scripts." "DEBUG"; fi
}
xxtb-load

