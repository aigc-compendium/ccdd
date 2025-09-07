#!/bin/bash

# DD 任务分解完成脚本  
# 在任务分解完成后执行, 验证分解结果并提供下一步指导

set -e

FEATURE_NAME="$1"
FEATURE_DIR=".claude/features/$FEATURE_NAME"

if [ -z "$FEATURE_NAME" ]; then
    echo "ERROR: Missing feature name parameter"
    exit 1
fi

echo "=== TASK_DECOMPOSE_FINISH ==="
echo "FEATURE_NAME: $FEATURE_NAME"
echo "FEATURE_DIR: $FEATURE_DIR"
echo ""

# 检查功能目录是否存在
if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature directory does not exist: $FEATURE_DIR"
    exit 1
fi

# 检查任务目录
if [ ! -d "$FEATURE_DIR/tasks" ]; then
    echo "ERROR: Tasks directory does not exist: $FEATURE_DIR/tasks"
    exit 1
fi

echo "=== TASK_VALIDATION ==="
task_count=$(find "$FEATURE_DIR/tasks" -name "*.md" 2>/dev/null | wc -l)
echo "TOTAL_TASKS: $task_count"

if [ "$task_count" -eq 0 ]; then
    echo "ERROR: No task files found in $FEATURE_DIR/tasks"
    exit 1
fi

# 验证每个任务文件
valid_tasks=0
invalid_tasks=0

echo "=== TASK_FILES_CHECK ==="
find "$FEATURE_DIR/tasks" -name "*.md" | sort | while read task_file; do
    task_id=$(basename "$task_file" .md)
    
    # 检查必要字段
    has_name=$(grep -q "^name:" "$task_file" && echo "true" || echo "false")
    has_feature=$(grep -q "^feature:" "$task_file" && echo "true" || echo "false")
    has_status=$(grep -q "^status:" "$task_file" && echo "true" || echo "false")
    
    if [ "$has_name" = "true" ] && [ "$has_feature" = "true" ] && [ "$has_status" = "true" ]; then
        task_name=$(grep "^name:" "$task_file" | sed 's/^name: *//')
        task_status=$(grep "^status:" "$task_file" | sed 's/^status: *//')
        echo "TASK_$task_id: VALID - $task_name [$task_status]"
    else
        echo "TASK_$task_id: INVALID - Missing required fields"
    fi
done
echo ""

echo "=== TASK_DEPENDENCIES ==="
# 检查任务依赖关系
find "$FEATURE_DIR/tasks" -name "*.md" | sort | while read task_file; do
    task_id=$(basename "$task_file" .md)
    dependencies=$(grep "^dependencies:" "$task_file" 2>/dev/null | sed 's/^dependencies: *//' || echo "[]")
    echo "TASK_$task_id: $dependencies"
done
echo ""

echo "=== PROGRESS_INITIALIZATION ==="
if [ -x ".claude/scripts/dd/utils/progress-calc.sh" ]; then
    echo "🔄 初始化任务和功能进度..."
    
    # 为每个任务初始化进度
    find "$FEATURE_DIR/tasks" -name "*.md" | while read task_file; do
        bash .claude/scripts/dd/utils/progress-calc.sh task "$task_file"
    done
    
    # 更新功能进度
    bash .claude/scripts/dd/utils/progress-calc.sh feature "$FEATURE_NAME"
    echo ""
else
    echo "⚠️  进度计算工具不可用, 跳过进度初始化"
    echo ""
fi

echo "=== FEATURE_STATUS_UPDATE ==="
# 更新功能元数据中的任务总数
if [ -f "$FEATURE_DIR/feature.md" ]; then
    current_status=$(grep "^status:" "$FEATURE_DIR/feature.md" | sed 's/^status: *//' || echo "未开始")
    echo "CURRENT_STATUS: $current_status"
    echo "TASKS_TOTAL: $task_count"
    echo "TASKS_COMPLETED: 0"
    
    # 更新任务总数（这里只读取, 不修改文件）
    echo "READY_FOR_DEVELOPMENT: true"
else
    echo "ERROR: feature.md not found"
    exit 1
fi
echo ""

echo "=== TASK_SEQUENCE ==="
echo "Recommended execution order:"
find "$FEATURE_DIR/tasks" -name "*.md" | sort -V | while read task_file; do
    task_id=$(basename "$task_file" .md)
    task_name=$(grep "^name:" "$task_file" 2>/dev/null | sed 's/^name: *//' || echo "")
    dependencies=$(grep "^dependencies:" "$task_file" 2>/dev/null | sed 's/^dependencies: *//' || echo "[]")
    echo "  $task_id. $task_name"
    if [ "$dependencies" != "[]" ] && [ -n "$dependencies" ]; then
        echo "     └─ Depends on: $dependencies"
    fi
done
echo ""

echo "=== NEXT_STEPS ==="
echo "DECOMPOSITION_COMPLETE: true"
echo "NEXT_COMMAND: /dd:feature-start $FEATURE_NAME"
echo "FIRST_TASK: $(find "$FEATURE_DIR/tasks" -name "*.md" | sort -V | head -1 | xargs basename .md)"
echo ""

echo "✅ Task decomposition completed: $FEATURE_NAME"
echo "📋 Generated $task_count tasks ready for development"