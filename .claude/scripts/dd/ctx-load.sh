#!/bin/bash

echo "加载项目上下文..."
echo ""
echo ""

echo "🔄 加载 DD 项目上下文"
echo "====================="
echo ""

echo "📋 项目概览:"

# PRDs
if [ -d ".claude/prds" ]; then
  prd_count=$(ls .claude/prds/*.md 2>/dev/null | wc -l)
  echo "  PRDs: $prd_count 个"
fi

# Epics  
if [ -d ".claude/epics" ]; then
  epic_count=$(ls -d .claude/epics/*/ 2>/dev/null | wc -l)
  echo "  Epics: $epic_count 个"
fi

# Tasks
if [ -d ".claude/epics" ]; then
  task_count=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l)
  echo "  任务: $task_count 个"
fi

echo ""
echo "🎯 常用命令:"
echo "  /dd:status - 查看详细状态"
echo "  /dd:task-list - 查看任务列表"
echo "  /dd:help - 查看帮助"

echo ""
echo "✅ 上下文加载完成！"

exit 0