# Claude Code 核心架构参考

> 来源：Claude Code v2.1.88 泄露源码分析
> 保存日期：2026-03-31
> 用途：处理事务时的架构参考

---

## 一、源码规模

| 指标 | 数值 |
|------|------|
| 源文件 | 1,884 个 .ts/.tsx |
| 代码行数 | 512,664 行 |
| 源码大小 | 35MB |
| 最大文件 | main.tsx (803KB, 4,683行) |
| 依赖包 | 192 个 |
| 运行时 | Bun（编译为 Node.js >= 18） |

---

## 二、核心目录结构

```
src/
├── main.tsx              # REPL 启动入口 (4,683行)
├── query.ts              # 核心 Agent 循环 (1,729行)
├── query/                # 查询子系统
│   ├── transitions.ts    # 状态转换
│   ├── config.ts        # 查询配置
│   └── deps.ts          # 依赖注入
├── Tool.ts               # 工具接口 (792行)
├── Task.ts               # 任务类型定义
├── tools.ts              # 工具注册表
├── commands.ts           # Slash 命令 (25KB)
├── context.ts            # 上下文管理
├── cost-tracker.ts       # 成本追踪
├── setup.ts             # 首次运行设置
│
├── tools/               # 工具实现 (43个子目录)
│   ├── BashTool/        # Bash 执行
│   ├── FileEditTool/    # 文件编辑
│   ├── FileReadTool/    # 文件读取
│   ├── FileWriteTool/   # 文件写入
│   ├── WebSearchTool/   # 网页搜索
│   ├── WebFetchTool/    # 网页抓取
│   ├── GrepTool/        # 代码搜索
│   ├── GlobTool/        # 文件匹配
│   ├── AgentTool/       # 子智能体
│   ├── MCPTool/         # MCP 协议
│   ├── REPLTool/        # 交互式 REPL
│   ├── TaskCreateTool/  # 任务创建
│   ├── TeamCreateTool/  # 团队创建
│   └── [30+ more...]
│
├── commands/             # Slash 命令 (101个子目录)
│   ├── init.ts/         # 初始化
│   ├── commit.ts/        # Git 提交
│   ├── diff.ts/          # 差异查看
│   ├── bughunter/       # Bug 追踪
│   ├── agents/          # 多智能体
│   ├── compact/          # 上下文压缩
│   └── [90+ more...]
│
├── bridge/               # Claude Desktop 远程桥接
├── cli/                  # CLI 基础设施
├── coordinator/           # 多智能体协调
├── services/             # 核心服务
│   ├── compact/          # 上下文压缩
│   ├── contextCollapse/  # 上下文折叠
│   ├── skillSearch/     # 技能搜索
│   └── [MCP服务]
├── components/           # React 组件
├── state/               # 状态管理
├── tasks/               # 任务系统
├── types/               # 类型定义
└── utils/               # 工具函数 (33个子目录)
```

---

## 三、89个特性开关（feature flags）

这是 Claude Code 最核心的工程设计 — **Bun 的 `feature()` 编译时 intrinsic**。

### 3.1 特性开关完整列表

| 开关 | 用途 | 引用次数 |
|------|------|----------|
| `KAIROS` | 主动式 AI 模式 | 154 |
| `TRANSCRIPT_CLASSIFIER` | 转录分类器 | 107 |
| `TEAMMEM` | 团队记忆 | 51 |
| `VOICE_MODE` | 语音模式 | 46 |
| `BASH_CLASSIFIER` | Bash 命令分类 | 45 |
| `KAIROS_BRIEF` | Kairos 摘要 | 39 |
| `PROACTIVE` | 主动通知 | 37 |
| `COORDINATOR_MODE` | 多智能体协调 | 32 |
| `BRIDGE_MODE` | 远程桥接 | 28 |
| `EXPERIMENTAL_SKILL_SEARCH` | 技能搜索 | 21 |
| `CONTEXT_COLLAPSE` | 上下文折叠 | 20 |
| `KAIROS_CHANNELS` | Kairos 频道 | 19 |
| `UDS_INBOX` | Unix Socket 收件箱 | 17 |
| `CHICAGO_MCP` | MCP 协议 | 16 |
| `BUDDY` | 伙伴系统 | 16 |
| `HISTORY_SNIP` | 历史片段 | 15 |
| `MONITOR_TOOL` | 监控工具 | 13 |
| `COMMIT_ATTRIBUTION` | 提交归因 | 12 |
| `CACHED_MICROCOMPACT` | 微压缩缓存 | 12 |
| `BG_SESSIONS` | 后台会话 | 11 |
| `AGENT_TRIGGERS` | 智能体触发器 | 11 |
| `WORKFLOW_SCRIPTS` | 工作流脚本 | 10 |
| `ULTRAPLAN` | 超级计划 | 10 |
| `FORK_SUBAGENT` | Fork 子智能体 | 10 |
| `WEB_BROWSER_TOOL` | 浏览器自动化 | 10+ |
| `MCP_SKILLS` | MCP 技能 | 9 |
| `EXTRACT_MEMORIES` | 记忆提取 | 7 |
| `DAEMON` | 后台守护进程 | 7 |
| `REACTIVE_COMPACT` | 响应式压缩 | - |
| `REPLTool` | 交互式 REPL | 内部 |

### 3.2 编译时死代码消除原理

```
内部构建 (feature = true)              npm 发布 (feature = false)
────────────────────────              ──────────────────────
feature('KAIROS') = true        ───▶    feature('KAIROS') = false
         ↓                                    ↓
   包含完整代码                      ───▶    死代码消除 (DCE)
   (daemon/main.js 等)                      (代码被删除)
```

**关键**：Bun 的 `feature()` 是编译时 intrinsic，不是运行时判断。

---

## 四、43个内置工具

| 类别 | 工具列表 |
|------|----------|
| **文件操作** | BashTool, FileReadTool, FileWriteTool, FileEditTool |
| **代码搜索** | GrepTool, GlobTool |
| **Web 能力** | WebSearchTool, WebFetchTool |
| **任务管理** | TaskCreateTool, TaskListTool, TaskGetTool, TaskUpdateTool, TaskStopTool, TaskOutputTool |
| **团队协作** | TeamCreateTool, TeamDeleteTool |
| **子智能体** | AgentTool |
| **MCP 协议** | MCPTool, ListMcpResourcesTool, ReadMcpResourceTool, McpAuthTool |
| **开发辅助** | REPLTool, LSPTool, NotebookEditTool |
| **其他** | WebBrowserTool, SkillTool, ToolSearchTool, BriefTool, TodoWriteTool, SendMessageTool, AskUserQuestionTool, PowerShellTool |

---

## 五、Agent 主循环架构

### 5.1 核心循环

```
用户输入 → 消息构建 → Claude API → 响应解析
                                  ↓
                        stop_reason == "tool_use"?
                               /            \
                             yes             no
                              ↓               ↓
                        执行工具          返回文本
                        追加结果
                        循环 ─────────▶ 消息列表
```

### 5.2 核心类型定义

```typescript
export type QueryParams = {
  messages: Message[]
  systemPrompt: SystemPrompt
  userContext: { [k: string]: string }
  systemContext: { [k: string]: string }
  canUseTool: CanUseToolFn
  toolUseContext: ToolUseContext
  fallbackModel?: string
  querySource: QuerySource
  maxOutputTokensOverride?: number
  maxTurns?: number
  skipCacheWrite?: boolean
  taskBudget?: { total: number }
  deps?: QueryDeps
}
```

### 5.3 工具执行

```typescript
// 工具工厂 - buildTool 模式
export type ToolInputJSONSchema = {
  type: 'object'
  properties?: { [x: string]: unknown }
}

// 特性开关条件加载
const reactiveCompact = feature('REACTIVE_COMPACT')
  ? require('./services/compact/reactiveCompact.js')
  : null

const contextCollapse = feature('CONTEXT_COLLAPSE')
  ? require('./services/contextCollapse/index.js')
  : null
```

---

## 六、与 OpenClaw 架构对比

| 维度 | Claude Code | OpenClaw |
|------|-------------|----------|
| **架构模式** | 单体 Agent + 特性开关 | 多 Agent + 通道路由 |
| **代码规模** | 51 万行 | ~30万行 |
| **特性开关** | 89 个 `feature()` | Skills 平台 |
| **工具系统** | 43 内置工具 | Tools 平台 |
| **命令系统** | 101 Slash 命令 | 插件系统 |
| **多智能体** | `FORK_SUBAGENT` | `sessions_spawn` |
| **上下文压缩** | `CONTEXT_COLLAPSE` | 手动/自动 |
| **发布方式** | npm (Bun 编译) | npm |

---

## 七、关键工程启示

1. **特性开关是工程化精髓**：用一套代码通过特性开关实现多种功能变体，发布时自动裁剪
2. **Bun 编译时优化**：利用 `feature()` intrinsic 实现编译时死代码消除
3. **Agent 模式标准化**：消息 → API → 工具 → 循环 是行业共识
4. **生产级工程**：50万行代码、完整的测试、监控、日志系统

---

## 八、源码位置

- 泄露源码：https://github.com/sanbuphy/claude-code-source-code
- 原始包：`@anthropic-ai/claude-code` v2.1.88
