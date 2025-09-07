---
allowed-tools: Bash, Read, Write, LS, Task
---

# 完成任务

完成指定任务，进行AI评审并确认完成状态。

## 用法
```
/dd:task-finish <任务ID>
```

## 执行流程

### 1. 验证任务状态
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
  exit 1
fi

status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
if [ "$status" = "已完成" ]; then
  echo "✅ 任务已经完成：$ARGUMENTS"
  exit 0
fi
```

### 2. 自动代码评审
首先执行代码变更检查：
```yaml
Task:
  description: "代码变更评审"  
  subagent_type: "code-analyzer"
  prompt: |
    为任务 $ARGUMENTS 执行代码变更评审：
    
    任务文件：$task_file
    任务内容：$(cat "$task_file")
    
    请执行：
    1. 检查代码变更是否符合任务要求
    2. 验证是否遵循编码规范
    3. 检查是否有安全问题
    4. 确认是否满足验收标准
    5. 评估代码质量和可维护性
    
    重要约束：
    - 严格遵循绝对安全规则
    - 只进行分析，不修改任何代码
    - 不执行git操作
    - 提供明确的完成度评估
    
    最后给出明确结论：
    - 是否建议标记为完成
    - 还需要什么工作（如果有）
```

### 3. AI自我评审
执行自我反思：
```yaml
Task:
  description: "任务完成自我评审"
  subagent_type: "code-analyzer" 
  prompt: |
    对任务 $ARGUMENTS 进行最终自我评审：
    
    任务详情：$(cat "$task_file")
    
    评审要点：
    1. 任务目标是否完全达成
    2. 验收标准是否全部满足
    3. 代码变更是否充分和正确
    4. 是否有遗漏的工作项
    5. 对其他任务的影响评估
    
    请给出：
    - 完成度百分比
    - 主要成果总结
    - 遗留问题（如果有）
    - 最终建议（完成/需要继续）
```

### 4. 用户确认
基于AI评审结果，询问用户：
```bash
echo "🤔 AI评审完成，请确认："
echo ""
echo "📋 任务：$task_name (ID: $ARGUMENTS)"
echo "📊 AI评估完成度：{AI给出的百分比}"
echo "✅ 主要成果：{AI总结的成果}"
echo ""

if [ -n "{遗留问题}" ]; then
  echo "⚠️ 遗留问题："
  echo "{AI指出的问题}"
  echo ""
fi

echo "❓ 确认将此任务标记为完成吗？(y/n)"
read -r confirmation

if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
  echo "❌ 任务未标记为完成"
  echo "💡 继续开发：/dd:task-resume $ARGUMENTS"
  exit 0
fi
```

### 5. 更新任务状态
用户确认后更新状态：
```bash
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
epic_name=$(basename $(dirname "$task_file"))

# 更新任务文件
sed -i.bak "s/^状态:.*/状态: 已完成/" "$task_file"
sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"

# 添加完成时间
if ! grep -q "^完成时间:" "$task_file"; then
  sed -i.bak "/^最后更新:/a\\
完成时间: $current_time" "$task_file"
fi

rm "${task_file}.bak"
```

### 6. 更新Epic进度
更新Epic的todo状态：
```bash
epic_file=".claude/epics/$epic_name/epic.md"
if [ -f "$epic_file" ]; then
  # 查找对应的todo项并标记完成
  task_description=$(grep "^## 目标" "$task_file" -A 1 | tail -1)
  sed -i.bak "s/- \[ \] .*$ARGUMENTS.*/- [x] $task_description (任务 $ARGUMENTS)/" "$epic_file"
  rm "${epic_file}.bak"
fi
```

### 7. 更新当前任务上下文
```bash
if [ -f ".claude/context/current-task.md" ]; then
  echo "" >> .claude/context/current-task.md
  echo "## 任务完成 - $current_time" >> .claude/context/current-task.md
  echo "任务已成功完成并通过AI评审" >> .claude/context/current-task.md
fi
```

### 8. Git 状态检查和提醒
任务完成后显示 git 状态供用户参考：
```bash
echo ""
echo "🔍 代码变更状态："
git status --porcelain 2>/dev/null | head -10 || echo "  无法获取git状态信息"
echo ""
echo "💡 建议操作："
echo "  git add ."
echo "  git commit -m \"完成任务: $task_name\""
echo ""
```

### 9. 分析后续任务
检查是否有依赖此任务的其他任务：
```bash
dependent_tasks=$(find .claude/epics -name "*.md" -exec grep -l "依赖:.*$ARGUMENTS" {} \;)
if [ -n "$dependent_tasks" ]; then
  echo "📌 以下任务现在可以开始："
  echo "$dependent_tasks" | while read task; do
    dep_task_id=$(basename "$task" .md)
    dep_task_name=$(grep "^名称:" "$task" | sed 's/^名称: *//')
    echo "  ✅ $dep_task_name (任务 $dep_task_id)"
  done
fi
```

## 输出格式

```markdown
✅ 任务完成：$task_name

📋 完成信息：
  - 任务ID：$ARGUMENTS
  - Epic：$epic_name  
  - 完成时间：$current_time
  - AI评估：通过

⚠️ 重要提醒：请提交代码变更
  🔍 检查变更：git status
  📝 添加文件：git add . 
  💾 提交变更：git commit -m "<type>: $task_name"

📊 完成统计：
  - 主要成果：{AI总结}
  - 完成度：{百分比}

🎯 后续建议：
  - 提交代码变更：git add . && git commit -m "完成任务: $task_name"
  - 执行代码反思：/dd:code-reflect --详细
  - 开始下一个任务：/dd:task-start <任务ID>
  - 查看Epic进度：/dd:epic-show $epic_name
  - 查看项目状态：/dd:status

💡 Git 工作流提醒：
  1. 检查变更：git status
  2. 添加文件：git add <文件名> 或 git add .
  3. 提交变更：git commit -m "描述变更内容"

📌 解锁的任务：
  {列出现在可以开始的依赖任务}
```

## 安全约束

严格遵循DD系统规则：
1. **禁止git操作** - 不执行任何git命令
2. **用户确认** - 必须用户确认后才标记完成
3. **只读评审** - AI只进行分析评审，不修改代码
4. **状态同步** - 同时更新任务和Epic状态