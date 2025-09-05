# 规则执行检查

用于验证和强制执行绝对规则的检查机制和方法。

## 检查时机

### 每次操作前检查
- **Bash 命令执行前** - 验证是否包含禁止的 git 操作
- **文件写操作前** - 确认文件路径在允许范围内
- **敏感信息处理时** - 自动检测和保护敏感数据
- **智能体调用前** - 验证操作范围和权限

### 定期完整性检查
- **会话开始时** - 验证系统配置完整性
- **上下文更新时** - 检查时间戳和元数据格式
- **文档生成时** - 验证内容符合质量标准

## 检查方法

### Git 操作安全检查
```bash
# 检查命令是否包含禁止的 git 操作
check_git_command_safety() {
    local command="$1"
    
    # 禁止的 git 写操作列表
    local forbidden_git_ops=(
        "git add"
        "git commit" 
        "git push"
        "git pull"
        "git merge"
        "git rebase"
        "git reset --hard"
        "git checkout -b"
        "git branch -d"
        "gh issue create"
        "gh pr create"
    )
    
    for op in "${forbidden_git_ops[@]}"; do
        if [[ "$command" == *"$op"* ]]; then
            echo "❌ 违反绝对规则：禁止执行 '$op'"
            echo "💡 允许的操作：git status, git diff, git log (只读)"
            return 1
        fi
    done
    
    return 0
}
```

### 文件操作边界检查
```bash
# 检查文件路径是否在允许的范围内
check_file_write_permission() {
    local file_path="$1"
    
    # 允许写入的路径模式
    if [[ "$file_path" == *".claude/"* ]]; then
        return 0
    fi
    
    # 特殊允许的文件（如果有）
    local allowed_files=(
        # 暂时没有特殊允许的文件
    )
    
    for allowed in "${allowed_files[@]}"; do
        if [[ "$file_path" == "$allowed" ]]; then
            return 0
        fi
    done
    
    echo "❌ 违反绝对规则：禁止修改 .claude/ 目录外的文件"
    echo "📁 允许修改：.claude/ 目录下的文件"
    echo "🚫 禁止修改：$file_path"
    return 1
}
```

### 敏感信息检测
```bash
# 检测文本中的敏感信息
detect_sensitive_info() {
    local text="$1"
    local warnings=()
    
    # 密钥模式
    if echo "$text" | grep -qiE "(api_?key|secret|password|token|credential)" && \
       echo "$text" | grep -qE "[:=]\s*['\"][a-zA-Z0-9+/]{10,}"; then
        warnings+=("检测到可能的API密钥或令牌")
    fi
    
    # 密码模式  
    if echo "$text" | grep -qiE "password\s*[:=]\s*['\"][^'\"]{3,}"; then
        warnings+=("检测到可能的密码")
    fi
    
    # URL中的凭据
    if echo "$text" | grep -qE "https?://[^@\s]+:[^@\s]+@"; then
        warnings+=("检测到URL中的凭据信息")
    fi
    
    if [ ${#warnings[@]} -gt 0 ]; then
        echo "⚠️ 敏感信息警告："
        for warning in "${warnings[@]}"; do
            echo "  - $warning"
        done
        echo "🔒 请确认是否需要移除或脱敏处理"
        return 1
    fi
    
    return 0
}
```

### 时间戳格式验证
```bash
# 验证时间戳格式是否符合 ISO 8601 标准
validate_timestamp_format() {
    local timestamp="$1"
    
    if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
        return 0
    else
        echo "❌ 违反绝对规则：时间戳格式错误"
        echo "📅 正确格式：2024-01-01T12:00:00Z"
        echo "🚫 错误格式：$timestamp"
        return 1
    fi
}
```

### 前置元数据完整性检查
```bash
# 检查文件前置元数据的完整性
check_frontmatter_completeness() {
    local file="$1"
    local required_fields=("创建时间" "最后更新")
    local warnings=()
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "^${field}:" "$file"; then
            warnings+=("缺少必需字段：$field")
        fi
    done
    
    # 检查时间格式
    local created_time=$(grep "^创建时间:" "$file" | sed 's/^创建时间: *//')
    local updated_time=$(grep "^最后更新:" "$file" | sed 's/^最后更新: *//')
    
    if [ -n "$created_time" ]; then
        validate_timestamp_format "$created_time" || warnings+=("创建时间格式错误")
    fi
    
    if [ -n "$updated_time" ]; then
        validate_timestamp_format "$updated_time" || warnings+=("最后更新时间格式错误")
    fi
    
    if [ ${#warnings[@]} -gt 0 ]; then
        echo "⚠️ 前置元数据问题：$file"
        for warning in "${warnings[@]}"; do
            echo "  - $warning"
        done
        return 1
    fi
    
    return 0
}
```

## 自动修复

### 时间戳自动修复
```bash
# 自动修复错误的时间戳格式
auto_fix_timestamps() {
    local file="$1"
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local fixed=false
    
    # 修复占位符时间
    if grep -q "创建时间: TBD\|创建时间: 待定\|创建时间: TODO" "$file"; then
        sed -i.bak "s/^创建时间:.*/创建时间: $current_time/" "$file"
        echo "✅ 已修复创建时间占位符"
        fixed=true
    fi
    
    # 修复缺失的最后更新字段
    if ! grep -q "^最后更新:" "$file"; then
        sed -i.bak "/^创建时间:/a\\
最后更新: $current_time" "$file"
        echo "✅ 已添加最后更新字段"
        fixed=true
    fi
    
    if [ "$fixed" = true ]; then
        rm "${file}.bak"
        echo "📄 文件已修复：$file"
    fi
    
    return 0
}
```

### 前置元数据自动补全
```bash
# 为缺失前置元数据的文件自动添加
auto_add_frontmatter() {
    local file="$1"
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if ! head -n 1 "$file" | grep -q "^---$"; then
        # 文件没有前置元数据，添加它
        local temp_file="${file}.tmp"
        
        cat > "$temp_file" << EOF
---
创建时间: $current_time
最后更新: $current_time
版本: 1.0
作者: DD 工作流系统
---

EOF
        cat "$file" >> "$temp_file"
        mv "$temp_file" "$file"
        
        echo "✅ 已为文件添加前置元数据：$file"
    fi
}
```

## 完整性扫描

### 系统完整性检查
```bash
# 扫描整个 DD 系统的完整性
scan_system_integrity() {
    local errors=0
    
    echo "🔍 开始 DD 系统完整性扫描..."
    
    # 检查必需的目录结构
    local required_dirs=(
        ".claude"
        ".claude/commands"
        ".claude/commands/dd"
        ".claude/agents"
        ".claude/rules"
        ".claude/context"
        ".claude/prds"
        ".claude/epics"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            echo "❌ 缺少必需目录：$dir"
            ((errors++))
        fi
    done
    
    # 检查核心文件
    local required_files=(
        ".claude/CLAUDE.md"
        ".claude/rules/absolute-rules.md"
        ".claude/rules/git-safety.md"
        ".claude/commands/dd/help.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "❌ 缺少核心文件：$file"
            ((errors++))
        fi
    done
    
    # 检查所有 .md 文件的前置元数据
    while IFS= read -r -d '' file; do
        check_frontmatter_completeness "$file" || ((errors++))
    done < <(find .claude -name "*.md" -print0)
    
    if [ $errors -eq 0 ]; then
        echo "✅ 系统完整性检查通过"
    else
        echo "❌ 发现 $errors 个问题"
    fi
    
    return $errors
}
```

## 使用指南

### 集成到命令中
在每个命令的开头添加相关检查：
```markdown
## 预检清单
1. **安全检查** - 验证操作不违反绝对规则
2. **权限检查** - 确认文件操作权限
3. **格式检查** - 验证输入参数格式
```

### 错误处理流程
1. **检测违规** - 使用上述检查函数
2. **立即停止** - 第一级规则违规时停止操作
3. **用户通知** - 清楚说明违规原因和解决方案
4. **自动修复** - 可能时提供自动修复选项

### 定期维护
```bash
# 建议的维护命令
/dd:system-check    # 运行完整性扫描
/dd:rule-verify     # 验证规则执行
/dd:auto-fix        # 自动修复常见问题
```

## 扩展机制

### 自定义检查
用户可以添加项目特定的检查：
```bash
# 在 .claude/rules/custom-checks.sh 中定义
check_project_specific_rules() {
    # 项目特定的检查逻辑
    return 0
}
```

### 规则更新
当绝对规则文件更新时：
1. 重新生成检查函数
2. 更新相关命令的检查逻辑
3. 通知所有智能体规则变更

这套机制确保绝对规则得到严格执行，同时提供必要的灵活性和可维护性。