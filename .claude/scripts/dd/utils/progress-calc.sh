#!/bin/bash

# 进度计算算法
# 提供功能和任务进度的精确计算和同步

# 计算任务进度
calc_task_progress() {
  local task_file="$1"
  
  if [ ! -f "$task_file" ]; then
    echo "0"
    return 1
  fi
  
  # 统计 Todo 项目
  local completed_todos=$(grep -c "- \[x\]" "$task_file" 2>/dev/null || echo "0")
  local pending_todos=$(grep -c "- \[ \]" "$task_file" 2>/dev/null || echo "0")
  local total_todos=$((completed_todos + pending_todos))
  
  if [ "$total_todos" -eq 0 ]; then
    # 没有 Todo 项时, 检查任务状态
    local task_status=$(grep "^status:" "$task_file" | sed 's/^status: *//' 2>/dev/null)
    case "$task_status" in
      "已完成") echo "100" ;;
      "进行中") echo "50" ;;
      *) echo "0" ;;
    esac
  else
    # 基于 Todo 项计算进度
    local progress=$((completed_todos * 100 / total_todos))
    echo "$progress"
  fi
}

# 更新任务进度
update_task_progress() {
  local task_file="$1"
  local progress=$(calc_task_progress "$task_file")
  
  if [ -f "$task_file" ]; then
    # 使用临时文件安全更新
    local temp_file="${task_file}.tmp"
    
    # 更新进度字段
    sed "s/^progress:.*/progress: $progress/" "$task_file" > "$temp_file"
    
    if [ $? -eq 0 ]; then
      mv "$temp_file" "$task_file"
      echo "📊 任务进度已更新: $progress%"
    else
      rm -f "$temp_file"
      echo "❌ 任务进度更新失败"
      return 1
    fi
  fi
}

# 计算功能进度
calc_feature_progress() {
  local feature_name="$1"
  local feature_dir=".claude/features/$feature_name"
  
  if [ ! -d "$feature_dir" ]; then
    echo "0"
    return 1
  fi
  
  # 统计任务完成情况
  local total_tasks=0
  local completed_tasks=0
  local total_progress=0
  
  for task_file in "$feature_dir/tasks"/*.md; do
    if [ -f "$task_file" ]; then
      total_tasks=$((total_tasks + 1))
      
      local task_status=$(grep "^status:" "$task_file" | sed 's/^status: *//' 2>/dev/null)
      local task_progress=$(calc_task_progress "$task_file")
      
      if [ "$task_status" = "已完成" ]; then
        completed_tasks=$((completed_tasks + 1))
        task_progress=100
      fi
      
      total_progress=$((total_progress + task_progress))
    fi
  done
  
  if [ "$total_tasks" -eq 0 ]; then
    echo "0"
  else
    local feature_progress=$((total_progress / total_tasks))
    echo "$feature_progress"
  fi
}

# 更新功能进度
update_feature_progress() {
  local feature_name="$1"
  local feature_dir=".claude/features/$feature_name"
  local feature_file="$feature_dir/feature.md"
  
  if [ ! -f "$feature_file" ]; then
    echo "❌ 功能文件不存在: $feature_file"
    return 1
  fi
  
  # 计算统计信息
  local total_tasks=$(find "$feature_dir/tasks" -name "*.md" -type f 2>/dev/null | wc -l)
  local completed_tasks=$(find "$feature_dir/tasks" -name "*.md" -exec grep -l "^status: 已完成" {} \; 2>/dev/null | wc -l)
  local progress=$(calc_feature_progress "$feature_name")
  
  # 使用临时文件安全更新
  local temp_file="${feature_file}.tmp"
  
  # 更新所有相关字段
  sed -e "s/^progress:.*/progress: $progress/" \
      -e "s/^tasks_total:.*/tasks_total: $total_tasks/" \
      -e "s/^tasks_completed:.*/tasks_completed: $completed_tasks/" \
      "$feature_file" > "$temp_file"
  
  if [ $? -eq 0 ]; then
    mv "$temp_file" "$feature_file"
    echo "📊 功能进度已更新: $feature_name ($progress%)"
    echo "  总任务: $total_tasks, 已完成: $completed_tasks"
  else
    rm -f "$temp_file"
    echo "❌ 功能进度更新失败"
    return 1
  fi
}

# 同步所有进度
sync_all_progress() {
  echo "🔄 开始同步所有功能和任务进度..."
  local updated_count=0
  
  # 遍历所有功能
  for feature_dir in .claude/features/*/; do
    if [ -d "$feature_dir" ]; then
      local feature_name=$(basename "$feature_dir")
      
      echo "📁 处理功能: $feature_name"
      
      # 更新该功能的所有任务进度
      for task_file in "$feature_dir/tasks"/*.md; do
        if [ -f "$task_file" ]; then
          update_task_progress "$task_file"
        fi
      done
      
      # 更新功能进度
      if update_feature_progress "$feature_name"; then
        updated_count=$((updated_count + 1))
      fi
      
      echo ""
    fi
  done
  
  echo "✅ 进度同步完成, 更新了 $updated_count 个功能"
}

# 生成进度报告
generate_progress_report() {
  local feature_name="$1"
  
  echo "📊 进度报告"
  echo "==========="
  echo "生成时间: $(date)"
  echo ""
  
  if [ -n "$feature_name" ]; then
    # 单个功能的详细报告
    echo "🎯 功能: $feature_name"
    
    local feature_progress=$(calc_feature_progress "$feature_name")
    echo "  整体进度: $feature_progress%"
    
    local feature_dir=".claude/features/$feature_name"
    echo ""
    echo "📝 任务详情: "
    
    local task_num=1
    for task_file in "$feature_dir/tasks"/*.md; do
      if [ -f "$task_file" ]; then
        local task_name=$(grep "^name:" "$task_file" | sed 's/^name: *//')
        local task_status=$(grep "^status:" "$task_file" | sed 's/^status: *//')
        local task_progress=$(calc_task_progress "$task_file")
        
        printf "  %03d. %-30s %s (%s%%)\n" "$task_num" "$task_name" "$task_status" "$task_progress"
        task_num=$((task_num + 1))
      fi
    done
    
  else
    # 所有功能的概览报告
    echo "🌟 所有功能进度概览: "
    
    local total_features=0
    local completed_features=0
    local total_progress=0
    
    for feature_dir in .claude/features/*/; do
      if [ -d "$feature_dir" ]; then
        local fname=$(basename "$feature_dir")
        local fprogress=$(calc_feature_progress "$fname")
        local fstatus=$(grep "^status:" "$feature_dir/feature.md" | sed 's/^status: *//' 2>/dev/null)
        
        printf "  %-25s %s (%s%%)\n" "$fname" "$fstatus" "$fprogress"
        
        total_features=$((total_features + 1))
        if [ "$fstatus" = "已完成" ]; then
          completed_features=$((completed_features + 1))
        fi
        total_progress=$((total_progress + fprogress))
      fi
    done
    
    if [ "$total_features" -gt 0 ]; then
      local overall_progress=$((total_progress / total_features))
      echo ""
      echo "📈 项目整体进度: $overall_progress%"
      echo "   已完成功能: $completed_features/$total_features"
    fi
  fi
  
  echo ""
}

# 进度数据导出
export_progress_data() {
  local output_file="$1"
  local format="${2:-json}"
  
  case "$format" in
    "json")
      export_progress_json "$output_file"
      ;;
    "csv")
      export_progress_csv "$output_file"
      ;;
    *)
      echo "❌ 不支持的格式: $format"
      echo "支持的格式: json, csv"
      return 1
      ;;
  esac
}

# 导出 JSON 格式
export_progress_json() {
  local output_file="$1"
  
  echo "{" > "$output_file"
  echo "  \"generated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," >> "$output_file"
  echo "  \"features\": [" >> "$output_file"
  
  local first=true
  for feature_dir in .claude/features/*/; do
    if [ -d "$feature_dir" ]; then
      [ "$first" = false ] && echo "    }," >> "$output_file"
      first=false
      
      local fname=$(basename "$feature_dir")
      local fprogress=$(calc_feature_progress "$fname")
      local fstatus=$(grep "^status:" "$feature_dir/feature.md" | sed 's/^status: *//' 2>/dev/null)
      
      echo "    {" >> "$output_file"
      echo "      \"name\": \"$fname\"," >> "$output_file"
      echo "      \"status\": \"$fstatus\"," >> "$output_file"
      echo "      \"progress\": $fprogress" >> "$output_file"
    fi
  done
  
  [ "$first" = false ] && echo "    }" >> "$output_file"
  echo "  ]" >> "$output_file"
  echo "}" >> "$output_file"
  
  echo "✅ 进度数据已导出到: $output_file (JSON 格式)"
}

# 导出 CSV 格式
export_progress_csv() {
  local output_file="$1"
  
  echo "Feature,Status,Progress" > "$output_file"
  
  for feature_dir in .claude/features/*/; do
    if [ -d "$feature_dir" ]; then
      local fname=$(basename "$feature_dir")
      local fprogress=$(calc_feature_progress "$fname")
      local fstatus=$(grep "^status:" "$feature_dir/feature.md" | sed 's/^status: *//' 2>/dev/null)
      
      echo "$fname,$fstatus,$fprogress" >> "$output_file"
    fi
  done
  
  echo "✅ 进度数据已导出到: $output_file (CSV 格式)"
}

# 主函数
main() {
  local command="$1"
  local param1="$2"
  local param2="$3"
  
  case "$command" in
    "task")
      if [ -n "$param1" ]; then
        update_task_progress "$param1"
      else
        echo "用法: $0 task <任务文件路径>"
      fi
      ;;
    "feature")
      if [ -n "$param1" ]; then
        update_feature_progress "$param1"
      else
        echo "用法: $0 feature <功能名称>"
      fi
      ;;
    "sync")
      sync_all_progress
      ;;
    "report")
      generate_progress_report "$param1"
      ;;
    "export")
      if [ -n "$param1" ]; then
        export_progress_data "$param1" "$param2"
      else
        echo "用法: $0 export <输出文件> [json|csv]"
      fi
      ;;
    "calc-task")
      if [ -n "$param1" ]; then
        calc_task_progress "$param1"
      else
        echo "用法: $0 calc-task <任务文件路径>"
      fi
      ;;
    "calc-feature")
      if [ -n "$param1" ]; then
        calc_feature_progress "$param1"
      else
        echo "用法: $0 calc-feature <功能名称>"
      fi
      ;;
    *)
      echo "进度计算工具"
      echo ""
      echo "用法: $0 {task|feature|sync|report|export|calc-task|calc-feature} [参数...]"
      echo ""
      echo "命令说明: "
      echo "  task <任务文件>     - 更新指定任务的进度"
      echo "  feature <功能名>    - 更新指定功能的进度"
      echo "  sync                - 同步所有功能和任务进度"
      echo "  report [功能名]     - 生成进度报告"
      echo "  export <文件> [格式] - 导出进度数据 (json|csv)"
      echo "  calc-task <任务文件> - 计算任务进度（不更新）"
      echo "  calc-feature <功能名> - 计算功能进度（不更新）"
      exit 1
      ;;
  esac
}

# 如果脚本被直接调用
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  main "$@"
fi