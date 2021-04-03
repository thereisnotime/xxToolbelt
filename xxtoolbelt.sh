#!/bin/bash
function xxtoolbelt-load () {
	while IFS= read -r -d '' file; do
		filename=$(basename -- "$file")
		extension="${filename##*.}"
		filename="${filename%.*}"
		if [[ " ${XXTOOLBELT_SCRIPTS_WHITELIST[*]} " =~  ${extension}  ]]; then
			if ! [[ -x "$file" ]]; then chmod +x "$file"; fi
			filename=$(echo "$filename" | sed "s@$XXTOOLBELT_PRIVATE_KEYWORD@@")
			alias "$filename"="$file"
			alias "xxedit-$filename"="$XXTOOLBELT_SCRIPTS_EDITOR $file"
			if [ "$XXTOOLBELT_DEBUG_MODE" -eq 1 ]; then echo "New alias: $filename(.$extension) to $file"; fi
		fi
	done < <(find "$XXTOOLBELT_SCRIPTS_FOLDER" -maxdepth "$XXTOOLBELT_SCANNING_DEPTH" -type f -print0)
}
xxtoolbelt-load