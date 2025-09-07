---
complexity: 中等
estimated_hours: 40
tech_stack: [Node.js, Express, JWT, bcrypt, MongoDB, React]
dependencies: []
---

# 用户认证系统 - 技术实现方案

## 技术选型

### 后端技术栈

- **框架**: Node.js + Express.js
- **数据库**: MongoDB + Mongoose ODM
- **认证**: JWT (JSON Web Token)
- **密码加密**: bcrypt
- **验证库**: Joi (输入验证)
- **邮件服务**: Nodemailer + SendGrid

### 前端技术栈

- **框架**: React.js
- **状态管理**: Redux Toolkit
- **路由**: React Router
- **UI组件**: Ant Design
- **HTTP客户端**: Axios
- **表单处理**: React Hook Form

## 架构设计

### 系统架构

```
前端 (React) -> API网关 -> 认证服务 -> 数据库 (MongoDB)
                    ↓
                邮件服务 (SendGrid)
```

### 数据层设计

- **用户表 (users)**
  - \_id: ObjectId (主键)
  - email: String (唯一索引)
  - username: String (可选, 唯一索引)
  - passwordHash: String
  - isEmailVerified: Boolean
  - emailVerificationToken: String
  - passwordResetToken: String
  - passwordResetExpires: Date
  - lastLogin: Date
  - loginAttempts: Number

- **会话表 (sessions)**
  - \_id: ObjectId (主键)
  - userId: ObjectId (外键)
  - tokenHash: String
  - deviceInfo: String
  - ipAddress: String

## 数据模型

### User Model

```javascript
const userSchema = new Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      validate: [validator.isEmail, 'Invalid email'],
    },
    username: {
      type: String,
      unique: true,
      sparse: true,
      minlength: 3,
      maxlength: 30,
    },
    passwordHash: {
      type: String,
      required: true,
      minlength: 8,
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    emailVerificationToken: String,
    passwordResetToken: String,
    passwordResetExpires: Date,
    lastLogin: Date,
    loginAttempts: {
      type: Number,
      default: 0,
    },
    lockUntil: Date,
  },
  {
    timestamps: true,
  }
)
```

## API 设计

### 认证相关接口

#### 1. 用户注册

- **POST** `/api/auth/register`
- **请求体**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePass123",
    "username": "optional_username"
  }
  ```
- **响应**:
  ```json
  {
    "success": true,
    "message": "Registration successful. Please verify your email.",
    "data": {
      "userId": "user_id",
      "email": "user@example.com"
    }
  }
  ```

#### 2. 邮箱验证

- **GET** `/api/auth/verify-email/:token`
- **响应**: 重定向到前端验证成功页面

#### 3. 用户登录

- **POST** `/api/auth/login`
- **请求体**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePass123",
    "rememberMe": true
  }
  ```
- **响应**:
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "user": {
        "id": "user_id",
        "email": "user@example.com",
        "username": "username"
      },
      "accessToken": "jwt_access_token",
      "refreshToken": "jwt_refresh_token"
    }
  }
  ```

#### 4. 密码重置请求

- **POST** `/api/auth/forgot-password`
- **请求体**:
  ```json
  {
    "email": "user@example.com"
  }
  ```

#### 5. 密码重置确认

- **POST** `/api/auth/reset-password/:token`
- **请求体**:
  ```json
  {
    "password": "NewSecurePass123"
  }
  ```

#### 6. 刷新Token

- **POST** `/api/auth/refresh-token`
- **请求头**: `Authorization: Bearer {refreshToken}`

#### 7. 登出

- **POST** `/api/auth/logout`
- **请求头**: `Authorization: Bearer {accessToken}`

## 关键技术点

### 1. 密码安全

- 使用 bcrypt 进行密码哈希, 强度因子设为 12
- 密码强度验证: 至少8位, 包含大小写字母和数字
- 防止密码在日志和错误信息中泄露

### 2. JWT Token 设计

- **Access Token**: 短期有效（15分钟）, 包含用户基本信息
- **Refresh Token**: 长期有效（7天）, 仅用于刷新Access Token
- Token中包含必要的用户信息和权限范围

### 3. 安全防护措施

- **输入验证**: 使用Joi库验证所有输入
- **SQL注入防护**: 使用参数化查询（Mongoose自带）
- **XSS防护**: 输出编码, 使用helmet.js
- **CSRF防护**: 双Cookie验证
- **暴力攻击防护**: 登录失败次数限制和账户锁定

### 4. 邮件验证机制

- 注册时发送验证邮件
- 验证token有24小时有效期
- 支持重新发送验证邮件

### 5. 会话管理

- JWT无状态认证
- Refresh Token存储在安全的HTTP-Only Cookie中
- 支持多设备登录和管理

## 错误处理策略

### 错误分类

1. **验证错误** (400): 输入格式错误、必填项缺失
2. **认证错误** (401): 密码错误、Token无效
3. **权限错误** (403): 账户未激活、账户被锁定
4. **资源错误** (404): 用户不存在、重置链接失效
5. **服务器错误** (500): 数据库连接失败、邮件发送失败

### 错误响应格式

```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Email or password is incorrect",
    "details": null
  }
}
```

## 性能优化

### 数据库优化

- 为email和username字段创建索引
- 连接池配置优化
- 查询语句优化

### 缓存策略

- Redis缓存用户会话信息
- 缓存邮件验证状态
- 缓存登录失败计数

### 监控指标

- 登录成功率
- 平均响应时间
- 邮件发送成功率
- 账户锁定频率

## 部署考虑

### 环境变量

- JWT_SECRET: JWT签名密钥
- JWT_EXPIRES_IN: Token过期时间
- MONGODB_URI: 数据库连接字符串
- EMAIL_SERVICE_KEY: 邮件服务API密钥
- BCRYPT_ROUNDS: 密码哈希强度

### 安全配置

- HTTPS强制使用
- 安全头配置
- CORS策略设置
- 敏感信息环境变量化
