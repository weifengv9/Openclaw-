# OpenClaw 知识库

> 创建时间: 2026-04-06
> 来源: 用户提供的官方文档

## 文档位置

已保存到本地知识库：
- `/root/.openclaw/workspace/docs/knowledge/openclaw-multi-agent.md` — 多Agent路由完整文档
- `/root/.openclaw/workspace/docs/knowledge/openclaw-github-repo.md` — GitHub仓库信息

## 核心要点

### 1. OpenClaw 是什么
- 个人AI助手，运行在自有设备上
- 支持多渠道: WhatsApp, Telegram, Discord, Slack, Signal, iMessage, Feishu, WeChat等
- 本地优先 Gateway 架构
- MIT开源项目，Star 349k+，Forks 70k+

### 2. Multi-Agent 架构
- **agentId**: 一个"大脑"，包含独立workspace、认证、会话存储
- **accountId**: 频道账号实例（如WhatsApp的personal/biz账号）
- **binding**: 通过(channel, accountId, peer)路由消息到指定agent
- 支持多个隔离的agent运行在同一Gateway进程中

### 3. 路由优先级（最具体优先）
1. peer匹配（精确DM/群组/频道ID）
2. parentPeer匹配（线程继承）
3. guildId + roles（Discord角色路由）
4. accountId匹配
5. 频道级别匹配
6. 回退到默认agent

### 4. 安全机制
- DM pairing: 未知发送者需配对码
- Per-agent沙箱和工具限制
- 群组/频道可配置mentionPatterns
- 工具allow/deny列表

### 5. 典型场景
- Discord/Telegram多机器人账号分Agent
- WhatsApp多号码分Agent
- 家庭Agent绑定WhatsApp群组
- 不同频道路由到不同Agent（如WhatsApp日常+Telegram深度工作）

## 配置示例

```json5
{
  agents: {
    list: [
      { id: "main", workspace: "~/.openclaw/workspace-main" },
      { id: "work", workspace: "~/.openclaw/workspace-work" },
    ],
  },
  bindings: [
    { agentId: "main", match: { channel: "whatsapp", accountId: "personal" } },
    { agentId: "work", match: { channel: "whatsapp", accountId: "biz" } },
  ],
}
```

## 相关命令

- `openclaw agents add <name>` — 添加新Agent
- `openclaw agents list --bindings` — 查看Agent绑定
- `openclaw channels login --channel <channel> --account <account>` — 登录频道账号
- `openclaw gateway restart` — 重启Gateway

## 文档链接

- 官方文档: https://docs.openclaw.ai
- Multi-Agent文档: https://docs.openclaw.ai/zh-CN/concepts/multi-agent
- GitHub: https://github.com/openclaw/openclaw

---

## 项目分析案例

### Media Matrix Overseas (已分析)
- 位置: `/root/business/media-matrix-overseas/`
- 分析文档: `/root/.openclaw/workspace/docs/knowledge/media-matrix-overseas-analysis.md`
- 类型: Docker 微服务多Agent系统
- 技术栈: Node.js 20 Alpine + Redis + Nginx + Docker Compose
- Agent数量: 8个 (master, dev, content, design, data, ops, support, research)
- 编程模式: Redis BRPOP 阻塞队列 + while(true) 主循环

### 可借鉴的规范
1. 每个Agent独立目录 + 标准化Dockerfile
2. Redis消息队列模式
3. docker-compose统一编排
4. .env环境变量管理 (gitignore)
