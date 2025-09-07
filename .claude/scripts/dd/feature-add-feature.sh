#!/bin/bash

# DD 功能描述文档生成脚本
# 基于 JSON 数据生成 feature.md 功能描述文档

set -e

# 解析参数
FEATURE_NAME="$1"
feature_data="$2"

if [ -z "$FEATURE_NAME" ]; then
    echo "ERROR: Missing feature name parameter"
    echo "用法: bash feature-add-feature.sh '<feature_name>' '<json_data>'"
    exit 1
fi

if [ -z "$feature_data" ] || [ "$feature_data" = "null" ]; then
    echo "ERROR: Missing JSON data parameter"
    echo "用法: bash feature-add-feature.sh '<feature_name>' '<json_data>'"
    exit 1
fi

FEATURE_DIR=".claude/features/$FEATURE_NAME"
FEATURE_FILE="$FEATURE_DIR/feature.md"

echo "=== FEATURE_ADD_FEATURE ==="
echo "FEATURE_NAME: $FEATURE_NAME"
echo "FEATURE_DIR: $FEATURE_DIR"
echo ""

# 确保功能目录存在
mkdir -p "$FEATURE_DIR"

# 从 JSON 中提取数据
goal=$(echo "$feature_data" | jq -r '.goal // "功能目标待定义"')
user_value=$(echo "$feature_data" | jq -r '.user_value // "用户价值待明确"')
core_features=$(echo "$feature_data" | jq -r '.core_features // "核心功能待设计"')
feature_boundary_include=$(echo "$feature_data" | jq -r '.feature_boundary_include // "功能边界待定义"')
feature_boundary_exclude=$(echo "$feature_data" | jq -r '.feature_boundary_exclude // "排除边界待明确"')
use_scenarios=$(echo "$feature_data" | jq -r '.use_scenarios // "使用场景待描述"')
acceptance_criteria=$(echo "$feature_data" | jq -r '.acceptance_criteria // "验收标准待制定"')
complexity=$(echo "$feature_data" | jq -r '.complexity // "中等"')
estimated_hours=$(echo "$feature_data" | jq -r '.estimated_hours // "40"')
dependencies=$(echo "$feature_data" | jq -r '.dependencies // "无特殊依赖"')

# 生成功能描述文档
cat > "$FEATURE_FILE" << EOF
---
feature_name: $FEATURE_NAME
status: 设计中
complexity: $complexity
estimated_hours: $estimated_hours
priority: 中等
---

# 功能: $FEATURE_NAME

## 功能目标
$goal

## 用户价值
$user_value

## 核心功能
$core_features

## 功能边界

### 包含的功能
$feature_boundary_include

### 不包含的功能  
$feature_boundary_exclude

## 使用场景
$use_scenarios

## 验收标准
$acceptance_criteria

## 技术考量
### 复杂度评估
- **开发复杂度**: $complexity
- **预估工时**: $estimated_hours 小时

### 技术依赖
$dependencies

### 风险评估
- 技术风险: 待评估
- 业务风险: 待评估
- 时间风险: 待评估

## 设计文档
相关设计文档将在 technical.md 中详细描述

## 测试计划
相关测试计划将在 testing.md 中详细制定

## 开发状态
- [x] 功能需求分析
- [ ] 技术方案设计
- [ ] 测试计划制定
- [ ] 任务分解规划
- [ ] 功能开发实现
- [ ] 测试验证完成

## 更新历史
- $(date +"%Y-%m-%d"): 功能需求文档创建
EOF

echo "✅ 功能描述文档已生成: $FEATURE_FILE"
echo ""