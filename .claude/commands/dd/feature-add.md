---
allowed-tools: Task, Read, Write, Bash
---

# DD 功能添加

通过深度对话分析功能需求, 生成完整功能文档结构.

## 执行流程

### 文档生成规范

#### 中英文间距要求

所有生成的文档内容必须遵循以下格式规范：

- **中英文混合文本**：英文单词与中文字符之间必须有一个空格
- **示例**：`这是一个 JWT 认证系统` 而不是 `这是一个JWT认证系统`
- **适用范围**：所有功能描述、技术方案、测试用例等文档
- **特殊情况**：标点符号前后不需要额外空格

### 1. 深度需求对话

与用户进行深入讨论, 明确:

- **功能目标**: 具体要实现什么
- **用户价值**: 为用户解决什么问题
- **核心功能点**: 主要功能模块
- **技术选型**: 使用的技术栈
- **复杂度评估**: 实现难度和工时
- **依赖关系**: 与其他功能的依赖

### 2. AI 质疑和优化

基于深度思考, 主动质疑:

- 功能是否真正必要
- 实现方案是否合理
- 是否有更简单的替代方案
- 功能边界是否清晰

### 3. 确认功能规格

讨论确认后, 整理出:

- 功能名称和目标描述
- 用户价值和使用场景
- 核心功能点列表
- 技术实现方案
- 测试策略和用例

### 4. 分步生成文档

基于深度对话结果, 依次调用参数化脚本生成各部分文档:

#### 4.1 生成功能描述文档

基于对话中获得的功能需求信息, 构建 JSON 数据并调用脚本:

```bash
feature_data=$(cat << 'EOF'
{
  "goal": "从对话中提取的功能目标描述",
  "user_value": "从对话中明确的用户价值",
  "core_features": "核心功能点描述",
  "feature_boundary_include": "包含的功能范围",
  "feature_boundary_exclude": "明确排除的功能范围",
  "use_scenarios": "具体使用场景描述",
  "acceptance_criteria": "详细的验收标准",
  "complexity": "简单|中等|复杂",
  "estimated_hours": "预估工时数字",
  "dependencies": "技术或功能依赖描述"
}
EOF
)

bash .claude/scripts/dd/feature-add-feature.sh "<功能名>" "$feature_data"
```

#### 4.2 生成技术方案文档

基于对话中的技术选型和架构讨论, 构建 JSON 数据并调用脚本:

```bash
technical_data=$(cat << 'EOF'
{
  "architecture_design": "从对话中确定的系统架构设计",
  "data_models": "数据模型和实体关系设计",
  "api_design": "API接口设计和规范",
  "database_design": "数据库设计方案",
  "security_considerations": "安全策略和考虑",
  "performance_requirements": "性能要求和优化策略",
  "tech_stack": "选择的技术栈组合",
  "external_integrations": "外部系统集成方案",
  "deployment_strategy": "部署和运维策略"
}
EOF
)

bash .claude/scripts/dd/feature-add-technical.sh "<功能名>" "$technical_data"
```

#### 4.3 生成测试用例文档

基于对话中的测试策略讨论, 构建 JSON 数据并调用脚本:

```bash
testing_data=$(cat << 'EOF'
{
  "test_strategy": "从对话中确定的测试策略",
  "unit_tests": "单元测试用例设计",
  "integration_tests": "集成测试用例设计",
  "e2e_tests": "端到端测试用例设计",
  "performance_tests": "性能测试计划",
  "security_tests": "安全测试用例",
  "test_data": "测试数据准备策略",
  "test_environment": "测试环境配置要求",
  "coverage_requirements": "代码覆盖率目标"
}
EOF
)

bash .claude/scripts/dd/feature-add-testing.sh "<功能名>" "$testing_data"
```

#### 4.4 完成功能创建

记录完整的功能设计对话历史:

```bash
conversation_data=$(cat << 'EOF'
{
  "feature_name": "功能名称",
  "conversation": "完整的功能设计对话历史, 包括: \n\n用户: 我需要添加一个XX功能\n---\n助手: 我来帮您分析这个功能的需求...\n---\n用户: 这个功能主要用于...\n---\n\n[记录所有实际对话内容, 每轮用---分割, 不是总结]",
  "design_decisions": "设计决策要点",
  "technical_choices": "技术选择理由"
}
EOF
)

bash .claude/scripts/dd/feature-add-finish.sh "<功能名>" "$conversation_data"
```

执行最终完成操作、验证文档生成结果并记录对话历史, 提供下一步操作建议

**重要**: 必须传递包含对话内容的 JSON 数据作为第二个参数:

```json
{
  "conversation": "完整的用户与AI对话内容, 每轮对话用---分割, 包含需求分析、技术讨论、方案确认等过程"
}
```

## 使用方式

```bash
/dd:feature-add <功能名称>
```

## 深度对话示例

**AI**: 您想添加什么功能？请描述一下核心需求.

**用户**: 我想添加一个用户认证系统.

**AI**: 让我深入了解一下这个功能:

1. **功能目标**: 您希望这个认证系统实现哪些具体功能？是否包括注册、登录、密码重置等？

2. **用户价值**: 这个系统主要为哪类用户服务？解决什么核心问题？

3. **技术考虑**: 基于您的项目架构, 倾向于使用什么认证方案？JWT、Session 还是 OAuth？

4. **质疑**: 是否考虑过使用第三方认证服务（如 Auth0）来简化实现？

_(继续深度对话, 直到明确所有细节)_

## AI 执行的关键原则

**参数说明**:

- `--goal`: 功能目标的具体描述
- `--value`: 为用户提供的价值描述
- `--features`: 核心功能点（用|分隔）
- `--scenarios`: 用户使用场景（用|分隔）
- `--criteria`: 验收标准（用|分隔）
- `--overwrite`: 覆盖现有文件（用于 refactory 场景）
- 其他参数可选, 有默认值

### 参数化脚本的正确使用

**重要: 必须传递完整的对话内容作为参数！**

1. **不要省略参数**: 每个重要信息都必须通过对应参数传递
2. **使用实际内容**: 不要使用占位符, 使用从对话中获得的实际内容
3. **遵循参数格式**: 多个项目用`|`分隔, 技术栈用`,`分隔
4. **保证内容完整性**: 所有从用户对话中获得的信息都必须体现在最终生成的文档中

### 执行示例

假设用户要求创建"用户认证系统", 经过对话得到以下信息:

- 功能目标: 实现安全的用户登录认证
- 用户价值: 为用户提供安全便捷的身份验证服务
- 核心功能: 用户注册、用户登录、密码重置、邮箱验证
- 技术栈: Node.js、React、JWT、MongoDB

则 AI 必须这样调用:

```bash
# 第一步: 生成功能文档
bash .claude/scripts/dd/feature-add-feature.sh "用户认证系统" \
  --goal "实现安全的用户登录认证" \
  --value "为用户提供安全便捷的身份验证服务" \
  --features "用户注册功能|用户登录功能|密码重置功能|邮箱验证功能" \
  --scenarios "新用户注册|老用户登录|忘记密码重置" \
  --complexity "中等" \
  --hours "40"

# 第二步: 生成技术文档
bash .claude/scripts/dd/feature-add-technical.sh "用户认证系统" \
  --tech-stack "Node.js,React,JWT,MongoDB" \
  --complexity "中等" \
  --hours "40" \
  --arch "前后端分离架构, JWT令牌认证" \
  --data "User表存储用户信息, 包含邮箱、密码哈希等字段" \
  --api "RESTful API设计, 包含注册、登录、重置密码接口" \
  --security "密码哈希存储, JWT令牌验证, 邮箱验证机制"

# 第三步: 生成测试文档
bash .claude/scripts/dd/feature-add-testing.sh "用户认证系统" \
  --strategy "分层测试, 从单元测试到端到端测试" \
  --unit "密码哈希函数测试|JWT令牌生成验证测试" \
  --integration "注册API集成测试|登录API集成测试" \
  --e2e "完整注册流程测试|完整登录流程测试" \
  --coverage "90"

# 第四步: 完成创建
bash .claude/scripts/dd/feature-add-finish.sh "用户认证系统" '{
  "conversation": "用户: 我想添加一个用户认证系统. \nAI: 让我深入了解一下这个功能的需求...\n[完整的对话过程记录]"
}'
```

## 输出规范

确认所有细节后, 会按顺序生成:

1. **feature.md** - 完整的功能需求文档（包含对话中的所有功能信息）
2. **technical.md** - 详细的技术实现方案（包含对话中的技术方案）
3. **testing.md** - 全面的测试用例集（包含对话中的测试策略）
4. **完成提示** - 下一步操作建议

## 质疑维度

- **必要性**: 是否真正解决核心痛点
- **复杂度**: 实现复杂度是否合理
- **替代方案**: 是否有更简单的解决方案
- **技术选型**: 技术方案是否适合项目
- **维护成本**: 长期维护复杂度考虑
- **扩展性**: 未来功能扩展的可能性
