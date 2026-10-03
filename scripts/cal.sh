#!/bin/bash

ALERT_IF_IN_NEXT_MINUTES=10
ALERT_POPUP_BEFORE_SECONDS=10
NERD_FONT_FREE="󱁕 "
NERD_FONT_MEETING="󰤙"

get_next_meeting() {
	next_meeting=$(icalBuddy \
		-n -ea -nc -li 1 \
		-ic "Work,nishitsuthar123@gmail.com" \
		-iep "title,datetime" \
		-po "datetime,title" \
		-b "" \
		eventsToday)
}

parse_result() {
	time=$(echo "$next_meeting" | grep -E "^[0-9]" | awk '{print $1, $2}')
	title=$(echo "$next_meeting" | grep -v "^[0-9]" | grep -v "^$" | grep -v "eventsToday" | sed 's/^[[:space:]]*//')
}

calculate_times() {
	local time_24
	time_24=$(date -j -f "%I:%M %p" "$time" +"%H:%M" 2>/dev/null)
	if [[ -z "$time_24" ]]; then
		minutes_till_meeting=999
		epoc_diff=999
		return
	fi
	epoc_meeting=$(date -j -f "%H:%M" "$time_24" +%s)
	epoc_now=$(date +%s)
	epoc_diff=$((epoc_meeting - epoc_now))
	minutes_till_meeting=$((epoc_diff/60))
}

display_popup() {
	tmux display-popup \
		-S "fg=#eba0ac" \
		-w50% \
		-h50% \
		-d '#{pane_current_path}' \
		-T meeting \
		icalBuddy \
			-n -ea -nc -li 1 \
			-ic "Work,nishitsuthar123@gmail.com" \
			-iep "title,datetime,notes,url,attendees" \
			-po "datetime,title" \
			-f \
			eventsToday
}

print_tmux_status() {
	if [[ $minutes_till_meeting -lt $ALERT_IF_IN_NEXT_MINUTES \
		&& $minutes_till_meeting -gt -60 ]]; then
		echo "$NERD_FONT_MEETING $time $title ($minutes_till_meeting minutes)"
	else
		echo "$NERD_FONT_FREE"
	fi

	if [[ $epoc_diff -gt $ALERT_POPUP_BEFORE_SECONDS && $epoc_diff -lt $((ALERT_POPUP_BEFORE_SECONDS + 10)) ]]; then
		display_popup
	fi
}

main() {
	get_next_meeting
	if [[ -z "$next_meeting" ]]; then
		echo "$NERD_FONT_FREE"
		exit 0
	fi
	parse_result
	calculate_times
	print_tmux_status
}

main
