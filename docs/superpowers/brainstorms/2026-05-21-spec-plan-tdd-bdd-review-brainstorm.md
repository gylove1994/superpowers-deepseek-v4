# Brainstorming: Spec & Plan TDD/BDD Independent Review

**Date Started:** 2026-05-21
**Status:** Done
**Current Phase:** finalizing
**Final Spec:** docs/superpowers/specs/2026-05-21-spec-plan-tdd-bdd-review-design.md
**Last Updated:** 2026-05-21 14:10

## Original User Request

> 给 superpower 的 spec 与 plan 流程 添加 TDD BDD 独立评审

---

## Phase A: Alignment Decision Log

### Q1: TDD/BDD 评审如何嵌入现有流程？
**Options Presented:**
- A: 扩展 multi-reviewer — 新增 tdd-reviewer / bdd-reviewer 作为并行 reviewer，与 architect 等同一轮收敛
- B: 后置专项 loop — multi-reviewer 收敛后再单独跑 TDD/BDD 专项评审
- C: 分阶段不同 reviewer — spec 阶段 BDD、plan 阶段 TDD，不同时出现
**Decision:** A — 扩展 multi-reviewer
**Rationale:** 用户选择 A，与现有并行多 reviewer + arbiter 收敛机制一致，避免额外 loop 增加流程复杂度
**Timestamp:** 2026-05-21 12:00

### Q2: TDD 与 BDD 如何组织 reviewer？
**Options Presented:**
- A: 两个独立 reviewer（tdd-reviewer + bdd-reviewer），prompt 按 spec/plan 文档类型分化
- B: 合并为一个 testability-reviewer
- C: 两个独立 reviewer，但分阶段只启用一个（spec→BDD，plan→TDD）
**Decision:** A — 两个独立 reviewer + 分阶段 prompt 变体
**Rationale:** 用户采纳 agent 推荐：BDD/TDD 职责边界清晰，与 multi-reviewer「窄职责 + arbiter 去重」哲学一致；spec/plan 均派发两者，checklist 随文档类型切换
**Timestamp:** 2026-05-21 12:15

### Q3: tdd-reviewer 对非代码任务的处理边界？
**Options Presented:**
- A: 严格 TDD 门禁 — 无 RED→GREEN 即 BLOCKING；skill/prompt 也必须写 agent behavior test
- B: 分层规则 — 代码任务强制 RED→GREEN→REFACTOR；skill/prompt/文档任务允许 structure self-check 或 behavior-test 替代，但必须有可验证通过标准
- C: 仅 advisory — 非代码任务 tdd-reviewer 只出 IMPORTANT/NIT，不出 BLOCKING
**Decision:** B — 分层规则
**Rationale:** 用户选择 B；与现有 writing-plans 约定一致，保持 TDD 纪律同时避免 skill 类改动被伪单元测试卡死
**Timestamp:** 2026-05-21 12:20

### Q4: bdd-reviewer 的验收标准格式？
**Options Presented:**
- A: 严格 Gherkin — 必须 Given/When/Then 结构，不符合即 BLOCKING
- B: 灵活可测即可 — 任意格式，只要可观测、可判定通过/失败
- C: 分层 — 用户-facing 行为要求 Gherkin；内部/技术 criteria 允许 bullet
**Decision:** A — 严格 Gherkin
**Rationale:** 用户选择 A；bdd-reviewer 以 Given/When/Then 为硬性格式要求
**Timestamp:** 2026-05-21 12:25

### Q5: 是否在 spec/plan 模板中强制 Gherkin 章节？
**Options Presented:**
- A: 模板 + reviewer 双管齐下 — spec 新增 `## Acceptance Scenarios`；plan 每 Task 新增 `**Acceptance Criteria:**`（Gherkin）；SKILL 写 draft 时必须填充；bdd-reviewer 复核
- B: 仅 reviewer enforcement — 不改模板，评审时要求补 Gherkin
- C: 仅 spec 改模板，plan 靠 reviewer — spec 有 Gherkin 章节；plan Task 通过 reviewer 引用 spec 场景
**Decision:** A — 模板 + reviewer 双管齐下
**Rationale:** 用户选择 A；严格 Gherkin 需模板锚点，减少 review 轮才补格式的返工
**Timestamp:** 2026-05-21 12:30

### Q6: 范围边界（Non-Goals）？
**Options Presented:**
- A: 仅 spec + plan 阶段 — 改 multi-reviewer/brainstorming/writing-plans/模板/prompt；execute 阶段不动；test-driven-development SKILL 不改，仅引用
- B: 延伸到 execute 阶段 — 实现任务执行时也派 TDD/BDD reviewer
- C: 仅 plan 阶段 — spec 保持现有 4+0–2 reviewer
**Decision:** A — 仅 spec + plan 阶段
**Rationale:** 用户选择 A；与 fork 设计「仅覆盖 spec + plan，execute 维持不变」一致
**Timestamp:** 2026-05-21 12:35

### Q7: 收敛规则是否随 reviewer 数量调整？
**Options Presented:**
- A: 保持现有收敛规则不变 — 50% degradation、3 轮 hard cap、NIT 上限 3/reviewer
- B: 放宽 degradation 阈值 — 50% → 60%
- C: 增加轮次上限 — 3 轮 → 4 轮
**Decision:** A — 保持现有收敛规则不变
**Rationale:** 用户选择 A；增量 findings 靠 arbiter 去重吸收，避免过早放宽质量门禁
**Timestamp:** 2026-05-21 12:40

### Phase A → B Transition Confirmation [2026-05-21 12:40]
**Alignment Summary (compiled by ds):**
- **集成方式：** 扩展 `multi-reviewer`，新增 `tdd-reviewer` + `bdd-reviewer` 作为第 5/6 个固定并行 reviewer，与 architect/red-team/edge-cases/yagni 同一轮收敛
- **Reviewer 组织：** 两个独立 reviewer；prompt 按文档类型分化（spec-draft / plan-draft 两套 checklist）
- **tdd-reviewer 边界：** 分层规则 — 代码任务强制 RED→GREEN→REFACTOR；skill/prompt/文档任务允许 structure self-check 或 behavior-test 替代，但必须有可验证通过标准
- **bdd-reviewer 格式：** 严格 Gherkin（Given/When/Then），不符合即 BLOCKING
- **模板改动：** spec 新增 `## Acceptance Scenarios`（Gherkin）；plan 每 Task 新增 `**Acceptance Criteria:**`（Gherkin）；`brainstorming` / `writing-plans` SKILL 写 draft 时必须填充
- **范围：** 仅 spec + plan 阶段；execute（subagent-driven-development / executing-plans）不动；`test-driven-development` SKILL 不改，仅在新 reviewer prompt 中引用
- **收敛规则：** 保持 50% degradation、3 轮 cap、NIT 上限 3/reviewer 不变

**User Confirmation:** ✓ Confirmed

---

## Phase B: Spec Writing Status

- [x] Initial draft complete (time: 2026-05-21 12:50)
- [x] Round 1 revision
- [x] Round 2 revision
- [ ] Round 3 revision
- [x] Final sign-off

## Phase B Review Progress

**Selected samples:** `2026-01-22-document-review-system-design.md`, `2026-04-06-worktree-rototill-design.md`

**Review engine:** 8 parallel subagents per round (`composer-2.5-fast`) + arbiter subagent

### Round 1 [✓ complete — CONTINUE]

**Dispatched (8):** architect | red-team | edge-cases | yagni-gatekeeper | bdd-reviewer | tdd-reviewer | exemplar-matcher(document-review) | exemplar-matcher(worktree)

**Receipt Status:** all ✓

**Arbiter Output:**
- counts: raw=37 → after_filter=17 (B=6, I=11, N=13)
- degradation_check: N/A
- convergence_status: CONTINUE
- Key BLOCKING: arbiter §G contradiction, Goal 7 scenario missing, Phase 1/2 ordering, all-reviewer-failure gap, empty Goals vacuous pass
- yagni removals of Testing Strategy/traceability FALSE_DISCARDED (Phase A alignment)

**Revision:** 18 items applied to spec draft (F1.1–F1.18)

### Round 2 [✓ complete — CONTINUE]

**Dispatched (8):** same set on revised draft

**Receipt Status:** all ✓

**Arbiter Output:**
- counts: raw=21 → after_filter=5 (B=3, I=2, N=8)
- degradation_check: PASSED (5 ≤ 8.5 vs prev_total 17)
- convergence_status: CONTINUE
- Key BLOCKING: STOP_CONVERGED enforcement when reviewer excluded; §E fake pnpm example; plan tdd-reviewer needs Testing Strategy payload
- bdd-reviewer: NO_BLOCKING_ISSUES | tdd-reviewer: NO_BLOCKING_ISSUES

**Post-Round-2 revision:** F2.4, F2.6, F2.7, F2.8, F2.9 applied inline (user requested exactly 2 agent rounds)

**Status after 2 rounds:** CONTINUE — spec revised twice; ready for user sign-off or optional Round 3

---

## Phase B User Intervention Decisions

### I1 [⏳ awaiting / ✓ decided]
**Triggered in round:** Round N
**Related finding:** F<x.y>
**Reason for intervention:** ...
**Options Presented:**
- A: ...
- B: ...
**User Decision:** <choice>
**Rationale:** <user reason>
**Timestamp:** YYYY-MM-DD HH:MM
