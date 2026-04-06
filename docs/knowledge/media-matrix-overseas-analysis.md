# Media Matrix Overseas 项目分析

> 来源: /root/business/media-matrix-overseas/
> 分析时间: 2026-04-06

## 1. 项目概述

### 项目类型
Docker 微服务架构的多 Agent 协作系统

### 技术栈
| 组件 | 技术 |
|------|------|
| 运行环境 | Node.js 20 Alpine |
| 消息队列 | Redis 7 (ioredis) |
| HTTP客户端 | axios |
| 网关 | Nginx Alpine |
| 容器化 | Docker + docker-compose |

### 核心依赖
```json
{
  "axios": "^1.6.0",
  "ioredis": "^5.3.0"
}
```

## 2. 项目架构

```
media-matrix-overseas/
├── docker-compose.yml      # 主编排文件
├── .env                   # 环境变量 (API密钥)
├── agents/                # Agent 目录
│   ├── master/            # 主控 Agent
│   │   ├── master.js
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── dev/               # 开发 Agent (deepseek/deepseek-chat)
│   ├── content/           # 内容 Agent (kimi-k2.5)
│   ├── design/            # 设计 Agent (glm-4-9b-chat)
│   ├── data/               # 数据 Agent (deepseek/deepseek-chat)
│   ├── ops/                # 运维 Agent (minimax-text-01)
│   ├── support/            # 支持 Agent (glm-4-9b-chat)
│   └── research/           # 研究 Agent (deepseek/deepseek-chat)
├── config/                 # 配置文件目录
├── data/                   # 数据存储 (agent数据)
├── logs/                   # 日志目录
└── materials/              # 材料目录
```

## 3. Docker Compose 服务架构

| 服务 | 端口 | 环境变量 |
|------|------|---------|
| redis | 6379 | - |
| gateway (nginx) | 3000 | - |
| master-agent | - | REDIS, OPENROUTERAPIKEY, VOLCENGINEAPIKEY |
| dev-agent | - | REDIS, OPENROUTERAPIKEY, MODEL=deepseek/deepseek-chat |
| content-agent | - | REDIS, VOLCENGINEAPIKEY, MODEL=kimi-k2.5-202501 |
| design-agent | - | REDIS, VOLCENGINEAPIKEY, MODEL=glm-4-9b-chat |
| data-agent | - | REDIS, OPENROUTERAPIKEY, MODEL=deepseek/deepseek-chat |
| ops-agent | - | REDIS, VOLCENGINEAPIKEY, MODEL=minimax-text-01 |
| support-agent | - | REDIS, VOLCENGINEAPIKEY, MODEL=glm-4-9b-chat |
| research-agent | - | REDIS, OPENROUTERAPIKEY, MODEL=deepseek/deepseek-chat |

## 4. Agent 代码模式

### 标准 Agent 结构
```javascript
const Redis = require('ioredis');
const axios = require('axios');

// Redis 连接
const redis = new Redis({
  host: process.env.REDIS_HOST || 'redis',
  port: process.env.REDIS_PORT || 6379
});

// 启动日志
console.log(`$agent Agent started with model: ${process.env.MODEL || 'default'}`);

// 主循环
async function main() {
  while (true) {
    // 监听任务队列 (阻塞式)
    const task = await redis.brpop(`${agent}-tasks`, 30);
    if (task) {
      console.log('Processing task:', task);
      // 处理任务逻辑
    }
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
}

main().catch(console.error);
```

### 模式特点
1. **环境变量优先**: `process.env.XXX || default`
2. **阻塞式队列**: `redis.brpop()` 带超时
3. **主循环**: `while(true)` + `setTimeout`
4. **错误处理**: `.catch(console.error)`

## 5. Dockerfile 规范

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json .
RUN npm install axios ioredis
COPY . .
CMD ["node", "master.js"]
```

### Dockerfile 最佳实践
- ✅ 使用 Alpine 镜像 (轻量)
- ✅ 先 COPY package.json 再 npm install (利用 Docker 缓存)
- ✅ 设置 WORKDIR
- ✅ 使用 npm install (不用 pnpm)

## 6. package.json 规范

```json
{
  "name": "master-agent",
  "version": "1.0.0",
  "main": "master.js",
  "dependencies": {
    "axios": "^1.6.0",
    "ioredis": "^5.3.0"
  }
}
```

## 7. Docker Compose 规范

### 服务定义规范
```yaml
service-name:
  build: ./agents/xxx
  container_name: overseas-xxx
  environment:
    - REDIS_HOST=redis
    - REDIS_PORT=6379
    - KEY=${ENV_VAR}
  depends_on:
    - redis
  restart: unless-stopped
```

### 关键配置
- `container_name`: 统一前缀 `overseas-`
- `depends_on`: 依赖 redis
- `restart: unless-stopped`: 自动重启
- 环境变量引用: `${ENV_VAR}`

## 8. 代码风格分析

| 方面 | 风格 |
|------|------|
| 缩进 | 2空格 |
| 引号 | 单引号 (JS字符串) |
| 分号 | 使用 |
| 变量命名 | camelCase |
| 日志格式 | `[PREFIX] message` |
| 错误处理 | `.catch(console.error)` |

## 9. 安全规范

### .env 文件
```
OPENROUTERAPIKEY=xxx
VOLCENGINEAPIKEY=xxx
```
- 不提交到 Git
- 使用 docker-compose .env 注入

### 敏感信息处理
- API 密钥存储在 .env
- docker-compose 引用 `${VAR}` 格式

## 10. 可借鉴的规范

### 项目结构
```
project/
├── docker-compose.yml
├── .env (gitignore)
├── agents/
│   ├── agent-name/
│   │   ├── agent.js
│   │   ├── Dockerfile
│   │   └── package.json
├── config/
├── data/
└── logs/
```

### Agent 开发规范
1. 每个 Agent 独立目录
2. 标准化 Dockerfile
3. 环境变量配置模型
4. Redis 任务队列模式
5. 阻塞式消息监听

### Git 规范
- .env 文件必须 gitignore
- 每个 agent 独立版本控制
- 使用语义化版本 (1.0.0)
