#!/bin/bash

# DD 任务完成脚本
# 接收 <feature>:<task_id> 参数, 标记任务完成并更新进度

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

mark_task_completed() {
  echo "=== TASK_COMPLETION ==="
  echo "TASK_ID: $TASK_ID"
  echo "FEATURE_NAME: $FEATURE_NAME"
  echo "TASK_NUMBER: $TASK_NUMBER"
  echo "TASK_FILE: $TASK_FILE"
  echo ""
  
  # 更新任务状态为已完成
  sed -i.bak 's/^status:.*/status: 已完成/' "$TASK_FILE"
  if [ $? -eq 0 ]; then
    rm -f "${TASK_FILE}.bak"
    echo "✅ 任务状态已更新为: 已完成"
  else
    echo "❌ 任务状态更新失败"
    return 1
  fi
  echo ""
}

update_task_progress() {
  echo "=== TASK_PROGRESS_UPDATE ==="
  if [ -x ".claude/scripts/dd/utils/progress-calc.sh" ]; then
    echo "🔄 计算并更新任务进度..."
    bash .claude/scripts/dd/utils/progress-calc.sh task "$TASK_FILE"
    echo ""
  else
    echo "⚠️  进度计算工具不可用, 手动设置进度为100%"
    sed -i.bak 's/^progress:.*/progress: 100/' "$TASK_FILE"
    rm -f "${TASK_FILE}.bak"
    echo ""
  fi
}

update_feature_progress() {
  echo "=== FEATURE_PROGRESS_UPDATE ==="
  if [ -x ".claude/scripts/dd/utils/progress-calc.sh" ]; then
    echo "🔄 重新计算功能进度..."
    bash .claude/scripts/dd/utils/progress-calc.sh feature "$FEATURE_NAME"
    echo ""
  else
    echo "⚠️  进度计算工具不可用, 跳过功能进度更新"
    echo ""
  fi
}

run_git_check() {
  echo "=== GIT_STATUS_CHECK ==="
  if [ -x ".claude/scripts/dd/utils/git-check.sh" ]; then
    echo "🔍 检查当前Git状态..."
    bash .claude/scripts/dd/utils/git-check.sh full-check "$FEATURE_NAME"
  else
    echo "⚠️  Git检查工具不可用, 跳过Git状态检查"
  fi
  echo ""
}

generate_completion_summary() {
  echo "=== TASK_COMPLETION_SUMMARY ==="
  echo "📝 任务完成总结:"
  echo "  任务: $TASK_ID"
  
  # 读取任务信息
  local task_name=$(grep "^name:" "$TASK_FILE" | sed 's/^name: *//')
  local task_progress=$(grep "^progress:" "$TASK_FILE" | sed 's/^progress: *//')
  
  echo "  名称: ${task_name:-未命名}"
  echo "  进度: ${task_progress:-0}%"
  echo "  状态: 已完成"
  echo ""
  
  # 检查功能整体进度
  local feature_progress=""
  if [ -x ".claude/scripts/dd/utils/progress-calc.sh" ]; then
    feature_progress=$(bash .claude/scripts/dd/utils/progress-calc.sh calc-feature "$FEATURE_NAME" 2>/dev/null || echo "0")
  fi
  
  echo "🎯 功能整体进度: ${feature_progress:-0}%"
  
  # 检查是否还有未完成任务
  local remaining_tasks=$(find ".claude/features/$FEATURE_NAME/tasks" -name "*.md" -exec grep -l "^status: 未开始\|^status: 进行中" {} \; 2>/dev/null | wc -l)
  
  if [ "$remaining_tasks" -eq 0 ]; then
    echo "🎉 所有任务已完成！功能可以标记为完成状态"
    echo "💡 建议下一步: 运行功能验收检查"
  else
    echo "📋 剩余 $remaining_tasks 个未完成任务"
    echo "💡 建议下一步: 继续完成其他任务"
  fi
  echo ""
}

main() {
  parse_task_id "$1"
  validate_task_existence
  
  mark_task_completed
  update_task_progress
  update_feature_progress
  run_git_check
  generate_completion_summary
  
  echo "✅ 任务完成处理完毕: $TASK_ID"
}

# 如果脚本被直接调用
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  if [ -z "$1" ]; then
    echo "用法: $0 <feature>:<task_id>"
    echo "示例: $0 用户认证系统:001"
    exit 1
  fi
  
  main "$1"
fi