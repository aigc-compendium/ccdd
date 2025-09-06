# UI 上下文配置

## UI 图片目录配置

### 默认扫描目录
```yaml
ui_design_paths:
  - "./.claude/designs/"  # Claude 管理的设计文件
  - "./designs/"          # 项目设计文件目录
```

### 支持的图片格式
```yaml
supported_formats:
  - "*.png"
  - "*.jpg" 
  - "*.jpeg"
  - "*.svg"
  - "*.webp"
  - "*.gif"
```

### UI 任务关键词识别
```yaml
ui_keywords:
  task_types:
    - "UI"
    - "界面" 
    - "页面"
    - "组件"
    - "前端"
    - "设计"
    - "样式"
    - "布局"
    - "响应式"
  
  tech_keywords:
    - "React"
    - "Vue" 
    - "HTML"
    - "CSS"
    - "Tailwind"
    - "Bootstrap"
    - "Material"
    - "Antd"
    
  action_keywords:
    - "实现"
    - "开发" 
    - "创建"
    - "构建"
    - "编码"
    - "还原"
```

### 自动分析配置
```yaml
auto_analysis:
  # 当检测到 UI 任务时自动扫描图片
  enabled: true
  
  # 分析深度
  analysis_depth:
    - "layout"      # 布局分析
    - "components"  # 组件识别  
    - "colors"      # 色彩方案
    - "typography"  # 字体样式
    - "spacing"     # 间距规律
    - "interaction" # 交互元素
  
  # 生成内容
  generate:
    - "component_structure"  # 组件结构分析
    - "css_variables"       # CSS 变量提取
    - "implementation_plan" # 实现计划
    - "code_templates"      # 代码模板
```

## 集成流程

### task-start 自动检测流程
1. **任务描述分析** - 检测 UI 开发相关关键词
2. **目录扫描** - 自动扫描配置的 UI 设计目录
3. **图片匹配** - 根据任务名称/标签匹配相关图片
4. **智能分析** - 自动分析图片并生成上下文
5. **上下文注入** - 将分析结果注入任务执行上下文

### 图片匹配规则
```yaml
matching_rules:
  # 按任务ID匹配
  task_id_pattern: "{task_id}*.*"
  
  # 按任务标签匹配  
  task_tag_pattern: "*{tag}*.*"
  
  # 按功能名称匹配
  feature_name_pattern: "*{feature}*.*"
  
  # 模糊匹配
  fuzzy_matching: true
```

---

**创建时间**: 2025-01-17T02:33:00Z  
**用途**: DD工作流系统UI图片智能识别配置