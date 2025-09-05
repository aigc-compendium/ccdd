---
allowed-tools: Read, LS
---

# Epic列表管理

显示项目中所有技术实施计划的列表和执行状态概览。

## 用法
```
/dd:epic-list [选项]
```

## 选项参数
- `--all` - 显示所有Epic（默认）
- `--backlog` - 只显示待开始的Epic
- `--planning` - 只显示规划中的Epic  
- `--active` - 只显示进行中的Epic
- `--completed` - 只显示已完成的Epic
- `--summary` - 显示摘要统计信息
- `--with-tasks` - 显示包含任务分解情况

## 操作指南

### 1. 扫描Epic目录
```bash
# 收集所有Epic信息
collect_epic_data() {
  local epics_data=()
  local total_epics=0
  
  echo "🔍 扫描所有Epic执行计划..."
  
  for epic_dir in .claude/epics/*/; do
    if [ -d "$epic_dir" ] && [ -f "${epic_dir}epic.md" ]; then
      epic_name=$(basename "$epic_dir")
      epic_file="${epic_dir}epic.md"
      
      # 提取Epic信息
      name=$(grep "^名称:" "$epic_file" | sed 's/^名称: *//')
      status=$(grep "^状态:" "$epic_file" | sed 's/^状态: *//')
      created=$(grep "^创建时间:" "$epic_file" | sed 's/^创建时间: *//')
      updated=$(grep "^最后更新:" "$epic_file" | sed 's/^最后更新: *//')
      description=$(grep "^描述:" "$epic_file" | sed 's/^描述: *//')
      
      # 统计任务情况
      total_tasks=$(find "$epic_dir" -name "*.md" ! -name "epic.md" | wc -l)
      completed_tasks=$(find "$epic_dir" -name "*.md" ! -name "epic.md" -exec grep -l "状态: 已完成" {} \; | wc -l)
      active_tasks=$(find "$epic_dir" -name "*.md" ! -name "epic.md" -exec grep -l "状态: 进行中" {} \; | wc -l)
      
      # 计算完成率
      completion_rate=0
      if [ $total_tasks -gt 0 ]; then
        completion_rate=$((completed_tasks * 100 / total_tasks))
      fi
      
      # 存储Epic数据
      epics_data+=("$epic_name|$name|$status|$created|$updated|$total_tasks|$completed_tasks|$active_tasks|$completion_rate|$description")
      ((total_epics++))
    fi
  done
  
  echo "📊 发现 $total_epics 个Epic执行计划"
  
  # 导出数据
  printf '%s\n' "${epics_data[@]}" > /tmp/dd_epics_data.txt
}
```

### 2. Epic筛选
```bash
# 根据选项筛选Epic
filter_epics() {
  local filter_option="$1"
  local epics_file="/tmp/dd_epics_data.txt"
  
  case "$filter_option" in
    "--backlog")
      grep "|backlog|" "$epics_file"
      ;;
    "--planning")
      grep "|规划中|" "$epics_file"
      ;;
    "--active")
      grep "|进行中|" "$epics_file"
      ;;
    "--completed")
      grep "|已完成|" "$epics_file"
      ;;
    "--all"|"")
      cat "$epics_file"
      ;;
  esac
}
```

### 3. 显示格式化

#### 表格视图（默认）
```bash
display_epic_table() {
  local filtered_epics="$1"
  local show_tasks="$2"
  
  echo "🎯 Epic执行计划列表"
  echo ""
  
  if [ "$show_tasks" == "true" ]; then
    printf "%-15s %-25s %-10s %-8s %-8s %-8s %-8s\n" "Epic标识" "计划名称" "状态" "总任务" "已完成" "进行中" "完成率"
    echo "$(printf '%.0s-' {1..90})"
  else
    printf "%-15s %-30s %-12s %-12s %-8s\n" "Epic标识" "计划名称" "状态" "创建时间" "完成率"
    echo "$(printf '%.0s-' {1..80})"
  fi
  
  echo "$filtered_epics" | while IFS='|' read -r epic_id name status created updated total_tasks completed_tasks active_tasks completion_rate description; do
    # 状态图标
    case "$status" in
      "backlog") status_icon="📋" ;;
      "规划中") status_icon="📝" ;;
      "进行中") status_icon="🔄" ;;
      "已完成") status_icon="✅" ;;
      *) status_icon="❓" ;;
    esac
    
    # 格式化日期
    created_date=$(echo $created | cut -d'T' -f1)
    
    if [ "$show_tasks" == "true" ]; then
      printf "%-15s %-25s %-10s %-8s %-8s %-8s %-8s\n" \
        "$epic_id" "$name" "$status_icon$status" "$total_tasks" "$completed_tasks" "$active_tasks" "${completion_rate}%"
    else
      printf "%-15s %-30s %-12s %-12s %-8s\n" \
        "$epic_id" "$name" "$status_icon$status" "$created_date" "${completion_rate}%"
    fi
  done
}
```

#### 详细视图
```bash
display_epic_detailed() {
  local filtered_epics="$1"
  
  echo "$filtered_epics" | while IFS='|' read -r epic_id name status created updated total_tasks completed_tasks active_tasks completion_rate description; do
    echo "🎯 Epic：$name"
    echo "   🆔 标识: $epic_id"
    echo "   📊 状态: $status"
    echo "   📅 创建: $(echo $created | cut -d'T' -f1)"
    echo "   🔄 更新: $(echo $updated | cut -d'T' -f1)"
    echo "   📋 任务: $total_tasks 个（已完成 $completed_tasks，进行中 $active_tasks）"
    echo "   📊 进度: ${completion_rate}%"
    echo "   💡 描述: $description"
    echo ""
  done
}
```

#### 摘要统计视图
```bash
display_epic_summary() {
  local filtered_epics="$1"
  local total_count=$(echo "$filtered_epics" | wc -l)
  
  # 按状态统计
  local backlog_count=$(echo "$filtered_epics" | grep "|backlog|" | wc -l)
  local planning_count=$(echo "$filtered_epics" | grep "|规划中|" | wc -l)
  local active_count=$(echo "$filtered_epics" | grep "|进行中|" | wc -l)
  local completed_count=$(echo "$filtered_epics" | grep "|已完成|" | wc -l)
  
  # 任务统计
  local total_tasks=0
  local total_completed=0
  local total_active=0
  
  echo "$filtered_epics" | while IFS='|' read -r epic_id name status created updated tasks completed active completion description; do
    total_tasks=$((total_tasks + tasks))
    total_completed=$((total_completed + completed))
    total_active=$((total_active + active))
  done
  
  echo "📊 Epic摘要统计"
  echo ""
  echo "📈 总体统计："
  echo "  🎯 Epic总数: $total_count"
  echo "  📋 包含任务: $total_tasks 个"
  echo "  ✅ 已完成任务: $total_completed 个"
  echo "  🔄 进行中任务: $total_active 个"
  
  if [ $total_tasks -gt 0 ]; then
    local overall_completion=$((total_completed * 100 / total_tasks))
    echo "  📊 整体完成率: ${overall_completion}%"
  fi
  
  echo ""
  echo "📊 Epic状态分布："
  echo "  📋 待开始: $backlog_count ($(calc_percentage $backlog_count $total_count)%)"
  echo "  📝 规划中: $planning_count ($(calc_percentage $planning_count $total_count)%)"
  echo "  🔄 进行中: $active_count ($(calc_percentage $active_count $total_count)%)"
  echo "  ✅ 已完成: $completed_count ($(calc_percentage $completed_count $total_count)%)"
}

calc_percentage() {
  local part=$1
  local total=$2
  if [ $total -eq 0 ]; then
    echo "0"
  else
    echo $((part * 100 / total))
  fi
}
```

### 4. 进度可视化
```bash
display_progress_bars() {
  local filtered_epics="$1"
  
  echo "📊 Epic执行进度："
  echo ""
  
  echo "$filtered_epics" | while IFS='|' read -r epic_id name status created updated total_tasks completed_tasks active_tasks completion_rate description; do
    # 创建进度条
    local bar_length=20
    local filled=$((completion_rate * bar_length / 100))
    local empty=$((bar_length - filled))
    
    local progress_bar=""
    for ((i=0; i<filled; i++)); do progress_bar+="█"; done
    for ((i=0; i<empty; i++)); do progress_bar+="░"; done
    
    printf "%-15s [%s] %3d%% (%d/%d)\n" "$epic_id" "$progress_bar" "$completion_rate" "$completed_tasks" "$total_tasks"
  done
}
```

## 输出格式示例

### 默认表格视图
```
🎯 Epic执行计划列表

Epic标识        计划名称                      状态        创建时间      完成率
--------------------------------------------------------------------------------
用户认证系统    用户登录注册技术实施          🔄进行中    2024-01-15    60%
支付系统        在线支付处理技术方案          📝规划中    2024-01-16    0%
订单管理        订单生命周期管理实施          📋backlog   2024-01-17    0%
```

### 包含任务的视图
```
🎯 Epic执行计划列表

Epic标识        计划名称                 状态      总任务  已完成  进行中  完成率
------------------------------------------------------------------------------------------
用户认证系统    用户登录注册技术实施    🔄进行中    5       3       2       60%
支付系统        在线支付处理技术方案    📝规划中    8       0       0       0%
```

### 摘要统计视图
```
📊 Epic摘要统计

📈 总体统计：
  🎯 Epic总数: 3
  📋 包含任务: 18 个
  ✅ 已完成任务: 8 个
  🔄 进行中任务: 3 个
  📊 整体完成率: 44%

📊 Epic状态分布：
  📋 待开始: 1 (33%)
  📝 规划中: 1 (33%)
  🔄 进行中: 1 (33%)
  ✅ 已完成: 0 (0%)
```

## 错误处理

### 无Epic情况
```markdown
ℹ️ 当前项目没有任何Epic执行计划

建议操作：
1. 先创建PRD: /dd:prd-new <功能名>
2. 转换为Epic: /dd:prd-parse <功能名>
3. 查看帮助: /dd:help epic-decompose
```

## 快捷操作

### 集成操作提示
```bash
display_quick_actions() {
  echo ""
  echo "🚀 快捷操作："
  echo "  📝 查看Epic详情: /dd:epic-show <Epic名>"
  echo "  🔧 分解为任务: /dd:epic-decompose <Epic名>"
  echo "  📋 查看任务列表: /dd:task-list --epic=<Epic名>"
  echo "  📊 查看项目状态: /dd:status"
}
```

## 使用示例

```bash
# 查看所有Epic
/dd:epic-list

# 查看进行中的Epic
/dd:epic-list --active

# 查看包含任务分解的详细信息
/dd:epic-list --with-tasks

# 查看摘要统计
/dd:epic-list --summary
```