#!/bin/bash

# DD Chat 持久上下文加载脚本
# 读取并整合所有项目上下文文件, 为智能对话提供完整的项目感知能力

set -e

echo "=== DD 项目上下文加载器 ==="
echo "正在加载持久项目上下文以支持智能对话..."
echo ""

echo "=== 项目基础信息 ==="
if [ -f ".claude/context/project.md" ]; then
    echo "📄 项目文档内容:"
    echo "---"
    cat ".claude/context/project.md"
    echo "---"
    echo ""
else
    echo "❌ project.md 未找到 - 项目上下文不完整"
    echo ""
fi

echo "=== 项目架构信息 ==="
if [ -f ".claude/context/architecture.md" ]; then
    echo "🏗️ 架构文档内容:"
    echo "---"
    cat ".claude/context/architecture.md"
    echo "---"
    echo ""
else
    echo "❌ architecture.md 未找到 - 架构上下文不完整"
    echo ""
fi

echo "=== 技术栈信息 ==="
if [ -f ".claude/context/tech-stack.md" ]; then
    echo "⚙️ 技术栈文档内容:"
    echo "---"
    cat ".claude/context/tech-stack.md"
    echo "---"
    echo ""
else
    echo "❌ tech-stack.md 未找到 - 技术栈上下文不完整"
    echo ""
fi

echo "=== 当前项目状态 ==="
if [ -f ".claude/context/current-status.md" ]; then
    echo "📊 状态文档内容:"
    echo "---"
    cat ".claude/context/current-status.md"
    echo "---"
    echo ""
else
    echo "❌ current-status.md 未找到 - 状态上下文不完整"
    echo ""
fi

echo "=== 功能概览 ==="
if [ -d ".claude/features" ]; then
    feature_count=$(find ".claude/features" -maxdepth 1 -type d | grep -v "^\.claude/features$" | wc -l)
    echo "📋 发现 $feature_count 个功能:"
    echo ""
    
    if [ "$feature_count" -gt 0 ]; then
        find ".claude/features" -maxdepth 1 -type d ! -path ".claude/features" | while read feature_dir; do
            feature_name=$(basename "$feature_dir")
            echo "--- 功能: $feature_name ---"
            
            if [ -f "$feature_dir/feature.md" ]; then
                echo "🎯 功能详情:"
                # 读取功能的关键信息
                grep -E "^(name|status|progress|tasks_total|tasks_completed):" "$feature_dir/feature.md" 2>/dev/null || echo "元数据不完整"
                echo ""
                
                # 读取功能目标
                if grep -q "## 功能目标" "$feature_dir/feature.md"; then
                    echo "📝 功能目标:"
                    sed -n '/## 功能目标/,/## /p' "$feature_dir/feature.md" | head -n -1
                    echo ""
                fi
            else
                echo "❌ $feature_name 缺少 feature.md 文件"
                echo ""
            fi
            
            # 检查任务信息
            if [ -d "$feature_dir/tasks" ]; then
                task_count=$(find "$feature_dir/tasks" -name "*.md" 2>/dev/null | wc -l)
                echo "📋 任务: 发现 $task_count 个任务"
                
                if [ "$task_count" -gt 0 ]; then
                    echo "📋 任务状态:"
                    find "$feature_dir/tasks" -name "*.md" | sort | while read task_file; do
                        task_id=$(basename "$task_file" .md)
                        task_name=$(grep "^name:" "$task_file" 2>/dev/null | sed 's/^name: *//' || echo "未命名")
                        task_status=$(grep "^status:" "$task_file" 2>/dev/null | sed 's/^status: *//' || echo "未知")
                        echo "  - 任务 $task_id: $task_name [$task_status]"
                    done
                fi
                echo ""
            else
                echo "📋 任务: 未找到任务目录"
                echo ""
            fi
            
            echo ""
        done
    fi
else
    echo "❌ .claude/features 目录未找到 - 无功能上下文可用"
    echo ""
fi

echo "=== 会话历史 ==="
if [ -d ".claude/context/session" ]; then
    session_count=$(find ".claude/context/session" -name "*.md" 2>/dev/null | wc -l)
    echo "📚 发现 $session_count 个会话文件:"
    
    if [ "$session_count" -gt 0 ]; then
        # 显示最近的几个会话文件
        find ".claude/context/session" -name "*.md" -type f | head -5 | while read session_file; do
            session_name=$(basename "$session_file" .md)
            echo "  - 会话: $session_name"
            if [ -f "$session_file" ]; then
                echo "    内容预览:"
                head -10 "$session_file" | sed 's/^/    /'
                echo "    ..."
                echo ""
            fi
        done
        
        if [ "$session_count" -gt 5 ]; then
            echo "  ... 还有 $((session_count - 5)) 个会话文件"
            echo ""
        fi
    fi
else
    echo "❌ session 目录未找到 - 无会话历史可用"
    echo ""
fi

echo "=== Claude 配置 ==="
if [ -f "CLAUDE.md" ]; then
    echo "⚙️ 发现 CLAUDE.MD - DD 系统配置已激活"
    echo "可用 DD 命令: $(grep -c '/dd:' CLAUDE.md) 个命令"
    echo ""
else
    echo "❌ 项目根目录未找到 CLAUDE.md - DD 系统可能配置不正确"
    echo ""
fi

echo "=== DD 系统状态 ==="
echo "📍 当前工作目录: $(pwd)"
echo "📦 DD 目录结构:"
if [ -d ".claude" ]; then
    echo "  ✅ .claude/ 目录存在"
    echo "  ✅ 命令文件: $(find .claude/commands -name "*.md" 2>/dev/null | wc -l) 个"
    echo "  ✅ 脚本文件: $(find .claude/scripts -name "*.sh" 2>/dev/null | wc -l) 个"
    echo "  ✅ 智能体文件: $(find .claude/agents -name "*.md" 2>/dev/null | wc -l) 个"
else
    echo "  ❌ .claude/ 目录缺失"
fi
echo ""

echo "=== 上下文加载完成 ==="
echo "🎯 项目上下文已成功加载, 支持智能对话"
echo "💡 现在可以提问项目相关问题, 获得上下文感知的回答"
echo "📝 AI 将理解您的项目结构、功能、任务和技术决策"
echo ""

echo "=== 准备开始对话 ==="
echo "✨ 上下文注入完成 - 准备进行智能对话"