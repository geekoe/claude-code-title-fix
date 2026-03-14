#!/bin/bash
# Claude Code Terminal Bell Fix
# 修复 OSC 序列使用 BEL(\x07) 作终止符导致终端不断出现未读标记的问题
#
# 原因：gP 函数生成所有 OSC 转义序列（标题、进度条等），使用 BEL 作终止符。
#       标题 spinner 动画不断刷新，每次都发一个 BEL，终端就显示未读标记。
# 修复：将 gP 的终止符从 BEL 改为 ST(\x1b\\)。只改这一个函数，影响最小。
#       notifyBell（真正的通知）不经过 gP，不受影响。
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

# Match the OSC terminator in gP function:
#   VAR.terminal==="kitty"?ST_VAR:BEL_VAR
# Only kitty uses ST, others use BEL. We change it to always use ST.
MATCH=$(grep -oE '[A-Za-z0-9$_]+\.terminal==="kitty"\?[A-Za-z0-9$_]+:[A-Za-z0-9$_]+' "$CLI_JS" | head -1)

if [ -z "$MATCH" ]; then
  if ! grep -q 'terminal==="kitty"' "$CLI_JS"; then
    echo "✅ Already fixed."
    exit 0
  fi
  echo "❌ Could not find the OSC terminator pattern in gP function."
  echo "   Please open an issue: https://github.com/geekoe/claude-code-title-fix/issues"
  exit 1
fi

echo "🔍 Found: $MATCH"

# Extract the ST variable (between ? and :)
ST_VAR=$(echo "$MATCH" | sed 's/.*?//' | sed 's/:.*//')
echo "🔧 Replacing with: $ST_VAR (always use ST terminator)"

COUNT=$(grep -c "$MATCH" "$CLI_JS")
if [ "$COUNT" -ne 1 ]; then
  echo "⚠️  Found ${COUNT} matches (expected 1), aborting."
  exit 1
fi

# Backup (only if no backup exists yet)
if [ ! -f "${CLI_JS}.bak" ]; then
  cp "$CLI_JS" "${CLI_JS}.bak"
fi

# Replace using python for reliability
CLI_JS_ENV="$CLI_JS" OLD_ENV="$MATCH" NEW_ENV="$ST_VAR" python3 << 'PYEOF'
import os
path = os.environ['CLI_JS_ENV']
old = os.environ['OLD_ENV']
new = os.environ['NEW_ENV']
with open(path, 'r') as f:
    content = f.read()
content = content.replace(old, new, 1)
with open(path, 'w') as f:
    f.write(content)
PYEOF

# Verify
if grep -q "$MATCH" "$CLI_JS"; then
  echo "❌ Replacement failed, restoring backup..."
  cp "${CLI_JS}.bak" "$CLI_JS"
  exit 1
else
  echo "✅ Fixed! OSC sequences now use ST instead of BEL."
  echo "   notifyBell (real notifications) is not affected."
  echo "   Restart Claude Code to take effect."
fi
