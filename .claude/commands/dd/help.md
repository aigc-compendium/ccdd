---
allowed-tools: Read, LS
---

# DD 工作流系统帮助

显示 dd 工作流系统的命令帮助和使用指南。

## 用法
```
/dd:help [命令名]
```

## DD 工作流系统简介

DD 是一个安全的、自控程度高的开发工作流系统，专注于：
- 产品需求到技术实施的完整管道  
- 智能体协作和上下文优化
- 严格的 Git 安全控制
- 用户完全掌控关键操作

## ⚠️ 绝对规则

DD 系统有一套绝对不可违反的核心规则，详见：`.claude/rules/absolute-rules.md`

**关键约束：**
- 🔴 绝对禁止任何 git 写操作（add、commit、push 等）
- 🔴 绝对禁止修改 `.claude/` 目录外的文件
- 🔴 绝对禁止暴露敏感信息（密钥、密码等）
- 🟠 必须使用专用智能体进行复杂分析
- 🟠 关键操作必须用户确认

## 核心命令

### 📋 PRD管理
```bash
/dd:prd-new <功能名称>        # 创建新的产品需求文档
/dd:prd-list [选项]          # 列出所有PRD
/dd:prd-show <功能名称>       # 查看PRD详情
/dd:prd-parse <功能名称>      # 将PRD转换为技术实施计划
```

### 🎯 Epic管理  
```bash
/dd:epic-list [选项]         # 列出所有执行计划
/dd:epic-show <功能名称>      # 显示特定执行计划详情
/dd:epic-decompose <功能名称>  # 分解执行计划为具体任务
```

### 📋 任务管理
```bash
/dd:task-list [选项]         # 显示任务列表和状态
/dd:task-show <任务ID>        # 查看任务详情
/dd:task-start <任务ID>      # 开始执行指定任务
/dd:task-pause <任务ID>      # 暂停任务
/dd:task-resume [任务ID]     # 恢复执行未完成的任务
/dd:task-finish <任务ID>     # 完成任务
/dd:task-set <任务ID> <操作> [参数]  # 设置任务属性
```

### 🔍 代码质量
```bash
/dd:code-review             # 检查当前改动（推荐）
/dd:code-reflect            # 改动后自我反思分析
```

### 🔧 上下文管理
```bash
/dd:ctx-init                # 初始化项目上下文
/dd:ctx-load                # 加载上下文到新会话
/dd:ctx-sync                # 同步项目上下文
```

### 🛠️ 系统工具
```bash
/dd:status                  # 显示项目整体状态
/dd:help [命令名]            # 显示帮助信息
```

## 典型工作流

### 1. 完整开发流程
```bash
# 1. 初始化项目上下文
/dd:ctx-init

# 2. 创建产品需求文档
/dd:prd-new 用户认证系统

# 3. 转换为技术实施计划
/dd:prd-parse 用户认证系统

# 4. 分解为具体任务
/dd:epic-decompose 用户认证系统

# 5. 查看任务列表
/dd:task-list --assignable

# 6. 开始执行任务
/dd:task-start 001

# 7. 改动后反思
/dd:code-reflect

# 8. 暂停或恢复任务
/dd:task-pause 001
/dd:task-resume 001

# 9. 完成任务
/dd:task-finish 001

# 10. 检查改动
/dd:code-review

# 11. 同步上下文
/dd:ctx-sync
```

### 2. 代码审查流程
```bash
# 检查当前所有改动
/dd:code-review

# 获取详细分析
/dd:code-review --详细

# 改动后反思分析
/dd:code-reflect

# 根据建议手动执行git操作
git add <文件>
git commit -m "提交信息"
```

## 安全特性

### 🔒 Git 安全保护
- **绝不执行**任何git写操作（add、commit、push等）
- **只提供分析**和建议，用户手动执行
- **多层安全检查**防止意外操作
- **透明操作**所有分析过程对用户可见

### 🛡️ 智能安全检查
- **敏感信息扫描**检测密钥、密码泄露
- **代码质量分析**识别潜在bug和问题  
- **依赖安全审计**分析第三方库风险
- **配置文件检查**防止意外配置暴露

## 智能体系统

### 🤖 专用智能体
- **代码分析智能体** - 深度代码分析和bug检测
- **文件分析智能体** - 日志和文档智能解析
- **测试执行智能体** - 测试运行和结果分析

### 🔄 上下文优化
- 智能体处理复杂分析，保持主对话清洁
- 自动选择最适合的智能体
- 结果摘要优化，减少token使用

## 文件结构

```
.claude/
├── commands/dd/          # DD命令定义
├── agents/              # 智能体定义
├── rules/              # 操作规则
├── prds/               # 产品需求文档
├── epics/              # 执行计划和任务
└── context/            # 项目上下文
```

## 配置和自定义

### 前置元数据字段
```yaml
---
名称: 功能标识名称
状态: backlog|进行中|已完成
创建时间: ISO格式时间戳
描述: 简短功能描述
---
```

### 状态生命周期
- **PRD**: backlog → 评估中 → 已批准 → 已实施
- **Epic**: backlog → 规划中 → 进行中 → 已完成  
- **任务**: 待开始 → 进行中 → 待审查 → 已完成

## 任务列表管理

### 📋 任务查看
```bash
/dd:task-list                    # 查看所有任务
/dd:task-list --pending          # 只显示待开始任务
/dd:task-list --active           # 只显示进行中任务
/dd:task-list --completed        # 只显示已完成任务
/dd:task-list --blocked          # 只显示被阻塞任务
/dd:task-list --assignable       # 显示可立即开始的任务
/dd:task-list --priority=高      # 按优先级筛选
/dd:task-list --epic=用户认证     # 只显示指定Epic任务
/dd:task-list --tree             # 树形结构显示依赖关系
/dd:task-list --summary          # 显示摘要统计
```

### 🔧 任务管理
```bash
# 状态管理
/dd:task-set 001 set-status 进行中
/dd:task-set 001 set-status 已完成

# 优先级管理
/dd:task-set 001 set-priority 高
/dd:task-set 001 set-priority 中

# 依赖关系管理
/dd:task-set 001 add-dependency 002,003
/dd:task-set 001 remove-dependency 002
/dd:task-set 001 clear-dependencies

# 其他属性管理
/dd:task-set 001 set-effort 5小时
/dd:task-set 001 set-parallel true
/dd:task-set 001 add-note "遇到技术难点需要调研"
```

## 最佳实践

### ✅ 推荐做法
1. **定期检查改动** - 提交前运行`/dd:code-review`
2. **结构化开发** - 遵循 PRD → Epic → Task 流程
3. **小步快跑** - 保持任务粒度适中（2-8小时）
4. **安全第一** - 重视敏感信息检查
5. **文档同步** - 保持代码与文档一致
6. **任务管理** - 定期查看任务状态，及时更新进度
7. **反思总结** - 改动后运行`/dd:code-reflect`

### ❌ 避免事项
1. 跳过PRD直接开发
2. 创建过大或过小的任务
3. 忽略安全检查建议
4. 依赖AI自动执行git操作
5. 混合多个功能在一个提交

## 故障排除

### 常见问题

#### 命令无法识别
```bash
# 确认命令格式正确
/dd:help  # 查看所有可用命令
```

#### 文件权限错误  
```bash
# 确保在项目根目录
ls -la .claude/  # 查看dd配置目录
```

#### Git状态异常
```bash
# 检查git仓库状态
git status
# dd系统只读取状态，不修改
```

### 获取帮助
```bash
# 查看特定命令帮助
/dd:help prd-new
/dd:help code-review
/dd:help epic-decompose
/dd:help task-list
/dd:help task-set
```

## 版本信息

- **系统版本**: DD v1.0
- **基于**: CCPM工作流系统
- **安全增强**: 完全移除自动git操作
- **智能体**: 上下文优化专用智能体

## 支持

如需更多帮助：
1. 查看具体命令的详细说明：`/dd:help <命令名>`
2. 检查`.claude/rules/`目录下的规则文档
3. 查看智能体说明：`.claude/agents/`目录

---
*DD 工作流系统 - 安全、智能、可控的开发工作流*