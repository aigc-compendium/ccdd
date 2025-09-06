#!/bin/bash

echo "Initializing..."
echo ""
echo ""

echo "🚀 Initializing DD System"
echo "========================="
echo ""

# Create CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
  echo ""
  echo "📄 Creating CLAUDE.md..."
  cat > CLAUDE.md << 'EOF'
# CLAUDE.md

> 仔细思考并实现最简洁的解决方案，尽可能少地更改代码。

## DD 工作流系统

这是 DD（开发工作流）系统 - 一个结构化的开发工作流。

## 使用方法

1. 初始化: `/dd:ctx-init`
2. 创建PRD: `/dd:prd-new <名称>`  
3. 查看状态: `/dd:status`
4. 查看帮助: `/dd:help`

## 项目说明

在此添加项目特定的说明。
EOF
  echo "  ✅ CLAUDE.md created"
fi

echo ""
echo "✅ Initialization Complete!"
echo "=========================="
echo ""
echo "🎯 建议的下一步操作:"
echo "  1. 开始开发新功能: /dd:prd-new <功能名称>"
echo "  2. 查看系统帮助: /dd:help"
echo "  3. 检查项目状态: /dd:status"
echo ""
echo "💡 完整开发工作流:"
echo "  /dd:prd-new → /dd:prd-parse → /dd:epic-decompose → /dd:task-start → /dd:code-reflect → /dd:task-finish"

exit 0