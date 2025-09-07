#!/bin/bash

# DD 任务添加 - 上下文文件脚本
# 基于项目上下文信息生成任务, 返回结构化信息给智能体

set -e

FEATURE_NAME="$1"
FEATURE_DIR=".claude/features/$FEATURE_NAME"

if [ -z "$FEATURE_NAME" ]; then
    echo "ERROR: Missing feature name parameter"
    exit 1
fi

echo "=== TASK_ADD_CONTEXT ==="
echo "FEATURE_NAME: $FEATURE_NAME"
echo "FEATURE_DIR: $FEATURE_DIR"
echo ""

echo "=== PROJECT_CONTEXT ==="
# 读取项目基本信息
if [ -f ".claude/context/project.md" ]; then
    echo "PROJECT_INFO: EXISTS"
    echo "--- PROJECT_METADATA ---"
    head -30 ".claude/context/project.md"
    echo ""
else
    echo "PROJECT_INFO: NOT_EXISTS"
fi

echo "=== ARCHITECTURE_CONTEXT ==="
# 读取架构信息
if [ -f ".claude/context/architecture.md" ]; then
    echo "ARCHITECTURE_INFO: EXISTS"
    echo "--- ARCHITECTURE_OVERVIEW ---"
    head -30 ".claude/context/architecture.md"
    echo ""
else
    echo "ARCHITECTURE_INFO: NOT_EXISTS"
fi

echo "=== TECH_STACK_CONTEXT ==="
# 读取技术栈信息
if [ -f ".claude/context/tech-stack.md" ]; then
    echo "TECH_STACK_INFO: EXISTS"
    echo "--- TECHNOLOGY_STACK ---"
    head -30 ".claude/context/tech-stack.md"
    echo ""
else
    echo "TECH_STACK_INFO: NOT_EXISTS"
fi

echo "=== CURRENT_STATUS ==="
# 读取当前项目状态
if [ -f ".claude/context/current-status.md" ]; then
    echo "STATUS_INFO: EXISTS"
    echo "--- PROJECT_STATUS ---"
    head -20 ".claude/context/current-status.md"
    echo ""
else
    echo "STATUS_INFO: NOT_EXISTS"
fi

echo "=== EXISTING_FEATURES ==="
# 扫描已有功能
if [ -d ".claude/features" ]; then
    feature_count=$(find ".claude/features" -maxdepth 1 -type d | wc -l)
    feature_count=$((feature_count - 1)) # 减去 features 目录本身
    
    echo "TOTAL_FEATURES: $feature_count"
    
    if [ "$feature_count" -gt 0 ]; then
        echo "--- FEATURE_LIST ---"
        find ".claude/features" -maxdepth 1 -type d ! -path ".claude/features" | while read feature_dir; do
            feature_name=$(basename "$feature_dir")
            if [ -f "$feature_dir/feature.md" ]; then
                status=$(grep "^status:" "$feature_dir/feature.md" 2>/dev/null | sed 's/^status: *//' || echo "未知")
                progress=$(grep "^progress:" "$feature_dir/feature.md" 2>/dev/null | sed 's/^progress: *//' || echo "0")
                echo "$feature_name: [$status] $progress%"
            else
                echo "$feature_name: [无状态文件]"
            fi
        done
        echo ""
    fi
else
    echo "TOTAL_FEATURES: 0"
fi

echo "=== DEPENDENCY_ANALYSIS ==="
# 分析当前功能与已有功能的依赖关系
if [ -f "$FEATURE_DIR/technical.md" ]; then
    feature_deps=$(grep "^dependencies:" "$FEATURE_DIR/technical.md" 2>/dev/null | sed 's/^dependencies: *//' || echo "[]")
    echo "FEATURE_DEPENDENCIES: $feature_deps"
    
    # 检查依赖功能的状态
    if [ "$feature_deps" != "[]" ] && [ -n "$feature_deps" ]; then
        echo "--- DEPENDENCY_STATUS ---"
        # 简单解析依赖（假设为逗号分隔）
        echo "$feature_deps" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,/ /g' | while read -r dep; do
            dep=$(echo "$dep" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/"//g')
            if [ -n "$dep" ] && [ -d ".claude/features/$dep" ]; then
                if [ -f ".claude/features/$dep/feature.md" ]; then
                    dep_status=$(grep "^status:" ".claude/features/$dep/feature.md" 2>/dev/null | sed 's/^status: *//' || echo "未知")
                    dep_progress=$(grep "^progress:" ".claude/features/$dep/feature.md" 2>/dev/null | sed 's/^progress: *//' || echo "0")
                    echo "DEPENDENCY_$dep: [$dep_status] $dep_progress%"
                else
                    echo "DEPENDENCY_$dep: [状态文件缺失]"
                fi
            else
                echo "DEPENDENCY_$dep: [功能不存在]"
            fi
        done
    fi
else
    echo "FEATURE_DEPENDENCIES: []"
fi
echo ""

echo "=== TASK_CONTEXT_SUMMARY ==="
echo "PROJECT_CONTEXT_AVAILABLE: $([ -f ".claude/context/project.md" ] && echo "true" || echo "false")"
echo "ARCHITECTURE_CONTEXT_AVAILABLE: $([ -f ".claude/context/architecture.md" ] && echo "true" || echo "false")"
echo "TECH_STACK_CONTEXT_AVAILABLE: $([ -f ".claude/context/tech-stack.md" ] && echo "true" || echo "false")"
echo "EXISTING_FEATURES_COUNT: $(find ".claude/features" -maxdepth 1 -type d 2>/dev/null | wc -l | xargs expr -1 +)"
echo ""

echo "✅ Context analysis completed for: $FEATURE_NAME"
echo "🔗 Dependency relationships and project context loaded for task decomposition"