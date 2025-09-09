# DD 工作流系统配置

> 仔细思考并实现最简洁的解决方案, 尽可能少地更改代码.

## ⚠️ 绝对规则 - 最高优先级

**必须首先阅读并严格遵守: `.claude/rules/absolute.md`**

这些规则绝不可违反, 包括:

- Git 操作绝对禁令
- 文件操作边界限制
- 敏感信息处理规范
- 代码质量铁律
- 用户控制原则

## 智能上下文系统

### 绝对遵循的规则

- **absolute.md**: 最高优先级的绝对规则, 任何时候都不可违反
- **root.md**: 根级规则, 覆盖系统核心行为和安全边界

### 自动上下文注入

系统会智能匹配并自动注入以下上下文:

- **项目上下文**: `.claude/context/*` - 项目状态、架构、进度等
- **功能上下文**: 当前操作相关的功能和任务信息
- **会话上下文**: 历史对话和决策记录

**注意**: 这些上下文会根据当前操作自动加载, 无需手动指定.

## 基于智能体的架构

系统使用专门的子智能体进行上下文优化:

- **chat-assistant**: 基于持久上下文的对话
- **code-analyzer**: 深度代码分析、逻辑跟踪、漏洞检测
- **feature-designer**: 功能需求分析和设计方案制定
- **task-executor**: 任务执行和进度跟踪管理
- **framework-architect**: 系统架构设计和技术选型
- **deep-thinker**: 深度思考和决策分析
- **claude-md-merger**: 智能合并 CLAUDE.md 配置文件

## 智能体使用要求

- **项目上下文**: `/dd:chat` 自动调用 chat-assistant
- **代码分析**: 使用 Task 工具调用 code-analyzer
- **功能设计**: 使用 Task 工具调用 feature-designer
- **任务执行**: 使用 Task 工具调用 task-executor
- **架构设计**: 使用 Task 工具调用 framework-architect
- **深度思考**: 使用 Task 工具调用 deep-thinker
- **配置合并**: init 完成后使用 Task 工具调用 claude-md-merger

## 工作行为规范

- 保持简洁直接, 避免冗长解释
- 按要求执行任务, 不多不少
- 优先编辑现有文件而不是创建新文件
- 永远不要主动创建文档文件
- 欢迎批评, 保持怀疑态度
- 不要奉承或过度解释, 除非用户要求

## DD 命令系统

所有工作流命令使用 `/dd:` 前缀, 共 21 个命令:

**智能对话类**: `/dd:chat`
**帮助状态类**: `/dd:help` `/dd:status` `/dd:version`
**项目初始化类**: `/dd:init` `/dd:prd`
**架构管理类**: `/dd:framework-init` `/dd:framework-audit` `/dd:framework-adjust` `/dd:prd-decompose`
**功能管理类**: `/dd:feature-add` `/dd:feature-decompose` `/dd:feature-start` `/dd:feature-update` `/dd:feature-status` `/dd:feature-refactory` `/dd:feature-remove`
**任务管理类**: `/dd:task-start` `/dd:task-update` `/dd:task-audit`
**代码质量类**: `/dd:code-reflect`

### 典型工作流程

```bash
/dd:init                      # 项目初始化 (支持 --analyze 参数)
/dd:prd                      # 需求设计
/dd:framework-init           # 架构设计
/dd:feature-add 用户认证      # 添加功能
/dd:feature-decompose 用户认证 # 功能分解
/dd:feature-start 用户认证    # 开始开发
/dd:code-reflect            # 代码反思
/dd:chat                    # 技术咨询
```

## 工作流文件组织

```
.claude/
├── commands/dd/     # DD 工作流命令
├── agents/          # AI 智能体配置
├── rules/           # 安全和操作规则
├── context/         # 项目上下文和状态
├── chats/           # 对话历史记录
├── features/        # 功能定义和任务
└── scripts/         # 实用工具脚本
```

## 配置管理

系统使用 YAML 元数据配置工具限制, 规则层次从绝对安全要求到行为指导.
