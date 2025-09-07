---
allowed-tools: Task, Read, Write, Edit, Bash
---

# DD 项目初始化

为新项目初始化 CCDD Helper 系统, 建立项目上下文和开发环境.

## 功能概述

基于深度思考模式与开发者讨论确定:

- 项目类型和技术选型
- 项目目标和需求范围
- 开发团队和时间规划
- 质量标准和交付要求

## 执行流程

### 1. 项目基础信息收集

使用 Task 工具调用 deep-thinker 智能体分析:

```
项目名称、类型、规模
目标用户和核心需求
技术选型倾向
团队规模和技术栈经验
```

### 2. 深度讨论和确认

AI 主动提出质疑:

- 项目可行性分析
- 技术选型合理性
- 需求范围是否明确
- 时间和资源评估

### 3. 初始化项目上下文

生成核心配置文件:

- `.claude/context/project.md`
- `.claude/context/architecture.md`
- `.claude/context/tech-stack.md`
- `.claude/context/current-status.md`

### 4. 执行 after-init.sh

执行后处理脚本, 传递完整的对话数据:

```bash
# 构建包含对话历史的 JSON 数据
conversation_data=$(cat << 'EOF'
{
  "project_name": "用户确认的项目名称",
  "project_type": "确定的项目类型",
  "tech_stack": "选择的技术栈",
  "architecture": "确定的架构模式",
  "conversation": "完整的真实对话历史, 逐句记录: \n\n用户: 我想创建一个新的Web应用项目\n助手: 我来帮您创建这个项目. 首先让我了解一些基本信息...\n用户: 这是一个电商平台\n助手: 电商平台需要考虑很多方面. 关于技术选型...\n\n[记录所有实际对话内容, 不是总结]"
}
EOF
)

bash .claude/scripts/dd/after-init.sh "$conversation_data"
```

**重要**: 必须记录完整的真实对话历史:

- 不是总结, 是逐句的实际对话内容
- 包括用户的每一次提问和回应
- 包括 AI 的每一次分析和建议
- 包括所有的讨论和决策过程
- 保持对话的原始格式和语言风格

### 5. 智能合并 CLAUDE.md 配置

**必须执行**: 调用 claude-md-merger 智能体, 让 AI 自动将 `.claude/CLAUDE.md` 合并到根目录的 `CLAUDE.md`.

## 完成后提示

```
✅ 新项目初始化完成！
📝 已生成文件:
   • .claude/chats/init/comm-{timestamp}.md - 对话记录
   • .claude/context/project.md - 项目基础信息
   • .claude/context/tech-stack.md - 技术栈信息
   • .claude/context/architecture.md - 架构设计
   • CLAUDE.md - 智能合并的配置文件

📝 建议下一步操作:
   /dd:chat        - 基于项目上下文的深度咨询
   /dd:feature-add - 添加第一个核心功能
   /dd:status      - 查看项目整体状态
```

## 文档生成规范

### 中英文间距要求

所有生成的文档内容必须遵循以下格式规范：

- **中英文混合文本**：英文单词与中文字符之间必须有一个空格
- **示例**：`这是一个 Web 应用项目` 而不是 `这是一个Web应用项目`
- **适用范围**：所有项目信息、技术选型、架构设计等文档
- **特殊情况**：标点符号前后不需要额外空格

## 深度思考要点

- **项目价值评估** - 解决什么核心问题
- **技术选型合理性** - 是否适合团队和需求
- **范围边界清晰度** - 避免需求蔓延
- **风险识别** - 技术风险、时间风险、团队风险
