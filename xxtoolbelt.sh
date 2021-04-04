#!/bin/bash
# shellcheck disable=2139
# shellcheck disable=2140
# shellcheck disable=2034
# shellcheck disable=1090
# shellcheck disable=2120
# TODO: Remove WET code.
# TODO: Add indication for private scripts when listing.
# TODO: Add option to import script module from url.
# TODO: Add option to open scripts from the menu.
# TODO: Fix placement of info log to be under the menu, not above.
# TODO: Add mechanism to prevent same naming of scripts in different languages.
# TODO: Remove eval's.
#####################################
#### Configuration
#####################################
XXTOOLBELT_SCRIPTS_FOLDER="$HOME/.xxtoolbelt/scripts"
XXTOOLBELT_VERSION="1.5"
XXTOOLBELT_SCRIPTS_EDITOR="code"
XXTOOLBELT_SCANNING_DEPTH="3"
XXTOOLBELT_DEBUG_FLAG=$(basename "$0/XXTOOLBELT_DEBUG_MODE")
XXTOOLBELT_DEBUG_MODE=$(if [[ -f  $XXTOOLBELT_DEBUG_FLAG ]]; then echo 1; else echo 0; fi)
XXTOOLBELT_PRIVATE_KEYWORD=".private"
XXTOOLBELT_SCRIPTS_WHITELIST=( "py" "sh" "erl" "hrl" "exs" "java" "rs" "ps1" "pwsh" "rb" "cpp" "c" "pl" "groovy" "d" "go" "js" "php" "r" "cs" )
XXTOOLBELT_MAIN_FILE=$(readlink -f "$0")
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
4) Export script (from file)
5) Import script
6) Reload xxToolbelt
7) Toggle DEBUG mode (dbg:$XXTOOLBELT_DEBUG_MODE)
8) Update xxToolbelt
0) Exit
*) 
${nc}
${bcyan}===============================${nc}"
}
function xxtb_back_menu () {
	tput civis
	xxtb_log "\n\n${fwhite}<--- Press ENTER to go back to the menu.${nc}" "INFO"
	read -r -s
	echo
	clear
	xxtb
}

#####################################
#### Main
#####################################
function xxtb () {
	tput cnorm
	xxtb_print_logo
	xxtb_print_menu
			echo -ne "\nYour choice: "
			read -r a
			case $a in
				1) xdg-open "$XXTOOLBELT_SCRIPTS_FOLDER" ; clear; xxtb ;;
				2) clear ; xxtb-list-scripts ; xxtb_back_menu ;;
				3) clear ; xxtb-show-command-export-menu ; xxtb ;;
				4) xxtb_log "Not yet implemented" "ERROR" ; xxtb ;;
				5) all_checks ; xxtb ;;
				6) clear ; xxtb-reload ; xxtb ;;
				7) clear ; xxtb-toggle-debug ; xxtb ;;
				8) xxtb-update ;;
			0) return 0 ;;
			*) clear; xxtb_log "No such option." "ERROR"; xxtb
			esac
}
function xxtb-reload () {
	if [[ "$1" != "silent" ]]; then xxtb_log "Reloading main script from $XXTOOLBELT_MAIN_FILE" "INFO"; fi
	source "$XXTOOLBELT_MAIN_FILE"
}
function xxtb-show-import-script-menu () {
	echo -ne "\nEnter command: "
	read -r EXPORTED
	eval "$EXPORTED"

}
function xxtb-update () {
	update_url="https://raw.githubusercontent.com/thereisnotime/xxToolbelt/main/xxtoolbelt.sh"
	if [ -x "$(command -v curl)" ]; then
		curl "$update_url" -O "$XXTOOLBELT_SCRIPTS_FOLDER/../"
	else
		if [ -x "$(command -v wget)" ]; then
			wget "$update_url" -O "$XXTOOLBELT_SCRIPTS_FOLDER/../xxtoolbelt.sh"
		else
			xxtb_log "You need curl or wget for this." "ERROR"
			return 1
		fi
	fi
	clear
	xxtb-reload
	xtb
}
function xxtb-show-command-export-menu () {
	# TODO: Fine tune the find command.
	xxtb-list-scripts
	echo -ne "\nEnter command of the script: "
	read -r SCRIPTNAME
	# TODO: Check if exists.
	# TODO: Improve file/folder management.
	file_path=$(find "$XXTOOLBELT_SCRIPTS_FOLDER" -mindepth 2 -maxdepth "$XXTOOLBELT_SCANNING_DEPTH" -type f -name "$SCRIPTNAME.*")
	if ! [ -f "$file_path" ]; then
		xxtb_log "No such script was found." "ERROR"
		xxtb_back_menu
	fi 
	clear
	file_name=$(basename -- "$file_path")
	file_extension="${file_name##*.}"
	file_name="${file_name%.*}"
	file_content=$(cat "$file_path" | base64)
	file_folder=${file_path//$XXTOOLBELT_SCRIPTS_FOLDER}
	file_folder=${file_folder//$file_name.$file_extension}
	file_command=${file_name//$XXTOOLBELT_PRIVATE_KEYWORD}
	xxtb_log "To import the script use: \n\nmkdir -r \"\$XXTOOLBELT_SCRIPTS_FOLDER$file_folder\" &>/dev/null; echo \"$file_content\" | base64 --decode >> \"\$XXTOOLBELT_SCRIPTS_FOLDER$file_folder$file_name.$file_extension\"; xxtb-load;" "INFO"
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