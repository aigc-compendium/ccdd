#!/bin/bash

# AI 代码反思脚本
# 使用 AI 智能分析代码变更，提供深入的反思和改进建议

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

# 检查是否需要详细分析
detailed_analysis=false
if [ "$1" = "--详细" ]; then
  detailed_analysis=true
  echo "🔬 执行详细分析..."
  
  # 统计变更规模
  added_lines=$(git diff --staged --numstat 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
  deleted_lines=$(git diff --staged --numstat 2>/dev/null | awk '{sum+=$2} END {print sum+0}')
  
  echo ""
  echo "📈 变更统计："
  echo "  新增行数：$added_lines"
  echo "  删除行数：$deleted_lines"
  echo "  净变更：$((added_lines - deleted_lines)) 行"
  echo "  影响文件：$(echo "$staged_changes $unstaged_changes" | wc -w) 个"
  echo ""
  
  # 检查测试覆盖
  test_files=$(echo "$staged_changes $unstaged_changes" | tr ' ' '\n' | grep -E '\.(test|spec)\.' | wc -l)
  if [ "$test_files" -gt 0 ]; then
    echo "✅ 包含测试文件：$test_files 个"
  else
    echo "⚠️ 未检测到测试文件"
  fi
  echo ""
fi

# 准备变更概述
echo "🤖 启动AI分析..."

# 构建变更概述
change_summary=""
if [ -n "$staged_changes" ]; then
  change_summary+="## 已暂存的变更：\n"
  change_summary+="$staged_changes\n\n"
  change_summary+="### 变更内容：\n"
  change_summary+="\`\`\`diff\n"
  change_summary+="$(git diff --staged)\n"
  change_summary+="\`\`\`\n\n"
fi

if [ -n "$unstaged_changes" ]; then
  change_summary+="## 未暂存的变更：\n"
  change_summary+="$unstaged_changes\n\n"
  change_summary+="### 变更内容：\n"
  change_summary+="\`\`\`diff\n"
  change_summary+="$(git diff)\n"
  change_summary+="\`\`\`\n\n"
fi

# 启动AI分析（这里是模拟，实际会调用AI服务）
echo "请对以下代码变更进行深入的反思分析："
echo ""
echo -e "$change_summary"

echo ""
echo "📋 分析维度："
echo "  • 功能正确性 (25%)"
echo "  • 代码质量 (25%)"  
echo "  • 安全性 (20%)"
echo "  • 性能影响 (15%)"
echo "  • 架构一致性 (15%)"

echo ""
echo "📝 反思完成"
echo ""
echo "💡 使用建议："
echo "  • 根据AI分析优化代码"
echo "  • 解决标识的关键问题"  
echo "  • 完善测试覆盖"
echo "  • 更新相关文档"

exit 0