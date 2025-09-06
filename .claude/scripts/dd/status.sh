#!/bin/bash

echo "获取状态..."
echo ""
echo ""

echo "📊 DD 系统状态"
echo "================"
echo ""

echo "📄 PRDs:"
if [ -d ".claude/prds" ]; then
  total=$(ls .claude/prds/*.md 2>/dev/null | wc -l)
  echo "  总数: $total"
else
  echo "  未找到 PRD"
fi

echo ""
echo "📚 Epics:"
if [ -d ".claude/epics" ]; then
  total=$(ls -d .claude/epics/*/ 2>/dev/null | wc -l)
  echo "  总数: $total"
else
  echo "  未找到 Epic"
fi

echo ""
echo "📝 任务:"
if [ -d ".claude/epics" ]; then
  total=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l)
  open=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *open" {} \; 2>/dev/null | wc -l)
  closed=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l)
  echo "  未开始: $open"
  echo "  已完成: $closed"
  echo "  总数: $total"
else
  echo "  未找到任务"
fi

echo ""

exit 0