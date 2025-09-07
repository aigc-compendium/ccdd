#!/bin/bash

# DD 测试用例文档生成脚本
# 基于 JSON 数据生成 testing.md 测试用例文档

set -e

# 解析参数
FEATURE_NAME="$1"
testing_data="$2"

if [ -z "$FEATURE_NAME" ]; then
    echo "ERROR: Missing feature name parameter"
    echo "用法: bash feature-add-testing.sh '<feature_name>' '<json_data>'"
    exit 1
fi

if [ -z "$testing_data" ] || [ "$testing_data" = "null" ]; then
    echo "ERROR: Missing JSON data parameter"
    echo "用法: bash feature-add-testing.sh '<feature_name>' '<json_data>'"
    exit 1
fi

FEATURE_DIR=".claude/features/$FEATURE_NAME"
TESTING_FILE="$FEATURE_DIR/testing.md"

echo "=== FEATURE_ADD_TESTING ==="
echo "FEATURE_NAME: $FEATURE_NAME"
echo "TESTING_FILE: $TESTING_FILE"
echo ""

# 确保功能目录存在
mkdir -p "$FEATURE_DIR"

# 从 JSON 中提取数据
test_strategy=$(echo "$testing_data" | jq -r '.test_strategy // "测试策略待制定"')
unit_tests=$(echo "$testing_data" | jq -r '.unit_tests // "单元测试用例待设计"')
integration_tests=$(echo "$testing_data" | jq -r '.integration_tests // "集成测试用例待设计"')
e2e_tests=$(echo "$testing_data" | jq -r '.e2e_tests // "端到端测试用例待设计"')
performance_tests=$(echo "$testing_data" | jq -r '.performance_tests // "性能测试待规划"')
security_tests=$(echo "$testing_data" | jq -r '.security_tests // "安全测试待设计"')
test_data=$(echo "$testing_data" | jq -r '.test_data // "测试数据待准备"')
test_environment=$(echo "$testing_data" | jq -r '.test_environment // "测试环境待搭建"')
coverage_requirements=$(echo "$testing_data" | jq -r '.coverage_requirements // "覆盖率要求: 80%以上"')

# 生成测试用例文档
cat > "$TESTING_FILE" << EOF
---
feature_name: $FEATURE_NAME
document_type: testing_plan
version: 1.0.0
---

# 测试计划: $FEATURE_NAME

## 测试策略
$test_strategy

## 测试类型

### 单元测试
$unit_tests

### 集成测试
$integration_tests

### 端到端测试
$e2e_tests

### 性能测试
$performance_tests

### 安全测试
$security_tests

## 测试数据
$test_data

## 测试环境
$test_environment

## 覆盖率要求
$coverage_requirements

## 测试用例清单
### 正常流程测试
- [ ] 基本功能正常流程验证
- [ ] 边界值测试
- [ ] 典型使用场景测试

### 异常流程测试
- [ ] 错误输入处理
- [ ] 异常情况处理
- [ ] 系统异常恢复

### 性能测试
- [ ] 响应时间测试
- [ ] 并发用户测试
- [ ] 资源消耗测试

### 安全测试
- [ ] 输入验证测试
- [ ] 权限控制测试
- [ ] 数据安全测试

## 测试执行计划
### 测试阶段
1. **单元测试**: 开发期间持续执行
2. **集成测试**: 功能开发完成后执行
3. **系统测试**: 所有功能集成后执行
4. **验收测试**: 正式发布前执行

### 测试时间规划
- 测试用例编写: 待安排
- 测试环境准备: 待安排
- 测试执行时间: 待安排
- 缺陷修复时间: 待安排

## 通过标准
- 所有测试用例通过率 >= 98%
- 代码覆盖率 >= 80%
- 性能指标达到要求
- 无严重安全漏洞

## 测试工具
### 自动化测试工具
- 单元测试框架: 待确定
- 集成测试工具: 待确定
- 性能测试工具: 待确定

### 测试管理工具
- 测试用例管理: 待确定
- 缺陷跟踪系统: 待确定
- 测试报告工具: 待确定

## 风险评估
### 测试风险
- 测试环境不稳定风险
- 测试数据不充分风险
- 测试时间不足风险

### 风险缓解措施
- 提前准备稳定的测试环境
- 设计全面的测试数据集
- 合理安排测试时间计划

## 更新历史
- $(date +"%Y-%m-%d"): 测试计划文档创建
EOF

echo "✅ 测试计划文档已生成: $TESTING_FILE"
echo ""