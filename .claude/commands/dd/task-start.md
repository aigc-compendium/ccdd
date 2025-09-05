---
allowed-tools: Read, Write, LS, Task
---

# 开始执行任务

开始执行指定的任务，建立任务执行上下文并进入任务开发闭环。

## 用法
```
/dd:task-start <任务ID>
```

## 参数说明
- `<任务ID>` - 任务文件名（如：001、002 或 GitHub issue ID）

## 预检清单

### 1. 任务存在性验证
```bash
# 检查任务文件是否存在
if [ -f ".claude/epics/*/001.md" ] || [ -f ".claude/epics/*/${ARGUMENTS}.md" ]; then
  echo "✅ 找到任务文件"
else
  echo "❌ 任务不存在：$ARGUMENTS"
  echo "💡 运行 /dd:status 查看可用任务"
  exit 1
fi
```

### 2. 任务状态检查
```bash
# 检查任务当前状态
task_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
if [ "$task_status" == "已完成" ]; then
  echo "⚠️ 任务已完成，确认重新开始？(是/否)"
  # 等待用户确认
fi
```

### 3. 依赖关系验证
```bash
# 检查任务依赖是否满足
dependencies=$(grep "^依赖:" "$task_file" | sed 's/^依赖: *\[//; s/\]//')
if [ -n "$dependencies" ]; then
  for dep in ${dependencies//,/ }; do
    dep_status=$(grep "^状态:" ".claude/epics/*/$dep.md" | sed 's/^状态: *//')
    if [ "$dep_status" != "已完成" ]; then
      echo "❌ 依赖任务 $dep 未完成（状态：$dep_status）"
      echo "💡 请先完成依赖任务或确认可以并行进行"
      exit 1
    fi
  done
fi
```

## 操作指南

### 1. 任务上下文建立

#### 读取任务详情
```bash
# 加载任务文件内容
task_file=$(find .claude/epics -name "${ARGUMENTS}.md" | head -1)
task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
task_description=$(sed -n '/^## 目标/,/^## /p' "$task_file" | head -n -1 | tail -n +2)
```

#### 创建任务工作空间
```bash
# 在 .claude/context/ 中创建当前任务上下文
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > .claude/context/current-task.md << EOF
---
任务ID: $ARGUMENTS
任务名称: $task_name
开始时间: $current_time
状态: 进行中
上次更新: $current_time
---

# 当前任务：$task_name

## 任务目标
$task_description

## 执行计划
[将在执行过程中更新]

## 完成进度
- [ ] 任务分析完成
- [ ] 实施方案确定
- [ ] 代码实现完成
- [ ] 自我验证通过

## 遇到的问题
[记录执行过程中的问题]

## 解决方案
[记录问题的解决方案]
EOF
```

### 2. 任务分析阶段

#### 使用智能体深度分析
```yaml
Task:
  description: "分析任务执行计划"
  subagent_type: "code-analyzer"
  prompt: |
    分析任务：$task_name（ID: $ARGUMENTS）
    
    任务内容：
    {插入完整的任务文件内容}
    
    当前项目上下文：
    {插入相关的项目上下文}
    
    请提供：
    1. 详细的实施步骤分解
    2. 需要修改的文件清单
    3. 可能的风险点和注意事项
    4. 与其他任务/组件的集成考虑
    5. 验收标准的具体检查方法
    
    确保分析全面且实用，为实际开发提供明确指导。
```

#### 更新任务状态
```bash
# 更新任务文件状态
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sed -i.bak "s/^状态:.*/状态: 进行中/" "$task_file"
sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
rm "${task_file}.bak"
```

### 3. 实施阶段

#### 分步执行
```markdown
对于任务中的每个实施步骤：

1. **步骤分析**
   - 理解当前步骤的目标
   - 识别需要的输入和预期输出
   - 检查步骤的前置条件

2. **代码实施**
   - 严格遵循 `.claude/rules/absolute-rules.md`
   - 只分析和建议，不直接修改代码
   - 提供具体的实施指导

3. **步骤验证**  
   - 检查实施结果是否符合预期
   - 验证与其他组件的兼容性
   - 确认没有引入新问题

4. **进度更新**
   - 更新 current-task.md 中的进度
   - 记录完成的工作和遇到的问题
```

### 4. 持续监控和调整

#### 定期状态检查
```bash
# 每完成一个主要步骤后
update_task_progress() {
  local step="$1"
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # 更新进度文件
  echo "- [x] $step - 完成时间：$current_time" >> .claude/context/current-task.md
  
  # 更新任务文件的最后更新时间
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  rm "${task_file}.bak"
}
```

#### 问题和阻碍处理
```bash
# 当遇到问题时
handle_task_blocker() {
  local issue="$1"
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  cat >> .claude/context/current-task.md << EOF

### 问题记录 - $current_time
**问题描述：** $issue
**影响评估：** [待分析]
**解决方案：** [待制定]
**状态：** 待解决
EOF

  # 可以调用问题分析智能体
  # 提供解决建议
}
```

## 任务完成检查

### 验收标准验证
```bash
# 检查任务的所有验收标准
validate_acceptance_criteria() {
  local task_file="$1"
  local criteria=$(sed -n '/^## 验收标准/,/^## /p' "$task_file" | grep "^- \[ \]")
  
  echo "📋 验收标准检查："
  echo "$criteria" | while read criterion; do
    echo "$criterion"
    echo "   请确认此标准是否已满足..."
  done
}
```

### 影响分析
```bash
# 分析任务完成对其他任务的影响
analyze_completion_impact() {
  echo "🔍 分析任务完成的影响..."
  
  # 检查依赖此任务的其他任务
  local dependent_tasks=$(grep -l "依赖:.*$ARGUMENTS" .claude/epics/*/*.md)
  if [ -n "$dependent_tasks" ]; then
    echo "📌 以下任务现在可以开始："
    echo "$dependent_tasks" | while read task; do
      task_name=$(grep "^名称:" "$task" | sed 's/^名称: *//')
      echo "  - $task_name"
    done
  fi
}
```

## 任务完成流程

### 标记任务完成
```bash
complete_task() {
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # 更新任务状态
  sed -i.bak "s/^状态:.*/状态: 已完成/" "$task_file"
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
  
  # 添加完成时间
  if ! grep -q "^完成时间:" "$task_file"; then
    sed -i.bak "/^最后更新:/a\\
完成时间: $current_time" "$task_file"
  fi
  
  rm "${task_file}.bak"
  
  # 更新当前任务上下文
  echo "任务于 $current_time 完成" >> .claude/context/current-task.md
}
```

### 自动触发反思
```bash
# 任务完成后自动进行反思
echo "🤔 任务完成，开始自我反思..."
/dd:reflect-on-changes
```

## 输出格式

### 任务开始确认
```markdown
🚀 开始执行任务：$task_name

📋 任务信息：
  - 任务ID：$ARGUMENTS
  - 优先级：{优先级}
  - 预估工作量：{预估小时数}小时
  - 并行状态：{可否并行}

📊 依赖状态：
  ✅ 所有依赖任务已完成
  或
  ⚠️ 依赖任务：任务001（状态：进行中）

🎯 执行计划：
  1. 任务分析和方案制定
  2. 分步骤实施
  3. 验证和测试
  4. 完成和反思

📁 工作空间：
  - 任务上下文：.claude/context/current-task.md
  - 任务文件：{任务文件路径}

💡 提醒：
  - 严格遵循绝对规则
  - 只提供实施建议，不直接修改代码
  - 遇到问题及时记录和寻求帮助
```

### 进度更新通知
```markdown
📈 任务进度更新：$task_name

✅ 已完成：
  - 步骤1：{描述}
  - 步骤2：{描述}

🔄 进行中：
  - 步骤3：{描述}（进度：60%）

⏳ 待完成：
  - 步骤4：{描述}
  - 步骤5：{描述}

⏰ 预计完成时间：{预估时间}
```

## 错误处理

### 任务不存在
```markdown
❌ 任务不存在：$ARGUMENTS

可能的原因：
1. 任务ID错误
2. 任务尚未创建
3. 任务文件已移动或删除

建议操作：
- 运行 /dd:status 查看可用任务
- 运行 /dd:epic-list 查看所有执行计划
- 确认任务ID格式正确
```

### 依赖未满足
```markdown
⚠️ 依赖条件未满足

依赖任务状态：
- 任务001：进行中（需要：已完成）
- 任务003：待开始（需要：已完成）

建议操作：
1. 先完成依赖任务
2. 确认任务可以并行执行
3. 联系团队确认依赖关系
```

## 最佳实践

### 任务执行原则
1. **小步快跑** - 将复杂任务分解为小步骤
2. **持续验证** - 每个步骤完成后进行验证
3. **及时记录** - 记录问题、决策和解决方案
4. **保持沟通** - 遇到阻碍及时寻求帮助

### 质量保证
1. **遵循规范** - 严格遵循编码规范和架构原则
2. **考虑影响** - 评估变更对其他组件的影响
3. **文档同步** - 保持文档与代码变更同步
4. **测试覆盖** - 确保变更有适当的测试（由用户执行）