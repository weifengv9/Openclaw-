# OpenClaw 多智能体知识库

> 来源: 
> - https://docs.OpenClaw.ai/zh-CN/concepts/multi-agent
> - https://github.com/OpenClaw/OpenClaw/
> 更新时间: 2026-04-03

---

## 一、OpenClaw 简介

OpenClaw 是一个运行在自己设备上的个人 AI 助手，通过已有的消息渠道（WhatsApp、Telegram、Slack、Discord 等）回答问题。

**核心功能：**
- 本地优先 Gateway — 会话、渠道、工具和事件的单一控制平面
- 多渠道收件箱 — 支持 20+ 消息平台
- 多智能体路由 — 将入站渠道/账户/对等方路由到隔离的智能体
- 语音唤醒 + 通话模式 — macOS/iOS 上的唤醒词和 Android 上的连续语音
- 实时画布 — AI 驱动的可视化工作区
- 配套应用 — macOS 菜单栏应用 + iOS/Android 节点

**支持的渠道：**
WhatsApp, Telegram, Slack, Discord, Google Chat, Signal, iMessage, BlueBubbles, IRC, Microsoft Teams, Matrix, Feishu, LINE, Mattermost, Nextcloud Talk, Nostr, Synology Chat, Tlon, Twitch, Zalo, WeChat, WebChat 等

**安装命令：**
```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

**快速开始：**
```bash
openclaw onboard --install-daemon
openclaw gateway --port 18789 --verbose
```

**安全默认：** 入站 DM 被视为不受信任的输入，默认需要配对码验证。

---

## 二、多智能体路由 (Multi-Agent Routing)

### 什么是"一个智能体"？

- **工作区**（文件、AGENTS.md/SOUL.md/USER.md、本地笔记、人设规则）
- **状态目录**（agentDir）用于认证配置文件、模型注册表和每智能体配置
- **会话存储**（聊天历史 + 路由状态）位于 `~/.openclaw/agents/<agentId>/sessions` 下

### 路径映射

| 用途 | 路径 |
|------|------|
| 配置 | `~/.openclaw/openclaw.json` |
| 状态目录 | `~/.openclaw` |
| 工作区 | `~/.openclaw/workspace` |
| 智能体目录 | `~/.openclaw/agents/<agentId>/agent` |
| 会话 | `~/.openclaw/agents/<agentId>/sessions` |

### 单智能体模式（默认）

- agentId 默认为 `main`
- 会话键为 `agent:main:<mainKey>`
- 工作区默认为 `~/.openclaw/workspace`

### 路由规则（最具体的优先）

1. peer 匹配（精确私信/群组/频道 id）
2. guildId（Discord）
3. teamId（Slack）
4. accountId 匹配
5. 渠道级匹配（accountId: "*"）
6. 回退到默认智能体

### 配置示例

- 两个 WhatsApp → 两个智能体（home + work）
- WhatsApp 日常聊天 + Telegram 深度工作
- 同一渠道，一个对等方到 Opus
- 绑定到 WhatsApp 群组的家庭智能体（带沙箱和工具限制）

### 每智能体沙箱和工具配置

- `sandbox.mode`: "off"（无沙箱）、"all"（始终隔离）
- `sandbox.scope`: "agent"（每智能体一个容器）、"shared"
- `tools.allow/deny` 列表

---

## 三、相关命令

```bash
# 查看状态
openclaw status

# 查看帮助
openclaw help

# Gateway 管理
openclaw gateway status
openclaw gateway start
openclaw gateway stop
openclaw gateway restart

# 安装守护进程
openclaw onboard --install-daemon
```

---

## 四、Sponsor

OpenAI, NVIDIA, Vercel, Blacksmith, Convex
