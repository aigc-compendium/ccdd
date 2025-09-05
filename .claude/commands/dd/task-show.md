---
allowed-tools: Read, LS, Grep
---

# 任务状态查看

查看指定任务或当前所有任务的详细状态信息。

## 用法
```
/dd:task-status [任务ID]
```

## 参数说明
- `[任务ID]` - 可选，指定要查看的任务ID。如果不提供，显示所有任务状态概览。

## 操作指南

### 1. 单个任务详细状态

```bash
if [ -n "$ARGUMENTS" ]; then
  # 查看指定任务的详细状态
  task_file=$(find .claude/epics -name "${ARGUMENTS}.md" | head -1)
  
  if [ ! -f "$task_file" ]; then
    echo "❌ 任务不存在：$ARGUMENTS"
    exit 1
  fi
  
  # 提取任务信息
  task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
  task_status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
  priority=$(grep "^优先级:" "$task_file" | sed 's/^优先级: *//')
  effort=$(grep "^预估工作量:" "$task_file" | sed 's/^预估工作量: *//')
  parallel=$(grep "^并行:" "$task_file" | sed 's/^并行: *//')
  
  echo "📋 任务详细状态：$task_name"
  echo "🆔 任务ID：$ARGUMENTS"
  echo "📊 状态：$task_status"
  echo "🎯 优先级：$priority"
  echo "⏰ 预估工作量：$effort"
  echo "🔄 并行：$parallel"
fi
```

### 2. 所有任务状态概览

```bash
if [ -z "$ARGUMENTS" ]; then
  echo "📊 所有任务状态概览"
  echo ""
  
  # 统计各状态任务数量
  total_tasks=0
  pending_count=0
  in_progress_count=0
  completed_count=0
  blocked_count=0
  
  for epic_dir in .claude/epics/*/; do
    if [ -d "$epic_dir" ]; then
      for task_file in "$epic_dir"*.md; do
        if [[ "$task_file" != *"epic.md" ]] && [ -f "$task_file" ]; then
          ((total_tasks++))
          
          status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
          case "$status" in
            "待开始") ((pending_count++)) ;;
            "进行中") ((in_progress_count++)) ;;
            "已完成") ((completed_count++)) ;;
            "阻塞") ((blocked_count++)) ;;
          esac
        fi
      done
    fi
  done
  
  echo "📈 任务统计："
  echo "  总任务数：$total_tasks"
  echo "  待开始：$pending_count"
  echo "  进行中：$in_progress_count" 
  echo "  已完成：$completed_count"
  echo "  阻塞：$blocked_count"
fi
```

## 输出格式

### 单个任务详细信息
```markdown
📋 任务详细状态：{任务名称}

## 基本信息
- 🆔 任务ID：{任务ID}
- 📊 状态：{当前状态}
- 🎯 优先级：{高/中/低}
- ⏰ 预估工作量：{小时数}小时
- 🔄 并行执行：{是/否}
- 📅 创建时间：{创建时间}
- 🔄 最后更新：{更新时间}

## 任务目标
{任务目标描述}

## 验收标准
- [ ] 标准1：{具体标准}
- [x] 标准2：{具体标准} ✅
- [ ] 标准3：{具体标准}

## 依赖关系
- 依赖任务：{依赖的任务ID列表}
- 冲突任务：{冲突的任务ID列表}
- 被依赖：{依赖此任务的其他任务}

## 执行进度
{如果任务进行中，显示进度信息}

## 相关文件
- 任务文件：{任务文件路径}
- 相关Epic：{所属Epic}
```

### 所有任务概览
```markdown
📊 任务状态概览

## 📈 统计信息
- 📁 总任务数：{总数}
- ⏳ 待开始：{数量} ({百分比}%)
- 🔄 进行中：{数量} ({百分比}%)  
- ✅ 已完成：{数量} ({百分比}%)
- 🚫 阻塞：{数量} ({百分比}%)

## 🔄 进行中任务
{列出所有进行中的任务}

## ⏳ 下一步可开始任务
{列出依赖已满足、可以开始的任务}

## 🚫 阻塞任务
{列出被阻塞的任务及阻塞原因}

## 🎯 建议行动
- {基于当前状态的建议}
```