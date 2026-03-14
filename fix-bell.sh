#!/bin/bash
# Claude Code Terminal Bell Fix
# 修复 OSC 序列使用 BEL(\x07) 作终止符导致终端不断出现未读标记的问题
# 改为使用 ST(\x1b\\) 作为 OSC 终止符，notifyBell 不受影响
#
# 用法：bash fix-bell.sh
#       升级 Claude Code 后需重新运行
# https://github.com/geekoe/claude-code-title-fix

set -e

# Locate cli.js
if command -v claude &>/dev/null; then
  CLI_JS="$(dirname "$(realpath "$(which claude)")")/cli.js"
elif [ -f "$(npm root -g)/@anthropic-ai/claude-code/cli.js" ]; then
  CLI_JS="$(npm root -g)/@anthropic-ai/claude-code/cli.js"
else
  echo "❌ Cannot find Claude Code cli.js."
  exit 1
fi

if [ ! -f "$CLI_JS" ]; then
  echo "❌ cli.js not found: $CLI_JS"
  exit 1
fi

echo "📄 cli.js: $CLI_JS"

# Count how many BEL variables exist
BEL_COUNT=$(grep -cE '[A-Za-z0-9$_]+="\\x07"' "$CLI_JS" || true)

if [ "$BEL_COUNT" -eq 0 ]; then
  echo "✅ Already fixed or no BEL variables found."
  exit 0
fi

echo "🔍 Found $BEL_COUNT BEL (\\x07) variable assignments"

# Find the notifyBell variable: useCallback(()=>{A(VAR)},[A])
# where VAR is one of the BEL variables
BELL_VAR=$(grep -oE 'useCallback\(\(\)=>\{[A-Za-z0-9$_]+\([A-Za-z0-9$_]+\)' "$CLI_JS" | grep -oE '\([A-Za-z0-9$_]+\)$' | tr -d '()' | while read var; do
  if grep -q "${var}=\"\\\\x07\"" "$CLI_JS"; then
    echo "$var"
  fi
done | head -1)

if [ -z "$BELL_VAR" ]; then
  echo "⚠️  Could not identify notifyBell variable, will replace all BEL vars"
  BELL_VAR="__NONE__"
else
  echo "🔔 notifyBell uses variable: $BELL_VAR (will keep it working)"
fi

# Backup (only if no backup exists yet)
if [ ! -f "${CLI_JS}.bak" ]; then
  cp "$CLI_JS" "${CLI_JS}.bak"
fi

# Use python for reliable replacement
CLI_JS_ENV="$CLI_JS" BELL_VAR_ENV="$BELL_VAR" python3 << 'PYEOF'
import os, sys

CLI_JS = os.environ['CLI_JS_ENV']
BELL_VAR = os.environ['BELL_VAR_ENV']

with open(CLI_JS, 'r') as f:
    content = f.read()

# In the JS source file, \x07 appears as literal text: backslash x 0 7
OLD = r'="\x07"'
NEW = r'="\x1b\\"'

count = content.count(OLD)
print(f'   Found {count} literal \\x07 assignments')

if count == 0:
    print('   Nothing to replace')
    sys.exit(0)

content = content.replace(OLD, NEW)

# Fix notifyBell to hardcode \x07 so real bell notifications still work
# Pattern: (()=>{A(BELL_VAR)}, where BELL_VAR is now pointing to ST
if BELL_VAR != '__NONE__':
    search = f'(()=>{{A({BELL_VAR})}}'
    if search in content:
        replace = r'(()=>{A("\x07")}'
        content = content.replace(search, replace, 1)
        print(f'   Fixed notifyBell to hardcode \\x07')
    else:
        print(f'   Warning: could not find notifyBell callback')

with open(CLI_JS, 'w') as f:
    f.write(content)

remaining = content.count(OLD)
print(f'   Remaining \\x07 assignments: {remaining}')
PYEOF

# Final check
REMAINING=$(grep -cE '[A-Za-z0-9$_]+="\\x07"' "$CLI_JS" || true)
if [ "$REMAINING" -eq 0 ]; then
  echo "✅ Fixed! All BEL terminators replaced with ST."
  echo "   notifyBell still sends real BEL for notifications."
  echo "   Restart Claude Code to take effect."
else
  echo "⚠️  $REMAINING BEL assignments remain (started with $BEL_COUNT)"
fi
