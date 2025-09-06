---
allowed-tools: Bash, Read, Write, LS, Task
---

# 继续执行任务

继续执行当前未完成的任务，恢复任务上下文并推进任务进度。

## 用法
```
/dd:task-resume [任务ID]
```

## 执行流程

### 1. 查找当前任务
```bash
if [ -z "$ARGUMENTS" ]; then
  # 从current-task.md获取任务ID
  if [ -f ".claude/context/current-task.md" ]; then
    task_id=$(grep "^任务ID:" .claude/context/current-task.md | sed 's/^任务ID: *//')
  else
    # 查找进行中的任务
    task_id=$(find .claude/epics -name "*.md" -exec grep -l "^状态: 进行中" {} \; | head -1 | xargs basename -s .md)
  fi
  
  if [ -z "$task_id" ]; then
    echo "❌ 没有找到进行中的任务"
    exit 1
  fi
else
  task_id="$ARGUMENTS"
fi
```

### 2. 验证任务状态
```bash
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
  echo "❌ 任务文件不存在：$task_file"
  exit 1
fi

task_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
if [ "$task_status" = "已完成" ]; then
  echo "✅ 任务已完成：$task_id"
  exit 0
fi
```

### 3. 恢复任务上下文
```bash
task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
epic_name=$(basename $(dirname "$task_file"))
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "🔄 恢复任务：$task_name"
echo "📅 任务ID：$task_id"
echo "📚 Epic：$epic_name"
```

### 4. 检查和同步Epic状态
```bash
epic_file=".claude/epics/$epic_name/epic.md"
if [ -f "$epic_file" ]; then
  echo "🔍 检查Epic todo状态..."
  
  # 显示Epic中的todo状态
  echo "📋 Epic进度："
  grep "^- \[" "$epic_file" | head -10
  echo ""
  
  # 智能分析：检查是否有已完成但未标记的项目
  completed_items=$(grep "^- \[x\]" .claude/context/current-task.md 2>/dev/null | wc -l || echo "0")
  if [ "$completed_items" -gt 0 ]; then
    echo "📈 检测到 $completed_items 个已完成项目"
    echo "💡 提示：使用 /dd:task-progress $task_id '<描述>' 同步Epic状态"
  fi
fi
```

### 5. 导入进度更新函数
```bash
# 导入task-progress的底层函数
source .claude/commands/dd/task-progress.md
```

### 6. 使用智能体分析并自动执行
```yaml
Task:
  description: "分析并继续执行任务"
  subagent_type: "code-analyzer"
  prompt: |
    分析并继续执行任务：
    
    任务信息：
    - 名称：$task_name
    - ID：$task_id  
    - 当前状态：$task_status
    - Epic：$epic_name
    
    任务内容：
    $(cat "$task_file")
    
    Epic当前todo状态：
    $(grep "^- \[" "$epic_file")
    
    当前上下文：
    $(cat ".claude/context/current-task.md" 2>/dev/null || echo "无当前上下文")
    
    执行要求：
    1. 分析Epic中下一个未完成的todo项
    2. 提供具体实施步骤和代码建议
    3. 完成一项工作后调用：epic_todo_update($task_id, "完成项描述")
    4. 继续分析下一项或告知需要用户干预的原因
    5. 实时报告进度和完成情况
    
    自动更新机制：
    - 每完成一项调用：epic_todo_update($task_id, "完成项描述")
    - 系统会自动更新Epic todo和进度文件
    - 显示剩余未完成项数量
    
    重要约束：
    - 严格遵循绝对安全规则
    - 不执行git操作，只提供代码分析和建议
    - 遇到复杂情况及时说明原因并建议暂停
    
    请开始执行并实时报告每个完成项。
```

### 6. 更新任务状态
```bash
# 更新最后更新时间
sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
rm "${task_file}.bak"

# 在current-task.md中记录恢复
if [ -f ".claude/context/current-task.md" ]; then
  echo "" >> .claude/context/current-task.md
  echo "## 任务恢复 - $current_time" >> .claude/context/current-task.md
  echo "任务继续执行，当前状态：$task_status" >> .claude/context/current-task.md
else
  # 重建current-task.md
  echo "📝 重建任务上下文..."
  cat > .claude/context/current-task.md << EOF
---
任务ID: $task_id
任务名称: $task_name
Epic: $epic_name
恢复时间: $current_time
状态: 进行中
---

# 当前任务：$task_name（已恢复）

## 任务目标
$(sed -n '/^## 目标/,/^## /p' "$task_file" | head -n -1 | tail -n +2)

## 执行计划
[请根据智能体分析更新]

## 完成进度
- [ ] 根据实际情况更新进度

## 恢复说明
此上下文文件已重建，请根据实际情况更新进度状态。
EOF
fi
```

### 7. 输出恢复信息
```bash
echo ""
echo "✅ 任务恢复完成！"
echo ""
echo "📋 任务信息："
echo "  - 任务ID：$task_id"
echo "  - 任务名称：$task_name"
echo "  - Epic：$epic_name"
echo "  - 恢复时间：$current_time"
echo ""
echo "🎯 建议的下一步操作："
echo "  • 更新任务进度：/dd:task-progress $task_id '<完成项描述>'"
echo "  • 代码反思评审：/dd:code-reflect"
echo "  • 完成任务：/dd:task-finish $task_id"
echo "  • 查看任务详情：/dd:task-show $task_id"
echo ""
echo "💡 提示：完成工作项后及时使用 /dd:task-progress 同步Epic状态"
```

## 重要功能

### Epic状态同步
- 自动检查Epic中的todo状态
- 提示使用task-progress同步进度
- 显示已完成但未同步的项目数量

### 智能上下文恢复
- 自动重建丢失的current-task.md
- 使用智能体分析继续策略
- 提供具体的下一步行动建议

### 进度跟踪提醒
- 提醒开发者及时更新进度
- 显示Epic整体进度情况
- 建议后续操作流程