---
allowed-tools: Read, Write, LS, Task
---

# 继续执行任务

继续执行当前未完成的任务，恢复任务上下文并推进任务进度。

## 用法
```
/dd:task-continue [任务ID]
```

## 参数说明
- `[任务ID]` - 可选，指定要继续的任务ID。如果不提供，自动继续最近的未完成任务。

## 预检清单

### 1. 查找当前任务
```bash
# 如果没有指定任务ID，查找当前正在进行的任务
if [ -z "$ARGUMENTS" ]; then
  # 检查是否有current-task.md
  if [ -f ".claude/context/current-task.md" ]; then
    task_id=$(grep "^任务ID:" .claude/context/current-task.md | sed 's/^任务ID: *//')
  else
    # 查找状态为"进行中"的任务
    task_id=$(grep -l "^状态: 进行中" .claude/epics/*/*.md | head -1 | xargs basename -s .md)
  fi
  
  if [ -z "$task_id" ]; then
    echo "❌ 没有找到进行中的任务"
    echo "💡 运行 /dd:task-start <任务ID> 开始新任务"
    exit 1
  fi
else
  task_id="$ARGUMENTS"
fi
```

### 2. 验证任务状态
```bash
# 检查任务文件是否存在
task_file=$(find .claude/epics -name "${task_id}.md" | head -1)
if [ ! -f "$task_file" ]; then
  echo "❌ 任务文件不存在：$task_id"
  exit 1
fi

# 检查任务状态
task_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
if [ "$task_status" == "已完成" ]; then
  echo "✅ 任务已完成：$task_id"
  echo "💡 运行 /dd:task-start <新任务ID> 开始其他任务"
  exit 0
elif [ "$task_status" != "进行中" ]; then
  echo "⚠️ 任务状态：$task_status"
  echo "❓ 确认要继续此任务？(是/否)"
  # 等待用户确认
fi
```

### 3. 恢复任务上下文
```bash
# 检查并恢复current-task.md
if [ ! -f ".claude/context/current-task.md" ]; then
  echo "📝 重建任务上下文文件..."
  # 从任务文件重建上下文
fi
```

## 操作指南

### 1. 任务上下文恢复

#### 加载任务信息
```bash
# 读取任务基本信息
task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
start_time=$(grep "^开始时间:" .claude/context/current-task.md | sed 's/^开始时间: *//')
last_update=$(grep "^最后更新:" "$task_file" | sed 's/^最后更新: *//')

echo "🔄 恢复任务：$task_name"
echo "📅 开始时间：$start_time"
echo "⏰ 最后更新：$last_update"
```

#### 分析任务进度
```bash
# 从current-task.md读取已完成的步骤
completed_steps=$(grep "^- \[x\]" .claude/context/current-task.md | wc -l)
total_steps=$(grep "^- \[\]" .claude/context/current-task.md | wc -l)
remaining_steps=$((total_steps - completed_steps))

echo "📊 任务进度：$completed_steps/$total_steps 步骤已完成"
echo "⏳ 剩余步骤：$remaining_steps"
```

#### 识别当前状态
```bash
# 分析上次停止的位置
last_completed_step=$(grep "^- \[x\]" .claude/context/current-task.md | tail -1)
next_step=$(grep -A1 "^- \[x\].*" .claude/context/current-task.md | grep "^- \[\]" | head -1)

echo "✅ 最后完成：$last_completed_step"
echo "🎯 下一步骤：$next_step"
```

### 2. 问题和阻碍回顾

#### 检查遗留问题
```bash
# 从current-task.md读取未解决的问题
unresolved_issues=$(sed -n '/^### 问题记录/,/^### /p' .claude/context/current-task.md | grep "状态：待解决")

if [ -n "$unresolved_issues" ]; then
  echo "⚠️ 发现未解决的问题："
  echo "$unresolved_issues"
  echo ""
  echo "🤔 需要先解决这些问题才能继续？(是/否)"
  # 等待用户确认
fi
```

#### 智能体辅助分析
```yaml
Task:
  description: "分析任务继续策略"
  subagent_type: "code-analyzer"
  prompt: |
    分析任务继续执行策略：
    
    任务信息：
    - 名称：$task_name
    - ID：$task_id  
    - 当前状态：进行中
    
    已完成的工作：
    {插入current-task.md中已完成的步骤}
    
    遗留问题：
    {插入未解决的问题}
    
    任务原始要求：
    {插入任务文件的目标和验收标准}
    
    请提供：
    1. 当前进度评估
    2. 下一步具体行动建议
    3. 遗留问题的解决策略
    4. 潜在风险和注意事项
    5. 完成任务的时间估算
    
    确保建议具体可操作，帮助快速恢复开发节奏。
```

### 3. 继续执行阶段

#### 更新时间戳
```bash
# 更新任务恢复时间
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 在current-task.md中记录恢复
cat >> .claude/context/current-task.md << EOF

## 任务恢复 - $current_time
从 $last_update 恢复任务执行
当前进度：$completed_steps/$total_steps 步骤已完成
EOF

# 更新任务文件
sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
rm "${task_file}.bak"
```

#### 制定继续计划
```bash
# 根据分析结果制定详细的继续计划
create_continuation_plan() {
  echo "📋 制定继续执行计划..."
  
  cat >> .claude/context/current-task.md << EOF

### 继续执行计划
1. **立即行动项**
   - [ ] 解决遗留问题（如有）
   - [ ] 验证已完成工作的正确性
   - [ ] 继续下一个待完成步骤

2. **短期目标（今日）**
   - [ ] 完成当前阶段的剩余工作
   - [ ] 进行阶段性验证

3. **中期目标（本周）**
   - [ ] 完成所有实施步骤
   - [ ] 通过验收标准检查
   - [ ] 准备任务完成

### 注意事项
- 保持与原始设计的一致性
- 及时更新进度记录
- 遇到新问题立即记录
EOF
}
```

### 4. 执行监控

#### 实时进度跟踪
```bash
# 定义进度更新函数
update_continuation_progress() {
  local step_description="$1"
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # 更新current-task.md
  sed -i.bak "s/- \[\] $step_description/- [x] $step_description - 完成时间：$current_time/" .claude/context/current-task.md
  rm .claude/context/current-task.md.bak
  
  # 更新任务文件时间戳
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
  
  echo "✅ 步骤完成：$step_description"
}
```

#### 质量检查点
```bash
# 在关键点进行质量检查
quality_checkpoint() {
  echo "🔍 执行质量检查..."
  
  # 检查代码变更（如果有）
  if git diff --quiet; then
    echo "📄 工作区干净，无未提交更改"
  else
    echo "📝 检测到代码变更，建议运行：/dd:changes-review"
  fi
  
  # 检查任务目标对齐
  echo "🎯 验证任务目标对齐性..."
  echo "   请确认当前进展与任务目标一致"
}
```

## 智能恢复功能

### 上下文重建
```bash
# 如果current-task.md不存在，智能重建
rebuild_task_context() {
  local task_file="$1"
  local task_id="$2"
  
  echo "🔧 重建任务上下文..."
  
  # 从任务文件提取信息
  local task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
  local created_time=$(grep "^创建时间:" "$task_file" | sed 's/^创建时间: *//')
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  cat > .claude/context/current-task.md << EOF
---
任务ID: $task_id
任务名称: $task_name
开始时间: $created_time
状态: 进行中
上次更新: $current_time
重建: true
---

# 当前任务：$task_name（已重建）

## 任务目标
$(sed -n '/^## 目标/,/^## /p' "$task_file" | head -n -1 | tail -n +2)

## 执行计划
基于任务文件重建，请更新实际进度

## 完成进度
- [ ] 任务分析完成
- [ ] 实施方案确定
- [ ] 代码实现完成
- [ ] 自我验证通过

## 重建说明
此上下文文件已重建，请根据实际情况更新进度状态。
EOF
  
  echo "✅ 任务上下文已重建"
}
```

### 进度推测
```bash
# 基于git提交历史推测任务进度
estimate_progress_from_git() {
  local task_id="$1"
  
  echo "🔍 分析git历史推测任务进度..."
  
  # 查找与任务相关的提交
  local related_commits=$(git log --oneline --grep="$task_id\|任务.*$task_id" | head -5)
  
  if [ -n "$related_commits" ]; then
    echo "📊 发现相关提交："
    echo "$related_commits"
    echo ""
    echo "💡 基于提交历史，任务可能有一定进展"
  else
    echo "ℹ️ 未发现相关提交，任务可能刚开始"
  fi
}
```

## 输出格式

### 继续确认
```markdown
🔄 继续执行任务：$task_name

📋 任务信息：
  - 任务ID：$task_id
  - 开始时间：$start_time
  - 上次更新：$last_update
  - 已暂停：{暂停时长}

📊 当前进度：
  ✅ 已完成：$completed_steps 个步骤
  ⏳ 待完成：$remaining_steps 个步骤
  📈 完成率：{百分比}%

🎯 下一步行动：
  1. {下一个待完成步骤}
  2. {后续步骤}

⚠️ 注意事项：
  - {遗留问题或特别注意的点}
  
🚀 准备继续执行...
```

### 进度恢复报告
```markdown
📈 任务进度恢复报告

⏱️ 时间信息：
  - 任务开始：$start_time
  - 上次停止：$last_update  
  - 恢复时间：$current_time
  - 暂停时长：{计算的时长}

✅ 已完成工作：
  - 步骤1：{描述} ✓
  - 步骤2：{描述} ✓
  
🔄 进行中工作：
  - 步骤3：{描述}（预计进度：60%）

📋 待完成工作：
  - 步骤4：{描述}
  - 步骤5：{描述}

🎯 预计完成时间：{基于剩余工作的估算}
```

## 错误处理

### 无进行中任务
```markdown
ℹ️ 当前没有进行中的任务

建议操作：
- 运行 /dd:status 查看所有任务状态
- 运行 /dd:task-start <任务ID> 开始新任务
- 检查是否有任务被意外标记为完成
```

### 上下文丢失
```markdown
⚠️ 任务上下文文件丢失

🔧 自动恢复措施：
- ✅ 从任务文件重建基本上下文
- ⚠️ 详细进度信息可能丢失
- 💡 建议手动更新实际进度状态

📝 需要手动确认的信息：
- 实际完成的步骤
- 遇到的问题和解决方案
- 当前的开发状态
```

## 最佳实践

### 任务继续原则
1. **状态检查** - 仔细检查暂停前的状态
2. **问题优先** - 优先解决遗留问题
3. **逐步推进** - 小步骤验证后再继续
4. **记录更新** - 及时更新进度和问题

### 效率提升
1. **定期保存** - 避免长时间暂停导致上下文丢失
2. **清晰记录** - 暂停时记录清楚当前状态
3. **问题跟踪** - 及时记录和解决问题
4. **节奏把控** - 保持适当的开发节奏