#!/bin/bash

# 初始化后处理脚本
# 由 dd:init 和 dd:init-exist 命令调用
# 根据 JSON 入参生成对应的文件并记录头脑风暴对话

set -e

echo "🔧 执行初始化后处理..."
echo ""

# 解析 JSON 参数
init_data="$1"
if [ -z "$init_data" ] || [ "$init_data" = "null" ]; then
    echo "❌ 错误: 缺少初始化数据 JSON 参数"
    echo "用法: bash after-init.sh '<json_data>'"
    exit 1
fi

# 提取 JSON 数据中的字段
project_name=$(echo "$init_data" | jq -r '.project_name // "默认项目名称"')
project_type=$(echo "$init_data" | jq -r '.project_type // "Web应用"')
tech_stack=$(echo "$init_data" | jq -r '.tech_stack // "Node.js, React"')
architecture=$(echo "$init_data" | jq -r '.architecture // "分层架构"')
conversation=$(echo "$init_data" | jq -r '.conversation // ""')

echo "📋 项目配置信息: "
echo "  项目名称: $project_name"
echo "  项目类型: $project_type" 
echo "  技术栈: $tech_stack"
echo "  架构模式: $architecture"
echo ""

## 0. 记录头脑风暴对话历史

if [ -n "$conversation" ] && [ "$conversation" != "" ]; then
    echo "💬 记录头脑风暴对话历史..."
    
    # 确保对话目录存在
    mkdir -p .claude/chats/init
    
    # 优化: 直接使用时间戳避免文件检查
    chat_filename="init-$(date +"%Y%m%d-%H%M%S").md"
    chat_filepath=".claude/chats/init/$chat_filename"
    
    # 创建对话记录文件
    cat > "$chat_filepath" << EOF
---
type: comminicate
project_name: $project_name
participants: [user, ai]
---

# 项目初始化头脑风暴对话

## 项目信息

- **项目名称**: $project_name
- **项目类型**: $project_type
- **技术栈**: $tech_stack
- **架构模式**: $architecture

## 对话内容

$conversation

## 对话总结

通过本次头脑风暴对话, 确定了项目的基础信息和技术选型, 为后续开发奠定了基础. 

## 后续行动

基于对话结果, 系统将自动生成项目上下文文件, 并配置DD工作流系统. 
EOF
    
    echo "  ✅ 对话历史已保存至: $chat_filepath"
    echo ""
else
    echo "ℹ️  未提供对话历史, 跳过对话记录"
    echo ""
fi

## 1. 更新项目上下文文件

echo "📝 更新项目上下文文件..."

# 更新 project.md
cat > .claude/context/project.md << EOF
---
name: $project_name
version: 1.0.0
type: $project_type
status: 开发中
initialized_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
---

# 项目基础信息

## 项目描述
$project_name 是一个基于现代技术栈的 $project_type, 旨在提供优秀的用户体验和高质量的代码实现.

## 项目目标
- 构建高质量, 可维护的软件系统
- 提供优秀的用户体验
- 遵循最佳实践和安全标准
- 实现可扩展的系统架构

## 目标用户
- 主要用户群体: [根据项目类型确定]
- 使用场景: [具体的用户使用场景]

## 核心价值
- 为用户提供核心价值和解决方案
- 提高工作效率和用户满意度
- 支持业务目标的实现

## 项目范围
### 包含的功能
- 核心业务功能
- 用户管理和认证
- 数据管理和处理

### 不包含的功能
- 明确排除的功能范围

## 成功指标
- 技术指标: 性能, 可靠性, 安全性
- 业务指标: 用户满意度, 使用率
- 质量指标: 代码质量, 测试覆盖率

## 项目约束
- 时间约束: 按计划交付
- 技术约束: 使用指定技术栈
- 资源约束: 人力和预算限制
- 合规约束: 安全和隐私要求
EOF

echo "  ✅ 已更新 project.md"

# 更新 tech-stack.md
cat > .claude/context/tech-stack.md << EOF
---
last_updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
version: 1.0.0
---

# 技术栈信息

## 主要技术选择
基于项目需求选择的技术栈: $tech_stack

## 前端技术栈
### 核心框架
- **主框架**: 根据项目需求选择
- **构建工具**: 现代化构建工具
- **包管理器**: npm/yarn

### UI 和样式
- **组件库**: 主流UI组件库
- **样式方案**: CSS预处理器或CSS-in-JS
- **响应式设计**: 移动端适配方案

## 后端技术栈
### 核心技术
- **主语言和框架**: 根据技术栈选择
- **数据库**: 适合业务需求的数据库选择
- **缓存方案**: Redis或其他缓存解决方案

### API和服务
- **API设计**: RESTful或GraphQL
- **认证方案**: JWT或其他认证机制
- **文档工具**: API文档生成工具

## 基础设施
### 部署环境
- **容器化**: Docker容器化部署
- **云服务**: 云平台选择
- **CI/CD**: 自动化部署流水线

### 监控和日志
- **监控系统**: 系统性能监控
- **日志管理**: 集中化日志管理
- **错误跟踪**: 错误监控和报警

## 开发工具链
### 版本控制
- **代码仓库**: Git + GitHub/GitLab
- **分支策略**: Git Flow或GitHub Flow
- **代码评审**: Pull Request流程

### 开发环境
- **IDE/编辑器**: 推荐的开发工具
- **调试工具**: 调试和性能分析工具
- **测试框架**: 单元测试和集成测试框架

## 安全和质量
### 代码质量
- **代码规范**: ESLint、Prettier等工具
- **静态分析**: 代码质量检查工具
- **测试策略**: 测试驱动开发

### 安全措施
- **代码扫描**: 安全漏洞扫描
- **依赖管理**: 依赖安全检查
- **安全最佳实践**: 安全编码规范
EOF

echo "  ✅ 已更新 tech-stack.md"

# 更新 architecture.md
cat > .claude/context/architecture.md << EOF
---
last_updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
version: 1.0.0
architecture_pattern: $architecture
---

# 项目架构

## 整体架构
### 架构风格
采用 $architecture 架构模式, 确保系统的可维护性、可扩展性和安全性. 

### 核心原则
- 模块化设计: 清晰的模块边界和职责分离
- 低耦合高内聚: 减少模块间依赖, 提高内聚性
- 可扩展性优先: 支持系统的横向和纵向扩展
- 安全性内置: 安全考虑融入架构设计

## 系统分层
根据选择的架构模式进行合理的系统分层: 

### 表现层 (Presentation Layer)
- 用户界面组件和交互
- API端点定义和路由
- 请求验证和响应格式化
- 用户认证和会话管理

### 业务逻辑层 (Business Logic Layer)
- 核心业务规则实现
- 领域模型和实体定义
- 业务流程编排和控制
- 数据验证和业务验证

### 数据访问层 (Data Access Layer)
- 数据模型定义和映射
- 数据库访问和操作
- 数据转换和处理
- 缓存策略实现

## 关键组件
### 核心模块
- **认证授权模块**: 用户认证和权限管理
- **业务核心模块**: 主要业务逻辑实现
- **数据管理模块**: 数据存储和访问

### 支撑模块
- **配置管理模块**: 系统配置和环境管理
- **日志监控模块**: 系统监控和日志管理
- **通用工具模块**: 共享工具和实用函数

## 数据架构
### 数据模型设计
- 核心实体及其关系定义
- 数据流向和转换规则
- 数据一致性和完整性保证

### 存储策略
- 主数据库选型和设计原则
- 缓存层设计和缓存策略
- 数据备份和恢复方案

## 集成和通信
### 内部通信
- 模块间通信机制
- 事件驱动架构考虑
- 消息队列和异步处理

### 外部集成
- 第三方服务集成策略
- API设计和版本管理
- 错误处理和重试机制

## 非功能性需求
### 性能要求
- 响应时间目标
- 并发用户支持
- 数据处理能力

### 可用性和可靠性
- 系统可用性目标
- 故障恢复机制
- 容灾和备份策略

### 扩展性设计
- 水平扩展能力
- 垂直扩展能力
- 微服务化准备

## 安全架构
### 安全防护层次
- 网络安全: 防火墙和网络隔离
- 应用安全: 身份认证和访问控制
- 数据安全: 加密存储和传输
- 运维安全: 安全运维和监控

### 安全最佳实践
- 最小权限原则
- 深度防御策略
- 安全开发生命周期
- 定期安全审计和评估
EOF

echo "  ✅ 已更新 architecture.md"

# 更新 current-status.md
cat > .claude/context/current-status.md << EOF
---
last_updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
project_phase: 项目初始化完成
overall_progress: 5%
---

# 当前项目状态

## 项目阶段
**当前阶段**: 项目初始化完成
- [x] 项目初始化和配置
- [x] DD工作流系统配置
- [x] 基础架构设计
- [ ] 核心功能开发
- [ ] 测试和优化
- [ ] 部署上线

## 功能完成情况
### 已完成功能 (0/0)
项目刚刚完成初始化, 尚未开始功能开发

### 规划中功能 (0/0)  
等待功能需求的添加和规划

## 技术实施进度
### 基础设施 (20%)
- [x] DD工作流系统配置
- [x] 项目上下文建立
- [x] 技术架构定义
- [ ] 开发环境搭建
- [ ] 数据库设计
- [ ] 部署环境准备

### 开发准备 (10%)
- [x] 项目结构规划
- [x] 技术栈确认
- [ ] 开发规范制定
- [ ] 代码库初始化
- [ ] CI/CD流程建立

## 质量指标
### 当前指标
- **DD工作流配置**: ✅ 已完成
- **项目文档完整性**: ✅ 基础文档已建立
- **技术架构清晰度**: ✅ 架构方案已确定

### 目标指标
- **代码质量**: 目标90%以上质量分数
- **测试覆盖率**: 目标80%以上覆盖率  
- **性能指标**: 响应时间<2秒
- **安全评级**: A级安全标准

## 下一步计划
### 近期任务（1-2周）
1. 使用 /dd:feature-add 添加第一个核心功能
2. 进行功能任务分解 /dd:task-decompose
3. 开始核心功能开发 /dd:feature-start
4. 建立基础开发环境和工具链

### 中期目标（1个月）
1. 完成核心功能的MVP版本
2. 建立完整的测试体系
3. 配置CI/CD自动化流程
4. 进行第一轮代码质量审查

### 长期目标（3个月）
1. 完成主要功能模块开发
2. 系统集成和性能优化
3. 安全评估和加固
4. 准备生产环境部署

## 团队状态
### 开发资源
- DD工作流系统: ✅ 已配置并可用
- 智能辅助开发: ✅ 可使用 /dd:chat 进行技术咨询
- 项目管理: ✅ 基于任务的进度跟踪

### 当前重点
- 明确第一个要开发的核心功能
- 建立开发环境和工具链
- 开始功能设计和开发工作

## 风险和挑战
### 当前风险
- 功能需求尚未明确定义
- 开发环境尚未搭建完成

### 缓解措施
- 使用 /dd:chat 进行需求分析讨论
- 使用 /dd:feature-add 系统化添加功能
- 遵循DD工作流确保质量和进度

## 建议的下一步行动
1. **明确核心功能**: 使用 /dd:chat 讨论和确定第一个要开发的功能
2. **添加功能**: 使用 /dd:feature-add <功能名称> 创建功能规划
3. **任务分解**: 使用 /dd:task-decompose <功能名称> 进行任务规划
4. **开始开发**: 使用 /dd:feature-start <功能名称> 开始开发
5. **持续改进**: 定期使用 /dd:code-reflect 进行代码质量反思
EOF

echo "  ✅ 已更新 current-status.md"

## 2. 清理模板功能目录

echo ""
echo "🧹 清理模板功能目录..."

# 删除示例功能目录
if [ -d ".claude/features/用户认证系统" ]; then
  rm -rf ".claude/features/用户认证系统"
  echo "  ✅ 已删除示例功能: 用户认证系统"
else
  echo "  ℹ️  示例功能目录不存在, 跳过清理"
fi

# 确保 features 目录存在但为空
mkdir -p .claude/features
echo "  ✅ 功能目录已准备就绪"

## 3. CLAUDE.md 文件状态检查

echo ""
echo "📋 检查 CLAUDE.md 文件状态..."

# 检查DD系统配置文件
if [ ! -f ".claude/CLAUDE.md" ]; then
    echo "❌ 错误: .claude/CLAUDE.md 文件不存在"
    exit 1
fi
echo "  ✅ DD系统配置文件存在"

# 检查根目录配置文件状态
if [ -f "CLAUDE.md" ]; then
    echo "  🔍 检测到根目录现有 CLAUDE.md 文件"
    echo "  📊 现有文件: $(wc -l < CLAUDE.md) 行"
else
    echo "  📄 根目录无现有 CLAUDE.md 文件"
fi
echo "  📊 DD配置文件: $(wc -l < .claude/CLAUDE.md) 行"

echo "  ⏭️  CLAUDE.md 智能合并将在下一步骤自动执行"

## 4. 完成后状态更新

echo ""
echo "📊 更新初始化完成状态..."

# 记录初始化完成时间和状态
sed -i.bak "s/project_phase: 项目初始化完成/project_phase: 已初始化/" .claude/context/current-status.md 2>/dev/null
sed -i.bak "s/overall_progress: 5%/overall_progress: 10%/" .claude/context/current-status.md 2>/dev/null
rm -f .claude/context/current-status.md.bak

echo "  ✅ 项目状态已更新"

## 5. 完成总结

echo ""
echo "🎉 初始化后处理完成！"
echo ""
echo "📋 处理完成项目: "
echo "  📁 项目名称: $project_name"
echo "  🏗️ 架构模式: $architecture"  
echo "  ⚙️ 技术栈: $tech_stack"
echo ""
echo "✅ 已完成的工作: "
echo "  • 项目上下文文件已更新"
echo "  • 模板功能目录已清理"
echo "  • CLAUDE.md 配置已处理"
echo "  • 绝对规则已永久加载"
echo ""
echo "🚀 建议的下一步操作: "
echo "  • 使用 /dd:chat 讨论项目具体需求"
echo "  • 使用 /dd:feature-add <功能名> 添加第一个功能"
echo "  • 使用 /dd:status 查看项目整体状态"
echo ""
echo "💡 快速开始: "
echo "  /dd:chat"
echo "  我想为这个项目添加第一个核心功能, "
echo "  应该从什么功能开始比较合适？"

exit 0