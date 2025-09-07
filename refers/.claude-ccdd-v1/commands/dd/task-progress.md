---
allowed-tools: Bash, Read, Write, LS
---

# 更新任务进度

更新任务执行进度，同步Epic的todo状态。既是开发者直接使用的命令，也是其他任务命令的底层抽象。

## 用法
```
# 开发者直接使用
/dd:task-progress <任务ID> <进度描述>

# 其他命令内部调用
epic_todo_update <任务ID> <进度描述>
```

## 核心功能

### 统一的任务Todo更新逻辑
```bash
epic_todo_update() {
  local task_id="$1"
  local progress_desc="$2"
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
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
    return 1
  fi
  
  echo "🔄 更新任务进度：$progress_desc"
  
  local epic_file=".claude/epics/$prd_name/epic.md"
  
  # 1. 更新任务文件的todo
  local key_words=$(echo "$progress_desc" | cut -d' ' -f1-3)
  local matching_todo=$(grep "^- \[ \]" "$task_file" | grep -i "$key_words" | head -1)
  
  if [ -n "$matching_todo" ]; then
    # 精确替换匹配的todo项
    sed -i.bak "s/^$(echo "$matching_todo" | sed 's/[[\.*^$()+?{|]/\\&/g')$/- [x] $progress_desc/" "$task_file"
    rm "${task_file}.bak" 2>/dev/null || true
    echo "  ✅ 任务todo已更新"
  else
    # 如果没找到精确匹配，添加新的完成项
    echo "- [x] $progress_desc (额外完成)" >> "$task_file"
    echo "  ℹ️ 添加为额外完成项"
  fi
  
  # 2. 更新Epic的任务列表状态
  if [ -f "$epic_file" ]; then
    # 检查任务是否完全完成
    local task_remaining=$(grep "^- \[ \]" "$task_file" 2>/dev/null | wc -l || echo "0")
    local task_completed=$(grep "^- \[x\]" "$task_file" 2>/dev/null | wc -l || echo "0")
    
    if [ "$task_remaining" -eq 0 ] && [ "$task_completed" -gt 0 ]; then
      # 任务完全完成，更新Epic中的任务状态为[x]
      sed -i.bak "s/^- \[ \] $task_num /- [x] $task_num /" "$epic_file"
      rm "${epic_file}.bak" 2>/dev/null || true
      echo "  🎉 Epic任务状态已更新为完成"
      
      # 重新计算Epic整体进度
      update_epic_progress "$prd_name" "$epic_file"
    else
      echo "  📊 任务进行中，Epic状态保持不变"
    fi
  fi
  
  # 更新任务文件时间戳
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  # 显示剩余进度
  local remaining=$(grep "^- \[ \]" "$task_file" 2>/dev/null | wc -l || echo "0")
  echo "  📊 剩余任务todo：$remaining 项"
  
  if [ "$remaining" -eq 0 ]; then
    echo "  🎉 所有任务todo已完成！"
  fi
  
  return 0
}

# 更新Epic整体进度
update_epic_progress() {
  local prd_name="$1"
  local epic_file="$2"
  
  # 统计Epic中的任务完成情况
  local total_tasks=$(grep "^- \[" "$epic_file" | grep -E "^- \[[x ]\] [0-9]{3} -" | wc -l || echo "0")
  local completed_tasks=$(grep "^- \[x\]" "$epic_file" | grep -E "^- \[x\] [0-9]{3} -" | wc -l || echo "0")
  
  if [ "$total_tasks" -gt 0 ]; then
    local progress=$(( (completed_tasks * 100) / total_tasks ))
    
    # 更新进度字段
    sed -i.bak "s/^进度:.*/进度: ${progress}%/" "$epic_file"
    rm "${epic_file}.bak" 2>/dev/null || true
    
    echo "  📈 Epic整体进度已更新：$completed_tasks/$total_tasks ($progress%)"
    
    # 如果100%完成，更新Epic状态
    if [ "$progress" -eq 100 ]; then
      sed -i.bak "s/^状态:.*/状态: completed/" "$epic_file"
      rm "${epic_file}.bak" 2>/dev/null || true
      echo "  🎉 Epic已完成！状态已更新为 completed"
    fi
  else
    echo "  ⚠️ Epic中没有找到标准格式的任务列表"
  fi
}

# 导出函数供其他命令使用
export -f epic_todo_update
export -f update_epic_progress
```

### 主命令处理
```bash
# 如果作为独立命令调用
if [ "$#" -eq 2 ]; then
  task_id="$1"
  progress_desc="$2"
  
  echo "📈 手动更新任务进度"
  
  if epic_todo_update "$task_id" "$progress_desc"; then
    echo ""
    echo "✅ 进度更新完成"
    echo ""
    echo "🎯 建议的下一步操作："
    echo "  • 继续任务：/dd:task-resume $task_id"
    echo "  • 更新更多进度：/dd:task-progress $task_id '<描述>'"
    echo "  • 完成任务：/dd:code-reflect 然后 /dd:task-finish $task_id"
  fi
else
  echo "❌ 用法：/dd:task-progress <任务ID> <进度描述>"
  echo "示例：/dd:task-progress 用户认证系统:001 '完成用户登录API接口'"
fi
```

## 设计优势

### 1. 代码复用
所有任务命令都调用统一的 `epic_todo_update` 函数：
- `task-start` → 分析完成调用更新
- `task-resume` → 每完成一项调用更新  
- `task-start-auto` → 自动执行中调用更新
- `task-resume-auto` → 自动执行中调用更新

### 2. 智能匹配
- 优先匹配Epic中现有的todo项
- 找不到匹配项时添加为额外完成项
- 避免重复和遗漏

### 3. 双重用途
- **开发者工具** - 手动同步进度状态
- **系统组件** - 其他命令的底层依赖

### 4. 一致性保证
所有命令使用相同的更新逻辑，确保行为一致性