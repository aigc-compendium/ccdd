---
allowed-tools: Bash, Read, Task
---

# AI 代码反思

使用 AI 智能分析最近的代码变更，提供深入的反思和改进建议。

## 用法
```
/dd:code-reflect [--详细]
```

## 参数说明
- `--详细` - 提供更详细的分析报告（可选）

## 功能特点

### 智能变更分析
- 自动检测最近的代码变更
- AI 分析变更的合理性和质量
- 识别潜在的问题和改进点

### 全面的反思维度
- **功能正确性** - 变更是否达到预期目标
- **代码质量** - 可读性、可维护性、复用性
- **安全性** - 潜在安全风险识别
- **性能影响** - 性能优化机会
- **架构一致性** - 是否符合项目架构模式

## 执行流程

### 1. 检测代码变更
```bash
echo "🔍 检测代码变更..."

# 检查是否在git仓库中
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ 当前目录不是git仓库"
  exit 1
fi

# 获取变更状态
changed_files=$(git status --porcelain)
staged_changes=$(git diff --staged --name-only)
unstaged_changes=$(git diff --name-only)

if [ -z "$changed_files" ]; then
  echo "ℹ️ 没有检测到代码变更"
  echo "💡 如果刚完成开发，请先用 git add 添加变更"
  exit 0
fi

echo "📊 发现变更："
echo "$changed_files" | head -20
if [ $(echo "$changed_files" | wc -l) -gt 20 ]; then
  echo "... (共 $(echo "$changed_files" | wc -l) 个文件)"
fi
echo ""
```

### 2. AI 智能分析
使用 AI 分析代码变更：

```yaml
Task:
  description: "AI代码反思分析"
  subagent_type: "code-analyzer" 
  prompt: |
    请对以下代码变更进行深入的反思分析：
    
    ## 变更概述
    $(if [ -n "$staged_changes" ]; then
      echo "已暂存的变更："
      echo "$staged_changes"
      echo ""
      echo "变更内容："
      git diff --staged
    fi)
    
    $(if [ -n "$unstaged_changes" ]; then
      echo "未暂存的变更："
      echo "$unstaged_changes" 
      echo ""
      echo "变更内容："
      git diff
    fi)
    
    ## 分析要求
    
    请从以下维度进行反思分析：
    
    ### 1. 功能正确性 (25%)
    - 变更是否解决了预期的问题？
    - 逻辑是否正确和完整？
    - 边界情况是否得到处理？
    
    ### 2. 代码质量 (25%)
    - 代码是否清晰易读？
    - 是否遵循项目的编码规范？
    - 是否有适当的注释和文档？
    - 是否存在代码重复？
    
    ### 3. 安全性 (20%)
    - 是否引入了安全漏洞？
    - 输入验证是否充分？
    - 敏感信息是否得到保护？
    
    ### 4. 性能影响 (15%)
    - 是否影响系统性能？
    - 算法复杂度是否合理？
    - 资源使用是否高效？
    
    ### 5. 架构一致性 (15%)
    - 是否符合项目架构模式？
    - 模块职责是否清晰？
    - 依赖关系是否合理？
    
    ## 输出格式
    
    ```
    🤔 AI代码反思报告
    
    📊 整体评估：[优秀/良好/一般/需改进] (X/100分)
    
    ## 🎯 核心发现
    
    ### ✅ 做得好的地方
    - [具体的正面评价]
    - [另一个正面评价]
    
    ### ⚠️ 需要关注的问题
    - [具体问题描述] (优先级：高/中/低)
    - [另一个问题] (优先级：高/中/低)
    
    ### 💡 改进建议
    - [具体的改进建议]
    - [另一个改进建议]
    
    ## 📋 详细分析
    
    **功能正确性 (X/25)**
    [详细分析内容]
    
    **代码质量 (X/25)**
    [详细分析内容]
    
    **安全性 (X/20)**
    [详细分析内容]
    
    **性能影响 (X/15)**
    [详细分析内容]
    
    **架构一致性 (X/15)**
    [详细分析内容]
    
    ## 🎯 下一步建议
    
    优先级排序的具体行动建议：
    1. [最重要的改进行动]
    2. [次要的改进行动]
    3. [长期优化建议]
    ```
    
    请基于实际的代码变更内容进行分析，给出具体、可操作的建议。
```

### 3. 补充分析
根据参数提供额外分析：

```bash
if [ "$1" = "--详细" ]; then
  echo "🔬 执行详细分析..."
  
  # 统计变更规模
  added_lines=$(git diff --staged --numstat | awk '{sum+=$1} END {print sum+0}')
  deleted_lines=$(git diff --staged --numstat | awk '{sum+=$2} END {print sum+0}')
  
  echo ""
  echo "📈 变更统计："
  echo "  新增行数：$added_lines"
  echo "  删除行数：$deleted_lines"
  echo "  净变更：$((added_lines - deleted_lines)) 行"
  echo "  影响文件：$(echo "$staged_changes" | wc -l) 个"
  echo ""
  
  # 检查测试覆盖
  test_files=$(echo "$staged_changes" | grep -E '\.(test|spec)\.' | wc -l)
  if [ "$test_files" -gt 0 ]; then
    echo "✅ 包含测试文件：$test_files 个"
  else
    echo "⚠️ 未检测到测试文件"
  fi
  echo ""
fi
```

### 4. 生成反思摘要
```bash
echo "📝 反思完成"
echo ""
echo "💡 使用建议："
echo "  • 根据AI分析优化代码"
echo "  • 解决标识的关键问题"  
echo "  • 完善测试覆盖"
echo "  • 更新相关文档"
```

## 使用场景

### 任务完成后
```bash
# 完成开发任务后进行反思
/dd:code-reflect
```

### 深度分析
```bash
# 获得详细的变更分析报告
/dd:code-reflect --详细
```

### 团队协作
```bash
# 代码提交前的最终检查
git add .
/dd:code-reflect --详细
# 根据建议优化后再提交
```

## 注意事项

- 需要在 git 仓库中执行
- 建议在有实际变更时使用
- AI 分析需要一定时间，请耐心等待
- 建议结合人工判断使用AI建议