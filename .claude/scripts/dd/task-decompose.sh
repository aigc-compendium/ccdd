#!/bin/bash

# DD 任务分解脚本
# 将功能拆解为具体的开发任务

set -e

FEATURE_NAME=""

show_help() {
  echo "📝 DD 任务分解工具"
  echo "=================="
  echo ""
  echo "用法: "
  echo "  $0 <功能名称>         # 分解功能任务"
  echo "  $0 --help           # 显示帮助"
  echo ""
  echo "示例: "
  echo "  $0 用户认证系统"
  echo ""
  echo "功能: "
  echo "  • 深度分析功能技术实现路径"
  echo "  • 按合理性进行任务规划"
  echo "  • 生成详细任务文档"
}

validate_input() {
  if [ -z "$1" ]; then
    echo "❌ 错误: 缺少功能名称参数"
    show_help
    exit 1
  fi
  
  FEATURE_NAME="$1"
  
  # 检查功能是否存在
  if [ ! -d ".claude/features/$FEATURE_NAME" ]; then
    echo "❌ 错误: 功能 '$FEATURE_NAME' 不存在"
    echo "💡 使用 /dd:feature-add '$FEATURE_NAME' 先创建功能"
    exit 1
  fi
}

check_prerequisites() {
  echo "🔍 检查功能状态..."
  
  local feature_file=".claude/features/$FEATURE_NAME/feature.md"
  if [ ! -f "$feature_file" ]; then
    echo "❌ 功能文档不完整"
    exit 1
  fi
  
  # 检查技术方案是否存在
  if [ ! -f ".claude/features/$FEATURE_NAME/technical.md" ]; then
    echo "⚠️ 技术方案文档缺失, 建议先完善技术设计"
  fi
  
  echo "✅ 功能状态检查通过"
}

analyze_feature_complexity() {
  echo "🧠 分析功能复杂度..."
  
  local technical_file=".claude/features/$FEATURE_NAME/technical.md"
  if [ -f "$technical_file" ]; then
    local complexity=$(grep "^complexity:" "$technical_file" | cut -d: -f2- | xargs)
    local estimated_hours=$(grep "^estimated_hours:" "$technical_file" | cut -d: -f2- | xargs)
    
    echo "  复杂度: ${complexity:-中等}"
    echo "  预估工时: ${estimated_hours:-40}小时"
  fi
  
  echo "✅ 复杂度分析完成"
}

prepare_task_template() {
  echo "📋 准备任务模板..."
  
  local task_count=1
  
  # 检查现有任务数量
  local tasks_dir=".claude/features/$FEATURE_NAME/tasks"
  if [ -d "$tasks_dir" ]; then
    task_count=$(ls -1 "$tasks_dir"/*.md 2>/dev/null | wc -l)
    task_count=$((task_count + 1))
  fi
  
  # 准备任务编号
  TASK_ID=$(printf "%03d" $task_count)
  
  echo "  下一个任务编号: $TASK_ID"
  echo "✅ 任务模板准备完成"
}

create_sample_tasks() {
  echo "📝 创建示例任务结构..."
  
  local tasks_dir=".claude/features/$FEATURE_NAME/tasks"
  
  # 创建第一个示例任务
  cat > "$tasks_dir/001.md" << EOF
---
name: 数据模型设计
feature: $FEATURE_NAME
status: 未开始
progress: 0
priority: 高
difficulty: 中等
estimated_hours: 8
dependencies: []
---

# 数据模型设计

## 任务目标
设计和实现 $FEATURE_NAME 的核心数据模型, 包括数据库表结构和实体关系. 

## 实现要点
1. **数据库表设计**: 根据功能需求设计数据表结构
2. **实体关系**: 定义表间关系和约束
3. **数据验证**: 设置数据验证规则
4. **索引优化**: 创建必要的数据库索引

## 验收标准
- [ ] 完成数据模型设计文档
- [ ] 创建数据库迁移脚本
- [ ] 实现数据模型类/接口
- [ ] 编写数据模型单元测试
- [ ] 通过代码审查

## 技术细节

### 数据库设计
[具体的数据库表结构设计]

### 实体关系
[实体间的关系定义]

## Todo 列表

### 准备阶段
- [ ] 分析功能数据需求
- [ ] 设计数据库表结构
- [ ] 确定实体关系

### 开发阶段
- [ ] 创建数据库迁移脚本
- [ ] 实现数据模型类
- [ ] 添加数据验证规则
- [ ] 创建数据库索引

### 测试阶段
- [ ] 编写单元测试
- [ ] 执行数据完整性测试
- [ ] 性能测试

### 完成阶段
- [ ] 代码审查
- [ ] 文档更新
- [ ] 合并到主分支
EOF

  # 更新功能的任务统计
  update_feature_task_count 1
  
  echo "✅ 示例任务创建完成"
}

update_feature_task_count() {
  local task_count=$1
  local feature_file=".claude/features/$FEATURE_NAME/feature.md"
  
  # 使用 sed 更新任务总数和更新时间
  sed -i '' "s/^tasks_total:.*/tasks_total: $task_count/" "$feature_file"
}

show_completion() {
  echo ""
  echo "🎯 任务分解完成！"
  echo "================"
  echo ""
  echo "📋 功能: $FEATURE_NAME"
  echo "📊 已生成 1 个示例任务"
  echo "⏱️ 预估工时: 8 小时"
  echo ""
  echo "📝 建议下一步操作: "
  echo "   /dd:feature-start '$FEATURE_NAME'  - 开始功能开发"
  echo ""
  echo "💡 或查看任务详情: "
  echo "   查看 .claude/features/$FEATURE_NAME/tasks/ 目录"
  echo ""
  echo "🔧 任务管理: "
  echo "   /dd:task-start '$FEATURE_NAME:001'  - 开始第一个任务"
}

main() {
  case "${1:-}" in
    "--help"|"-h"|"help")
      show_help
      ;;
    "")
      echo "❌ 错误: 缺少功能名称参数"
      show_help
      exit 1
      ;;
    *)
      validate_input "$1"
      check_prerequisites
      analyze_feature_complexity
      prepare_task_template
      create_sample_tasks
      show_completion
      ;;
  esac
}

main "$@"