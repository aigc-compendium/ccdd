#!/bin/bash

# DD 功能信息读取脚本
# 接收 <feature_name> 参数, 读取功能文件内容并返回给智能体

set -e

FEATURE_NAME="$1"
FEATURE_DIR=".claude/features/$FEATURE_NAME"

parse_feature_name() {
  if [ -z "$1" ]; then
    echo "ERROR: Missing feature parameter"
    exit 1
  fi
  
  FEATURE_NAME="$1"
  FEATURE_DIR=".claude/features/$FEATURE_NAME"
}

validate_feature_existence() {
  # 检查功能是否存在
  if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature '$FEATURE_NAME' does not exist"
    exit 1
  fi
  
  # 检查功能文件是否存在
  if [ ! -f "$FEATURE_DIR/feature.md" ]; then
    echo "ERROR: Feature file does not exist: $FEATURE_DIR/feature.md"
    exit 1
  fi
}

read_feature_content() {
  echo "=== GIT_STATUS_CHECK ==="
  if [ -x ".claude/scripts/dd/utils/git-check.sh" ]; then
    bash .claude/scripts/dd/utils/git-check.sh full-check "$FEATURE_NAME"
  else
    echo "⚠️  Git检查工具不可用, 跳过Git状态检查"
  fi
  echo ""
  
  echo "=== FEATURE_INFO ==="
  echo "FEATURE_NAME: $FEATURE_NAME"
  echo "FEATURE_DIR: $FEATURE_DIR"
  echo ""
  
  echo "=== FEATURE_METADATA ==="
  # 读取 feature.md 中的元数据
  grep "^name:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "name: $FEATURE_NAME"
  grep "^status:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "status: 未开始"
  grep "^progress:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "progress: 0"
  grep "^tasks_total:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "tasks_total: 0"
  grep "^tasks_completed:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "tasks_completed: 0"
  echo ""
  
  echo "=== TASK_STATS ==="
  local tasks_count=0
  local tasks_completed=0
  local tasks_in_progress=0
  
  if [ -d "$FEATURE_DIR/tasks" ]; then
    tasks_count=$(find "$FEATURE_DIR/tasks" -name "*.md" 2>/dev/null | wc -l)
    tasks_completed=$(find "$FEATURE_DIR/tasks" -name "*.md" -exec grep -l "^status: 已完成" {} \; 2>/dev/null | wc -l)
    tasks_in_progress=$(find "$FEATURE_DIR/tasks" -name "*.md" -exec grep -l "^status: 进行中" {} \; 2>/dev/null | wc -l)
  fi
  
  echo "TASKS_COUNT: $tasks_count"
  echo "TASKS_COMPLETED: $tasks_completed"
  echo "TASKS_IN_PROGRESS: $tasks_in_progress"
  echo ""
  
  echo "=== SESSION_CONTEXT ==="
  local session_file=".claude/context/session/$FEATURE_NAME.md"
  if [ -f "$session_file" ]; then
    echo "HAS_SESSION: true"
    echo "SESSION_FILE: $session_file"
  else
    echo "HAS_SESSION: false"
    echo "SESSION_FILE: "
  fi
  echo ""
  
  echo "=== GIT_STATUS ==="
  # 只读取 Git 状态信息, 不进行操作
  echo "WORKING_TREE_CLEAN: $(git diff --quiet && git diff --cached --quiet && echo "true" || echo "false")"
  echo "CURRENT_BRANCH: $(git branch --show-current)"
  echo "UNCOMMITTED_FILES: $(git status --porcelain | wc -l | tr -d ' ')"
  echo ""
  
  echo "=== FEATURE_CONTENT ==="
  # 输出完整的功能文档内容
  cat "$FEATURE_DIR/feature.md"
  echo ""
  
  # 如果存在技术文档, 也输出
  if [ -f "$FEATURE_DIR/technical.md" ]; then
    echo "=== TECHNICAL_CONTENT ==="
    cat "$FEATURE_DIR/technical.md"
    echo ""
  fi
  
  # 输出任务列表信息
  if [ -d "$FEATURE_DIR/tasks" ] && [ "$tasks_count" -gt 0 ]; then
    echo "=== TASKS_INFO ==="
    find "$FEATURE_DIR/tasks" -name "*.md" | sort | while read task_file; do
      task_id=$(basename "$task_file" .md)
      task_name=$(grep "^name:" "$task_file" 2>/dev/null | sed 's/^name: *//' || echo "")
      task_status=$(grep "^status:" "$task_file" 2>/dev/null | sed 's/^status: *//' || echo "未开始")
      echo "TASK_$task_id: $task_name [$task_status]"
    done
    echo ""
  fi
}

main() {
  parse_feature_name "$1"
  validate_feature_existence
  read_feature_content
}

main "$@"