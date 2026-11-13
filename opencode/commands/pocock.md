---
description: Run Matt Pocock skill workflows: setup, one stage, or a chained spec to review flow
argument-hint: "status | setup | spec <idea> | tickets <spec> | triage <ref> | implement <ref> | review <scope> | flow <idea>"
---

# Matt Pocock workflow runner

Argument string: `$ARGUMENTS`

Split it into a mode word and the rest. If it is empty, use `status`.

Per-repo config lives in `docs/agents/`: `issue-tracker.md`, `domain.md`, and `triage-labels.md`. Read those files before running a stage. If `docs/agents/issue-tracker.md` is missing and the mode is not `status`, run **Setup** first without asking.

## Modes

### status

Report in at most 10 lines:

- The git remote and the detected tracker.
- Which `docs/agents/*.md` files exist.
- Whether an `## Agent skills` section exists in `CLAUDE.md` or `AGENTS.md`.
- Which pipeline skills are installed.

Then name the next useful command. Write nothing.

### setup

Read `~/dotfiles/skills/setup-matt-pocock-skills/SKILL.md` and the seed templates in that folder. Follow that skill with these overrides:

1. Run unattended. Never ask a question. Apply the defaults below and report what you wrote.
2. Tracker: a GitHub remote uses `issue-tracker-github.md`; a GitLab remote uses `issue-tracker-gitlab.md`; any other remote, or no remote, uses `issue-tracker-local.md`.
3. Triage labels: use the five defaults unchanged.
4. Domain docs: single-context, unless `pnpm-workspace.yaml`, a `workspaces` field, or populated `packages/*/src` directories exist.
5. Edit `CLAUDE.md` if it exists, else `AGENTS.md` if it exists, else create `AGENTS.md`. Update an existing `## Agent skills` section in place instead of appending a duplicate.
6. Create missing tracker labels with `gh label create` or `glab label create` only when that CLI is installed and authenticated. Never rename or delete a label.
7. Do not create `GLOSSARY.md`, `GLOSSARY-MAP.md`, or ADR files.
8. Preserve existing `docs/agents/*.md` contents. Create absent files. Change an existing file only when it names the wrong tracker.
9. Be idempotent. A second run on the same repo state must produce no changes.

End with one line per file created or changed, then the next command to run.

### spec, tickets, triage, implement, review

Read the matching `SKILL.md` and follow it. Pass the remaining arguments as the scope.

- `spec` reads `~/dotfiles/skills/to-spec/SKILL.md`.
- `tickets` reads `~/dotfiles/skills/to-tickets/SKILL.md`.
- `triage` reads `~/dotfiles/skills/triage/SKILL.md`.
- `implement` reads `~/dotfiles/skills/implement/SKILL.md`.
- `review` reads `~/dotfiles/skills/code-review/SKILL.md`.

Read those files directly because most of these skills set `disable-model-invocation: true` and are hidden from the skill list.

Read tracker, labels, and domain rules from `docs/agents/`, not from assumptions. Do not ask the user to repeat context that is already in the conversation, the spec, or the tracker.

### flow

Take one feature idea or spec through delivery. Run the phases in order and stop at each gate:

1. Run Setup if `docs/agents/issue-tracker.md` is missing.
2. Spec: when the remaining arguments are an idea rather than a path or reference, load `to-spec`. Gate: show the spec title and a short summary, then ask for approval.
3. Tickets: load `to-tickets`. Gate: show the ticket list in blocking order, then ask for approval.
4. Implement: load `implement`, one ticket at a time in blocking order. Run the repo's tests after each ticket. Stop and report on a failing test instead of continuing.
5. Review: load `code-review` on the changes since the flow started. Report findings. Do not fix them unless asked.

If the user explicitly says "no gates", skip the approval questions in phases 2 and 3 and continue automatically.

Never commit, push, or open a pull request as part of this flow.
