---
last_updated: 2025-01-23T00:00:00Z
version: 1.0.0
---

# DD 系统对话记录机制

## 概述

DD 系统现在支持自动记录用户与 AI 的头脑风暴对话历史, 便于追踪决策过程和项目演进历史.

## 对话记录目录结构

```
.claude/chats/
├── init/           # 项目初始化对话
│   └── comm-YYYYMMDD-HHMMSS.md
└── feature/        # 功能设计对话
    └── feature-design-<功能名>-YYYYMMDD-HHMMSS.md
```

## 脚本调用规范

### after-init.sh 脚本

**新的调用方式**:

```bash
bash .claude/scripts/dd/after-init.sh '<json_data>'
```

**JSON 数据格式**:

```json
{
  "project_name": "项目名称",
  "project_type": "项目类型",
  "tech_stack": "技术栈",
  "architecture": "架构模式",
  "conversation": "完整的初始化头脑风暴对话内容"
}
```

### feature-add-finish.sh 脚本

**新的调用方式**:

```bash
bash .claude/scripts/dd/feature-add-finish.sh '<feature_name>' '<json_data>'
```

**JSON 数据格式**:

```json
{
  "conversation": "完整的功能设计对话内容, 包含需求分析、技术讨论、方案确认等"
}
```

## 对话文件格式

### 项目初始化对话文件

```markdown
---
type: comminicate
project_name: 项目名称
participants: [user, ai]
---

# 项目初始化头脑风暴对话

## 项目信息

- 项目基础信息
- 对话时间和类型

## 对话内容

完整的对话记录

## 对话总结

决策总结和成果

## 后续行动

下一步建议操作
```

### 功能设计对话文件

```markdown
---
type: feature_design
feature_name: 功能名称
participants: [user, ai]
---

# 功能设计对话记录

## 功能信息

- 功能基础信息
- 对话时间和类型

## 对话内容

完整的需求分析和设计讨论

## 对话成果

生成的文档和决策结果

## 后续行动

下一步开发建议
```

## 智能体调用指南

当智能体执行相关命令时, 需要:

1. **收集对话内容**: 在整个交互过程中记录用户与 AI 的完整对话
2. **格式化为 JSON**: 将对话内容和相关信息格式化为规范的 JSON 格式
3. **传递给脚本**: 在调用 after-init.sh 或 feature-add-finish.sh 时传递 JSON 数据

## 好处

- **决策可追溯**: 记录完整的决策过程和考虑因素
- **项目历史**: 保留项目演进的完整历史记录
- **知识沉淀**: 积累团队的设计思路和解决方案
- **回顾学习**: 便于后续回顾和改进工作流程

## 注意事项

- 对话记录文件使用 UTF-8 编码
- 文件名中的特殊字符会被转换为下划线
- JSON 数据中的特殊字符需要正确转义
- 如果未提供对话内容, 脚本会跳过记录步骤
