---
allowed-tools: Bash, Read, Write, LS, Task
---

# 恢复任务自动执行

恢复被暂停的任务自动执行模式。

## 用法
```
/dd:task-auto-resume <任务ID>
```

## 执行流程

### 1. 检查暂停状态
```bash
task_id="$ARGUMENTS"

if [ ! -f ".claude/context/auto-mode/paused.md" ]; then
  echo "❌ 没有找到暂停的自动执行任务"
  echo "💡 使用 /dd:task-auto $task_id 开启自动模式"
  exit 1
fi

paused_task=$(grep "^task_id:" .claude/context/auto-mode/paused.md | sed 's/^task_id: *//')
if [ "$paused_task" != "$task_id" ]; then
  echo "❌ 暂停的任务ID ($paused_task) 与指定任务 ($task_id) 不匹配"
  exit 1
fi
```

### 2. 恢复执行上下文
```bash
pause_reason=$(grep "^reason:" .claude/context/auto-mode/paused.md | sed 's/^reason: *//')
paused_at=$(grep "^paused_at:" .claude/context/auto-mode/paused.md | sed 's/^paused_at: *//')
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "🔄 恢复自动执行模式"
echo "📋 任务ID: $task_id"
echo "⏸️ 暂停原因: $pause_reason"
echo "⏰ 暂停时间: $paused_at"
echo "🚀 恢复时间: $current_time"
```

### 3. 清理暂停状态
```bash
# 删除暂停标记
rm .claude/context/auto-mode/paused.md

# 更新配置
sed -i.bak "s/^状态:.*/状态: 运行中/" .claude/context/auto-mode/config.md
echo "resumed_at: $current_time" >> .claude/context/auto-mode/config.md
rm .claude/context/auto-mode/config.md.bak
```

### 4. 继续自动执行
```yaml
Task:
  description: "恢复自动执行任务"
  subagent_type: "code-analyzer"
  prompt: |
    恢复任务自动执行：
    
    任务ID: $task_id
    暂停原因: $pause_reason
    恢复时间: $current_time
    
    请分析当前状态并继续执行：
    1. 检查暂停前的进度
    2. 确认暂停问题是否已解决
    3. 继续执行剩余的Epic todo项
    4. 保持自动进度更新机制
    
    如果暂停问题仍未解决，请再次暂停并说明原因。
```

### 5. 输出恢复信息
```bash
echo ""
echo "✅ 自动执行模式已恢复"
echo "🤖 AI将继续执行剩余工作直到Epic完成"
echo ""
echo "⚠️ 如需再次暂停，可随时中断执行"
```