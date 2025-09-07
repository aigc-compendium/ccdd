#!/bin/bash

# DD 项目初始化脚本
# 为新项目初始化 CCDD Helper 系统

set -e

show_help() {
  echo "🎯 DD 项目初始化"
  echo "================"
  echo ""
  echo "功能: 为新项目初始化 CCDD Helper 系统"
  echo ""
  echo "用法: "
  echo "  $0                    # 开始初始化向导"
  echo "  $0 --help           # 显示帮助信息"
  echo ""
  echo "执行内容: "
  echo "  • 深度讨论项目需求和技术选型"
  echo "  • 生成项目上下文文档"
  echo "  • 执行 after-init.sh 完成配置"
  echo ""
  echo "前置条件: "
  echo "  • 在项目根目录执行"
  echo "  • 确保 .claude 目录结构完整"
}

check_environment() {
  echo "🔍 检查执行环境..."
  
  if [ ! -d ".claude" ]; then
    echo "❌ 未找到 .claude 目录, 请确保在正确的项目根目录执行"
    exit 1
  fi
  
  if [ ! -f ".claude/CLAUDE.md" ]; then
    echo "❌ 未找到 .claude/CLAUDE.md 配置文件"
    exit 1
  fi
  
  echo "✅ 环境检查通过"
}

interactive_init() {
  echo "🎯 DD 项目初始化向导"
  echo "==================="
  echo ""
  echo "我将通过深度对话帮助您初始化项目. "
  echo ""
  echo "🤖 正在启动深度思考模式..."
  echo "💬 智能体将分析以下方面: "
  echo "  • 项目类型和目标"
  echo "  • 技术选型建议"
  echo "  • 团队和资源情况"
  echo "  • 开发计划和时间线"
  echo ""
  echo "📋 完成后将生成项目上下文文档并执行初始化配置"
  echo ""
  echo "💡 提示: 初始化过程中 AI 会主动质疑和提出建议, "
  echo "   请准备详细讨论项目的各个方面. "
}

run_after_init() {
  echo ""
  echo "🔄 执行初始化后处理..."
  
  if [ -f ".claude/scripts/dd/after-init.sh" ]; then
    bash .claude/scripts/dd/after-init.sh
    echo "✅ 初始化后处理完成"
  else
    echo "⚠️ 未找到 after-init.sh 脚本"
  fi
}

show_completion() {
  echo ""
  echo "🎉 项目初始化完成！"
  echo "=================="
  echo ""
  echo "📋 已生成的文档: "
  echo "  • .claude/context/project.md     - 项目基础信息"
  echo "  • .claude/context/architecture.md - 架构设计框架"
  echo "  • .claude/context/tech-stack.md  - 技术栈信息"
  echo "  • .claude/context/current-status.md - 当前状态"
  echo ""
  echo "📝 建议下一步操作: "
  echo "   /dd:prd  - 开始详细需求设计"
  echo ""
  echo "💡 或使用智能对话: "
  echo "   /dd:chat - 继续深度讨论项目规划"
}

main() {
  case "${1:-}" in
    "--help"|"-h"|"help")
      show_help
      ;;
    "")
      check_environment
      interactive_init
      # 注意: 实际的深度对话由 Claude Code 系统处理
      # 此脚本主要提供流程引导和环境检查
      run_after_init
      show_completion
      ;;
    *)
      echo "❌ 未知参数: $1"
      echo "💡 使用 $0 --help 查看帮助"
      exit 1
      ;;
  esac
}

main "$@"