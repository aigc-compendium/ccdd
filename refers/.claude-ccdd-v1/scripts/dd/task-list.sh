#!/bin/bash

echo "获取任务列表..."
echo ""
echo ""

echo "📋 任务列表"
echo "============"
echo ""

if [ ! -d ".claude/epics" ]; then
  echo "📁 未找到 Epic 目录"
  exit 0
fi

found=0

for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue
  epic_name=$(basename "$epic_dir")

  for task_file in "$epic_dir"[0-9]*.md; do
    [ -f "$task_file" ] || continue
    
    task_num=$(basename "$task_file" .md)
    task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
    status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
    
    [ -z "$task_name" ] && task_name="(未命名)"
    [ -z "$status" ] && status="open"
    
    case "$status" in
      completed|done|closed)
        echo "✅ #$task_num - $task_name"
        ;;
      in-progress|started)
        echo "🔄 #$task_num - $task_name"
        ;;
      blocked)
        echo "🚫 #$task_num - $task_name"
        ;;
      *)
        echo "📋 #$task_num - $task_name"
        ;;
    esac
    echo "   Epic: $epic_name"
    echo ""
    ((found++))
  done
done

if [ $found -eq 0 ]; then
  echo "未找到任务"
fi

echo "📊 总计: $found 个任务"
echo ""

exit 0