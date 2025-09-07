---
allowed-tools: Bash
---

Run `bash .claude/scripts/dd/task-set.sh` using a sub-agent and show me the complete output.

- DO NOT truncate.
- DO NOT collapse. 
- DO NOT abbreviate.
- Show ALL lines in full.
- DO NOT print any other comments.
validate_task_id() {
  local task_id="$1"
  
  if [ -z "$task_id" ]; then
    echo "❌ 缺少任务ID参数"
    echo "💡 用法：/dd:task-manage <任务ID> <操作> [参数]"
    return 1
  fi
  
  # 解析任务ID格式：prd_name:task_num
  if [[ "$task_id" != *:* ]]; then
    echo "❌ 任务ID格式错误，应为：<PRD名称>:<任务编号>"
    echo "示例：用户认证系统:001"
    return 1
  fi
  
  local prd_name="${task_id%%:*}"
  local task_num="${task_id##*:}"
  local task_file=".claude/epics/$prd_name/$task_num.md"
  
  if [ ! -f "$task_file" ]; then
    echo "❌ 任务不存在：$task_file"
    echo "💡 运行 /dd:task-list 查看所有任务"
    return 1
  fi
  
  echo "$task_file"
  return 0
}

# 验证操作参数
validate_operation() {
  local operation="$1"
  local valid_ops=("set-status" "set-priority" "add-dependency" "remove-dependency" "clear-dependencies" "set-effort" "set-parallel" "add-note")
  
  for valid_op in "${valid_ops[@]}"; do
    if [ "$operation" == "$valid_op" ]; then
      return 0
    fi
  done
  
  echo "❌ 无效操作：$operation"
  echo "💡 支持的操作：${valid_ops[*]}"
  return 1
}
```

### 2. 状态管理操作

```bash
# 更新任务状态
set_task_status() {
  local task_file="$1"
  local new_status="$2"
  local task_id=$(basename "$task_file" .md)
  local task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
  
  # 验证状态值
  local valid_statuses=("待开始" "进行中" "已完成" "阻塞")
  local status_valid=false
  
  for valid_status in "${valid_statuses[@]}"; do
    if [ "$new_status" == "$valid_status" ]; then
      status_valid=true
      break
    fi
  done
  
  if [ "$status_valid" == "false" ]; then
    echo "❌ 无效状态：$new_status"
    echo "💡 有效状态：${valid_statuses[*]}"
    return 1
  fi
  
  # 获取当前状态
  local current_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
  
  if [ "$current_status" == "$new_status" ]; then
    echo "ℹ️ 任务 $task_id 状态已经是：$new_status"
    return 0
  fi
  
  # 状态变更验证
  validate_status_transition "$current_status" "$new_status" "$task_id"
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  # 更新状态
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  sed -i.bak "s/^状态:.*/状态: $new_status/" "$task_file"
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  
  # 如果标记为已完成，添加完成时间
  if [ "$new_status" == "已完成" ] && ! grep -q "^完成时间:" "$task_file"; then
    sed -i.bak "/^最后更新:/a\\
完成时间: $current_time" "$task_file"
  fi
  
  rm "${task_file}.bak"
  
  echo "✅ 任务 $task_id ($task_name) 状态已更新：$current_status → $new_status"
  
  # 检查依赖影响
  check_dependency_impact "$task_id" "$new_status"
}

# 验证状态转换的合理性
validate_status_transition() {
  local current_status="$1"
  local new_status="$2"
  local task_id="$3"
  
  # 检查不合理的状态转换
  if [ "$current_status" == "已完成" ] && [ "$new_status" != "已完成" ]; then
    echo "⚠️ 要将已完成的任务改为其他状态，请确认："
    echo "  任务：$task_id"
    echo "  变更：$current_status → $new_status"
    echo "  确认继续？(是/否)"
    # 在实际实现中需要用户确认
  fi
  
  return 0
}
```

### 3. 优先级管理

```bash
# 设置任务优先级
set_task_priority() {
  local task_file="$1"
  local new_priority="$2"
  local task_id=$(basename "$task_file" .md)
  
  # 验证优先级值
  local valid_priorities=("高" "中" "低")
  local priority_valid=false
  
  for valid_priority in "${valid_priorities[@]}"; do
    if [ "$new_priority" == "$valid_priority" ]; then
      priority_valid=true
      break
    fi
  done
  
  if [ "$priority_valid" == "false" ]; then
    echo "❌ 无效优先级：$new_priority"
    echo "💡 有效优先级：${valid_priorities[*]}"
    return 1
  fi
  
  # 更新优先级
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  if grep -q "^优先级:" "$task_file"; then
    sed -i.bak "s/^优先级:.*/优先级: $new_priority/" "$task_file"
  else
    sed -i.bak "/^状态:/a\\
优先级: $new_priority" "$task_file"
  fi
  
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 任务 $task_id 优先级已设置为：$new_priority"
}
```

### 4. 依赖关系管理

```bash
# 添加任务依赖
add_task_dependency() {
  local task_file="$1" 
  local dependencies="$2"  # 逗号分隔的任务ID列表
  local task_id=$(basename "$task_file" .md)
  
  # 验证依赖任务是否存在
  IFS=',' read -ra dep_array <<< "$dependencies"
  for dep in "${dep_array[@]}"; do
    dep=$(echo "$dep" | xargs)  # 去除空白
    if [ ! -f ".claude/epics/*/$dep.md" ]; then
      local dep_file=$(find .claude/epics -name "$dep.md" | head -1)
      if [ ! -f "$dep_file" ]; then
        echo "❌ 依赖任务不存在：$dep"
        return 1
      fi
    fi
    
    # 检查循环依赖
    if check_circular_dependency "$task_id" "$dep"; then
      echo "❌ 检测到循环依赖：$task_id ↔ $dep"
      return 1
    fi
  done
  
  # 获取现有依赖
  local current_deps=""
  if grep -q "^依赖:" "$task_file"; then
    current_deps=$(grep "^依赖:" "$task_file" | sed 's/^依赖: *\[//; s/\]//')
  fi
  
  # 合并依赖（避免重复）
  local all_deps="$current_deps"
  for dep in "${dep_array[@]}"; do
    dep=$(echo "$dep" | xargs)
    if [[ ",$all_deps," != *",$dep,"* ]]; then
      if [ -n "$all_deps" ]; then
        all_deps="$all_deps, $dep"
      else
        all_deps="$dep"
      fi
    fi
  done
  
  # 更新依赖
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  if grep -q "^依赖:" "$task_file"; then
    sed -i.bak "s/^依赖:.*/依赖: [$all_deps]/" "$task_file"
  else
    sed -i.bak "/^并行:/a\\
依赖: [$all_deps]" "$task_file"
  fi
  
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 任务 $task_id 依赖已更新：[$all_deps]"
}

# 检查循环依赖
check_circular_dependency() {
  local task_id="$1"
  local dep_id="$2"
  local visited=("$task_id")
  
  check_dependency_chain "$dep_id" visited[@]
}

check_dependency_chain() {
  local current_task="$1"
  local -n visited_ref=$2
  
  # 检查是否已访问过（循环）
  for visited_task in "${visited_ref[@]}"; do
    if [ "$current_task" == "$visited_task" ]; then
      return 0  # 发现循环
    fi
  done
  
  # 添加到已访问列表
  visited_ref+=("$current_task")
  
  # 检查当前任务的依赖
  # 解析任务ID格式：prd_name:task_num
  local prd_name="${current_task%%:*}"
  local task_num="${current_task##*:}"
  local task_file=".claude/epics/$prd_name/$task_num.md"
  if [ -f "$task_file" ]; then
    local task_deps=$(grep "^依赖:" "$task_file" | sed 's/^依赖: *\[//; s/\]//' | tr ',' ' ')
    for dep in $task_deps; do
      dep=$(echo "$dep" | xargs)
      if check_dependency_chain "$dep" visited_ref; then
        return 0  # 发现循环
      fi
    done
  fi
  
  return 1  # 未发现循环
}

# 移除任务依赖
remove_task_dependency() {
  local task_file="$1"
  local dep_to_remove="$2"
  local task_id=$(basename "$task_file" .md)
  
  # 获取现有依赖
  if ! grep -q "^依赖:" "$task_file"; then
    echo "ℹ️ 任务 $task_id 没有依赖关系"
    return 0
  fi
  
  local current_deps=$(grep "^依赖:" "$task_file" | sed 's/^依赖: *\[//; s/\]//')
  
  # 移除指定依赖
  local new_deps=$(echo "$current_deps" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v "^$dep_to_remove$" | tr '\n' ',' | sed 's/,$//')
  
  # 更新依赖
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  if [ -n "$new_deps" ]; then
    sed -i.bak "s/^依赖:.*/依赖: [$new_deps]/" "$task_file"
  else
    sed -i.bak "/^依赖:/d" "$task_file"
  fi
  
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 已从任务 $task_id 中移除依赖：$dep_to_remove"
}

# 清除所有依赖
clear_task_dependencies() {
  local task_file="$1"
  local task_id=$(basename "$task_file" .md)
  
  if ! grep -q "^依赖:" "$task_file"; then
    echo "ℹ️ 任务 $task_id 没有依赖关系"
    return 0
  fi
  
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  sed -i.bak "/^依赖:/d" "$task_file"
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 任务 $task_id 的所有依赖已清除"
}
```

### 5. 其他属性管理

```bash
# 设置工作量估算
set_task_effort() {
  local task_file="$1"
  local effort="$2"
  local task_id=$(basename "$task_file" .md)
  
  # 验证工作量格式
  if [[ ! "$effort" =~ ^[0-9]+[小时]*$ ]]; then
    echo "❌ 工作量格式错误：$effort"
    echo "💡 正确格式：3小时 或 3"
    return 1
  fi
  
  # 标准化格式
  effort=$(echo "$effort" | sed 's/小时$//')
  if [[ "$effort" =~ ^[0-9]+$ ]]; then
    effort="${effort}小时"
  fi
  
  # 更新工作量
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  if grep -q "^预估工作量:" "$task_file"; then
    sed -i.bak "s/^预估工作量:.*/预估工作量: $effort/" "$task_file"
  else
    sed -i.bak "/^优先级:/a\\
预估工作量: $effort" "$task_file"
  fi
  
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 任务 $task_id 工作量已设置为：$effort"
}

# 设置并行执行标志
set_task_parallel() {
  local task_file="$1"
  local parallel="$2"
  local task_id=$(basename "$task_file" .md)
  
  # 验证并行值
  if [ "$parallel" != "true" ] && [ "$parallel" != "false" ]; then
    echo "❌ 无效的并行值：$parallel"
    echo "💡 有效值：true 或 false"
    return 1
  fi
  
  # 更新并行标志
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  if grep -q "^并行:" "$task_file"; then
    sed -i.bak "s/^并行:.*/并行: $parallel/" "$task_file"
  else
    sed -i.bak "/^预估工作量:/a\\
并行: $parallel" "$task_file"
  fi
  
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 任务 $task_id 并行执行已设置为：$parallel"
}

# 添加任务笔记
add_task_note() {
  local task_file="$1"
  local note="$2"
  local task_id=$(basename "$task_file" .md)
  
  if [ -z "$note" ]; then
    echo "❌ 笔记内容不能为空"
    return 1
  fi
  
  # 添加笔记到任务文件末尾
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  cat >> "$task_file" << EOF

## 管理笔记 - $current_time
$note
EOF
  
  # 更新时间戳
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 已为任务 $task_id 添加笔记"
}
```

### 6. 影响分析

```bash
# 检查状态变更对依赖任务的影响
check_dependency_impact() {
  local task_id="$1"
  local new_status="$2"
  
  if [ "$new_status" == "已完成" ]; then
    # 查找依赖此任务的其他任务
    local dependent_tasks=$(find .claude/epics -name "*.md" -exec grep -l "依赖:.*$task_id" {} \;)
    
    if [ -n "$dependent_tasks" ]; then
      echo ""
      echo "📌 任务 $task_id 完成后，以下任务现在可以开始："
      echo "$dependent_tasks" | while read task_file; do
        local dep_task_id=$(basename "$task_file" .md)
        local dep_task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
        local dep_task_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
        
        if [ "$dep_task_status" == "待开始" ]; then
          # 检查所有依赖是否都已完成
          local all_deps_complete=true
          local task_deps=$(grep "^依赖:" "$task_file" | sed 's/^依赖: *\[//; s/\]//' | tr ',' ' ')
          
          for dep in $task_deps; do
            dep=$(echo "$dep" | xargs)
            local dep_file=$(find .claude/epics -name "$dep.md" | head -1)
            if [ -f "$dep_file" ]; then
              local dep_status=$(grep "^状态:" "$dep_file" | sed 's/^状态: *//')
              if [ "$dep_status" != "已完成" ]; then
                all_deps_complete=false
                break
              fi
            fi
          done
          
          if [ "$all_deps_complete" == "true" ]; then
            echo "  ✅ $dep_task_name ($dep_task_id) - 可立即开始"
          else
            echo "  ⏳ $dep_task_name ($dep_task_id) - 仍有其他依赖"
          fi
        fi
      done
    fi
  fi
}

# 分析任务管理操作的整体影响
analyze_management_impact() {
  local task_id="$1"
  local operation="$2"
  local new_value="$3"
  
  echo ""
  echo "📊 操作影响分析："
  
  case "$operation" in
    "set-status")
      if [ "$new_value" == "阻塞" ]; then
        echo "  ⚠️ 任务被阻塞可能影响项目进度"
        echo "  💡 建议及时解决阻塞问题"
      elif [ "$new_value" == "已完成" ]; then
        echo "  🎉 任务完成，检查是否解锁了其他任务"
      fi
      ;;
    "set-priority")
      echo "  🎯 优先级调整可能影响任务执行顺序"
      echo "  💡 建议重新评估任务计划"
      ;;
    "add-dependency")
      echo "  🔗 新增依赖可能延长任务开始时间"
      echo "  💡 确认依赖的合理性和必要性"
      ;;
  esac
}
```

## 命令执行流程

### 主命令处理
```bash
# 主命令入口
handle_task_manage_command() {
  local task_id="$1"
  local operation="$2"
  local parameter="$3"
  
  # 验证参数
  local task_file=$(validate_task_id "$task_id")
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  if ! validate_operation "$operation"; then
    return 1
  fi
  
  # 执行操作
  case "$operation" in
    "set-status")
      set_task_status "$task_file" "$parameter"
      ;;
    "set-priority")
      set_task_priority "$task_file" "$parameter"
      ;;
    "add-dependency")
      add_task_dependency "$task_file" "$parameter"
      ;;
    "remove-dependency")
      remove_task_dependency "$task_file" "$parameter"
      ;;
    "clear-dependencies")
      clear_task_dependencies "$task_file"
      ;;
    "set-effort")
      set_task_effort "$task_file" "$parameter"
      ;;
    "set-parallel")
      set_task_parallel "$task_file" "$parameter"
      ;;
    "add-note")
      add_task_note "$task_file" "$parameter"
      ;;
  esac
  
  # 分析影响
  analyze_management_impact "$task_id" "$operation" "$parameter"
}
```

## 输出格式

### 操作成功确认
```markdown
✅ 任务管理操作完成

📋 任务信息：
  - 任务ID：001
  - 任务名称：实现用户登录API
  - 操作类型：状态变更
  - 变更内容：待开始 → 进行中
  - 操作时间：2024-01-01T10:30:00Z

📊 操作影响分析：
  🎯 任务状态变更为进行中
  💡 建议专注完成当前任务
  
🔄 相关任务：
  - 任务002依赖此任务，仍需等待完成
  - 任务003可以并行执行
```

### 批量操作确认
```markdown
✅ 批量任务管理完成

📊 操作摘要：
  - 处理任务：3个
  - 成功操作：3个  
  - 失败操作：0个
  - 操作时间：2024-01-01T10:30:00Z

📋 操作详情：
  ✅ 任务001：状态 → 已完成
  ✅ 任务002：优先级 → 高
  ✅ 任务003：依赖 → [001, 002]
```

## 安全和约束

### 操作限制
```bash
# 检查操作权限和安全性
check_operation_safety() {
  local operation="$1"
  local task_id="$2"
  
  # 检查是否违反绝对规则
  if [ "$operation" == "delete-task" ]; then
    echo "❌ 删除任务操作被绝对规则禁止"
    echo "💡 请手动操作或联系管理员"
    return 1
  fi
  
  # 其他安全检查...
  return 0
}
```

### 数据完整性
- 所有操作都更新时间戳
- 保持前置元数据格式一致
- 验证依赖关系的有效性
- 防止循环依赖的产生

这个任务管理命令提供了全面的任务属性管理功能，同时严格遵循DD系统的安全规则，只进行元数据管理，不涉及实际代码开发。