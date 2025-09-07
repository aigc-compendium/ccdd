#!/bin/bash

# DD 功能添加完成脚本
# 在功能文档生成完成后执行, 完成后续处理工作
# 根据 JSON 入参记录功能对话历史

set -e

# 解析参数
FEATURE_NAME="$1"
feature_data="$2"

if [ -z "$FEATURE_NAME" ]; then
    echo "ERROR: Missing feature name parameter"
    echo "用法: bash feature-add-finish.sh '<feature_name>' ['<json_data>']"
    exit 1
fi

FEATURE_DIR=".claude/features/$FEATURE_NAME"

echo "=== FEATURE_ADD_FINISH ==="
echo "FEATURE_NAME: $FEATURE_NAME"
echo "FEATURE_DIR: $FEATURE_DIR"
echo ""

# 记录功能设计对话历史
if [ -n "$feature_data" ] && [ "$feature_data" != "null" ] && [ "$feature_data" != "" ]; then
    echo "💬 记录功能设计对话历史..."
    
    # 确保对话目录存在
    mkdir -p ".claude/chats/feature"
    
    # 提取对话内容（如果 JSON 中包含）
    conversation=$(echo "$feature_data" | jq -r '.conversation // ""' 2>/dev/null || echo "")
    
    if [ -n "$conversation" ] && [ "$conversation" != "" ]; then
        # 优化: 直接使用功能名+时间戳避免文件检查
        safe_feature_name=$(echo "$FEATURE_NAME" | sed 's/[^a-zA-Z0-9\u4e00-\u9fa5]/_/g')
        chat_filename="feature-${safe_feature_name}-$(date +"%Y%m%d-%H%M%S").md"
        chat_filepath=".claude/chats/feature/$chat_filename"
        
        # 创建对话记录文件
        cat > "$chat_filepath" << EOF
---
type: feature_design
feature_name: $FEATURE_NAME
participants: [user, ai]
---

# 功能设计对话记录

## 功能信息

- **功能名称**: $FEATURE_NAME
- **对话类型**: 功能需求分析与设计

## 对话内容

$conversation

## 对话成果

通过本次对话, 完成了功能的详细设计, 包括: 

- 功能需求文档 (feature.md)
- 技术方案文档 (technical.md)  
- 测试用例文档 (testing.md)

## 后续行动

- 使用 \`/dd:task-decompose $FEATURE_NAME\` 进行任务分解
- 使用 \`/dd:feature-start $FEATURE_NAME\` 开始功能开发
EOF
        
        echo "  ✅ 对话历史已保存至: $chat_filepath"
    else
        echo "  ℹ️  JSON 数据中未包含对话内容"
    fi
    echo ""
else
    echo "ℹ️  未提供对话历史数据, 跳过对话记录"
    echo ""
fi

# 检查功能目录是否存在
if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature directory does not exist: $FEATURE_DIR"
    exit 1
fi

# 检查必要的功能文件是否存在
required_files=("feature.md" "technical.md" "testing.md")
for file in "${required_files[@]}"; do
    if [ ! -f "$FEATURE_DIR/$file" ]; then
        echo "ERROR: Required file missing: $FEATURE_DIR/$file"
        exit 1
    fi
done

echo "=== FEATURE_FILES_STATUS ==="
for file in "${required_files[@]}"; do
    if [ -f "$FEATURE_DIR/$file" ]; then
        echo "$file: EXISTS"
    else
        echo "$file: MISSING"
    fi
done
echo ""

echo "=== TASKS_DIRECTORY ==="
if [ -d "$FEATURE_DIR/tasks" ]; then
    task_count=$(find "$FEATURE_DIR/tasks" -name "*.md" 2>/dev/null | wc -l)
    echo "TASKS_DIR: EXISTS"
    echo "TASKS_COUNT: $task_count"
    
    if [ "$task_count" -gt 0 ]; then
        echo "=== TASKS_LIST ==="
        find "$FEATURE_DIR/tasks" -name "*.md" | sort | while read task_file; do
            task_id=$(basename "$task_file" .md)
            task_name=$(grep "^name:" "$task_file" 2>/dev/null | sed 's/^name: *//' || echo "")
            echo "TASK_$task_id: $task_name"
        done
        echo ""
    fi
else
    echo "TASKS_DIR: NOT_EXISTS"
    echo "TASKS_COUNT: 0"
fi
echo ""

echo "=== PROGRESS_CALCULATION ==="
if [ -x ".claude/scripts/dd/utils/progress-calc.sh" ]; then
    echo "🔄 计算并更新功能进度..."
    bash .claude/scripts/dd/utils/progress-calc.sh feature "$FEATURE_NAME"
    echo ""
else
    echo "⚠️  进度计算工具不可用, 跳过进度计算"
    echo ""
fi

echo "=== FEATURE_METADATA ==="
if [ -f "$FEATURE_DIR/feature.md" ]; then
    grep "^name:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "name: $FEATURE_NAME"
    grep "^status:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "status: 未开始"
    grep "^progress:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "progress: 0"
    grep "^tasks_total:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "tasks_total: 0"
    grep "^tasks_completed:" "$FEATURE_DIR/feature.md" 2>/dev/null || echo "tasks_completed: 0"
fi
echo ""

echo "=== NEXT_STEPS ==="
if [ -d "$FEATURE_DIR/tasks" ] && [ "$(find "$FEATURE_DIR/tasks" -name "*.md" 2>/dev/null | wc -l)" -gt 0 ]; then
    echo "READY_FOR_DEVELOPMENT: true"
    echo "NEXT_COMMAND: /dd:feature-start $FEATURE_NAME"
else
    echo "READY_FOR_DEVELOPMENT: false"
    echo "NEXT_COMMAND: /dd:task-decompose $FEATURE_NAME"
fi
echo ""

echo "✅ Feature add process completed: $FEATURE_NAME"