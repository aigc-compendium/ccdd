#!/bin/bash

echo "同步项目上下文..."
echo ""
echo ""

echo "🔄 同步 DD 项目上下文"
echo "====================="
echo ""

echo "📊 收集统计信息..."

# Basic counts
prd_count=0
epic_count=0  
task_count=0

if [ -d ".claude/prds" ]; then
  prd_count=$(ls .claude/prds/*.md 2>/dev/null | wc -l)
fi

if [ -d ".claude/epics" ]; then
  epic_count=$(ls -d .claude/epics/*/ 2>/dev/null | wc -l)
  task_count=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l)
fi

echo "📝 同步结果:"
echo "  PRDs: $prd_count"
echo "  Epics: $epic_count"
echo "  任务: $task_count"

echo ""
echo "✅ 项目上下文同步完成！"

exit 0