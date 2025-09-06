---
allowed-tools: Read, Edit, LS
---

# 暂停任务

暂停当前正在进行的任务，保存执行状态和进度信息。

## 用法
```
/dd:task-pause <任务ID>
```

## 参数说明
- `<任务ID>` - 要暂停的任务标识符

## 操作指南

### 1. 任务状态验证
```bash
# 解析任务ID格式：prd_name:task_num
if [[ "$ARGUMENTS" != *:* ]]; then
  echo "❌ 任务ID格式错误，应为：<PRD名称>:<任务编号>"
  echo "示例：用户认证系统:001"
  exit 1
fi

prd_name="${ARGUMENTS%%:*}"
task_num="${ARGUMENTS##*:}"
task_file=".claude/epics/$prd_name/$task_num.md"

if [ ! -f "$task_file" ]; then
  echo "❌ 任务不存在：$task_file"
  echo "💡 运行 /dd:task-list 查看所有任务"
  exit 1
fi

# 检查当前状态
current_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')

if [ "$current_status" != "进行中" ]; then
  echo "⚠️ 任务当前状态为：$current_status"
  echo "💡 只有进行中的任务才能暂停"
  exit 1
fi
```

### 2. 保存执行上下文
```bash
# 保存当前任务执行状态
save_task_context() {
  local task_id="$1"
  local context_file=".claude/context/paused-task-${task_id}.md"
  
  # 创建暂停上下文文件
  cat > "$context_file" << EOF
---
任务ID: $task_id
暂停时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
任务状态: 已暂停
---

# 任务暂停记录

## 暂停时状态
- 暂停时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- 执行进度: {当前进度描述}

## 已完成工作
- {记录已完成的工作项}

## 待继续工作
- {记录下一步需要做的工作}

## 暂停原因
{记录暂停原因，如遇到阻塞、优先级调整等}

## 恢复提示
运行 /dd:task-resume $task_id 恢复此任务
EOF

  echo "📝 任务执行上下文已保存到：$context_file"
}
```

### 3. 更新任务状态
```bash
# 更新任务文件状态
update_task_status() {
  local task_file="$1"
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # 更新状态为已暂停
  sed -i.bak "s/^状态:.*/状态: 已暂停/" "$task_file"
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  
  # 添加暂停时间记录
  if ! grep -q "^暂停时间:" "$task_file"; then
    sed -i.bak "/^最后更新:/a\\
暂停时间: $current_time" "$task_file"
  else
    sed -i.bak "s/^暂停时间:.*/暂停时间: $current_time/" "$task_file"
  fi
  
  rm "${task_file}.bak"
}
```

### 4. 清理当前任务上下文
```bash
# 清理当前任务标记
clear_current_task() {
  if [ -f ".claude/context/current-task.md" ]; then
    # 将当前任务信息归档
    local archive_file=".claude/context/task-history/$(date +%Y%m%d-%H%M%S)-task-pause.md"
    mkdir -p ".claude/context/task-history"
    mv ".claude/context/current-task.md" "$archive_file"
    echo "📚 当前任务信息已归档到：$archive_file"
  fi
}
```

### 5. 分析暂停影响
```bash
# 分析任务暂停对其他任务的影响
analyze_pause_impact() {
  local task_id="$1"
  
  # 查找依赖此任务的其他任务
  local dependent_tasks=$(find .claude/epics -name "*.md" -exec grep -l "依赖:.*$task_id" {} \;)
  
  if [ -n "$dependent_tasks" ]; then
    echo ""
    echo "⚠️ 暂停影响分析："
    echo "以下任务依赖当前暂停的任务，可能受到影响："
    
    echo "$dependent_tasks" | while read dep_file; do
      local dep_task_id=$(basename "$dep_file" .md)
      local dep_task_name=$(grep "^名称:" "$dep_file" | sed 's/^名称: *//')
      local dep_task_status=$(grep "^状态:" "$dep_file" | sed 's/^状态: *//')
      
      echo "  - $dep_task_name ($dep_task_id) [状态: $dep_task_status]"
    done
    
    echo ""
    echo "💡 建议："
    echo "  1. 通知相关团队成员任务暂停情况"
    echo "  2. 评估依赖任务是否需要调整计划"
    echo "  3. 尽快解决阻塞问题并恢复任务"
  fi
}
```

## 输出格式

### 暂停成功
```markdown
⏸️ 任务暂停成功

📋 任务信息：
  - 任务ID：{任务ID}
  - 任务名称：{任务名称}
  - 暂停时间：{暂停时间}
  - 执行时长：{开始到暂停的时长}

📝 状态变更：
  - 旧状态：进行中
  - 新状态：已暂停
  - 上下文：已保存

🔄 恢复方式：
  运行 /dd:task-resume {任务ID} 恢复此任务

⚠️ 影响分析：
  - 依赖任务数：{数量}
  - 建议尽快恢复以避免阻塞其他任务
```

## 错误处理

### 任务状态错误
```markdown
⚠️ 无法暂停任务

任务状态：{当前状态}
暂停条件：只有"进行中"的任务才能暂停

建议操作：
- 如果任务是"待开始"，请使用 /dd:task-start {任务ID}
- 如果任务是"已完成"，无需暂停
- 如果任务是"已暂停"，请使用 /dd:task-resume {任务ID}
```

## 最佳实践

### 暂停时机
1. **遇到技术阻塞** - 需要研究或咨询时
2. **优先级调整** - 有更紧急任务需要处理
3. **等待依赖** - 等待其他任务或外部条件
4. **时间安排** - 需要暂时转移工作重点

### 暂停记录
1. **详细记录进度** - 记录已完成和待完成的工作
2. **说明暂停原因** - 便于后续恢复时理解背景
3. **设置提醒** - 安排合适的时间恢复任务
4. **通知协作者** - 如果暂停影响其他人的工作

## 使用示例

```bash
# 暂停当前正在进行的任务
/dd:task-pause 001

# 暂停特定任务
/dd:task-pause user-auth-api
```