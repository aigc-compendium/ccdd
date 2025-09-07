---
allowed-tools: Bash, Read, Write, LS, Task
---

# 开始执行任务

开始执行指定的任务，建立任务执行上下文并进入任务开发闭环。

## 用法
```
/dd:task-start <任务ID>
```

## 快速检查

1. **查找任务文件：**
   ```bash
   # 解析任务ID格式：prd_name:task_num
   if [[ "$ARGUMENTS" != *:* ]]; then
     echo "❌ 任务ID格式错误，应为：<PRD名称>:<任务编号>"
     echo "示例：用户认证系统:001"
     exit 1
   fi
   
   prd_name="${ARGUMENTS%%:*}"
   task_num="${ARGUMENTS##*:}"
   task_file=".claude/epics/$prd_name/$task_num.md"
   
   if [ ! -f "$task_file" ]; then
     echo "❌ 任务不存在：$task_file"
     echo "💡 运行 /dd:task-list 查看所有任务"
     exit 1
   fi
   ```

2. **检查任务状态：**
   ```bash
   status=$(grep "^状态:" "$task_file" | sed 's/^状态: *//')
   if [ "$status" = "已完成" ]; then
     echo "✅ 任务已完成：$ARGUMENTS"
     echo "💡 运行 /dd:task-list 查看其他任务"
     exit 0
   fi
   ```

3. **验证依赖关系：**
   ```bash
   dependencies=$(grep "^依赖:" "$task_file" | sed 's/^依赖: *\[//; s/\]//')
   if [ -n "$dependencies" ]; then
     for dep in ${dependencies//,/ }; do
       dep_file=$(find .claude/epics -name "$dep.md" | head -1)
       dep_status=$(grep "^状态:" "$dep_file" | sed 's/^状态: *//')
       if [ "$dep_status" != "已完成" ]; then
         echo "❌ 依赖任务 $dep 未完成（状态：$dep_status）"
         exit 1
       fi
     done
   fi
   ```

## 执行步骤

### 1. 建立任务上下文

提取任务信息：
```bash
task_name=$(grep "^名称:" "$task_file" | sed 's/^名称: *//')
epic_name=$(basename $(dirname "$task_file"))
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

创建当前任务上下文文件：
```bash
cat > .claude/context/current-task.md << EOF
---
任务ID: $ARGUMENTS
任务名称: $task_name
Epic: $epic_name
开始时间: $current_time
状态: 进行中
上次更新: $current_time
---

# 当前任务：$task_name

## 任务目标
$(sed -n '/^## 目标/,/^## /p' "$task_file" | head -n -1 | tail -n +2)

## 执行计划
[将在执行过程中更新]

## 完成进度
- [ ] 任务分析完成
- [ ] 实施方案确定
- [ ] 代码实现完成
- [ ] 自我验证通过

## 遇到的问题
[记录执行过程中的问题]

## 解决方案
[记录问题的解决方案]
EOF
```

### 2. 导入进度更新函数
```bash
# 导入task-progress的底层函数
source .claude/commands/dd/task-progress.md
```

### 3. 任务分析阶段

使用智能体进行深度分析：
```yaml
Task:
  description: "分析任务执行计划"
  subagent_type: "code-analyzer"
  prompt: |
    分析任务：$task_name（ID: $ARGUMENTS）
    
    任务文件内容：
    $(cat "$task_file")
    
    请提供：
    1. 详细的实施步骤分解
    2. 需要分析的文件清单
    3. 可能的风险点和注意事项
    4. 与其他任务/组件的集成考虑
    5. 验收标准的具体检查方法
    
    重要：严格遵循绝对安全规则
    - 禁止任何git操作
    - 只能在.claude/目录内修改文件
    - 只提供分析和建议，不直接修改代码
    
    分析完成后调用: epic_todo_update("$ARGUMENTS", "任务分析完成")
    
    确保分析全面且实用，为实际开发提供明确指导。
```

### 4. 自动更新进度
```bash
# 任务分析完成后自动更新Epic进度
epic_todo_update "$ARGUMENTS" "任务分析和上下文建立完成"
```

### 3. 更新任务状态

更新任务文件：
```bash
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sed -i.bak "s/^状态:.*/状态: 进行中/" "$task_file"
sed -i.bak "s/^最后更新:.*/最后更新: $current_time/" "$task_file"
rm "${task_file}.bak"
```

## 输出格式

```markdown
🚀 开始执行任务：$task_name

📋 任务信息：
  - 任务ID：$ARGUMENTS
  - Epic：$epic_name
  - 开始时间：$current_time

📊 依赖状态：
  ✅ 所有依赖任务已完成

🎯 执行计划：
  1. 任务分析和方案制定
  2. 分步骤实施（用户执行）
  3. 验证和测试（用户执行）
  4. 完成和反思

📁 工作空间：
  - 任务上下文：.claude/context/current-task.md
  - 任务文件：$task_file

💡 重要提醒：
  - AI严格遵循绝对安全规则
  - 只提供分析和实施建议
  - 所有代码修改由用户执行
  - 禁止git操作和远程仓库访问

🎯 下一步操作：
  - 继续任务: /dd:task-resume $ARGUMENTS
  - 暂停任务: /dd:task-pause $ARGUMENTS  
  - 完成任务: /dd:task-finish $ARGUMENTS
```

## 错误处理

### 任务不存在
```
❌ 任务不存在：$ARGUMENTS

建议操作：
- 运行 /dd:task-list 查看所有任务
- 运行 /dd:epic-list 查看所有Epic
- 确认任务ID格式正确
```

### 依赖未满足
```
⚠️ 依赖条件未满足

依赖任务状态：
{动态显示具体的依赖任务和状态}

建议操作：
1. 先完成依赖任务
2. 确认任务可以并行执行
```

## 安全约束

严格遵循DD系统绝对规则：
1. **禁止git操作** - 不执行任何git命令
2. **禁止远程操作** - 不访问GitHub等远程仓库
3. **文件操作限制** - 只能在.claude/目录内修改文件
4. **用户控制原则** - AI只提供分析建议，用户保持完全控制权