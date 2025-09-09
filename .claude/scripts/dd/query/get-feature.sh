#!/bin/bash

# DD 功能信息读取脚本
# 读取功能文档的信息，包括状态、进度和子任务信息
# 默认读取 overview.md，支持多种读取选项

set -e

FEATURE_NAME=""
STATUS_ONLY=false
READ_ALL=false
READ_OVERVIEW=false
READ_TECHNICAL=false
READ_ACCEPTANCE=false

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --status-only)
      STATUS_ONLY=true
      shift
      ;;
    --all)
      READ_ALL=true
      shift
      ;;
    --overview)
      READ_OVERVIEW=true
      shift
      ;;
    --technical)
      READ_TECHNICAL=true
      shift
      ;;
    --acceptance)
      READ_ACCEPTANCE=true
      shift
      ;;
    --help|-h|help)
      echo "DD 功能信息读取工具"
      echo "用法: $0 [选项] <feature_name>"
      echo ""
      echo "选项:"
      echo "  --status-only     仅显示状态信息，不显示文档内容"
      echo "  --all            读取所有文档 (overview.md + technical.md + acceptance.md)"
      echo "  --overview       仅读取功能概述文档 (overview.md)"
      echo "  --technical      仅读取技术方案文档 (technical.md)"
      echo "  --acceptance     仅读取验收标准文档 (acceptance.md)"
      echo "  --help, -h       显示此帮助信息"
      echo ""
      echo "示例:"
      echo "  $0 用户认证系统                    # 默认读取 overview.md"
      echo "  $0 --all 用户认证系统              # 读取所有文档"
      echo "  $0 --technical 用户认证系统        # 仅读取技术方案"
      echo "  $0 --acceptance 用户认证系统       # 仅读取验收标准"
      echo "  $0 --status-only 用户认证系统      # 仅显示状态信息"
      exit 0
      ;;
    *)
      if [ -z "$FEATURE_NAME" ]; then
        FEATURE_NAME="$1"
      else
        echo "ERROR: 意外的参数: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

FEATURE_DIR=".claude/features/$FEATURE_NAME"

if [ -z "$FEATURE_NAME" ]; then
  echo "ERROR: Missing feature name parameter"
  echo "用法: $0 [选项] <feature_name>"
  echo "使用 --help 查看完整帮助"
  exit 1
fi

# 设置默认行为：如果没有指定任何文档选项，默认读取 overview.md
if [ "$STATUS_ONLY" = false ] && [ "$READ_ALL" = false ] && [ "$READ_OVERVIEW" = false ] && [ "$READ_TECHNICAL" = false ] && [ "$READ_ACCEPTANCE" = false ]; then
  READ_OVERVIEW=true
fi

# 验证功能目录和基础文件
validate_feature() {
  if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature directory does not exist: $FEATURE_DIR"
    exit 1
  fi
  
  if [ ! -f "$FEATURE_DIR/overview.md" ]; then
    echo "ERROR: Feature document does not exist: $FEATURE_DIR/overview.md"
    exit 1
  fi
}

# 显示功能基本信息
show_feature_header() {
  echo "=== FEATURE_STATUS_READ ==="
  echo "FEATURE_NAME: $FEATURE_NAME"
  echo "FEATURE_DIR: $FEATURE_DIR"
  echo ""
}

# 读取并显示功能元数据
show_feature_metadata() {
  echo "=== FEATURE_METADATA ==="
  # 读取功能文档的元数据
  local status=$(grep "^status:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^status: *//' || echo "未开始")
  local progress=$(grep "^progress:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^progress: *//' || echo "0")
  local type=$(grep "^type:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^type: *//' || echo "功能")
  local scope=$(grep "^scope:" "$FEATURE_DIR/overview.md" 2>/dev/null | sed 's/^scope: *//' || echo "待确定")
  
  echo "STATUS: $status"
  echo "PROGRESS: $progress"
  echo "TYPE: $type"
  echo "SCOPE: $scope"
  echo ""
}

# 显示功能文件状态
show_feature_files_status() {
  echo "=== FEATURE_FILES_STATUS ==="
  # 检查关键文档文件状态
  local feature_files=("overview.md" "technical.md" "acceptance.md")
  for file in "${feature_files[@]}"; do
    if [ -f "$FEATURE_DIR/$file" ]; then
      echo "$file: EXISTS"
    else
      echo "$file: MISSING"
    fi
  done
  echo ""
}

# 分析并显示任务状态
show_tasks_analysis() {
  echo "=== TASKS_ANALYSIS ==="
  # 分析任务状态
  if [ -d "$FEATURE_DIR/tasks" ]; then
    local task_files=$(find "$FEATURE_DIR/tasks" -name "*.md" 2>/dev/null | wc -l | xargs)
    echo "TOTAL_TASKS: $task_files"
    
    if [ "$task_files" -gt 0 ]; then
      echo "--- TASK_DETAILS ---"
      find "$FEATURE_DIR/tasks" -name "*.md" | sort | while read task_file; do
        local task_id=$(basename "$task_file" .md)
        local task_name=$(grep "^name:" "$task_file" 2>/dev/null | sed 's/^name: *//' || echo "")
        local task_status=$(grep "^status:" "$task_file" 2>/dev/null | sed 's/^status: *//' || echo "未开始")
        local task_progress=$(grep "^progress:" "$task_file" 2>/dev/null | sed 's/^progress: *//' || echo "0")
        
        echo "$task_id: [$task_status] $task_progress% - $task_name"
      done
      
      # 计算统计数据
      local completed_count=0
      local in_progress_count=0
      local pending_count=0
      
      for task_file in "$FEATURE_DIR/tasks"/*.md; do
        if [ -f "$task_file" ]; then
          local task_status=$(grep "^status:" "$task_file" 2>/dev/null | sed 's/^status: *//' || echo "未开始")
          
          case "$task_status" in
            "已完成") completed_count=$((completed_count + 1)) ;;
            "进行中") in_progress_count=$((in_progress_count + 1)) ;;
            *) pending_count=$((pending_count + 1)) ;;
          esac
        fi
      done
      
      echo ""
      echo "--- TASK_SUMMARY ---"
      echo "COMPLETED_TASKS: $completed_count"
      echo "IN_PROGRESS_TASKS: $in_progress_count"  
      echo "PENDING_TASKS: $pending_count"
      echo "TOTAL_TASKS: $((completed_count + in_progress_count + pending_count))"
      
      # 计算整体进度
      if [ "$task_files" -gt 0 ]; then
        local overall_progress=$(echo "scale=0; $completed_count * 100 / $task_files" | bc)
        echo "CALCULATED_PROGRESS: ${overall_progress}%"
      fi
    fi
  else
    echo "TOTAL_TASKS: 0"
    echo "TASKS_DIR: NOT_EXISTS"
  fi
  echo ""
}

# 显示单个文档内容
show_document() {
  local doc_type="$1"
  local file_path="$FEATURE_DIR/$2"
  local display_name="$3"
  
  if [ -f "$file_path" ]; then
    echo "--- $display_name ---"
    cat "$file_path"
    echo ""
  else
    echo "--- $display_name ---"
    echo "File not found: $file_path"
    echo ""
  fi
}

# 显示功能文档内容
show_feature_content() {
  if [ "$STATUS_ONLY" = false ]; then
    echo "=== FEATURE_CONTENT ==="
    
    # 显示 overview.md
    if [ "$READ_ALL" = true ] || [ "$READ_OVERVIEW" = true ]; then
      show_document "overview" "overview.md" "OVERVIEW_DOCUMENT"
    fi
    
    # 显示 technical.md
    if [ "$READ_ALL" = true ] || [ "$READ_TECHNICAL" = true ]; then
      show_document "technical" "technical.md" "TECHNICAL_DOCUMENT"
    fi
    
    # 显示 acceptance.md
    if [ "$READ_ALL" = true ] || [ "$READ_ACCEPTANCE" = true ]; then
      show_document "acceptance" "acceptance.md" "ACCEPTANCE_DOCUMENT"
    fi
  fi
}

# 显示完成消息
show_completion_message() {
  if [ "$STATUS_ONLY" = true ]; then
    echo "✅ Feature status read completed: $FEATURE_NAME"
  else
    echo "✅ Feature information read completed: $FEATURE_NAME"
  fi
}

# 主要的功能读取函数
read_feature_status() {
  validate_feature
  show_feature_header
  show_feature_metadata
  show_feature_files_status
  show_tasks_analysis
  show_feature_content
  show_completion_message
}

main() {
  read_feature_status
}

main "$@"