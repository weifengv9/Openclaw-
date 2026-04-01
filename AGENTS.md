# AGENTS.md - 工作空间索引

## 启动顺序

1. 读 `SOUL.md` — 我是谁
2. 读 `USER.md` — 我在帮谁
3. 读 `memory/YYYY-MM-DD.md`（今天 + 昨天）

## 核心文件

| 文件 | 作用 |
|------|------|
| `SOUL.md` | 身份与行事风格 |
| `USER.md` | 用户信息与偏好 |
| `MEMORY.md` | 长期记忆（仅主会话） |
| `TOOLS.md` | 本地工具配置 |
| `HEARTBEAT.md` | 定期检查清单 |

## 目录结构

```
workspace/
├── memory/               # 日常记录
│   ├── YYYY-MM-DD.md     # 每日日志
│   ├── MEMORY.md         # 长期记忆
│   └── *.md              # 专题记忆
├── docs/                 # 文档库（真正的内容在这里）
│   ├── agent-team-config.md   # Agent 团队配置
│   ├── design/           # 设计文档
│   ├── architecture/     # 架构文档
│   ├── planning/         # 计划文档
│   ├── research/         # 研究资料
│   ├── templates/        # 模板文件
│   └── standards/        # 各 Agent 验收标准
│       ├── generator-standards.md
│       ├── evaluator-standards.md
│       └── doc-gardener-config.md
└── [根目录文件]          # 配置类文件（少改）
```

## Agent 团队

详见 `docs/agent-team-config.md`

| Agent | 职责 |
|-------|------|
| Coordinator | 协调、分配、最终验收 |
| Generator | 内容生成、代码编写 |
| Evaluator | 质量审查、打分反馈 |
| DocGardener | 文档维护、知识整理 |
| Researcher | 信息检索、资料收集 |

## 验收四维度

1. **质量** — 准确、完整、无错误
2. **原创性** — 独特价值、无重复
3. **工艺** — 结构清晰、格式规范
4. **功能** — 满足需求、可落地

详见 `docs/standards/`

## 规则

- **红线**：不泄露隐私、不乱删文件（用 `trash`）
- **外部操作**（发邮件/发帖）需先确认
- **群聊**：不随便插嘴，Quality > Quantity

## 心跳机制

见 `HEARTBEAT.md`

---
完整内容去对应文件夹找，这里只是索引。
