# Claude Code 命令编写规则

基于 CCPM 项目分析总结的标准命令编写规则和格式规范。

## 文件结构规范

### 1. Frontmatter 结构

每个命令文件必须以 YAML frontmatter 开头：

```yaml
---
allowed-tools: Bash, Read, Write, LS, Task
---
```

**allowed-tools 规则：**
- 必须声明命令中使用的所有工具
- 常见工具：`Bash`, `Read`, `Write`, `LS`, `Task`, `Edit`, `MultiEdit`, `Grep`, `Glob`
- 顺序按使用频率或重要性排列

### 2. 命令标题和描述

```markdown
# Command Name

简洁的一句话描述命令功能。
```

**标题规则：**
- 使用英文标题（如：`# Epic Start`）
- 描述要简洁明了，一句话说明核心功能
- 避免冗长的解释，重点突出价值

## Usage 部分

### 1. Usage 格式

```markdown
## Usage
```bash
/command:subcommand <required_param> [optional_param]
```

Options:
- `--flag` - Flag description
- `--option <value>` - Option with value description
```

**Usage 规则：**
- 使用 bash 代码块
- 必需参数用 `<>` 包围
- 可选参数用 `[]` 包围
- 选项和标志单独列出说明

### 2. 参数说明

- 简洁说明每个参数的作用
- 提供具体示例
- 标明参数类型和约束

## Instructions 部分

### 1. 整体结构

```markdown
## Instructions

### 1. Section Name
### 2. Section Name  
### 3. Section Name
...
```

**结构规则：**
- 使用数字编号的三级标题
- 按执行顺序组织内容
- 每个部分功能明确，独立完整

### 2. 代码块规范

**Bash 命令：**
```markdown
```bash
# Check something
if [ condition ]; then
  echo "Success"
fi
```

**配置文件：**
```markdown
```yaml
key: value
nested:
  - item1
  - item2
```

**规则：**
- 所有代码块必须指定语言
- Bash 代码包含注释说明
- 复杂逻辑要分步骤解释

### 3. 错误处理

**格式：**
```markdown
If X fails:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible  
- Never leave partial state
```

**规则：**
- 明确说明失败条件
- 提供具体修复建议
- 避免部分状态或数据损坏

## 特殊部分规范

### 1. Quick Check 部分

```markdown
## Quick Check

1. **Check condition:**
   ```bash
   command_to_check
   ```
   If it fails: "❌ Error message with fix suggestion"

2. **Verify state:**
   - Check file exists
   - Validate format
   - Confirm prerequisites
```

**用途：**
- 快速验证前置条件
- 提供即时反馈
- 避免深入执行后发现问题

### 2. Preflight Checklist 部分

```markdown
## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress ("I'm not going to ..."). Just do them and move on.

1. **Validate input:**
   - Format checks
   - Existence verification
   - Permission validation

2. **Check dependencies:**
   - Required tools available
   - External services accessible
   - File system permissions
```

**规则：**
- 执行前必须完成的检查
- 失败时停止执行
- 不要向用户展示检查过程

### 3. Required Rules 部分

```markdown
## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/datetime.md` - For getting real current date/time
- `.claude/rules/branch-operations.md` - For git operations
```

**用途：**
- 引用项目级别的规则文件
- 确保一致性行为
- 避免重复规则说明

## 输出格式规范

### 1. 成功输出

```markdown
### X. Output

```
✅ Operation Complete

Summary:
  - Item 1: Status
  - Item 2: Status
  
Next Steps:
  /command:next - Description
  /command:other - Description
```

### 2. 错误输出

```markdown
## Error Handling

If any step fails:
```
❌ What went wrong
  Details: {error_details}
  
Fix: {specific_steps_to_resolve}
  
Try: {alternative_approach}
```

### 3. 进度输出

```markdown
```
🚀 Process Started: {name}

Status: {current_stage}

Progress:
  ├─ Step 1: ✅ Complete
  ├─ Step 2: 🔄 In Progress  
  └─ Step 3: ⏸ Waiting

Monitor with: /command:status {name}
```

## 命令类型模式

### 1. 脚本执行类

```markdown
---
allowed-tools: Bash
---

Run `bash .claude/scripts/path/script.sh $ARGUMENTS` using a sub-agent and show me the complete output.

- DO NOT truncate.
- DO NOT collapse.  
- DO NOT abbreviate.
- Show ALL lines in full.
- DO NOT print any other comments.
```

**特点：**
- 简单直接
- 执行特定脚本
- 显示完整输出

### 2. 分析处理类

```markdown
## Instructions

### 1. Read Context
- Load required files
- Parse configurations
- Understand current state

### 2. Process Data  
- Transform information
- Apply business logic
- Generate results

### 3. Output Results
- Format output
- Update files
- Provide feedback
```

**特点：**
- 多步骤处理
- 数据转换
- 状态管理

### 3. 交互式类

```markdown
### 1. Gather Input
Ask user for:
- Required parameters
- Configuration options
- Preferences

### 2. Validate Input
- Format checking
- Range validation  
- Consistency verification

### 3. Execute Action
- Process user input
- Perform operations
- Handle errors gracefully
```

**特点：**
- 用户交互
- 输入验证
- 动态执行

## 最佳实践

### 1. 命名规范

- **命令名**：使用kebab-case，如 `epic-start`
- **文件名**：与命令名一致，如 `epic-start.md`
- **参数名**：清晰描述用途，如 `<epic_name>`
- **变量名**：使用snake_case，如 `current_datetime`

### 2. 文档质量

- **简洁明确**：避免冗余说明
- **结构清晰**：逻辑顺序组织
- **示例丰富**：提供具体用例
- **错误处理完整**：覆盖异常情况

### 3. 代码质量

- **工具声明完整**：frontmatter 中列出所有使用的工具
- **命令可执行**：确保代码块中的命令可以直接运行
- **路径正确**：使用相对路径，确保可移植性
- **时间处理标准**：统一使用 ISO 8601 格式

### 4. 用户体验

- **反馈及时**：操作后立即给出状态反馈
- **错误友好**：错误信息包含修复建议
- **步骤清晰**：复杂操作分解为简单步骤
- **进度可见**：长时间操作提供进度指示

## 反模式避免

### ❌ 错误做法

1. **frontmatter 缺失工具声明**
2. **Usage 部分格式不标准**
3. **Instructions 没有数字编号**
4. **代码块没有指定语言**
5. **错误处理不完整**
6. **输出格式不一致**
7. **参数说明不清楚**

### ✅ 正确做法

1. **完整声明所有使用的工具**
2. **标准 Usage 格式，包含选项说明**
3. **Instructions 使用数字编号的三级标题**
4. **所有代码块指定语言类型**
5. **每个失败点都有处理逻辑**
6. **统一的输出格式和图标使用**
7. **清晰的参数类型和用途说明**

## 工具使用指南

### Bash 工具
- 用于执行 shell 命令
- 包含脚本运行和系统操作
- 需要处理命令失败情况

### Read/Write 工具
- Read：读取文件内容
- Write：创建或覆盖文件
- 注意文件路径和权限

### Task 工具
- 调用子智能体
- 需要指定 subagent_type
- 传递完整上下文

### LS 工具
- 列出目录内容
- 验证文件存在性
- 目录结构检查

这些规则基于对 CCPM 项目中 37+ 个命令文件的深入分析，代表了 Claude Code 命令的最佳实践和标准格式。