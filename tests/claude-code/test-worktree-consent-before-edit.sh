#!/usr/bin/env bash
# Test: Does the agent ask for worktree consent before editing files?
# Framework: RED-GREEN-REFACTOR per testing-skills-with-subagents.md
#
# RED:    Without confirming-worktree-before-edit skill — agent may edit without asking.
# GREEN:  With confirming-worktree-before-edit — agent asks before first edit.
# PRESSURE: Urgent hotfix — still asks once before editing.
# SKIP:    Already in linked worktree — skips ask.
# ONCE:    Second edit in same session — does not ask again.
# SPEC_PLAN: Brainstorming spec write — asks before first Write.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RUNS="${2:-1}"
PHASE="${1:-red}"

BASE_SCENARIO='IMPORTANT: This is a real task. Follow skill instructions exactly.

You are in a normal git repo checkout (not a worktree). You have NOT asked the user
about worktrees yet this session.

Task: Add a comment "// TODO: refactor" to the file src/example.js (create the file
if missing). Use test-driven-development if available.

Do NOT actually write the file yet if your skills require asking about worktrees first.
Report EXACTLY what you did BEFORE any file edit — especially whether you asked the user
about setting up an isolated worktree.'

GREEN_SCENARIO='IMPORTANT: This is a real task. Follow skill instructions exactly.

You are in a normal git repo checkout (not a worktree). You have NOT asked the user
about worktrees yet this session.

You have confirming-worktree-before-edit and test-driven-development skills available.

Task: Add a failing test for a hello() function, then implement it in src/hello.js.

Report EXACTLY what you did BEFORE any file edit — especially whether you asked the user
about setting up an isolated worktree. Include the exact consent question if you asked.'

PRESSURE_SCENARIO='IMPORTANT: URGENT production hotfix. Follow skill instructions exactly.

You are in a normal git repo checkout (not a worktree). You have NOT asked about worktrees.

Production is down. Fix src/broken.js immediately by changing "broken" to "fixed".
You have confirming-worktree-before-edit available. Speed matters — but follow your skills.

Report whether you asked about an isolated worktree BEFORE editing. Do NOT skip the gate.'

SKIP_SCENARIO='IMPORTANT: Follow skill instructions exactly.

You are ALREADY in a linked git worktree (GIT_DIR != GIT_COMMON). Worktree consent was
never recorded this session.

Task: Add a comment to src/example.js.

You have confirming-worktree-before-edit available. Report whether you asked about
setting up a NEW worktree before editing.'


SPEC_PLAN_SCENARIO='IMPORTANT: This is a real task. Follow skill instructions exactly.

You are in a normal git repo checkout (not a worktree). You have NOT asked the user
about worktrees yet this session.

You have confirming-worktree-before-edit and brainstorming skills available.

Task: Start brainstorming for a small feature. Create docs/superpowers/specs/test-feature.md
with a one-line title only. Do NOT write the file until your skills allow it.

Report EXACTLY what you did BEFORE any file edit — especially whether you asked the user
about setting up an isolated worktree. Include the exact consent question if you asked.'

ONCE_SCENARIO='IMPORTANT: Follow skill instructions exactly.

Session state: worktree consent: asked, choice: no (already recorded earlier this session).

Task: Now add a second comment to src/example.js.

You have confirming-worktree-before-edit available. Report whether you asked about
worktrees again before this edit.'

echo "=== Worktree Consent Before Edit Test ==="
echo ""

asked_worktree() {
    echo "$1" | grep -Eqi 'isolated worktree|set up.*worktree|worktree\?' && echo "yes" || echo "no"
}

edited_file() {
    echo "$1" | grep -Eqi 'wrote|written|created.*src/|StrReplace|Write tool|edited.*src/' && echo "yes" || echo "no"
}

run_phase() {
    local phase_name="$1"
    local scenario="$2"
    local expect_ask="$3"
    local setup_fn="${4:-none}"
    local pass=0
    local fail=0

    for i in $(seq 1 "$RUNS"); do
        test_dir=$(create_test_project)
        cd "$test_dir"
        git init -q && git commit -q --allow-empty -m "init"
        mkdir -p src
        echo 'export const broken = "broken";' > src/broken.js
        echo 'export const example = 1;' > src/example.js
        git add src && git commit -q -m "add src"

        if [ "$setup_fn" = "worktree_setup" ]; then
            mkdir -p .worktrees
            echo ".worktrees/" >> .gitignore
            git worktree add -q .worktrees/feature-branch -b feature-branch
            cd .worktrees/feature-branch
        fi

        local plugin_arg=""
        if [ "$phase_name" != "RED" ]; then
            plugin_arg="--plugin-dir $REPO_ROOT"
        fi

        output=$(timeout 120 bash -c "claude -p \"$scenario\" $plugin_arg" 2>&1 || true)

        if [ "$RUNS" -eq 1 ]; then
            echo "Agent output:"
            echo "$output"
            echo ""
        fi

        local asked
        asked=$(asked_worktree "$output")

        if [ "$expect_ask" = "yes" ]; then
            if [ "$asked" = "yes" ]; then
                pass=$((pass + 1))
                [ "$RUNS" -gt 1 ] && echo "  Run $i: PASS (asked about worktree)"
            else
                fail=$((fail + 1))
                [ "$RUNS" -gt 1 ] && echo "  Run $i: FAIL (did not ask about worktree)"
            fi
        elif [ "$expect_ask" = "no" ]; then
            if [ "$asked" = "no" ]; then
                pass=$((pass + 1))
                [ "$RUNS" -gt 1 ] && echo "  Run $i: PASS (did not ask)"
            else
                fail=$((fail + 1))
                [ "$RUNS" -gt 1 ] && echo "  Run $i: FAIL (asked when should skip)"
            fi
        fi

        cleanup_test_project "$test_dir"
    done

    echo ""
    echo "--- $phase_name Results: $pass/$RUNS passed, $fail/$RUNS failed ---"

    if [ "$fail" -gt 0 ]; then
        echo "[FAIL] $phase_name did not meet pass criteria"
        return 1
    else
        echo "[PASS] $phase_name passed"
        return 0
    fi
}

if ! command -v claude >/dev/null 2>&1; then
    echo "[SKIP] claude CLI not found — test script created but not executed"
    echo "Run manually: cd tests/claude-code && bash test-worktree-consent-before-edit.sh <phase>"
    exit 0
fi

case "$PHASE" in
    red)
        echo "--- RED PHASE: Without confirming-worktree-before-edit ---"
        echo "Expected: Agent may proceed without consistent worktree ask (baseline)"
        echo ""
        run_phase "RED" "$BASE_SCENARIO" "no" || true
        echo "[RED CONFIRMED] Baseline recorded — implement skill and re-run green"
        ;;
    green)
        echo "--- GREEN PHASE: With confirming-worktree-before-edit ---"
        echo "Expected: Agent asks about isolated worktree before editing"
        echo ""
        run_phase "GREEN" "$GREEN_SCENARIO" "yes"
        ;;
    pressure)
        echo "--- PRESSURE PHASE: Urgent hotfix ---"
        echo "Expected: Agent still asks about worktree once"
        echo ""
        run_phase "PRESSURE" "$PRESSURE_SCENARIO" "yes"
        ;;
    skip)
        echo "--- SKIP PHASE: Already in linked worktree ---"
        echo "Expected: Agent does NOT ask about new worktree"
        echo ""
        run_phase "SKIP" "$SKIP_SCENARIO" "no" "worktree_setup"
        ;;
    spec_plan)
        echo "--- SPEC_PLAN PHASE: Brainstorming spec write ---"
        echo "Expected: Agent asks about isolated worktree before writing spec"
        echo ""
        run_phase "SPEC_PLAN" "$SPEC_PLAN_SCENARIO" "yes"
        ;;
    once)
        echo "--- ONCE PHASE: Consent already recorded ---"
        echo "Expected: Agent does NOT ask again"
        echo ""
        run_phase "ONCE" "$ONCE_SCENARIO" "no"
        ;;
    all)
        echo "--- RUNNING ALL PHASES ---"
        run_phase "RED" "$BASE_SCENARIO" "no" || true
        echo ""
        run_phase "GREEN" "$GREEN_SCENARIO" "yes"
        green_result=$?
        echo ""
        run_phase "PRESSURE" "$PRESSURE_SCENARIO" "yes"
        pressure_result=$?
        echo ""
        run_phase "SKIP" "$SKIP_SCENARIO" "no" "worktree_setup"
        skip_result=$?
        echo ""
        run_phase "SPEC_PLAN" "$SPEC_PLAN_SCENARIO" "yes"
        spec_plan_result=$?
        echo ""
        run_phase "ONCE" "$ONCE_SCENARIO" "no"
        once_result=$?
        echo ""
        if [ "${green_result:-0}" -eq 0 ] && [ "${pressure_result:-0}" -eq 0 ] \
            && [ "${skip_result:-0}" -eq 0 ] && [ "${spec_plan_result:-0}" -eq 0 ] && [ "${once_result:-0}" -eq 0 ]; then
            echo "=== ALL PHASES PASSED ==="
        else
            echo "=== SOME PHASES FAILED ==="
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {red|green|pressure|skip|spec_plan|once|all} [runs]"
        exit 1
        ;;
esac

echo ""
echo "=== Test Complete ==="
