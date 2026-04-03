# OpenClaw 系统深入研究笔记

> 研究日期: 2026-04-03
> 来源: 官方文档 + CLI帮助 + 全部 SKILL.md 分析

---

## 一、架构设计

### 1.1 核心定位

OpenClaw 是一个**本地优先（Local-First）的个人 AI 助手**。它不是一个聊天机器人，而是一个运行在自己设备上的智能中枢，通过已有的消息渠道与用户交互。

### 1.2 核心组件

| 组件 | 作用 |
|------|------|
| **Gateway** | 会话、渠道、工具和事件的单一控制平面（WebSocket 服务） |
| **Agent** | 独立的工作区 + 配置 + 会话存储 |
| **Channel** | 20+ 消息平台的接入层（WhatsApp/Telegram/Discord/飞书等） |
| **Skills** | 模块化的能力扩展包 |
| **MCP Bridge** | 将 OpenClaw 作为 MCP Server 暴露给 IDE |

### 1.3 路径映射

| 用途 | 路径 |
|------|------|
| 全局配置 | `~/.openclaw/openclaw.json` |
| 状态目录 | `~/.openclaw` |
| 默认工作区 | `~/.openclaw/workspace` |
| 智能体目录 | `~/.openclaw/agents/<agentId>/agent` |
| 会话存储 | `~/.openclaw/agents/<agentId>/sessions` |
| 技能目录 | `~/.openclaw/workspace/skills` (workspace) / `openclaw/skills` (bundled) |

### 1.4 多智能体路由

**路由优先级（最具体优先）：**
1. peer 匹配（精确私信/群组/频道 id）
2. guildId（Discord）
3. teamId（Slack）
4. accountId 匹配
5. 渠道级匹配（accountId: "*"）
6. 回退到默认智能体

**沙箱配置：**
- `sandbox.mode`: "off"（无沙箱）、"all"（始终隔离）
- `sandbox.scope`: "agent"（每智能体一个容器）、"shared"
- `tools.allow/deny` 列表

### 1.5 安全默认

入站 DM 被视为不受信任的输入，**默认需要配对码验证**。

---

## 二、MCP 配置方式

### 2.1 OpenClaw 作为 MCP Server

```bash
# 本地 Gateway
openclaw mcp serve

# 远程 Gateway（含 Token 认证）
openclaw mcp serve --url wss://gateway-host:18789 --token-file ~/.openclaw/gateway.token

# 启用 Claude 通知模式
openclaw mcp serve --claude-channel-mode on
```

**暴露的 MCP 工具：**
- `conversations_list` / `conversation_get` — 会话列表/详情
- `messages_read` — 读取历史消息
- `attachments_fetch` — 获取附件元数据
- `events_poll` / `events_wait` — 实时事件轮询
- `messages_send` — 发送消息
- `permissions_list_open` / `permissions_respond` — 审批管理

### 2.2 OpenClaw 作为 MCP Client（管理其他 MCP Server）

```bash
# 列出已保存的 MCP Server 定义
openclaw mcp list

# 查看某个定义
openclaw mcp show context7 --json

# 添加 stdio 传输的 MCP Server
openclaw mcp set context7 '{"command":"uvx","args":["context7-mcp"]}'

# 添加 HTTP/SSE 传输的远程 MCP Server
openclaw mcp set docs '{"url":"https://mcp.example.com","headers":{"Authorization":"Bearer <token>"}}'

# 删除
openclaw mcp unset context7
```

**配置格式（openclaw.json）：**
```json
{
  "mcp": {
    "servers": {
      "context7": {
        "command": "uvx",
        "args": ["context7-mcp"]
      },
      "remote-tools": {
        "url": "https://mcp.example.com",
        "headers": { "Authorization": "Bearer <token>" }
      }
    }
  }
}
```

### 2.3 MCP 与 ACP 的区别

| 特性 | `openclaw mcp serve` | `openclaw acp` |
|------|----------------------|-----------------|
| 协议 | MCP (Model Context Protocol) | ACP (Agent Client Protocol) |
| 用途 | IDE 接入 OpenClaw 渠道会话 | 外部 Agent 驱动 OpenClaw 会话 |
| 会话归属 | OpenClaw | ACP Client |
| 工具暴露 | 渠道消息工具 | ACP 原生工具 |

---

## 三、CLI 命令列表

### 3.1 核心命令

```bash
# 启动
openclaw onboard --install-daemon   # 首次安装 + 启动守护进程
openclaw gateway --port 18789       # 启动 Gateway

# 状态与管理
openclaw status                     # 查看渠道健康和最近会话
openclaw gateway status/start/stop/restart  # Gateway 管理
openclaw tui                        # 终端 UI 连接 Gateway
openclaw update *                   # 更新 OpenClaw

# 配置
openclaw config get <key>           # 获取配置
openclaw config set <key> <value>  # 设置配置

# Skills
openclaw skills list               # 列出所有技能
openclaw skills search <query>     # 搜索技能
openclaw skills install <name>      # 安装技能
openclaw skills update <name>       # 更新技能

# MCP
openclaw mcp serve                 # 启动 MCP Server
openclaw mcp list/show/set/unset   # 管理 MCP Server 定义

# ACP
openclaw acp                        # 启动 ACP Bridge
openclaw acp client                 # 内置 ACP 调试客户端

# 会话
openclaw sessions *                 # 会话管理
openclaw agent --to <target> --message "..." --deliver  # 直接发送消息

# 消息
openclaw message send --channel <channel> --target <target> --message "..."

# 配对与安全
openclaw pair                       # 配对管理
openclaw secrets *                  # 密钥运行时控制
openclaw security *                 # 安全工具和本地审计
```

### 3.2 完整命令列表

| 命令 | 描述 |
|------|------|
| `account *` | 渠道账户管理 |
| `acp` | ACP Bridge for IDE 集成 |
| `agents *` | 智能体配置 |
| `channels *` | 渠道管理（login/status/logout） |
| `chat` | 加密 DM 配对 |
| `config *` | 配置管理 |
| `gateway *` | Gateway 控制 |
| `help` | 帮助 |
| `logs` | 查看日志 |
| `models *` | 模型配置 |
| `mcp *` | MCP Server / MCP Server 定义管理 |
| `onboard` | 首次设置向导 |
| `pair` | 配对管理 |
| `plugins *` | 插件和扩展管理 |
| `qr` | iOS 配对二维码 |
| `reset` | 重置本地配置 |
| `sandbox *` | 沙箱容器管理 |
| `secrets *` | 密钥运行时控制 |
| `security *` | 安全工具 |
| `sessions *` | 会话管理 |
| `setup` | 初始化配置和工作区 |
| `skills *` | 技能管理 |
| `status` | 渠道健康状态 |
| `system *` | 系统事件和心跳 |
| `tasks *` | 后台任务状态 |
| `tui` | 终端 UI |
| `uninstall` | 卸载 |
| `update *` | 更新 |
| `webhooks *` | Webhook 集成 |

---

## 四、Skills 开发规范

### 4.1 目录结构

```
skill-name/
├── SKILL.md (必需)
│   ├── YAML frontmatter (必需)
│   │   ├── name: 技能名称
│   │   └── description: 描述（触发条件和功能说明）
│   └── Markdown 说明 (必需)
├── scripts/ (可选)
│   └── *.py / *.sh 等可执行脚本
├── references/ (可选)
│   └── *.md 参考文档
└── assets/ (可选)
    └── * 静态资源文件
```

### 4.2 核心原则

1. **简洁优先**：上下文窗口是公共资源，只添加模型真正需要的信息
2. **渐进披露**：元数据(约100词) → SKILL.md正文(<5k词) → bundled资源(按需)
3. **适度自由**：
   - 高自由度（文本指令）：适用于多路径、可变场景
   - 中等自由度（伪代码/脚本）：适用于有偏好模式但允许变化
   - 低自由度（固定脚本）：适用于脆弱、需一致性的操作

### 4.3 触发机制

Skill 的 `description` 字段是**唯一的触发机制**。Agent 根据描述判断是否触发该技能。

### 4.4 创建流程

1. 理解使用场景（具体例子）
2. 规划可复用资源（scripts/references/assets）
3. 初始化：`scripts/init_skill.py <name> --path <dir>`
4. 编写 SKILL.md 和资源文件
5. 打包验证：`scripts/package_skill.py <path>`
6. 迭代优化

### 4.5 命名规范

- 仅使用小写字母、数字、连字符
- 首选简短、动词领先的短语
- 可按工具命名空间（如 `gh-address-comments`）

---

## 五、Skills 清单（按功能分类）

### 5.1 消息与协作

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `feishu-doc` | 飞书文档读写 | 飞书文档、云文档 |
| `feishu-drive` | 飞书云空间 | 云空间、文件夹 |
| `feishu-perm` | 飞书权限管理 | 分享、权限、协作者 |
| `feishu-wiki` | 飞书知识库 | 知识库、wiki |
| `wecom-*` (12个) | 企业微信全家桶 | 文档/待办/会议/日程/通讯录/智能表格 |
| `tencent-docs` | 腾讯文档 | 新建/编辑腾讯文档 |
| `tencent-meeting-mcp` | 腾讯会议 | 预约/创建/查询会议 |
| `qqbot-*` (3个) | QQ 机器人 | 频道/提醒/媒体 |

### 5.2 开发者工具

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `github` | GitHub CLI | issue/PR/run/ api |
| `gh-issues` | GitHub Issues 管理 | 抓取issue + 修复 + PR |
| `git-helper` | 常用 Git 操作 | status/pull/push/branch/log |
| `git-workflows` | 高级 Git 操作 | rebase/bisect/worktree/subtree |
| `agent-git-oracle` | 代码库分析重构 | 技术债务/架构问题 |
| `coding-agent` | 代理编码任务 | 委托 Codex/Claude Code/Pi |
| `docker-sandbox` | Docker 沙箱 | 运行不受信任代码/隔离工作流 |
| `agent-browser` | 浏览器自动化 | AI 操作网页 |
| `tmux` | Tmux 会话控制 | 交互式 CLI 远程控制 |

### 5.3 效率与生产力

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `wecom-edit-todo` | 企业微信待办 | 创建/分配/完成待办 |
| `wecom-get-todo-list` | 待办列表查询 | 查看待办列表 |
| `wecom-get-todo-detail` | 待办详情 | 查看待办详情 |
| `wecom-schedule` | 企业微信日程 | 日程查询/创建/成员闲忙 |
| `lightclawbot-cron` | 定时提醒 | 一次性/周期性提醒 |
| `summarize` | 内容摘要 | 摘要 URL/文件/PDF/音视频 |
| `content-factory` | 多格式内容生产 | 社媒帖子/邮件/脚本 |
| `weather` | 天气预报 | 天气/温度/预报查询 |

### 5.4 云服务

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `tencent-cos-skill` | 腾讯云COS | 上传/下载/图片处理 |
| `tencentcloud-lighthouse-skill` | 腾讯云轻量应用服务器 | Lighthouse 管理 |

### 5.5 安全与维护

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `healthcheck` | 主机安全加固 | 安全审计/防火墙/SSH加固 |
| `openclaw-security-audit` | OpenClaw 安全审计 | 部署安全审查 |
| `security-scanner` | 安全扫描 | 漏洞扫描/SSL/端口检测 |
| `memory-hygiene` | 记忆清理 | LanceDB 清理/优化 |

### 5.6 平台集成

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `spotify-player` | Spotify 控制 | 播放/搜索音乐 |
| `openhue` | Philips Hue 灯光 | 控制灯光/场景 |
| `sonoscli` | Sonos 音箱 | 控制音箱/分组 |
| `apple-notes` | Apple Notes | 笔记管理 |
| `apple-reminders` | Apple Reminders | 提醒管理 |
| `things-mac` | Things 3 | 任务管理 |
| `notion` | Notion API | 页面/数据库管理 |
| `obsidian` | Obsidian 笔记 | 笔记库操作 |

### 5.7 AI 与媒体

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `agent-browser` | 浏览器自动化 | 网页操作 |
| `tavily-search` | Web 搜索 | 搜索网络/查找来源 |
| `video-frames` | 视频帧提取 | ffmpeg 提取帧/片段 |
| `openai-whisper` | 本地语音转文字 | 本地 Whisper |
| `openai-whisper-api` | API 语音转文字 | OpenAI API 转录 |
| `sag` | TTS (ElevenLabs) | 语音合成 |
| `sherpa-onnx-tts` | 本地 TTS | 离线语音合成 |
| `songsee` | 音频可视化 | 频谱图生成 |

### 5.8 技能开发

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `skill-creator` | 技能创建/审计 | 创建/改进/审计技能 |
| `clawhub` | ClawHub CLI | 搜索/安装/发布技能 |
| `find-skills` | 技能发现 | 查找/安装技能 |
| `skillhub-preference` | SkillHub 优先 | 中文用户技能发现 |
| `Skill Builder` | 技能构建器 | 创建高质量技能 |
| `mcporter` | MCP Server 管理 | 列出/配置/调用 MCP |

### 5.9 工作流编排

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `clawflow` | 多步骤任务编排 | 跨多个后台任务的工作流 |
| `clawflow-inbox-triage` | 收件箱分类 | 消息意图路由/通知汇总 |

### 5.10 系统工具

| Skill | 功能 | 触发场景 |
|-------|------|----------|
| `node-connect` | 节点连接诊断 | 配对失败/连接问题 |
| `model-usage` | 模型使用统计 | 用量/成本分析 |
| `session-logs` | 会话日志分析 | 历史会话搜索/jq |
| `canvas` | 画布控制 | 展示/截图/导航 |

---

## 六、高频核心 Skill（推荐熟练掌握）

### ⭐⭐⭐ 必会

| Skill | 重要性原因 |
|-------|-----------|
| `clawhub` / `find-skills` | 技能发现和安装的基础 |
| `skill-creator` | 自定义技能开发 |
| `github` / `git-helper` | 开发者日常工作 |
| `wecom-*` (企业微信) | 中文办公场景核心 |
| `feishu-*` (飞书) | 中文协作场景核心 |
| `weather` | 极高频日常查询 |
| `summarize` | 信息处理高频需求 |

### ⭐⭐ 常用

| Skill | 使用场景 |
|-------|----------|
| `tmux` | 交互式 CLI 操作 |
| `agent-browser` | 网页操作和爬取 |
| `tavily-search` | Web 搜索 |
| `git-workflows` | 高级 Git 操作 |
| `docker-sandbox` | 代码隔离执行 |
| `content-factory` | 内容多格式生产 |
| `tencent-docs` | 腾讯文档操作 |
| `tencent-meeting-mcp` | 腾讯会议 |

### ⭐ 辅助

| Skill | 场景 |
|-------|------|
| `healthcheck` | 安全审计 |
| `openclaw-security-audit` | OpenClaw 部署安全 |
| `security-scanner` | 渗透测试/漏洞扫描 |
| `memory-hygiene` | 向量记忆维护 |
| `agent-git-oracle` | 代码库重构分析 |

---

## 七、能力缺口分析（想做但暂无 Skill 支持）

### 7.1 高优先级缺口

| 需求 | 说明 | 建议方案 |
|------|------|----------|
| **飞书消息收发** | 目前只有文档/云空间/权限/知识库，缺少即时消息 | 需开发 `feishu-im` 或 `feishu-message` |
| **企业微信消息收发** | 只有待办/会议/日程/文档，缺少即时消息 | 已有 `wecom_mcp` 工具，可包装为 skill |
| **钉钉集成** | 完全缺失 | 需开发 `dingtalk-*` 系列 |
| **邮件发送/接收** | 有 `himalaya`（IMAP/SMTP CLI）但 needs setup | 需配置并包装为 skill |
| **日历同步（通用）** | 有 `gog`（Google Calendar）但 needs setup | 需配置 Apple 日历或 Outlook |
| **文件搜索** | 无全局文件搜索 skill | 可基于 `agent-browser` 或 `exec` 实现 |
| **数据库操作** | 无 SQL/NoSQL 操作 skill | 可开发 `database-cli` skill |

### 7.2 中优先级缺口

| 需求 | 说明 |
|------|------|
| **微信（个人号）** | 暂无支持 |
| **Telegram 管理** | 仅有基础 channel 工具 |
| **Notion 深度操作** | 仅有基础 API skill |
| **PDF 解析/问答** | 有 `nano-pdf` 但 needs setup |
| **OCR 图片文字识别** | 缺失 |
| **网页内容结构化提取** | 可用 `agent-browser` 曲线实现 |
| **监控系统集成** | 缺失（Prometheus/Grafana 等） |
| **CI/CD 状态查询** | 可用 `github` + `gh` 扩展 |

### 7.3 低优先级（生态已有但未集成）

| 需求 | 现有替代 |
|------|----------|
| **密码管理** | `1password` (needs setup) |
| **音乐识别** | `songsee` (音频可视化) |
| **智能家居** | `openhue`/`sonoscli`/`eightctl` (均 needs setup) |

---

## 八、技能依赖的外部工具/脚本路径

### 8.1 核心依赖

| Skill | 依赖工具 | 路径/命令 |
|-------|---------|----------|
| `clawhub` | clawhub CLI | `npm i -g clawhub` |
| `skill-creator` | init_skill.py, package_skill.py | `skills/skill-creator/scripts/` |
| `weather` | wttr.in / Open-Meteo | 无需安装 |
| `summarize` | summarize CLI | 需安装 |
| `github` | gh CLI | `npm i -g gh` 或系统安装 |
| `git-helper` | git | 系统自带 |
| `git-workflows` | git | 系统自带 |
| `tmux` | tmux | 系统自带 |
| `docker-sandbox` | docker | 系统安装 |
| `agent-browser` | 浏览器驱动 | 自动检测 |

### 8.2 企业微信依赖

| Skill | 依赖工具 | 说明 |
|-------|---------|------|
| `wecom-*` 全系列 | `wecom_mcp` MCP 工具 | 通过 `openclaw config set tools.alsoAllow '["wecom_mcp"]'` 白名单 |

### 8.3 腾讯云依赖

| Skill | 依赖工具 | 说明 |
|-------|---------|------|
| `tencent-cos-skill` | COS SDK / CI 服务 | 需配置 SecretId/SecretKey |
| `tencentcloud-lighthouse-skill` | 腾讯云 TAT / API | 需配置 CAM 密钥 |

---

## 九、当前已安装的 Skills 统计

**总计：92 个 Skills**
- ✅ Ready（可立即使用）：38 个
- △ Needs Setup（需配置才能用）：54 个

**按来源分布：**
- `openclaw-bundled`：内置 skills（多数 needs setup）
- `openclaw-extra`：飞书/企业微信/QQ 等扩展
- `openclaw-workspace`：工作区自定义 skills

### 10.2 Claude/pi-agent-core 集成（重要！）

OpenClaw 的嵌入式 Agent 运行时 **pi-agent-core**（即 Claude Code 的核心引擎）：

| 组件 | 说明 |
|------|------|
| `pi-agent-core` | Claude Code 的核心引擎，OpenClaw 通过它调用 Claude |
| `createAgentSession()` | OpenClaw 创建 Agent 会话的 SDK |
| `runEmbeddedPiAgent` | 串行化执行 Agent 核心逻辑 |
| `subscribeEmbeddedPiSession` | 桥接 pi 事件到 OpenClaw 流事件 |

**支持的模型提供商：**
- Anthropic (API key 或 Claude Code setup-token)
- OpenAI (Codex 订阅 OAuth)
- Google Gemini
- OpenRouter (含免费模型扫描)

**Provider 特定处理：**
- Anthropic: 拒绝识别、轮次验证、Claude Code 参数兼容性
- Google/Gemini: 轮次排序修复、工具 schema 清理
- OpenAI: `apply_patch` 工具支持（Codex 模型）

### 10.3 关键 Hook 点

OpenClaw 有两套 Hook 系统：

**Gateway Hooks（内部）：**
- `agent:bootstrap` — 构建引导文件时运行
- 命令 Hook — `/new`, `/reset`, `/stop` 等

**Plugin Hooks（Agent + Gateway 生命周期）：**
| Hook | 时机 |
|------|------|
| `before_model_resolve` | session 前（无 messages） |
| `before_prompt_build` | session 加载后（带 messages） |
| `before_agent_start` | Agent 启动前 |
| `agent_end` | Agent 完成后 |
| `before_compaction / after_compaction` | 压缩周期 |
| `before_tool_call / after_tool_call` | 工具调用前后 |
| `message_received / message_sending / message_sent` | 消息生命周期 |

### 10.4 快速参考

#### 安装新 Skill
```bash
clawhub install <skill-name>          # 从 ClawHub 安装
openclaw skills install <name>        # 同样是安装命令
```

#### 搜索 Skill
```bash
clawhub search <keyword>             # 搜索
openclaw skills search <query>       # 同样是搜索
```

#### 查看 Skill 详情
```bash
cat ~/.openclaw/workspace/skills/<name>/SKILL.md
```

#### 开发新 Skill
1. 读取 `skill-creator` skill
2. 运行 `scripts/init_skill.py <name> --path skills/`
3. 编写 SKILL.md
4. 打包 `scripts/package_skill.py <path>`

#### 模型管理
```bash
openclaw models list                 # 列出模型
openclaw models status              # 模型状态
openclaw models set <provider/model> # 设置默认模型
openclaw models scan                # 扫描 OpenRouter 免费模型
```

#### Claude Code 集成（via acpx）
```bash
# 让 Codex/Claude Code 通过 ACP 协议连接 OpenClaw
acpx openclaw exec "Summarize the active session state"

# 持久化会话
acpx openclaw sessions ensure --name codex-bridge
acpx openclaw -s codex-bridge --cwd /path/to/repo "..."
```

---

## 十一、参考资料

- 官方文档：https://docs.openclaw.ai
- GitHub：https://github.com/openclaw/openclaw
- ClawHub：https://clawhub.com
