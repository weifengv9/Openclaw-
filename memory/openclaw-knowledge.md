# OpenClaw 知识库

> 学习自官方文档：https://docs.OpenClaw.ai/zh-CN/concepts/multi-agent 和 https://github.com/OpenClaw/OpenClaw

## 项目概览

- **GitHub**: openclaw/openclaw
- **Stars**: 342k | **Forks**: 67.6k | **Contributors**: 1,426+
- **最新版本**: 2026.3.28
- **语言**: TypeScript 89%, Swift 6.3%, Kotlin 1.6%, JavaScript 1.2%
- **协议**: MIT License
- **官网**: openclaw.ai

## 核心架构

### Gateway (本地优先网关)
- WebSocket 控制平面
- 支持远程访问（SSH tunnels、Tailscale）
- 多渠道接入（40+消息平台）

### 关键子系统
- **Channels**: WhatsApp, Telegram, Slack, Discord, Signal, iMessage, Microsoft Teams, Matrix, Feishu, LINE, WeChat, Nostr, IRC, etc.
- **Apps + Nodes**: macOS app, iOS node, Android node, 远程 Gateway
- **Tools + Automation**: Browser control, Canvas, Cron + wakeups, Webhooks, Gmail Pub/Sub, Skills platform
- **Runtime + Safety**: Channel routing, retry policy, streaming/chunking, Presence, typing indicators, usage tracking
- **Agent to Agent**: sessions_* tools 支持多 Agent 通信

---

## 多智能体 (Multi-Agent) 文档要点

### 什么是 "One Agent"？
一个 Agent 是一个独立的大脑，有：
- **独立的工作空间** (workspace)
- **独立的认证配置** (per-agent authentication)
- **独立的会话存储** (per-agent session storage)

### 路由规则 (Routing Rules)
**确定性路由，优先匹配最具体的规则**：

1. `peer` 匹配 — 精确的 DM/群组/频道 ID
2. `guildId` 匹配 — Discord guild
3. `teamId` 匹配 — Slack team
4. `channel` 的 `accountId` 匹配
5. `channel` 级别匹配 (`accountId: "*"`)
6. 回退到默认 Agent

### 配置绑定 (Binding)
使用 `binding` 将消息路由到指定 AgentId，格式：
```yaml
binding:
  - channel: telegram
    accountId: "123456"
    peer: "789"       # 可选
    agentId: "my-agent"
```

### 多账号/多渠道场景
- **多 WhatsApp 账号** → 每个账号对应一个 Agent
- **WhatsApp 日常聊天 + Telegram 深度工作** → 不同 Agent 处理
- **家庭群组** → Family Agent 专门处理 WhatsApp 群消息

### Per-agent 沙箱和工具配置 (v2026.1.6+)
每个 Agent 可以有独立的：
- **sandbox 配置**: `mode` (off/all), `scope` (shared/agent), docker 镜像
- **tools 限制**: allow/deny 列表控制可用工具

### 关键配置字段
| 字段 | 说明 |
|------|------|
| `agentId` | Agent 唯一标识 |
| `accountId` | 渠道账号实例（如 WhatsApp 登录账号） |
| `binding` | 消息路由规则 |
| `workspace` | Agent 工作目录 |
| `agentDir` | Agent 认证配置目录 |
| `sandbox` | 沙箱模式配置 |
| `tools` | 工具允许/拒绝列表 |

---

## Skills 平台 (ClawHub)

- Skills 存放于 `skills/` 目录
- 通过 `clawhub` CLI 管理技能安装/更新
- Skill 结构：`SKILL.md` 定义技能说明和工具使用

---

## 重要链接

- 文档索引: https://docs.openclaw.ai
- GitHub: https://github.com/openclaw/openclaw
- 多智能体路由: https://docs.OpenClaw.ai/zh-CN/concepts/multi-agent
- ClawHub: https://clawhub.ai
