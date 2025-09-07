#!/bin/bash

echo "获取被阻塞任务..."
echo ""
echo ""

echo "🚫 被阻塞的任务"
echo "================"
echo ""

found=0

if [ ! -d ".claude/epics" ]; then
  echo "📁 未找到 Epic 目录"
  exit 0
fi

for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue
  epic_name=$(basename "$epic_dir")

  for task_file in "$epic_dir"[0-9]*.md; do
    [ -f "$task_file" ] || continue
    
    status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
    if [ "$status" = "blocked" ]; then
      task_num=$(basename "$task_file" .md)
      task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
      [ -z "$task_name" ] && task_name="(未命名)"
      
      echo "🚫 #$task_num - $task_name"
      echo "   Epic: $epic_name"
      echo ""
      ((found++))
    fi
  done
done

if [ $found -eq 0 ]; then
  echo "🎉 没有被阻塞的任务！"
fi

echo "📊 被阻塞任务: $found 个"

exit 0