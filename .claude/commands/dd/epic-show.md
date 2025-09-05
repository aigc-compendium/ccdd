---
allowed-tools: Read, LS
---

# Epic详情查看

显示指定技术实施计划的详细内容、执行状态和任务分解情况。

## 用法
```
/dd:epic-show <功能名称>
```

## 参数说明
- `<功能名称>` - Epic的功能标识名称

## 操作指南

### 1. 查找Epic文件
```bash
# 在Epic目录中查找指定名称的文件
epic_dir=".claude/epics/${ARGUMENTS}"
epic_file="${epic_dir}/epic.md"

if [ ! -f "$epic_file" ]; then
  echo "❌ Epic不存在：$ARGUMENTS"
  echo "💡 运行 /dd:epic-list 查看所有可用Epic"
  exit 1
fi
```

### 2. 提取Epic信息
```bash
# 提取前置元数据和关键信息
epic_name=$(grep "^名称:" "$epic_file" | sed 's/^名称: *//')
epic_status=$(grep "^状态:" "$epic_file" | sed 's/^状态: *//')
epic_created=$(grep "^创建时间:" "$epic_file" | sed 's/^创建时间: *//')
epic_updated=$(grep "^最后更新:" "$epic_file" | sed 's/^最后更新: *//')
epic_description=$(grep "^描述:" "$epic_file" | sed 's/^描述: *//')

# 检查对应的PRD
prd_file=".claude/prds/${ARGUMENTS}.md"
prd_exists="否"
if [ -f "$prd_file" ]; then
  prd_exists="是"
  prd_status=$(grep "^状态:" "$prd_file" | sed 's/^状态: *//')
fi
```

### 3. 任务统计分析
```bash
# 统计Epic下的所有任务
analyze_tasks() {
  local epic_dir="$1"
  
  # 统计各状态任务数量
  local total_tasks=0
  local pending_tasks=0
  local active_tasks=0
  local completed_tasks=0
  local blocked_tasks=0
  
  for task_file in "$epic_dir"/*.md; do
    if [[ "$task_file" != *"epic.md" ]] && [ -f "$task_file" ]; then
      ((total_tasks++))
      
      local task_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
      case "$task_status" in
        "待开始") ((pending_tasks++)) ;;
        "进行中") ((active_tasks++)) ;;
        "已完成") ((completed_tasks++)) ;;
        "阻塞") ((blocked_tasks++)) ;;
      esac
    fi
  done
  
  # 计算完成率
  local completion_rate=0
  if [ $total_tasks -gt 0 ]; then
    completion_rate=$((completed_tasks * 100 / total_tasks))
  fi
  
  # 导出统计数据
  echo "$total_tasks|$pending_tasks|$active_tasks|$completed_tasks|$blocked_tasks|$completion_rate" > /tmp/epic_task_stats.txt
}
```

### 4. 技术方案提取
```bash
# 提取技术方案关键章节
extract_technical_sections() {
  local epic_file="$1"
  
  # 提取技术架构
  local tech_arch=$(sed -n '/^## 技术架构/,/^## /p' "$epic_file" | head -n -1)
  
  # 提取核心组件
  local core_components=$(sed -n '/^## 核心组件/,/^## /p' "$epic_file" | head -n -1)
  
  # 提取实施步骤
  local implementation_steps=$(sed -n '/^## 实施步骤/,/^## /p' "$epic_file" | head -n -1)
  
  # 提取风险评估
  local risk_assessment=$(sed -n '/^## 风险评估/,/^## /p' "$epic_file" | head -n -1)
}
```

### 5. 依赖关系分析
```bash
# 分析Epic和任务的依赖关系
analyze_dependencies() {
  local epic_dir="$1"
  local epic_name="$2"
  
  echo "🔗 依赖关系分析："
  
  # 检查Epic级别的依赖
  if grep -q "^Epic依赖:" "$epic_dir/epic.md"; then
    local epic_deps=$(grep "^Epic依赖:" "$epic_dir/epic.md" | sed 's/^Epic依赖: *//')
    echo "  📁 Epic依赖: $epic_deps"
  fi
  
  # 统计任务间的依赖关系
  local dep_count=0
  for task_file in "$epic_dir"/*.md; do
    if [[ "$task_file" != *"epic.md" ]] && [ -f "$task_file" ]; then
      if grep -q "^依赖:" "$task_file"; then
        ((dep_count++))
      fi
    fi
  done
  
  echo "  📋 包含依赖的任务数: $dep_count"
  
  # 检查被其他Epic依赖的情况
  local dependent_epics=$(find .claude/epics -name "epic.md" -exec grep -l "Epic依赖:.*$epic_name" {} \;)
  if [ -n "$dependent_epics" ]; then
    echo "  ⬆️  被以下Epic依赖:"
    echo "$dependent_epics" | while read dep_epic_file; do
      local dep_epic_name=$(dirname "$dep_epic_file" | xargs basename)
      echo "    - $dep_epic_name"
    done
  fi
}
```

### 6. 进度可视化
```bash
# 创建进度可视化
create_progress_visualization() {
  local completion_rate="$1"
  local total_tasks="$2"
  local completed_tasks="$3"
  
  # 创建进度条
  local bar_length=30
  local filled=$((completion_rate * bar_length / 100))
  local empty=$((bar_length - filled))
  
  local progress_bar=""
  for ((i=0; i<filled; i++)); do progress_bar+="█"; done
  for ((i=0; i<empty; i++)); do progress_bar+="░"; done
  
  echo "📊 执行进度："
  echo "  [$progress_bar] $completion_rate% ($completed_tasks/$total_tasks)"
}
```

## 输出格式

### Epic详细信息
```markdown
🎯 Epic详情：{功能名称}

## 基本信息
- 🏷️ 名称：{Epic名称}
- 📊 状态：{状态图标} {状态}
- 📅 创建时间：{创建时间}
- 🔄 最后更新：{最后更新时间}
- 📝 描述：{功能描述}

## 关联PRD
- 📋 PRD状态：{存在/不存在}
- 📊 PRD状态：{PRD当前状态}

## 执行进度
{进度条可视化}
- 📋 总任务数：{总任务数}
- ⏳ 待开始：{待开始数量}
- 🔄 进行中：{进行中数量}
- ✅ 已完成：{已完成数量}
- 🚫 阻塞：{阻塞数量}
- 📊 完成率：{完成率}%

## 技术方案概览
### 🏗️ 技术架构
{技术架构关键信息}

### 🔧 核心组件
{核心组件列表}

### 📋 实施步骤
{实施步骤概要}

## 依赖关系
{依赖关系分析结果}

## 风险评估
{风险评估关键信息}

## 相关文件
- Epic文件：{Epic文件路径}
- PRD文件：{PRD文件路径或"无"}
- 任务文件：{任务文件数量} 个

## 快捷操作
- 📝 编辑Epic：直接编辑文件 {Epic文件路径}
- 🔧 分解任务：/dd:epic-decompose {功能名称}
- 📋 查看任务：/dd:task-list --epic={功能名称}
- ▶️  开始执行：/dd:task-start <任务ID>
```

## 任务列表详情

### 任务概览表
```markdown
## 📋 任务分解详情

| 任务ID | 任务名称 | 状态 | 优先级 | 预估工作量 | 依赖 |
|--------|----------|------|--------|------------|------|
| 001    | 用户认证API | ✅已完成 | 高 | 4小时 | - |
| 002    | 数据库设计 | 🔄进行中 | 高 | 3小时 | 001 |
| 003    | 前端集成 | ⏳待开始 | 中 | 5小时 | 001,002 |
```

## 错误处理

### Epic不存在
```markdown
❌ Epic不存在：{功能名称}

可能原因：
1. 功能名称拼写错误
2. Epic尚未创建
3. Epic文件已移动或删除

建议操作：
- 运行 /dd:epic-list 查看所有Epic
- 确认功能名称的正确拼写
- 从PRD生成Epic: /dd:prd-parse {功能名称}
```

### Epic文件损坏
```markdown
⚠️ Epic文件存在但无法解析

问题：{具体错误信息}

建议操作：
- 检查文件格式是否正确
- 确认前置元数据完整性
- 手动检查文件：{文件路径}
```

## 使用示例

```bash
# 查看用户认证系统的Epic详情
/dd:epic-show 用户认证系统

# 查看支付系统的Epic
/dd:epic-show 支付系统

# 查看订单管理的Epic
/dd:epic-show 订单管理
```