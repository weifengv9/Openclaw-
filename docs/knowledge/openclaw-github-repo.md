# OpenClaw GitHub 仓库信息

> 来源: https://github.com/openclaw/openclaw
> 保存时间: 2026-04-06

## 基本信息

| 属性 | 值 |
|------|-----|
| 全名 | openclaw/openclaw |
| 描述 | Your own personal AI assistant. Any OS. Any Platform. The lobster way. 🦞 |
| Stars | 349,404 |
| Forks | 70,034 |
| 语言 | TypeScript |
| License | MIT |
| 创建时间 | 2025-11-24 |
| 默认分支 | main |
| 网站 | https://openclaw.ai |

## 核心特性

### 多渠道支持

OpenClaw 支持众多消息渠道：
- 即时消息: WhatsApp, Telegram, Signal, iMessage, SMS
- 社交: Discord, Slack, Microsoft Teams, Google Chat
- 其他: IRC, Matrix, Feishu, LINE, Mattermost, Nextcloud Talk, Nostr, Synology Chat, Tlon, Twitch, Zalo, WeChat, WebChat
- 移动端: macOS, iOS, Android

### 核心架构

- **Gateway WS 控制平面** — 会话、存在性、配置、cron、webhooks、Control UI 和 Canvas 主机
- **CLI 界面** — gateway、agent、send、onboarding 和 doctor 命令
- **Pi agent 运行时** — RPC 模式下的工具流和块流
- **会话模型** — `main` 用于直接聊天、群组隔离、激活模式、队列模式、回复回退
- **媒体管道** — 图像/音频/视频、转录钩子、大小限制、临时文件生命周期

### 关键子系统

- **Gateway WebSocket 网络** — 单一 WS 控制平面，用于客户端、工具和事件
- **Tailscale 暴露** — Serve/Funnel 用于 Gateway 仪表板 + WS（远程访问）
- **浏览器控制** — openclaw 管理的 Chrome/Chromium 与 CDP 控制
- **Canvas + A2UI** — agent 驱动的可视化工作空间
- **Voice Wake** + **Talk Mode** — macOS/iOS 唤醒词 + Android 持续语音
- **Nodes** — Canvas、相机快照/剪辑、屏幕录制、`location.get`、通知

### 部署方式

```bash
# 推荐安装
npm install -g openclaw@latest
openclaw onboard --install-daemon

# 从源码构建
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm build
```

### 运行环境

- **推荐**: Node 24 或 Node 22.16+
- **开发**: pnpm（bun 可选）
- **支持的平台**: macOS, Linux, Windows (via WSL2)

### 安全模型

- **DM pairing** (`dmPolicy="pairing"`): 未知发送者收到配对码，bot 不处理其消息
- **Public DM**: 需要显式 opt-in，设置 `dmPolicy="open"` 并在 allowlist 中包含 `"*"`
- 工具默认在主机上运行，为主要会话提供完整访问权限
- 群组/频道安全: 设置 `agents.defaults.sandbox.mode: "non-main"` 在 Docker 沙箱中运行非主要会话

### 配置示例

最小配置 `~/.openclaw/openclaw.json`:
```json5
{
  agent: {
    model: "anthropic/claude-opus-4-6",
  },
}
```

完整配置参考: https://docs.openclaw.ai/gateway/configuration

### 赞助商

- OpenAI (ChatGPT/Codex)
- GitHub
- NVIDIA
- Vercel
- Blacksmith
- Convex

### 相关链接

- [文档](https://docs.openclaw.ai)
- [愿景](https://github.com/openclaw/openclaw/blob/main/VISION.md)
- [DeepWiki](https://deepwiki.com/openclaw/openclaw)
- [入门指南](https://docs.openclaw.ai/start/getting-started)
- [更新指南](https://docs.openclaw.ai/install/updating)
- [展示](https://docs.openclaw.ai/start/showcase)
- [FAQ](https://docs.openclaw.ai/help/faq)
- [Nix 安装](https://github.com/openclaw/nix-openclaw)
- [Docker](https://docs.openclaw.ai/install/docker)
- [Discord](https://discord.gg/clawd)
