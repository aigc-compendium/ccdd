#!/bin/bash

# DD 任务添加 - 功能文件脚本
# 基于功能文档信息生成任务, 返回结构化信息给智能体

set -e

FEATURE_NAME="$1"
FEATURE_DIR=".claude/features/$FEATURE_NAME"

if [ -z "$FEATURE_NAME" ]; then
    echo "ERROR: Missing feature name parameter"
    exit 1
fi

echo "=== TASK_ADD_FEATURE ==="
echo "FEATURE_NAME: $FEATURE_NAME"
echo "FEATURE_DIR: $FEATURE_DIR"
echo ""

# 检查功能目录是否存在
if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature directory does not exist: $FEATURE_DIR"
    exit 1
fi

echo "=== FEATURE_FILES ==="
# 检查功能文件
feature_files=("feature.md" "technical.md" "testing.md")
for file in "${feature_files[@]}"; do
    if [ -f "$FEATURE_DIR/$file" ]; then
        echo "$file: EXISTS"
    else
        echo "$file: MISSING"
    fi
done
echo ""

echo "=== FEATURE_CONTENT ==="
# 读取功能描述文档
if [ -f "$FEATURE_DIR/feature.md" ]; then
    echo "--- FEATURE_DESCRIPTION ---"
    cat "$FEATURE_DIR/feature.md"
    echo ""
fi
echo ""

echo "=== TECHNICAL_CONTENT ==="
# 读取技术方案文档
if [ -f "$FEATURE_DIR/technical.md" ]; then
    echo "--- TECHNICAL_DESIGN ---"
    cat "$FEATURE_DIR/technical.md"
    echo ""
fi
echo ""

echo "=== TESTING_CONTENT ==="
# 读取测试用例文档
if [ -f "$FEATURE_DIR/testing.md" ]; then
    echo "--- TESTING_CASES ---"
    cat "$FEATURE_DIR/testing.md"
    echo ""
fi
echo ""

echo "=== CURRENT_TASKS ==="
# 检查已有任务
if [ -d "$FEATURE_DIR/tasks" ]; then
    existing_tasks=$(find "$FEATURE_DIR/tasks" -name "*.md" 2>/dev/null | wc -l)
    echo "EXISTING_TASKS: $existing_tasks"
    
    if [ "$existing_tasks" -gt 0 ]; then
        echo "--- EXISTING_TASK_LIST ---"
        find "$FEATURE_DIR/tasks" -name "*.md" | sort | while read task_file; do
            task_id=$(basename "$task_file" .md)
            task_name=$(grep "^name:" "$task_file" 2>/dev/null | sed 's/^name: *//' || echo "")
            echo "$task_id: $task_name"
        done
        echo ""
    fi
else
    echo "EXISTING_TASKS: 0"
    echo "TASKS_DIR: NOT_EXISTS"
fi
echo ""

echo "=== PROJECT_CONTEXT ==="
# 读取项目上下文（如果存在）
if [ -f ".claude/context/project.md" ]; then
    echo "PROJECT_CONTEXT: EXISTS"
    echo "--- PROJECT_INFO ---"
    head -20 ".claude/context/project.md"
    echo ""
else
    echo "PROJECT_CONTEXT: NOT_EXISTS"
fi
echo ""

echo "=== READY_FOR_DECOMPOSITION ==="
echo "FEATURE_FILES_READY: $([ -f "$FEATURE_DIR/feature.md" ] && [ -f "$FEATURE_DIR/technical.md" ] && echo "true" || echo "false")"
echo "TASKS_DIR_READY: $([ -d "$FEATURE_DIR/tasks" ] && echo "true" || echo "false")"
echo ""

echo "✅ Feature information loaded for task decomposition: $FEATURE_NAME"