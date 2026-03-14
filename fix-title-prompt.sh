#!/bin/bash
# Claude Code Terminal Title Prompt Fix
# 将标题生成 prompt 改为中文，且生成更详细的摘要（8-15字）
#
# 用法：bash fix-title-prompt.sh
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

OLD_PROMPT="Analyze if this message indicates a new conversation topic. If it does, extract a 2-3 word title that captures the new topic. Format your response as a JSON object with two fields: 'isNewTopic' (boolean) and 'title' (string, or null if isNewTopic is false)."

NEW_PROMPT="分析这条消息是否表示一个新的对话主题。如果是，用中文提取一个8-15字的简短摘要作为标题，要能概括用户的具体意图（例如「修复登录页面样式错乱」而不是「修复Bug」）。用JSON格式回复，包含两个字段：'isNewTopic'（布尔值）和 'title'（字符串，如果isNewTopic为false则为null）。"

# Check if already patched
if grep -q "分析这条消息是否表示一个新的对话主题" "$CLI_JS"; then
  echo "✅ Already patched, nothing to do."
  exit 0
fi

# Check original prompt exists
if ! grep -q "$OLD_PROMPT" "$CLI_JS"; then
  echo "❌ Could not find the original title prompt. Version may have changed."
  echo "   Please open an issue: https://github.com/geekoe/claude-code-title-fix/issues"
  exit 1
fi

echo "🔍 Found original prompt"
echo "🔧 Replacing with Chinese prompt (8-15 chars summary)"

# Ensure exactly 1 match
COUNT=$(grep -c "$OLD_PROMPT" "$CLI_JS")
if [ "$COUNT" -ne 1 ]; then
  echo "⚠️  Found ${COUNT} matches (expected 1), aborting."
  exit 1
fi

# Backup (only if no backup exists yet from fix.sh)
if [ ! -f "${CLI_JS}.bak" ]; then
  cp "$CLI_JS" "${CLI_JS}.bak"
fi

# Use python for reliable string replacement (avoids sed escaping issues)
python3 -c "
import sys
path = sys.argv[1]
old = sys.argv[2]
new = sys.argv[3]
with open(path, 'r') as f:
    content = f.read()
content = content.replace(old, new, 1)
with open(path, 'w') as f:
    f.write(content)
" "$CLI_JS" "$OLD_PROMPT" "$NEW_PROMPT"

# Verify
if grep -q "分析这条消息是否表示一个新的对话主题" "$CLI_JS"; then
  echo "✅ Patched! Terminal titles will now be in Chinese (8-15 chars)."
  echo "   Restart Claude Code to take effect."
else
  echo "❌ Replacement failed, restoring backup..."
  cp "${CLI_JS}.bak" "$CLI_JS"
  exit 1
fi
