# Claude Code 源码分析

> 来源: claude-code-main.zip (2026-03-31 泄漏版本)
> 分析时间: 2026-04-06

## 项目概述

| 属性 | 值 |
|------|-----|
| 项目名 | Claude Code |
| 类型 | AI 编程 CLI 工具 |
| 语言 | TypeScript |
| 运行时 | Bun |
| 终端 UI | React + Ink |
| 代码规模 | ~1,900 文件, 512,000+ 行代码 |
| 架构 | Commander.js CLI + React Ink TUI |

## 目录结构

```
src/
├── main.tsx                 # 入口点 (Commander.js CLI)
├── commands.ts              # 命令注册表
├── tools.ts                 # 工具注册表
├── Tool.ts                  # 工具类型定义
├── QueryEngine.ts           # LLM 查询引擎
├── context.ts               # 系统/用户上下文收集
├── cost-tracker.ts          # Token 成本追踪
│
├── commands/                # 斜杠命令实现 (~50个)
├── tools/                   # Agent 工具实现 (~40个)
├── components/              # Ink UI 组件 (~140个)
├── hooks/                   # React hooks
├── services/                # 外部服务集成
├── screens/                 # 全屏 UI (Doctor, REPL, Resume)
├── types/                   # TypeScript 类型定义
├── utils/                   # 工具函数
│
├── bridge/                  # IDE 和远程控制桥接
├── coordinator/             # 多 Agent 协调器
├── plugins/                 # 插件系统
├── skills/                  # 技能系统
├── keybindings/            # 快捷键配置
├── vim/                     # Vim 模式
├── voice/                   # 语音输入
├── remote/                  # 远程会话
├── server/                  # 服务器模式
├── memdir/                  # 持久化内存目录
├── tasks/                   # 任务管理
├── state/                   # 状态管理
├── migrations/              # 配置迁移
├── schemas/                 # 配置 schema (Zod)
├── entrypoints/             # 初始化逻辑
├── ink/                     # Ink 渲染器包装
├── buddy/                   # 伙伴精灵
├── native-ts/               # 原生 TypeScript 工具
├── outputStyles/            # 输出样式
├── query/                   # 查询管道
└── upstreamproxy/          # 代理配置
```

## 核心系统

### 1. 工具系统 (`src/tools/`)

每个 Claude Code 可调用的工具都实现为自包含模块。

| 工具 | 描述 |
|------|------|
| `BashTool` | Shell 命令执行 |
| `FileReadTool` | 文件读取 (图片, PDF, notebooks) |
| `FileWriteTool` | 文件创建/覆盖 |
| `FileEditTool` | 部分文件修改 (字符串替换) |
| `GlobTool` | 文件模式匹配搜索 |
| `GrepTool` | ripgrep 内容搜索 |
| `WebFetchTool` | 获取 URL 内容 |
| `WebSearchTool` | 网络搜索 |
| `AgentTool` | 子 Agent 生成 |
| `SkillTool` | 技能执行 |
| `MCPTool` | MCP 服务器工具调用 |
| `LSPTool` | 语言服务器协议集成 |
| `NotebookEditTool` | Jupyter notebook 编辑 |
| `TaskCreateTool` / `TaskUpdateTool` | 任务创建和管理 |
| `SendMessageTool` | Agent 间消息 |
| `TeamCreateTool` / `TeamDeleteTool` | 团队 Agent 管理 |
| `EnterPlanModeTool` / `ExitPlanModeTool` | 计划模式切换 |
| `EnterWorktreeTool` / `ExitWorktreeTool` | Git worktree 隔离 |
| `ToolSearchTool` | 延迟工具发现 |
| `CronCreateTool` | 定时触发器创建 |
| `RemoteTriggerTool` | 远程触发器 |
| `SleepTool` | 主动模式等待 |
| `SyntheticOutputTool` | 结构化输出生成 |

### 2. 命令系统 (`src/commands/`)

用户可调用的斜杠命令 (`/` 前缀)。

| 命令 | 描述 |
|------|------|
| `/commit` | 创建 git 提交 |
| `/review` | 代码审查 |
| `/compact` | 上下文压缩 |
| `/mcp` | MCP 服务器管理 |
| `/config` | 设置管理 |
| `/doctor` | 环境诊断 |
| `/login` / `/logout` | 认证 |
| `/memory` | 持久化内存管理 |
| `/skills` | 技能管理 |
| `/tasks` | 任务管理 |
| `/vim` | Vim 模式切换 |
| `/diff` | 查看变更 |
| `/cost` | 检查使用成本 |
| `/theme` | 更改主题 |
| `/context` | 上下文可视化 |
| `/pr_comments` | 查看 PR 评论 |
| `/resume` | 恢复上一个会话 |
| `/share` | 分享会话 |
| `/desktop` | 桌面应用切换 |
| `/mobile` | 移动应用切换 |

### 3. 服务层 (`src/services/`)

| 服务 | 描述 |
|------|------|
| `api/` | Anthropic API 客户端, 文件 API, bootstrap |
| `mcp/` | Model Context Protocol 服务器连接和管理 |
| `oauth/` | OAuth 2.0 认证流程 |
| `lsp/` | 语言服务器协议管理器 |
| `analytics/` | GrowthBook 特性开关和分析 |
| `plugins/` | 插件加载器 |
| `compact/` | 会话上下文压缩 |
| `policyLimits/` | 组织策略限制 |
| `remoteManagedSettings/` | 远程托管设置 |
| `extractMemories/` | 自动记忆提取 |
| `tokenEstimation.ts` | Token 计数估算 |
| `teamMemorySync/` | 团队记忆同步 |

### 4. 桥接系统 (`src/bridge/`)

连接 IDE 扩展 (VS Code, JetBrains) 与 Claude Code CLI 的双向通信层。

- `bridgeMain.ts` — 桥接主循环
- `bridgeMessaging.ts` — 消息协议
- `bridgePermissionCallbacks.ts` — 权限回调
- `replBridge.ts` — REPL 会话桥接
- `jwtUtils.ts` — 基于 JWT 的认证
- `sessionRunner.ts` — 会话执行管理

### 5. 权限系统 (`src/hooks/toolPermission/`)

检查每个工具调用的权限。根据配置的权限模式 (`default`, `plan`, `bypassPermissions`, `auto` 等) 提示用户批准/拒绝或自动解析。

## 代码风格分析

### 导入顺序规范
```typescript
// 1. 必须最先运行的效果 (在所有其他导入之前)
import { profileCheckpoint, profileReport } from './utils/startupProfiler.js';
import { startMdmRawRead } from './utils/settings/mdm/rawRead.js';
import { startKeychainPrefetch } from './utils/secureStorage/keychainPrefetch.js';

// 2. 特性开关条件导入 (构建时消除死代码)
import { feature } from 'bun:bundle';
const voiceCommand = feature('VOICE_MODE')
  ? require('./commands/voice/index.js').default
  : null;

// 3. 第三方库
import React from 'react';
import chalk from 'chalk';

// 4. 内部模块
import { getTools } from './tools.js';
import type { ToolInputJSONSchema } from './Tool.js';
```

### 工具定义模式
```typescript
import { buildTool, type ToolDef } from '../../Tool.js';
import { z } from 'zod/v4';

export const BashTool = buildTool({
  name: BASH_TOOL_NAME,
  description: 'Execute shell commands',
  
  inputSchema: z.object({
    command: z.string(),
    timeout: z.number().optional(),
  }),
  
  renderMessage: (params) => ...,    // UI 渲染
  execute: async (params, context) => ...,  // 执行逻辑
});
```

### 组件模式 (Ink/React)
```typescript
import * as React from 'react';
import { Text, Box } from 'ink';

export function BashToolUI({ result, progress }: Props): React.ReactNode {
  return (
    <Box>
      <Text>Command: {result.command}</Text>
      {progress && <Text color="yellow">Running...</Text>}
    </Box>
  );
}
```

### 错误处理模式
```typescript
import { isENOENT, ShellError } from '../../utils/errors.js';

try {
  const result = await exec(command);
  return { success: true, data: result };
} catch (error) {
  if (isENOENT(error)) {
    return { success: false, message: 'File not found' };
  }
  throw error;
}
```

### 进度报告模式
```typescript
const PROGRESS_THRESHOLD_MS = 2000; // 2秒后显示进度

export function isSearchOrReadBashCommand(command: string): {
  isSearch: boolean;
  isRead: boolean;
  isList: boolean;
} {
  // 检测命令类型
}
```

## 关键设计模式

### 1. 构建器模式 (Tool)
```typescript
export function buildTool<T extends ToolDef>(definition: T): ToolImpl<T>
```

### 2. 注册表模式 (Commands/Tools)
```typescript
// commands.ts
export const commands: CommandMap = {};
export function getCommands(): Command[] { ... }

// tools.ts
export const tools: ToolMap = {};
export function getTools(): Tool[] { ... }
```

### 3. 特性开关 (Dead Code Elimination)
```typescript
import { feature } from 'bun:bundle';
const coordinatorModule = feature('COORDINATOR_MODE')
  ? require('./coordinator/coordinatorMode.js')
  : null;
```

### 4. 延迟导入 (循环依赖)
```typescript
const getTeammateUtils = () => require('./utils/teammate.js');
```

### 5. 权限检查链
```typescript
// hooks/toolPermission/handlers/
export async function handleToolPermission(
  tool: Tool,
  params: unknown,
  context: ToolContext
): Promise<PermissionResult> { ... }
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | TypeScript |
| 运行时 | Bun |
| CLI 框架 | Commander.js |
| UI 框架 | React + Ink |
| 数据验证 | Zod v4 |
| 样式 | chalk (ANSI 颜色) |
| 持久化 | 文件系统 + JSON |
| 进程管理 | 原生 Node.js |
| 测试 | (未分析) |

## 安全设计

### 权限模型
- `default`: 每次提示
- `plan`: 仅在计划模式提示
- `bypassPermissions`: 跳过提示
- `auto`: 自动批准安全命令

### 沙箱
- `shouldUseSandbox()` 检测
- `SandboxManager` 隔离执行

### 路径验证
- `pathValidation.ts` 路径安全检查
- `filesystem.ts` 文件系统权限

## 可借鉴的规范

### 1. 入口文件规范 (`main.tsx`)
```typescript
// 1. profileCheckpoint 最先
profileCheckpoint('main_tsx_entry');
// 2. 启动并行预取
startMdmRawRead();
startKeychainPrefetch();
// 3. 延迟导入循环依赖
const getTeammateUtils = () => require('./utils/teammate.js');
```

### 2. 工具模块结构
```
tools/
├── BashTool/
│   ├── BashTool.tsx       # 主工具
│   ├── UI.tsx             # 渲染组件
│   ├── prompt.ts          # 提示词
│   ├── bashPermissions.ts # 权限
│   ├── bashSecurity.ts    # 安全
│   ├── commandSemantics.ts # 命令语义
│   └── utils.ts           # 工具函数
```

### 3. 组件结构
```
components/
├── ComponentName/
│   ├── ComponentName.tsx
│   ├── SubComponent.tsx
│   └── index.ts
```

### 4. 常量定义
```typescript
// constants/tools.ts
export const TOOL_SUMMARY_MAX_LENGTH = 2000;

// 命名规范: 大写下划线
const PROGRESS_THRESHOLD_MS = 2000;
const BASH_SEARCH_COMMANDS = new Set([...]);
```

### 5. 类型导出
```typescript
// Tool.ts
export type ToolInputJSONSchema = { ... }

// 集中导出 progress 类型
export type {
  AgentToolProgress,
  BashProgress,
  MCPProgress,
};
```

## 与 Media Matrix 项目的区别

| 方面 | Claude Code | Media Matrix |
|------|-------------|--------------|
| 架构 | 单体 CLI | 微服务 Docker |
| 并发 | 事件循环 | Redis 队列 |
| 通信 | 内存/管道 | HTTP/WS |
| 部署 | 本地安装 | 容器编排 |
| 规模 | 1900 文件 | 8 个 Agent |
| UI | Ink TUI | 无 UI |
