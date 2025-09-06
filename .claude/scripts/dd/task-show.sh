#!/bin/bash

if [ $# -eq 0 ]; then
    echo "用法: /dd:task-show <任务ID>"
    echo "示例: /dd:task-show 001"
    exit 1
fi

TASK_ID="$1"

echo "显示任务详情..."
echo ""
echo ""

echo "📋 任务详情: #$TASK_ID"
echo "======================"
echo ""

# Find the task file
task_file=""
epic_name=""

for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue
  if [ -f "$epic_dir$TASK_ID.md" ]; then
    task_file="$epic_dir$TASK_ID.md"
    epic_name=$(basename "$epic_dir")
    break
  fi
done

if [ -z "$task_file" ]; then
  echo "❌ 未找到任务 #$TASK_ID"
  echo ""
  echo "💡 提示:"
  echo "  • 查看所有任务: /dd:task-list --all"
  echo "  • 查看 Epic 列表: /dd:epic-list"
  exit 1
fi

# Display task information
echo "📁 Epic: $epic_name"
echo "📄 文件: $task_file"
echo ""

# Extract and display metadata
name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
priority=$(grep "^priority:" "$task_file" | head -1 | sed 's/^priority: *//')
estimated_time=$(grep "^estimated_time:" "$task_file" | head -1 | sed 's/^estimated_time: *//')
depends_on=$(grep "^depends_on:" "$task_file" | head -1 | sed 's/^depends_on: *//')
parallel=$(grep "^parallel:" "$task_file" | head -1 | sed 's/^parallel: *//')
assignee=$(grep "^assignee:" "$task_file" | head -1 | sed 's/^assignee: *//')

# Display metadata with defaults
[ -n "$name" ] && echo "📝 名称: $name" || echo "📝 名称: (未命名)"
[ -n "$status" ] && echo "📊 状态: $status" || echo "📊 状态: open"
[ -n "$priority" ] && echo "🎯 优先级: $priority"
[ -n "$estimated_time" ] && echo "⏱️ 预估时间: $estimated_time"
[ -n "$assignee" ] && echo "👤 负责人: $assignee"
[ -n "$parallel" ] && [ "$parallel" = "true" ] && echo "🔄 可并行执行: 是"

# Check dependencies
if [ -n "$depends_on" ] && [ "$depends_on" != "depends_on:" ]; then
  echo ""
  echo "🔗 依赖关系:"
  deps=$(echo "$depends_on" | sed 's/^\[//' | sed 's/\]$//' | sed 's/,/ /g')
  for dep in $deps; do
    dep=$(echo "$dep" | xargs) # trim whitespace
    dep_file="$(dirname "$task_file")/$dep.md"
    if [ -f "$dep_file" ]; then
      dep_status=$(grep "^status:" "$dep_file" | head -1 | sed 's/^status: *//')
      dep_name=$(grep "^name:" "$dep_file" | head -1 | sed 's/^name: *//')
      [ -z "$dep_name" ] && dep_name="#$dep"
      
      case "$dep_status" in
        completed|done|closed)
          echo "  ✅ $dep_name (已完成)"
          ;;
        in-progress|started)
          echo "  🔄 $dep_name (进行中)"
          ;;
        blocked)
          echo "  🚫 $dep_name (被阻塞)"
          ;;
        *)
          echo "  ⏳ $dep_name (未开始)"
          ;;
      esac
    else
      echo "  ❌ #$dep (文件不存在)"
    fi
  done
fi

# Show task content (skip frontmatter)
echo ""
echo "📄 任务内容:"
echo "============"
echo ""

# Skip frontmatter and display content
in_frontmatter=false
first_line=true

while IFS= read -r line; do
  if [ "$first_line" = "true" ] && [ "$line" = "---" ]; then
    in_frontmatter=true
    first_line=false
    continue
  fi
  
  if [ "$in_frontmatter" = "true" ] && [ "$line" = "---" ]; then
    in_frontmatter=false
    continue
  fi
  
  if [ "$in_frontmatter" = "false" ]; then
    echo "$line"
  fi
  
  first_line=false
done < "$task_file"

# Show related tasks in same epic
echo ""
echo "🔍 同 Epic 中的其他任务:"
echo "========================"

other_tasks=$(ls "$(dirname "$task_file")"[0-9]*.md 2>/dev/null | grep -v "$task_file")
if [ -n "$other_tasks" ]; then
  echo "$other_tasks" | while read other_file; do
    other_id=$(basename "$other_file" .md)
    other_name=$(grep "^name:" "$other_file" | head -1 | sed 's/^name: *//')
    other_status=$(grep "^status:" "$other_file" | head -1 | sed 's/^status: *//')
    
    [ -z "$other_name" ] && other_name="(未命名)"
    [ -z "$other_status" ] && other_status="open"
    
    case "$other_status" in
      completed|done|closed)
        echo "  ✅ #$other_id - $other_name"
        ;;
      in-progress|started)
        echo "  🔄 #$other_id - $other_name"
        ;;
      blocked)
        echo "  🚫 #$other_id - $other_name"
        ;;
      *)
        echo "  📋 #$other_id - $other_name"
        ;;
    esac
  done
else
  echo "  (无其他任务)"
fi

echo ""

exit 0