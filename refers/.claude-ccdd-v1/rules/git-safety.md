# Git 安全规则

dd 工作流系统的核心安全原则：绝对不允许 AI 执行任何 git 写操作。

## 绝对禁止的操作

### Git 写操作
- `git add` - 暂存文件
- `git commit` - 提交更改
- `git push` - 推送到远程
- `git pull` - 拉取远程更改
- `git merge` - 合并分支
- `git rebase` - 变基操作
- `git reset --hard` - 硬重置
- `git checkout -b` - 创建新分支
- `git branch -d` - 删除分支

### GitHub 操作
- `gh issue create` - 创建问题
- `gh issue edit` - 编辑问题  
- `gh pr create` - 创建拉取请求
- `gh pr edit` - 编辑拉取请求
- 任何涉及远程仓库修改的操作

### 危险的文件操作
- 修改 `.git/` 目录下的任何文件
- 在 `.claude/` 目录外创建/修改文件
- 执行任何可能影响版本控制的操作

## 允许的只读操作

### Git 查看操作
- `git status` - 查看工作区状态
- `git diff` - 查看文件差异
- `git log` - 查看提交历史
- `git show` - 显示提交详情
- `git branch -a` - 查看分支列表
- `git remote -v` - 查看远程地址

### 安全的文件操作
- 读取任何文件内容
- 在 `.claude/` 目录下创建/修改文件
- 分析和搜索代码
- 生成报告和文档

## 安全检查机制

### 命令前验证
AI 在执行任何 Bash 命令前必须：
1. 检查命令是否包含禁止的 git 操作
2. 确认文件路径在允许的范围内
3. 验证操作的安全性

### 工具限制
在命令 frontmatter 中严格限制 allowed-tools：
```yaml
allowed-tools: Read, Write, LS, Glob, Grep, Task
# 绝不包含 Bash（除非绝对安全的只读操作）
```

### 智能体约束
所有智能体必须遵循相同的安全规则：
- 不执行任何 git 写操作
- 不修改 `.claude/` 外的文件
- 只进行分析、总结和报告

## 违规处理

如果检测到尝试执行禁止操作：
1. 立即停止执行
2. 明确告知用户违规内容
3. 提供安全的替代方案
4. 记录违规尝试（如需要）

## 用户手动操作建议

当 AI 分析完成后，向用户提供建议：
```bash
# 建议的手动操作示例
git add src/components/new-feature.js
git commit -m "feat: 添加新功能组件"
git push origin feature-branch
```

但绝不自动执行这些操作。

## 安全提醒

- AI 是分析和建议的助手，不是执行者
- 用户保持对代码仓库的完全控制权
- 所有关键决策必须由用户确认和执行
- 透明度是安全的基础