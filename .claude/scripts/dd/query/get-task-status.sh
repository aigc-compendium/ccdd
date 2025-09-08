#!/bin/bash

# DD 任务状态读取脚本
# 读取任务文档的状态和进度信息

set -e

TASK_ID=""
FEATURE_NAME=""
TASK_NUMBER=""
TASK_FILE=""

parse_task_id() {
  if [ -z "$1" ]; then
    echo "ERROR: Missing task parameter"
    exit 1
  fi
  
  # 解析功能名和任务编号
  if [[ "$1" == *":"* ]]; then
    FEATURE_NAME="${1%:*}"
    TASK_NUMBER="${1#*:}"
  else
    echo "ERROR: Invalid task format. Expected: <feature>:<task_id>"
    exit 1
  fi
  
  TASK_ID="$1"
  TASK_FILE=".claude/features/$FEATURE_NAME/tasks/$TASK_NUMBER.md"
}

read_task_status() {
  echo "=== TASK_STATUS_READ ==="
  echo "TASK_ID: $TASK_ID"
  echo "FEATURE_NAME: $FEATURE_NAME"
  echo "TASK_NUMBER: $TASK_NUMBER"
  echo "TASK_FILE: $TASK_FILE"
  echo ""
  
  # 检查任务文件是否存在
  if [ ! -f "$TASK_FILE" ]; then
    echo "ERROR: Task file does not exist: $TASK_FILE"
    exit 1
  fi
  
  echo "=== TASK_METADATA ==="
  # 读取 YAML frontmatter 中的关键信息
  name=$(grep "^name:" "$TASK_FILE" 2>/dev/null | sed 's/^name: *//' || echo "")
  status=$(grep "^status:" "$TASK_FILE" 2>/dev/null | sed 's/^status: *//' || echo "未开始")
  progress=$(grep "^progress:" "$TASK_FILE" 2>/dev/null | sed 's/^progress: *//' || echo "0")
  estimated_hours=$(grep "^estimated_hours:" "$TASK_FILE" 2>/dev/null | sed 's/^estimated_hours: *//' || echo "8")
  priority=$(grep "^priority:" "$TASK_FILE" 2>/dev/null | sed 's/^priority: *//' || echo "中等")
  
  echo "NAME: $name"
  echo "STATUS: $status"
  echo "PROGRESS: $progress"
  echo "ESTIMATED_HOURS: $estimated_hours"
  echo "PRIORITY: $priority"
  echo ""
  
  echo "=== TODO_ANALYSIS ==="
  # 分析 TODO 项目完成情况
  total_todos=$(grep -c "^- \[" "$TASK_FILE" 2>/dev/null || echo "0")
  completed_todos=$(grep -c "^- \[x\]" "$TASK_FILE" 2>/dev/null || echo "0")
  
  echo "TOTAL_TODOS: $total_todos"
  echo "COMPLETED_TODOS: $completed_todos"
  
  if [ "$total_todos" -gt 0 ]; then
    todo_progress=$(echo "scale=0; $completed_todos * 100 / $total_todos" | bc)
    echo "TODO_PROGRESS: ${todo_progress}%"
  else
    echo "TODO_PROGRESS: 0%"
  fi
  echo ""
  
  echo "=== SESSION_CONTEXT ==="
  # 检查会话上下文文件
  session_file=".claude/context/session/$TASK_NUMBER.md"
  if [ -f "$session_file" ]; then
    echo "SESSION_FILE: EXISTS"
    echo "LAST_MODIFIED: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$session_file")"
  else
    echo "SESSION_FILE: NOT_EXISTS"
  fi
  echo ""
  
  echo "=== TASK_CONTENT ==="
  echo "--- FULL_CONTENT ---"
  cat "$TASK_FILE"
  echo ""
  
  echo "✅ Task status read completed: $TASK_ID"
}

main() {
  case "${1:-}" in
    "--help"|"-h"|"help")
      echo "DD 任务状态读取工具"
      echo "用法: $0 <feature>:<task_id>"
      echo "示例: $0 用户认证系统:001"
      ;;
    "")
      echo "ERROR: Missing task parameter"
      echo "用法: $0 <feature>:<task_id>"
      exit 1
      ;;
    *)
      parse_task_id "$1"
      read_task_status
      ;;
  esac
}

main "$@"