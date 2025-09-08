#!/bin/bash

# DD 功能状态读取脚本
# 读取功能文档的状态和进度信息，包括所有子任务状态

set -e

FEATURE_NAME="$1"
FEATURE_DIR=".claude/features/$FEATURE_NAME"

if [ -z "$FEATURE_NAME" ]; then
  echo "ERROR: Missing feature name parameter"
  echo "用法: $0 <feature_name>"
  exit 1
fi

read_feature_status() {
  echo "=== FEATURE_STATUS_READ ==="
  echo "FEATURE_NAME: $FEATURE_NAME"
  echo "FEATURE_DIR: $FEATURE_DIR"
  echo ""
  
  # 检查功能目录是否存在
  if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature directory does not exist: $FEATURE_DIR"
    exit 1
  fi
  
  # 检查功能文档是否存在
  if [ ! -f "$FEATURE_DIR/overview.md" ]; then
    echo "ERROR: Feature document does not exist: $FEATURE_DIR/overview.md"
    exit 1
  fi
  
  echo "=== FEATURE_METADATA ==="
  # 读取功能文档的元数据
  status=$(grep "^status:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^status: *//' || echo "未开始")
  progress=$(grep "^progress:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^progress: *//' || echo "0")
  priority=$(grep "^priority:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^priority: *//' || echo "中等")
  estimated_hours=$(grep "^estimated_hours:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^estimated_hours: *//' || echo "40")
  complexity=$(grep "^complexity:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^complexity: *//' || echo "中等")
  
  echo "STATUS: $status"
  echo "PROGRESS: $progress"
  echo "PRIORITY: $priority"
  echo "ESTIMATED_HOURS: $estimated_hours"
  echo "COMPLEXITY: $complexity"
  echo ""
  
  echo "=== FEATURE_FILES_STATUS ==="
  # 检查关键文档文件状态
  feature_files=("overview.md" "technical.md" "acceptance.md")
  for file in "${feature_files[@]}"; do
    if [ -f "$FEATURE_DIR/$file" ]; then
      echo "$file: EXISTS"
    else
      echo "$file: MISSING"
    fi
  done
  echo ""
  
  echo "=== TASKS_ANALYSIS ==="
  # 分析任务状态
  if [ -d "$FEATURE_DIR/tasks" ]; then
    task_files=$(find "$FEATURE_DIR/tasks" -name "*.md" 2>/dev/null | wc -l | xargs)
    echo "TOTAL_TASKS: $task_files"
    
    if [ "$task_files" -gt 0 ]; then
      completed_tasks=0
      in_progress_tasks=0
      pending_tasks=0
      total_estimated_hours=0
      
      echo "--- TASK_DETAILS ---"
      find "$FEATURE_DIR/tasks" -name "*.md" | sort | while read task_file; do
        task_id=$(basename "$task_file" .md)
        task_name=$(grep "^name:" "$task_file" 2>/dev/null | sed 's/^name: *//' || echo "")
        task_status=$(grep "^status:" "$task_file" 2>/dev/null | sed 's/^status: *//' || echo "未开始")
        task_progress=$(grep "^progress:" "$task_file" 2>/dev/null | sed 's/^progress: *//' || echo "0")
        task_hours=$(grep "^estimated_hours:" "$task_file" 2>/dev/null | sed 's/^estimated_hours: *//' || echo "8")
        
        echo "$task_id: [$task_status] $task_progress% - $task_name ($task_hours h)"
        
        # 累计统计（注意：在子shell中无法更新外部变量，这里仅作展示）
        case "$task_status" in
          "已完成") completed_tasks=$((completed_tasks + 1)) ;;
          "进行中") in_progress_tasks=$((in_progress_tasks + 1)) ;;
          *) pending_tasks=$((pending_tasks + 1)) ;;
        esac
      done
      
      # 重新计算统计数据（因为子shell问题，这里重新统计）
      completed_count=0
      in_progress_count=0
      pending_count=0
      total_hours=0
      
      for task_file in "$FEATURE_DIR/tasks"/*.md; do
        if [ -f "$task_file" ]; then
          task_status=$(grep "^status:" "$task_file" 2>/dev/null | sed 's/^status: *//' || echo "未开始")
          task_hours=$(grep "^estimated_hours:" "$task_file" 2>/dev/null | sed 's/^estimated_hours: *//' || echo "8")
          
          case "$task_status" in
            "已完成") completed_count=$((completed_count + 1)) ;;
            "进行中") in_progress_count=$((in_progress_count + 1)) ;;
            *) pending_count=$((pending_count + 1)) ;;
          esac
          
          total_hours=$((total_hours + task_hours))
        fi
      done
      
      echo ""
      echo "--- TASK_SUMMARY ---"
      echo "COMPLETED_TASKS: $completed_count"
      echo "IN_PROGRESS_TASKS: $in_progress_count"  
      echo "PENDING_TASKS: $pending_count"
      echo "TOTAL_ESTIMATED_HOURS: $total_hours"
      
      # 计算整体进度
      if [ "$task_files" -gt 0 ]; then
        overall_progress=$(echo "scale=0; $completed_count * 100 / $task_files" | bc)
        echo "CALCULATED_PROGRESS: ${overall_progress}%"
      fi
    fi
  else
    echo "TOTAL_TASKS: 0"
    echo "TASKS_DIR: NOT_EXISTS"
  fi
  echo ""
  
  echo "=== FEATURE_CONTENT ==="
  echo "--- FEATURE_DOCUMENT ---"
  cat "$FEATURE_DIR/overview.md"
  echo ""
  
  if [ -f "$FEATURE_DIR/technical.md" ]; then
    echo "--- TECHNICAL_DOCUMENT ---"
    head -50 "$FEATURE_DIR/technical.md"
    echo ""
  fi
  
  echo "✅ Feature status read completed: $FEATURE_NAME"
}

main() {
  case "${1:-}" in
    "--help"|"-h"|"help")
      echo "DD 功能状态读取工具"
      echo "用法: $0 <feature_name>"
      echo "示例: $0 用户认证系统"
      ;;
    "")
      echo "ERROR: Missing feature name parameter"
      echo "用法: $0 <feature_name>"
      exit 1
      ;;
    *)
      read_feature_status
      ;;
  esac
}

main "$@"