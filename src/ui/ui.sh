#!/usr/bin/env bash
# ui.sh — hr, section, indent, color_box, table

if [[ -n "${__BASHLIB_UI:-}" ]]; then
	if (return 0 2>/dev/null); then
		return 0
	fi
	exit 0
fi
__BASHLIB_UI=1

# Choose drawing characters safely (ASCII fallback)
__bashlib_box_chars() {
	if __bashlib_is_utf8; then
		printf '%s\n' '┌' '┐' '└' '┘' '─' '│'
	else
		printf '%s\n' '+' '+' '+' '+' '-' '|'
	fi
}

hr() {
	local c cols
	if __bashlib_is_utf8; then c='─'; else c='-'; fi
	cols="$(__bashlib_cols)"
	__bashlib_repeat "$c" "$cols"
	printf '\n'
}

section() {
	local t="$1" s="${2:-}"
	hr
	printf '%b\n' "$(color_text "$C_BOLD" "$t")"
	[[ -n "$s" ]] && printf '%b\n' "$(color_text "$C_DIM" "$s")"
	hr
}

indent() {
	local pad="${1:-  }" text
	if [[ -t 0 ]]; then
		text="${2:-}"
		printf '%s' "$text" | sed "s/^/${pad}/"
	else
		sed "s/^/${pad}/"
	fi
}

# Pretty box with optional title and style
# Usage: color_box "Title" "content" [fg_style bg_style ...]
color_box() {
	local title="$1" content="$2"
	shift 2 || true

	# Load drawing chars into an array to avoid read/IFS pitfalls
	local chars=()
	while IFS= read -r ch; do chars+=("$ch"); done < <(__bashlib_box_chars)
	local TL="${chars[0]}" TR="${chars[1]}" BL="${chars[2]}" BR="${chars[3]}" H="${chars[4]}" V="${chars[5]}"

	local cols pad inner left right
	pad=2
	cols="$(__bashlib_cols)"
	inner=$((cols - 2 - pad * 2))
	((inner < 20)) && inner=20

	# Top border (with centered title when provided)
	if [[ -n "$title" ]]; then
		local t=" ${title} "
		local total=${#t}
		left=$(((cols - total - 2) / 2))
		right=$((cols - total - 2 - left))
		printf '%s' "$TL"
		__bashlib_repeat "$H" "$left"
		printf '%s' "$t"
		__bashlib_repeat "$H" "$right"
		printf '%s\n' "$TR"
	else
		printf '%s' "$TL"
		__bashlib_repeat "$H" "$((cols - 2))"
		printf '%s\n' "$TR"
	fi

	# Body
	while IFS= read -r line; do
		local out="$line"
		((${#out} > inner)) && out="${out:0:inner-1}…"
		printf '%s' "$V"
		__bashlib_repeat ' ' "$pad"
		if (($# > 0)); then printf '%b' "$(color_text "$@" "$out")"; else printf '%s' "$out"; fi
		# right padding to close the box
		local used=$((pad + ${#out}))
		local pad_right=$((cols - 2 - used))
		((pad_right < 0)) && pad_right=0
		__bashlib_repeat ' ' "$pad_right"
		printf '%s\n' "$V"
	done <<<"$content"

	# Bottom border
	printf '%s' "$BL"
	__bashlib_repeat "$H" "$((cols - 2))"
	printf '%s\n' "$BR"
}

# Small fixed-width table: table "hdr1;hdr2" $'row1a;row1b\nrow2a;row2b'
_table_pad() {
	local s="$1" w="$2"
	printf '%s%*s' "$s" "$((w - ${#s}))" ''
}

__bashlib_table_split_row() {
	local line="$1" sep="${2:-;}"
	__bashlib_table_row=()

	while :; do
		if [[ "$line" == *"$sep"* ]]; then
			__bashlib_table_row+=("${line%%"$sep"*}")
			line="${line#*"$sep"}"
			continue
		fi

		__bashlib_table_row+=("$line")
		break
	done
}

table() {
	local headers="$1" rows="$2" sep=";"
	local cols=() widths=() row=() cell i line

	__bashlib_table_split_row "$headers" "$sep"
	cols=("${__bashlib_table_row[@]}")

	for i in "${!cols[@]}"; do widths[i]="${#cols[i]}"; done

	if [[ -n "$rows" ]]; then
		while IFS= read -r line; do
			__bashlib_table_split_row "$line" "$sep"
			row=("${__bashlib_table_row[@]}")
			for i in "${!row[@]}"; do
				((${#row[i]} > widths[i])) && widths[i]="${#row[i]}"
			done
		done <<<"$rows"
	fi

	for i in "${!cols[@]}"; do
		printf ' %b ' "$(color_text "$C_BOLD" "$(_table_pad "${cols[i]}" "${widths[i]}")")"
	done
	printf '\n'

	if [[ -n "$rows" ]]; then
		while IFS= read -r line; do
			__bashlib_table_split_row "$line" "$sep"
			row=("${__bashlib_table_row[@]}")
			for i in "${!cols[@]}"; do
				cell="${row[i]:-}"
				printf ' %s ' "$(_table_pad "$cell" "${widths[i]}")"
			done
			printf '\n'
		done <<<"$rows"
	fi
}

title() {
	local main="$1" sub="${2:-}"
	local style="${TITLE_STYLE:-$C_BOLD$C_BLUE}"
	local decor="${TITLE_DECOR:-box}"
	local align="${TITLE_ALIGN:-center}"
	local upper="${TITLE_UPPER:-1}"
	local pad="${TITLE_PADDING:-3}"
	local icon="${TITLE_ICON:-}"
	local icon_w="${TITLE_ICON_W:-2}"
	local term_cols
	term_cols="$(__bashlib_cols)"

	[[ "$upper" == "1" ]] && main="$(__bashlib_to_upper "$main")"

	# Visible/colored content string (text only; icon printed separately)
	local text=" ${main} "
	[[ -n "$sub" ]] && text+="$(color_text "$C_DIM" "$sub")"

	case "$decor" in
	box)
		local TL TR BL BR H V
		if __bashlib_is_utf8; then
			TL='╔'
			TR='╗'
			BL='╚'
			BR='╝'
			H='═'
			V='║'
		else
			TL='+'
			TR='+'
			BL='+'
			BR='+'
			H='='
			V='|'
		fi

		# Plain (no ANSI, no icon) for width math
		local plain=" ${main} "
		[[ -n "$sub" ]] && plain+=" $sub"

		# How many columns the icon contributes, incl. a trailing space after it
		local icon_extra=0
		if [[ -n "$icon" ]]; then
			icon_extra=$((icon_w + 1))
		fi

		# Inner width based on plain text + padding + icon_extra
		local inner_width=$((${#plain} + pad * 2 + icon_extra))
		((inner_width > term_cols - 4)) && inner_width=$((term_cols - 4))
		((inner_width < 6)) && inner_width=6

		# Horizontal border
		local hline
		printf -v hline '%*s' "$inner_width" ''
		hline="${hline// /$H}"

		# Left indent for centering entire box
		local left=0
		if [[ "$align" == "center" ]]; then
			left=$(((term_cols - inner_width - 2) / 2))
			((left < 0)) && left=0
		fi

		# Top
		printf '%*s' "$left" ''
		printf '%b\n' "$(color_text "$style" "$TL$hline$TR")"

		# Middle: compute gap so the right bar aligns
		# Visible width = pad + icon_extra + ${#plain} + pad
		local visible=$((pad + icon_extra + ${#plain} + pad))
		local gap=$((inner_width - visible))
		((gap < 0)) && gap=0

		local pad_space
		printf -v pad_space '%*s' "$pad" ''
		printf '%*s' "$left" ''
		printf '%b' "$(color_text "$style" "$V")"
		printf '%s' "$pad_space"
		if [[ -n "$icon" ]]; then
			printf '%b' "$(color_text "$style" "$icon")"
			printf ' '
		fi
		printf '%b' "$(color_text "$style" "$text")"
		printf '%s' "$pad_space"
		__bashlib_repeat ' ' "$gap"
		printf '%b\n' "$(color_text "$style" "$V")"

		# Bottom
		printf '%*s' "$left" ''
		printf '%b\n' "$(color_text "$style" "$BL$hline$BR")"
		;;

	block)
		local block
		if __bashlib_is_utf8; then block='█'; else block='#'; fi
		printf '%b\n' "$(color_text "$style" "$(__bashlib_repeat "$block" "$term_cols")")"
		printf '%b\n' "$(color_text "$style" "${block}  ${icon:+$icon }${text}  ${block}")"
		printf '%b\n' "$(color_text "$style" "$(__bashlib_repeat "$block" "$term_cols")")"
		;;

	underline)
		local underline_extra=0
		if [[ -n "$icon" ]]; then underline_extra=$((icon_w + 1)); fi
		printf '%b\n' "$(color_text "$style" "${icon:+$icon }$text")"
		local underline_char
		if __bashlib_is_utf8; then underline_char='─'; else underline_char='-'; fi
		printf '%b\n' "$(color_text "$style" "$(__bashlib_repeat "$underline_char" "$((${#text} + underline_extra))")")"
		;;

	bracket | *)
		printf '%b\n' "$(color_text "$style" "[ ${icon:+$icon }$text ]")"
		;;
	esac
}
