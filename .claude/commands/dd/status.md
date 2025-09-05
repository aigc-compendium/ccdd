---
allowed-tools: Read, LS, Glob
---

# 项目状态概览

显示 dd 工作流系统管理的项目整体状态。

## 用法
```
/dd:status
```

## 功能概述

显示项目的全面状态信息，包括：
- PRD 和 Epic 统计
- 任务进度概览
- 最近活动情况
- 系统健康状态

## 操作指南

### 1. 收集PRD信息

```bash
# 统计PRD文件
prd_count=$(ls .claude/prds/*.md 2>/dev/null | wc -l)

# 按状态分类PRD
backlog_prds=$(grep -l "^状态: backlog" .claude/prds/*.md 2>/dev/null | wc -l)
in_progress_prds=$(grep -l "^状态: 评估中\|^状态: 已批准" .claude/prds/*.md 2>/dev/null | wc -l)
completed_prds=$(grep -l "^状态: 已实施" .claude/prds/*.md 2>/dev/null | wc -l)
```

### 2. 收集Epic信息

```bash
# 统计Epic目录
epic_count=$(ls -d .claude/epics/*/ 2>/dev/null | wc -l)

# 按状态分类Epic
backlog_epics=$(find .claude/epics -name "epic.md" -exec grep -l "^状态: backlog" {} \; 2>/dev/null | wc -l)
in_progress_epics=$(find .claude/epics -name "epic.md" -exec grep -l "^状态: 进行中\|^状态: 规划中" {} \; 2>/dev/null | wc -l)
completed_epics=$(find .claude/epics -name "epic.md" -exec grep -l "^状态: 已完成" {} \; 2>/dev/null | wc -l)
```

### 3. 收集任务统计

```bash
# 统计所有任务文件（排除epic.md）
total_tasks=$(find .claude/epics -name "*.md" ! -name "epic.md" 2>/dev/null | wc -l)

# 按状态统计任务
pending_tasks=$(find .claude/epics -name "*.md" ! -name "epic.md" -exec grep -l "^状态: 待开始" {} \; 2>/dev/null | wc -l)
in_progress_tasks=$(find .claude/epics -name "*.md" ! -name "epic.md" -exec grep -l "^状态: 进行中" {} \; 2>/dev/null | wc -l)
completed_tasks=$(find .claude/epics -name "*.md" ! -name "epic.md" -exec grep -l "^状态: 已完成" {} \; 2>/dev/null | wc -l)
```

### 4. 分析最近活动

```bash
# 查找最近修改的文件
recent_prds=$(find .claude/prds -name "*.md" -mtime -7 2>/dev/null)
recent_epics=$(find .claude/epics -name "*.md" -mtime -7 2>/dev/null)

# 获取最近活跃的项目
active_projects=$(find .claude/epics -name "*.md" -mtime -7 -exec dirname {} \; 2>/dev/null | sort -u)
```

### 5. Git工作区状态（只读）

```bash
# 检查是否在git仓库中
if git rev-parse --git-dir >/dev/null 2>&1; then
  # 获取当前分支
  current_branch=$(git branch --show-current 2>/dev/null)
  
  # 获取工作区状态
  modified_files=$(git diff --name-only 2>/dev/null | wc -l)
  staged_files=$(git diff --cached --name-only 2>/dev/null | wc -l)
  untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
fi
```

## 输出格式

### 标准状态报告

```markdown
# 📊 DD 项目状态报告

## 🗂️ 产品需求文档 (PRD)
- **总计**: {prd_count} 个PRD
- **待办**: {backlog_prds} 个
- **进行中**: {in_progress_prds} 个  
- **已完成**: {completed_prds} 个

## 🎯 执行计划 (Epic)
- **总计**: {epic_count} 个Epic
- **待办**: {backlog_epics} 个
- **进行中**: {in_progress_epics} 个
- **已完成**: {completed_epics} 个

## ✅ 任务统计
- **总任务数**: {total_tasks} 个
- **待开始**: {pending_tasks} 个
- **进行中**: {in_progress_tasks} 个
- **已完成**: {completed_tasks} 个
- **完成率**: {completion_percentage}%

## 🔄 Git 工作区状态
- **当前分支**: {current_branch}
- **修改文件**: {modified_files} 个
- **暂存文件**: {staged_files} 个
- **未跟踪文件**: {untracked_files} 个

## 📈 近期活动 (7天内)
### 活跃项目
{列出最近有活动的项目}

### 最近更新的PRD
{列出最近修改的PRD}

### 最近更新的Epic
{列出最近修改的Epic}

## 💡 建议行动
{根据当前状态提供建议}
```

### 详细项目列表

对于每个活跃项目，显示：

```markdown
### 📁 项目：{项目名}
- **状态**: {当前状态}
- **进度**: {完成百分比}
- **任务**: {已完成}/{总数}
- **最后更新**: {时间}
- **下一步**: {建议的下一步行动}
```

## 健康度评估

### 系统健康检查

```bash
# 检查文件完整性
check_file_integrity() {
  # 检查PRD前置元数据完整性
  for prd in .claude/prds/*.md; do
    if ! grep -q "^名称:" "$prd" 2>/dev/null; then
      echo "⚠️ PRD缺少名称字段: $prd"
    fi
  done
  
  # 检查Epic前置元数据完整性
  for epic in .claude/epics/*/epic.md; do
    if ! grep -q "^名称:" "$epic" 2>/dev/null; then
      echo "⚠️ Epic缺少名称字段: $epic"
    fi
  done
}
```

### 建议生成逻辑

```bash
generate_recommendations() {
  local recommendations=()
  
  # 基于当前状态生成建议
  if [ "$pending_tasks" -gt 0 ]; then
    recommendations+=("有 $pending_tasks 个待开始任务，建议优先开始高优先级任务")
  fi
  
  if [ "$modified_files" -gt 0 ]; then
    recommendations+=("工作区有 $modified_files 个修改文件，建议运行 /dd:changes-review 检查")
  fi
  
  if [ "$backlog_prds" -gt "$in_progress_prds" ]; then
    recommendations+=("有较多待办PRD，建议评估和优先级排序")
  fi
  
  # 输出建议
  for rec in "${recommendations[@]}"; do
    echo "- $rec"
  done
}
```

## 高级功能

### 趋势分析

```bash
# 分析项目活跃度趋势
analyze_activity_trend() {
  # 统计不同时间段的文件修改
  last_24h=$(find .claude -name "*.md" -mtime -1 2>/dev/null | wc -l)
  last_week=$(find .claude -name "*.md" -mtime -7 2>/dev/null | wc -l)
  last_month=$(find .claude -name "*.md" -mtime -30 2>/dev/null | wc -l)
  
  echo "活跃度趋势："
  echo "- 最近24小时: $last_24h 个文件更新"
  echo "- 最近7天: $last_week 个文件更新" 
  echo "- 最近30天: $last_month 个文件更新"
}
```

### 瓶颈识别

```bash
identify_bottlenecks() {
  # 识别长时间停滞的项目
  stale_projects=$(find .claude/epics -name "epic.md" -mtime +14 -exec grep -l "^状态: 进行中" {} \; 2>/dev/null)
  
  if [ -n "$stale_projects" ]; then
    echo "⚠️ 发现停滞项目："
    echo "$stale_projects" | while read project; do
      project_name=$(basename $(dirname "$project"))
      echo "- $project_name (超过14天无更新)"
    done
  fi
}
```

## 快捷操作建议

基于状态分析，提供快捷操作：

```markdown
## 🚀 快捷操作

### 立即可执行
- `/dd:changes-review` - 检查当前改动
- `/dd:epic-list` - 查看所有执行计划
- `/dd:prd-list` - 查看所有需求文档

### 基于当前状态
{动态生成基于当前状态的建议命令}

### 项目推进
{基于项目状态提供的推进建议}
```

## 错误处理

```bash
# 处理目录不存在的情况
if [ ! -d ".claude" ]; then
  echo "❌ 未找到 .claude 目录"
  echo "请确保在 DD 工作流项目根目录运行此命令"
  exit 1
fi

# 处理无权限访问
if [ ! -r ".claude/prds" ]; then
  echo "⚠️ 无法访问 PRD 目录，权限不足"
fi
```

## 性能优化

- 使用高效的文件查找和统计方法
- 缓存重复计算的结果
- 仅在需要时执行耗时操作
- 并行处理独立的统计任务

## 集成建议

建议在以下情况自动运行状态检查：
- 项目初始化后
- 完成重要里程碑时
- 定期健康检查
- 用户请求项目概览时