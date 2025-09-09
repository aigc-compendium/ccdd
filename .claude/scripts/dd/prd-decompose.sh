#!/bin/bash

# 需求拆解脚本
# 基于PRD和架构设计拆解大功能模块, 规划开发路径

set -e

show_help() {
  echo "🎯 DD 需求拆解工具"
  echo "=================="
  echo ""
  echo "功能: 基于PRD和架构设计, 将项目需求拆解为大功能模块"
  echo ""
  echo "用法: "
  echo "  $0                          # 自动分析并拆解需求"
  echo "  $0 --interactive            # 交互式拆解过程"
  echo "  $0 --show                   # 显示现有拆解结果"
  echo ""
  echo "执行条件: "
  echo "  • 项目已完成初始化 (dd:init)"  # 支持 --analyze 参数
  echo "  • 已完成需求设计 (dd:prd)"  
  echo "  • 已完成架构设计 (dd:framework-init)"
  echo ""
  echo "输出: "
  echo "  • 生成 .claude/context/requirements-breakdown.md"
  echo "  • 创建功能模块开发路径规划"
  echo "  • 提供下一步操作建议"
}

check_prerequisites() {
  local missing=false
  
  echo "🔍 检查前置条件..."
  
  # 检查项目是否已初始化
  if [ ! -f ".claude/context/project.md" ]; then
    echo "❌ 项目未初始化, 请先执行 /dd:init (支持 --analyze 参数)"
    missing=true
  fi
  
  # 检查是否已完成需求设计
  if [ ! -f ".claude/context/project.md" ] || ! grep -q "prd_completed" .claude/context/project.md 2>/dev/null; then
    echo "⚠️  建议先完成需求设计 (/dd:prd)"
  fi
  
  # 检查是否已完成架构设计
  if [ ! -f ".claude/context/architecture.md" ]; then
    echo "❌ 架构设计未完成, 请先执行 /dd:framework-init"
    missing=true
  fi
  
  if [ "$missing" = true ]; then
    echo ""
    echo "🚨 前置条件不满足, 无法执行需求拆解"
    exit 1
  fi
  
  echo "✅ 前置条件检查通过"
}

load_project_context() {
  echo "📋 加载项目上下文..."
  
  # 读取项目信息
  if [ -f ".claude/context/project.md" ]; then
    PROJECT_NAME=$(grep "^name:" .claude/context/project.md | cut -d: -f2- | xargs)
    PROJECT_TYPE=$(grep "^type:" .claude/context/project.md | cut -d: -f2- | xargs)
    echo "  项目名称: $PROJECT_NAME"
    echo "  项目类型: $PROJECT_TYPE"
  fi
  
  # 读取架构信息
  if [ -f ".claude/context/architecture.md" ]; then
    echo "  ✅ 架构设计文档已加载"
  fi
  
  # 读取技术栈信息
  if [ -f ".claude/context/tech-stack.md" ]; then
    echo "  ✅ 技术栈信息已加载"
  fi
}

show_existing_breakdown() {
  if [ -f ".claude/context/requirements-breakdown.md" ]; then
    echo "📋 当前需求拆解方案: "
    echo "===================="
    cat .claude/context/requirements-breakdown.md
  else
    echo "❌ 尚未生成需求拆解方案"
    echo "💡 请执行 /dd:requirements-decompose 生成拆解方案"
  fi
}

perform_decomposition() {
  echo "🧠 开始需求拆解分析..."
  echo "使用深度思考模式进行多维度分析..."
  echo ""
  
  local project_name=${PROJECT_NAME:-"未知项目"}
  
  # 创建需求拆解文档模板
  cat > .claude/context/requirements-breakdown.md << EOF
---
project: $project_name
status: 分析中
total_modules: 0
estimated_weeks: 0
complexity: 待评估
priority_order: []
---

# $project_name - 需求拆解方案

## 执行状态

🔄 **当前状态**: 正在进行深度思考分析
🎯 **分析目标**: 基于PRD和架构设计拆解功能模块

## 分析进度

- [x] 加载项目上下文
- [x] 读取架构设计
- [ ] 深度思考分析 (进行中)
- [ ] 功能模块识别
- [ ] 依赖关系分析  
- [ ] 优先级规划
- [ ] 开发路径设计

## 等待智能体完成分析...

此文档将由 DD 深度思考智能体更新完整的拆解方案. 
EOF
  
  echo "📄 已创建需求拆解文档模板"
  echo "🤖 正在调用深度思考智能体进行分析..."
}

show_completion_message() {
  local breakdown_file=".claude/context/requirements-breakdown.md"
  
  if [ -f "$breakdown_file" ]; then
    # 提取统计信息
    local total_modules=$(grep "total_modules:" "$breakdown_file" | cut -d: -f2 | xargs)
    local estimated_weeks=$(grep "estimated_weeks:" "$breakdown_file" | cut -d: -f2 | xargs)
    
    echo ""
    echo "🎯 需求拆解完成！"
    echo "📋 已生成 $total_modules 个功能模块的开发规划"
    echo "⏱️ 预估总开发时间: $estimated_weeks 周"
    echo ""
    echo "📝 建议下一步操作: "
    echo "   /dd:feature-add <第一优先级功能名>"
    echo ""
    echo "💡 查看完整拆解方案: "
    echo "   查看 .claude/context/requirements-breakdown.md"
    echo ""
    echo "🔍 或查看优先级顺序: "
    echo "   grep -A 20 '## 功能模块概览' .claude/context/requirements-breakdown.md"
  fi
}

main() {
  case "${1:-}" in
    "--help"|"-h"|"help")
      show_help
      ;;
    "--show"|"show")
      show_existing_breakdown
      ;;
    "--interactive"|"-i")
      echo "🎯 交互式需求拆解"
      echo "=================="
      check_prerequisites
      load_project_context
      echo ""
      echo "💬 提示: 此功能将启动深度对话进行需求分析"
      echo "🤖 请使用 /dd:chat 进行交互式需求拆解讨论"
      ;;
    "")
      echo "🎯 DD 需求拆解 - 自动分析模式"
      echo "=============================="
      check_prerequisites
      load_project_context
      perform_decomposition
      
      echo ""
      echo "📋 需求拆解文档已生成, 等待智能体完成详细分析..."
      echo "💡 智能体将基于以下信息进行深度分析: "
      echo "   • 项目上下文和需求"
      echo "   • 架构设计和技术选型"  
      echo "   • 功能模块拆解策略"
      echo "   • 依赖关系和优先级规划"
      ;;
    *)
      echo "❌ 未知参数: $1"
      echo "💡 使用 $0 --help 查看帮助"
      exit 1
      ;;
  esac
}

main "$@"