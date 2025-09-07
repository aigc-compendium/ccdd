# CCDD v2

> Claude Code 工作流工具 - 深度思考模式下的智能开发助手

## .claude 目录结构

```
.claude/
├── agents/                 # AI 智能体配置
│   ├── code-analyzer.md   # 代码分析智能体
│   ├── feature-designer.md # 功能设计智能体
│   ├── task-executor.md   # 任务执行智能体
│   ├── framework-architect.md # 架构设计智能体
│   └── deep-thinker.md    # 深度思考智能体
├── context/               # 项目上下文
│   ├── project.md         # 项目基础信息
│   ├── architecture.md    # 项目架构描述
│   ├── tech-stack.md      # 技术栈信息
│   ├── current-status.md  # 当前项目状态
│   └── session/           # 会话上下文
│       ├── <task-id>.md   # 任务会话记录
│       └── archive/       # 历史会话归档
│           └── <task-id>-<timestamp>.md
├── commands/dd/           # DD 命令定义
│   ├── chat.md            # dd:chat
│   ├── init.md            # dd:init
│   ├── init-exist.md      # dd:init-exist
│   ├── prd.md             # dd:prd
│   ├── prd-decompose.md   # dd:prd-decompose
│   ├── framework-init.md  # dd:framework-init
│   ├── framework-audit.md # dd:framework-audit
│   ├── framework-adjust.md # dd:framework-adjust
│   ├── help.md            # dd:help
│   ├── version.md         # dd:version
│   ├── status.md          # dd:status
│   ├── feature-add.md     # dd:feature-add
│   ├── feature-start.md   # dd:feature-start
│   ├── feature-list.md    # dd:feature-list
│   ├── feature-remove.md  # dd:feature-remove
│   ├── feature-refactory.md # dd:feature-refactory
│   ├── feature-status.md  # dd:feature-status
│   ├── task-decompose.md  # dd:task-decompose
│   ├── task-audit.md      # dd:task-audit
│   ├── task-start.md      # dd:task-start
│   └── code-reflect.md    # dd:code-reflect
├── rules/                 # 规则系统
│   ├── root.md           # 根规则 - 动态加载其他规则
│   ├── absolute.md       # 绝对规则 - 严格遵循
│   ├── code-style.md     # 代码风格规则
│   ├── git-rules.md      # Git 操作约束
│   └── acceptance.md     # 验收规则 - 功能和任务验收标准
├── features/              # 功能管理
│   └── <feature-name>/   # 单个功能目录
│       ├── feature.md    # 功能详细描述
│       ├── technical.md  # 技术方案
│       ├── testing.md    # 人工测试用例
│       └── tasks/        # 任务文件夹
│           ├── 001.md    # 任务文件
│           ├── 002.md
│           └── ...
├── CLAUDE.md             # 项目配置文件
└── scripts/dd/            # 执行脚本
    ├── init.sh            # dd:init
    ├── init-exist.sh      # dd:init-exist
    ├── after-init.sh      # 初始化后处理
    ├── prd.sh             # dd:prd
    ├── framework-init.sh  # dd:framework-init
    ├── framework-audit.sh # dd:framework-audit
    ├── framework-adjust.sh # dd:framework-adjust
    ├── help.sh            # dd:help
    ├── version.sh         # dd:version
    ├── status.sh          # dd:status
    ├── feature-add.sh     # dd:feature-add
    ├── feature-start.sh   # dd:feature-start
    ├── feature-remove.sh  # dd:feature-remove
    ├── feature-update.sh  # dd:feature-update
    ├── feature-status.sh  # dd:feature-status
    ├── task-decompose.sh  # dd:task-decompose
    ├── task-audit.sh      # dd:task-audit
    ├── task-start.sh      # dd:task-start
    ├── code-reflect.sh    # dd:code-reflect
    └── utils/             # 工具脚本
        ├── git-check.sh   # Git状态检查
        ├── progress-calc.sh # 进度计算
        ├── state-sync.sh  # 状态同步
        └── deep-think.sh  # 深度思考逻辑
```

## 命令系统

> 命令前缀: `dd:`

### 智能对话命令

- `dd:chat`: 智能对话系统
  - 支持多行输入的深度对话
  - 基于项目上下文的智能分析
  - 结合DD规则和深度思考模式
  - 技术咨询、方案设计、问题诊断

### 项目级命令

- `dd:init`: 初始化空项目
  - 深度思考模式：头脑风暴分析项目可行性
  - AI 提出质疑和改进建议
  - 与开发者深度讨论确认方向
  - 完成后执行 after-init.sh 脚本

- `dd:init-exist`: 初始化已有项目
  - 深度分析现有代码架构
  - AI 需求分析和架构评估
  - 提出质疑和优化建议
  - 与开发者讨论改进方案
  - 完成后执行 after-init.sh 脚本

- `dd:prd`: 项目需求设计
  - 生成项目整体需求文档
  - 深度分析用户需求和技术可行性

- `dd:framework-init`: 项目框架设计
  - 生成架构设计文档
  - 深度思考技术选型和架构模式
  - 完成后提示执行 `dd:prd-decompose`

- `dd:prd-decompose`: 需求拆解
  - 基于PRD和架构设计拆解大功能模块
  - 分析功能依赖关系和开发优先级
  - 为新项目规划核心功能列表
  - 完成后提示执行第一个 `dd:feature-add`

- `dd:framework-audit`: 项目架构审计
  - 深度分析现有架构合理性
  - 识别架构缺陷和改进点

- `dd:framework-adjust`: 项目架构调整
  - 基于审计结果调整架构
  - 深度思考调整的影响和风险

- `dd:help`: 帮助信息
- `dd:version`: 版本信息
- `dd:status`: 项目整体状态概览

### 功能级命令

- `dd:feature-add`: 新增功能
  - 深度分析功能需求和技术实现
  - 生成完整的功能文档集合
  - AI 质疑功能必要性和设计合理性
  - 完成后提示执行 `dd:task-decompose`

- `dd:feature-start <feature>`: 智能判断功能状态，开始或继续功能开发
  - **前置条件**：功能必须已完成任务拆解
  - **状态检测**：检查功能当前状态
    - 未开始 → 可以开始
    - 开发中 → 继续开发
    - 测试中 → 转为开发状态
    - 已完成 → 询问是否重新开发
  - **Git 状态检查**：
    - 检查本地未提交文件 → 有则报错停止
    - 自动 fetch 检查远程变更 → 有则转交用户手动处理
    - 检查代码状态与功能状态一致性 → 不匹配则更新状态
  - **执行**：调用任务级命令执行具体任务

- `dd:feature-list`: 显示所有功能列表和状态概览
- `dd:feature-remove`: 删除功能
- `dd:feature-refactory`: 基于用户需求重构功能，重新生成功能文档
- `dd:feature-status`: 查看功能状态和进度

### 任务级命令

- `dd:task-decompose <feature>`: 功能任务拆解
  - 深度分析功能技术实现路径
  - 按实现顺序合理性进行任务规划
  - 自动分解任务，疑惑时与开发者确认
  - 生成任务 todo 列表
  - 完成后提示执行 `dd:feature-start`

- `dd:task-audit <feature>`: 任务审计
  - 基于关联功能进行深度审计
  - 生成任务改造方案
  - 重新编排任务执行顺序

- `dd:task-start <task>`: 智能判断任务状态，开始、继续或恢复任务执行
  - 自动检测任务当前状态（未开始/进行中/已完成/已暂停）
  - 智能恢复任务执行上下文和进度
  - 深度思考任务实现方案并实时同步状态

### 代码质量命令

- `dd:code-reflect`: 代码变更反思
  - 基于 Git 未提交的文件变动进行反思
  - 深度分析代码变更的合理性和质量
  - AI 代码审查和改进建议
  - 评估变更对系统的影响

## 数据结构设计

### 功能文档结构

#### feature.md - 功能详细描述

```yaml
---
name: 功能名称
status: 未开始|开发中|测试中|已完成
progress: 0-100
tasks_total: 总任务数
tasks_completed: 已完成任务数
---
# 功能描述

## 功能目标

## 用户价值

## 核心功能点

## 功能边界
```

#### technical.md - 技术方案

```yaml
---
complexity: 简单|中等|复杂
estimated_hours: 预估工作量
tech_stack: [技术栈]
dependencies: [依赖功能]
---
# 技术实现方案

## 技术选型

## 架构设计

## 数据模型

## API 设计

## 关键技术点
```

#### testing.md - 人工测试用例

```yaml
---
test_type: 人工测试
test_cases_count: 测试用例数量
---
# 人工测试用例

## 功能测试

## 边界测试

## 异常测试

## 用户体验测试
```

#### tasks/xxx.md - 任务文件

```yaml
---
name: 任务名称
feature: 所属功能
status: 未开始|进行中|已完成
progress: 0-100
priority: 高|中|低
difficulty: 简单|中等|复杂
estimated_hours: 预估时间
dependencies: [依赖任务]
---

# 任务描述

## 任务目标

## 实现要点

## 验收标准

## 技术细节

## Todo 列表
- [ ] 具体实现项1
- [ ] 具体实现项2
- [ ] ...
```

## 规则系统

### root.md - 根规则

```
- 永远存在于上下文中
- 动态关联和加载其他规则文件
- 智能体根据当前任务类型查询使用对应规则
- 深度思考模式：所有决策都需要深入分析
```

### absolute.md - 绝对规则

```
- 通过 CLAUDE.md 永远存在于上下文中
- Claude Code 系统自动加载此规则
- 严格遵循，不可违反
- 深度思考：每个操作前都要深度分析影响
- 所有AI智能体都必须遵循此规则
```

### acceptance.md - 验收规则

```
## 功能验收标准
- 所有任务状态为"已完成"
- 功能进度达到100%
- 通过所有人工测试用例
- 代码质量符合项目标准

## 功能验收流程
1. 自动检查任务完成状态
2. 执行人工测试用例
3. 代码质量审查
4. 功能演示和确认

## 任务验收标准
- Todo 列表全部完成
- 任务进度达到100%
- 符合任务验收标准
- 代码变更已提交

## 任务验收流程
1. 检查 Todo 列表完成状态
2. 验证任务目标达成
3. 代码审查和测试
4. 更新任务状态
```

### git-rules.md - Git 操作约束

```
## AI 操作限制
- AI 不执行任何 Git 写操作
- 只能执行只读 Git 命令（status, diff, log等）
- Git 问题发现后转交用户手动处理

## 状态检查规则
- 开始功能前检查未提交文件
- 自动 fetch 检查远程更新
- 代码状态与功能状态一致性检查
```

### code-style.md - 代码风格规则

```
## 代码质量标准
- 遵循项目既定编码规范
- 适当的错误处理
- 清晰的变量和函数命名
- 必要的代码注释

## 深度思考要求
- 每次代码变更都要深度分析影响
- 考虑代码可维护性和扩展性
- 评估性能和安全性影响
```

## 状态管理

### 功能状态流转

```
未开始 → 开发中 → 测试中 → 已完成
         ↑_________|
```

### 任务状态流转

```
未开始 → 进行中 → 已完成
```

### 进度计算

```
功能进度 = 已完成任务数 / 总任务数 * 100%
任务进度 = 已完成Todo数 / 总Todo数 * 100%
```

## 工作流程

### 深度思考模式

- 所有命令执行前进行深度分析
- AI 主动提出质疑和改进建议
- 与开发者深度讨论确认方案
- 考虑长远影响和技术债务

### 标准开发流程

```
1. dd:init 或 dd:init-exist        # 项目初始化
2. dd:prd                          # 需求设计
3. dd:framework-init               # 架构设计
4. dd:prd-decompose              # 需求拆解（大功能模块拆解）
5. dd:feature-add <功能名>          # 添加具体功能
6. dd:task-decompose <feature>     # 任务拆解
7. dd:feature-start <feature>      # 开始开发
8. dd:code-reflect                # 代码变更反思
9. dd:feature-status              # 查看进度
10. 重复5-9直到功能完成
11. dd:framework-audit            # 架构审计
```

## 初始化后处理流程

### after-init.sh 脚本功能

两个 init 命令（dd:init 和 dd:init-exist）完成用户讨论后，都会执行 after-init.sh 脚本：

1. **更新项目上下文文件**
   - 根据用户需求和讨论结果更新 context/project.md
   - 更新 context/architecture.md 架构信息
   - 更新 context/tech-stack.md 技术栈选择
   - 更新 context/current-status.md 当前状态

2. **清理模板功能目录**
   - 删除 .claude/features/ 下的模板示例功能
   - 为用户实际功能开发准备干净环境

3. **CLAUDE.md 文件处理**
   - .claude/ 目录下必须有一个 CLAUDE.md 配置文件
   - 若项目根目录没有 CLAUDE.md，则直接复制到根目录
   - 若根目录已有 CLAUDE.md，则使用智能体智能合并两个文件
   - 确保绝对规则通过 CLAUDE.md 永久存在于上下文中

## CLAUDE.md 配置管理

### 文件位置和作用

- **源文件**: .claude/CLAUDE.md（DD系统配置）
- **目标文件**: 项目根目录 CLAUDE.md（Claude Code加载）
- **作用**: 确保绝对规则和DD规则永久存在于Claude Code上下文中

### 智能合并策略

当根目录已存在 CLAUDE.md 时，智能体执行合并：

1. **分析现有文件** - 理解现有配置的意图和结构
2. **识别冲突项** - 找出可能冲突的配置项
3. **智能合并** - 保留用户配置，集成DD系统必需规则
4. **验证完整性** - 确保合并后配置的有效性

### 绝对规则永久化

通过 CLAUDE.md 文件确保以下规则永久存在：

- Git 操作绝对禁令
- 文件操作边界限制
- 敏感信息处理规范
- 代码质量铁律
- 深度思考要求

## dd:chat 命令详细设计

### 多行输入支持

```
/dd:chat
我想实现一个用户认证系统
需要支持邮箱登录和手机号登录
还要考虑密码安全和会话管理
应该使用什么技术架构？
有哪些安全风险需要注意？
```

### 深度分析流程

1. **加载项目上下文** - 读取 context/ 下的所有相关文件
2. **多维度分析** - 技术、业务、用户、安全等角度分析
3. **智能体协作** - 调用专门智能体进行深度分析
4. **交互式讨论** - 与用户进行多轮深度对话
5. **方案推荐** - 提供具体可行的实施建议

### 上下文感知能力

- **项目状态感知** - 了解当前开发状态和技术选型
- **历史对话关联** - 关联之前的讨论和决策
- **功能依赖分析** - 理解功能间的依赖关系
- **进度影响评估** - 评估对整体进度的影响

## dd:code-reflect 命令设计

### Git变更分析

```bash
# 检测未提交的文件变更
git diff --name-only
git diff --staged --name-only

# 分析变更内容
git diff HEAD
git diff --staged
```

### 智能反思维度

1. **变更合理性** - 代码变更是否符合任务目标
2. **代码质量** - 是否遵循编码规范和最佳实践
3. **架构影响** - 对系统架构的影响评估
4. **安全考虑** - 变更是否引入安全风险
5. **性能影响** - 对系统性能的潜在影响
6. **测试覆盖** - 是否需要更新相关测试

### 输出格式

```markdown
🔍 代码变更反思分析

📊 变更概览：
修改文件：5个
新增行数：+120
删除行数：-45

🎯 变更目标匹配度：✅ 高度匹配
当前变更完全符合任务目标要求

⭐ 代码质量评估：⚠️ 需要改进
发现的问题：
• user.controller.js:45 - 缺少错误处理
• auth.service.js:89 - 建议提取常量

🏗️ 架构影响分析：✅ 影响可控
变更遵循现有架构模式，无破坏性影响

🔒 安全评估：✅ 安全合规
所有变更符合安全最佳实践

💡 改进建议：

1. 添加错误处理机制
2. 提取魔法数字为常量
3. 增加单元测试覆盖

🎯 下一步建议：
• 修复发现的代码质量问题
• 运行测试套件验证
• 考虑提交变更
```

## 详细目录说明

### agents/ - AI 智能体配置

- **code-analyzer.md** - 代码分析和质量审查智能体
- **feature-designer.md** - 功能设计和需求分析智能体
- **task-executor.md** - 任务执行和进度跟踪智能体
- **framework-architect.md** - 架构设计和技术选型智能体
- **deep-thinker.md** - 深度思考和决策分析智能体

### context/ - 项目上下文

- **project.md** - 项目名称、描述、目标等基础信息
- **architecture.md** - 项目整体架构、模块划分、技术架构
- **tech-stack.md** - 使用的技术栈、框架、工具链信息
- **current-status.md** - 当前项目开发状态、功能完成情况
- **session/<task-id>.md** - 任务会话记录和上下文
- **session/archive/** - 历史会话归档，便于追溯决策过程

### commands/dd/ - DD 命令定义

- **智能对话** - chat.md 深度对话系统
- **项目级命令** - init.md, init-exist.md, prd.md, framework-\*.md 等
- **功能级命令** - feature-\*.md 系列，处理功能的增删改查和开发
- **任务级命令** - task-\*.md 系列，处理具体任务的执行和管理
- **代码质量** - code-reflect.md 代码变更反思
- **帮助和状态** - help.md, version.md, status.md 等

### scripts/dd/ - 执行脚本

- **项目级操作脚本** - init.sh, init-exist.sh, after-init.sh, prd.sh, framework-\*.sh 等
- **功能级操作脚本** - feature-\*.sh 系列，实际执行功能操作
- **任务级操作脚本** - task-\*.sh 系列，实际执行任务操作
- **代码质量脚本** - code-reflect.sh 代码变更分析
- **帮助和状态脚本** - help.sh, version.sh, status.sh 等
- **utils/** - 通用工具脚本
  - **git-check.sh** - Git状态检查和冲突处理
  - **progress-calc.sh** - 进度计算算法
  - **state-sync.sh** - 状态同步逻辑
  - **deep-think.sh** - 深度思考模式的实现逻辑

### features/ - 功能管理

- **动态功能目录** - 根据用户实际需求创建
- **初始化清理** - after-init.sh 会删除模板示例功能
- **结构标准化** - 每个功能包含 feature.md, technical.md, testing.md, tasks/

### rules/ - 规则系统层次

1. **root.md** - 根规则，动态加载其他规则
2. **absolute.md** - 通过CLAUDE.md永久存在的绝对规则
3. **code-style.md** - 代码风格和质量标准
4. **git-rules.md** - Git操作安全约束
5. **acceptance.md** - 功能和任务验收标准
