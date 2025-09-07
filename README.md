# CCDD v2 - Claude Code 深度开发工作流系统

> 基于深度思考模式的智能开发助手，提供结构化、安全优先的开发工作流

## 🌟 核心特性

### 💬 智能对话驱动

- **`/dd:chat`** - 基于项目上下文的 AI 智能对话
- 支持多行输入，深度分析技术问题
- 结合项目实际情况提供针对性建议
- 批判性思维，主动质疑和改进

### 🧠 深度思考模式

- 每个决策都基于多维度深度分析
- 考虑技术、业务、用户价值等多个角度
- 识别潜在风险和长期影响
- 与开发者深度讨论确认方案

### 🛡️ 安全优先设计

- AI 完全禁止 Git 写操作（add/commit/push/merge）
- 只读 Git 检查，发现问题转交用户处理
- 用户保持完全控制权，AI 只提供建议
- 敏感信息和凭证绝对安全保护

### 🎯 功能→任务开发路径

- 清晰的功能管理和任务分解
- 按实现顺序合理性进行任务规划
- 实时进度跟踪和状态同步
- 基于依赖关系的任务执行

## 📁 目录结构

```
.claude/
├── agents/                 # AI 智能体配置
│   ├── code-analyzer.md    # 代码分析智能体
│   ├── feature-designer.md # 功能设计智能体
│   ├── task-executor.md    # 任务执行智能体
│   ├── framework-architect.md # 架构设计智能体
│   └── deep-thinker.md     # 深度思考智能体
├── context/                # 项目上下文
│   ├── project.md          # 项目基础信息
│   ├── architecture.md     # 项目架构描述
│   ├── tech-stack.md       # 技术栈信息
│   ├── current-status.md   # 当前项目状态
│   └── session/            # 会话上下文
│       ├── <task-id>.md    # 任务会话记录
│       └── archive/        # 历史会话归档
├── commands/dd/            # DD 命令定义
│   ├── chat.md             # dd:chat
│   ├── help.md             # dd:help
│   ├── feature-*.md        # 功能管理命令
│   └── task-*.md           # 任务管理命令
├── rules/                  # 规则系统
│   ├── root.md             # 根规则 - 动态加载其他规则
│   ├── absolute.md         # 绝对规则 - 严格遵循
│   ├── code-style.md       # 代码风格规则
│   ├── git-rules.md        # Git 操作约束
│   └── acceptance.md       # 验收规则
├── features/               # 功能管理
│   └── <feature-name>/     # 单个功能目录
│       ├── feature.md      # 功能详细描述
│       ├── technical.md    # 技术方案
│       ├── testing.md      # 人工测试用例
│       └── tasks/          # 任务文件夹
│           ├── 001.md      # 任务文件
│           └── ...
└── scripts/dd/             # 执行脚本
    ├── help.sh             # dd:help
    ├── chat.sh             # dd:chat
    ├── feature-*.sh        # 功能管理脚本
    ├── task-*.sh           # 任务管理脚本
    └── utils/              # 工具脚本
        ├── git-check.sh    # Git状态检查
        ├── progress-calc.sh # 进度计算
        ├── deep-think.sh   # 深度思考逻辑
        └── state-sync.sh   # 状态同步
```

## 🚀 快速开始

### 1. 查看帮助信息

```bash
/dd:help
```

### 2. 智能对话咨询

```bash
/dd:chat
我想实现一个用户认证系统，需要考虑什么安全问题？
应该使用什么技术栈？
如何设计数据库表结构？
```

### 3. 完整开发流程

```bash
# 新项目
/dd:init                       # 初始化项目
/dd:prd                        # 项目需求设计
/dd:framework-init             # 框架设计
/dd:prd-decompose            # 需求拆解（大功能模块拆解）
/dd:feature-add 用户认证系统     # 添加功能
/dd:task-decompose 用户认证系统  # 任务分解
/dd:feature-start 用户认证系统   # 开始开发

# 已有项目
/dd:init-exist                 # 初始化已有项目
/dd:framework-audit            # 架构审计
/dd:feature-add 新功能名称       # 添加新功能
```

## 📋 命令参考

### 💬 智能对话

```bash
/dd:chat                    # 基于 DD 规则和上下文的 AI 智能对话
```

### 🎯 核心工作流

```bash
/dd:init                    # 初始化新项目
/dd:init-exist              # 初始化已有项目
/dd:prd                     # 项目需求设计
/dd:framework-init          # 项目框架设计
/dd:prd-decompose         # 需求拆解（大功能模块拆解）
/dd:framework-audit         # 项目架构审计
/dd:framework-adjust        # 项目架构调整
```

### 📄 功能管理

```bash
/dd:feature-add <名称>      # 创建新功能，深度分析需求
/dd:feature-start <名称>    # 开始功能开发（需已完成任务拆解）
/dd:feature-remove <名称>   # 删除功能
/dd:feature-update <名称>   # 更新功能文档
/dd:feature-status          # 查看所有功能状态和进度
```

### 📝 任务管理

```bash
/dd:task-decompose <功能>   # 深度分析功能，智能拆解任务
/dd:task-audit <功能>       # 基于功能进行任务深度审计
/dd:task-start <任务>       # 开始执行任务，深度思考实现
```

### 🔍 代码质量

```bash
/dd:code-reflect            # 基于Git变更进行代码反思分析
```

### 🔄 状态和工具

```bash
/dd:help                    # 显示帮助信息
/dd:version                 # 版本信息
/dd:status                  # 项目整体状态概览
```

## 📊 示例：用户认证系统

本项目包含了一个完整的示例功能 "用户认证系统"，展示了 CCDD v2 的完整工作流：

### 功能结构

```
.claude/features/用户认证系统/
├── feature.md              # 功能详细描述
├── technical.md            # 技术实现方案
├── testing.md              # 25个人工测试用例
└── tasks/                  # 5个任务分解
    ├── 001.md             # 用户数据模型设计和数据库配置
    ├── 002.md             # 用户注册API实现
    ├── 003.md             # 用户登录API和JWT认证
    ├── 004.md             # 密码重置功能实现
    └── 005.md             # 前端认证组件和页面实现
```

### 开发流程演示

```bash
# 1. 查看功能状态
/dd:feature-status

# 2. 开始功能开发
/dd:feature-start 用户认证系统

# 3. 执行具体任务
/dd:task-start 用户认证系统:001

# 4. 代码变更反思
/dd:code-reflect

# 5. 智能对话咨询
/dd:chat
在实现JWT认证时，如何防止Token被窃取？
应该设置多长的过期时间？
如何处理Token刷新？
```

## 🛡️ 安全保障

### Git 操作限制

- ❌ AI 绝对禁止任何 Git 写操作
- ✅ 只允许只读检查：status、diff、log、show
- 🔒 发现问题转交用户手动处理
- 👤 用户保持完全控制权

### 文件操作边界

- ✅ 允许在 `.claude/` 目录下创建和修改文件
- ✅ 允许读取项目文件进行分析
- ❌ 禁止修改源代码文件（除非明确授权）
- ❌ 禁止修改配置文件

### 敏感信息保护

- 🔐 绝对禁止处理任何凭证、密钥、密码
- 🚫 不记录或暴露敏感信息
- ⚠️ 发现敏感信息立即停止并警告

## 🎯 典型工作流程

### 新项目开发

1. `/dd:init` - 初始化项目上下文
2. `/dd:prd` - 设计项目需求
3. `/dd:framework-init` - 设计技术架构
4. `/dd:prd-decompose` - 拆解大功能模块
5. `/dd:feature-add <功能名>` - 添加具体功能
6. `/dd:task-decompose <功能名>` - 分解任务
7. `/dd:feature-start <功能名>` - 开始开发

### 已有项目

1. `/dd:init-exist` - 分析现有项目
2. `/dd:framework-audit` - 审计现有架构
3. `/dd:feature-add <新功能>` - 添加新功能
4. 后续流程同新项目

### 日常开发

1. `/dd:chat` - 遇到问题时智能咨询
2. `/dd:task-start <任务ID>` - 开始具体任务
3. `/dd:code-reflect` - 代码变更反思分析
4. `/dd:status` - 查看整体进度

## 🌟 核心价值

### ✅ 深度思考驱动

每个决策都基于多维度深度分析，考虑长远影响和技术债务

### ✅ 安全优先设计

严格的安全边界和用户控制权保护，绝不执行危险操作

### ✅ 结构化开发路径

清晰的功能→任务分解，按依赖关系有序执行

### ✅ AI 辅助质量保证

智能代码分析和改进建议，持续提升代码质量

### ✅ 灵活的多行输入

支持复杂问题的详细描述，提供针对性的深度分析

## 📚 更多资源

- 查看 `/dd:help` 获取完整命令列表
- 参考示例功能了解完整工作流
- 使用 `/dd:chat` 进行智能咨询
- 查看 `design.md` 了解系统设计理念

## 🛠️ 开发工具

### Markdown 格式化

项目根目录提供了 `format-md.sh` 脚本，用于格式化所有 Markdown 文件：

```bash
# 安装 Prettier（如果尚未安装）
npm install -g prettier

# 检查格式
./format-md.sh --check

# 格式化文件
./format-md.sh

# 显示详细信息
./format-md.sh --verbose
```

脚本会自动使用项目中的 `.prettierrc` 配置文件。

## 🚀 开始使用

```bash
# 立即开始智能对话
/dd:chat

# 或查看完整帮助
/dd:help

# 或查看项目状态
/dd:status
```

---

**CCDD v2** - 让 AI 成为你的智能开发伙伴，而不是代替你做决策的工具。
