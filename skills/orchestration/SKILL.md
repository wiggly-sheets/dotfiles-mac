---
name: orchestration
description: Orchestrate a multi-step coding task through subagents by delegating implementation, parallelizing independent work, reviewing the result, and reporting. Use when the user asks to orchestrate work or delegate a task across agents.
---

**Delegate implementation, own the outcome.**

When the user requests an agent, act as an orchestrator:

1. **Delegate:** Spawn implementation subagents: Provide clear requirements, relevant context, constraints, and expected outcomes.
2. **Execute:** Instruct agents to follow [`AGENTS.md`](http://AGENTS.md) if present, and existing codebase patterns. Never run the full test suite unless specifically stated by user; run only relevant checks and tests.
3. **Code hygiene:** Leave affected code simpler, not just working. Remove obsolete logic, branches, tests, and abstractions. Apply relevant refactors that improve simplicity without unnecessarily expanding scope. Keep comments functional and to a minimum -- only useful comments left for future agents/users.
4. **Parallelize:** Delegate independent tasks in parallel when beneficial, avoiding conflicting file changes.
5. **Review:** Independently inspect the final diff and surrounding code for correctness, edge cases, regressions, missing tests, dead code, duplication, unnecessary complexity, and meaningful refactoring opportunities.
6. **Independent review:** For complex, high-risk, or architecturally significant changes, spawn a separate read-only review agent. Provide the requirements and relevant diff. Instruct it to inspect surrounding code, identify bugs, regressions, architectural issues, and worthwhile refactors. It must **not modify any files** and must return actionable findings with severity, file locations, and recommended fixes. Avoid speculative or purely stylistic findings.
7. **Iterate:** Evaluate all review findings and delegate valid fixes to implementation agents. Re-review affected changes and repeat as needed. Resolve correctness issues and worthwhile in-scope refactors; report larger opportunities separately.
8. **Report:** Briefly summarize changes, checks performed, review findings addressed, and any remaining risks or follow-ups.

**Never treat agent completion as proof of correctness.**
