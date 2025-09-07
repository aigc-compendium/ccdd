#!/bin/bash

# DD 任务信息读取脚本
# 接收 <feature>:<task_id> 参数, 读取任务文件内容并返回给智能体

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

validate_task_existence() {
  # 检查功能是否存在
  if [ ! -d ".claude/features/$FEATURE_NAME" ]; then
    echo "ERROR: Feature '$FEATURE_NAME' does not exist"
    exit 1
  fi
  
  # 检查任务文件是否存在
  if [ ! -f "$TASK_FILE" ]; then
    echo "ERROR: Task file does not exist: $TASK_FILE"
    exit 1
  fi
}

read_task_content() {
  # 提取关键信息
  local task_name=$(grep "^name:" "$TASK_FILE" 2>/dev/null | cut -d' ' -f2- || echo "")
  local status=$(grep "^status:" "$TASK_FILE" 2>/dev/null | cut -d' ' -f2- || echo "未开始")
  local progress=$(grep "^progress:" "$TASK_FILE" 2>/dev/null | cut -d' ' -f2- || echo "0")
  local priority=$(grep "^priority:" "$TASK_FILE" 2>/dev/null | cut -d' ' -f2- || echo "中")
  local difficulty=$(grep "^difficulty:" "$TASK_FILE" 2>/dev/null | cut -d' ' -f2- || echo "中等")
  local estimated_hours=$(grep "^estimated_hours:" "$TASK_FILE" 2>/dev/null | cut -d' ' -f2- || echo "8")
  local dependencies=$(grep "^dependencies:" "$TASK_FILE" 2>/dev/null | cut -d' ' -f2- || echo "[]")
  local pending_todos=$(grep -c "^- \[ \]" "$TASK_FILE" 2>/dev/null | tr -d '\n' || echo "0")
  local completed_todos=$(grep -c "^- \[x\]" "$TASK_FILE" 2>/dev/null | tr -d '\n' || echo "0")
  local total_todos=$((${pending_todos:-0} + ${completed_todos:-0}))
  local session_file=".claude/context/session/$TASK_ID.md"
  local has_session=$([ -f "$session_file" ] && echo "true" || echo "false")
  
  # 紧凑格式一次性输出
  cat << EOF
=== TASK_INFO ===
TASK_ID: $TASK_ID
FEATURE: $FEATURE_NAME
STATUS: $status
PROGRESS: $progress%
PRIORITY: $priority
DIFFICULTY: $difficulty
HOURS: $estimated_hours
TODOS: $completed_todos/$total_todos completed
SESSION: $has_session
DEPENDENCIES: $dependencies

=== TASK_CONTENT ===
$(cat "$TASK_FILE")
EOF
}

main() {
  parse_task_id "$1"
  validate_task_existence
  read_task_content
}

main "$@"