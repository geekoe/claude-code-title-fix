# Claude Code Terminal Title Fix

[中文](#中文说明) | [English](#english)

---

## 中文说明

### 问题

Claude Code 在 v2.1.72+ 版本中存在一个 bug：终端 tab 标题不再自动更新为对话主题。

正常情况下，当你发送第一条消息后，Claude Code 会调用 Haiku 模型分析你的消息，生成一个 2-3 个词的主题作为终端标题（例如 "✳ Fix Login Bug"）。但升级后这个功能失效了，标题始终停留在 "✳ Claude Code"。

### 原因

Claude Code 的代码中有一个条件判断，用于决定是否生成标题：

```
previousMessages.length <= 1
```

这个条件要求"之前的消息数量 ≤ 1"时才触发标题生成。但由于启动时的初始化消息（系统消息等）已经让这个数组的长度达到 2 或更多，导致条件**永远不满足**，标题生成函数永远不会被调用。

### 修复方式

脚本将 `previousMessages.length <= 1` 替换为 `!autoTitle`（检查是否已经生成过自动标题）。这样只要还没生成过标题，就会尝试生成——这才是正确的逻辑。

### 使用方法

**一键修复（推荐）：**

```bash
curl -fsSL https://raw.githubusercontent.com/geekoe/claude-code-title-fix/main/fix.sh | bash
```

**或者克隆后运行：**

```bash
git clone https://github.com/geekoe/claude-code-title-fix.git
bash claude-code-title-fix/fix.sh
```

修复后**重启 Claude Code** 即可生效。

> ⚠️ 每次升级 Claude Code 后需要重新运行此脚本。

### 测试过的版本

| 版本 | 状态 |
|------|------|
| v2.1.72 | ✅ 已测试 |
| v2.1.76 | ✅ 已测试 |

### 运行不成功怎么办？

1. **提示找不到 `cli.js`**：确保 `claude` 命令在 PATH 中，或者 Claude Code 是通过 npm 全局安装的。
2. **提示找不到匹配的代码模式**：可能新版本改动了代码结构。请到 [Issues](https://github.com/geekoe/claude-code-title-fix/issues) 提交问题，附上你的 Claude Code 版本号（运行 `claude --version`）。
3. **提示已经修复过**：说明之前运行过脚本且修复仍然有效，无需操作。
4. **想恢复原始文件**：脚本会自动创建 `.bak` 备份文件，路径会在输出中显示。

---

## English

### The Bug

Claude Code v2.1.72+ has a bug where the terminal tab title no longer auto-updates to reflect the conversation topic.

Normally, after you send your first message, Claude Code calls the Haiku model to analyze it and generates a 2-3 word topic as the terminal title (e.g., "✳ Fix Login Bug"). After upgrading, this feature stopped working — the title stays as "✳ Claude Code" permanently.

### Root Cause

The code has a condition that gates title generation:

```
previousMessages.length <= 1
```

This requires the previous messages array to have ≤ 1 entry before triggering title generation. However, initialization messages (system messages, etc.) already push this array to length ≥ 2 by the time the user sends their first message. The condition **never passes**, so the title generation function is never called.

### The Fix

The script replaces `previousMessages.length <= 1` with `!autoTitle` (checking whether an auto-generated title already exists). This way, title generation is attempted as long as no title has been generated yet — which is the correct logic.

### Usage

**One-liner (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/geekoe/claude-code-title-fix/main/fix.sh | bash
```

**Or clone and run:**

```bash
git clone https://github.com/geekoe/claude-code-title-fix.git
bash claude-code-title-fix/fix.sh
```

**Restart Claude Code** after running the fix.

> ⚠️ You need to re-run this script after every Claude Code upgrade.

### Tested Versions

| Version | Status |
|---------|--------|
| v2.1.72 | ✅ Tested |
| v2.1.76 | ✅ Tested |

### Troubleshooting

1. **"Cannot find cli.js"**: Make sure the `claude` command is in your PATH, or that Claude Code was installed globally via npm.
2. **"Could not find the buggy code pattern"**: The code structure may have changed in a newer version. Please [open an issue](https://github.com/geekoe/claude-code-title-fix/issues) with your Claude Code version (`claude --version`).
3. **"Already fixed"**: The script was previously applied and the fix is still in place. No action needed.
4. **Want to restore the original file**: The script automatically creates a `.bak` backup. The path is shown in the output.
