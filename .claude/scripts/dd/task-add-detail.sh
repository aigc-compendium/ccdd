#!/bin/bash

# DD 任务细节生成脚本
# 动态生成单个任务的详细文档

set -e

FEATURE_NAME="$1"
TASK_ID="$2"
TASK_DATA="$3"  # JSON格式的任务数据
OVERWRITE="${4:-false}"  # 可选参数, 默认为false

if [ -z "$FEATURE_NAME" ] || [ -z "$TASK_ID" ] || [ -z "$TASK_DATA" ]; then
    echo "ERROR: Missing required parameters"
    echo "Usage: $0 <feature_name> <task_id> <task_data_json> [overwrite]"
    echo "  overwrite: true|false (default: false)"
    exit 1
fi

FEATURE_DIR=".claude/features/$FEATURE_NAME"
TASKS_DIR="$FEATURE_DIR/tasks"
TASK_FILE="$TASKS_DIR/$TASK_ID.md"

echo "=== TASK_DETAIL_GENERATION ==="
echo "FEATURE_NAME: $FEATURE_NAME"
echo "TASK_ID: $TASK_ID"
echo "TASK_FILE: $TASK_FILE"
echo "OVERWRITE: $OVERWRITE"
echo ""

# 检查文件是否存在, 是否允许覆盖
if [ -f "$TASK_FILE" ] && [ "$OVERWRITE" != "true" ]; then
    echo "ERROR: Task file already exists: $TASK_FILE"
    echo "Use overwrite=true to replace existing file"
    exit 1
fi

# 确保目录存在
mkdir -p "$TASKS_DIR"

# JSON解析函数
parse_json_field() {
    local json="$1"
    local field="$2"
    local default="$3"
    
    local value=$(echo "$json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\"/\1/" || echo "$default")
    echo "$value"
}

parse_json_array() {
    local json="$1"
    local field="$2"
    
    echo "$json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\[[^\]]*\]" | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\[\([^\]]*\)\]/\1/" | sed 's/"//g'
}

# 解析任务数据
TASK_NAME=$(parse_json_field "$TASK_DATA" "name" "任务$TASK_ID")
TASK_PRIORITY=$(parse_json_field "$TASK_DATA" "priority" "中")
TASK_DIFFICULTY=$(parse_json_field "$TASK_DATA" "difficulty" "中等")
TASK_HOURS=$(parse_json_field "$TASK_DATA" "estimated_hours" "8")
TASK_GOAL=$(parse_json_field "$TASK_DATA" "goal" "")
TASK_POINTS=$(parse_json_field "$TASK_DATA" "implementation_points" "")
TASK_DETAILS=$(parse_json_field "$TASK_DATA" "technical_details" "")
TASK_DEPENDENCIES=$(parse_json_array "$TASK_DATA" "dependencies")
TASK_TODOS=$(parse_json_array "$TASK_DATA" "todos")
TASK_ACCEPTANCE=$(parse_json_array "$TASK_DATA" "acceptance_criteria")

echo "=== PARSED_TASK_DATA ==="
echo "TASK_NAME: $TASK_NAME"
echo "TASK_PRIORITY: $TASK_PRIORITY"
echo "TASK_DIFFICULTY: $TASK_DIFFICULTY"
echo "TASK_HOURS: $TASK_HOURS"
echo ""

# 生成任务文件内容
cat > "$TASK_FILE" << EOF
---
name: $TASK_NAME
feature: $FEATURE_NAME
status: 未开始
progress: 0
priority: $TASK_PRIORITY
difficulty: $TASK_DIFFICULTY
estimated_hours: $TASK_HOURS
dependencies: [$TASK_DEPENDENCIES]
---

# $TASK_NAME

## 任务目标
$TASK_GOAL

## 实现要点
EOF

# 添加实现要点（如果有的话, 按行分割）
if [ -n "$TASK_POINTS" ]; then
    echo "$TASK_POINTS" | sed 's/\\n/\n/g' | while IFS= read -r point; do
        if [ -n "$point" ]; then
            echo "- $point" >> "$TASK_FILE"
        fi
    done
else
    echo "- 待补充实现要点" >> "$TASK_FILE"
fi

cat >> "$TASK_FILE" << EOF

## 验收标准
EOF

# 添加验收标准列表
if [ -n "$TASK_ACCEPTANCE" ]; then
    echo "$TASK_ACCEPTANCE" | sed 's/,/\n/g' | while IFS= read -r criterion; do
        criterion=$(echo "$criterion" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [ -n "$criterion" ]; then
            echo "- [ ] $criterion" >> "$TASK_FILE"
        fi
    done
else
    echo "- [ ] 功能实现完成" >> "$TASK_FILE"
    echo "- [ ] 单元测试通过" >> "$TASK_FILE"
    echo "- [ ] 代码审查通过" >> "$TASK_FILE"
fi

cat >> "$TASK_FILE" << EOF

## 技术细节
EOF

# 添加技术细节（如果有的话, 按行分割）
if [ -n "$TASK_DETAILS" ]; then
    echo "$TASK_DETAILS" | sed 's/\\n/\n/g' >> "$TASK_FILE"
else
    echo "待补充技术实现细节" >> "$TASK_FILE"
fi

cat >> "$TASK_FILE" << EOF

## Todo 列表
EOF

# 添加Todo列表
if [ -n "$TASK_TODOS" ]; then
    echo "$TASK_TODOS" | sed 's/,/\n/g' | while IFS= read -r todo; do
        todo=$(echo "$todo" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [ -n "$todo" ]; then
            echo "- [ ] $todo" >> "$TASK_FILE"
        fi
    done
else
    echo "- [ ] 分析需求和设计方案" >> "$TASK_FILE"
    echo "- [ ] 编写核心实现代码" >> "$TASK_FILE"
    echo "- [ ] 编写单元测试" >> "$TASK_FILE"
    echo "- [ ] 进行代码审查" >> "$TASK_FILE"
    echo "- [ ] 更新相关文档" >> "$TASK_FILE"
fi

echo ""
echo "=== GENERATION_RESULT ==="
echo "TASK_FILE_CREATED: $TASK_FILE"
echo "TASK_FILE_SIZE: $(wc -c < "$TASK_FILE") bytes"
echo "TASK_LINES: $(wc -l < "$TASK_FILE") lines"

# 验证依赖关系（如果有的话）
if [ -n "$TASK_DEPENDENCIES" ] && [ "$TASK_DEPENDENCIES" != "[]" ]; then
    echo "TASK_DEPENDENCIES: $TASK_DEPENDENCIES"
    echo "DEPENDENCY_CHECK: $(echo "$TASK_DEPENDENCIES" | wc -w) dependencies found"
else
    echo "TASK_DEPENDENCIES: none"
fi

echo ""
echo "✅ Task detail generated: $TASK_ID.md for feature $FEATURE_NAME"