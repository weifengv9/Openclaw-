# OpenClaw Multi-Agent 架构文档

> 来源: https://docs.openclaw.ai/zh-CN/concepts/multi-agent
> 保存时间: 2026-04-06

## 核心概念

### 什么是"一个 Agent"？

一个 **agent** 是一个完整作用域的大脑，拥有自己的：

- **Workspace**（文件、AGENTS.md/SOUL.md/USER.md、本地笔记、角色规则）
- **状态目录**（`agentDir`）用于认证配置、模型注册和每个 agent 的配置
- **会话存储**（聊天历史 + 路由状态）位于 `~/.openclaw/agents/<agentId>/sessions`

### 路径快速映射

- 配置: `~/.openclaw/openclaw.json`（或 `OPENCLAW_CONFIG_PATH`）
- 状态目录: `~/.openclaw`（或 `OPENCLAW_STATE_DIR`）
- Workspace: `~/.openclaw/workspace`（或 `~/.openclaw/workspace-<agentId>`）
- Agent 目录: `~/.openclaw/agents/<agentId>/agent`（或 `agents.list[].agentDir`）
- 会话: `~/.openclaw/agents/<agentId>/sessions`

## 多 Agent 路由机制

### 路由规则（消息如何选择 Agent）

绑定是 **确定性** 的，**最具体者优先**：

1. `peer` 匹配（精确 DM/群组/频道 ID）
2. `parentPeer` 匹配（线程继承）
3. `guildId + roles`（Discord 角色路由）
4. `guildId`（Discord）
5. `teamId`（Slack）
6. `accountId` 匹配（频道账号）
7. 频道级别匹配（`accountId: "*"`）
8. 回退到默认 agent（`agents.list[].default`，否则第一个条目，默认为 `main`）

### 关键概念

- `agentId`: 一个"大脑"（workspace、per-agent 认证、per-agent 会话存储）
- `accountId`: 一个频道账号实例（例如 WhatsApp 的 `"personal"` vs `"biz"`）
- `binding`: 通过 `(channel, accountId, peer)` 将入站消息路由到 `agentId`，可选地使用 guild/team ids

## 快速开始

### 步骤 1: 创建每个 Agent workspace

```bash
openclaw agents add coding
openclaw agents add social
```

### 步骤 2: 创建频道账号

每个 agent 创建自己偏好的频道账号：

```bash
openclaw channels login --channel whatsapp --account work
```

### 步骤 3: 添加 agents、accounts 和 bindings

在 `agents.list` 下添加 agents，在 `channels.<channel>.accounts` 下添加频道账号，并用 `bindings` 连接它们。

### 步骤 4: 重启并验证

```bash
openclaw gateway restart
openclaw agents list --bindings
openclaw channels status --probe
```

## 多个 Agent = 多个人，多种人格

使用 **多 Agent**，每个 `agentId` 成为 **完全隔离的人格**：

- **不同的电话号码/账号**（每个频道 per-accountId）
- **不同的人格**（per-agent workspace 文件如 `AGENTS.md` 和 `SOUL.md`）
- **分离的认证 + 会话**（除非明确启用，否则不会交叉对话）

## 平台示例

### Discord bots per agent

每个 Discord bot 账号映射到唯一的 `accountId`。将每个账号绑定到一个 agent。

```json5
{
  agents: {
    list: [
      { id: "main", workspace: "~/.openclaw/workspace-main" },
      { id: "coding", workspace: "~/.openclaw/workspace-coding" },
    ],
  },
  bindings: [
    { agentId: "main", match: { channel: "discord", accountId: "default" } },
    { agentId: "coding", match: { channel: "discord", accountId: "coding" } },
  ],
  channels: {
    discord: {
      accounts: {
        default: { token: "DISCORD_BOT_TOKEN_MAIN" },
        coding: { token: "DISCORD_BOT_TOKEN_CODING" },
      },
    },
  },
}
```

### Telegram bots per agent

```json5
{
  agents: {
    list: [
      { id: "main", workspace: "~/.openclaw/workspace-main" },
      { id: "alerts", workspace: "~/.openclaw/workspace-alerts" },
    ],
  },
  bindings: [
    { agentId: "main", match: { channel: "telegram", accountId: "default" } },
    { agentId: "alerts", match: { channel: "telegram", accountId: "alerts" } },
  ],
  channels: {
    telegram: {
      accounts: {
        default: { botToken: "123456:ABC..." },
        alerts: { botToken: "987654:XYZ..." },
      },
    },
  },
}
```

### WhatsApp numbers per agent

```bash
openclaw channels login --channel whatsapp --account personal
openclaw channels login --channel whatsapp --account biz
```

### 同一个 WhatsApp 号码，多个人（DM split）

可以将 **不同的 WhatsApp DM** 路由到不同的 agent，同时使用 **一个 WhatsApp 账号**。通过发送者 E.164 匹配（如 `+15551234567`）和 `peer.kind: "direct"`。

## 跨 Agent QMD 内存搜索

如果一个 agent 应该搜索另一个 agent 的 QMD 会话记录，在 `agents.list[].memorySearch.qmd.extraCollections` 下添加额外集合。

```json5
{
  agents: {
    defaults: {
      memorySearch: {
        qmd: {
          extraCollections: [{ path: "~/agents/family/sessions", name: "family-sessions" }],
        },
      },
    },
  },
}
```

## Per-Agent 沙箱和工具配置

每个 agent 可以有自己的沙箱和工具限制：

```js
{
  agents: {
    list: [
      {
        id: "personal",
        sandbox: { mode: "off" },  // 无沙箱
      },
      {
        id: "family",
        sandbox: {
          mode: "all",
          scope: "agent",
          docker: {
            setupCommand: "apt-get update && apt-get install -y git curl",
          },
        },
        tools: {
          allow: ["read"],
          deny: ["exec", "write", "edit", "apply_patch"],
        },
      },
    ],
  },
}
```

**好处：**
- **安全隔离**：为不受信任的 agent 限制工具
- **资源控制**：为特定 agent 启用沙箱，同时让其他 agent 在主机运行
- **灵活策略**：每个 agent 不同权限

## 典型使用场景

### 场景 1: WhatsApp 日常聊天 + Telegram 深度工作

按频道分割：路由 WhatsApp 到快速日常 agent，Telegram 到 Opus agent。

### 场景 2: 同一个频道，一个 peer 到 Opus

保持 WhatsApp 在快速 agent，但将一个 DM 路由到 Opus：

```json5
{
  bindings: [
    { agentId: "opus", match: { channel: "whatsapp", peer: { kind: "direct", id: "+15551234567" } } },
    { agentId: "chat", match: { channel: "whatsapp" } },
  ],
}
```

### 场景 3: 家庭 Agent 绑定到 WhatsApp 群组

将专用家庭 agent 绑定到单个 WhatsApp 群组：

```json5
{
  agents: {
    list: [{
      id: "family",
      groupChat: { mentionPatterns: ["@family", "@familybot"] },
      sandbox: { mode: "all", scope: "agent" },
      tools: {
        allow: ["exec", "read", "sessions_list", "sessions_history"],
        deny: ["write", "edit", "browser", "canvas", "nodes", "cron"],
      },
    }],
  },
  bindings: [
    { agentId: "family", match: { channel: "whatsapp", peer: { kind: "group", id: "120363999999999999@g.us" } } },
  ],
}
```

## 相关文档

- [Channel Routing](/channels/channel-routing) — 消息如何路由到 agents
- [Sub-Agents](/tools/subagents) — 生成后台 agent 运行
- [ACP Agents](/tools/acp-agents) — 运行外部编码工具
- [Presence](/concepts/presence) — agent 存在性和可用性
- [Session](/concepts/session) — 会话隔离和路由
