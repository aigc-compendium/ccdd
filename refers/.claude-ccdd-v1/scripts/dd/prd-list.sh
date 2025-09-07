#!/bin/bash
# Check if PRD directory exists
if [ ! -d ".claude/prds" ]; then
  echo "📁 未找到 PRD 目录。使用以下命令创建你的第一个 PRD: /dd:prd-new <功能名称>"
  exit 0
fi

# Check for PRD files
if ! ls .claude/prds/*.md >/dev/null 2>&1; then
  echo "📁 未找到 PRD。使用以下命令创建你的第一个 PRD: /dd:prd-new <功能名称>"
  exit 0
fi

# Initialize counters
backlog_count=0
in_progress_count=0
implemented_count=0
total_count=0

echo "获取 PRD 列表..."
echo ""
echo ""

echo "📋 PRD 列表"
echo "==========="
echo ""

# Display by status groups
echo "🔍 待办 PRDs:"
for file in .claude/prds/*.md; do
  [ -f "$file" ] || continue
  
  # 获取PRD基本信息（支持中英文字段）
  name=$(grep -E "^(name|名称):" "$file" | head -1 | sed 's/^[^:]*: *//')
  desc=$(grep -E "^(description|描述):" "$file" | head -1 | sed 's/^[^:]*: *//')
  [ -z "$name" ] && name=$(basename "$file" .md)
  [ -z "$desc" ] && desc="无描述"
  
  # 检查对应的Epic状态和进度
  epic_file=".claude/epics/$name/epic.md"
  if [ -f "$epic_file" ]; then
    status=$(grep "^状态:" "$epic_file" | head -1 | sed 's/^状态: *//')
    progress=$(grep "^进度:" "$epic_file" | head -1 | sed 's/^进度: *//' | sed 's/%//')
    
    # 根据进度判断真实状态
    if [ -n "$progress" ] && [ "$progress" -gt 0 ] && [ "$progress" -lt 100 ]; then
      actual_status="in-progress"
    elif [ -n "$progress" ] && [ "$progress" -eq 100 ]; then
      actual_status="completed"
    else
      actual_status="$status"
    fi
  else
    # 如果没有Epic文件，使用PRD文件的状态
    actual_status=$(grep -E "^(status|状态):" "$file" | head -1 | sed 's/^[^:]*: *//')
  fi
  
  # 根据实际状态分类
  if [ "$actual_status" = "backlog" ] || [ "$actual_status" = "draft" ] || [ -z "$actual_status" ]; then
    echo "   📋 $name - $desc"
    ((backlog_count++))
  fi
  ((total_count++))
done
[ $backlog_count -eq 0 ] && echo "   (无)"

echo ""
echo "🔄 进行中 PRDs:"
for file in .claude/prds/*.md; do
  [ -f "$file" ] || continue
  
  # 获取PRD基本信息（支持中英文字段）
  name=$(grep -E "^(name|名称):" "$file" | head -1 | sed 's/^[^:]*: *//')
  desc=$(grep -E "^(description|描述):" "$file" | head -1 | sed 's/^[^:]*: *//')
  [ -z "$name" ] && name=$(basename "$file" .md)
  [ -z "$desc" ] && desc="无描述"
  
  # 检查对应的Epic状态和进度
  epic_file=".claude/epics/$name/epic.md"
  if [ -f "$epic_file" ]; then
    status=$(grep "^状态:" "$epic_file" | head -1 | sed 's/^状态: *//')
    progress=$(grep "^进度:" "$epic_file" | head -1 | sed 's/^进度: *//' | sed 's/%//')
    
    # 根据进度判断真实状态
    if [ -n "$progress" ] && [ "$progress" -gt 0 ] && [ "$progress" -lt 100 ]; then
      actual_status="in-progress"
    elif [ -n "$progress" ] && [ "$progress" -eq 100 ]; then
      actual_status="completed"
    else
      actual_status="$status"
    fi
  else
    # 如果没有Epic文件，使用PRD文件的状态
    actual_status=$(grep -E "^(status|状态):" "$file" | head -1 | sed 's/^[^:]*: *//')
  fi
  
  # 显示进行中的PRD（包括进度信息）
  if [ "$actual_status" = "in-progress" ] || [ "$actual_status" = "active" ]; then
    if [ -n "$progress" ]; then
      echo "   📋 $name - $desc (进度: ${progress}%)"
    else
      echo "   📋 $name - $desc"
    fi
    ((in_progress_count++))
  fi
done
[ $in_progress_count -eq 0 ] && echo "   (无)"

echo ""
echo "✅ 已实施 PRDs:"
for file in .claude/prds/*.md; do
  [ -f "$file" ] || continue
  
  # 获取PRD基本信息（支持中英文字段）
  name=$(grep -E "^(name|名称):" "$file" | head -1 | sed 's/^[^:]*: *//')
  desc=$(grep -E "^(description|描述):" "$file" | head -1 | sed 's/^[^:]*: *//')
  [ -z "$name" ] && name=$(basename "$file" .md)
  [ -z "$desc" ] && desc="无描述"
  
  # 检查对应的Epic状态和进度
  epic_file=".claude/epics/$name/epic.md"
  if [ -f "$epic_file" ]; then
    status=$(grep "^状态:" "$epic_file" | head -1 | sed 's/^状态: *//')
    progress=$(grep "^进度:" "$epic_file" | head -1 | sed 's/^进度: *//' | sed 's/%//')
    
    # 根据进度判断真实状态
    if [ -n "$progress" ] && [ "$progress" -gt 0 ] && [ "$progress" -lt 100 ]; then
      actual_status="in-progress"
    elif [ -n "$progress" ] && [ "$progress" -eq 100 ]; then
      actual_status="completed"
    else
      actual_status="$status"
    fi
  else
    # 如果没有Epic文件，使用PRD文件的状态
    actual_status=$(grep -E "^(status|状态):" "$file" | head -1 | sed 's/^[^:]*: *//')
  fi
  
  # 显示已完成的PRD
  if [ "$actual_status" = "implemented" ] || [ "$actual_status" = "completed" ] || [ "$actual_status" = "done" ]; then
    echo "   📋 $name - $desc (100%)"
    ((implemented_count++))
  fi
done
[ $implemented_count -eq 0 ] && echo "   (无)"

# Display summary
echo ""
echo "📊 PRD 统计"
echo "   总 PRDs: $total_count"
echo "   待办: $backlog_count"
echo "   进行中: $in_progress_count"
echo "   已实施: $implemented_count"
echo ""

exit 0