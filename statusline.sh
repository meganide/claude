#!/bin/bash
input=$(cat)

# Model
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# Context usage
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
USAGE=$(echo "$input" | jq '.context_window.current_usage // null')

if [ "$USAGE" != "null" ] && [ "$CONTEXT_SIZE" != "0" ]; then
    CURRENT_TOKENS=$(echo "$USAGE" | jq '(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)')
    TOKENS_K=$(awk "BEGIN {printf \"%.0f\", $CURRENT_TOKENS / 1000}")
    CONTEXT_K=$(awk "BEGIN {printf \"%.0f\", $CONTEXT_SIZE / 1000}")
    PERCENT=$(awk "BEGIN {printf \"%.0f\", ($CURRENT_TOKENS / $CONTEXT_SIZE) * 100}")
    CONTEXT_STR="${TOKENS_K}K/${CONTEXT_K}K (${PERCENT}%)"
else
    CONTEXT_STR="0K (0%)"
fi

# Cost
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST_STR=$(awk "BEGIN {printf \"$%.2f\", $COST}")

# Session time
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
DURATION_SEC=$((DURATION_MS / 1000))
HOURS=$((DURATION_SEC / 3600))
MINUTES=$(( (DURATION_SEC % 3600) / 60 ))
SECONDS=$((DURATION_SEC % 60))
if [ $HOURS -gt 0 ]; then
    TIME_STR=$(printf "%d:%02d:%02d" $HOURS $MINUTES $SECONDS)
else
    TIME_STR=$(printf "%d:%02d" $MINUTES $SECONDS)
fi

# Lines added/removed
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
LINES_STR="+${LINES_ADDED}/-${LINES_REMOVED}"

echo "$MODEL | $CONTEXT_STR | $COST_STR | $TIME_STR | $LINES_STR"
