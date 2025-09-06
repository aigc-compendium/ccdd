---
allowed-tools: Bash
---

Run `bash .claude/scripts/dd/help.sh` using a sub-agent and show me the complete output.

- DO NOT truncate.
- DO NOT collapse.
- DO NOT abbreviate.
- Show ALL lines in full.
- DO NOT print any other comments.

## DD 典型工作流程

### 手动执行流程
```bash
# 完整手动开发流程
/dd:ctx-init                    # 1. 初始化项目上下文
/dd:prd-new 用户认证系统         # 2. 创建需求文档
/dd:prd-parse 用户认证系统       # 3. 转换为技术方案
/dd:epic-decompose 用户认证系统  # 4. 分解为具体任务
/dd:task-list --assignable      # 5. 查看可执行任务
/dd:task-start 用户认证系统:001  # 6. 开始执行任务
/dd:task-finish 用户认证系统:001 # 7. 完成任务
/dd:code-reflect                # 8. 反思和检查
/dd:ctx-sync                    # 9. 同步上下文
```

### 自动执行流程（推荐）
```bash
# AI自动完整执行流程
/dd:ctx-init                    # 1. 初始化项目上下文
/dd:prd-new 用户认证系统         # 2. 创建需求文档
/dd:prd-parse 用户认证系统       # 3. 转换为技术方案
/dd:epic-decompose 用户认证系统  # 4. 分解为具体任务
/dd:prd-auto-exec 用户认证系统   # 5. AI自动执行所有任务
/dd:code-reflect                # 6. 反思和检查
/dd:ctx-sync                    # 7. 同步上下文
```