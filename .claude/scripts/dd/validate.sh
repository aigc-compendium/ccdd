#!/bin/bash

echo "验证 DD 系统..."
echo ""
echo ""

echo "🔍 验证 DD 系统"
echo "================"
echo ""

errors=0

echo "📁 目录结构:"
[ -d ".claude" ] && echo "  ✅ .claude 目录存在" || { echo "  ❌ .claude 目录缺失"; ((errors++)); }
[ -d ".claude/prds" ] && echo "  ✅ PRDs 目录存在" || echo "  ⚠️ PRDs 目录缺失"
[ -d ".claude/epics" ] && echo "  ✅ Epics 目录存在" || echo "  ⚠️ Epics 目录缺失"

echo ""
echo "📊 验证结果:"
echo "  错误: $errors"

if [ $errors -eq 0 ]; then
  echo ""
  echo "✅ 系统验证通过！"
else
  echo ""
  echo "❌ 发现错误，需要修复"
fi

exit 0