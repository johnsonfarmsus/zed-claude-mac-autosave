# Zed Claude Autosave (macOS)

**Automatic backup system for Claude Code conversations in Zed editor on macOS.**

> **Note:** This tool is designed for macOS and uses LaunchAgent for auto-start functionality.

## The Problem

Zed's Claude Code integration (via ACP) currently doesn't support resuming past conversation threads. When you close Zed or start a new thread, your previous conversations are lost from the UI. This tool solves that by automatically backing up your conversations.

## What This Does

- Monitors Claude Code conversations in real-time
- Automatically saves conversation snapshots every 5 minutes
- Only runs when Zed is actively open (saves system resources)
- Backs up to each project's `.claude-history/` folder
- Works across ALL your projects automatically

## How It Works

Claude Code stores active conversations in `~/.claude/projects/`. This script:
1. Watches for active threads being updated
2. Detects when conversations change (using file hashing)
3. Copies them to your project folder with timestamps
4. Only backs up when Zed is running

## Quick Start

### Test It First (Recommended)

1. **Clone or download this repository**

2. **Run the script manually:**
   ```bash
   cd zed-claude-autosave
   chmod +x claude-code-autosave-v2.sh
   ./claude-code-autosave-v2.sh
   ```

3. **Use Claude Code in Zed** for a few minutes

4. **Check for backups:**
   ```bash
   ls -lh /path/to/your/project/.claude-history/
   ```

   You should see `.jsonl` files with timestamps like `thread_2025-11-25_22-25-01.jsonl`

### Permanent Setup (Auto-start on Login)

Once you've verified it works, set it up to run automatically:

#### 1. Copy script to permanent location

```bash
mkdir -p ~/.local/bin
cp claude-code-autosave-v2.sh ~/.local/bin/
chmod +x ~/.local/bin/claude-code-autosave-v2.sh
```

#### 2. Create LaunchAgent

Create file at `~/Library/LaunchAgents/com.claude.autosave.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.autosave</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/.local/bin/claude-code-autosave-v2.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/.local/log/claude-autosave.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/.local/log/claude-autosave.error.log</string>
</dict>
</plist>
```

**Replace `YOUR_USERNAME` with your actual macOS username.**

#### 3. Create log directory and load service

```bash
mkdir -p ~/.local/log
launchctl load ~/Library/LaunchAgents/com.claude.autosave.plist
```

#### 4. Verify it's running

```bash
launchctl list | grep claude
ps aux | grep claude-code-autosave
```

## Managing the Service

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.claude.autosave.plist

# Start
launchctl load ~/Library/LaunchAgents/com.claude.autosave.plist

# View logs
tail -f ~/.local/log/claude-autosave.log

# Restart (after making changes)
launchctl unload ~/Library/LaunchAgents/com.claude.autosave.plist
launchctl load ~/Library/LaunchAgents/com.claude.autosave.plist
```

## Finding Your Backups

### Automatic Backups
Backups are saved in each project's `.claude-history/` folder:

```bash
# List backups for current project
ls -lh .claude-history/

# View a backup (JSONL format)
cat .claude-history/thread_2025-11-25_22-25-01.jsonl
```

### Live Conversations (No Backup Needed)
You can also access live conversations directly from Claude's data directory:

```bash
# List all projects with Claude threads
ls ~/.claude/projects/

# View threads for a specific project
# Format: ~/.claude/projects/-Users-username-path-to-project/
ls ~/.claude/projects/-Users-YOUR_USERNAME-Documents-Projects-myproject/
```

The live `.jsonl` files are updated in real-time as you chat.

## Configuration

Edit `claude-code-autosave-v2.sh` to customize:

```bash
SAVE_INTERVAL=300  # Backup every 5 minutes
CHECK_INTERVAL=30  # Check if Zed is running every 30 seconds
```

## Git Integration

Add to your project's `.gitignore` to keep backups out of version control:

```gitignore
# Claude Code temporary files
Claude Code

# Claude conversation backups
.claude-history/
```

## File Format

Backups are saved as JSONL (JSON Lines) - one JSON object per line. Each line represents a message or event in the conversation.

## Troubleshooting

### No backups being created?

1. **Check if script is running:**
   ```bash
   ps aux | grep claude-code-autosave
   ```

2. **Check if Zed is running:**
   ```bash
   pgrep -x "zed"
   ```

3. **View logs:**
   ```bash
   tail -f ~/.local/log/claude-autosave.log
   ```

4. **Verify you have an active Claude Code thread in Zed**

### Script not starting on login?

1. **Check LaunchAgent status:**
   ```bash
   launchctl list | grep claude
   ```

2. **Verify plist syntax:**
   ```bash
   plutil ~/Library/LaunchAgents/com.claude.autosave.plist
   ```

3. **Check system logs:**
   ```bash
   log show --predicate 'process == "launchd"' --last 1h | grep claude
   ```

## How This Differs From Manual "Open Thread in Markdown"

- **Manual:** Click button → exports current snapshot → must save manually
- **This tool:** Runs automatically → saves every 5 minutes → works across all projects → no interaction needed

## Requirements

- macOS (uses LaunchAgent for auto-start)
- Zed editor with Claude Code integration
- Active Claude Pro subscription or API access

## Known Issues

- The Zed team plans to add native thread history support in the future
- Until then, this tool provides a workaround

## Contributing

Issues and pull requests welcome! This tool was created to solve a real workflow problem while waiting for native Zed support.

## License

GNU Affero General Public License v3.0 (AGPL-3.0)

See [LICENSE](LICENSE) file for details.
