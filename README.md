# Claude Code Terminal Title Fix

[中文](#中文说明) | [English](#english)

---

## 中文说明

Claude Code v2.1.72+ 有几个终端标题相关的问题，本仓库提供独立的修复脚本。

### 问题一：标题不更新（fix.sh）

终端 tab 标题不再自动更新为对话主题，始终停留在 "✳ Claude Code"。

**原因：** 代码中的条件 `previousMessages.length <= 1` 要求之前的消息数 ≤ 1 才触发标题生成，但启动时的初始化消息已经让数组长度 ≥ 2，条件永远不满足。

**修复：** 将 `previousMessages.length <= 1` 替换为 `!autoTitle`（检查是否已生成过标题），只要没生成过就会尝试生成。

### 问题二：标题太短且是英文（fix-title-prompt.sh）

默认标题只有 2-3 个英文单词（如 "Fix Login Bug"），信息量太少，多个 tab 时难以区分。

**修复：** 将标题生成的 prompt 改为中文，生成 8-15 字的摘要（如「修复登录页面样式错乱」而不是「Fix Bug」）。可以在脚本中修改 prompt 以适配你的语言偏好。

### 问题三：Tab 不断出现未读标记（fix-bell.sh）

只要切换到其他 tab 或窗口，Claude Code 所在的 tab 就会出现未读标记（小圆点/高亮）。点掉之后很快又出现。

**原因：** Claude Code 使用 BEL 字符（`\x07`）作为所有 OSC 转义序列的终止符。OSC 序列用于设置标题、进度条等，而标题中有 spinner 动画在不断刷新。每次刷新都会发一个 BEL，终端就把它当作"需要注意"的通知，显示未读标记。（相关 issue：[#7121](https://github.com/anthropics/claude-code/issues/7121)、[#17060](https://github.com/anthropics/claude-code/issues/17060)）

**修复：** 将 OSC 终止符从 BEL（`\x07`）改为 ST（`\x1b\\`）。ST 是标准的 OSC 终止符，不会触发未读标记。真正的 bell 通知（`notifyBell`）不受影响。

### 使用方法

**一键全部修复（推荐）：**

```bash
# 修复标题不更新
curl -fsSL https://raw.githubusercontent.com/geekoe/claude-code-title-fix/main/fix.sh | bash

# 修复 tab 未读标记（推荐）
curl -fsSL https://raw.githubusercontent.com/geekoe/claude-code-title-fix/main/fix-bell.sh | bash

# 改为中文长标题（可选）
curl -fsSL https://raw.githubusercontent.com/geekoe/claude-code-title-fix/main/fix-title-prompt.sh | bash
```

**或者克隆后运行：**

```bash
git clone https://github.com/geekoe/claude-code-title-fix.git
bash claude-code-title-fix/fix.sh
bash claude-code-title-fix/fix-bell.sh
bash claude-code-title-fix/fix-title-prompt.sh  # 可选
```

修复后**重启 Claude Code** 即可生效。

> ⚠️ 每次升级 Claude Code 后需要重新运行。

### 测试过的版本

| 版本 | 状态 |
|------|------|
| v2.1.72 | ✅ 已测试 |
| v2.1.76 | ✅ 已测试 |

### 运行不成功怎么办？

1. **提示找不到 `cli.js`**：确保 `claude` 命令在 PATH 中，或者 Claude Code 是通过 npm 全局安装的。
2. **提示找不到匹配的代码模式**：可能新版本改动了代码结构。请到 [Issues](https://github.com/geekoe/claude-code-title-fix/issues) 提交问题，附上你的 Claude Code 版本号（`claude --version`）。
3. **提示已经修复过**：之前运行过且修复仍有效，无需操作。
4. **想恢复原始文件**：脚本会自动创建 `.bak` 备份，路径会在输出中显示。

---

## English

Claude Code v2.1.72+ has several terminal title issues. This repo provides independent fix scripts.

### Issue 1: Title not updating (fix.sh)

The terminal tab title no longer auto-updates to reflect the conversation topic — it stays as "✳ Claude Code" permanently.

**Root cause:** The condition `previousMessages.length <= 1` requires ≤ 1 previous messages before triggering title generation. But initialization messages already push the array to length ≥ 2, so the condition never passes.

**Fix:** Replaces `previousMessages.length <= 1` with `!autoTitle` (checks if a title has already been generated).

### Issue 2: Title too short (fix-title-prompt.sh)

The default title is only 2-3 English words (e.g., "Fix Login Bug"), which is too brief to distinguish between multiple tabs.

**Fix:** Replaces the title generation prompt to produce longer, more descriptive summaries in Chinese (8-15 characters). You can modify the prompt in the script to suit your preferred language.

### Issue 3: Tab keeps showing unread badge (fix-bell.sh)

Whenever you switch away from the Claude Code tab, it immediately shows an unread indicator (dot/highlight). Dismissing it doesn't help — it reappears within seconds.

**Root cause:** Claude Code uses the BEL character (`\x07`) as the terminator for all OSC escape sequences. OSC sequences are used for setting titles, progress bars, etc. The title has a spinner animation that constantly refreshes, sending a BEL each time. Terminals interpret BEL as an "attention needed" notification, showing an unread badge. (Related: [#7121](https://github.com/anthropics/claude-code/issues/7121), [#17060](https://github.com/anthropics/claude-code/issues/17060))

**Fix:** Changes the OSC terminator from BEL (`\x07`) to ST (`\x1b\\`). ST is the standard OSC terminator and does not trigger unread badges. The actual bell notification (`notifyBell`) is not affected.

### Usage

**One-liner (recommended):**

```bash
# Fix title not updating
curl -fsSL https://raw.githubusercontent.com/geekoe/claude-code-title-fix/main/fix.sh | bash

# Fix tab unread badge (recommended)
curl -fsSL https://raw.githubusercontent.com/geekoe/claude-code-title-fix/main/fix-bell.sh | bash

# Use longer Chinese titles (optional)
curl -fsSL https://raw.githubusercontent.com/geekoe/claude-code-title-fix/main/fix-title-prompt.sh | bash
```

**Or clone and run:**

```bash
git clone https://github.com/geekoe/claude-code-title-fix.git
bash claude-code-title-fix/fix.sh
bash claude-code-title-fix/fix-bell.sh
bash claude-code-title-fix/fix-title-prompt.sh  # optional
```

**Restart Claude Code** after running.

> ⚠️ Re-run after every Claude Code upgrade.

### Tested Versions

| Version | Status |
|---------|--------|
| v2.1.72 | ✅ Tested |
| v2.1.76 | ✅ Tested |

### Troubleshooting

1. **"Cannot find cli.js"**: Make sure the `claude` command is in your PATH, or that Claude Code was installed globally via npm.
2. **"Could not find the buggy code pattern"**: The code structure may have changed. Please [open an issue](https://github.com/geekoe/claude-code-title-fix/issues) with your Claude Code version (`claude --version`).
3. **"Already fixed/patched"**: Previously applied and still in effect. No action needed.
4. **Restore original file**: The script creates a `.bak` backup automatically. Path is shown in the output.
