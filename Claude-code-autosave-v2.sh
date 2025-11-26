#!/bin/bash
# Auto-save Claude Code threads by monitoring the actual Claude data directory
# This script monitors ~/.claude/projects/ for real-time conversation updates

SAVE_INTERVAL=300  # Save every 5 minutes (300 seconds)
CHECK_INTERVAL=30  # Check if Zed is running every 30 seconds
CLAUDE_PROJECTS_DIR="$HOME/.claude/projects"

echo "Starting Claude Code auto-save daemon (v2 - monitoring live data)..."
echo "Will save threads every $SAVE_INTERVAL seconds when Zed is running"

while true; do
    # Check if Zed is running
    if pgrep -x "zed" > /dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Zed is running, checking for active threads..."

        # Find all project directories
        find "$CLAUDE_PROJECTS_DIR" -maxdepth 1 -type d -name "-Users-*" 2>/dev/null | while read -r project_dir; do
            # Extract the actual project path from the directory name
            # Format: -Users-trevorjohnson-Documents-Projects-tetris -> /Users/trevorjohnson/Documents/Projects/tetris
            project_path=$(echo "$project_dir" | sed 's|.*/||' | sed 's/-/\//g')

            # Skip if project path doesn't exist
            [ ! -d "$project_path" ] && continue

            # Find the most recently modified .jsonl file in this project
            latest_thread=$(find "$project_dir" -name "*.jsonl" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1)

            [ -z "$latest_thread" ] && continue

            # Check if file was modified recently (within last hour - indicates active thread)
            if [ -n "$(find "$latest_thread" -mmin -60 2>/dev/null)" ]; then
                # Create .claude-history directory in the project
                history_dir="$project_path/.claude-history"
                mkdir -p "$history_dir"

                # Generate timestamp
                timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

                # Calculate hash to avoid duplicate saves
                if command -v md5 &> /dev/null; then
                    current_hash=$(md5 -q "$latest_thread")
                else
                    current_hash=$(md5sum "$latest_thread" | cut -d' ' -f1)
                fi

                hash_file="$history_dir/.last_hash"

                # Check if file has changed since last save
                if [ ! -f "$hash_file" ] || [ "$(cat "$hash_file")" != "$current_hash" ]; then
                    # Convert JSONL to readable markdown format
                    output_file="$history_dir/thread_${timestamp}.jsonl"
                    cp "$latest_thread" "$output_file"
                    echo "$current_hash" > "$hash_file"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Saved thread to $output_file"
                    echo "   Project: $project_path"
                fi
            fi
        done

        sleep "$SAVE_INTERVAL"
    else
        # Zed not running, check again in shorter interval
        sleep "$CHECK_INTERVAL"
    fi
done
