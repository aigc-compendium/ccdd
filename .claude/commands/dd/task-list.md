---
allowed-tools: Read, LS, Grep
---

# 任务列表管理

显示和管理项目中的任务列表，支持多种视图和筛选方式。

## 用法
```
/dd:task-list [选项]
```

## 选项参数
- `--all` - 显示所有任务（默认）
- `--pending` - 只显示待开始的任务
- `--active` - 只显示进行中的任务
- `--completed` - 只显示已完成的任务
- `--blocked` - 只显示被阻塞的任务
- `--priority=高|中|低` - 按优先级筛选
- `--epic=<epic_name>` - 只显示指定Epic的任务
- `--assignable` - 显示可以立即开始的任务（依赖已满足）
- `--tree` - 以树形结构显示（包含依赖关系）
- `--summary` - 显示摘要统计信息

## 操作指南

### 1. 收集所有任务信息

```bash
# 扫描所有Epic目录，收集任务信息
collect_all_tasks() {
  local tasks_data=()
  local epic_count=0
  local total_tasks=0
  
  echo "🔍 扫描所有任务..."
  
  for epic_dir in .claude/epics/*/; do
    if [ -d "$epic_dir" ]; then
      epic_name=$(basename "$epic_dir")
      ((epic_count++))
      
      # 扫描Epic中的任务文件
      for task_file in "$epic_dir"*.md; do
        if [[ "$task_file" != *"epic.md" ]] && [ -f "$task_file" ]; then
          task_id=$(basename "$task_file" .md)
          
          # 提取任务信息
          task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
          task_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
          task_priority=$(grep "^优先级:" "$task_file" | sed 's/^优先级: *//')
          task_effort=$(grep "^预估工作量:" "$task_file" | sed 's/^预估工作量: *//')
          task_parallel=$(grep "^并行:" "$task_file" | sed 's/^并行: *//')
          task_dependencies=$(grep "^依赖:" "$task_file" | sed 's/^依赖: *\[//; s/\]//' | tr ',' ' ')
          task_created=$(grep "^创建时间:" "$task_file" | sed 's/^创建时间: *//')
          task_updated=$(grep "^最后更新:" "$task_file" | sed 's/^最后更新: *//')
          
          # 存储任务数据
          tasks_data+=("$epic_name|$task_id|$task_name|$task_status|$task_priority|$task_effort|$task_parallel|$task_dependencies|$task_created|$task_updated")
          ((total_tasks++))
        fi
      done
    fi
  done
  
  echo "📊 发现 $epic_count 个Epic，共 $total_tasks 个任务"
  
  # 导出数据供后续处理
  printf '%s\n' "${tasks_data[@]}" > /tmp/dd_tasks_data.txt
}
```

### 2. 任务筛选和排序

```bash
# 根据选项筛选任务
filter_tasks() {
  local filter_option="$1"
  local tasks_file="/tmp/dd_tasks_data.txt"
  
  case "$filter_option" in
    "--pending")
      grep "|待开始|" "$tasks_file"
      ;;
    "--active") 
      grep "|进行中|" "$tasks_file"
      ;;
    "--completed")
      grep "|已完成|" "$tasks_file"
      ;;
    "--blocked")
      grep "|阻塞|" "$tasks_file"
      ;;
    "--priority=高")
      grep "|高|" "$tasks_file"
      ;;
    "--priority=中")
      grep "|中|" "$tasks_file"  
      ;;
    "--priority=低")
      grep "|低|" "$tasks_file"
      ;;
    "--epic="*)
      local epic_name="${filter_option#--epic=}"
      grep "^$epic_name|" "$tasks_file"
      ;;
    "--assignable")
      # 找出依赖已满足的待开始任务
      while IFS='|' read -r epic task_id task_name status priority effort parallel deps created updated; do
        if [ "$status" == "待开始" ]; then
          # 检查依赖是否都已完成
          local can_start=true
          if [ -n "$deps" ] && [ "$deps" != " " ]; then
            for dep in $deps; do
              dep_status=$(grep "|$dep|" "$tasks_file" | cut -d'|' -f4)
              if [ "$dep_status" != "已完成" ]; then
                can_start=false
                break
              fi
            done
          fi
          
          if [ "$can_start" == "true" ]; then
            echo "$epic|$task_id|$task_name|$status|$priority|$effort|$parallel|$deps|$created|$updated"
          fi
        fi
      done < "$tasks_file"
      ;;
    "--all"|"")
      cat "$tasks_file"
      ;;
  esac
}
```

### 3. 显示格式化

#### 表格视图（默认）
```bash
display_table_view() {
  local filtered_tasks="$1"
  
  echo "📋 任务列表"
  echo ""
  printf "%-12s %-8s %-30s %-8s %-6s %-8s %-6s\n" "Epic" "ID" "任务名称" "状态" "优先级" "工作量" "并行"
  echo "$(printf '%.0s-' {1..80})"
  
  echo "$filtered_tasks" | while IFS='|' read -r epic task_id task_name status priority effort parallel deps created updated; do
    # 状态图标
    case "$status" in
      "待开始") status_icon="⏳" ;;
      "进行中") status_icon="🔄" ;;
      "已完成") status_icon="✅" ;;
      "阻塞") status_icon="🚫" ;;
      *) status_icon="❓" ;;
    esac
    
    # 优先级颜色（文本标记）
    case "$priority" in
      "高") priority_display="🔴$priority" ;;
      "中") priority_display="🟡$priority" ;;
      "低") priority_display="🟢$priority" ;;
      *) priority_display="⚪$priority" ;;
    esac
    
    # 截断长任务名
    if [ ${#task_name} -gt 28 ]; then
      task_name="${task_name:0:25}..."
    fi
    
    printf "%-12s %-8s %-30s %-8s %-6s %-8s %-6s\n" \
      "$epic" "$task_id" "$task_name" "$status_icon$status" "$priority_display" "$effort" "$parallel"
  done
}
```

#### 详细视图
```bash
display_detailed_view() {
  local filtered_tasks="$1"
  
  echo "$filtered_tasks" | while IFS='|' read -r epic task_id task_name status priority effort parallel deps created updated; do
    echo "📋 任务：$task_name"
    echo "   🆔 ID: $task_id"
    echo "   📁 Epic: $epic"
    echo "   📊 状态: $status"
    echo "   🎯 优先级: $priority"
    echo "   ⏰ 预估: ${effort:-未设置}"
    echo "   🔄 并行: $parallel"
    
    if [ -n "$deps" ] && [ "$deps" != " " ]; then
      echo "   🔗 依赖: $deps"
    fi
    
    echo "   📅 创建: $(echo $created | cut -d'T' -f1)"
    echo "   🔄 更新: $(echo $updated | cut -d'T' -f1)"
    echo ""
  done
}
```

#### 树形视图
```bash
display_tree_view() {
  local filtered_tasks="$1"
  
  echo "🌳 任务依赖树"
  echo ""
  
  # 构建依赖关系图
  local processed_tasks=()
  
  # 先显示没有依赖的任务（根节点）
  echo "$filtered_tasks" | while IFS='|' read -r epic task_id task_name status priority effort parallel deps created updated; do
    if [ -z "$deps" ] || [ "$deps" == " " ]; then
      echo "📦 $task_name ($task_id) [$status]"
      processed_tasks+=("$task_id")
      
      # 查找依赖此任务的子任务
      display_children "$task_id" "$filtered_tasks" "  "
    fi
  done
}

display_children() {
  local parent_id="$1"
  local all_tasks="$2" 
  local indent="$3"
  
  echo "$all_tasks" | while IFS='|' read -r epic task_id task_name status priority effort parallel deps created updated; do
    if [[ "$deps" == *"$parent_id"* ]]; then
      echo "${indent}└── 📋 $task_name ($task_id) [$status]"
      display_children "$task_id" "$all_tasks" "$indent  "
    fi
  done
}
```

### 4. 摘要统计

```bash
display_summary() {
  local filtered_tasks="$1"
  local total_count=$(echo "$filtered_tasks" | wc -l)
  
  # 按状态统计
  local pending_count=$(echo "$filtered_tasks" | grep "|待开始|" | wc -l)
  local active_count=$(echo "$filtered_tasks" | grep "|进行中|" | wc -l)
  local completed_count=$(echo "$filtered_tasks" | grep "|已完成|" | wc -l)
  local blocked_count=$(echo "$filtered_tasks" | grep "|阻塞|" | wc -l)
  
  # 按优先级统计
  local high_priority=$(echo "$filtered_tasks" | grep "|高|" | wc -l)
  local medium_priority=$(echo "$filtered_tasks" | grep "|中|" | wc -l)
  local low_priority=$(echo "$filtered_tasks" | grep "|低|" | wc -l)
  
  # 按Epic统计
  local epics_with_tasks=$(echo "$filtered_tasks" | cut -d'|' -f1 | sort | uniq | wc -l)
  
  # 工作量统计
  local total_effort=0
  local completed_effort=0
  
  echo "$filtered_tasks" | while IFS='|' read -r epic task_id task_name status priority effort parallel deps created updated; do
    if [[ "$effort" =~ ^[0-9]+$ ]]; then
      total_effort=$((total_effort + effort))
      if [ "$status" == "已完成" ]; then
        completed_effort=$((completed_effort + effort))
      fi
    fi
  done
  
  echo "📊 任务摘要统计"
  echo ""
  echo "📈 总体统计："
  echo "  📁 涉及Epic数: $epics_with_tasks"
  echo "  📋 任务总数: $total_count"
  echo "  ⏰ 总工作量: ${total_effort}小时"
  echo "  ✅ 已完成工作量: ${completed_effort}小时"
  
  if [ $total_effort -gt 0 ]; then
    local completion_rate=$((completed_effort * 100 / total_effort))
    echo "  📊 完成率: ${completion_rate}%"
  fi
  
  echo ""
  echo "📊 状态分布："
  echo "  ⏳ 待开始: $pending_count ($(calc_percentage $pending_count $total_count)%)"
  echo "  🔄 进行中: $active_count ($(calc_percentage $active_count $total_count)%)"
  echo "  ✅ 已完成: $completed_count ($(calc_percentage $completed_count $total_count)%)"
  echo "  🚫 阻塞: $blocked_count ($(calc_percentage $blocked_count $total_count)%)"
  
  echo ""
  echo "🎯 优先级分布："
  echo "  🔴 高优先级: $high_priority"
  echo "  🟡 中优先级: $medium_priority" 
  echo "  🟢 低优先级: $low_priority"
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

### 5. 可操作任务识别

```bash
identify_actionable_tasks() {
  local tasks_file="/tmp/dd_tasks_data.txt"
  
  echo "🎯 可立即执行的任务："
  echo ""
  
  local actionable_count=0
  
  while IFS='|' read -r epic task_id task_name status priority effort parallel deps created updated; do
    if [ "$status" == "待开始" ]; then
      # 检查依赖
      local can_start=true
      local dependency_status=""
      
      if [ -n "$deps" ] && [ "$deps" != " " ]; then
        local dep_list=""
        for dep in $deps; do
          dep_status=$(grep "|$dep|" "$tasks_file" | cut -d'|' -f4)
          dep_name=$(grep "|$dep|" "$tasks_file" | cut -d'|' -f3)
          
          if [ "$dep_status" != "已完成" ]; then
            can_start=false
            dep_list="$dep_list $dep($dep_status)"
          fi
        done
        dependency_status="依赖: $dep_list"
      fi
      
      if [ "$can_start" == "true" ]; then
        echo "✅ $task_name ($task_id)"
        echo "   📁 Epic: $epic"
        echo "   🎯 优先级: $priority"
        echo "   ⏰ 预估工作量: ${effort:-未设置}"
        echo "   💡 可立即开始: /dd:task-start $task_id"
        echo ""
        ((actionable_count++))
      else
        echo "⏳ $task_name ($task_id) - 等待依赖"
        echo "   📁 Epic: $epic"
        echo "   🔗 $dependency_status"
        echo ""
      fi
    fi
  done < "$tasks_file"
  
  echo "📋 可立即开始的任务: $actionable_count 个"
}
```

## 输出格式示例

### 默认表格视图
```
📋 任务列表

Epic         ID       任务名称                        状态    优先级  工作量   并行
--------------------------------------------------------------------------------
用户认证      001      实现用户登录API                🔄进行中  🔴高     4小时   true
用户认证      002      设计用户数据库表               ✅已完成  🟡中     2小时   true  
用户认证      003      实现JWT令牌验证               ⏳待开始  🔴高     3小时   false
支付系统      004      集成支付网关                   ⏳待开始  🟡中     6小时   true
```

### 摘要统计视图
```
📊 任务摘要统计

📈 总体统计：
  📁 涉及Epic数: 3
  📋 任务总数: 12
  ⏰ 总工作量: 45小时
  ✅ 已完成工作量: 18小时
  📊 完成率: 40%

📊 状态分布：
  ⏳ 待开始: 6 (50%)
  🔄 进行中: 2 (17%)
  ✅ 已完成: 4 (33%)
  🚫 阻塞: 0 (0%)

🎯 优先级分布：
  🔴 高优先级: 4
  🟡 中优先级: 6
  🟢 低优先级: 2
```

### 可操作任务视图
```
🎯 可立即执行的任务：

✅ 实现JWT令牌验证 (003)
   📁 Epic: 用户认证
   🎯 优先级: 高
   ⏰ 预估工作量: 3小时
   💡 可立即开始: /dd:task-start 003

✅ 集成支付网关 (004)
   📁 Epic: 支付系统
   🎯 优先级: 中
   ⏰ 预估工作量: 6小时
   💡 可立即开始: /dd:task-start 004

📋 可立即开始的任务: 2 个
```

## 错误处理

### 无任务情况
```markdown
ℹ️ 当前项目没有任何任务

建议操作：
1. 创建产品需求: /dd:prd-new <功能名>
2. 生成技术方案: /dd:prd-parse <功能名>
3. 分解具体任务: /dd:epic-decompose <功能名>
```

### 筛选无结果
```markdown
🔍 没有找到符合条件的任务

筛选条件: {显示当前筛选条件}

建议操作：
- 调整筛选条件
- 运行 /dd:task-list --all 查看所有任务
- 检查任务状态是否正确
```

## 快捷操作

### 集成其他命令
```bash
# 在列表中显示快捷操作提示
display_quick_actions() {
  echo ""
  echo "🚀 快捷操作："
  echo "  📋 查看详细状态: /dd:task-status <任务ID>"
  echo "  ▶️ 开始执行任务: /dd:task-start <任务ID>"
  echo "  📊 查看项目概览: /dd:status"
  echo "  🔍 查看Epic详情: /dd:epic-show <Epic名称>"
}
```

### 智能建议
```bash
provide_intelligent_suggestions() {
  local active_tasks=$(grep "|进行中|" /tmp/dd_tasks_data.txt | wc -l)
  local actionable_tasks=$(filter_tasks "--assignable" | wc -l)
  local blocked_tasks=$(grep "|阻塞|" /tmp/dd_tasks_data.txt | wc -l)
  
  echo ""
  echo "💡 智能建议："
  
  if [ $active_tasks -eq 0 ] && [ $actionable_tasks -gt 0 ]; then
    echo "  🎯 没有进行中的任务，建议开始一个新任务"
    echo "  📋 有 $actionable_tasks 个任务可以立即开始"
  elif [ $active_tasks -gt 2 ]; then
    echo "  ⚠️ 同时进行 $active_tasks 个任务，建议专注完成当前任务"
  fi
  
  if [ $blocked_tasks -gt 0 ]; then
    echo "  🚫 有 $blocked_tasks 个任务被阻塞，建议优先解决阻塞问题"
  fi
}
```

## 使用示例

### 常用命令组合
```bash
# 查看所有任务
/dd:task-list

# 查看可以开始的任务
/dd:task-list --assignable

# 查看高优先级待开始任务
/dd:task-list --pending --priority=高

# 查看指定Epic的任务
/dd:task-list --epic=用户认证

# 查看任务统计
/dd:task-list --summary

# 查看依赖关系
/dd:task-list --tree
```