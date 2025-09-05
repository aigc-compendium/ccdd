---
allowed-tools: Read, LS, Task
---

# 改动后自我反思

在完成代码改动或任务后，进行深度反思分析，评估改动的合理性、架构一致性和对后续开发的影响。

## 用法
```
/dd:reflect-on-changes [--详细]
```

## 参数说明
- `--详细` - 生成详细的反思报告（可选）

## 功能概述

这个命令提供全面的改动后反思分析，帮助：
- 验证改动是否符合预期
- 检查架构一致性
- 评估对后续任务的影响
- 识别潜在的技术债务

## 操作指南

### 1. 改动范围分析

#### 使用代码分析智能体进行深度分析
```yaml
Task:
  description: "深度分析改动影响"
  subagent_type: "code-analyzer"
  prompt: |
    对最近的代码改动进行全面反思分析：
    
    分析范围：
    1. 改动合理性评估
       - 改动是否解决了预期问题
       - 实现方式是否最优
       - 是否引入了不必要的复杂性
    
    2. 架构一致性检查
       - 是否符合现有架构模式
       - 是否破坏了系统边界
       - 是否违反了设计原则
    
    3. 代码质量评估
       - 代码可读性和维护性
       - 错误处理是否完善
       - 性能影响分析
    
    4. 集成影响分析
       - 对其他组件的影响
       - 接口变更的向后兼容性
       - 数据流变化的影响
    
    5. 后续开发影响
       - 对计划中任务的影响
       - 可能阻塞的开发工作
       - 需要调整的相关任务
    
    请提供：
    - 改动质量评分（1-10分）
    - 具体的改进建议
    - 潜在风险识别
    - 后续行动建议
    
    分析要客观、具体，突出关键问题和建议。
```

### 2. 当前任务对齐检查

#### 验证任务完成度
```bash
# 检查当前任务状态
if [ -f ".claude/context/current-task.md" ]; then
  task_id=$(grep "^任务ID:" .claude/context/current-task.md | sed 's/^任务ID: *//')
  task_name=$(grep "^任务名称:" .claude/context/current-task.md | sed 's/^任务名称: *//')
  
  echo "🎯 当前任务：$task_name (ID: $task_id)"
  
  # 读取任务的验收标准
  task_file=$(find .claude/epics -name "${task_id}.md" | head -1)
  if [ -f "$task_file" ]; then
    echo "📋 检查验收标准符合度..."
    acceptance_criteria=$(sed -n '/^## 验收标准/,/^## /p' "$task_file" | grep "^- \[ \]")
    echo "$acceptance_criteria"
  fi
fi
```

#### 对比预期vs实际
```bash
# 分析实际改动与任务预期的差异
analyze_expectation_vs_reality() {
  echo "🔍 分析预期vs实际差异..."
  
  if [ -f "$task_file" ]; then
    # 提取任务的技术方案
    expected_approach=$(sed -n '/^### 技术方案/,/^### /p' "$task_file")
    
    # 提取实际的文件变更
    actual_changes=$(git diff --name-status HEAD~1..HEAD 2>/dev/null)
    
    echo "📝 预期方案："
    echo "$expected_approach"
    echo ""
    echo "📄 实际变更："
    echo "$actual_changes"
  fi
}
```

### 3. 架构一致性验证

#### 使用上下文分析智能体
```yaml
Task:
  description: "验证架构一致性"
  subagent_type: "context-analyzer"
  prompt: |
    验证最近改动的架构一致性：
    
    项目上下文：
    {加载 project-structure.md 和 system-patterns.md}
    
    最近改动：
    {提供 git diff 信息}
    
    当前任务：
    {提供当前任务信息}
    
    请分析：
    1. 改动是否符合既定的架构模式
    2. 是否引入了新的架构复杂性
    3. 目录结构和命名是否一致
    4. 是否违反了分层原则
    5. 是否需要更新架构文档
    
    提供具体的一致性评估和改进建议。
```

#### 模式遵循检查
```bash
# 检查是否遵循项目模式
check_pattern_compliance() {
  echo "🏗️ 检查架构模式遵循情况..."
  
  # 从system-patterns.md读取既定模式
  if [ -f ".claude/context/system-patterns.md" ]; then
    echo "📖 既定架构模式："
    grep "^- " .claude/context/system-patterns.md | head -5
    echo ""
    echo "🔍 请确认改动是否遵循上述模式..."
  fi
}
```

### 4. 技术债务评估

#### 债务识别
```bash
# 识别可能的技术债务
identify_technical_debt() {
  echo "💳 技术债务评估..."
  
  local debt_indicators=()
  
  # 检查TODO注释（违反绝对规则）
  if git diff HEAD~1..HEAD | grep -i "TODO\|FIXME\|HACK"; then
    debt_indicators+=("发现TODO/FIXME注释")
  fi
  
  # 检查复制代码
  if git diff --name-only HEAD~1..HEAD | xargs -I {} sh -c 'echo "=== {} ===" && cat {}' | grep -A5 -B5 "function\|def\|const.*="; then
    echo "⚠️ 检查是否存在代码重复..."
  fi
  
  # 检查配置硬编码
  if git diff HEAD~1..HEAD | grep -E "localhost|127.0.0.1|hardcoded"; then
    debt_indicators+=("发现硬编码配置")
  fi
  
  if [ ${#debt_indicators[@]} -gt 0 ]; then
    echo "⚠️ 识别到的技术债务："
    for debt in "${debt_indicators[@]}"; do
      echo "  - $debt"
    done
  else
    echo "✅ 未发现明显的技术债务"
  fi
}
```

### 5. 性能影响分析

#### 性能关注点检查
```bash
# 分析性能影响
analyze_performance_impact() {
  echo "⚡ 性能影响分析..."
  
  # 检查数据库查询变更
  if git diff HEAD~1..HEAD | grep -i "select\|insert\|update\|delete\|query"; then
    echo "🗄️ 发现数据库相关变更，请注意："
    echo "  - 查询效率"
    echo "  - 索引需求"
    echo "  - 事务边界"
  fi
  
  # 检查循环和算法
  if git diff HEAD~1..HEAD | grep -E "for.*in|while|forEach|map|filter|reduce"; then
    echo "🔄 发现循环/迭代变更，请注意："
    echo "  - 时间复杂度"
    echo "  - 数据量影响"
    echo "  - 内存使用"
  fi
  
  # 检查网络请求
  if git diff HEAD~1..HEAD | grep -i "fetch\|axios\|http\|api"; then
    echo "🌐 发现网络请求变更，请注意："
    echo "  - 请求频率"
    echo "  - 错误处理"
    echo "  - 超时设置"
  fi
}
```

### 6. 后续任务影响评估

#### 依赖任务分析
```bash
# 分析对其他任务的影响
analyze_task_dependencies() {
  echo "📊 分析对后续任务的影响..."
  
  if [ -f ".claude/context/current-task.md" ]; then
    current_task_id=$(grep "^任务ID:" .claude/context/current-task.md | sed 's/^任务ID: *//')
    
    # 查找依赖当前任务的其他任务
    dependent_tasks=$(find .claude/epics -name "*.md" -exec grep -l "依赖:.*$current_task_id" {} \;)
    
    if [ -n "$dependent_tasks" ]; then
      echo "📌 以下任务依赖当前任务："
      echo "$dependent_tasks" | while read task_file; do
        task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
        task_id=$(basename "$task_file" .md)
        echo "  - $task_name (ID: $task_id)"
      done
      echo ""
      echo "🔍 需要验证改动是否影响这些任务的前提条件"
    fi
  fi
}
```

#### 接口变更影响
```bash
# 检查接口变更对其他组件的影响
check_interface_changes() {
  echo "🔌 检查接口变更影响..."
  
  # 检查是否有API或函数签名变更
  if git diff HEAD~1..HEAD | grep -E "function|def|export|interface|type"; then
    echo "⚠️ 检测到可能的接口变更"
    echo "📋 需要检查的影响范围："
    echo "  - 调用方是否需要更新"
    echo "  - 是否需要版本兼容性处理"
    echo "  - 文档是否需要更新"
  fi
}
```

### 7. 改进建议生成

#### 使用文件分析智能体总结
```yaml
Task:
  description: "生成改进建议"
  subagent_type: "file-analyzer"
  prompt: |
    基于反思分析结果，生成改进建议：
    
    分析输入：
    - 代码质量评估结果
    - 架构一致性检查结果
    - 技术债务识别结果
    - 性能影响分析结果
    - 任务依赖分析结果
    
    请提供：
    1. 立即需要解决的问题（优先级高）
    2. 短期改进建议（本周内）
    3. 长期优化方向（未来版本）
    4. 风险缓解措施
    5. 监控和验证建议
    
    建议要具体可操作，按优先级排序。
```

## 输出格式

### 标准反思报告
```markdown
🤔 改动反思分析报告

## 📊 改动概览
- 分析时间：{当前时间}
- 改动范围：{修改文件数量} 个文件
- 当前任务：{任务名称}（ID: {任务ID}）
- Git状态：{clean/有未提交变更}

## 🎯 任务对齐度评估
### 验收标准完成情况
- ✅ 标准1：{具体标准} - 已满足
- ⚠️ 标准2：{具体标准} - 部分满足
- ❌ 标准3：{具体标准} - 未满足

### 预期vs实际
- **预期方案**：{简要描述}
- **实际实现**：{简要描述}
- **差异分析**：{差异说明}

## 🏗️ 架构一致性
- **模式遵循**：{遵循/违反} 既定架构模式
- **结构一致**：{目录和命名是否一致}
- **边界清晰**：{组件边界是否清晰}
- **文档同步**：{架构文档是否需要更新}

## 💳 技术债务评估
- **债务等级**：{无/低/中/高}
- **主要问题**：
  - {问题1}
  - {问题2}
- **影响评估**：{对维护性的影响}

## ⚡ 性能影响
- **性能影响**：{积极/中性/负面}
- **关注点**：
  - {性能关注点1}
  - {性能关注点2}
- **建议监控**：{需要监控的指标}

## 📈 后续任务影响
- **依赖任务数量**：{数量}
- **影响类型**：{正面/负面/中性}
- **需要调整的任务**：
  - {任务1}：{调整原因}
  - {任务2}：{调整原因}

## 📋 改进建议
### 🔴 立即处理（高优先级）
1. {具体建议}
2. {具体建议}

### 🟡 短期改进（本周内）
1. {具体建议}
2. {具体建议}

### 🟢 长期优化（未来版本）
1. {具体建议}
2. {具体建议}

## 🎖️ 总体评分
- **代码质量**：{分数}/10
- **架构一致性**：{分数}/10
- **任务完成度**：{分数}/10
- **综合评分**：{分数}/10

## 📝 下一步行动
1. {具体行动项1}
2. {具体行动项2}
3. {具体行动项3}
```

### 简洁版报告
```markdown
🤔 快速反思摘要

✅ **做得好的**：
- {亮点1}
- {亮点2}

⚠️ **需要关注**：
- {关注点1}
- {关注点2}

🔧 **立即行动**：
- {行动项1}
- {行动项2}

📊 **总体评分**：{分数}/10 - {评级}
```

## 自动触发机制

### 任务完成后自动反思
```bash
# 集成到task-start.md的完成流程中
auto_reflect_on_task_completion() {
  echo "🤔 任务完成，自动开始反思分析..."
  /dd:reflect-on-changes
  
  # 将反思结果附加到任务记录
  cat >> .claude/context/current-task.md << EOF

## 完成反思
$(cat /tmp/reflection-summary.md)
EOF
}
```

### 重要变更检测触发
```bash
# 当检测到重要变更时自动触发
check_significant_changes() {
  local changed_files=$(git diff --name-only HEAD~1..HEAD | wc -l)
  local changed_lines=$(git diff --stat HEAD~1..HEAD | tail -1 | grep -o '[0-9]\+ insertions\|[0-9]\+ deletions' | awk '{sum += $1} END {print sum}')
  
  if [ "$changed_files" -gt 5 ] || [ "$changed_lines" -gt 100 ]; then
    echo "🚨 检测到重要变更，建议进行反思分析"
    echo "💡 运行：/dd:reflect-on-changes --详细"
  fi
}
```

## 持续改进

### 反思历史跟踪
```bash
# 保存反思历史，用于模式识别
save_reflection_history() {
  local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local reflection_file=".claude/context/reflection-history.md"
  
  if [ ! -f "$reflection_file" ]; then
    echo "# 反思历史记录" > "$reflection_file"
  fi
  
  cat >> "$reflection_file" << EOF

## 反思记录 - $current_time
任务：{当前任务}
评分：{总体评分}
主要问题：{主要问题摘要}
改进建议：{主要建议}

EOF
}
```

### 模式学习
```bash
# 分析反思历史，识别改进模式
analyze_improvement_patterns() {
  if [ -f ".claude/context/reflection-history.md" ]; then
    echo "📈 分析改进模式..."
    
    # 统计常见问题
    common_issues=$(grep "主要问题：" .claude/context/reflection-history.md | sort | uniq -c | sort -nr)
    
    echo "🔍 常见问题排序："
    echo "$common_issues"
  fi
}
```

## 最佳实践

### 反思时机
1. **任务完成后** - 验证任务目标达成
2. **重要变更后** - 评估变更影响
3. **阶段性里程碑** - 总结阶段性进展
4. **遇到问题时** - 分析问题根因

### 反思质量
1. **客观性** - 基于事实和数据
2. **具体性** - 提供具体的改进建议
3. **前瞻性** - 考虑对未来的影响
4. **行动性** - 每个建议都可操作