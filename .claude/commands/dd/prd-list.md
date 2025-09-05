---
allowed-tools: Read, LS
---

# PRD列表管理

显示项目中所有产品需求文档的列表和状态概览。

## 用法
```
/dd:prd-list [选项]
```

## 选项参数
- `--all` - 显示所有PRD（默认）
- `--backlog` - 只显示待处理的PRD
- `--active` - 只显示评估中的PRD  
- `--approved` - 只显示已批准的PRD
- `--implemented` - 只显示已实施的PRD
- `--summary` - 显示摘要统计信息

## 操作指南

### 1. 扫描PRD目录
```bash
# 收集所有PRD信息
collect_prd_data() {
  local prds_data=()
  local total_prds=0
  
  echo "🔍 扫描所有PRD文档..."
  
  for prd_file in .claude/prds/*.md; do
    if [ -f "$prd_file" ]; then
      prd_name=$(basename "$prd_file" .md)
      
      # 提取PRD信息
      name=$(grep "^名称:" "$prd_file" | sed 's/^名称: *//')
      status=$(grep "^状态:" "$prd_file" | sed 's/^状态: *//')
      created=$(grep "^创建时间:" "$prd_file" | sed 's/^创建时间: *//')
      updated=$(grep "^最后更新:" "$prd_file" | sed 's/^最后更新: *//')
      description=$(grep "^描述:" "$prd_file" | sed 's/^描述: *//')
      
      # 检查实施状态
      epic_exists="否"
      if [ -f ".claude/epics/${prd_name}/epic.md" ]; then
        epic_exists="是"
      fi
      
      # 存储PRD数据
      prds_data+=("$prd_name|$name|$status|$created|$updated|$epic_exists|$description")
      ((total_prds++))
    fi
  done
  
  echo "📊 发现 $total_prds 个PRD文档"
  
  # 导出数据
  printf '%s\n' "${prds_data[@]}" > /tmp/dd_prds_data.txt
}
```

### 2. PRD筛选
```bash
# 根据选项筛选PRD
filter_prds() {
  local filter_option="$1"
  local prds_file="/tmp/dd_prds_data.txt"
  
  case "$filter_option" in
    "--backlog")
      grep "|backlog|" "$prds_file"
      ;;
    "--active")
      grep "|评估中|" "$prds_file"
      ;;
    "--approved")
      grep "|已批准|" "$prds_file"
      ;;
    "--implemented")
      grep "|已实施|" "$prds_file"
      ;;
    "--all"|"")
      cat "$prds_file"
      ;;
  esac
}
```

### 3. 显示格式化

#### 表格视图（默认）
```bash
display_prd_table() {
  local filtered_prds="$1"
  
  echo "📋 PRD列表"
  echo ""
  printf "%-15s %-25s %-10s %-12s %-8s %-6s\n" "功能标识" "PRD名称" "状态" "创建时间" "技术方案" "描述"
  echo "$(printf '%.0s-' {1..80})"
  
  echo "$filtered_prds" | while IFS='|' read -r prd_id name status created updated epic_exists description; do
    # 状态图标
    case "$status" in
      "backlog") status_icon="📋" ;;
      "评估中") status_icon="🔍" ;;
      "已批准") status_icon="✅" ;;
      "已实施") status_icon="🚀" ;;
      *) status_icon="❓" ;;
    esac
    
    # 技术方案状态
    case "$epic_exists" in
      "是") epic_icon="✅" ;;
      "否") epic_icon="⏳" ;;
    esac
    
    # 格式化日期
    created_date=$(echo $created | cut -d'T' -f1)
    
    # 截断长描述
    if [ ${#description} -gt 20 ]; then
      description="${description:0:17}..."
    fi
    
    printf "%-15s %-25s %-10s %-12s %-8s %-25s\n" \
      "$prd_id" "$name" "$status_icon$status" "$created_date" "$epic_icon" "$description"
  done
}
```

#### 摘要统计视图
```bash
display_prd_summary() {
  local filtered_prds="$1"
  local total_count=$(echo "$filtered_prds" | wc -l)
  
  # 按状态统计
  local backlog_count=$(echo "$filtered_prds" | grep "|backlog|" | wc -l)
  local active_count=$(echo "$filtered_prds" | grep "|评估中|" | wc -l)
  local approved_count=$(echo "$filtered_prds" | grep "|已批准|" | wc -l)
  local implemented_count=$(echo "$filtered_prds" | grep "|已实施|" | wc -l)
  
  # 实施进度统计
  local with_epic=$(echo "$filtered_prds" | grep "|是|" | wc -l)
  local without_epic=$(echo "$filtered_prds" | grep "|否|" | wc -l)
  
  echo "📊 PRD摘要统计"
  echo ""
  echo "📈 总体统计："
  echo "  📋 PRD总数: $total_count"
  echo "  ✅ 已生成技术方案: $with_epic"
  echo "  ⏳ 待生成技术方案: $without_epic"
  
  if [ $total_count -gt 0 ]; then
    local epic_rate=$((with_epic * 100 / total_count))
    echo "  📊 技术方案覆盖率: ${epic_rate}%"
  fi
  
  echo ""
  echo "📊 状态分布："
  echo "  📋 待处理: $backlog_count ($(calc_percentage $backlog_count $total_count)%)"
  echo "  🔍 评估中: $active_count ($(calc_percentage $active_count $total_count)%)"
  echo "  ✅ 已批准: $approved_count ($(calc_percentage $approved_count $total_count)%)"
  echo "  🚀 已实施: $implemented_count ($(calc_percentage $implemented_count $total_count)%)"
}

calc_percentage() {
  local part=$1
  local total=$2
  if [ $total -eq 0 ]; then
    echo "0"
  else
    echo $((part * 100 / total))
  fi
}
```

## 输出格式示例

### 默认表格视图
```
📋 PRD列表

功能标识        PRD名称                   状态        创建时间      技术方案  描述
--------------------------------------------------------------------------------
用户认证系统    用户登录注册系统          ✅已批准    2024-01-15    ✅        实现完整的用户认证...
支付系统        在线支付处理系统          🔍评估中    2024-01-16    ⏳        支持多种支付方式...
订单管理        订单生命周期管理          📋backlog   2024-01-17    ⏳        从下单到交付的完整...
```

### 摘要统计视图
```
📊 PRD摘要统计

📈 总体统计：
  📋 PRD总数: 5
  ✅ 已生成技术方案: 2
  ⏳ 待生成技术方案: 3
  📊 技术方案覆盖率: 40%

📊 状态分布：
  📋 待处理: 2 (40%)
  🔍 评估中: 1 (20%)
  ✅ 已批准: 1 (20%)
  🚀 已实施: 1 (20%)
```

## 错误处理

### 无PRD情况
```markdown
ℹ️ 当前项目没有任何PRD文档

建议操作：
1. 创建第一个PRD: /dd:prd-new <功能名>
2. 查看帮助信息: /dd:help prd-new
```

### 筛选无结果
```markdown
🔍 没有找到符合条件的PRD

筛选条件: {显示当前筛选条件}

建议操作：
- 调整筛选条件
- 运行 /dd:prd-list --all 查看所有PRD
- 检查PRD状态是否正确
```

## 快捷操作

### 批量操作提示
```bash
display_batch_operations() {
  echo ""
  echo "🚀 批量操作："
  echo "  📝 查看PRD详情: /dd:prd-show <功能名>"
  echo "  🔄 转换为技术方案: /dd:prd-parse <功能名>"
  echo "  📊 查看项目概览: /dd:status"
}
```

## 使用示例

```bash
# 查看所有PRD
/dd:prd-list

# 查看已批准的PRD
/dd:prd-list --approved

# 查看摘要统计
/dd:prd-list --summary

# 查看待处理的PRD
/dd:prd-list --backlog
```