# DeepSeek-V4-Pro Optimization for Superpowers Fork

**Date:** 2026-05-16
**Status:** Draft
**Fork:** `gylove1994/superpowers-deepseek-v4`

## Problem

This fork targets deepseek-v4-pro 在执行"架构、设计、审查"任务时的低评分问题。三个具体观察：

1. **单上下文盲区** — ds 在长 spec/plan 编写中倾向陷入局部最优，缺少"跳出当前思路"的能力
2. **缺乏稳定参考** — ds 在没有高质量参考样例时，产出风格与严谨度波动大
3. **自审浅尝辄止** — ds 自己做 reviewer 时常重复自己的盲点

现有 superpowers 的 `brainstorming` / `writing-plans` 流程使用单一 reviewer + 一次性评审，对上述问题适应不足。

## Goals

1. 通过**模范样本对齐**机制，让 ds 在 spec/plan 编写时主动参考高质量样例，reviewer 也用样例作为基准
2. 通过**多 reviewer 独立并行评审 + 多轮迭代收敛**，规避单上下文盲区
3. 通过**完整状态追踪文件**，使工作过程对人类可见、可恢复、可监督
4. 显式区分 brainstorming 中"与用户对齐"和"spec 编写"两阶段
5. 仅覆盖 spec + plan 两阶段。execute 阶段（subagent-driven-development）维持上游设计不变

## Non-Goals

- **能力自进化系统**（lessons-learned + 剪枝 + 角色分类访问）— 独立为 Spec B，依赖本 spec 实施完成
- **客观打分/评分基线工具** — 人工监督已足够
- **subagent-driven-development 改造** — 范围之外
- **visual-companion 改动** — 与本次无关
- **上游同步能力** — 已决定不再保留，本 fork 自由演进
- **reviewer prompt 措辞精细 tuning** — 先实现基础版，真实使用后再 tune

## Design Principles

### 多上下文独立 reviewer 规避单上下文盲区

4~6 个独立 reviewer subagent（4 固定 + N 动态样本对照员，N=0/1/2）由完全隔离的 context 承载，各自从不同视角（架构 / 红队 / 边界 / YAGNI / 样本对照）审视同一份 draft。这是规避 ds 单 context 盲区的核心机制。

### 元代理是过滤与裁决者，不是合并者

元代理（arbiter）的职责不是"把 5 个 reviewer 的意见拼起来"，而是：去重、去伪、冲突裁决、降级压缩。这避免把所有 reviewer 的水量都堆给 ds。

### 用户主动 vs 自动化的清晰边界

样本库的"加料"工作完全用户主动（不询问、不推荐）。brainstorming/writing-plans 流程内部完全自动（包括 resume、reviewer 调度、收敛判定），仅在必要决策点暂停等用户。

### Progress 文件是单一信息源

中间过程不 commit。所有状态（reviewer 派发、回执、finding、arbiter 裁决、ds 修订状态）全部记录在 progress 文件本身，不依赖 git 历史追溯。仅在 Status 转为 Done / Abandoned 时一次性 commit。

### 显式 Phase 划分

brainstorming 显式分 **Phase A**（人机对齐）+ **Phase B**（ds 写 spec + reviewer 评审），职责清晰，转换需用户确认。writing-plans 单 Phase（spec 已 Done 是前置条件）。

### 自由 fork，不再同步上游

可大改既有 SKILL.md，删除/替换上游设计，按本 fork 的优化目标演进。

### SKILL 文件与 prompt 模板一律使用英语

所有 `skills/**/SKILL.md`、prompt 模板（reviewer prompts、arbiter prompt、conflict-detection prompt、index-entry-schema 等）、文件模板示范文件（`skills/resume-*/templates/*`）均使用英语编写。这保持与上游 superpowers 一致的工程约定，且大语言模型（包括 deepseek-v4-pro）对英语 prompt 的指令遵循稳定性更高。

**例外**：运行时由用户输入或 ds 生成的内容（决策日志中的 Q&A 文本、finding 的 problem/evidence/suggestion 字段值、用户介入决策的理由等）保持用户使用的语言，由 ds 自动判定。**框架/字段名永远是英语，内容可以是任何语言。**

## Design

### A. 多 reviewer 评审子系统（`skills/multi-reviewer/`）

由 brainstorming（Phase B）与 writing-plans 在产出 spec/plan draft 后调用。纯 prompt 模板系统，无可执行代码。

#### A.1 Finding 四件套 schema

每条 finding 必须按结构化格式输出。缺任一项 → 元代理丢弃。

```yaml
severity: BLOCKING | IMPORTANT | NIT
location: <章节/段落/原文摘引>
problem: <一句问题陈述>
evidence: <为什么是问题——可引用样本、可引用规范>
suggestion: <最小修复建议>
reviewer_role: <架构师|红队|边界|YAGNI|样本对照员>
```

Reviewer 必须用 YAML block 输出 findings 数组。若无 BLOCKING/IMPORTANT 问题，必须明确输出 `NO_BLOCKING_ISSUES: true`。

#### A.2 5 类 reviewer 的角色与边界

| Reviewer | 关注维度 | 禁止越界 |
|---|---|---|
| **架构师** | 模块化、边界、接口、依赖、可演进性、扩展点 | 实现细节、文风、语法 |
| **红队** | 找反例与不可行场景；**必须给出具体失败用例**（不能只说"可能失败"） | 改进建议（只描述漏洞，让其他人补） |
| **边界条件** | 异常路径、并发、容错、回退、降级、空状态、上限值 | 架构、文风 |
| **YAGNI 守门员** | 删冗余、反 scope creep、标记"现在不必要"的内容 | 加东西的建议 |
| **样本对照员** | 按指定样本作基准比对结构完整性与缺失项 | 不引用样本具体段落就提建议（否则元代理丢弃） |

每 reviewer 的 NIT 上限：**3 条**，超出被元代理截断（抑制水量的硬约束）。

#### A.3 reviewer 数量动态化

样本对照员的数量 = 命中样本数。其余 4 reviewer 固定参与。

| 命中样本数 | 总 reviewer 数 | 样本对照员 |
|---|---|---|
| 0 | 4 | 不启用 |
| 1 | 5 | 1 个，对应该样本 |
| 2 | 6 | 2 个，各对应一个样本 |

`exemplar-matcher.md` 是**参数化模板**——派发时填入"被对照的样本文件名 + 该样本全文"。每个对照员只负责一个样本，避免在多样本之间切换造成判断模糊。

#### A.4 元代理（arbiter）

输入：所有 reviewer 的输出 + 当前 draft + 当前轮数 + 上一轮 `BLOCKING+IMPORTANT` 数量。

任务（按顺序执行）：

1. **去重** — 多 reviewer 提同一问题 → 合并为 1 条，标注"被 N 个 reviewer 同时提出"（提升优先级信号）
2. **去伪** — 缺四件套任一项 → 丢弃
3. **冲突裁决** — A 说加 X、B 说删 X → 二选一并附理由
4. **降级压缩** — 只把 `BLOCKING + IMPORTANT` 喂给 ds 修订；`NIT` 仅入附录
5. **退化检测** — 本轮有效 finding 数 ≤ 上轮 50%？若否，触发 `STOP_DEGENERATE`
6. **判定收敛状态** — `CONTINUE` / `STOP_CONVERGED` / `STOP_DEGENERATE` / `STOP_LIMIT` 之一

输出格式：

```yaml
round: <N>
counts:
  raw: <从 reviewer 收到的原始数量>
  after_dedup: <去重后>
  after_filter: <去伪后>
  blocking: <数>
  important: <数>
  nit: <数>
degradation_check: PASSED | FAILED | N/A   # round=1 时 N/A
convergence_status: CONTINUE | STOP_CONVERGED | STOP_DEGENERATE | STOP_LIMIT
revision_instructions:
  - finding_id: <F<round>.<id>>
    action_required: <必须做的修订>
unresolved_carried: []   # 上轮未解决但本轮没复现的项
arbiter_rationale: <一段简短理由>
```

#### A.5 收敛算法（伪代码）

```
ROUND = 1
prev_total = +infinity

LOOP:
  draft = (ROUND == 1) ? ds_initial_draft : ds_revised_draft
  reviewer_outputs = parallel_dispatch(draft, samples_if_hit)
  arbiter_output = arbiter(reviewer_outputs, ROUND, prev_total)

  IF arbiter_output.convergence_status == STOP_CONVERGED:    # B+I = 0
    BREAK   # 成功收敛

  IF arbiter_output.convergence_status == STOP_DEGENERATE:   # 退化触发
    BREAK   # 强制停止 → 用户裁决

  IF ROUND >= 3:                                              # 硬上限
    arbiter_output.convergence_status = STOP_LIMIT
    BREAK

  ds_revised_draft = ds.revise(draft, arbiter_output.revision_instructions)
  prev_total = arbiter_output.blocking + arbiter_output.important
  ROUND += 1

IF stop_status in [STOP_DEGENERATE, STOP_LIMIT] AND has_unresolved:
  user_arbitration(arbiter_output)   # 把未解决项呈给用户拍板
```

#### A.6 调度模型

multi-reviewer 是纯 prompt 系统，"并行派发"由调用方（brainstorming 或 writing-plans 的主流程 agent，即 ds 自己）通过 subagent 工具实现：

1. 主流程 agent **以 controller 身份**用 Task 工具并行派发 4~6 个 reviewer subagent
2. 收集回执后，**派发第 N+1 个 subagent**（arbiter），喂入回执 + draft + round 信息
3. 收到 arbiter 输出后：
   - `STOP_CONVERGED` → 退出循环，进入下一阶段
   - `STOP_DEGENERATE` / `STOP_LIMIT` → 把未解决项呈给用户拍板
   - `CONTINUE` → 主流程 agent **以 ds 身份**按 revision_instructions 修订 draft → 进入下一轮

主流程 agent 在评审循环中身兼二职——既是 controller，又是 ds。subagent 只承担 reviewer 与 arbiter，其 context 完全隔离，不继承主流程历史。

#### A.7 文件清单

```
skills/multi-reviewer/
├── SKILL.md                          # 触发、流程、调度模型说明
├── finding-schema.md                 # A.1 schema 规范
├── convergence-rules.md              # A.5 伪代码 + 5 层规则解释
├── arbiter-prompt.md                 # A.4 完整 prompt 模板
└── reviewer-prompts/
    ├── architect.md
    ├── red-team.md
    ├── edge-cases.md
    ├── yagni-gatekeeper.md
    └── exemplar-matcher.md           # 参数化模板
```

### B. 模范样本库 + 管理 SKILL

#### B.1 样本库目录与元数据

```
samples/
├── README.md                         # 总览 + 给 ds 看的查找规则说明
├── specs/
│   ├── INDEX.md                      # 元数据表（每条 YAML 块）
│   └── <date>-<topic>.md
└── plans/
    ├── INDEX.md
    └── <date>-<topic>.md
```

`INDEX.md` 中每个样本对应一个 YAML 块：

```yaml
- file: 2026-04-06-worktree-rototill-design.md
  topic: <主题简述，一句>
  domain: <领域分类，如 "hook 设计" / "skill 设计" / "插件兼容性">
  scale: small | medium | large
  characteristics:
    - <关键特征 1>
    - <关键特征 2>
  problem_summary: <一句话：这个 spec/plan 解决了什么问题>
  why_exemplar: <为什么是模范——结构完整？严谨？清晰？>
```

`why_exemplar` 是关键字段：告诉 ds 与 reviewer "学什么"。

#### B.2 样本文件本身

**保留原貌，不做清洗。** 项目专属路径与具体细节都保留——真实产出比"灭菌后的范本"更有教学价值。仅在初始化时遇到明显临时标注（如 `TBD`、`XXX`）由用户决定是否删。

#### B.3 ds 运行时查找匹配的样本

写 spec/plan 初稿前，主流程 agent 执行：

1. 读 `samples/specs/INDEX.md`（或 plans/）
2. 把当前用户需求与每条元数据做语义匹配
3. 选出最相关的样本：**注入上限 2 个**（避免 context 爆炸）
4. 输出"已选 X、Y 作为参考，理由是…"给用户，**默认前进**，用户**可以**否决/调整
5. 如果 **0 命中** → 跳过样本注入，本次跑无样本流程，样本对照员 reviewer 不启用

| 命中数量 | ds 注入数量 | 样本对照员 reviewer |
|---|---|---|
| 0 | 0 | 不启用（仅 4 reviewer） |
| 1 | 1 | 启用，1 个 |
| 2 | 2 | 启用，2 个 |
| 3+ | ds 挑最相关的 2 个并解释理由 | 启用（用挑选后的样本） |

#### B.4 `skills/managing-samples/` 工作流

**触发：仅用户主动。** 模型不自动询问、不主动推荐。两种形态：

##### 形态 1：一次性初始化（仅做一次）

用户说"初始化样本库"或类似：

1. 扫描 `docs/superpowers/specs/` + `docs/superpowers/plans/`
2. 对每个文件：ds 阅读后**自动推断**元数据 → 呈现给用户校对/修改
3. **全局冲突扫描**：N×N 比对，列出所有冲突/重复对
4. 用户批量裁决（每对 3 选 1）
5. 按裁决执行：复制 / 跳过 / 删除
6. 写入 INDEX
7. 一次性 commit：`feat(samples): seed initial sample library`

##### 形态 2：单个提升（任意时刻）

用户说"把 <文件> 加进样本"或"把刚才那个 spec 提升为样本"：

1. ds 阅读源文件，**先推荐**元数据 → 用户确认/调整
2. **冲突扫描**：与现有 INDEX 全部条目比对，输出重复候选 + 冲突候选
3. 若有 → 三选一裁决：

| 选项 | 含义 |
|---|---|
| 保留新、删旧 | 复制新样本 + 从 samples/ 删除旧文件 + 从 INDEX 删除旧条目 |
| 保留旧、放弃新 | 不复制新样本，结束本次 |
| 两者都保留 | 用户判断"实际不冲突"——按原流程继续 |

4. 复制源文件到 `samples/specs|plans/`
5. INDEX append 新条目
6. commit：`feat(samples): add <topic> as exemplar`

#### B.5 冲突扫描标准

ds 读取**现有 INDEX 全部条目 + 新候选条目**，输出两类候选：

- **重复候选** — 相同 domain + 高度相似的 characteristics + problem_summary
- **冲突候选** — 相同问题（problem_summary 相似）但 characteristics 暗示对立方案

#### B.6 文件清单

```
samples/
├── README.md
├── specs/
│   ├── INDEX.md
│   └── *.md
└── plans/
    ├── INDEX.md
    └── *.md

skills/managing-samples/
├── SKILL.md
├── index-entry-schema.md
└── conflict-detection-prompt.md
```

### C. 决策日志（brainstorming）

#### C.1 文件位置与命名

`docs/superpowers/brainstorms/YYYY-MM-DD-<topic-slug>-brainstorm.md`

`<topic-slug>` 由 ds 从用户原 query 总结后让用户确认（在第一次 append 前确认）。

#### C.2 完整模板（Phase A + Phase B 一体化）

```markdown
# Brainstorming: <topic>

**Date Started:** YYYY-MM-DD
**Status:** In Progress | Done | Abandoned
**Current Phase:** alignment | spec_writing | review_round_N | awaiting_user_decision | finalizing
**Based On:** <previous brainstorm filename>   # only when continuing
**Final Spec:** <spec path>                    # filled when Done
**Last Updated:** YYYY-MM-DD HH:MM

## Original User Request

> <user's first message verbatim>

---

## Phase A: Alignment Decision Log

### Q1: <question summary>
**Options Presented:**
- A: ...
- B: ...
**Decision:** B
**Rationale:** <user rationale or accepted recommendation>
**Timestamp:** YYYY-MM-DD HH:MM

### Q2: ...

### Phase A → B Transition Confirmation [timestamp]
**Alignment Summary (compiled by ds):**
- Decision 1: ...
- Decision 2: ...

**User Confirmation:** ✓ Confirmed / Needs more (back to Phase A Q<n+1>)

---

## Phase B: Spec Writing Status

- [✓] Initial draft complete (time: ...)
- [✓] Round 1 revision   (time: ...)
- [⏳] Round 2 revision
- [ ] Final sign-off

## Phase B Review Progress

### Round 1 [✓ Complete]

**Dispatched reviewers (5):** architect | red-team | edge-cases | yagni | exemplar-matcher(sample-1)

**Receipt Status:** architect ✓ | red-team ✓ | edge-cases ✓ | yagni ✓ | exemplar-matcher ✓

**Findings:**

| ID | Sev | Location | Reviewer | Problem | Arbiter | Status |
|----|-----|----------|----------|---------|---------|--------|
| F1.1 | B | §X | architect | ... | KEEP | ✓ FIXED |
| F1.2 | I | §Y | red-team | ... | KEEP | ✗ USER_REJECTED(I1) |
| F1.3 | I | §Z | edge-cases | ... | KEEP | ✓ FIXED |
| F1.4 | I | §W | yagni | sub-task c removable | MERGED into F1.5 | (MERGED) |
| F1.5 | I | §W | architect | sub-task c boundary unclear | KEEP | ✓ FIXED |
| F1.6 | I | §X | red-team | duplicate of F1.1 | DEDUP_DISCARDED | - |
| F1.7 | I | §Goals | exemplar | missing evidence | FALSE_DISCARDED | - |
| F1.8 | N | §Header | architect | table misaligned | APPENDIX | (NIT) |

**Arbiter Output:**
- counts: raw=12 → dedup=10 → after_filter=8 (B=1, I=4, N=3)
- degradation_check: N/A (Round 1)
- convergence_status: CONTINUE
- arbiter_rationale: Task granularity issues critical; F1.2 needs user decision due to boundary condition trade-off

### Round 2 [⏳ In Progress]
...

---

## Phase B User Intervention Decisions

### I1 [✓ Decided]
**Triggered in round:** Round 1
**Related finding:** F1.2
**Reason for intervention:** F1.2 has revision options A/B; arbiter determined user must decide
**Options Presented:**
- A: ...
- B: ...
**User Decision:** B
**Rationale:** ...
**Timestamp:** ...
```

#### C.3 字段枚举值（英语，由模板规定）

| 字段 | 取值 |
|---|---|
| Sev | B (BLOCKING) / I (IMPORTANT) / N (NIT) |
| Arbiter | KEEP / MERGED into F\<x.y\> / DEDUP_DISCARDED / FALSE_DISCARDED / APPENDIX |
| Status | ✓ FIXED / ⏳ PENDING / ✗ USER_REJECTED(I\<x\>) / (MERGED) / (NIT) / - |

#### C.4 Append 触发点

| 触发点 | 写入内容 |
|---|---|
| brainstorming 启动 | 创建文件 + 写 metadata + 用户原始需求 |
| Phase A 每问答一轮 | append 该 Q 的"问题 + 选项 + 决定 + 理由 + 时间戳" |
| Phase A → B 转换 | append "对齐结论摘要" + 用户确认状态 |
| Phase B 初稿完成 | 更新"Spec 编写状态"段 |
| Round N 派发 | 写入 reviewer 名单 + "回执状态：全部 ⏳" |
| 每 reviewer 回执 | 更新该 reviewer 状态 ✓ + append 其 finding 到表格 |
| Arbiter 运行后 | 填入"Arbiter 裁决"列 + "Arbiter 输出"段 + 更新 convergence_status |
| ds 修订后 | 更新对应 finding 的"处理状态" |
| 用户介入决策 | 写入 I\<x\> 段 + 更新关联 finding 的"处理状态"为"用户驳回(I\<x\>)" |
| Phase 转换 | 更新 metadata 的 Current Phase |
| Status → Done/Abandoned | 一次性 `git add` + commit 整个文件 |

中间过程一律不 commit，仅 Status 终态时一次性 commit。

#### C.5 Status / Current Phase 状态机

```
Status: (初始) → In Progress → Done       (spec 收敛 + 用户签字)
                              → Abandoned  (用户放弃)

Current Phase 在 Status=In Progress 时取值:
  alignment → spec_writing → review_round_N → [awaiting_user_decision] → finalizing
                          ↑                  ↓
                          └─── ds 修订 ─────┘
```

### D. 进度追踪（writing-plans）

#### D.1 文件位置与命名

`docs/superpowers/brainstorms/YYYY-MM-DD-<topic-slug>-plan-progress.md`

与 brainstorm 文件并列。

#### D.2 完整模板（单 Phase，无对齐阶段）

```markdown
# Plan Progress: <topic>

**Date Started:** YYYY-MM-DD
**Status:** In Progress | Done | Abandoned
**Current Phase:** draft_writing | review_round_N | awaiting_user_decision | finalizing
**Source Spec:** docs/superpowers/specs/...md
**Based On:** <previous plan-progress filename>  # only when continuing
**Final Plan:** <plan path>                       # filled when Done
**Last Updated:** YYYY-MM-DD HH:MM

## Plan Writing Status

- [✓] Initial draft complete (time: ...)
- [✓] Round 1 revision   (time: ...)
- [⏳] Round 2 revision
- [ ] Final sign-off

## Review Progress

### Round 1 [✓ Complete]
[same structure as Phase B Review Progress in C.2]

### Round 2 [⏳ In Progress]
...

## User Intervention Decisions

### I1 [...]
...

## Context Reference

### Source Spec Summary
> <extracted problem + goals from source spec>

### User's Launch Instruction
> <original message>
```

#### D.3 与 brainstorm 文件的差异

- 无 Phase A（对齐阶段）— planning 启动必须有 Done 的 spec 作为输入
- Current Phase 取值缺 `alignment`：仅 `draft_writing / review_round_N / awaiting_user_decision / finalizing`
- 加 `Source Spec` 必选字段
- 加 `Context Reference` 段（Source Spec Summary + User's Launch Instruction）
- 内容主体不再是 Q&A，而是 Plan Writing Status + Review Progress + User Intervention Decisions

#### D.4 Append 触发点 + commit 时机

与 C.4 中 Phase B 部分相同。同样：中间过程不 commit，仅 Status 终态时一次性 commit。

### E. Resume SKILL（brainstorming + planning）

#### E.1 触发

写入到 `brainstorming/SKILL.md` 和 `writing-plans/SKILL.md` 的**第一步**，作为强制前置。

#### E.2 resume-brainstorming 工作流

1. 扫描 `docs/superpowers/brainstorms/*-brainstorm.md`
2. 按 Status 分类，按时间倒序
3. 呈现给用户 4 选项（仓库为空时自动跳过）：

```
docs/superpowers/brainstorms/ 状态:

In Progress (2):
  [1] 2026-05-15-foo-brainstorm.md   — <topic>  Current Phase: alignment
  [2] 2026-05-14-bar-brainstorm.md   — <topic>  Current Phase: review_round_2

Done (12, 最近 5 个):
  [d1] 2026-05-10-xxx-brainstorm.md  — <topic>
  ...

Abandoned (3):
  [a1] 2026-04-30-yyy-brainstorm.md  — <topic>
  ...

请选择:
  A) 继续 In Progress           → "1" / "2"
  B) 基于某个 Done 开新一轮     → "new based on d1"
  C) 基于某个 Abandoned 开新一轮 → "new based on a1"
  D) 放弃 In Progress           → "abandon 1"
```

4. 按用户选择执行：

| 选项 | 行动 |
|---|---|
| A 继续 X | 读 X 全文 → 主流程 agent 把已有内容载入 context → 从 Current Phase 精确恢复 |
| B 基于 Done Y 开新 | 创建新文件 + `Based On: Y` + 主流程 agent 读 Y 全文作为"已有讨论结果" → 从此基础上开新一轮（不是从零） |
| C 基于 Abandoned Y 开新 | 同 B，附加加载 Y 中的"放弃理由" |
| D 放弃 N | 把 N 的 Status 改为 Abandoned + commit |

仓库为空 → SKILL 返回 "no existing brainstorms, proceed to new" → 主流程创建空白新文件继续。

#### E.3 Current Phase 精确恢复（brainstorm）

| Current Phase | 恢复行为 |
|---|---|
| `alignment` | 读 Phase A 已有 Q&A → 从最后一个 Q 继续 |
| `spec_writing` | 读对齐结论摘要 → 从 draft 继续编写 |
| `review_round_N` | 重派发该 round 的 reviewer（因为中间不 commit，draft 在工作区） |
| `awaiting_user_decision` | 呈现"等待"的 I 项给用户 |
| `finalizing` | 呈现 spec 等签字 |

#### E.4 resume-planning 工作流

#### E.4.1 前置：必选 source spec

planning 启动必须有一个 Done 的 spec 作为输入。resume-planning 第一步：

```
请先选择本次 planning 对应的 source spec:

docs/superpowers/specs/ Done 状态 (15, 最近 5 个):
  [s1] 2026-05-14-foo-design.md
  [s2] ...

输入编号或路径
```

#### E.4.2 然后呈现 resume 菜单

```
docs/superpowers/brainstorms/ 中 source_spec = <你选的> 的 plan-progress 文件:

In Progress (1):
  [1] 2026-05-15-foo-plan-progress.md
      Current Phase: review_round_2
      Last Updated: 2026-05-15 10:30

Done (相同 spec 的, 2):
  [d1] ...

Done (其他 spec 的, 6):
  [d3] ...

Abandoned (1):
  [a1] ...

请选择:
  A) 继续 In Progress (推荐，从 Current Phase 恢复) → "1"
  B) 基于某个 Done 开新一轮                       → "new based on d1"
  C) 基于某个 Abandoned 开新一轮                  → "new based on a1"
  D) 放弃 In Progress                              → "abandon 1"
```

Done/Abandoned 列表标注**是否同一 source spec**（同 spec 在前，跨 spec 借鉴在后）。

#### E.4.3 Current Phase 精确恢复（plan-progress）

| Current Phase | 恢复行为 |
|---|---|
| `draft_writing` | 重读 spec + plan-progress 已记录的 D → 从 draft 继续编写 |
| `review_round_N` | 重派发该 round 的 reviewer |
| `awaiting_user_decision` | 呈现"等待"的 I 项给用户 |
| `finalizing` | 呈现 plan 等签字 |

#### E.5 文件清单

```
skills/resume-brainstorming/
├── SKILL.md
└── templates/
    └── brainstorm-template.md

skills/resume-planning/
├── SKILL.md
└── templates/
    └── plan-progress-template.md
```

### F. 既有 brainstorming / writing-plans 改造点

#### F.1 `skills/brainstorming/SKILL.md` 改造

主要结构性修改：

1. **第一步插入**：调用 `resume-brainstorming` SKILL（强制前置）
2. **Phase A（对齐）**：保留现有"逐个询问问题 + 提出方案"的流程；每问答一轮后，append 决策日志
3. **Phase A → B 转换**：ds 汇总对齐结论摘要 → 用户确认 → 才能进入 Phase B
4. **Phase B（spec 编写）**：
   - ds 读取 `samples/specs/INDEX.md`，匹配并注入样本（上限 2 个）
   - 写 spec draft
   - 调用 `multi-reviewer` 子系统，按 A.5 收敛算法循环
   - 每轮派发/回执/arbiter/修订都同步写入决策日志的"Phase B 评审进度"段
5. **最终签字**：用户签字后 Status → Done，一次性 commit
6. **保留**：`visual-companion.md` 与 `scripts/`（与本次无关）

#### F.2 `skills/brainstorming/spec-document-reviewer-prompt.md` 删除

被 multi-reviewer 子系统取代。

#### F.3 `skills/writing-plans/SKILL.md` 改造

主要结构性修改：

1. **第一步插入**：调用 `resume-planning` SKILL（强制前置，含 source spec 选择）
2. **draft 编写**：
   - ds 读取 `samples/plans/INDEX.md`，匹配并注入样本（上限 2 个）
   - 写 plan draft
3. **评审循环**：调用 `multi-reviewer` 子系统，按 A.5 收敛算法循环
4. **进度追踪**：每动作都同步写入 plan-progress
5. **最终签字**：用户签字后 Status → Done，一次性 commit

#### F.4 `skills/writing-plans/plan-document-reviewer-prompt.md` 删除

被 multi-reviewer 子系统取代。

## Implementation Phases

5 个 Phase，按依赖顺序执行：

### Phase 1：基础设施（样本库 + 多 reviewer）

- 1a. 创建 `samples/` 目录结构 + README + INDEX schema 文档
- 1b. 创建 `skills/managing-samples/` 全部文件（SKILL + index-entry-schema + conflict-detection-prompt）
- 1c. 用 managing-samples 跑一次初始化：把现有 `docs/superpowers/specs/` + `plans/` 共 10 个文件复制到 samples 并写 INDEX
- 1d. 创建 `skills/multi-reviewer/` 全部文件（SKILL + finding-schema + convergence-rules + arbiter-prompt + 5 reviewer-prompts）

**验收**：可独立跑通"用户说：把 X 加入样本"流程；5 个 reviewer prompt 静态审查通过。

### Phase 2：Resume SKILL + 文件模板文档

- 2a. 把 brainstorm 与 plan-progress 文件模板写为参考文档（保存在 `skills/resume-*/templates/`）
- 2b. 创建 `skills/resume-brainstorming/SKILL.md`
- 2c. 创建 `skills/resume-planning/SKILL.md`

**验收**：手动创建一个假的 In Progress brainstorm 文件，验证 resume 菜单正确呈现。

### Phase 3：改造 brainstorming

- 3a. 重写 `skills/brainstorming/SKILL.md`：加 resume 触发 + Phase A/B 结构 + Phase A→B 转换 + 决策日志写入 + multi-reviewer 调用
- 3b. 删除 `skills/brainstorming/spec-document-reviewer-prompt.md`
- 3c. 保留 `visual-companion.md` 与 `scripts/`

**验收**：跑一次真实 brainstorming session，走完 Phase A + Phase B + 至少 1 轮 reviewer。

### Phase 4：改造 writing-plans

- 4a. 重写 `skills/writing-plans/SKILL.md`：加 resume 触发 + plan-progress 写入 + multi-reviewer 调用
- 4b. 删除 `skills/writing-plans/plan-document-reviewer-prompt.md`

**验收**：用 Phase 3 产出的 spec 跑一次真实 writing-plans session。

### Phase 5：端到端场景验证

跑下面 Testing Strategy 中的 14 个场景。

**验收**：所有核心场景行为符合 spec 描述。

## Testing Strategy

本系统是纯 prompt 模板而非可执行代码，无法用传统单元测试。验证方法：

### 静态审查（structural）

- 每个新 SKILL.md 遵循现有 frontmatter + name + description + 流程图 + Red Flags 格式
- 所有 schema 用 YAML 明确标注

### 行为测试矩阵（真实会话）

| # | 场景 | 验证目的 |
|---|---|---|
| T1 | brainstorming 全流程 → Done | 端到端 Phase A → B → 收敛 |
| T2 | brainstorming 中用户驳回某 finding | I\<x\> 机制 + 处理状态 "✗ 用户驳回(I1)" |
| T3 | brainstorming reviewer 触发退化（人为造 reviewer 持续挑刺） | STOP_DEGENERATE + 用户裁决出口 |
| T4 | brainstorming 走完 3 轮强停 | STOP_LIMIT |
| T5 | brainstorming 中途中断 + resume 继续 | Current Phase 字段恢复精确性 |
| T6 | 基于 Done 文件开新一轮 | Based On + 加载老文件全文 |
| T7 | 基于 Abandoned 文件开新一轮 | Based On + 加载放弃理由 |
| T8 | brainstorming Abandon | Status 转换 + commit |
| T9 | writing-plans 全流程 → Done | plan-progress 端到端 |
| T10 | writing-plans resume | 基于 Current Phase 精确恢复 |
| T11 | 样本库初始化 | managing-samples 形态 1 |
| T12 | 单个样本提升 | managing-samples 形态 2 |
| T13 | 样本冲突检测（人为提交冲突样本） | 冲突扫描 + 三选一裁决 |
| T14 | 0/1/2 命中样本 | reviewer 数量动态 4/5/6 + 样本对照员触发 |

### Dogfooding 测试（最有说服力）

用新的 brainstorming SKILL 去 brainstorm **Spec B（能力自进化系统）**。既验证流程能跑完，又顺便产出 Spec B。这是最真实的 acceptance test。

## File Inventory

| 类型 | 路径 | 操作 |
|---|---|---|
| 新增 | `skills/multi-reviewer/SKILL.md` | 创建 |
| 新增 | `skills/multi-reviewer/finding-schema.md` | 创建 |
| 新增 | `skills/multi-reviewer/convergence-rules.md` | 创建 |
| 新增 | `skills/multi-reviewer/arbiter-prompt.md` | 创建 |
| 新增 | `skills/multi-reviewer/reviewer-prompts/architect.md` | 创建 |
| 新增 | `skills/multi-reviewer/reviewer-prompts/red-team.md` | 创建 |
| 新增 | `skills/multi-reviewer/reviewer-prompts/edge-cases.md` | 创建 |
| 新增 | `skills/multi-reviewer/reviewer-prompts/yagni-gatekeeper.md` | 创建 |
| 新增 | `skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md` | 创建 |
| 新增 | `skills/managing-samples/SKILL.md` | 创建 |
| 新增 | `skills/managing-samples/index-entry-schema.md` | 创建 |
| 新增 | `skills/managing-samples/conflict-detection-prompt.md` | 创建 |
| 新增 | `skills/resume-brainstorming/SKILL.md` | 创建 |
| 新增 | `skills/resume-brainstorming/templates/brainstorm-template.md` | 创建 |
| 新增 | `skills/resume-planning/SKILL.md` | 创建 |
| 新增 | `skills/resume-planning/templates/plan-progress-template.md` | 创建 |
| 新增 | `samples/README.md` | 创建 |
| 新增 | `samples/specs/INDEX.md` | 创建 |
| 新增 | `samples/plans/INDEX.md` | 创建 |
| 新增 | `samples/specs/*.md`（5 个） | Phase 1c 复制 |
| 新增 | `samples/plans/*.md`（5 个） | Phase 1c 复制 |
| 新增 | `docs/superpowers/brainstorms/.gitkeep` | 创建空目录占位 |
| 修改 | `skills/brainstorming/SKILL.md` | 重写主体 |
| 修改 | `skills/writing-plans/SKILL.md` | 重写主体 |
| 删除 | `skills/brainstorming/spec-document-reviewer-prompt.md` | 删除 |
| 删除 | `skills/writing-plans/plan-document-reviewer-prompt.md` | 删除 |

## Out of Scope

- **能力自进化系统**（Spec B 独立）
- **客观评分/打分基线工具**（人工监督已足够）
- **subagent-driven-development 改造**（method 2 只覆盖 spec + plan）
- **visual-companion 改动**（与本次无关）
- **上游同步机制**（已决定不再同步）
- **reviewer prompt 措辞精细 tuning**（先实现基础版，跑几次真实 session 后再 tune）
