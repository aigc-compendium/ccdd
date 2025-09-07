# 日期时间操作规则

在 dd 工作流系统中处理日期时间的标准模式和操作。

## 时间格式标准

### ISO 8601 格式
所有时间戳必须使用 ISO 8601 UTC 格式：
```
2024-01-01T00:00:00Z
```

### 获取当前时间
```bash
# 标准命令
date -u +"%Y-%m-%dT%H:%M:%SZ"

# 示例输出
2024-03-15T14:30:25Z
```

## 前置元数据中的时间字段

### 必需字段
```yaml
---
创建时间: 2024-01-01T00:00:00Z  # 文档首次创建时间
最后更新: 2024-01-01T12:30:00Z  # 最后修改时间
---
```

### 时间字段规则
- **创建时间**：文档创建时设置，永不更改
- **最后更新**：每次实质性修改时更新
- **格式要求**：严格使用 ISO 8601 UTC 格式
- **禁止占位符**：绝不使用 "待定"、"稍后设置" 等占位符

## 操作模式

### 创建新文档时
```bash
# 获取当前时间
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 在前置元数据中使用
---
创建时间: $current_time
最后更新: $current_time
---
```

### 更新现有文档时
```bash
# 获取当前时间
update_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 只更新最后更新字段
sed -i.bak "s/^最后更新:.*/最后更新: $update_time/" 文件名.md
```

### 时间戳验证
```bash
# 验证时间格式
validate_timestamp() {
  local timestamp="$1"
  if [[ $timestamp =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    echo "✅ 时间格式正确: $timestamp"
    return 0
  else
    echo "❌ 时间格式错误: $timestamp"
    return 1
  fi
}
```

## 时区处理

### 统一使用 UTC
- **原因**：避免时区混淆，确保全球一致性
- **格式**：以 `Z` 结尾表示 UTC 时间
- **转换**：所有本地时间都转换为 UTC

### 时区转换示例
```bash
# 从本地时间转换为 UTC
date -u +"%Y-%m-%dT%H:%M:%SZ"

# 从 UTC 转换为本地时间显示（用于人类阅读）
date -d "2024-01-01T12:00:00Z" "+%Y-%m-%d %H:%M:%S %Z"
```

## 常见使用场景

### PRD 创建时间
```yaml
---
名称: 用户认证系统
创建时间: 2024-03-15T09:00:00Z
最后更新: 2024-03-15T09:00:00Z
---
```

### Epic 进度更新
```yaml
---
名称: 用户认证系统
创建时间: 2024-03-15T09:00:00Z
最后更新: 2024-03-16T14:30:00Z
进度: 25%
---
```

### 任务完成标记
```yaml
---
名称: 实现登录API
状态: 已完成
创建时间: 2024-03-15T10:00:00Z
完成时间: 2024-03-16T16:45:00Z
---
```

## 时间计算

### 计算耗时
```bash
# 计算两个时间戳之间的差异
start_time="2024-03-15T09:00:00Z"
end_time="2024-03-16T16:45:00Z"

# 转换为秒数并计算差异
start_sec=$(date -d "$start_time" +%s)
end_sec=$(date -d "$end_time" +%s)
duration=$((end_sec - start_sec))

# 转换为小时
hours=$((duration / 3600))
echo "耗时: $hours 小时"
```

### 相对时间判断
```bash
# 检查文件是否在最近7天内更新
check_recent_update() {
  local file="$1"
  local last_updated=$(grep '^最后更新:' "$file" | sed 's/^最后更新: *//')
  local seven_days_ago=$(date -u -d '7 days ago' +"%Y-%m-%dT%H:%M:%SZ")
  
  if [[ "$last_updated" > "$seven_days_ago" ]]; then
    echo "✅ 文件最近有更新"
  else
    echo "⚠️ 文件超过7天未更新"
  fi
}
```

## 错误处理

### 常见时间错误
```bash
# 检查并修复时间格式错误
fix_timestamp_format() {
  local file="$1"
  
  # 检查是否有无效的时间格式
  if grep -q "^创建时间: TBD\|^创建时间: 待定" "$file"; then
    echo "❌ 发现占位符时间，需要修复"
    current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    sed -i.bak "s/^创建时间:.*/创建时间: $current_time/" "$file"
  fi
}
```

### 时间一致性检查
```bash
# 验证最后更新时间不早于创建时间
validate_time_consistency() {
  local file="$1"
  local created=$(grep '^创建时间:' "$file" | sed 's/^创建时间: *//')
  local updated=$(grep '^最后更新:' "$file" | sed 's/^最后更新: *//')
  
  created_sec=$(date -d "$created" +%s 2>/dev/null)
  updated_sec=$(date -d "$updated" +%s 2>/dev/null)
  
  if [[ $updated_sec -lt $created_sec ]]; then
    echo "❌ 时间不一致：最后更新时间早于创建时间"
    return 1
  fi
}
```

## 最佳实践

### 命令执行时机
1. **PRD 创建时**：立即获取并设置创建时间
2. **文档更新前**：获取当前时间准备更新
3. **批量操作时**：统一获取时间戳避免时间不一致

### 时间精度
- **使用秒级精度**：足够精确，避免过度复杂
- **避免毫秒**：在大多数场景下不必要
- **保持一致性**：同一操作中使用相同时间戳

### 性能考虑
```bash
# 一次性获取时间戳，多处使用
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 避免重复调用
for file in *.md; do
  sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$file"
done
```

## 国际化支持

### 多语言时间显示
```bash
# 英文格式（用于系统内部）
date -u +"%Y-%m-%dT%H:%M:%SZ"

# 中文格式（用于用户显示）
date -d "2024-03-15T14:30:00Z" "+%Y年%m月%d日 %H:%M:%S UTC"
```

### 时间本地化
虽然内部使用 UTC，但在向用户展示时可以考虑本地时间：
```bash
# 检测用户时区
user_tz=$(date +%Z)

# 显示本地时间（仅用于展示）
display_local_time() {
  local utc_time="$1"
  date -d "$utc_time" "+%Y-%m-%d %H:%M:%S %Z"
}
```

## 安全考虑

### 时间戳不可篡改
- 创建时间一旦设置不应修改
- 通过版本控制系统保护时间戳完整性
- 定期验证时间戳的合理性

### 审计跟踪
使用时间戳建立完整的审计跟踪：
```yaml
---
创建时间: 2024-03-15T09:00:00Z
最后更新: 2024-03-16T14:30:00Z
更新历史:
  - "2024-03-15T09:00:00Z: 初始创建"
  - "2024-03-16T14:30:00Z: 更新任务状态"
---
```