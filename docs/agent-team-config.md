# Agent 团队配置

> 定义各 Agent 的角色、职责和验收标准

---

## 团队成员

| Agent | 职责 | 工具配置 |
|-------|------|----------|
| **Coordinator** (主) | 协调、分配任务、最终验收 | 全部工具 |
| **Generator** | 内容生成、页面创建、代码编写 | exec, write, read |
| **Evaluator** | 质量审查、反馈打分、功能验证 | exec, read, canvas |
| **DocGardener** | 文档扫描、更新维护、知识整理 | read, write, memory_search |
| **Researcher** | 信息检索、资料收集、对比分析 | agent-browser, tavily_search |

---

## 四个验收维度

| 维度 | 含义 | 最低达标线 |
|------|------|-----------|
| **质量** | 输出准确、无错误、完整 | 90% 正确率 |
| **原创性** | 有独特价值、不重复 | 与库内内容重复率 < 20% |
| **工艺** | 专业程度、结构清晰 | 符合文档规范 |
| **功能** | 满足需求、可落地 | 核心功能 100% 实现 |

---

## 工作流程

```
用户请求
    │
    ▼
Coordinator（接收 + 分析 + 分派）
    │
    ├──► Generator（生成初稿）
    │         │
    │         ▼
    │    Coordinator（检查点1）
    │         │
    │         ├──► 评估不通过 ──► Generator（修正）
    │         │
    │         ▼
    │    Evaluator（质量审查）
    │         │
    │         ├──► 不通过 ──► Generator（修改）
    │         │
    │         ▼
    │    Coordinator（检查点2）
    │         │
    │         ▼
    └────► 用户交付
```

---

## 文档路径规范

| 文档类型 | 存放位置 |
|----------|----------|
| 设计文档 | `docs/design/` |
| 架构文档 | `docs/architecture/` |
| 计划文档 | `docs/planning/` |
| 研究资料 | `docs/research/` |
| 模板文件 | `docs/templates/` |

---

## Agent 间通信

通过 `sessions_send` 工具进行 Agent 间消息传递。

消息格式：
```json
{
  "sessionKey": "agent:generator:default",
  "message": "任务描述 + 验收标准 + 上下文"
}
```
