---
allowed-tools: Read, Edit, LS, Task
---

# 完成任务

标记任务为已完成，进行验收检查，并触发相关的后续流程。

## 用法
```
/dd:task-finish <任务ID>
```

## 参数说明
- `<任务ID>` - 要完成的任务标识符

## 操作指南

### 1. 任务状态验证
```bash
# 查找任务文件
task_file=$(find .claude/epics -name "${ARGUMENTS}.md" | head -1)

if [ ! -f "$task_file" ]; then
  echo "❌ 任务不存在：$ARGUMENTS"
  echo "💡 运行 /dd:task-list 查看所有任务"
  exit 1
fi

# 检查当前状态
current_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')

if [ "$current_status" == "已完成" ]; then
  echo "ℹ️ 任务已经完成"
  exit 0
elif [ "$current_status" != "进行中" ] && [ "$current_status" != "已暂停" ]; then
  echo "⚠️ 任务当前状态为：$current_status"
  echo "💡 只有进行中或已暂停的任务才能标记完成"
  exit 1
fi
```

### 2. 验收标准检查
```bash
# 使用代码分析智能体进行验收检查
perform_acceptance_check() {
  local task_file="$1"
  local task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
  
  # 提取验收标准
  local acceptance_criteria=$(sed -n '/^## 验收标准/,/^## /p' "$task_file" | grep "^- \[ \]")
  
  if [ -n "$acceptance_criteria" ]; then
    echo "📋 正在检查验收标准..."
    echo "$acceptance_criteria"
    echo ""
    echo "⚠️ 请确认所有验收标准是否已满足"
    echo "💡 如有未完成项，请先完成后再标记任务完成"
  fi
}
```

### 3. 代码改动验证
```yaml
Task:
  description: "验证任务完成质量"
  subagent_type: "code-analyzer"
  prompt: |
    验证任务完成的代码改动质量：
    
    当前任务：{任务名称}
    任务ID：{任务ID}
    
    请分析：
    1. 代码改动是否符合任务目标
    2. 实现是否完整和正确
    3. 是否遵循了代码规范
    4. 是否有潜在的bug或问题
    5. 是否需要补充文档或测试
    
    任务验收标准：
    {从任务文件提取的验收标准}
    
    基于分析结果，提供：
    - 任务完成质量评估（1-10分）
    - 发现的问题和改进建议
    - 是否建议标记为完成
```

### 4. 更新任务状态
```bash
# 标记任务完成
complete_task() {
  local task_file="$1"
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # 更新任务状态
  sed -i.bak "s/^状态:.*/状态: 已完成/" "$task_file"
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  
  # 添加完成时间
  if ! grep -q "^完成时间:" "$task_file"; then
    sed -i.bak "/^最后更新:/a\\
完成时间: $current_time" "$task_file"
  else
    sed -i.bak "s/^完成时间:.*/完成时间: $current_time/" "$task_file"
  fi
  
  # 清理暂停时间（如果存在）
  sed -i.bak "/^暂停时间:/d" "$task_file"
  
  rm "${task_file}.bak"
}
```

### 5. 自动触发反思
```bash
# 任务完成后自动进行反思
auto_reflect_on_completion() {
  echo "🤔 任务完成，自动开始反思分析..."
  
  # 调用反思命令
  /dd:code-reflect
  
  # 将反思结果附加到任务记录
  if [ -f "/tmp/reflection-summary.md" ]; then
    cat >> "$task_file" << EOF

## 完成反思
$(cat /tmp/reflection-summary.md)
EOF
  fi
}
```

### 6. 解锁依赖任务
```bash
# 分析任务完成对其他任务的影响
unlock_dependent_tasks() {
  local task_id="$1"
  
  # 查找依赖此任务的其他任务
  local dependent_tasks=$(find .claude/epics -name "*.md" -exec grep -l "依赖:.*$task_id" {} \;)
  
  if [ -n "$dependent_tasks" ]; then
    echo ""
    echo "🎉 任务完成影响分析："
    echo "以下任务的依赖条件现已满足："
    
    local unlocked_count=0
    
    echo "$dependent_tasks" | while read dep_file; do
      local dep_task_id=$(basename "$dep_file" .md)
      local dep_task_name=$(grep "^名称:" "$dep_file" | sed 's/^名称: *//')
      local dep_task_status=$(grep "^状态:" "$dep_file" | sed 's/^状态: *//')
      
      # 检查是否所有依赖都已完成
      local all_deps_complete=true
      local task_deps=$(grep "^依赖:" "$dep_file" | sed 's/^依赖: *\[//; s/\]//' | tr ',' ' ')
      
      for dep in $task_deps; do
        dep=$(echo "$dep" | xargs)
        local dep_status=$(find .claude/epics -name "$dep.md" -exec grep "^状态:" {} \; | sed 's/^状态: *//')
        if [ "$dep_status" != "已完成" ]; then
          all_deps_complete=false
          break
        fi
      done
      
      if [ "$all_deps_complete" == "true" ] && [ "$dep_task_status" == "待开始" ]; then
        echo "  ✅ $dep_task_name ($dep_task_id) - 可立即开始"
        echo "     💡 运行：/dd:task-start $dep_task_id"
        ((unlocked_count++))
      else
        echo "  ⏳ $dep_task_name ($dep_task_id) - 仍有其他依赖或已在进行"
      fi
    done
    
    if [ $unlocked_count -gt 0 ]; then
      echo ""
      echo "🚀 已解锁 $unlocked_count 个任务，可以继续推进项目进度！"
    fi
  fi
}
```

### 7. 清理任务上下文
```bash
# 清理当前任务上下文
cleanup_task_context() {
  local task_id="$1"
  
  # 归档当前任务上下文
  if [ -f ".claude/context/current-task.md" ]; then
    local archive_file=".claude/context/task-history/$(date +%Y%m%d-%H%M%S)-task-completed.md"
    mkdir -p ".claude/context/task-history"
    mv ".claude/context/current-task.md" "$archive_file"
    echo "📚 任务执行记录已归档到：$archive_file"
  fi
  
  # 清理暂停上下文（如果存在）
  local pause_context=".claude/context/paused-task-${task_id}.md"
  if [ -f "$pause_context" ]; then
    rm "$pause_context"
    echo "🧹 已清理任务暂停上下文"
  fi
}
```

## 输出格式

### 完成成功
```markdown
🎉 任务完成！

📋 任务信息：
  - 任务ID：{任务ID}
  - 任务名称：{任务名称}
  - 完成时间：{完成时间}
  - 执行时长：{总执行时间}

✅ 验收状态：
  - 代码质量：{质量评分}/10
  - 验收标准：{满足/部分满足/未满足}
  - 推荐状态：{建议完成/需要改进}

🎯 任务成果：
  - 实现目标：{达成情况}
  - 交付物：{具体产出}
  - 影响范围：{受影响的组件或功能}

🔓 解锁任务：
  - 解锁任务数：{数量}
  - 可开始任务：{任务列表}
  - 下一步建议：{具体行动建议}

🤔 完成反思：
  {自动反思分析结果摘要}
```

## 错误处理

### 任务状态错误
```markdown
⚠️ 无法完成任务

任务状态：{当前状态}
完成条件：只有"进行中"或"已暂停"的任务才能标记完成

建议操作：
- 如果任务是"待开始"，请先使用 /dd:task-start {任务ID}
- 如果任务是"已完成"，任务已经完成
```

### 验收标准未满足
```markdown
⚠️ 验收标准检查

发现问题：
- 验收标准1：未满足
- 验收标准2：部分满足
- 代码质量评分：{分数}/10

建议操作：
1. 完成剩余的验收标准
2. 解决发现的代码问题
3. 重新运行 /dd:task-finish {任务ID}

或者：
- 强制完成：确认问题可接受后再次运行命令
```

## 最佳实践

### 完成前检查
1. **验收标准** - 确保所有验收标准都已满足
2. **代码质量** - 进行代码审查和质量检查
3. **文档更新** - 确保相关文档已更新
4. **测试覆盖** - 验证功能测试通过

### 完成后操作
1. **反思总结** - 记录经验教训和改进点
2. **知识分享** - 与团队分享实施经验
3. **后续规划** - 安排后续任务的执行
4. **持续改进** - 基于反思结果改进流程

## 使用示例

```bash
# 完成当前任务
/dd:task-finish 001

# 完成特定任务
/dd:task-finish user-auth-api
```