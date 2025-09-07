#!/bin/bash

# DD 任务添加 - 技术文件脚本
# 基于技术方案文档生成任务, 返回结构化信息给智能体

set -e

FEATURE_NAME="$1"
FEATURE_DIR=".claude/features/$FEATURE_NAME"

if [ -z "$FEATURE_NAME" ]; then
    echo "ERROR: Missing feature name parameter"
    exit 1
fi

echo "=== TASK_ADD_TECHNICAL ==="
echo "FEATURE_NAME: $FEATURE_NAME"
echo "FEATURE_DIR: $FEATURE_DIR"
echo ""

# 检查功能目录是否存在
if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature directory does not exist: $FEATURE_DIR"
    exit 1
fi

echo "=== TECHNICAL_ANALYSIS ==="
if [ -f "$FEATURE_DIR/technical.md" ]; then
    echo "TECHNICAL_FILE: EXISTS"
    
    # 提取技术方案关键信息
    echo "--- TECHNICAL_METADATA ---"
    grep "^complexity:" "$FEATURE_DIR/technical.md" 2>/dev/null || echo "complexity: 中等"
    grep "^estimated_hours:" "$FEATURE_DIR/technical.md" 2>/dev/null || echo "estimated_hours: 40"
    grep "^tech_stack:" "$FEATURE_DIR/technical.md" 2>/dev/null || echo "tech_stack: []"
    grep "^dependencies:" "$FEATURE_DIR/technical.md" 2>/dev/null || echo "dependencies: []"
    echo ""
    
    echo "--- TECHNICAL_SECTIONS ---"
    # 提取技术选型部分
    if grep -q "## 技术选型" "$FEATURE_DIR/technical.md"; then
        echo "TECH_STACK_SECTION: EXISTS"
        sed -n '/## 技术选型/,/## /p' "$FEATURE_DIR/technical.md" | head -n -1
        echo ""
    fi
    
    # 提取架构设计部分
    if grep -q "## 架构设计" "$FEATURE_DIR/technical.md"; then
        echo "ARCHITECTURE_SECTION: EXISTS"
        sed -n '/## 架构设计/,/## /p' "$FEATURE_DIR/technical.md" | head -n -1
        echo ""
    fi
    
    # 提取数据模型部分
    if grep -q "## 数据模型" "$FEATURE_DIR/technical.md"; then
        echo "DATA_MODEL_SECTION: EXISTS"
        sed -n '/## 数据模型/,/## /p' "$FEATURE_DIR/technical.md" | head -n -1
        echo ""
    fi
    
    # 提取API设计部分
    if grep -q "## API 设计" "$FEATURE_DIR/technical.md"; then
        echo "API_DESIGN_SECTION: EXISTS"
        sed -n '/## API 设计/,/## /p' "$FEATURE_DIR/technical.md" | head -n -1
        echo ""
    fi
    
    # 提取关键技术点
    if grep -q "## 关键技术点" "$FEATURE_DIR/technical.md"; then
        echo "KEY_POINTS_SECTION: EXISTS"
        sed -n '/## 关键技术点/,/## /p' "$FEATURE_DIR/technical.md" | head -n -1
        echo ""
    fi
    
else
    echo "TECHNICAL_FILE: NOT_EXISTS"
    echo "ERROR: technical.md file is required for task decomposition"
    exit 1
fi

echo "=== IMPLEMENTATION_COMPLEXITY ==="
complexity=$(grep "^complexity:" "$FEATURE_DIR/technical.md" 2>/dev/null | sed 's/^complexity: *//' || echo "中等")
estimated_hours=$(grep "^estimated_hours:" "$FEATURE_DIR/technical.md" 2>/dev/null | sed 's/^estimated_hours: *//' || echo "40")

echo "COMPLEXITY_LEVEL: $complexity"
echo "ESTIMATED_HOURS: $estimated_hours"

# 基于复杂度建议任务数量
case "$complexity" in
    "简单")
        echo "SUGGESTED_TASK_COUNT: 3-5"
        echo "TASK_SIZE: 4-8 hours each"
        ;;
    "中等")
        echo "SUGGESTED_TASK_COUNT: 5-8"
        echo "TASK_SIZE: 6-10 hours each"
        ;;
    "复杂")
        echo "SUGGESTED_TASK_COUNT: 8-12"
        echo "TASK_SIZE: 8-15 hours each"
        ;;
    *)
        echo "SUGGESTED_TASK_COUNT: 5-8"
        echo "TASK_SIZE: 6-10 hours each"
        ;;
esac
echo ""

echo "=== EXISTING_TASKS_CHECK ==="
if [ -d "$FEATURE_DIR/tasks" ]; then
    existing_count=$(find "$FEATURE_DIR/tasks" -name "*.md" 2>/dev/null | wc -l)
    echo "EXISTING_TASKS: $existing_count"
    
    if [ "$existing_count" -gt 0 ]; then
        echo "--- CURRENT_TASKS ---"
        find "$FEATURE_DIR/tasks" -name "*.md" | sort | while read task_file; do
            task_id=$(basename "$task_file" .md)
            task_name=$(grep "^name:" "$task_file" 2>/dev/null | sed 's/^name: *//' || echo "")
            echo "$task_id: $task_name"
        done
    fi
else
    echo "EXISTING_TASKS: 0"
    mkdir -p "$FEATURE_DIR/tasks"
    echo "TASKS_DIR: CREATED"
fi
echo ""

echo "=== TECHNICAL_DEPENDENCIES ==="
dependencies=$(grep "^dependencies:" "$FEATURE_DIR/technical.md" 2>/dev/null | sed 's/^dependencies: *//' || echo "[]")
tech_stack=$(grep "^tech_stack:" "$FEATURE_DIR/technical.md" 2>/dev/null | sed 's/^tech_stack: *//' || echo "[]")

echo "FEATURE_DEPENDENCIES: $dependencies"
echo "TECHNOLOGY_STACK: $tech_stack"
echo ""

echo "✅ Technical analysis completed for: $FEATURE_NAME"
echo "📊 Ready for intelligent task decomposition based on technical complexity"