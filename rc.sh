# START xxToolbelt
XXTOOLBELT_SCRIPTS_FOLDER="$HOME/.scripts/"
XXTOOLBELT_SCRIPTS_EDITOR="code"
XXTOOLBELT_SCANNING_DEPTH="2"
XXTOOLBELT_SCRIPTS_WHITELIST=( "py" "sh" "java" "rs" "ps1" "pwsh" "rb" "cpp" "c" "pl" "groovy" "d" "go" "js" "php" "r" "cs" )
function xxtoolbelt-load () {
	while IFS= read -r -d '' file; do
		filename=$(basename -- "$file")
		extension="${filename##*.}"
		filename="${filename%.*}"
		if [[ " ${XXTOOLBELT_SCRIPTS_WHITELIST[@]} " =~ " ${extension} " ]]; then
			if ! [[ -x "$file" ]]; then chmod +x "$file"; fi
			alias "$filename"="$file"
			alias "xxedit-$filename"="$XXTOOLBELT_SCRIPTS_EDITOR $file"
		fi
	done < <(find "$XXTOOLBELT_SCRIPTS_FOLDER" -maxdepth "$XXTOOLBELT_SCANNING_DEPTH" -type f -print0)
}
xxtoolbelt-load
# END xxToolbelt