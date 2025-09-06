---
allowed-tools: Bash, Read, Write, LS, Task
---

# 任务自动执行模式

开启任务自动执行模式，AI将持续执行任务直到Epic的所有todo完成，并自动切换到下一个任务。

## 用法
```
/dd:task-start-auto <任务ID>
```

## 执行流程

### 1. 初始化自动模式
```bash
task_id="$ARGUMENTS"
# 解析任务ID格式：prd_name:task_num
if [[ "$task_id" != *:* ]]; then
  echo "❌ 任务ID格式错误，应为：<PRD名称>:<任务编号>"
  echo "示例：用户认证系统:001"
  exit 1
fi

prd_name="${task_id%%:*}"
task_num="${task_id##*:}"
task_file=".claude/epics/$prd_name/$task_num.md"

if [ ! -f "$task_file" ]; then
  echo "❌ 任务不存在：$task_file"
  exit 1
fi

epic_name=$(basename $(dirname "$task_file"))
epic_file=".claude/epics/$epic_name/epic.md"

echo "🤖 启动任务自动执行模式"
echo "📋 任务：$(grep "^名称:" "$task_file" | sed 's/^名称: *//')"
echo "📚 Epic：$epic_name"
```

### 2. 创建自动执行上下文
```bash
mkdir -p .claude/context/auto-mode
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > .claude/context/auto-mode/config.md << EOF
---
mode: auto-execution
task_id: $task_id
epic_name: $epic_name
started: $current_time
cycle_count: 0
max_cycles: 20
---

# 自动执行模式配置

## 任务信息
- 任务ID: $task_id
- Epic: $epic_name
- 开始时间: $current_time

## 执行状态
- 当前周期: 0
- 最大周期: 20
- 状态: 运行中
EOF
```

### 3. 自动执行循环
```yaml
Task:
  description: "自动执行任务循环"
  subagent_type: "code-analyzer"
  prompt: |
    进入任务自动执行循环：
    
    任务ID: $task_id
    Epic: $epic_name
    
    任务详情:
    $(cat "$task_file")
    
    Epic todo状态:
    $(grep "^- \[" "$epic_file")
    
    执行指令：
    1. 分析Epic中未完成的todo项
    2. 选择下一个可执行的工作项
    3. 提供具体的实施步骤
    4. 完成后自动更新Epic todo状态
    5. 检查是否还有未完成项，决定是否继续
    
    自动执行规则：
    - 每完成一项工作，自动标记Epic todo为完成
    - 更新current-task.md的进度
    - 严格遵循安全规则，不执行git操作
    - 如果遇到需要用户干预的情况，暂停并提示
    - 所有Epic todo完成后自动结束
    
    请开始执行并实时报告进度。
```

### 4. 进度自动更新机制
```bash
# 创建进度更新函数
auto_update_progress() {
  local completed_item="$1"
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # 更新current-task.md
  if [ -f ".claude/context/current-task.md" ]; then
    echo "- [x] $completed_item - 自动完成: $current_time" >> .claude/context/current-task.md
  fi
  
  # 自动更新Epic todo
  if [ -f "$epic_file" ]; then
    # 查找匹配的todo项并标记完成
    sed -i.bak "s/- \[ \] .*$completed_item.*/- [x] $completed_item (自动完成)/" "$epic_file"
    rm "${epic_file}.bak" 2>/dev/null || true
  fi
  
  # 更新任务文件时间戳
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 自动更新: $completed_item"
}
```

### 5. 循环控制逻辑
```bash
# 检查是否所有Epic todo已完成
check_epic_completion() {
  local remaining_todos=$(grep "^- \[ \]" "$epic_file" | wc -l)
  
  if [ "$remaining_todos" -eq 0 ]; then
    echo "🎉 所有Epic todo已完成！"
    echo "🔄 准备完成任务..."
    
    # 自动触发task-finish流程
    echo "🤔 执行最终评审..."
    /dd:code-reflect
    echo ""
    echo "✅ 准备完成任务，请确认："
    /dd:task-finish "$task_id"
    
    # 清理自动模式
    rm -rf .claude/context/auto-mode
    return 0
  else
    echo "⏳ 剩余Epic todo: $remaining_todos 项"
    return 1
  fi
}
```

### 6. 智能暂停机制
```bash
# 检查是否需要用户干预
check_user_intervention_needed() {
  # 检查是否遇到复杂问题
  local intervention_signals=(
    "需要用户确认"
    "需要外部依赖"
    "需要配置变更"
    "需要数据库操作"
    "需要第三方服务"
  )
  
  # 如果智能体报告需要干预，暂停自动模式
  echo "🤖 检查是否需要用户干预..."
  return 1  # 如果需要干预返回1
}
```

### 7. 执行监控和报告
```bash
echo ""
echo "🤖 自动执行模式已启动"
echo ""
echo "📊 执行参数："
echo "  - 任务ID: $task_id"
echo "  - Epic: $epic_name"
echo "  - 最大循环: 20"
echo "  - 自动进度更新: 启用"
echo "  - 智能暂停: 启用"
echo ""
echo "🎯 执行目标："
echo "  - 完成所有Epic todo项"
echo "  - 自动更新进度状态"
echo "  - 智能处理复杂情况"
echo ""
echo "⚠️ 注意事项："
echo "  - 遇到复杂问题会自动暂停"
echo "  - 可随时使用 Ctrl+C 中断"
echo "  - 所有操作严格遵循安全规则"
echo ""
echo "🚀 开始自动执行..."
```

### 8. 暂停和恢复机制
```bash
# 保存暂停状态
save_pause_state() {
  local reason="$1"
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  cat > .claude/context/auto-mode/paused.md << EOF
---
paused: true
reason: $reason
paused_at: $current_time
task_id: $task_id
epic_name: $epic_name
---

# 自动执行已暂停

## 暂停原因
$reason

## 恢复方式
/dd:task-auto-resume $task_id
EOF
  
  echo "⏸️ 自动执行已暂停: $reason"
  echo "🔄 恢复命令: /dd:task-auto-resume $task_id"
}
```

## 关键特性

### 自动进度更新
- 每完成一项工作自动标记Epic todo
- 实时更新current-task.md进度
- 自动同步任务文件时间戳

### 智能执行控制
- 自动分析下一步工作项
- 智能判断是否需要用户干预
- 支持暂停和恢复机制

### 安全保障
- 严格遵循DD系统安全规则
- 不执行任何git操作
- 最大循环次数限制防止无限循环
- 智能检测异常情况并暂停

### 完成检测
- 自动检测所有Epic todo完成
- 自动触发code-reflect和task-finish
- 清理自动执行上下文