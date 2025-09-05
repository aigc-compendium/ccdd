---
allowed-tools: Read, Write, LS, Task
---

# 创建项目上下文

通过分析当前项目状态创建初始项目上下文文档，建立全面的基线文档。

## 用法
```
/dd:context-create
```

## 预检清单

执行前完成这些验证步骤。
不要打扰用户预检进度，直接执行并继续。

### 1. 上下文目录检查
- 运行：`ls -la .claude/context/ 2>/dev/null`
- 如果目录存在且有文件：
  - 统计现有文件：`ls -1 .claude/context/*.md 2>/dev/null | wc -l`
  - 询问用户："⚠️ 发现 {数量} 个现有上下文文件。覆盖所有上下文？(是/否)"
  - 只有明确确认'是'才继续
  - 如果用户说否，建议："使用 /dd:context-update 刷新现有上下文"

### 2. 项目类型检测
- 检查项目指标：
  - Node.js：`test -f package.json && echo "检测到 Node.js 项目"`
  - Python：`test -f requirements.txt || test -f pyproject.toml && echo "检测到 Python 项目"`
  - Rust：`test -f Cargo.toml && echo "检测到 Rust 项目"`
  - Go：`test -f go.mod && echo "检测到 Go 项目"`
- 运行：`git status 2>/dev/null` 确认这是 git 仓库
- 如果不是 git 仓库，询问："⚠️ 不是 git 仓库。继续？(是/否)"

### 3. 目录创建
- 如果 `.claude/` 不存在，创建它：`mkdir -p .claude/context/`
- 验证写权限：`touch .claude/context/.test && rm .claude/context/.test`
- 如果权限被拒绝，告诉用户："❌ 无法创建上下文目录。检查权限。"

### 4. 获取当前时间
- 运行：`date -u +"%Y-%m-%dT%H:%M:%SZ"`
- 在所有上下文文件前置元数据中使用此值

## 操作指南

### 1. 预分析验证
- 确认项目根目录正确（存在 .git、package.json 等）
- 检查可以提供上下文信息的现有文档（README.md、docs/）
- 如果 README.md 不存在，询问用户项目描述

### 2. 系统化项目分析
按此顺序收集信息：

**项目检测：**
```bash
find . -maxdepth 2 -name 'package.json' -o -name 'requirements.txt' -o -name 'Cargo.toml' -o -name 'go.mod' 2>/dev/null
git remote -v 2>/dev/null  # 获取仓库信息
git branch --show-current 2>/dev/null  # 获取当前分支
```

**代码库分析：**
```bash
find . -type f -name '*.js' -o -name '*.py' -o -name '*.rs' -o -name '*.go' 2>/dev/null | head -20
ls -la  # 查看根目录结构
# 如果存在则读取 README.md
```

### 3. 带前置元数据的上下文文件创建

每个上下文文件必须包含带有真实时间的前置元数据：

```yaml
---
创建时间: [使用 date 命令的真实时间]
最后更新: [使用 date 命令的真实时间]
版本: 1.0
作者: DD 工作流系统
---
```

生成以下初始上下文文件：

#### `project-overview.md` - 项目总览
提供项目的高层次总结，包括功能和能力列表

#### `project-brief.md` - 项目简介  
建立项目范围、目标和关键目的

#### `progress.md` - 当前进度
记录当前项目状态、已完成工作和紧急后续步骤
- 包含：当前分支、最近提交、待处理更改

#### `tech-context.md` - 技术上下文
编录当前依赖、技术和开发工具
- 包含：语言版本、框架版本、开发依赖

#### `project-structure.md` - 项目结构
映射目录结构和文件组织
- 包含：关键目录、文件命名模式、模块组织

#### `system-patterns.md` - 系统模式
识别现有架构模式和设计决策
- 包含：观察到的设计模式、架构风格、数据流

#### `product-context.md` - 产品上下文
定义产品需求、目标用户和核心功能
- 包含：用户画像、核心功能、用例

#### `project-vision.md` - 项目愿景
阐述长期愿景和战略方向
- 包含：未来目标、潜在扩展、战略优先级

#### `project-style-guide.md` - 项目风格指南
记录编码标准、惯例和风格偏好
- 包含：命名惯例、文件结构模式、注释风格

### 4. 使用智能体进行复杂分析

如果项目复杂（>50个文件），使用 Task 工具并行分析：

```yaml
Task:
  description: "分析项目技术栈"
  subagent_type: "code-analyzer"
  prompt: |
    分析当前项目的技术栈和架构：
    
    1. 识别主要技术和框架
    2. 分析依赖关系和版本
    3. 理解项目结构和模式
    4. 识别关键配置和设置
    
    为以下上下文文件生成内容：
    - tech-context.md
    - system-patterns.md
    - project-structure.md
    
    确保分析准确且全面，但保持内容简洁。
```

### 5. 质量验证

创建每个文件后：
- 验证文件创建成功
- 检查文件不为空（最少10行内容）
- 确保前置元数据存在且有效
- 验证 markdown 格式正确

### 6. 错误处理

**常见问题：**
- **无写权限：**"❌ 无法写入 .claude/context/。检查权限。"
- **磁盘空间：**"❌ 磁盘空间不足，无法创建上下文文件。"
- **文件创建失败：**"❌ 创建 {filename} 失败。错误：{error}"

如果任何文件创建失败：
- 报告成功创建的文件
- 提供继续使用部分上下文的选项
- 永不留下损坏或不完整的文件

### 7. 创建后摘要

提供全面摘要：

```markdown
📋 上下文创建完成

📁 在以下位置创建上下文：.claude/context/
✅ 创建文件：{count}/9

📊 上下文摘要：
  - 项目类型：{detected_type}
  - 语言：{primary_language}
  - Git 状态：{clean/changes}
  - 依赖：{count} 个包

📝 文件详情：
  ✅ project-overview.md ({lines} 行) - 项目总览和功能列表
  ✅ project-brief.md ({lines} 行) - 项目目标和范围
  ✅ progress.md ({lines} 行) - 当前状态和最近工作
  ✅ tech-context.md ({lines} 行) - 技术栈和依赖
  ✅ project-structure.md ({lines} 行) - 目录组织
  ✅ system-patterns.md ({lines} 行) - 架构模式
  ✅ product-context.md ({lines} 行) - 产品需求
  ✅ project-vision.md ({lines} 行) - 长期愿景
  ✅ project-style-guide.md ({lines} 行) - 编码规范

⏰ 创建时间：{timestamp}
🔄 下一步：使用 /dd:context-prime 在新会话中加载上下文
💡 提示：定期运行 /dd:context-update 保持上下文当前
```

## 上下文收集命令

使用这些命令收集项目信息：
- 目标目录：`.claude/context/`（需要时创建）
- 当前 git 状态：`git status --short`
- 最近提交：`git log --oneline -10`
- 项目 README：读取 `README.md`（如果存在）
- 包文件：检查 `package.json`、`requirements.txt`、`Cargo.toml`、`go.mod` 等
- 文档扫描：`find . -type f -name '*.md' -path '*/docs/*' 2>/dev/null | head -10`
- 测试检测：`find . -type d \( -name 'test' -o -name 'tests' -o -name '__tests__' -o -name 'spec' \) 2>/dev/null | head -5`

## 重要说明

- **始终使用真实时间** 从系统时钟，绝不使用占位符
- **覆盖前询问确认** 现有上下文
- **验证每个文件** 创建成功
- **提供详细摘要** 创建的内容
- **优雅处理错误** 并提供具体指导

## 安全约束

- 遵循 `.claude/rules/git-safety.md` 中的所有安全规则
- 只执行只读的 git 操作进行信息收集
- 不修改项目代码或配置文件
- 仅在 `.claude/context/` 目录下创建文件