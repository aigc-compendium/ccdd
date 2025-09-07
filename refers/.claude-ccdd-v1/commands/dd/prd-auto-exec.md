---
allowed-tools: Bash, Read, Write, LS, Task
---

# PRD自动完整执行

自动执行指定PRD的所有任务，按依赖关系顺序执行，直到PRD完全完成。

## 用法
```
/dd:prd-auto-exec <PRD名称>
```

## 执行流程

### 1. 验证PRD存在
```bash
prd_name="$ARGUMENTS"
epic_dir=".claude/epics/$prd_name"
epic_file="$epic_dir/epic.md"

if [ ! -f "$epic_file" ]; then
  echo "❌ PRD不存在：$prd_name"
  echo "💡 运行 /dd:epic-list 查看所有PRD"
  exit 1
fi

echo "🚀 开始PRD自动执行：$prd_name"
```

### 2. 扫描所有任务文件
```bash
# 获取所有任务文件
task_files=($(find "$epic_dir" -name "*.md" -not -name "epic.md" | sort))
if [ ${#task_files[@]} -eq 0 ]; then
  echo "❌ 没有找到任务文件"
  echo "💡 运行 /dd:epic-decompose $prd_name 创建任务"
  exit 1
fi

echo "📋 发现任务：${#task_files[@]} 个"
```

### 3. 创建执行上下文
```bash
mkdir -p .claude/context/prd-auto-mode
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > .claude/context/prd-auto-mode/config.md << EOF
---
mode: prd-auto-execution
prd_name: $prd_name
started: $current_time
current_task: null
completed_tasks: []
failed_tasks: []
max_cycles: 50
cycle_count: 0
---

# PRD自动执行模式配置

## PRD信息
- PRD名称: $prd_name
- 开始时间: $current_time
- 任务总数: ${#task_files[@]}

## 执行状态
- 当前任务: 待分配
- 已完成: 0
- 执行失败: 0
- 状态: 运行中
EOF
```

### 4. 任务依赖分析和排序
```yaml
Task:
  description: "分析任务依赖关系并排序"
  subagent_type: "general-purpose"
  prompt: |
    分析PRD "$prd_name" 的所有任务依赖关系，并生成执行顺序：
    
    任务文件列表：
    $(for file in "${task_files[@]}"; do
      task_id="$prd_name:$(basename "$file" .md)"
      echo "- $task_id: $file"
    done)
    
    分析要求：
    1. 读取每个任务文件的依赖字段
    2. 构建依赖图，检测循环依赖
    3. 使用拓扑排序生成执行顺序
    4. 识别可并行执行的任务组
    5. 输出执行计划
    
    输出格式：
    ```
    执行顺序：
    1. 第一批（可并行）：任务A, 任务B
    2. 第二批（可并行）：任务C
    3. 第三批（可并行）：任务D, 任务E
    ```
    
    将执行顺序保存到：.claude/context/prd-auto-mode/execution-plan.md
```

### 5. 主执行循环
```bash
execution_plan=".claude/context/prd-auto-mode/execution-plan.md"

echo "⚙️ 开始自动执行循环..."

cycle_count=0
max_cycles=50

while [ $cycle_count -lt $max_cycles ]; do
  cycle_count=$((cycle_count + 1))
  echo "🔄 执行周期 $cycle_count/$max_cycles"
  
  # 更新配置文件
  sed -i.bak "s/^cycle_count:.*/cycle_count: $cycle_count/" .claude/context/prd-auto-mode/config.md
  rm -f .claude/context/prd-auto-mode/config.md.bak
  
  # 检查是否还有未完成任务
  remaining_tasks=$(find_remaining_tasks "$prd_name")
  if [ -z "$remaining_tasks" ]; then
    echo "🎉 所有任务已完成！PRD执行完毕"
    break
  fi
  
  # 选择下一个可执行任务
  next_task=$(select_next_task "$prd_name" "$execution_plan")
  if [ -z "$next_task" ]; then
    echo "⚠️ 没有可执行的任务，可能存在依赖阻塞"
    echo "剩余任务：$remaining_tasks"
    break
  fi
  
  echo "▶️ 开始执行任务：$next_task"
  
  # 调用任务自动执行
  if execute_task_auto "$next_task"; then
    echo "✅ 任务完成：$next_task"
    mark_task_completed "$next_task"
  else
    echo "❌ 任务执行失败：$next_task"
    mark_task_failed "$next_task"
    
    # 询问用户是否继续
    echo "❓ 任务失败，是否继续执行其他任务？(y/N)"
    read -t 30 continue_choice
    if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
      echo "🛑 用户选择停止执行"
      break
    fi
  fi
  
done
```

### 6. 任务选择逻辑
```bash
# 查找剩余未完成任务
find_remaining_tasks() {
  local prd_name="$1"
  local remaining=""
  
  for file in "$epic_dir"/*.md; do
    [ "$file" = "$epic_dir/epic.md" ] && continue
    
    local task_id="$prd_name:$(basename "$file" .md)"
    local status=$(grep "^状态:" "$file" | sed 's/^状态: *//')
    
    if [ "$status" != "已完成" ]; then
      remaining="$remaining $task_id"
    fi
  done
  
  echo "$remaining"
}

# 选择下一个可执行任务
select_next_task() {
  local prd_name="$1"
  local execution_plan="$2"
  
  # 根据执行计划和依赖关系选择任务
  # 优先选择：
  # 1. 无依赖的任务
  # 2. 依赖已完成的任务
  # 3. 状态为"待开始"的任务
  
  for file in "$epic_dir"/*.md; do
    [ "$file" = "$epic_dir/epic.md" ] && continue
    
    local task_id="$prd_name:$(basename "$file" .md)"
    local status=$(grep "^状态:" "$file" | sed 's/^状态: *//')
    
    if [ "$status" = "待开始" ] && check_dependencies_ready "$task_id"; then
      echo "$task_id"
      return 0
    fi
  done
  
  # 没有找到可执行任务
  return 1
}

# 检查任务依赖是否就绪
check_dependencies_ready() {
  local task_id="$1"
  local prd_name="${task_id%%:*}"
  local task_num="${task_id##*:}"
  local task_file="$epic_dir/$task_num.md"
  
  local dependencies=$(grep "^依赖:" "$task_file" | sed 's/^依赖: *\[//; s/\]//' | tr ',' ' ')
  
  for dep in $dependencies; do
    dep=$(echo "$dep" | xargs)  # 去除空格
    local dep_prd="${dep%%:*}"
    local dep_num="${dep##*:}"
    local dep_file=".claude/epics/$dep_prd/$dep_num.md"
    
    if [ -f "$dep_file" ]; then
      local dep_status=$(grep "^状态:" "$dep_file" | sed 's/^状态: *//')
      if [ "$dep_status" != "已完成" ]; then
        return 1  # 依赖未完成
      fi
    fi
  done
  
  return 0  # 所有依赖已完成
}
```

### 7. 任务执行封装
```bash
# 执行单个任务
execute_task_auto() {
  local task_id="$1"
  
  echo "🤖 启动任务自动执行：$task_id"
  
  # 更新当前任务
  sed -i.bak "s/^current_task:.*/current_task: $task_id/" .claude/context/prd-auto-mode/config.md
  rm -f .claude/context/prd-auto-mode/config.md.bak
  
  # 调用现有的任务自动执行功能
  if /dd:task-start-auto "$task_id"; then
    echo "✅ 任务自动执行完成：$task_id"
    return 0
  else
    echo "❌ 任务自动执行失败：$task_id"
    return 1
  fi
}

# 标记任务完成
mark_task_completed() {
  local task_id="$1"
  local config_file=".claude/context/prd-auto-mode/config.md"
  
  # 添加到已完成列表
  sed -i.bak "s/^completed_tasks:.*/& $task_id/" "$config_file"
  rm -f "${config_file}.bak"
  
  echo "📝 任务已标记完成：$task_id"
}

# 标记任务失败
mark_task_failed() {
  local task_id="$1"
  local config_file=".claude/context/prd-auto-mode/config.md"
  
  # 添加到失败列表
  sed -i.bak "s/^failed_tasks:.*/& $task_id/" "$config_file"
  rm -f "${config_file}.bak"
  
  echo "❌ 任务已标记失败：$task_id"
}
```

### 8. 执行监控和报告
```bash
echo ""
echo "🏁 PRD自动执行完成：$prd_name"
echo ""
echo "📊 执行统计："

# 统计结果
completed_count=$(grep "^completed_tasks:" .claude/context/prd-auto-mode/config.md | wc -w)
failed_count=$(grep "^failed_tasks:" .claude/context/prd-auto-mode/config.md | wc -w)
total_tasks=${#task_files[@]}

echo "  - 总任务数：$total_tasks"
echo "  - 已完成：$completed_count"
echo "  - 执行失败：$failed_count"
echo "  - 成功率：$(( (completed_count * 100) / total_tasks ))%"
echo "  - 执行周期：$cycle_count"

echo ""
echo "🎯 执行结果："
if [ $failed_count -eq 0 ]; then
  echo "  ✅ PRD完全执行成功"
else
  echo "  ⚠️ 部分任务执行失败，需要人工干预"
fi

echo ""
echo "📁 执行日志："
echo "  - 配置文件：.claude/context/prd-auto-mode/config.md"
echo "  - 执行计划：.claude/context/prd-auto-mode/execution-plan.md"

echo ""
echo "🎯 建议的下一步操作："
if [ $failed_count -eq 0 ]; then
  echo "  • 代码评审：/dd:code-reflect"
  echo "  • 更新上下文：/dd:ctx-sync"
  echo "  • 查看PRD状态：/dd:epic-show $prd_name"
else
  echo "  • 检查失败任务：查看任务日志"
  echo "  • 手动执行失败任务：/dd:task-start <任务ID>"
  echo "  • 恢复自动执行：/dd:prd-auto-exec $prd_name"
fi
```

### 9. 清理和状态保存
```bash
# 更新PRD状态
if [ $failed_count -eq 0 ]; then
  # 如果所有任务都完成，更新Epic状态
  current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "" >> "$epic_file"
  echo "## 自动执行完成 - $current_time" >> "$epic_file"
  echo "- 执行模式：PRD自动执行" >> "$epic_file"
  echo "- 总任务数：$total_tasks" >> "$epic_file"
  echo "- 执行周期：$cycle_count" >> "$epic_file"
  echo "- 状态：已完成" >> "$epic_file"
fi
```

## 关键特性

### 智能依赖管理
- 自动解析任务依赖关系
- 拓扑排序确定执行顺序
- 循环依赖检测和报错
- 支持并行任务识别

### 强大的执行引擎
- 调用现有task-start-auto功能
- 任务失败时智能暂停
- 用户干预选项
- 执行进度实时监控

### 完整的状态管理
- 执行上下文持久化
- 任务完成状态跟踪
- 详细执行统计报告
- 失败任务记录和恢复

### 安全保障
- 最大执行周期限制
- 用户确认机制
- 执行日志完整保存
- 支持中途暂停和恢复