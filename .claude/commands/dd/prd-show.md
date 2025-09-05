---
allowed-tools: Read, LS
---

# PRD详情查看

显示指定产品需求文档的详细内容和状态信息。

## 用法
```
/dd:prd-show <功能名称>
```

## 参数说明
- `<功能名称>` - PRD的功能标识名称

## 操作指南

### 1. 查找PRD文件
```bash
# 在PRD目录中查找指定名称的文件
prd_file=$(find .claude/prds -name "${ARGUMENTS}.md" | head -1)

if [ ! -f "$prd_file" ]; then
  echo "❌ PRD不存在：$ARGUMENTS"
  echo "💡 运行 /dd:prd-list 查看所有可用PRD"
  exit 1
fi
```

### 2. 提取PRD信息
```bash
# 提取前置元数据
prd_name=$(grep "^名称:" "$prd_file" | sed 's/^名称: *//')
prd_status=$(grep "^状态:" "$prd_file" | sed 's/^状态: *//')
prd_created=$(grep "^创建时间:" "$prd_file" | sed 's/^创建时间: *//')
prd_updated=$(grep "^最后更新:" "$prd_file" | sed 's/^最后更新: *//')
prd_description=$(grep "^描述:" "$prd_file" | sed 's/^描述: *//')
```

### 3. 状态分析
```bash
# 根据状态显示不同的状态图标和说明
case "$prd_status" in
  "backlog") status_display="📋 待处理" ;;
  "评估中") status_display="🔍 评估中" ;;
  "已批准") status_display="✅ 已批准" ;;
  "已实施") status_display="🚀 已实施" ;;
  *) status_display="❓ $prd_status" ;;
esac
```

### 4. 相关文件检查
```bash
# 检查是否已生成对应的Epic
epic_exists=false
if [ -f ".claude/epics/${ARGUMENTS}/epic.md" ]; then
  epic_exists=true
fi

# 检查实施进度
implementation_progress=""
if [ "$epic_exists" = true ]; then
  task_count=$(find ".claude/epics/${ARGUMENTS}" -name "*.md" ! -name "epic.md" | wc -l)
  completed_tasks=$(find ".claude/epics/${ARGUMENTS}" -name "*.md" ! -name "epic.md" -exec grep -l "状态: 已完成" {} \; | wc -l)
  
  if [ $task_count -gt 0 ]; then
    completion_rate=$((completed_tasks * 100 / task_count))
    implementation_progress="实施进度: $completed_tasks/$task_count 任务完成 ($completion_rate%)"
  fi
fi
```

## 输出格式

### PRD详细信息
```markdown
📋 PRD详情：{功能名称}

## 基本信息
- 🏷️ 名称：{PRD名称}
- 📊 状态：{状态图标} {状态}
- 📅 创建时间：{创建时间}
- 🔄 最后更新：{最后更新时间}
- 📝 描述：{功能描述}

## 实施状态
{如果存在Epic，显示实施进度}
- 📁 技术方案：{已生成/未生成}
- 📊 实施进度：{完成任务数}/{总任务数} ({完成率}%)

## 文档内容
{显示PRD的主要内容章节标题}

## 相关文件
- PRD文件：{PRD文件路径}
- Epic文件：{Epic文件路径或"未生成"}

## 快捷操作
- 📝 编辑PRD：直接编辑文件 {PRD文件路径}
- 🔄 生成技术方案：/dd:prd-parse {功能名称}
- 📊 查看实施状态：/dd:epic-show {功能名称}
```

## 错误处理

### PRD不存在
```markdown
❌ PRD不存在：{功能名称}

可能原因：
1. 功能名称拼写错误
2. PRD尚未创建
3. PRD文件已移动或删除

建议操作：
- 运行 /dd:prd-list 查看所有PRD
- 确认功能名称的正确拼写
- 运行 /dd:prd-new {功能名称} 创建新PRD
```

## 使用示例

```bash
# 查看用户认证系统的PRD详情
/dd:prd-show 用户认证系统

# 查看支付系统的PRD
/dd:prd-show 支付系统
```