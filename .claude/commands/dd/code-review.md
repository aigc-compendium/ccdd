---
allowed-tools: Read, LS, Grep, Task
---

# 改动检查和安全审查

分析当前工作区的所有改动，提供安全检查、代码质量评估和提交建议。

## 用法
```
/dd:changes-review [--详细]
```

## 参数说明
- `--详细` - 显示每个文件的详细差异信息（可选）

## 功能概述

这个命令提供全面的改动分析，但**绝不执行任何git操作**。它只是分析和建议，所有实际的git操作需要用户手动执行。

## 操作指南

### 1. 收集改动信息

使用只读的git命令收集信息：
```bash
# 获取工作区状态
git status --porcelain

# 获取分支信息
git branch --show-current
git status -b --porcelain

# 获取暂存和未暂存的差异
git diff --name-status
git diff --cached --name-status
```

### 2. 分析改动范围

#### 文件统计
- 新增文件数量
- 修改文件数量  
- 删除文件数量
- 重命名/移动文件数量

#### 代码量统计
```bash
# 统计行数变化（只读操作）
git diff --stat
git diff --cached --stat

# 按文件类型分组
git diff --name-only | grep -E '\.(js|ts|py|java|go)$' | wc -l
git diff --name-only | grep -E '\.(md|txt|yml|yaml)$' | wc -l
```

### 3. 安全检查

#### 敏感信息检测
使用 Grep 工具搜索潜在的敏感信息：

```bash
# 检查密钥和密码模式
grep -r -i "password\s*=" 变更的文件
grep -r -i "api_key\s*=" 变更的文件  
grep -r -i "secret\s*=" 变更的文件
grep -r -i "token\s*=" 变更的文件

# 检查硬编码的凭据
grep -r -E "(username|password)\s*:\s*['\"].*['\"]" 变更的文件
grep -r -E "https?://[^@\s]+:[^@\s]+@" 变更的文件
```

#### 配置文件检查
```bash
# 检查是否有配置文件被意外提交
git diff --name-only | grep -E '\.(env|config|ini|conf)$'

# 检查是否有调试代码
grep -r -i "console\.log\|debugger\|print\(" 变更的文件
grep -r -i "TODO\|FIXME\|HACK" 变更的文件
```

### 4. 代码质量分析

#### 使用代码分析智能体
如果改动文件较多（>5个）或改动较复杂，使用 Task 工具调用代码分析智能体：

```yaml
Task:
  description: "分析代码改动质量"
  subagent_type: "code-analyzer"
  prompt: |
    分析当前工作区的代码改动，重点关注：
    
    1. 代码质量问题
    2. 潜在的bug和逻辑错误
    3. 性能影响
    4. 架构一致性
    5. 最佳实践遵循情况
    
    改动的文件列表：
    {列出所有变更文件}
    
    请提供简洁的分析报告，包括：
    - 关键质量问题
    - 改进建议  
    - 风险评估
    - 建议的提交策略
```

### 5. 依赖分析

#### 包管理文件检查
```bash
# 检查依赖文件是否有变更
git diff --name-only | grep -E 'package\.json|requirements\.txt|go\.mod|Cargo\.toml'

# 如果有依赖变更，分析影响
if [[ $(git diff --name-only | grep -E 'package\.json') ]]; then
  echo "检测到依赖变更，建议检查："
  echo "- 新增依赖的安全性"
  echo "- 版本兼容性"
  echo "- 许可证合规性"
fi
```

### 6. 分支和合并策略分析

```bash
# 检查当前分支状态
current_branch=$(git branch --show-current)
main_branch="main"  # 或 master

# 检查是否有未合并的上游变更
git fetch origin $main_branch 2>/dev/null || echo "无法获取远程分支信息"
commits_ahead=$(git rev-list --count HEAD ^origin/$main_branch 2>/dev/null || echo "未知")
commits_behind=$(git rev-list --count origin/$main_branch ^HEAD 2>/dev/null || echo "未知")
```

## 输出格式

### 标准报告结构
```markdown
# 改动检查报告

## 📊 改动概览
- 当前分支：{分支名}
- 总变更文件：{数量}
- 新增文件：{数量}
- 修改文件：{数量}
- 删除文件：{数量}

## 🔍 安全检查
### ✅ 通过检查
- 未发现敏感信息泄露
- 无意外的配置文件
- 调试代码已清理

### ⚠️ 安全警告
- 发现硬编码密码：文件路径
- 包含调试代码：文件路径
- 配置文件变更：文件路径

## 📈 代码质量评估
- 整体质量：良好/需改进/有问题
- 主要问题：{关键问题列表}
- 改进建议：{具体建议}

## 📦 依赖变更
- 新增依赖：{列表}
- 更新依赖：{列表}
- 移除依赖：{列表}

## 💡 提交建议
### 建议的提交策略
1. 首先提交：{安全相关的文件}
2. 然后提交：{核心功能文件}
3. 最后提交：{文档和配置文件}

### 建议的提交信息
```bash
# 建议的提交命令（需手动执行）
git add {文件列表}
git commit -m "feat: {功能描述}

{详细描述}

- 关键变更1
- 关键变更2"
```

## 🔄 后续步骤建议
1. 修复发现的安全问题
2. 运行测试验证功能
3. 更新相关文档
4. 检查代码审查清单
```

### 详细模式输出
如果使用 `--详细` 参数，额外显示：

```markdown
## 📄 详细文件差异

### {文件名1}
- 变更类型：修改
- 行数变化：+{新增} -{删除}
- 关键变更：
  - 变更点1：描述
  - 变更点2：描述

### {文件名2}  
- 变更类型：新增
- 功能描述：文件用途说明
- 注意事项：需要关注的点
```

## 错误处理

### 常见问题处理
```bash
# 如果不在git仓库中
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ 当前目录不是git仓库"
  echo "请在git仓库根目录运行此命令"
  exit 1
fi

# 如果没有任何改动
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ℹ️ 工作区无任何改动"
  echo "所有文件都已提交或暂存"
fi
```

## 安全约束

### 严格限制
- **绝不执行**任何写操作的git命令
- **只使用**只读的git查询命令
- **不修改**任何文件或配置
- **不执行**自动化的修复操作

### 允许的操作
- `git status` - 查看状态
- `git diff` - 查看差异
- `git log` - 查看历史（如需要）
- `git show` - 显示特定提交（如需要）

## 最佳实践

### 使用建议
1. **在提交前运行** - 作为提交前的最后检查
2. **定期执行** - 在开发过程中定期检查改动
3. **结合其他工具** - 配合linter和测试使用
4. **关注安全** - 特别注意敏感信息检查
5. **文档同步** - 确保文档与代码变更同步

### 工作流集成
```bash
# 建议的工作流
/dd:changes-review          # 检查改动
# 根据建议修复问题
/dd:changes-review --详细    # 再次详细检查
# 手动执行建议的git操作
```