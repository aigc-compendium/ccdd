---
allowed-tools: Task, Write, Read
---

# DD 任务分解

深度分析功能技术实现路径, 按合理性进行任务规划和分解.

## 功能概述

智能分解功能为具体任务:

- 基于技术实现路径分析
- 按依赖关系排序任务
- 生成详细任务文档
- 评估工作量和复杂度

## 分解原则

### 文档生成规范

#### 中英文间距要求

所有生成的文档内容必须遵循以下格式规范：

- **中英文混合文本**：英文单词与中文字符之间必须有一个空格
- **示例**：`这是一个 API 接口设计` 而不是 `这是一个API接口设计`
- **适用范围**：所有任务描述、技术细节、验收标准等文档
- **特殊情况**：标点符号前后不需要额外空格

### 1. 任务独立性

- 每个任务可以独立开发和测试
- 明确的输入和输出定义
- 清晰的验收标准

### 2. 合理的任务粒度

- 单个任务 1-3 天工作量
- 避免过度拆分或合并
- 便于进度跟踪和管理

### 3. 依赖关系清晰

- 识别任务间的前后依赖
- 避免循环依赖
- 支持并行开发的任务

## 执行流程

### 1. 多维度信息收集

通过脚本收集分解所需的全部信息:

- **功能信息** - 调用 `task-add-feature.sh <feature_name>`
- **技术方案** - 调用 `task-add-technical.sh <feature_name>`
- **项目上下文** - 调用 `task-add-context.sh <feature_name>`

### 2. 智能体深度分析

基于收集的信息进行深度分析:

- **技术路径分析** - 分析最佳实现路径和关键技术点
- **复杂度评估** - 评估功能复杂度和潜在风险
- **依赖关系梳理** - 识别任务间和功能间的依赖关系
- **任务规划策略** - 制定合理的任务分解和执行计划

### 3. 智能任务分解

生成优化的任务列表:

- 基于技术复杂度建议任务数量（简单:3-5 个, 中等:5-8 个, 复杂:8-12 个）
- 按实现顺序合理性排列任务
- 确定任务间的依赖关系
- 估算各任务工作量

### 4. 智能任务文档生成

基于深度分析结果, 为每个分解的任务调用生成脚本:

```bash
bash .claude/scripts/dd/task-add-detail.sh "<feature_name>" "<task_id>" '<task_data_json>'
```

**参数说明**:

- `<feature_name>`: 功能名称
- `<task_id>`: 任务 ID（如: 001, 002, 003）
- `<task_data_json>`: 任务数据的 JSON 格式

**JSON 数据结构**:

```json
{
  "name": "任务名称",
  "priority": "高|中|低",
  "difficulty": "简单|中等|复杂",
  "estimated_hours": "预估工时",
  "goal": "任务目标描述",
  "implementation_points": "关键实现要点",
  "technical_details": "技术细节说明",
  "dependencies": ["依赖任务1", "依赖任务2"],
  "todos": ["具体实现项1", "具体实现项2", "具体实现项3"],
  "acceptance_criteria": ["验收条件1", "验收条件2"]
}
```

### 5. 完成处理

调用 `task-decompose-finish.sh <feature_name>` 进行验证和总结

## 输出结果

在功能目录下创建 `tasks/` 文件夹:

```
.claude/features/{功能名}/tasks/
├── 001.md  # 第一个任务
├── 002.md  # 第二个任务
└── ...
```

每个任务文件包含:

- YAML 元数据（状态、优先级、工时等）
- 任务描述和目标
- 实现要点和技术细节
- 验收标准
- Todo 列表

## 脚本调用序列

命令执行时按顺序调用以下脚本:

```bash
# 1. 收集功能信息
bash .claude/scripts/dd/task-add-feature.sh "<feature_name>"

# 2. 收集技术方案信息
bash .claude/scripts/dd/task-add-technical.sh "<feature_name>"

# 3. 收集项目上下文信息
bash .claude/scripts/dd/task-add-context.sh "<feature_name>"

# 4. 生成任务文档（智能体分解后为每个任务调用）
bash .claude/scripts/dd/task-add-detail.sh "<feature_name>" "001" '<task1_json>'
bash .claude/scripts/dd/task-add-detail.sh "<feature_name>" "002" '<task2_json>'
bash .claude/scripts/dd/task-add-detail.sh "<feature_name>" "003" '<task3_json>'
# ... 为每个任务调用一次

# 5. 完成验证和总结
bash .claude/scripts/dd/task-decompose-finish.sh "<feature_name>"
```

## 完成后提示

```bash
🎯 功能任务分解完成！
📋 功能: {功能名}
📊 已生成 {X} 个任务
⏱️ 预估总工时: {Y} 小时

📝 建议下一步操作:
   /dd:feature-start {功能名}  - 开始功能开发

💡 或查看任务详情:
   查看 .claude/features/{功能名}/tasks/ 目录
```

## 质量标准

- **独立性** - 任务可独立完成和验证
- **完整性** - 覆盖功能所有技术要求
- **合理性** - 任务大小和复杂度适中
- **可测试性** - 明确的验收和测试标准
